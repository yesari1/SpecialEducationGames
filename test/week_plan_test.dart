import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/week_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  test('7 days cycle the themes; early days use free cards only', () {
    const games = {
      'animals': ['G02', 'G01', 'G10', 'G14', 'G04'],
      'colors': ['G02', 'G01', 'G14'],
    };
    const free = {
      'animals_G02',
      'animals_G01',
      'animals_G10',
      'colors_G02',
      'colors_G01',
      'colors_G14',
    };
    final plan = WeekPlan.build(
      themes: const ['animals', 'colors'],
      gamesOf: (t) => games[t]!,
      isFree: (t, g) => free.contains('${t}_$g'),
    );
    expect(plan, hasLength(7));
    expect(plan.map((d) => d.theme), [
      'animals',
      'colors',
      'animals',
      'colors',
      'animals',
      'colors',
      'animals',
    ]);
    // Days 1–3: free games, Learn only when a theme has too few.
    expect(plan[0].games, ['G01', 'G10']);
    expect(plan[1].games, ['G01', 'G14']);
    for (final day in plan.take(3)) {
      for (final g in day.games) {
        expect(free, contains('${day.theme}_$g'));
      }
    }
    // Later: one new (Premium) game first; an all-free theme stays free.
    expect(plan[4].games, ['G14', 'G01']);
    expect(plan[3].games, ['G01', 'G14']);
    expect(
      WeekPlan.build(
        themes: const [],
        gamesOf: (_) => [],
        isFree: (_, _) => true,
      ),
      isEmpty,
    );
  });

  test('AppState plan follows the liked themes for a sample child', () async {
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    addTearDown(state.dispose);
    await state.load();
    // 4-year-old who likes vehicles and colors.
    await state.completeOnboarding(
      name: 'Ada',
      survey: {
        'ageYears': 4,
        'favorite': [1, 2],
      },
      dailyGoalMinutes: 10,
    );
    final plan = state.weekPlan;
    expect(plan, hasLength(7));
    final featured = state.configuration.featuredTheme;
    final liked = plan.map((d) => d.theme).where((t) => t != featured).take(2);
    expect(liked, ['vehicles', 'colors']);
    for (final day in plan) {
      expect(day.games, isNotEmpty);
      expect(state.content.theme(day.theme).games, containsAll(day.games));
    }
    for (final day in plan.take(3)) {
      for (final g in day.games) {
        expect(state.configuration.freeGames, contains('${day.theme}_$g'));
      }
    }
  });
}
