import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/sync/summary_export.dart';

final now = DateTime(2026, 10, 16, 12);
GameSession session(
  String id, {
  String profile = 'p',
  bool completed = true,
  int activeMs = 1000,
  DateTime? start,
  DateTime? end,
  bool open = false,
}) => GameSession(
  id: id,
  profileId: profile,
  themeId: 'animals',
  gameId: 'G01',
  difficulty: 'easy',
  startedAt: start ?? DateTime(2026, 10, 16, 10),
  endedAt: open ? null : end ?? DateTime(2026, 10, 16, 10, 1),
  activeMs: activeMs,
  completed: completed,
);
Trial trial(
  int id, {
  String profile = 'p',
  int hint = 0,
  int wrong = 0,
  DateTime? at,
}) => Trial(
  id: id,
  profileId: profile,
  themeId: 'animals',
  gameId: 'G01',
  targetId: 'private-target',
  selectedIds: '["private-choice"]',
  difficulty: 'easy',
  wrongCount: wrong,
  maxHint: hint,
  latencyMs: 100,
  idleMs: 0,
  activeMs: 1000,
  at: at ?? DateTime(2026, 10, 16, 10, 0, 30),
);

DailySessionSummary summary({
  int active = 1000,
  DateTime? at,
  String date = '2026-10-16',
  int stages = 1,
  int independent = 1,
}) => DailySessionSummary(
  date: date,
  themeId: 'animals',
  modeId: 'G01',
  difficulty: 'easy',
  activeMs: active,
  rounds: 1,
  stages: stages,
  independent: independent,
  updatedAt: at ?? now,
);

void main() {
  test(
    'remote payload decoding fails closed on extra fields and malformed types',
    () {
      final payload = summary().toPayload();
      final restored = DailySessionSummary.fromPayload(payload, now: now);
      expect(restored?.toPayload(), payload);
      for (final invalid in [
        {...payload, 'premium': true},
        {...payload}..remove('rounds'),
        {...payload, 'activeMs': 1.5},
        {...payload, 'rounds': true},
        {...payload, 'updatedAt': now.toIso8601String()},
        {...payload, 'date': '2026-02-30'},
        {...payload, 'date': '2099-01-01'},
        {...payload, 'modeId': 'G01/private'},
      ]) {
        expect(DailySessionSummary.fromPayload(invalid, now: now), isNull);
      }
    },
  );
  test(
    'deduplicates records, isolates profile, excludes open/future/invalid',
    () {
      final good = session('a');
      final independent = trial(1);
      final result = prepareDailySummaries(
        profileId: 'p',
        now: now,
        sessions: [
          good,
          good,
          session('interrupted', completed: false, activeMs: 500),
          session('other', profile: 'other'),
          session('open', open: true),
          session('future', end: now.add(const Duration(minutes: 1))),
          session('negative', activeMs: -1),
          session('impossible', activeMs: 999999),
          session('reversed', end: DateTime(2026, 10, 15)),
        ],
        trials: [
          independent,
          independent,
          trial(2, hint: 2),
          trial(3, wrong: 1),
          trial(4, profile: 'other'),
          trial(5, hint: -1),
          trial(6, hint: 5),
          trial(7, at: now.add(const Duration(seconds: 1))),
        ],
      );
      expect(result, hasLength(1));
      final record = result.single;
      expect(record.documentId, '2026-10-16_animals_G01_easy');
      expect(record.activeMs, 1500);
      expect(record.rounds, 1);
      expect(record.stages, 3);
      expect(record.independent, 1);
      expect(record.toPayload().keys.toSet(), {
        'date',
        'themeId',
        'modeId',
        'difficulty',
        'activeMs',
        'rounds',
        'stages',
        'independent',
        'updatedAt',
      });
      expect(record.toPayload().toString(), isNot(contains('private')));
      expect(record.toPayload(), isNot(contains('profileId')));
      expect(record.updatedAt, DateTime(2026, 10, 16, 10, 1).toUtc());
    },
  );

  test('midnight accounting: session end day, stages actual local days', () {
    final start = DateTime(2026, 10, 15, 23, 59);
    final end = DateTime(2026, 10, 16, 0, 1);
    final result = prepareDailySummaries(
      profileId: 'p',
      now: now,
      sessions: [session('midnight', start: start, end: end, activeMs: 60000)],
      trials: [
        trial(1, at: start),
        trial(2, at: end),
      ],
    );
    expect(result.map((x) => x.date), ['2026-10-15', '2026-10-16']);
    expect(result.first.rounds, 0);
    expect(result.first.activeMs, 0);
    expect(result.first.stages, 1);
    expect(result.last.activeMs, 60000);
    expect(result.last.rounds, 1);
    expect(result.last.stages, 1);
    expect(result.every((x) => x.validAt(now)), isTrue);
  });

  test('conflicting row IDs resolve identically regardless of input order', () {
    final sessions = [session('same', activeMs: 2000), session('same')];
    final trials = [trial(1), trial(1, hint: 3)];
    final a = prepareDailySummaries(
      profileId: 'p',
      now: now,
      sessions: sessions,
      trials: trials,
    );
    final b = prepareDailySummaries(
      profileId: 'p',
      now: now,
      sessions: sessions.reversed,
      trials: trials.reversed,
    );
    expect(a.single.toPayload(), b.single.toPayload());
    expect(a.single.rounds, 1);
    expect(a.single.stages, 1);
    expect(a.single.independent, 0);
  });

  test('LWW keeps newer whole document; ties stable, never sums', () {
    final old = summary(
      active: 7000,
      at: now.subtract(const Duration(hours: 1)),
    );
    final newer = summary(active: 1000);
    final tie = summary(active: 2000);
    final invalidFuture = summary(
      active: 9999,
      at: now.add(const Duration(seconds: 1)),
    );
    final records = [
      old,
      newer,
      tie,
      tie,
      invalidFuture,
      summary(date: '2026-02-30'),
      summary(date: '2026-10-17'),
      summary(at: DateTime.fromMillisecondsSinceEpoch(0)),
      summary(stages: 0, independent: 1),
    ];
    final a = mergeDailySummaries(records, now: now);
    final b = mergeDailySummaries(records.reversed, now: now);
    expect(a, hasLength(1));
    expect(a.single.activeMs, 2000);
    expect(a.single.toPayload(), b.single.toPayload());
    expect(mergeDailySummaries([old, newer], now: now).single.activeMs, 1000);
  });
}
