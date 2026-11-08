// Run explicitly: flutter test tools/color_swatches_shot_test.dart --update-goldens
// All colour cards side by side with their names (artifacts/claude/colors/).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  testWidgets('colour swatches', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader('Nunito')
            ..addFont(rootBundle.load('assets/fonts/Nunito.ttf')))
          .load();
    });
    final content = (await tester.runAsync(ContentRepository.load))!;
    final colors = content.items.where((x) => x.theme == 'colors').toList();
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1800, 900);
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: segTheme(),
          home: Scaffold(
            backgroundColor: SegColors.canvas,
            body: GridView.count(
              crossAxisCount: 8,
              padding: const EdgeInsets.all(16),
              children: [
                for (final c in colors)
                  Column(
                    children: [
                      Expanded(child: ItemVisual(c)),
                      Text(c.name('tr'), style: SegText.label),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/colors/swatches.png'),
    );
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
