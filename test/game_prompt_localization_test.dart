import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/round_spec.dart';
import 'package:special_education_games/features/game/templates/game_template.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async => content = await ContentRepository.load());

  testWidgets('Fixed prompts use the selected ARB copy and preserve dynamics', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);

    const cases = [
      (
        theme: 'animals',
        game: 'G01',
        difficulty: Difficulty.medium,
        tr: '',
        en: '',
      ),
      (
        theme: 'animals',
        game: 'G04',
        difficulty: Difficulty.medium,
        tr: 'Bu hangi grupta?',
        en: 'Which group does this belong to?',
      ),
      (
        theme: 'numbers',
        game: 'G33',
        difficulty: Difficulty.medium,
        tr: 'Kaç tane var?',
        en: 'How many are there?',
      ),
      (
        theme: 'numbers',
        game: 'G36',
        difficulty: Difficulty.medium,
        tr: 'Hangisi daha çok?',
        en: 'Which has more?',
      ),
      (
        theme: 'animals',
        game: 'G14',
        difficulty: Difficulty.medium,
        tr: 'Aynısını bul',
        en: 'Find the match',
      ),
      (
        theme: 'numbers',
        game: 'G35',
        difficulty: Difficulty.medium,
        tr: 'Sıradaki sayı hangisi?',
        en: 'Which number comes next?',
      ),
    ];

    for (final locale in ['tr', 'en']) {
      for (final entry in cases) {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final state = AppState(content, db, AudioService());
        await state.load();
        await state.createProfile('Test', 'cat', {});
        state.locale = locale;
        state.sound = false;
        state.audio.enabled = false;
        state.introduction = false;
        state.hintSeconds = 0;
        // Medium and Hard cards need Premium.
        state.entitlement.lifetimeOwned = true;
        state.configuration = AppConfiguration(
          freeGames: {
            ...content.freeGames,
            'animals_G01',
            'animals_G04',
            'numbers_G33',
            'numbers_G36',
            'animals_G14',
            'numbers_G35',
          },
          choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: segTheme(),
            home: GameScreen(
              state: state,
              themeId: entry.theme,
              gameId: entry.game,
              difficulty: entry.difficulty,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));

        expect(find.byType(RoundChoicesView), findsOneWidget);
        final round = tester.widget<RoundChoicesView>(
          find.byType(RoundChoicesView),
        );
        final dynamicPrompt = entry.game == 'G01';
        expect(
          round.spec.promptKey,
          dynamicPrompt ? isNull : isNotNull,
          reason: '$locale ${entry.game} prompt key',
        );
        final prompt = dynamicPrompt
            ? (locale == 'tr' ? round.spec.promptTr : round.spec.promptEn)
            : (locale == 'tr' ? entry.tr : entry.en);
        expect(prompt, isNotEmpty);
        expect(
          find.text(prompt),
          findsOneWidget,
          reason: '$locale ${entry.game} ${entry.difficulty.name}',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
        await db.close();
      }
    }

    // Build hard G36 through the real template directly. The production game
    // gates hard mode behind entitlement, so this validates copy without
    // inventing a premium entitlement in the widget test.
    final hardRound = TemplateRegistry.resolve('G36').buildRound(
      ModeContext(
        content: content,
        themeId: 'numbers',
        gameId: 'G36',
        locale: 'en',
        difficulty: Difficulty.hard,
        scheduler: ItemScheduler(Random(36)),
        struggle: const {},
        choiceCount: Difficulty.hard.choices,
      ),
    );
    expect(hardRound.promptKey, GamePromptKey.compareNumbers);
    expect(hardRound.promptTr, 'Bu sayıları karşılaştır');
    expect(hardRound.promptEn, 'Compare these numbers');

    final hardSequence = TemplateRegistry.resolve('G35').buildRound(
      ModeContext(
        content: content,
        themeId: 'numbers',
        gameId: 'G35',
        locale: 'en',
        difficulty: Difficulty.hard,
        scheduler: ItemScheduler(Random(35)),
        struggle: const {},
        choiceCount: Difficulty.hard.choices,
      ),
    );
    expect(hardSequence.promptKey, GamePromptKey.sequenceMissing);
    expect(hardSequence.promptTr, 'Eksik sayı hangisi?');
    expect(hardSequence.promptEn, 'Which number is missing?');

    for (final (theme, locale, expectedKey, tr, en) in [
      (
        'numbers',
        'tr',
        GamePromptKey.listenForNumber,
        'Dinle. Hangi sayı?',
        'Listen. Which number?',
      ),
      (
        'vehicles',
        'tr',
        GamePromptKey.listenForSoundSource,
        'Dinle. Ses kimden geliyor?',
        'Listen. What makes this sound?',
      ),
    ]) {
      final listenRound = TemplateRegistry.resolve('G10').buildRound(
        ModeContext(
          content: content,
          themeId: theme,
          gameId: 'G10',
          locale: locale,
          difficulty: Difficulty.medium,
          scheduler: ItemScheduler(Random(theme.hashCode)),
          struggle: const {},
          choiceCount: Difficulty.medium.choices,
        ),
      );
      expect(listenRound.promptKey, expectedKey);
      expect(listenRound.promptTr, tr);
      expect(listenRound.promptEn, en);
    }
  });
}
