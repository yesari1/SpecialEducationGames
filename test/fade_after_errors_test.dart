import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/round_controller.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  for (final threshold in [1, 2, 3]) {
    testWidgets(
      'Full error support begins at error $threshold and keeps wrong choices blocked',
      (tester) async {
        final controller = RoundController(
          content: content,
          themeId: 'animals',
          gameId: 'G01',
          difficulty: Difficulty.easy,
          struggle: {},
          saveTrial: (_) async {},
          playPrompt: (_) async {},
          hintSeconds: 0,
          fadeAfterErrors: threshold,
        );
        controller.start();
        await tester.pump();
        final wrong = controller.spec!.choices.firstWhere(
          (x) => x.id != controller.spec!.target.id,
        );
        for (var error = 1; error <= 3; error++) {
          await controller.choose(wrong);
          expect(controller.hint, error >= threshold ? 4 : 2);
          expect(controller.wrongCount, error.clamp(0, threshold));
          expect(
            HintPolicy.afterWrong(error, fadeAfterErrors: threshold),
            error >= threshold ? 4 : 2,
          );
        }
        controller.dispose();
      },
    );

    testWidgets('Parent fade-off overrides remote threshold $threshold', (
      tester,
    ) async {
      final controller = RoundController(
        content: content,
        themeId: 'animals',
        gameId: 'G01',
        difficulty: Difficulty.easy,
        struggle: {},
        saveTrial: (_) async {},
        playPrompt: (_) async {},
        hintSeconds: 0,
        fadeWrongChoices: false,
        fadeAfterErrors: threshold,
      );
      controller.start();
      await tester.pump();
      final wrong = controller.spec!.choices.firstWhere(
        (x) => x.id != controller.spec!.target.id,
      );
      for (var error = 1; error <= 3; error++) {
        await controller.choose(wrong);
        expect(controller.hint, 2);
        expect(controller.maxHint, 2);
        expect(controller.wrongCount, error);
      }
      controller.dispose();
    });
  }

  testWidgets(
    'GameScreen snapshots threshold once; next game receives changed configuration',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final state = AppState(
        content,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await state.load();
      await state.createProfile('Test', 'cat', {});
      state.audio.enabled = false;
      state.introduction = false;
      state.hintSeconds = 0;
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
        fadeAfterErrors: 3,
      );

      Future<void> mount(String key) async {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              key: ValueKey(key),
              state: state,
              themeId: 'animals',
              gameId: 'G01',
              difficulty: Difficulty.easy,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump();
      }

      RoundChoicesView view() =>
          tester.widget<RoundChoicesView>(find.byType(RoundChoicesView));
      await mount('first');
      final wrong = view().spec.choices.firstWhere(
        (x) => x.id != view().spec.target.id,
      );
      view().callbacks.onSelect(wrong);
      await tester.pump();
      expect(view().hint.level, 2);
      // Even an explicit rebuild with a new config cannot alter this controller.
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
        fadeAfterErrors: 1,
      );
      await mount('first');
      view().callbacks.onSelect(wrong);
      await tester.pump();
      expect(view().hint.wrongCount, 2);
      expect(view().hint.level, 2);
      view().callbacks.onSelect(wrong);
      await tester.pump();
      expect(view().hint.level, 4);
      await mount('second');
      final nextWrong = view().spec.choices.firstWhere(
        (x) => x.id != view().spec.target.id,
      );
      view().callbacks.onSelect(nextWrong);
      await tester.pump();
      expect(view().hint.level, 4);
      expect(view().hint.wrongCount, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await state.db.select(state.db.gameSessions).get();
      state.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
