import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/round_controller.dart';
import 'package:flutter/services.dart';

ContentItem item(String id) => ContentItem.fromJson({
  'id': 'animals.$id',
  'theme': 'animals',
  'tier': 'easy',
  'name': {'tr': id, 'en': id},
  'audio': {},
  'images': ['test.png'],
  'tags': [],
});
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Animal sound rounds use playable recordings with distinct image choices',
    () async {
      final repo = await ContentRepository.load();
      for (final difficulty in Difficulty.values) {
        final c = RoundController(
          content: repo,
          themeId: 'animals',
          gameId: 'G10',
          difficulty: difficulty,
          struggle: {},
          saveTrial: (_) async {},
          playPrompt: (_) async {},
        );
        c.start();
        expect(c.error, isNull);
        expect(c.spec!.choices.length, difficulty.choices);
        expect(
          c.spec!.choices.map((x) => x.id).toSet().length,
          difficulty.choices,
        );
        for (final item in c.spec!.choices) {
          expect(item.images, isNotEmpty);
          expect(
            (await rootBundle.load(item.sfx!)).lengthInBytes,
            greaterThan(1000),
          );
        }
        // The spoken "listen" instruction, then the natural sound.
        expect(c.template.introCues(c.spec!, c.modeContext, 'tr'), [
          'assets/audio/tr/prompts/listen_sound_selected.mp3',
          c.spec!.target.sfx,
        ]);
        expect(c.template.introCues(c.spec!, c.modeContext, 'en'), [
          'assets/audio/en/prompts/listen_sound_selected.mp3',
          c.spec!.target.sfx,
        ]);
        c.dispose();
      }
    },
  );
  testWidgets('Old successful save cannot advance a newly started session', (
    tester,
  ) async {
    final saved = Completer<void>();
    final repo = ContentRepository([], [item('cat'), item('dog')], [], {});
    final c = RoundController(
      content: repo,
      themeId: 'animals',
      gameId: 'G01',
      difficulty: Difficulty.easy,
      struggle: {},
      saveTrial: (_) => saved.future,
      playPrompt: (_) async {},
    );
    c.start();
    await tester.pump();
    final completion = c.choose(c.spec!.target);
    c.start();
    await tester.pump();
    saved.complete();
    await completion;
    await tester.pump(const Duration(seconds: 2));
    expect(c.stage, 0);
    expect(c.phase, RoundPhase.answering);
    c.dispose();
  });
  test(
    'Phase-one numerical and group rounds have genuine distinct mechanics',
    () async {
      final repo = await ContentRepository.load();
      for (final id in ['G04', 'G33', 'G35', 'G36']) {
        final c = RoundController(
          content: repo,
          themeId: id == 'G04' ? 'animals' : 'numbers',
          gameId: id,
          difficulty: id == 'G36' ? Difficulty.hard : Difficulty.medium,
          struggle: {},
          saveTrial: (_) async {},
          playPrompt: (_) async {},
        );
        c.start();
        expect(c.error, isNull);
        expect(c.spec!.choices.any((x) => x.id == c.spec!.target.id), true);
        if (id == 'G04') expect(c.spec!.stimulus, isNotNull);
        if (id == 'G04') {
          expect(c.spec!.stimulus!.tags, contains(c.spec!.target.tags.single));
          for (final other in c.spec!.choices.where(
            (x) => x.id != c.spec!.target.id,
          )) {
            expect(c.spec!.stimulus!.tags, isNot(contains(other.tags.single)));
          }
        }
        if (id == 'G33') expect(c.spec!.count, int.parse(c.spec!.target.slug));
        if (id == 'G35') expect(c.spec!.sequence.last, '?');
        if (id == 'G36') {
          expect(c.spec!.choices.map((x) => x.slug).toSet(), {'>', '=', '<'});
        }
        c.dispose();
      }
    },
  );
  test(
    'Quantity comparison and missing middle have one mathematically correct answer',
    () async {
      final repo = await ContentRepository.load();
      expect(
        repo.themes.fold<int>(0, (sum, theme) => sum + theme.games.length),
        // Cards after removing G55 and G11 (Learn is the first card everywhere),
        // plus Feelings and Our Body (3 each) and Our Home (7), Nov 2026,
        // plus Find the Shadow on Shapes, What Color? and Color Baskets.
        68,
      );
      for (var i = 0; i < 30; i++) {
        for (final theme in ['animals', 'produce', 'vehicles', 'numbers']) {
          final c = RoundController(
            content: repo,
            themeId: theme,
            gameId: 'G36',
            difficulty: Difficulty.medium,
            struggle: {},
            saveTrial: (_) async {},
            playPrompt: (_) async {},
          );
          c.start();
          expect(c.error, isNull);
          expect(c.spec!.quantities.values.toSet().length, 3);
          expect(
            c.spec!.quantities[c.spec!.target.id],
            c.spec!.quantities.values.reduce(max),
          );
          if (theme != 'numbers') {
            expect(c.spec!.quantityItem?.images, isNotEmpty);
          }
          c.dispose();
        }
        final c = RoundController(
          content: repo,
          themeId: 'numbers',
          gameId: 'G35',
          difficulty: Difficulty.hard,
          struggle: {},
          saveTrial: (_) async {},
          playPrompt: (_) async {},
        );
        c.start();
        final expected = int.parse(c.spec!.target.slug);
        expect(c.spec!.sequence, ['${expected - 1}', '?', '${expected + 1}']);
        expect(expected, inInclusiveRange(1, 20));
        c.dispose();
      }
    },
  );
  test('Two wrong choices narrow the field; idle hints progress', () {
    expect(HintPolicy.afterWrong(1), 2);
    expect(HintPolicy.afterWrong(2), 4);
    expect(HintPolicy.afterIdle(3, Difficulty.easy), 0);
    expect(HintPolicy.afterIdle(4, Difficulty.easy), 1);
    expect(HintPolicy.afterIdle(12, Difficulty.easy), 3);
  });
  test('Adaptive difficulty waits for ten stages and respects boundaries', () {
    expect(
      DifficultyEngine.recommend(Difficulty.easy, [0, 0]),
      Difficulty.easy,
    );
    expect(
      DifficultyEngine.recommend(Difficulty.easy, List.filled(10, 0)),
      Difficulty.medium,
    );
    expect(
      DifficultyEngine.recommend(Difficulty.medium, List.filled(10, 4)),
      Difficulty.easy,
    );
    expect(
      DifficultyEngine.recommend(Difficulty.hard, List.filled(10, 0)),
      Difficulty.hard,
    );
  });
  test(
    'Scheduler avoids consecutive targets and all targets belong to the pool',
    () {
      final pool = [item('cat'), item('dog'), item('rabbit')];
      final scheduler = ItemScheduler(Random(12));
      String? previous;
      for (var i = 0; i < 100; i++) {
        final chosen = scheduler.next(pool, {'animals.cat': 4});
        expect(pool, contains(chosen));
        expect(chosen.id, isNot(previous));
        previous = chosen.id;
      }
    },
  );
  test('Sensitive sound and receptive answers map to gentler settings', () {
    final result = SurveyMapper.map({
      'sound': 0,
      'receptive': 0,
      'focus': 0,
      'motor': 0,
    });
    expect(result.celebration, 'off');
    expect(result.introduction, true);
    expect(result.stages, 3);
    expect(result.tapAlternative, true);
  });
  test(
    'Content has the approved free cards (Learn + two games per theme) and unique IDs',
    () async {
      final repo = await ContentRepository.load();
      expect(repo.freeGames, {
        'animals_G02', 'animals_G01', 'animals_G10', //
        'produce_G02', 'produce_G01', 'produce_G14', //
        'food_G02', 'food_G01', 'food_G14', //
        'vehicles_G02', 'vehicles_G01', 'vehicles_G10', //
        'colors_G02', 'colors_G01', 'colors_G14', //
        'shapes_G02', 'shapes_G01', 'shapes_G14', //
        'numbers_G02', 'numbers_G35', 'numbers_G10', //
        'emotions_G02', 'emotions_G01', 'emotions_G14', //
        'body_G02', 'body_G01', 'body_G14', //
        'home_G02', 'home_G01', 'home_G14',
      });
      expect(repo.items.map((i) => i.id).toSet().length, repo.items.length);
      for (final theme in repo.themes) {
        expect(repo.items.any((i) => i.id == theme.hero), true);
        for (final game in theme.games) {
          expect(repo.games.any((g) => g.id == game), true);
        }
      }
    },
  );
  test(
    'Targets are present once and stale audio completion cannot start an old round',
    () async {
      final repo = ContentRepository(
        [],
        [item('cat'), item('dog'), item('rabbit')],
        [],
        {},
      );
      final prompts = <Completer<void>>[];
      final c = RoundController(
        content: repo,
        themeId: 'animals',
        gameId: 'G01',
        difficulty: Difficulty.easy,
        struggle: {},
        saveTrial: (_) async {},
        playPrompt: (_) {
          final p = Completer<void>();
          prompts.add(p);
          return p.future;
        },
      );
      c.start();
      expect(c.spec!.choices.where((i) => i.id == c.spec!.target.id).length, 1);
      expect(c.spec!.choices.map((i) => i.id).toSet().length, 2);
      c.start();
      prompts.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(c.phase, RoundPhase.preparing);
      c.dispose();
      prompts.last.complete();
      await Future<void>.delayed(Duration.zero);
    },
  );
}
