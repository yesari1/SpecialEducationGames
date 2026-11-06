import '../db/app_database.dart';

/// A path step represents a distinct, accessible game, rather than a trial.
class DailyPathProgress {
  final List<String> steps;
  final Set<String> completed;
  const DailyPathProgress(this.steps, this.completed);

  factory DailyPathProgress.fromSessions({
    required List<String> steps,
    required Iterable<GameSession> sessions,
    required String profileId,
    required DateTime now,
  }) {
    final localNow = now.toLocal();
    final done = <String>{};
    for (final session in sessions) {
      final ended = session.endedAt?.toLocal();
      final key = '${session.themeId}_${session.gameId}';
      if (session.profileId == profileId &&
          session.completed &&
          session.activeMs > 0 &&
          ended != null &&
          !ended.isAfter(localNow) &&
          !session.startedAt.isAfter(session.endedAt!) &&
          ended.year == localNow.year &&
          ended.month == localNow.month &&
          ended.day == localNow.day &&
          steps.contains(key)) {
        done.add(key);
      }
    }
    return DailyPathProgress(List.unmodifiable(steps), Set.unmodifiable(done));
  }

  int get count => completed.length;
  // A remotely reduced path with fewer than four games is not a full daily path.
  bool get complete => steps.length >= 3 && count == steps.length;
  static String dayKey(DateTime value) {
    final day = value.toLocal();
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  static bool validStickerDay(String value, DateTime now) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    return parsed != null &&
        dayKey(parsed) == value &&
        value.compareTo(dayKey(now)) <= 0;
  }
}
