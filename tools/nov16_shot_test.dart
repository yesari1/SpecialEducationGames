// Run explicitly: flutter test tools/nov16_shot_test.dart --update-goldens
// Plays the reworked games a few steps and renders them (Turkish, phone
// landscape) into artifacts/claude/nov16-shots/.
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
      matchesGoldenFile('../artifacts/claude/nov16-shots/$name.png'),
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


    // Fruit salad: three fruits in, stirred, two pieces of each in the bowl.
    for (final gender in ['boy', 'girl']) {
      final state = await newState(gender);
      await open(
        GameScreen(
          state: state,
          themeId: 'kitchen',
          gameId: 'G65',
          difficulty: Difficulty.medium,
        ),
      );
      await settle(12);
      await playScene('G65', 3);
      await shot('G65-$gender-1-in');
      final stage = tester.getRect(find.byKey(const ValueKey('scene-stage')));
      final g = await tester.startGesture(stage.center);
      for (var i = 0; i < 80; i++) {
        await g.moveBy(Offset.fromDirection(i * .5, 40));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump(const Duration(milliseconds: 300));
      await shot('G65-$gender-2-mixed');
      await close();
      state.dispose();
    }

    // "Bugün Ne Giysek?": the result in the middle, the choices gone.
    for (final gender in ['boy', 'girl']) {
      final state = await newState(gender);
      await open(
        GameScreen(
          state: state,
          themeId: 'clothes',
          gameId: 'G64',
          difficulty: Difficulty.easy,
        ),
      );
      await settle(6);
      await shot('G64-$gender-0-start');
      final screen = tester.state<State<GameScreen>>(find.byType(GameScreen));
      final target = (screen as dynamic).controller.spec.target.id as String;
      final card = find.byWidgetPredicate(
        (w) => w is ChoiceCard && w.item.id == target,
      );
      await tester.tap(card.first, warnIfMissed: false);
      await settle(3);
      await shot('G64-$gender-1-result');
      await close();
      state.dispose();
    }

    // Story choices for a girl's profile show Ayşe.
    for (final id in ['teeth', 'angry']) {
      final g = await newState('girl');
      final story = g.content.stories.firstWhere((x) => x.id == id);
      await open(StoryPlayerScreen(state: g, story: story));
      await settle(4);
      for (var i = 0; i < 6; i++) {
        if (find.byKey(const ValueKey('story-choice-0')).evaluate().isNotEmpty) {
          break;
        }
        final next = find.byKey(const ValueKey('story-next'));
        if (next.evaluate().isEmpty) break;
        await tester.tap(next, warnIfMissed: false);
        await settle(4);
      }
      await shot('story-$id-girl-choices');
      await close();
      g.dispose();
    }

    // The home Learn shelf for a girl's profile shows Ayşe on "Vücudumuz".
    final girl = await newState('girl');
    girl.homeTab = HomeTab.learn;
    await open(HomeScreen(state: girl));
    await settle(4);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('theme-cover-body')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(2);
    await shot('home-learn-girl');
    await close();
    girl.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
