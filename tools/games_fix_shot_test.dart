// Run explicitly: flutter test tools/games_fix_shot_test.dart --update-goldens
// Show It on Ali (question beside a big picture), Paint in mid-stroke, the
// story hand hint and the narrated right choice (artifacts/claude/games-fix/).
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/paint_view.dart';
import 'package:special_education_games/features/stories/story_screens.dart';

void main() {
  testWidgets('shots', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
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
    final state = (await tester.runAsync(() async {
      final s = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      await s.createProfile('Ada', 'cat', {});
      s.audio.enabled = false;
      s.introduction = false;
      s.hintSeconds = 0;
      s.entitlement
        ..storeActive = true
        ..lastConfirmedAt = DateTime.now();
      return s;
    }))!;
    state.locale = 'tr';

    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Future<void> show(Widget home) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            home: home,
          ),
        ),
      );
      await settle();
    }

    Future<void> shot(String name) => expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/games-fix/$name.png'),
    );

    for (final (name, tier) in [
      ('ali-1', Difficulty.easy),
      ('ali-2', Difficulty.medium),
      ('ali-3', Difficulty.hard),
    ]) {
      await show(
        GameScreen(
          key: ValueKey(name),
          state: state,
          themeId: 'body',
          gameId: 'G47',
          difficulty: tier,
        ),
      );
      await shot(name);
    }

    await show(
      GameScreen(
        key: const ValueKey('paint'),
        state: state,
        themeId: 'colors',
        gameId: 'G42',
        difficulty: Difficulty.medium,
      ),
    );
    final paint = tester.widget<PaintView>(find.byType(PaintView));
    paint.callbacks.onSelect(paint.spec.target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 620));
    await shot('paint-mid');
    await tester.pump(const Duration(seconds: 1));
    await shot('paint-done');

    final doctor = state.content.story('doctor')!;
    await show(StoryPlayerScreen(state: state, story: doctor));
    await tester.pump(const Duration(seconds: 6));
    await settle();
    await shot('story-hand');
    await tester.tap(find.byKey(const ValueKey('story-page-area')));
    await settle();
    await tester.tap(find.byKey(const ValueKey('story-page-area')));
    await settle();
    final right = doctor.pages[2].choices.indexWhere((c) => c.correct);
    await tester.tap(find.byKey(ValueKey('story-choice-$right')));
    await tester.pump(const Duration(seconds: 1));
    await settle();
    await shot('story-right');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    state.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
