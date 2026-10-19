import 'dart:convert';

import '../db/app_database.dart';

/// Local preparation only: no authentication, database writes or network calls.
/// Session active time belongs to its local end day: historical rows do not
/// retain clock segments needed for an accurate midnight split. Trial counts
/// use their own local day. An adapter must preserve this accounting policy.
class DailySessionSummary {
  final String date, themeId, modeId, difficulty;
  final int activeMs, rounds, stages, independent;
  final DateTime updatedAt;

  const DailySessionSummary({
    required this.date,
    required this.themeId,
    required this.modeId,
    required this.difficulty,
    required this.activeMs,
    required this.rounds,
    required this.stages,
    required this.independent,
    required this.updatedAt,
  });

  String get documentId => '${date}_${themeId}_${modeId}_$difficulty';

  /// A future SDK adapter must convert its timestamp to DateTime first.
  /// Reject unexpected fields instead of accepting raw logs or account data.
  static DailySessionSummary? fromPayload(
    Map<String, dynamic> data, {
    required DateTime now,
  }) {
    const fields = {
      'date',
      'themeId',
      'modeId',
      'difficulty',
      'activeMs',
      'rounds',
      'stages',
      'independent',
      'updatedAt',
    };
    if (data.length != fields.length || !data.keys.every(fields.contains)) {
      return null;
    }
    for (final key in ['date', 'themeId', 'modeId', 'difficulty']) {
      if (data[key] is! String) return null;
    }
    for (final key in ['activeMs', 'rounds', 'stages', 'independent']) {
      if (data[key] is! int) return null;
    }
    if (data['updatedAt'] is! DateTime) return null;
    final result = DailySessionSummary(
      date: data['date'],
      themeId: data['themeId'],
      modeId: data['modeId'],
      difficulty: data['difficulty'],
      activeMs: data['activeMs'],
      rounds: data['rounds'],
      stages: data['stages'],
      independent: data['independent'],
      updatedAt: data['updatedAt'],
    );
    return result.validAt(now) ? result : null;
  }

  /// DateTime is intentionally kept typed for a future Firestore adapter.
  /// Only fields allowed by the draft sessions security rule are exported.
  Map<String, Object> toPayload() => {
    'date': date,
    'themeId': themeId,
    'modeId': modeId,
    'difficulty': difficulty,
    'activeMs': activeMs,
    'rounds': rounds,
    'stages': stages,
    'independent': independent,
    'updatedAt': updatedAt.toUtc(),
  };

  bool validAt(DateTime now) =>
      _validDay(date, now) &&
      _safeId(themeId) &&
      _safeId(modeId) &&
      const ['easy', 'medium', 'hard'].contains(difficulty) &&
      activeMs >= 0 &&
      rounds >= 0 &&
      stages >= 0 &&
      independent >= 0 &&
      independent <= stages &&
      updatedAt.millisecondsSinceEpoch > 0 &&
      !updatedAt.isAfter(now);
}

bool _safeId(String value) => RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value);

bool _validDay(String value, DateTime now) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null &&
      _day(parsed) == value &&
      value.compareTo(_day(now)) <= 0;
}

