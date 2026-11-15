// Run explicitly: flutter test tools/fix_nov12_games_shot_test.dart --update-goldens
// Plays the reworked games a few steps and renders them (Turkish, phone
// landscape) into artifacts/claude/fix-nov12/games/.
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
import 'package:special_education_games/features/game/game_screen.dart';
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
      matchesGoldenFile('../artifacts/claude/fix-nov12/games/$name.png'),
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

    for (final gender in ['boy', 'girl']) {
      final state = await newState(gender);
      await open(
        GameScreen(
          state: state,
          themeId: 'clothes',
          gameId: 'G63',
          difficulty: Difficulty.easy,
        ),
      );
      await shot('G63-$gender-0-start');
      await playScene('G63-$gender', 2, midShotAt: 1);
      await shot('G63-$gender-2-two-on');
      await playScene('G63-$gender', 4);
      await shot('G63-$gender-3-end');
      await close();
      await open(
        GameScreen(
          state: state,
          themeId: 'clothes',
          gameId: 'G63',
          difficulty: Difficulty.hard,
        ),
      );
      await shot('G63-$gender-hard-start');
      await close();
      await open(
        GameScreen(
          state: state,
          themeId: 'clothes',
          gameId: 'G64',
          difficulty: Difficulty.easy,
        ),
      );
      await shot('G64-$gender-start');
      await close();
      state.dispose();
    }

    final state = await newState('boy');
    for (final (theme, game, tier, steps) in const [
      ('kitchen', 'G65', Difficulty.medium, 3),
      ('kitchen', 'G66', Difficulty.easy, 2),
      ('kitchen', 'G66', Difficulty.hard, 3),
      ('cleaning', 'G60', Difficulty.easy, 0),
      ('nature', 'G71', Difficulty.easy, 1),
    ]) {
      await open(
        GameScreen(
          state: state,
          themeId: theme,
          gameId: game,
          difficulty: tier,
        ),
      );
      final name = '$game-${tier.name}';
      await shot('$name-0-start');
      if (steps > 0) {
        await playScene(name, steps, midShotAt: 0);
        await shot('$name-1-after-$steps');
      }
      await close();
    }

    // Pair games: the right card brings the result picture up.
    for (final (theme, game) in const [
      ('jobs', 'G68'),
      ('jobs', 'G69'),
      ('cleaning', 'G62'),
      ('clothes', 'G64'),
    ]) {
      await open(
        GameScreen(
          state: state,
          themeId: theme,
          gameId: game,
          difficulty: Difficulty.easy,
        ),
      );
      await shot('$game-0-start');
      final screen = tester.state<State<GameScreen>>(find.byType(GameScreen));
      final target = (screen as dynamic).controller.spec.target.id as String;
      final card = find.byWidgetPredicate(
        (w) => w is ChoiceCard && w.item.id == target,
      );
      if (card.evaluate().isNotEmpty) {
        await tester.tap(card.first, warnIfMissed: false);
        await settle(5);
        await shot('$game-1-result');
      }
      await close();
    }

    for (final level in Difficulty.values) {
      await open(PuzzleScreen(state: state));
      if (level != Difficulty.easy) {
        await tester.tap(find.text(level == Difficulty.medium ? '6' : '9'));
        await settle(3);
      }
      if (level == Difficulty.easy) await shot('puzzle-shelf');
      // Pick the first picture of the shelf.
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              '${(w.key! as ValueKey).value}'.startsWith('puzzle-pick-'),
        ).first,
      );
      await settle(3);
      await shot('puzzle-${level.name}-0');
      // Bring the first two pieces home.
      for (final i in [0, 1]) {
        final piece = find.byKey(ValueKey('puzzle-piece-$i'));
        final slot = find.byKey(ValueKey('puzzle-slot-$i'));
        final gesture = await tester.startGesture(tester.getCenter(piece));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveBy(const Offset(-20, 0));
        await gesture.moveTo(tester.getCenter(slot) + const Offset(18, -12));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await settle(3);
      }
      await shot('puzzle-${level.name}-1');
      await close();
    }

    // Music: the piano game and free play; the colouring shelf and board.
    for (final (game, tier) in const [
      ('G75', Difficulty.easy),
      ('G75', Difficulty.hard),
      ('G76', Difficulty.easy),
    ]) {
      await open(
        GameScreen(
          state: state,
          themeId: 'music',
          gameId: game,
          difficulty: tier,
        ),
      );
      await settle(6);
      await shot('$game-${tier.name}');
      await close();
    }
    await open(ColoringScreen(state: state));
    await shot('coloring-shelf');
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key! as ValueKey).value}'.startsWith('coloring-page-'),
      ).first,
    );
    await settle(4);
    await tester.tap(find.byKey(const ValueKey('coloring-paint-5')));
    await settle(2);
    await shot('coloring-board');
    await close();

    // A girl's profile: the same games show and name Ayşe.
    final girl = await newState('girl');
    for (final (theme, game) in const [
      ('cleaning', 'G60'),
      ('cleaning', 'G62'),
      ('emotions', 'G44'),
      ('body', 'G47'),
      ('jobs', 'G69'),
    ]) {
      await open(
        GameScreen(
          state: girl,
          themeId: theme,
          gameId: game,
          difficulty: Difficulty.easy,
        ),
      );
      await shot('girl-$game');
      await close();
    }
    girl.dispose();
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
