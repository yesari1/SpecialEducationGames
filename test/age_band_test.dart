import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/round_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Age band mapping', () {
    test('exact ages map to the four bands', () {
      expect(
        [for (var age = 2; age <= 10; age++) AgeBand.forAge(age)],
        [
          AgeBand.firstSteps,
          AgeBand.firstSteps,
          AgeBand.explore,
          AgeBand.explore,
          AgeBand.schoolReady,
          AgeBand.schoolReady,
          AgeBand.practice,
          AgeBand.practice,
          AgeBand.practice,
        ],
      );
    });

    test('existing profiles: ageYears first, legacy range index second', () {
      expect(AgeBand.fromAge({'ageYears': 3, 'age': 3}), AgeBand.firstSteps);
      expect(AgeBand.fromAge({'age': 1}), AgeBand.explore);
      expect(AgeBand.fromAge({'age': 3}), AgeBand.practice);
      expect(AgeBand.fromAge({'age': 9}), isNull);
      expect(AgeBand.fromAge({}), isNull);
      expect(AgeBand.of({}), isNull);
    });

    test('the parent shift moves one band and stays in range', () {
      expect(
        AgeBand.of({'ageYears': 5, 'ageLevelShift': 1}),
        AgeBand.schoolReady,
      );
      expect(
        AgeBand.of({'ageYears': 5, 'ageLevelShift': -1}),
        AgeBand.firstSteps,
      );
      expect(
        AgeBand.of({'ageYears': 5, 'ageLevelShift': 5}),
        AgeBand.schoolReady,
      );
      expect(
        AgeBand.of({'ageYears': 2, 'ageLevelShift': -1}),
        AgeBand.firstSteps,
      );
      expect(AgeBand.of({'ageYears': 9, 'ageLevelShift': 1}), AgeBand.practice);
    });

    test('at the default tier each band matches the approved table', () {
      final rows = {
        for (final band in AgeBand.values)
          band: [
            band.choices(band.defaultTier),
            band.maxNumber(band.defaultTier),
            band.stages,
          ],
      };
      expect(rows, {
        AgeBand.firstSteps: [2, 3, 5],
        AgeBand.explore: [3, 5, 6],
        AgeBand.schoolReady: [4, 10, 8],
        AgeBand.practice: [4, 20, 10],
      });
      // Zor is never a default: it stays premium.
      expect(
        AgeBand.values.map((b) => b.defaultTier),
        everyElement(isNot(Difficulty.hard)),
      );
    });

    test('Kolay/Orta/Zor still step the level, within limits', () {
      expect(
        [for (final t in Difficulty.values) AgeBand.explore.choices(t)],
        [2, 3, 4],
      );
      expect(
        [for (final t in Difficulty.values) AgeBand.firstSteps.maxNumber(t)],
        [3, 5, 10],
      );
      expect(
        [for (final t in Difficulty.values) AgeBand.practice.maxNumber(t)],
        [10, 20, 20],
      );
      expect(AgeBand.practice.countableMax(Difficulty.medium), 10);
    });

    test('hints: sooner for 2–3, later for 8+; drag games after tap', () {
      expect(AgeBand.firstSteps.hintOffsetSeconds, lessThan(0));
      expect(AgeBand.practice.hintOffsetSeconds, greaterThan(0));
      expect(AgeBand.firstSteps.prefersTap, isTrue);
      expect(AgeBand.explore.prefersTap, isFalse);
      expect(AgeBand.practice.contentTier(Difficulty.easy), Difficulty.medium);
      expect(AgeBand.explore.contentTier(Difficulty.easy), Difficulty.easy);
    });

    test('focus answer refines the round length', () {
      expect(AgeBand.schoolReady.stagesFor({}), 8);
      expect(AgeBand.schoolReady.stagesFor({'focus': 0}), 6);
      expect(AgeBand.firstSteps.stagesFor({'focus': 0}), 3);
      expect(AgeBand.practice.stagesFor({'focus': 2}), 10);
    });

    test('theme start: band default, one lower for unfamiliar themes', () {
      // 6–7, theme known → Orta; unknown → Kolay.
      final known = {
        'ageYears': 6,
        'known': [0],
      };
      expect(SurveyMapper.initialForTheme(known, 'animals'), Difficulty.medium);
      expect(SurveyMapper.initialForTheme(known, 'colors'), Difficulty.easy);
      // 2–3 opens on Kolay even for a known theme.
      expect(
        SurveyMapper.initialForTheme({
          'ageYears': 2,
          'known': [0],
        }, 'animals'),
        Difficulty.easy,
      );
      // 8+ without other answers → Orta, never Zor.
      expect(
        SurveyMapper.initialForTheme({'ageYears': 9}, 'animals'),
        Difficulty.medium,
      );
      // No age: unchanged behaviour.
      expect(
        SurveyMapper.initialForTheme({
          'known': [0],
        }, 'animals'),
        Difficulty.medium,
      );
      expect(SurveyMapper.initialForTheme({}, 'animals'), Difficulty.easy);
      expect(
        SurveyMapper.initialForTheme({'ageYears': 9, 'receptive': 0}, 'x'),
        Difficulty.easy,
      );
    });
  });

  group('Age band in rounds', () {
    late ContentRepository content;
    setUpAll(() async => content = await ContentRepository.load());

    RoundController controller(
      String theme,
      String game,
      AgeBand band, {
      int seed = 1,
    }) => RoundController(
      content: content,
      themeId: theme,
      gameId: game,
      difficulty: band.defaultTier,
      choiceCount: band.choices(band.defaultTier),
      total: band.stages,
      band: band,
      struggle: {},
      saveTrial: (_) async {},
      playPrompt: (_) async {},
      scheduler: ItemScheduler(Random(seed)),
    );

    test('choices and question count follow the band', () {
      for (final band in AgeBand.values) {
        final c = controller('animals', 'G01', band)..start();
        expect(c.error, isNull, reason: '$band');
        expect(c.spec!.choices.length, band.choices(band.defaultTier));
        expect(c.total, band.stages);
        c.dispose();
      }
    });

    test('number games stay in the band range', () {
      for (final band in AgeBand.values) {
        final limit = band.maxNumber(band.defaultTier);
        for (var seed = 0; seed < 25; seed++) {
          for (final game in ['G33', 'G37', 'G38', 'G01']) {
            final c = controller('numbers', game, band, seed: seed)..start();
            expect(c.error, isNull, reason: '$band $game');
            for (final item in c.spec!.choices) {
              final n = int.tryParse(item.slug);
              if (n == null) continue;
              expect(n, lessThanOrEqualTo(limit), reason: '$band $game');
              if (game != 'G01') {
                expect(n, lessThanOrEqualTo(10), reason: 'countable $game');
              }
            }
            c.dispose();
          }
        }
      }
    });
  });

  test(
    'parent shift is gated, stored with the profile and read back',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      addTearDown(state.dispose);
      await state.load();
      await state.createProfile('Bir', 'cat', {'ageYears': 4, 'age': 1});
      expect(state.ageBand, AgeBand.explore);
      await expectLater(state.setAgeLevelShift(1), throwsStateError);
      state.unlockFamily();
      await expectLater(state.setAgeLevelShift(2), throwsArgumentError);
      await state.setAgeLevelShift(1);
      expect(state.ageBand, AgeBand.schoolReady);
      expect(state.ageBandFromAge, AgeBand.explore);
      expect(state.ageLevelShift, 1);
      await state.load();
      expect(state.ageBand, AgeBand.schoolReady);
      await state.setAgeLevelShift(0);
      expect(state.ageBand, AgeBand.explore);
      expect(state.activeSurvey.containsKey('ageLevelShift'), isFalse);
      // A band never unlocks premium: Zor stays locked for a free profile.
      await state.setAgeLevelShift(1);
      expect(state.canPlay('animals', 'G01', Difficulty.hard), isFalse);
    },
  );
}
