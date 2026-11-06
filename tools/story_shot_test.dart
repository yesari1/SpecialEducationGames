// Run explicitly: flutter test tools/story_shot_test.dart --update-goldens
// Renders the Stories card, shelf and every kind of story page (TR), on a
// Pixel 9a-sized and a small landscape phone, into artifacts/claude/stories/.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/stories/story_screens.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  testWidgets('story shots', (tester) async {
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
    final state = (await tester.runAsync(() async {
      final s = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      await s.createProfile('Deniz', 'cat', {});
      return s;
    }))!;
    state.locale = 'tr';
    state.sound = false;
    state.audio.enabled = false;

    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
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
      matchesGoldenFile('../artifacts/claude/stories/$name.png'),
    );

    final teeth = state.content.story('teeth')!;
    final angry = state.content.story('angry')!;
    for (final (size, ratio, tag) in [
      (const Size(2424, 1080), 2.625, 'pixel9a'),
      (const Size(1280, 720), 2.0, 'small'),
    ]) {
      tester.view.devicePixelRatio = ratio;
      tester.view.physicalSize = size;
      await show(HomeScreen(state: state));
      await shot('$tag-1-home');
      await show(StoryShelfScreen(state: state));
      await shot('$tag-2-shelf');

      await show(StoryPlayerScreen(state: state, story: teeth));
      await shot('$tag-3-page');
      await tester.tap(find.byKey(const ValueKey('story-next')));
      await settle();
      await tester.tap(find.byKey(const ValueKey('story-next')));
      await settle();
      await shot('$tag-4-question');

      await show(StoryPlayerScreen(state: state, story: angry));
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('story-next')));
        await settle();
      }
      await shot('$tag-5-feelings');
      await tester.tap(find.byKey(const ValueKey('story-choice-0')));
      await settle();
      await tester.tap(find.byKey(const ValueKey('story-next')));
      await settle();
      await tester.tap(find.byKey(const ValueKey('story-choice-0')));
      await tester.pump(const Duration(milliseconds: 400));
      await settle();
      await shot('$tag-6-result');
      await tester.pump(const Duration(seconds: 6));
      await settle();
      await shot('$tag-7-retry');
      await tester.tap(find.byKey(const ValueKey('story-choice-1')));
      await tester.pump(const Duration(seconds: 2));
      await settle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('story-next')));
        await settle();
      }
      await shot('$tag-8-end');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
