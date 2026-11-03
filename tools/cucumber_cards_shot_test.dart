// Run explicitly:
//   flutter test tools/cucumber_cards_shot_test.dart
// Renders the cucumber next to other photos as real choice cards to
// artifacts/claude/cucumber-cards/cards.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  testWidgets('cucumber cards', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'Nunito',
      )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    });
    final content = (await tester.runAsync(ContentRepository.load))!;
    const ids = [
      'produce.apple', 'produce.lemon', 'produce.apricot', 'produce.cucumber',
      'produce.zucchini', 'vehicles.airplane', 'vehicles.car',
      'vehicles.helicopter', 'animals.cat', 'animals.dog', 'animals.turtle',
    ];
    final items = [
      for (final id in ids) content.items.firstWhere((x) => x.id == id),
    ];
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(2400, 1100);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: segTheme(),
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFFFDF3EA),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: 200,
                      height: 230,
                      child: ChoiceCard(
                        item: item,
                        locale: 'tr',
                        state: ChoiceCardState.idle,
                        animate: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'artifacts/claude/cucumber-cards/cards.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
