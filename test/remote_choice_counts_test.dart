import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/item_performance.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/round_controller.dart';
import 'package:special_education_games/features/game/templates/game_template.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

ContentItem _item(
  String theme,
  String slug, {
  String? tag,
  bool withVerifiedPhotoPair = false,
}) {
  const photoPaths = ['test-fixture/photo-a.png', 'test-fixture/photo-b.png'];
  Map<String, dynamic> provenance(String path, String hashDigit) => {
    'path': path,
    'author': 'Synthetic test fixture (not a real photo attribution)',
    'source': 'test-fixture://g14/$hashDigit',
    'license': 'Test fixture only',
    'licenseUrl': 'test-fixture://license',
    'sha256': hashDigit.padLeft(64, '0'),
    'licenseVerified': true,
  };
  return ContentItem.fromJson({
    'id': '$theme.$slug',
    'theme': theme,
    'tier': 'easy',
    'name': {'tr': slug, 'en': slug},
    'images': withVerifiedPhotoPair ? photoPaths : ['test.png'],
    if (withVerifiedPhotoPair)
      'imageProvenance': {
        photoPaths[0]: provenance(photoPaths[0], '1'),
        photoPaths[1]: provenance(photoPaths[1], '2'),
      },
    'audio': {'tr': 'test.mp3'},
    'sfx': 'test.mp3',
    'tags': [?tag],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository realContent;
  setUpAll(() async => realContent = await ContentRepository.load());
  final repo = ContentRepository(
    [],
    [
      for (final group in ['evcil', 'ciftlik', 'vahsi', 'deniz'])
        _item(
          'animals',
          group,
          tag: group,
          withVerifiedPhotoPair: group == 'evcil',
        ),
      for (var number = 1; number <= 20; number++) _item('numbers', '$number'),
    ],
    [],
    {},
  );

  ModeContext context(String game, Difficulty tier, int? choices) =>
      ModeContext(
        content: repo,
        themeId: 'animals',
        gameId: game,
        difficulty: tier,
        scheduler: ItemScheduler(Random(42)),
        struggle: {},
        choiceCount: choices,
      );

  test(
    'Remote 2/2/3 choices apply across graded templates while default 2/3/4 remains',
    () {
      for (final tier in Difficulty.values) {
        for (final game in ['G01', 'G10', 'G14', 'G34', 'G04', 'G33', 'G35']) {
          for (final choiceCount in [
            null,
            [2, 2, 3][tier.index],
          ]) {
            final spec = TemplateRegistry.resolve(
              game,
            ).buildRound(context(game, tier, choiceCount));
            // Group games show at most three groups side by side.
            final expected = choiceCount ?? tier.choices;
            expect(
              spec.choices.length,
              game == 'G04' ? min(expected, 3) : expected,
              reason: '$game ${tier.name} $choiceCount',
            );
            expect(
              spec.choices.map((x) => x.id).toSet().length,
              spec.choices.length,
            );
            expect(spec.choices.where((x) => x.id == spec.target.id).length, 1);
            if (game == 'G14' && tier == Difficulty.hard) {
              expect(spec.target.id, 'animals.evcil');
              expect(spec.promptImagePath, isNotNull);
              expect(spec.correctChoiceImagePath, isNotNull);
              expect(spec.correctChoiceImagePath, isNot(spec.promptImagePath));
              expect(
                spec.target.verifiedPhotoPaths,
                containsAll([
                  spec.promptImagePath,
                  spec.correctChoiceImagePath,
                ]),
              );
            }
            if (game == 'G33') {
              expect(spec.count, inInclusiveRange(1, [3, 5, 10][tier.index]));
            }
            if (game == 'G35') {
              expect(spec.sequence.where((x) => x == '?').length, 1);
              expect(spec.sequence.length, 3);
              if (tier == Difficulty.hard) expect(spec.sequence[1], '?');
            }
          }
        }
      }
    },
  );

  test('G04 asked for four choices builds at most three groups (frog)', () {
    final pool = realContent
        .pool('animals', Difficulty.medium)
        .where((item) => item.images.isNotEmpty)
        .toList();
    final frogIndex = pool.indexWhere((item) => item.id == 'animals.frog');
    expect(frogIndex, greaterThanOrEqualTo(0));
    final seed = List<int>.generate(10000, (index) => index).firstWhere(
      (candidate) => Random(candidate).nextInt(pool.length) == frogIndex,
    );
    final spec = TemplateRegistry.resolve('G04').buildRound(
      ModeContext(
        content: realContent,
        themeId: 'animals',
        gameId: 'G04',
        difficulty: Difficulty.medium,
        scheduler: ItemScheduler(Random(seed)),
        struggle: const {},
        choiceCount: 4,
      ),
    );

    expect(spec.stimulus?.id, 'animals.frog');
    expect(spec.target.id, 'group.vahsi');
    expect(spec.choices, hasLength(3));
    expect(spec.choices.map((item) => item.id).toSet(), hasLength(3));
    expect(spec.choices, contains(spec.target));
  });

  test(
    'Comparison and exploratory templates retain task structure despite requested counts',
    () {
      for (final tier in Difficulty.values) {
        final compare = TemplateRegistry.resolve(
          'G36',
        ).buildRound(context('G36', tier, 4));
        expect(
          compare.choices.length,
          tier == Difficulty.hard ? 3 : tier.choices,
        );
        for (final game in ['G02', 'G55']) {
          final spec = TemplateRegistry.resolve(
            game,
          ).buildRound(context(game, tier, 4));
          expect(spec.choices.single.id, spec.target.id);
        }
      }
    },
  );

  testWidgets(
    'Support fading reduces configured 3 to 2; available pool caps and keeps target',
    (tester) async {
      RoundController build(
        ContentRepository content, {
        Map<String, ItemPerformance>? performance,
        int choices = 3,
      }) => RoundController(
        content: content,
        themeId: 'animals',
        gameId: 'G01',
        difficulty: Difficulty.hard,
        struggle: {},
        saveTrial: (_) async {},
        playPrompt: (_) async {},
        hintSeconds: 0,
        choiceCount: choices,
        performance: performance,
      );
      final reduced = build(
        repo,
        performance: {
          for (final item in repo.items)
            item.id: const ItemPerformance(fullSupportStreak: 2),
        },
      );
      reduced.start();
      await tester.pump();
      expect(reduced.choiceCount, 3);
      expect(reduced.spec!.choices.length, 2);
      expect(
        reduced.spec!.choices.any((x) => x.id == reduced.spec!.target.id),
        isTrue,
      );
      reduced.dispose();
      final small = ContentRepository(
        [],
        repo.items.where((x) => x.theme == 'animals').take(2).toList(),
        [],
        {},
      );
      final capped = build(small, choices: 4);
      capped.start();
      await tester.pump();
      expect(capped.spec!.choices.length, 2);
      expect(capped.spec!.choices.map((x) => x.id).toSet().length, 2);
      expect(
        capped.spec!.choices.any((x) => x.id == capped.spec!.target.id),
        isTrue,
      );
      capped.dispose();
    },
  );

  testWidgets(
    'GameScreen captures configured count; rebuilt controller changes only in next game',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final state = AppState(
        realContent,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await state.load();
      await state.createProfile('Local', 'cat', {});
      state.audio.enabled = false;
      state.introduction = false;
      state.hintSeconds = 0;
      state.configuration = AppConfiguration(
        freeGames: realContent.freeGames.toSet(),
        choiceCounts: const {'easy': 2, 'medium': 2, 'hard': 3},
      );
      Future<void> mount(String key) async {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: ValueKey(key),
              state: state,
              themeId: 'animals',
              gameId: 'G01',
              difficulty: Difficulty.medium,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
      }

      int choices() => tester
          .widget<RoundChoicesView>(find.byType(RoundChoicesView))
          .spec
          .choices
          .length;
      await mount('same');
      expect(choices(), 2);
      state.configuration = AppConfiguration(
        freeGames: realContent.freeGames.toSet(),
        choiceCounts: const {'easy': 4, 'medium': 4, 'hard': 4},
      );
      await mount('same');
      expect(choices(), 2);
      await mount('next');
      expect(choices(), 4);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await state.db.select(state.db.gameSessions).get();
      state.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
