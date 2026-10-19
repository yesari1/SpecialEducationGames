import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/features/onboarding/survey_questions.dart';

void main() {
  const themeIds = ['animals', 'vehicles', 'colors'];

  Future<AppState> buildState(WidgetTester tester) async {
    return (await tester.runAsync(() async {
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await state.load();
      return state;
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
          (scrollable) =>
              scrollable.axisDirection == AxisDirection.down ||
              scrollable.axisDirection == AxisDirection.up,
        );
    expect(vertical, isEmpty, reason: '$tag must not scroll vertically');
  }

  void expectOnScreen(
    WidgetTester tester,
    Finder finder,
    Size size,
    String tag,
  ) {
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(-0.5), reason: tag);
    expect(rect.top, greaterThanOrEqualTo(-0.5), reason: tag);
    expect(rect.right, lessThanOrEqualTo(size.width + 0.5), reason: tag);
    expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5), reason: tag);
  }

  Future<void> openFinal(
    WidgetTester tester,
    String language,
    String name,
  ) async {
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), name);
    await tester.pumpAndSettle();
    await tester.tap(find.text(language == 'tr' ? 'Devam et' : 'Continue'));
    await tester.pumpAndSettle();
    for (var i = 0; i < surveyQuestions.length; i++) {
      await tester.tap(
        find.text(language == 'tr' ? 'Bu soruyu atla' : 'Skip this question'),
      );
      await tester.pumpAndSettle();
    }
  }

  void expectReadableText(WidgetTester tester, Finder finder, String tag) {
    final text = tester.widget<Text>(finder);
    expect(text.maxLines, isNull, reason: '$tag must keep every line');
    expect(text.overflow, isNull, reason: '$tag must not use ellipsis');
  }

  testWidgets('final recommendations fit the landscape matrix', (tester) async {
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
            final nickname =
                language == 'tr' && size == const Size(800, 360) && scale == 2.0
                ? 'ABCDEFGHIJKLMNOPQRSTUVWX'
                : 'Ela';
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
                  key: ValueKey('final-$language-$size-$scale'),
                  state: state,
                ),
              ),
            );
            await tester.pumpAndSettle();
            await openFinal(tester, language, nickname);

            expectNoVerticalScroll(tester, tag);
            final title = find.byKey(const ValueKey('final-ready-title'));
            expect(title, findsOneWidget, reason: tag);
            expect(
              find.text(
                language == 'tr' ? 'Hazırız, $nickname!' : 'Ready, $nickname!',
              ),
              findsOneWidget,
              reason: '$tag nickname copy',
            );
            expectOnScreen(tester, title, size, '$tag ready title');
            expectReadableText(tester, title, '$tag ready title');

            final suggested = find.byKey(
              const ValueKey('final-suggested-title'),
            );
            expect(suggested, findsOneWidget, reason: tag);
            expectOnScreen(tester, suggested, size, '$tag suggested heading');
            expectReadableText(tester, suggested, '$tag suggested heading');

            final hint = find.byKey(const ValueKey('final-family-hint'));
            expect(hint, findsOneWidget, reason: tag);
            expectOnScreen(tester, hint, size, '$tag family hint');
            expectReadableText(tester, hint, '$tag family hint');
            expect(
              find.text(
                language == 'tr'
                    ? 'Aile bölümünden değiştirebilirsiniz.'
                    : 'You can adjust these in the Family area.',
              ),
              findsOneWidget,
              reason: '$tag hint copy',
            );

            final play = find.byKey(const ValueKey('final-play'));
            expect(play, findsOneWidget, reason: tag);
            expectOnScreen(tester, play, size, '$tag play CTA');
            expect(
              tester.getRect(play).height,
              greaterThanOrEqualTo(64),
              reason: '$tag play CTA minimum tap height',
            );
            expect(
              find.text(language == 'tr' ? 'Oyunlara geç' : 'Let’s play'),
              findsOneWidget,
              reason: '$tag play copy',
            );
            expect(find.byType(FittedBox), findsNothing, reason: tag);

            final pager = find.byKey(
              const ValueKey('final-recommendations-pager'),
            );
            if (pager.evaluate().isNotEmpty) {
              for (var i = 0; i < themeIds.length; i++) {
                final card = find.byKey(
                  ValueKey('final-recommendation-${themeIds[i]}'),
                );
                expect(card, findsOneWidget, reason: '$tag rec ${themeIds[i]}');
                expectOnScreen(tester, card, size, '$tag rec ${themeIds[i]}');
                final theme = state.content.theme(themeIds[i]).name(language);
                final level = SurveyMapper.initialForTheme(
                  {},
                  themeIds[i],
                ).label(language);
                expect(find.text(theme), findsOneWidget, reason: tag);
                expect(
                  find.descendant(of: card, matching: find.text(level)),
                  findsOneWidget,
                  reason: '$tag ${themeIds[i]} mapped level',
                );
                expectReadableText(tester, find.text(theme), '$tag $theme');
                if (i + 1 < themeIds.length) {
                  final next = find.byTooltip(
                    language == 'tr' ? 'Sonraki öneri' : 'Next recommendation',
                  );
                  expect(
                    next,
                    findsOneWidget,
                    reason: '$tag next recommendation',
                  );
                  await tester.tap(next);
                  await tester.pumpAndSettle();
                }
              }
            } else {
              for (final id in themeIds) {
                final card = find.byKey(ValueKey('final-recommendation-$id'));
                expect(card, findsOneWidget, reason: '$tag rec $id');
                expectOnScreen(tester, card, size, '$tag rec $id');
                final theme = state.content.theme(id).name(language);
                final level = SurveyMapper.initialForTheme(
                  {},
                  id,
                ).label(language);
                expect(find.text(theme), findsOneWidget, reason: tag);
                expect(
                  find.descendant(of: card, matching: find.text(level)),
                  findsOneWidget,
                  reason: '$tag $id mapped level',
                );
                expectReadableText(tester, find.text(theme), '$tag $theme');
              }
            }

            expectNoVerticalScroll(tester, '$tag recommendation review');
            expect(tester.takeException(), isNull, reason: tag);
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });

  testWidgets('recommendation levels follow SurveyMapper answers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      final state = await buildState(tester);
      addTearDown(state.dispose);
      await loadFonts(tester);
      state.locale = 'tr';
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          home: OnboardingScreen(state: state),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome-start')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ela');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bu soruyu atla'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bu soruyu atla'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('survey-options-receptive')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('survey-options-receptive')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('survey-option-2')));
      await tester.pumpAndSettle();
      for (
        var questionIndex = 3;
        questionIndex < surveyQuestions.length;
        questionIndex++
      ) {
        await tester.tap(find.text('Bu soruyu atla'));
        await tester.pumpAndSettle();
      }

      for (final id in themeIds) {
        final card = find.byKey(ValueKey('final-recommendation-$id'));
        final level = SurveyMapper.initialForTheme({
          'receptive': 2,
        }, id).label('tr');
        expect(
          find.descendant(of: card, matching: find.text(level)),
          findsOneWidget,
          reason: '$id recommendation follows the survey response',
        );
      }
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });

  testWidgets('final CTA saves once and opens the game route', (tester) async {
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
      state.locale = 'en';
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, routeState) => OnboardingScreen(state: state),
          ),
          GoRoute(
            path: '/',
            builder: (context, routeState) => const Scaffold(
              body: Center(
                child: Text('Saved destination', key: ValueKey('saved-route')),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: segTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      await openFinal(tester, 'en', 'Rae');

      final play = find.byKey(const ValueKey('final-play'));
      await tester.tap(play);
      await tester.tap(play);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(state.profiles, hasLength(1));
      expect(state.profiles.single.nickname, 'Rae');
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.byKey(const ValueKey('saved-route')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });
}
