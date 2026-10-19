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
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';

void main() {
  Future<AppState> buildState(WidgetTester tester) async {
    return (await tester.runAsync(() async {
      final s = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      return s;
    }))!;
  }

  Future<void> loadFonts(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(rootBundle.load(entry.value));
        await loader.load();
      }
    });
  }

  void expectNoVerticalScroll(WidgetTester tester, String tag) {
    final vertical = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (s) =>
              s.axisDirection == AxisDirection.down ||
              s.axisDirection == AxisDirection.up,
        );
    expect(vertical, isEmpty, reason: '$tag must not scroll vertically');
  }

  void expectOnScreen(WidgetTester tester, Finder f, Size size, String tag) {
    final rect = tester.getRect(f);
    expect(rect.left, greaterThanOrEqualTo(-0.5), reason: tag);
    expect(rect.top, greaterThanOrEqualTo(-0.5), reason: tag);
    expect(rect.right, lessThanOrEqualTo(size.width + 0.5), reason: tag);
    expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5), reason: tag);
  }

  Future<void> goToNamePage(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pumpAndSettle();
  }

  testWidgets('profile page bounds across matrix', (tester) async {
    final semantics = tester.ensureSemantics();
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      tester.view.devicePixelRatio = 1;
      final state = await buildState(tester);
      addTearDown(state.dispose);
      await loadFonts(tester);

      for (final language in ['tr', 'en']) {
        state.locale = language;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          for (final scale in [1.0, 1.6, 2.0]) {
            final tag = '$language $size x$scale';
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              MaterialApp(
                theme: segTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: OnboardingScreen(
                  key: ValueKey('$language-$size-$scale'),
                  state: state,
                ),
              ),
            );
            await tester.pumpAndSettle();
            await goToNamePage(tester);
            expectNoVerticalScroll(tester, tag);

            final title = find.text(
              language == 'tr'
                  ? 'Minik kaşifimiz kim?'
                  : 'Who is our little explorer?',
            );
            expect(title, findsOneWidget, reason: tag);
            expectOnScreen(tester, title, size, '$tag title');
            final sub = find.text(
              language == 'tr'
                  ? 'Bir takma ad yeterli.'
                  : 'A nickname is all we need.',
            );
            expect(sub, findsOneWidget, reason: tag);
            expectOnScreen(tester, sub, size, '$tag subtitle');

            final field = find.byType(TextField);
            expect(field, findsOneWidget, reason: tag);
            expectOnScreen(tester, field, size, '$tag field');

            expect(find.bySemanticsLabel('cat'), findsOneWidget, reason: tag);
            expect(find.bySemanticsLabel('dog'), findsOneWidget, reason: tag);
            expect(find.bySemanticsLabel('rabbit'), findsOneWidget);
            expect(find.bySemanticsLabel('bear'), findsOneWidget);
            for (final a in ['cat', 'dog', 'rabbit', 'bear']) {
              expectOnScreen(
                tester,
                find.bySemanticsLabel(a),
                size,
                '$tag avatar $a',
              );
            }

            final cont = find.text(
              language == 'tr' ? 'Devam et' : 'Continue',
            );
            expect(cont, findsOneWidget, reason: tag);
            expectOnScreen(tester, cont, size, '$tag continue');
            expect(tester.takeException(), isNull, reason: tag);

            await tester.enterText(field, 'Ela');
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsLabel('dog'));
            await tester.pumpAndSettle();
            await tester.tap(cont);
            await tester.pumpAndSettle();
            expect(
              find.text('Minik kaşifimiz kim?').evaluate().isEmpty &&
                  find.text('Who is our little explorer?').evaluate().isEmpty,
              isTrue,
              reason: '$tag should leave profile page',
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });

  testWidgets('keyboard inset exposes field, CTA and avatars', (tester) async {
    final semantics = tester.ensureSemantics();
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);
      final state = await buildState(tester);
      addTearDown(state.dispose);
      await loadFonts(tester);

      for (final language in ['tr', 'en']) {
        state.locale = language;
        for (final scale in [1.0, 1.6, 2.0]) {
          final tag = 'kb $language x$scale';
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            MaterialApp(
              theme: segTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  viewInsets: const EdgeInsets.only(bottom: 120),
                ),
                child: child!,
              ),
              home: OnboardingScreen(
                key: ValueKey('$language-$scale-keyboard'),
                state: state,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await goToNamePage(tester);
          await tester.enterText(find.byType(TextField), 'Ela');
          await tester.pumpAndSettle();

          final title = find.text(
            language == 'tr'
                ? 'Minik kaşifimiz kim?'
                : 'Who is our little explorer?',
          );
          expect(title, findsNothing, reason: '$tag decor hidden');

          final visibleH = 360 - 120;
          final field = find.byType(TextField);
          expect(field, findsOneWidget);
          expect(
            tester.getRect(field).bottom,
            lessThanOrEqualTo(visibleH + 0.5),
            reason: '$tag field above keyboard',
          );
          final cont = find.text(
            language == 'tr' ? 'Devam et' : 'Continue',
          );
          expect(
            tester.getRect(cont).bottom,
            lessThanOrEqualTo(visibleH + 0.5),
            reason: '$tag CTA above keyboard',
          );
          for (final a in ['cat', 'dog', 'rabbit', 'bear']) {
            final rect = tester.getRect(find.bySemanticsLabel(a));
            expect(
              rect.height,
              greaterThanOrEqualTo(48),
              reason: '$tag $a height',
            );
            expect(
              rect.bottom,
              lessThanOrEqualTo(visibleH + 0.5),
              reason: '$tag $a above keyboard',
            );
          }
          expect(tester.takeException(), isNull, reason: tag);
        }
      }
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });
}
