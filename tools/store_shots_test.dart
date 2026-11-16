// Run explicitly: flutter test tools/store_shots_test.dart --update-goldens
// Raw landscape screens (TR+EN) for the Play store images.
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
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/stories/story_screens.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  testWidgets('store shots', (tester) async {
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
    for (final locale in ['tr', 'en']) {
      final state = (await tester.runAsync(() async {
        final s = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await s.load();
        await s.createProfile(locale == 'tr' ? 'Deniz' : 'Ella', 'cat', {});
        s.audio.enabled = false;
        s.sound = false;
        s.introduction = false;
        s.hintSeconds = 0;
        s.entitlement
          ..storeActive = true
          ..lastConfirmedAt = DateTime.now();
        return s;
      }))!;
      state.locale = locale;
      Future<void> show(Widget home) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: segTheme(),
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: home,
            ),
          ),
        );
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)),
          );
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      Future<void> shot(String name) => expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/store-shots/raw/$locale-$name.png'),
      );

      await show(HomeScreen(state: state));
      await shot('01-home');
      for (final (name, theme, game, tier) in [
        ('02-find', 'animals', 'G01', Difficulty.easy),
        ('03-count', 'numbers', 'G33', Difficulty.easy),
        ('04-colors', 'colors', 'G42', Difficulty.medium),
        ('05-shapes', 'shapes', 'G43', Difficulty.medium),
        ('06-feelings', 'emotions', 'G44', Difficulty.medium),
        ('07-body', 'body', 'G47', Difficulty.easy),
        ('08-basket', 'animals', 'G23', Difficulty.easy),
        ('09-learn', 'produce', 'G02', Difficulty.easy),
      ]) {
        await show(
          GameScreen(
            key: ValueKey('$locale-$name'),
            state: state,
            themeId: theme,
            gameId: game,
            difficulty: tier,
          ),
        );
        await shot(name);
      }
      await show(StoryShelfScreen(state: state));
      await shot('10-stories');
      await show(StoryPlayerScreen(state: state, story: state.content.story('teeth')!));
      await shot('11-story');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      state.dispose();
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
