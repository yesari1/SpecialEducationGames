import 'dart:convert';
import '../db/app_database.dart';

class DailyPlayTime {
  final int usedMs, extraMs;
  const DailyPlayTime({this.usedMs = 0, this.extraMs = 0});
  int remainingMs(int limitMinutes) => limitMinutes == 0
      ? -1
      : (limitMinutes * 60000 + extraMs - usedMs).clamp(0, 1 << 50);
}

/// Active play only; separate from reminder goals and wall-clock session length.
/// Writes are serialized so overlapping ticks cannot overwrite each other.
class PlayTimeLedger {
  final AppDatabase db;
  final DateTime Function() now;
  Future<void> _tail = Future.value();
  PlayTimeLedger(this.db, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  static String dayKey(DateTime at) =>
      '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';
  String _key(String profile, DateTime at) =>
      'profile.$profile.playTime.${dayKey(at)}';
  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<DailyPlayTime> _read(
    String profile,
    DateTime at, {
    int seedMs = 0,
  }) async {
    final raw = await db.preference(_key(profile, at));
    if (raw == null) {
      final seeded = DailyPlayTime(usedMs: seedMs.clamp(0, 1 << 50));
      await _write(profile, at, seeded);
      return seeded;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return DailyPlayTime(
        usedMs: (data['usedMs'] as int).clamp(0, 1 << 50),
        extraMs: (data['extraMs'] as int).clamp(0, 1 << 50),
      );
    } catch (_) {
      // A damaged record must not silently grant a fresh allowance.
      return const DailyPlayTime(usedMs: 24 * 60 * 60000);
    }
  }

  Future<void> _write(String profile, DateTime at, DailyPlayTime value) =>
      db.setPreference(
        _key(profile, at),
        jsonEncode({'usedMs': value.usedMs, 'extraMs': value.extraMs}),
      );
  Future<DailyPlayTime> load(String profile, {int seedMs = 0}) =>
      _serial(() => _read(profile, now(), seedMs: seedMs));
  Future<DailyPlayTime> charge(
    String profile,
    int activeMs, {
    DateTime? endedAt,
  }) {
    if (activeMs < 0) throw ArgumentError.value(activeMs);
    final end = endedAt ?? now();
    return _serial(() async {
      var cursor = end.subtract(Duration(milliseconds: activeMs));
      while (cursor.isBefore(end)) {
        final midnight = cursor.isUtc
            ? DateTime.utc(cursor.year, cursor.month, cursor.day + 1)
            : DateTime(cursor.year, cursor.month, cursor.day + 1);
        final until = midnight.isBefore(end) ? midnight : end;
        final before = await _read(profile, cursor);
        await _write(
          profile,
          cursor,
          DailyPlayTime(
            usedMs: before.usedMs + until.difference(cursor).inMilliseconds,
            extraMs: before.extraMs,
          ),
        );
        cursor = until;
      }
      return _read(profile, end);
    });
  }

  Future<DailyPlayTime> extend(String profile, int minutes) {
    if (minutes != 10) throw ArgumentError.value(minutes);
    final at = now();
    return _serial(() async {
      final before = await _read(profile, at);
      final after = DailyPlayTime(
        usedMs: before.usedMs,
        extraMs: before.extraMs + minutes * 60000,
      );
      await _write(profile, at, after);
      return after;
    });
  }
}