String _day(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// Inputs must be local records for the supplied profile. Others are ignored.
/// Open/invalid sessions are excluded; ended interrupted sessions contribute
/// active time but no completed round. Trials have no sessionId, so no ambiguous
/// time-window join is attempted: each valid stage uses its own local date.
List<DailySessionSummary> prepareDailySummaries({
  required String profileId,
  required Iterable<GameSession> sessions,
  required Iterable<Trial> trials,
  required DateTime now,
}) {
  final unique = <String, GameSession>{};
  for (final session in sessions) {
    final end = session.endedAt;
    if (session.profileId != profileId ||
        end == null ||
        session.id.isEmpty ||
        end.isAfter(now) ||
        session.startedAt.millisecondsSinceEpoch <= 0 ||
        end.isBefore(session.startedAt) ||
        session.activeMs < 0 ||
        session.activeMs > end.difference(session.startedAt).inMilliseconds ||
        !_safeId(session.themeId) ||
        !_safeId(session.gameId) ||
        !const ['easy', 'medium', 'hard'].contains(session.difficulty)) {
      continue;
    }
    final old = unique[session.id];
    if (old == null || _sessionKey(session).compareTo(_sessionKey(old)) > 0) {
      unique[session.id] = session;
    }
  }
  final rounds = unique.values.toList()
    ..sort((a, b) {
      final start = b.startedAt.compareTo(a.startedAt);
      return start != 0 ? start : b.id.compareTo(a.id);
    });
  final groups = <String, _Bucket>{};
  for (final round in rounds) {
    final key =
        '${_day(round.endedAt!)}_${round.themeId}_'
        '${round.gameId}_${round.difficulty}';
    final bucket = groups.putIfAbsent(key, () => _Bucket(round));
    bucket.activeMs += round.activeMs;
    if (round.completed) bucket.rounds++;
    if (round.endedAt!.isAfter(bucket.updatedAt)) {
      bucket.updatedAt = round.endedAt!;
    }
  }
  final uniqueTrials = <int, Trial>{};
  for (final trial in trials) {
    if (trial.profileId != profileId ||
        trial.id <= 0 ||
        trial.at.isAfter(now) ||
        trial.wrongCount < 0 ||
        trial.maxHint < 0 ||
        trial.maxHint > 4 ||
        trial.latencyMs < 0 ||
        trial.idleMs < 0 ||
        trial.activeMs < 0 ||
        trial.at.millisecondsSinceEpoch <= 0 ||
        !_safeId(trial.themeId) ||
        !_safeId(trial.gameId) ||
        !const ['easy', 'medium', 'hard'].contains(trial.difficulty)) {
      continue;
    }
    final old = uniqueTrials[trial.id];
    if (old == null || _trialKey(trial).compareTo(_trialKey(old)) > 0) {
      uniqueTrials[trial.id] = trial;
    }
  }
  for (final trial in uniqueTrials.values) {
    final key =
        '${_day(trial.at)}_${trial.themeId}_'
        '${trial.gameId}_${trial.difficulty}';
    final bucket = groups.putIfAbsent(key, () => _Bucket.fromTrial(trial));
    bucket.stages++;
    if (trial.wrongCount == 0 && trial.maxHint == 0) bucket.independent++;
    if (trial.at.isAfter(bucket.updatedAt)) {
      bucket.updatedAt = trial.at;
    }
  }
  final result = groups.values.map((b) => b.summary).toList()
    ..sort((a, b) => a.documentId.compareTo(b.documentId));
  return List.unmodifiable(result);
}

String _sessionKey(GameSession s) => jsonEncode([
  s.endedAt!.toUtc().toIso8601String(),
  s.startedAt.toUtc().toIso8601String(),
  s.themeId,
  s.gameId,
  s.difficulty,
  s.activeMs,
  s.completed,
]);
String _trialKey(Trial t) => jsonEncode([
  t.at.toUtc().toIso8601String(),
  t.themeId,
  t.gameId,
  t.difficulty,
  t.wrongCount,
  t.maxHint,
  t.latencyMs,
  t.idleMs,
  t.activeMs,
]);

/// Document-level last-write-wins; never sums duplicate aggregates. Invalid or
/// future timestamps are discarded. Equal timestamps choose the lexically
/// largest canonical payload, independent of input order or device arrival.
List<DailySessionSummary> mergeDailySummaries(
  Iterable<DailySessionSummary> summaries, {
  required DateTime now,
}) {
  final merged = <String, DailySessionSummary>{};
  for (final summary in summaries) {
    if (!summary.validAt(now)) continue;
    final old = merged[summary.documentId];
    if (old == null ||
        summary.updatedAt.isAfter(old.updatedAt) ||
        (summary.updatedAt.isAtSameMomentAs(old.updatedAt) &&
            _canonical(summary).compareTo(_canonical(old)) > 0)) {
      merged[summary.documentId] = summary;
    }
  }
  return List.unmodifiable(
    merged.values.toList()
      ..sort((a, b) => a.documentId.compareTo(b.documentId)),
  );
}

String _canonical(DailySessionSummary s) => jsonEncode([
  s.date,
  s.themeId,
  s.modeId,
  s.difficulty,
  s.activeMs,
  s.rounds,
  s.stages,
  s.independent,
  s.updatedAt.toUtc().toIso8601String(),
]);

class _Bucket {
  final String date, themeId, modeId, difficulty;
  int activeMs = 0, rounds = 0, stages = 0, independent = 0;
  DateTime updatedAt;
  _Bucket(GameSession first)
    : date = _day(first.endedAt!),
      themeId = first.themeId,
      modeId = first.gameId,
      difficulty = first.difficulty,
      updatedAt = first.endedAt!;
  _Bucket.fromTrial(Trial first)
    : date = _day(first.at),
      themeId = first.themeId,
      modeId = first.gameId,
      difficulty = first.difficulty,
      updatedAt = first.at;
  DailySessionSummary get summary => DailySessionSummary(
    date: date,
    themeId: themeId,
    modeId: modeId,
    difficulty: difficulty,
    activeMs: activeMs,
    rounds: rounds,
    stages: stages,
    independent: independent,
    updatedAt: updatedAt.toUtc(),
  );
}
