import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/features/onboarding/survey_questions.dart';

void main() {
  testWidgets('captures real-font onboarding landscape screens', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    try {
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await tester.runAsync(state.load);
      addTearDown(state.dispose);
      await tester.runAsync(() async {
        for (final entry in {
          'Nunito': 'assets/fonts/Nunito.ttf',
          'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        }.entries) {
          final loader = FontLoader(entry.key)
            ..addFont(rootBundle.load(entry.value));
          await loader.load();
        }
        await Directory('artifacts/screenshots').create(recursive: true);
      });

      Future<void> capture(String tag, GlobalKey key) async {
        await tester.pumpAndSettle();
        final vertical = tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where(
              (s) =>
                  s.axisDirection == AxisDirection.down ||
                  s.axisDirection == AxisDirection.up,
            );
        expect(vertical, isEmpty, reason: '$tag must not scroll vertically');
        expect(tester.takeException(), isNull, reason: tag);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('artifacts/screenshots/onboarding-$tag.png');
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          for (final scale in [1.0, 1.6, 2.0]) {
            final tag =
                '$locale-${size.width.toInt()}x${size.height.toInt()}-x${scale.toString().replaceAll('.', '_')}';
            final key = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: segTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: RepaintBoundary(
                  key: key,
                  child: OnboardingScreen(key: ValueKey(tag), state: state),
                ),
              ),
            );
            await capture('$tag-welcome', key);
            await tester.tap(find.byKey(const ValueKey('welcome-start')));
            await tester.pumpAndSettle();
            await capture('$tag-profile', key);
            await tester.enterText(find.byType(TextField), 'Ada');
            await tester.pumpAndSettle();
            await tester.tap(
              find.text(locale == 'tr' ? 'Devam et' : 'Continue'),
            );
            await tester.pumpAndSettle();
            await capture('$tag-survey', key);
            for (var i = 0; i < surveyQuestions.length; i++) {
              await tester.tap(
                find.text(
                  locale == 'tr' ? 'Bu soruyu atla' : 'Skip this question',
                ),
              );
              await tester.pumpAndSettle();
            }
            await capture('$tag-final', key);
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox());
    }
  });
}
