import 'dart:async';

import 'summary_export.dart';

bool isSafeSyncId(String value) =>
    value.length <= 128 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

class SummaryDocument {
  final String id;
  final Map<String, dynamic> payload;
  const SummaryDocument(this.id, this.payload);
}

abstract interface class SummaryStore {
  /// Implementations must reject oversized responses rather than truncate.
  Future<List<SummaryDocument>> fetch(
    String uid,
    String profileId, {
    required bool Function() stillAuthorized,
  });

  /// Compare again atomically on the server. Never increment aggregate fields.
  Future<List<DailySessionSummary>> merge(
    String uid,
    String profileId,
    List<DailySessionSummary> summaries, {
    required DateTime now,
    required bool Function() stillAuthorized,
  });
}

enum SummarySyncIssue {
  unauthorized,
  invalidScope,
  busy,
  cancelled,
  timeout,
  unavailable,
  capacity,
}

class SummarySyncFailure implements Exception {
  final SummarySyncIssue issue;
  const SummarySyncFailure(this.issue);
}

class SummarySyncResult {
  /// A separate merged snapshot; callers must not overwrite local raw records.
  final List<DailySessionSummary> summaries;
  const SummarySyncResult(this.summaries);
}

/// Explicit action only. Construction never initializes Firebase or uses a
/// network. Consent, account and profile are rechecked between every await.
class SummarySync {
  static const maxDocuments = 200;
  final SummaryStore store;
  final String? Function() currentUid;
  final String? Function() currentProfileId;
  final bool Function() parentAuthorized;
  final bool Function() consentGiven;
  final DateTime Function() now;
  final Duration timeout;
  int _generation = 0;
  bool _busy = false;
  bool _disposed = false;

  SummarySync({
    required this.store,
    required this.currentUid,
    required this.currentProfileId,
    required this.parentAuthorized,
    required this.consentGiven,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 20),
  }) : now = now ?? DateTime.now;

  bool get busy => _busy;

  /// Call immediately when account/profile/consent or parent access changes.
  /// Already committed server writes cannot be recalled; their scope is fixed.
  void cancel() {
    _generation++;
    _busy = false;
  }

  void dispose() {
    _disposed = true;
    cancel();
  }

  Future<SummarySyncResult> synchronize(
    Iterable<DailySessionSummary> local,
  ) async {
    if (_disposed ||
        !parentAuthorized() ||
        !consentGiven() ||
        currentUid() == null) {
      throw const SummarySyncFailure(SummarySyncIssue.unauthorized);
    }
    final uid = currentUid()!;
    final profile = currentProfileId();
    if (!isSafeSyncId(uid) || profile == null || !isSafeSyncId(profile)) {
      throw const SummarySyncFailure(SummarySyncIssue.invalidScope);
    }
    if (_busy) throw const SummarySyncFailure(SummarySyncIssue.busy);
    final generation = ++_generation;
    _busy = true;
    bool valid() =>
        !_disposed &&
        generation == _generation &&
        parentAuthorized() &&
        consentGiven() &&
        currentUid() == uid &&
        currentProfileId() == profile;
    void check() {
      if (!valid()) throw const SummarySyncFailure(SummarySyncIssue.cancelled);
    }

    final at = now();
    try {
      final prepared = mergeDailySummaries(local, now: at);
      if (prepared.length > maxDocuments) {
        throw const SummarySyncFailure(SummarySyncIssue.capacity);
      }
      final result = await (() async {
        check();
        final remote = await store.fetch(uid, profile, stillAuthorized: valid);
        check();
        if (remote.length > maxDocuments) {
          throw const SummarySyncFailure(SummarySyncIssue.capacity);
        }
        final decoded = <DailySessionSummary>[];
        for (final doc in remote) {
          final summary = DailySessionSummary.fromPayload(doc.payload, now: at);
          if (summary != null && doc.id == summary.documentId) {
            decoded.add(summary);
          }
        }
        final merged = mergeDailySummaries([...prepared, ...decoded], now: at);
        if (merged.length > maxDocuments) {
          throw const SummarySyncFailure(SummarySyncIssue.capacity);
        }
        check();
        final committed = await store.merge(
          uid,
          profile,
          merged,
          now: at,
          stillAuthorized: valid,
        );
        check();
        return SummarySyncResult(mergeDailySummaries(committed, now: at));
      })().timeout(timeout);
      check();
      return result;
    } on TimeoutException {
      if (generation == _generation) {
        _generation++;
        _busy = false;
      }
      throw const SummarySyncFailure(SummarySyncIssue.timeout);
    } on SummarySyncFailure {
      rethrow;
    } catch (_) {
      throw const SummarySyncFailure(SummarySyncIssue.unavailable);
    } finally {
      if (generation == _generation) _busy = false;
    }
  }
}
