import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'summary_export.dart';
import 'summary_sync.dart';

/// Imported aggregates remain separate from local profiles and raw play records.
class SummarySnapshot {
  final DateTime savedAt;
  final List<DailySessionSummary> summaries;

  SummarySnapshot({
    required this.savedAt,
    required Iterable<DailySessionSummary> summaries,
  }) : summaries = List.unmodifiable(summaries);
}

/// Explicit local storage only. Construction never reads or calls a cloud SDK.
class SummarySnapshotCache {
  static const maxBytes = 256 * 1024;
  static const maxDocumentBytes = 4096;
  final AppDatabase db;
  final DateTime Function() now;
  // Recreated cache wrappers on the same database share ordering, including clear.
  static final _queues = Expando<Future<void>>('summary snapshot operations');

  SummarySnapshotCache(this.db, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  String? _profilePrefix(String profile) {
    if (!RegExp(r'^[A-Za-z0-9-]{1,128}$').hasMatch(profile)) return null;
    final hash = sha256.convert(utf8.encode(profile));
    return 'sync.imported.v2.$hash.';
  }

  String? _key(String uid, String profile) {
    final prefix = _profilePrefix(profile);
    if (!isSafeSyncId(uid) || prefix == null) return null;
    final accountHash = sha256.convert(utf8.encode(uid));
    return '$prefix$accountHash';
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = (_queues[db] ?? Future<void>.value()).then((_) => action());
    _queues[db] = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> save(
    String uid,
    String profile,
    List<DailySessionSummary> summaries,
  ) {
    final key = _key(uid, profile);
    final copy = List<DailySessionSummary>.of(summaries);
    return _serial(() async {
      if (key == null) throw ArgumentError('Invalid summary cache scope');
      final at = now().toUtc();
      if (at.millisecondsSinceEpoch <= 0 ||
          copy.length > SummarySync.maxDocuments) {
        throw ArgumentError('Invalid summary snapshot');
      }
      final ids = <String>{};
      final documents = <Map<String, Object>>[];
      for (final summary in copy) {
        if (!summary.validAt(at) || !ids.add(summary.documentId)) {
          throw ArgumentError('Invalid or duplicate summary');
        }
        final payload = summary.toPayload()
          ..['updatedAt'] = summary.updatedAt.toUtc().toIso8601String();
        if (utf8.encode(jsonEncode(payload)).length > maxDocumentBytes) {
          throw ArgumentError('Summary exceeds cache capacity');
        }
        documents.add(payload);
      }
      final encoded = jsonEncode({
        'version': 1,
        'savedAt': at.toIso8601String(),
        'summaries': documents,
      });
      if (utf8.encode(encoded).length > maxBytes) {
        throw ArgumentError('Snapshot exceeds cache capacity');
      }
      await db.setPreference(key, encoded);
    });
  }

  Future<SummarySnapshot?> load(
    String uid,
    String profile,
  ) => _serial(() async {
    final key = _key(uid, profile);
    if (key == null) return null;
    final raw = await db.preference(key);
    if (raw == null || utf8.encode(raw).length > maxBytes) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic> ||
          data.length != 3 ||
          !data.keys.every(
            const {'version', 'savedAt', 'summaries'}.contains,
          ) ||
          data['version'] is! int ||
          data['version'] != 1) {
        return null;
      }
      final savedAt = _timestamp(data['savedAt']);
      final current = now();
      if (savedAt == null || savedAt.isAfter(current)) return null;
      final documents = data['summaries'];
      if (documents is! List || documents.length > SummarySync.maxDocuments) {
        return null;
      }
      final ids = <String>{};
      final summaries = <DailySessionSummary>[];
      for (final document in documents) {
        if (document is! Map<String, dynamic> ||
            utf8.encode(jsonEncode(document)).length > maxDocumentBytes) {
          return null;
        }
        final updatedAt = _timestamp(document['updatedAt']);
        if (updatedAt == null) return null;
        final decoded = Map<String, dynamic>.of(document)
          ..['updatedAt'] = updatedAt;
        final summary = DailySessionSummary.fromPayload(decoded, now: savedAt);
        if (summary == null ||
            !summary.validAt(current) ||
            !ids.add(summary.documentId)) {
          return null;
        }
        summaries.add(summary);
      }
      return SummarySnapshot(savedAt: savedAt, summaries: summaries);
    } on FormatException {
      return null;
    }
  });

  Future<void> clear(String uid, String profile) => _serial(() async {
    final key = _key(uid, profile);
    if (key == null) throw ArgumentError('Invalid summary cache scope');
    await (db.delete(db.preferences)..where((row) => row.key.equals(key))).go();
  });

  /// Remove imported copies for this local profile under every account.
  /// Account identifiers are not needed or retained to perform local deletion.
  Future<void> clearProfile(String profile) => _serial(() async {
    final prefix = _profilePrefix(profile);
    if (prefix == null) throw ArgumentError('Invalid summary cache profile');
    await (db.delete(
      db.preferences,
    )..where((row) => row.key.like('$prefix%'))).go();
  });

  /// Forget all imported profiles for an account when it signs out.
  Future<void> clearAccount(String uid) => _serial(() async {
    if (!isSafeSyncId(uid)) {
      throw ArgumentError('Invalid summary cache account');
    }
    final accountHash = sha256.convert(utf8.encode(uid));
    await (db.delete(
      db.preferences,
    )..where((row) => row.key.like('sync.imported.v2.%.$accountHash'))).go();
  });

  static DateTime? _timestamp(Object? value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    return parsed != null &&
            parsed.millisecondsSinceEpoch > 0 &&
            parsed.isUtc &&
            parsed.toIso8601String() == value
        ? parsed
        : null;
  }
}
