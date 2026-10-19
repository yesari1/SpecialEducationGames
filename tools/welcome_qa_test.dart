import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/onboarding/welcome_pane.dart';

void main() {
  testWidgets(
    'Landscape welcome keeps the start action visible without scrolling',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await tester.runAsync(state.load);
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
      });
      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          var tapped = false;
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: segTheme(),
              home: RepaintBoundary(
                key: key,
                child: WelcomePane(
                  state: state,
                  onContinue: () => tapped = true,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final start = find.byKey(const ValueKey('welcome-start'));
          final bounds = tester.getRect(start);
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.bottom, lessThanOrEqualTo(size.height));
          await tester.tap(start);
          expect(tapped, isTrue);
          // Capture the painted frame after the button's ink animation settles.
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'artifacts/screenshots/modern-welcome-$locale-${size.width.toInt()}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
