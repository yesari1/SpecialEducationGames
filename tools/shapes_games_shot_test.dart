// Run explicitly: flutter test tools/shapes_games_shot_test.dart --update-goldens
// Shapes: Find the Shadow (G15) and Count and Choose (G33) with the drawn
// shapes. Shots to artifacts/claude/shapes-games/.
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

void main() {
  testWidgets('shapes game shots', (tester) async {
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
    for (final (theme, game, tier) in [
      ('shapes', 'G15', Difficulty.easy),
      ('shapes', 'G15', Difficulty.medium),
      ('shapes', 'G15', Difficulty.hard),
      ('animals', 'G15', Difficulty.hard),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            home: GameScreen(
              key: ValueKey('$theme-$game-$tier'),
              state: state,
              themeId: theme,
              gameId: game,
              difficulty: tier,
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(
          '../artifacts/claude/shapes-games/$theme-$game-${tier.name}.png',
        ),
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    state.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
