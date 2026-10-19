import 'dart:convert';
import '../db/app_database.dart';
import 'firestore_announcement_source.dart';
import 'parent_announcement.dart';

typedef AnnouncementFetcher = Future<Map<String, dynamic>?> Function(String id);

/// Caller refreshes only while showing the parent card. No background polling,
/// account identifiers, writes to Firestore, or collection queries.
class AnnouncementRepository {
  final AppDatabase db;
  final AnnouncementFetcher fetcher;
  final DateTime Function() now;
  final Map<String, Future<ParentAnnouncement?>> _pending = {};

  AnnouncementRepository(
    this.db, {
    AnnouncementFetcher? fetcher,
    DateTime Function()? now,
  }) : fetcher = fetcher ?? FirestoreAnnouncementSource.read,
       now = now ?? DateTime.now;

  Future<ParentAnnouncement?> load(String id) async {
    if (!ParentAnnouncement.isValidId(id)) return null;
    try {
      final encoded = await db.preference('announcement:$id');
      if (encoded == null || encoded.length > 20000) return null;
      final data = jsonDecode(encoded);
      if (data is! Map ||
          data.length != 2 ||
          data['id'] != id ||
          !data.containsKey('payload')) {
        return null;
      }
      return ParentAnnouncement.tryParse(id, data['payload']);
    } catch (_) {
      return null;
    }
  }

  Future<ParentAnnouncement?> refresh(String id) {
    if (!ParentAnnouncement.isValidId(id)) return Future.value(null);
    return _pending.putIfAbsent(id, () async {
      try {
        return await _refresh(id);
      } finally {
        _pending.remove(id);
      }
    });
  }

  Future<ParentAnnouncement?> _refresh(String id) async {
    final cached = await load(id);
    try {
      final key = 'announcementCheckedAt:$id';
      final checked = DateTime.tryParse(await db.preference(key) ?? '');
      final time = now();
      if (checked != null) {
        if (time.isBefore(checked)) {
          // Rebase once and throttle: rolling the clock back cannot force reads.
          await db.setPreference(key, time.toIso8601String());
          return cached;
        }
        if (time.difference(checked) < const Duration(hours: 6)) return cached;
      }
      // Failed and malformed responses consume the same attempt interval.
      await db.setPreference(key, time.toIso8601String());
      final payload = await fetcher(id).timeout(const Duration(seconds: 10));
      final announcement = ParentAnnouncement.tryParse(id, payload);
      if (announcement == null) return cached;
      await db.setPreference(
        'announcement:$id',
        jsonEncode({'id': id, 'payload': announcement.toJson()}),
      );
      return announcement;
    } catch (_) {
      return cached;
    }
  }
}
