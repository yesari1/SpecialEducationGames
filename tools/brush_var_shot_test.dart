// Run explicitly: flutter test tools/nov16_shot_test.dart --update-goldens
// Plays the reworked games a few steps and renders them (Turkish, phone
// landscape) into artifacts/claude/brush-var/.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/stories/story_screens.dart';
import 'package:special_education_games/features/game/widgets/scene_game_view.dart';
import 'package:special_education_games/features/park/coloring_screen.dart';
import 'package:special_education_games/features/park/puzzle_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  testWidgets('reworked games', (tester) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
    });
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(2424, 1080);

    Future<AppState> newState(String gender) async {
      final state = (await tester.runAsync(() async {
        final s = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await s.load();
        await s.createProfile('Deniz', 'cat', {'gender': gender});
        s.entitlement
          ..storeActive = true
          ..lastConfirmedAt = DateTime.now();
        return s;
      }))!;
      state
        ..locale = 'tr'
        ..introduction = false
        ..hintSeconds = 0;
      state.audio.enabled = false;
      return state;
    }

    Future<void> settle([int frames = 8]) async {
      for (var i = 0; i < frames; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Future<void> open(Widget home) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home,
          ),
        ),
      );
      await settle();
    }

    Future<void> shot(String name) => expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/brush-var/$name.png'),
    );

    Future<void> close() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    }

    /// Drags the asked piece of a scene game to its place, [steps] times.
    Future<void> playScene(String name, int steps, {int midShotAt = -1}) async {
      for (var n = 0; n < steps; n++) {
        final view = tester.widget<SceneGameView>(find.byType(SceneGameView));
        final round = view.spec.scene!;
        final placed = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              '${(w.key! as ValueKey).value}'.startsWith('scene-placed-'),
        );
        final index = round.steps.every((s) => s.stays)
            ? tester.widgetList(placed).length
            : n;
        if (index >= round.steps.length) break;
        final step = round.steps[index];
        final piece = find.byKey(ValueKey('scene-piece-${step.piece}'));
        if (piece.evaluate().isEmpty) break;
        final stage = tester.getRect(find.byKey(const ValueKey('scene-stage')));
        final to = Offset(
          stage.left + (step.zone.x + step.zone.w / 2) * stage.width + 40,
          stage.top + (step.zone.y + step.zone.h / 2) * stage.height - 30,
        );
        final gesture = await tester.startGesture(tester.getCenter(piece));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveBy(const Offset(-30, -10));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(to);
        await tester.pump(const Duration(milliseconds: 50));
        if (n == midShotAt) await shot('$name-carried');
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 200));
        if (n == midShotAt) await shot('$name-flying');
        await settle(4);
      }
    }


    // Tooth brushing: the brush is held by its handle, close to the mouth;
    // scrubbing leaves foam and the stains fade.
    for (final gender in ['girl']) {
      final state = await newState(gender);
      await open(
        GameScreen(
          state: state,
          themeId: 'cleaning',
          gameId: 'G60',
          difficulty: Difficulty.medium,
        ),
      );
      await settle(8);
      await shot('G60-$gender-0-start');
      final tool = tester.getCenter(find.byKey(const ValueKey('scene-tool')));
      final stage = tester.getRect(find.byKey(const ValueKey('scene-stage')));
      final g = await tester.startGesture(tool);
      await tester.pump(const Duration(milliseconds: 50));
      // The finger goes below-left of the mouth so the brush head is on it.
      final side = stage.height * .36 * 1.5;
      final head = Offset(-side * 1.3 * .62, side * 1.3 * .03);
      final mouth = Offset(stage.center.dx, stage.top + stage.height * .55);
      await g.moveTo(mouth - head);
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(Offset(i.isEven ? 90 : -90, 0));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await shot('G60-$gender-1-brushing');
      for (var i = 0; i < 120; i++) {
        await g.moveBy(Offset(i.isEven ? 140 : -140, (i % 10 - 5) * 9.0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await settle(3);
      await shot('G60-$gender-2-after');
      await close();
      state.dispose();
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
