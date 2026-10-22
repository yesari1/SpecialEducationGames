// Run explicitly: flutter test tools/r49_hop_frames_test.dart --update-goldens
// Frames of the basket (G23) hop after a correct tap, to artifacts/claude/r49/.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

void main() {
  testWidgets('hop frames', (tester) async {
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
    final content = (await tester.runAsync(ContentRepository.load))!;
    final state = (await tester.runAsync(() async {
      final s = AppState(
        content,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      await s.createProfile('Test', 'cat', {});
      return s;
    }))!;
    state.audio.enabled = false;
    state.introduction = false;
    state.hintSeconds = 0;
    state.entitlement.lifetimeOwned = true;
    state.configuration = AppConfiguration(freeGames: content.freeGames);
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(2400, 1080);
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: segTheme(),
          home: GameScreen(
            state: state,
            themeId: 'produce',
            gameId: 'G23',
            difficulty: Difficulty.easy,
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump(const Duration(milliseconds: 250));
    }
    final view = tester.widget<RoundChoicesView>(find.byType(RoundChoicesView));
    final target = view.spec.target.id;
    final card = find.byWidgetPredicate(
      (w) => w is ChoiceCard && w.item.id == target,
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/r49/hop-0-before.png'),
    );
    await tester.tap(card.first, warnIfMissed: false);
    var elapsed = 0;
    for (final ms in [16, 50, 120, 250, 400, 600, 800]) {
      await tester.pump(Duration(milliseconds: ms - elapsed));
      elapsed = ms;
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/r49/hop-$ms.png'),
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
