// Run explicitly: flutter test tools/basket_shot_test.dart --update-goldens
// Renders the basket (G23) and group (G04) games at three sizes.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  testWidgets('basket shots', (tester) async {
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
      await s.entitlement.confirmStoreState(true);
      await s.createProfile('Ada', 'cat', {});
      return s;
    }))!;
    state
      ..locale = 'tr'
      ..sound = false
      ..introduction = false
      ..hintSeconds = 0;
    state.audio.enabled = false;
    for (final (name, size, dpr) in const [
      ('phone-1080x2400', Size(2400, 1080), 2.625),
      ('phone-720p', Size(1280, 720), 2.0),
      ('tablet-10in', Size(2560, 1600), 2.0),
    ]) {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = size;
      for (final (theme, game, tier) in const [
        ('vehicles', 'G23', Difficulty.medium),
        ('animals', 'G23', Difficulty.hard),
        ('animals', 'G04', Difficulty.medium),
      ]) {
        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: segTheme(),
              locale: const Locale('tr'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: GameScreen(
                key: ValueKey('$name$theme$game'),
                state: state,
                themeId: theme,
                gameId: game,
                difficulty: tier,
              ),
            ),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)),
          );
          await tester.pump(const Duration(milliseconds: 300));
        }
        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile(
            '../artifacts/claude/r35/after-$game-$theme-$name.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      }
    }
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
