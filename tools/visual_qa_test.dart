// Run explicitly with: flutter test tools/visual_qa_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  testWidgets('Render content cards against the app surface', (tester) async {
    const tier = String.fromEnvironment('QA_TIER', defaultValue: 'easy');
    const theme = String.fromEnvironment('QA_THEME', defaultValue: 'vehicles');
    const selected = String.fromEnvironment('QA_SLUGS');
    final selectedIds = selected.split(',').where((x) => x.isNotEmpty).toSet();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
    final repo = await ContentRepository.load();
    final items = repo.items
        .where(
          (x) =>
              x.theme == theme &&
              (tier == 'all' || x.tier == tier) &&
              x.images.isNotEmpty &&
              (selectedIds.isEmpty ||
                  selectedIds.contains(x.id.split('.').last)),
        )
        .toList();
    expect(items, isNotEmpty);
    tester.view.physicalSize = Size(
      1280,
      (items.length / 5).ceil() * 270.0 + 48,
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.count(
                crossAxisCount: 5,
                childAspectRatio: .95,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                children: items
                    .map(
                      (item) => SegCard(
                        child: Column(
                          children: [
                            Expanded(child: ItemVisual(item)),
                            Text(
                              item.name('tr'),
                              style: SegText.item,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final item in items) {
        await precacheImage(
          AssetImage(item.images.first),
          tester.element(find.byType(Scaffold)),
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final label = theme == 'vehicles' ? 'vehicle' : theme;
      final file = File('artifacts/screenshots/$label-cards-$tier.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
