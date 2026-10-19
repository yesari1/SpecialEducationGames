import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/features/onboarding/survey_questions.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in const ['tr', 'en']) {
    testWidgets('landscape onboarding saves once at 2x and opens home ($locale)', (
      tester,
    ) async {
      final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(viewport.width, greaterThan(viewport.height));
      expect(tester.view.devicePixelRatio, greaterThan(0));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final state = AppState(
        await ContentRepository.load(),
        db,
        AudioService(),
      );
      await db.setPreference('locale', locale);
      await state.load();
      addTearDown(() {
        state.lockFamily();
        state.dispose();
      });

      await tester.pumpWidget(EducationApp(state: state));
      await tester.pumpAndSettle();
      var surfaceConverted = false;
      Future<void> capture(String name) async {
        if (!surfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        }
        await tester.pump();
        await binding.takeScreenshot(name);
      }

      void checkNativeMetrics(String stage) {
        final view = tester.view;
        final actualSize = view.physicalSize / view.devicePixelRatio;
        final context = tester.element(find.byType(OnboardingScreen));
        final media = MediaQuery.of(context);
        expect(actualSize.width, greaterThan(actualSize.height), reason: stage);
        expect(media.size.width, closeTo(actualSize.width, 1), reason: stage);
        expect(media.size.height, closeTo(actualSize.height, 1), reason: stage);
        expect(media.devicePixelRatio, closeTo(view.devicePixelRatio, 0.01));
        expect(media.textScaler.scale(1), 2, reason: '$stage text scale');
        expect(media.padding.left, greaterThanOrEqualTo(0));
        expect(media.padding.top, greaterThanOrEqualTo(0));
        expect(media.padding.right, greaterThanOrEqualTo(0));
        expect(media.padding.bottom, greaterThanOrEqualTo(0));
        expect(media.padding.horizontal, lessThan(actualSize.width));
        expect(media.padding.vertical, lessThan(actualSize.height));
        // Deliberately record device-provided metrics without changing the viewport.
        // ignore: avoid_print
        print(
          'ONBOARDING_METRICS locale=$locale stage=$stage '
          'physical=${view.physicalSize} dpr=${view.devicePixelRatio} '
          'logical=$actualSize padding=${media.padding} '
          'viewPadding=${media.viewPadding} textScale=${media.textScaler.scale(1)}',
        );
      }

      void expectNoVerticalScroll(String stage) {
        final vertical = tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where(
              (scrollable) =>
                  scrollable.axisDirection == AxisDirection.down ||
                  scrollable.axisDirection == AxisDirection.up,
            );
        expect(vertical, isEmpty, reason: '$stage must not scroll vertically');
      }

      void expectAtLeast48(double actual, String reason) {
        // The target remains 48 logical px; tolerate only IEEE-754 noise.
        expect(actual + 1e-6, greaterThanOrEqualTo(48), reason: reason);
      }

      void expectLargeTargets(String stage) {
        for (final type in [
          ElevatedButton,
          TextButton,
          OutlinedButton,
          FilledButton,
          IconButton,
        ]) {
          for (final element in find.byType(type).evaluate()) {
            final target = find.byElementPredicate(
              (candidate) => identical(candidate, element),
            );
            final rect = tester.getRect(target);
            expectAtLeast48(rect.width, '$stage $type width');
            expectAtLeast48(rect.height, '$stage $type height');
            expect(
              rect.left,
              greaterThanOrEqualTo(0),
              reason: '$stage $type left',
            );
            expect(
              rect.top,
              greaterThanOrEqualTo(0),
              reason: '$stage $type top',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(viewport.width),
              reason: '$stage $type right',
            );
            expect(
              rect.bottom,
              lessThanOrEqualTo(viewport.height),
              reason: '$stage $type bottom',
            );
          }
        }
      }

      void expectButtonLabelTarget(
        Finder label,
        Type buttonType,
        String stage,
      ) {
        final button = find
            .ancestor(of: label, matching: find.byType(buttonType))
            .first;
        final size = tester.getSize(button);
        expectAtLeast48(size.width, '$stage width');
        expectAtLeast48(size.height, '$stage height');
      }

      Future<void> checkStage(String stage) async {
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsOneWidget, reason: stage);
        checkNativeMetrics(stage);
        expectNoVerticalScroll(stage);
        expectLargeTargets(stage);
        expect(tester.takeException(), isNull, reason: '$stage overflow');
      }

      await checkStage('welcome');
      await capture('seg-onboarding-$locale-welcome-2x');
      final start = find.byKey(const ValueKey('welcome-start'));
      expectAtLeast48(tester.getSize(start).height, 'welcome start height');
      await tester.tap(start);
      await tester.pumpAndSettle();

      await checkStage('profile');
      await tester.enterText(find.byType(TextField), 'Ada');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final continueLabel = state.tr('Devam et', 'Continue');
      final profileContinue = find.text(continueLabel);
      expectButtonLabelTarget(
        profileContinue,
        ElevatedButton,
        'profile continue',
      );
      await tester.tap(profileContinue);
      await tester.pumpAndSettle();

      await checkStage('age question');
      expect(
        find.text(
          locale == 'tr' ? surveyQuestions[0].tr : surveyQuestions[0].en,
        ),
        findsOneWidget,
      );
      final skip = find.text(state.tr('Bu soruyu atla', 'Skip this question'));
      expectButtonLabelTarget(skip, TextButton, 'age skip');
      await tester.tap(skip);
      await tester.pumpAndSettle();

      expect(
        find.text(
          locale == 'tr' ? surveyQuestions[1].tr : surveyQuestions[1].en,
        ),
        findsOneWidget,
      );
      await checkStage('speech question');
      final speechOption = find.byKey(const ValueKey('survey-option-0'));
      expectAtLeast48(tester.getSize(speechOption).height, 'speech option height');
      await tester.tap(speechOption);
      await tester.pumpAndSettle();

      for (var i = 2; i < 6; i++) {
        await checkStage('survey ${surveyQuestions[i].key}');
        expect(
          find.text(
            locale == 'tr' ? surveyQuestions[i].tr : surveyQuestions[i].en,
          ),
          findsOneWidget,
        );
        final skipQuestion = find.text(
          state.tr('Bu soruyu atla', 'Skip this question'),
        );
        expectButtonLabelTarget(
          skipQuestion,
          TextButton,
          'survey ${surveyQuestions[i].key} skip',
        );
        await tester.tap(skipQuestion);
        await tester.pumpAndSettle();
      }

      await checkStage('multiple-select question');
      expect(
        find.text(
          locale == 'tr' ? surveyQuestions[6].tr : surveyQuestions[6].en,
        ),
        findsOneWidget,
      );
      final multipleOption = find.byKey(const ValueKey('survey-option-0'));
      expectAtLeast48(tester.getSize(multipleOption).height, 'multiple-select option height');
      await tester.tap(multipleOption);
      await tester.pumpAndSettle();
      final multipleContinue = find.text(continueLabel);
      expectButtonLabelTarget(
        multipleContinue,
        ElevatedButton,
        'multiple-select continue',
      );
      await tester.tap(multipleContinue);
      await tester.pumpAndSettle();

      for (var i = 7; i < surveyQuestions.length; i++) {
        await checkStage('survey ${surveyQuestions[i].key}');
        expect(
          find.text(
            locale == 'tr' ? surveyQuestions[i].tr : surveyQuestions[i].en,
          ),
          findsOneWidget,
        );
        final skipQuestion = find.text(
          state.tr('Bu soruyu atla', 'Skip this question'),
        );
        expectButtonLabelTarget(
          skipQuestion,
          TextButton,
          'survey ${surveyQuestions[i].key} skip',
        );
        await tester.tap(skipQuestion);
        await tester.pumpAndSettle();
      }

      await checkStage('final recommendation');
      await capture('seg-onboarding-$locale-final-2x');
      expect(find.byKey(const ValueKey('final-ready-title')), findsOneWidget);
      final play = find.byKey(const ValueKey('final-play'));
      expectAtLeast48(tester.getSize(play).height, 'final play height');
      await tester.tap(play);
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(state.profiles, hasLength(1));
      expect(state.profiles.single.nickname, 'Ada');
      expect(state.locale, locale);
      expect(await db.preference('locale'), locale);
      expect(tester.takeException(), isNull);
    });
  }
}
