// Run explicitly: flutter test tools/new_games_shot_test.dart --update-goldens
// Renders the opening of every new game in Turkish, phone landscape, into
// artifacts/claude/new-games/.
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
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  testWidgets('new games', (tester) async {
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
      await s.createProfile('Deniz', 'cat', {});
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

    Future<void> shot(Widget home, String name) async {
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
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/new-games/$name.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    }

    state.homeTab = HomeTab.learn;
    state.homeLearnOffset = 295;
    await shot(HomeScreen(state: state), '00-gunluk-isler');
    for (final (theme, game) in const [
      ('cleaning', 'G02'),
      ('cleaning', 'G60'),
      ('cleaning', 'G61'),
      ('cleaning', 'G62'),
      ('clothes', 'G63'),
      ('clothes', 'G64'),
      ('clothes', 'G49'),
      ('kitchen', 'G65'),
      ('kitchen', 'G66'),
      ('kitchen', 'G67'),
      ('jobs', 'G68'),
      ('jobs', 'G69'),
      ('jobs', 'G70'),
      ('nature', 'G71'),
      ('nature', 'G72'),
      ('nature', 'G73'),
    ]) {
      await shot(
        GameScreen(
          state: state,
          themeId: theme,
          gameId: game,
          difficulty: Difficulty.medium,
        ),
        '$theme-$game',
      );
    }
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
