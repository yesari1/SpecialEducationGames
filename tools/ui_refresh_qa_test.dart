import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';

void main() {
  testWidgets(
    'Modern home and theme cards fit landscape and keep titles centered',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final state = (await tester.runAsync(
        () async => AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        ),
      ))!;
      addTearDown(state.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      await tester.runAsync(() async {
        final font = FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        await state.load();
        await state.createProfile('Deniz', 'cat', {});
      });
      for (final language in ['tr', 'en']) {
        state.locale = language;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          for (final themeId in ['', 'animals', 'vehicles']) {
            final key = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: segTheme(),
                home: RepaintBoundary(
                  key: key,
                  child: themeId.isEmpty
                      ? HomeScreen(key: UniqueKey(), state: state)
                      : ThemeScreen(
                          key: UniqueKey(),
                          state: state,
                          themeId: themeId,
                        ),
                ),
              ),
            );
            await tester.runAsync(() async {
              for (final theme in state.orderedThemes) {
                final item = state.content.items.firstWhere(
                  (item) => item.id == theme.hero,
                );
                if (item.images.isNotEmpty) {
                  await precacheImage(
                    AssetImage(item.images.first),
                    tester.element(find.byType(Scaffold)),
                  );
                }
              }
            });
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$language $size $themeId',
            );
            final cardFinder = find.byType(ThemeGameCard).first;
            final card = tester.widget<ThemeGameCard>(cardFinder);
            final title = find.descendant(
              of: cardFinder,
              matching: find.text(card.title),
            );
            expect(
              (tester.getCenter(title).dx - tester.getCenter(cardFinder).dx)
                  .abs(),
              lessThan(1),
            );
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'artifacts/screenshots/modern-${themeId.isEmpty ? 'home' : themeId}-$language-${size.width.toInt()}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
            if (themeId.isEmpty) {
              await tester.tap(
                find.text(state.tr('Bugünün Yolu', 'Today’s Path')),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: 'Path $language $size',
              );
              await tester.pump();
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  'artifacts/screenshots/modern-path-$language-${size.width.toInt()}.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
