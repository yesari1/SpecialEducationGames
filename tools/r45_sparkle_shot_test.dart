// Run explicitly:
//   flutter test tools/r45_sparkle_shot_test.dart --update-goldens
// Frames of the correct-answer sparkle burst to artifacts/claude/r45/.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  testWidgets('sparkle frames', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'Nunito',
      )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    });
    final content = (await tester.runAsync(ContentRepository.load))!;
    final item = content.items.firstWhere((x) => x.id == 'produce.apple');
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 640);
    Widget card(ChoiceCardState state) => RepaintBoundary(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: segTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 240,
              child: ChoiceCard(item: item, locale: 'tr', state: state),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(card(ChoiceCardState.idle));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpWidget(card(ChoiceCardState.correct));
    for (final ms in [120, 140, 200]) {
      await tester.pump(Duration(milliseconds: ms));
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/r45/sparkle-$ms.png'),
      );
    }
    await tester.pump(const Duration(seconds: 2));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
