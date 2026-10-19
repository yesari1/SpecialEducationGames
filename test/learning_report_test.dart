import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/learning_report.dart';

Trial trial(int id, DateTime at, {int wrong = 0, int hint = 0}) => Trial(
  id: id,
  profileId: 'p',
  themeId: 'animals',
  gameId: 'G01',
  targetId: 'animals.cat',
  difficulty: 'easy',
  wrongCount: wrong,
  maxHint: hint,
  latencyMs: 1500,
  idleMs: 4000,
  activeMs: 5500,
  selectedIds: '[]',
  at: at,
);

void main() {
  test(
    'Item insight requires repeated recent evidence and ignores future observations',
    () {
      final now = DateTime(2026, 10, 16, 12);
      final records = [
        trial(4, DateTime(2026, 10, 16, 10)),
        trial(1, DateTime(2026, 10, 13), hint: 4),
        trial(3, DateTime(2026, 10, 15)),
        trial(2, DateTime(2026, 10, 14)),
        trial(5, DateTime(2026, 10, 17), hint: 4),
        trial(
          6,
          DateTime(2026, 10, 14),
          hint: 3,
        ).copyWith(targetId: 'animals.dog'),
        trial(
          7,
          DateTime(2026, 10, 15),
          wrong: 2,
        ).copyWith(targetId: 'animals.dog'),
        trial(8, DateTime(2026, 10, 16, 10)).copyWith(targetId: 'animals.dog'),
      ];
      final summaries = ItemLearningSummary.fromTrials(records, now);
      final cat = summaries.firstWhere((x) => x.itemId == 'animals.cat');
      final dog = summaries.firstWhere((x) => x.itemId == 'animals.dog');
      expect(cat.observations.length, 4);
      expect(cat.independentStreak, 3);
      expect(cat.independentlyAnswered, true);
      expect(cat.needsSupport, false);
      expect(dog.needsSupport, true);
      expect(dog.independentlyAnswered, false);
    },
  );
  test(
    'Skill trend compares two calendar weeks only with enough observations',
    () {
      final now = DateTime(2026, 10, 16, 12);
      final report = LearningReport(
        [
          for (var i = 0; i < 3; i++) trial(i, DateTime(2026, 10, 15)),
          trial(3, DateTime(2026, 10, 8)),
          trial(4, DateTime(2026, 10, 8), hint: 2),
          trial(5, DateTime(2026, 10, 8), hint: 4),
        ],
        [],
        now,
      );
      expect(report.skillTrend('receptive_language'), closeTo(2 / 3, .0001));
      expect(report.skillTrend('fine_motor'), isNull);
    },
  );
  test(
    'Weekly report uses calendar days, preserves missing data and excludes future records',
    () {
      final now = DateTime(2026, 10, 16, 12);
      final report = LearningReport(
        [
          trial(1, DateTime(2026, 10, 10)),
          trial(2, DateTime(2026, 10, 16, 9)),
          trial(3, DateTime(2026, 10, 16, 10), wrong: 1),
          trial(4, DateTime(2026, 10, 16, 11), hint: 2),
          trial(5, DateTime(2026, 10, 9, 23, 59)),
          trial(6, DateTime(2026, 10, 16, 13)),
        ],
        [
          GameSession(
            id: 's',
            profileId: 'p',
            themeId: 'animals',
            gameId: 'G02',
            difficulty: 'easy',
            startedAt: DateTime(2026, 10, 16, 9),
            activeMs: 90000,
            completed: false,
          ),
        ],
        now,
      );
      expect(report.days.length, 7);
      expect(report.trials.length, 4);
      expect(report.days[1].independence, isNull);
      expect(report.days[1].latencySeconds, isNull);
      expect(report.days.last.independence, closeTo(1 / 3, .0001));
      expect(report.days.last.latencySeconds, 1.5);
      expect(report.days.last.idleSeconds, 4);
      expect(report.days.last.minutes, 1.5);
      expect(report.completedRounds, 0);
      expect(report.forSkill('receptive_language').length, 4);
      expect(report.forSkill('fine_motor'), isEmpty);
    },
  );
}
