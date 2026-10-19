import 'dart:ui' show CheckedState;

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
import 'package:special_education_games/features/onboarding/survey_questions.dart';

void main() {
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

  Future<void> openSurvey(WidgetTester tester, String language) async {
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ela');
    await tester.pumpAndSettle();
    await tester.tap(find.text(language == 'tr' ? 'Devam et' : 'Continue'));
    await tester.pumpAndSettle();
  }

  Future<void> swipeToNextOption(
    WidgetTester tester,
    String questionKey,
  ) async {
    await tester.drag(
      find.byKey(ValueKey('survey-options-$questionKey')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeToPreviousOption(
    WidgetTester tester,
    String questionKey,
  ) async {
    await tester.drag(
      find.byKey(ValueKey('survey-options-$questionKey')),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('survey questions and options fit landscape matrix', (
    tester,
  ) async {
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
                  key: ValueKey('survey-$language-$size-$scale'),
                  state: state,
                ),
              ),
            );
            await tester.pumpAndSettle();
            await openSurvey(tester, language);

            for (
              var questionIndex = 0;
              questionIndex < surveyQuestions.length;
              questionIndex++
            ) {
              final question = surveyQuestions[questionIndex];
              final questionText = language == 'tr' ? question.tr : question.en;
              final options = language == 'tr'
                  ? question.trOptions
                  : question.enOptions;
              final heading = find.text(questionText);
              expect(heading, findsOneWidget, reason: '$tag ${question.key}');
              expectOnScreen(tester, heading, size, '$tag question');
              expectNoVerticalScroll(tester, '$tag ${question.key}');
              final progress = find.text(
                '${questionIndex + 1} / ${surveyQuestions.length}',
              );
              expect(
                progress,
                findsOneWidget,
                reason: '$tag question progress',
              );
              expectOnScreen(tester, progress, size, '$tag question progress');

              final skip = find.text(
                language == 'tr' ? 'Bu soruyu atla' : 'Skip this question',
              );
              expect(skip, findsOneWidget, reason: '$tag ${question.key} skip');
              expectOnScreen(tester, skip, size, '$tag skip');
              expect(find.byType(TextButton), findsOneWidget, reason: tag);
              expect(
                tester.getRect(find.byType(TextButton)).height,
                greaterThanOrEqualTo(48),
                reason: '$tag skip tap target',
              );
              expect(find.byType(IconButton), findsNWidgets(2), reason: tag);
              for (final arrow in find.byType(IconButton).evaluate()) {
                final arrowFinder = find.byElementPredicate(
                  (element) => identical(element, arrow),
                );
                expect(
                  tester.getRect(arrowFinder).height,
                  greaterThanOrEqualTo(48),
                  reason: '$tag option arrow tap target',
                );
              }
              if (question.multiple) {
                final continueButton = find.text(
                  language == 'tr' ? 'Devam et' : 'Continue',
                );
                expect(continueButton, findsOneWidget, reason: tag);
                expectOnScreen(tester, continueButton, size, '$tag continue');
                expect(find.byType(ElevatedButton), findsOneWidget);
                expect(
                  tester.getRect(find.byType(ElevatedButton)).height,
                  greaterThanOrEqualTo(48),
                  reason: '$tag continue tap target',
                );
                await tester.tap(find.byKey(const ValueKey('survey-option-0')));
                await tester.pumpAndSettle();
              }

              for (var i = 0; i < options.length; i++) {
                final option = find.byKey(ValueKey('survey-option-$i'));
                expect(
                  option,
                  findsOneWidget,
                  reason: '$tag ${question.key} option $i',
                );
                expectOnScreen(
                  tester,
                  option,
                  size,
                  '$tag ${question.key} option $i',
                );
                expect(
                  tester.getRect(option).height,
                  greaterThanOrEqualTo(48),
                  reason: '$tag ${question.key} option $i tap target',
                );
                expect(find.text(options[i]), findsOneWidget, reason: tag);
                if (i + 1 < options.length) {
                  await swipeToNextOption(tester, question.key);
                }
              }

              if (question.multiple) {
                await tester.tap(
                  find.byKey(ValueKey('survey-option-${options.length - 1}')),
                );
                await tester.pumpAndSettle();
                for (var i = options.length - 1; i > 0; i--) {
                  await swipeToPreviousOption(tester, question.key);
                }
                final firstChoice = find.byKey(
                  const ValueKey('survey-option-0'),
                );
                final checkedState = tester
                    .getSemantics(firstChoice)
                    .getSemanticsData()
                    .flagsCollection
                    .isChecked;
                expect(
                  checkedState,
                  isNot(CheckedState.none),
                  reason: '$tag ${question.key} selection persists',
                );
                expect(
                  checkedState,
                  CheckedState.isTrue,
                  reason:
                      '$tag ${question.key} first selection remains checked',
                );
                await tester.tap(
                  find.text(language == 'tr' ? 'Devam et' : 'Continue'),
                );
              } else {
                await tester.tap(
                  find.byKey(ValueKey('survey-option-${options.length - 1}')),
                );
              }
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$tag ${question.key}',
              );
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });

  testWidgets('skip and empty multiple choice continue advance', (
    tester,
  ) async {
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
      state.locale = 'tr';
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          home: OnboardingScreen(state: state),
        ),
      );
      await tester.pumpAndSettle();
      await openSurvey(tester, 'tr');

      await tester.tap(find.text('Bu soruyu atla'));
      await tester.pumpAndSettle();
      expect(find.text(surveyQuestions[1].tr), findsOneWidget);
      expectNoVerticalScroll(tester, 'after skip');

      for (var i = 1; i < 6; i++) {
        await tester.tap(find.text('Bu soruyu atla'));
        await tester.pumpAndSettle();
      }
      expect(find.text(surveyQuestions[6].tr), findsOneWidget);
      expectNoVerticalScroll(tester, 'empty multiple continue');
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
      expect(find.text(surveyQuestions[7].tr), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });

  testWidgets('survey arrows jump when reduced motion is requested', (
    tester,
  ) async {
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
      for (final reducedBySetting in [true, false]) {
        state.reducedMotion = reducedBySetting;
        await tester.pumpWidget(
          MaterialApp(
            theme: segTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: !reducedBySetting),
              child: child!,
            ),
            home: OnboardingScreen(
              key: ValueKey('reduced-motion-$reducedBySetting'),
              state: state,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openSurvey(tester, 'en');

        final next = find.byTooltip('Next option');
        expect(next, findsOneWidget);
        expect(tester.getRect(next).height, greaterThanOrEqualTo(48));
        await tester.tap(next);
        await tester.pump();
        expect(
          find.text('2 / ${surveyQuestions.first.enOptions.length}'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      semantics.dispose();
    }
  });
}
