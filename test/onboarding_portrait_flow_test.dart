import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/orientation.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';

// The Linux target keeps the Play Billing plugin from connecting on the host.
final _host = TargetPlatformVariant.only(TargetPlatform.linux);

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

  Future<GoRouter> pumpOnboarding(
    WidgetTester tester,
    AppState state, {
    Size size = const Size(412, 915),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (context, _) => OnboardingScreen(state: state),
        ),
        GoRoute(
          path: '/',
          builder: (context, _) => const Scaffold(
            body: Text('child home', key: ValueKey('child-home')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: segTheme(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// After the goal the plan pages show: "Building the plan" moves on by
  /// itself, the 7-day plan waits for its button. [check] runs on the plan.
  Future<void> passPlan(
    WidgetTester tester, [
    Future<void> Function(String step)? check,
  ]) async {
    final building = find.byKey(const ValueKey('plan-building'));
    // The profile is saved first (real database work).
    for (var i = 0; i < 30 && building.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    if (building.evaluate().isNotEmpty) {
      await tester.pump(const Duration(seconds: 3));
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-ready-title')), findsOneWidget);
    if (check != null) await check('plan ready');
    await tester.tap(find.byKey(const ValueKey('plan-continue')));
    await tester.pumpAndSettle();
  }

  /// After the plan pages the Premium offer shows; continue with the free
  /// version.
  Future<void> passOffer(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paywall-continue')), findsOneWidget);
    // No close button: the offer is left once the account has its trial.
    expect(find.byKey(const ValueKey('paywall-close')), findsNothing);
    final state =
        (tester.state(find.byType(OnboardingScreen)) as dynamic).widget.state
            as AppState;
    await tester.runAsync(
      () => state.entitlement.setTrial('parent-1', DateTime.now()),
    );
    state.setAccount('parent-1', ready: true);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('family routes are upright and child routes are landscape', () {
    for (final path in [
      '/welcome',
      '/family',
      '/family/subscription',
      '/family/profile/new',
    ]) {
      expect(AppOrientation.forPath(path), [DeviceOrientation.portraitUp]);
    }
    for (final path in ['/', '/theme/animals', '/game/animals/G01/easy']) {
      expect(
        AppOrientation.forPath(path),
        isNot(contains(DeviceOrientation.portraitUp)),
      );
    }
    expect(AppOrientation.isFamilyPath('/familyish'), isFalse);
  });

  testWidgets('full flow saves profile, age, answers and goal once', (
    tester,
  ) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'tr';
    final router = await pumpOnboarding(tester, state);

    expect(find.byKey(const ValueKey('welcome-title')), findsOneWidget);
    await tapKey(tester, 'welcome-start');

    await tester.enterText(find.byKey(const ValueKey('nickname-field')), 'Ada');
    await tapKey(tester, 'age-5');
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('age-5')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      isNotNull,
    );
    await tapKey(tester, 'onboarding-continue');

    // favorite (multiple): pick two, then deselect one.
    expect(find.byKey(const ValueKey('question-favorite')), findsOneWidget);
    await tapKey(tester, 'survey-option-0');
    await tapKey(tester, 'survey-option-1');
    await tapKey(tester, 'survey-option-0');
    await tapKey(tester, 'onboarding-continue');
    // known: skipped. First run asks only these two questions.
    expect(find.byKey(const ValueKey('question-known')), findsOneWidget);
    await tapKey(tester, 'onboarding-skip');

    // Goal, then straight to the offer: no PIN step.
    expect(find.byKey(const ValueKey('goal-title')), findsOneWidget);
    await tapKey(tester, 'goal-20');
    await tapKey(tester, 'onboarding-continue');

    // The profile is saved, the parent area is open for the offer.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(state.profiles, hasLength(1));
    expect(state.familyUnlocked, isTrue);
    await passPlan(tester);
    await passOffer(tester);
    // Saved profiles follow their own language setting (the test device's).
    expect(find.textContaining('Ada!'), findsOneWidget);
    final play = find.byKey(const ValueKey('final-play'));
    await tester.tap(play);
    await tester.tap(play);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(state.profiles, hasLength(1));
    final profile = state.profiles.single;
    expect(profile.nickname, 'Ada');
    final survey = jsonDecode(profile.payload) as Map<String, dynamic>;
    expect(survey['ageYears'], 5);
    expect(survey['age'], 1);
    expect(survey['favorite'], [1]);
    expect(survey.containsKey('known'), isFalse);
    expect(survey.containsKey('sound'), isFalse);
    expect(survey.containsKey('focus'), isFalse);
    expect(state.dailyGoalMinutes, 20);
    expect(state.hasParentPin, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/');
    // Handing the phone to the child closes the parent area again.
    expect(state.familyUnlocked, isFalse);
    expect(tester.takeException(), isNull);
  }, variant: _host);

  testWidgets('skipping everything still creates a named profile', (
    tester,
  ) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'en';
    await pumpOnboarding(tester, state);
    await tapKey(tester, 'welcome-start');
    await tapKey(tester, 'onboarding-continue');
    for (var i = 0; i < 2; i++) {
      await tapKey(tester, 'onboarding-skip');
    }
    await tapKey(tester, 'onboarding-continue'); // goal (15 preselected)
    await passPlan(tester);
    await passOffer(tester);
    await tapKey(tester, 'final-play');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(state.profiles.single.nickname, 'Little explorer');
    expect(state.dailyGoalMinutes, 15);
    expect(state.hasParentPin, isFalse);
  }, variant: _host);

  testWidgets('goal leads to the plan pages, then the offer', (tester) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'tr';
    await pumpOnboarding(tester, state);
    await tapKey(tester, 'welcome-start');
    await tester.enterText(find.byKey(const ValueKey('nickname-field')), 'Ada');
    await tapKey(tester, 'age-4');
    await tapKey(tester, 'onboarding-continue');
    await tapKey(tester, 'survey-option-1'); // Taşıtlar
    await tapKey(tester, 'onboarding-continue');
    await tapKey(tester, 'onboarding-skip');
    await tapKey(tester, 'goal-10');
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));

    // Building the plan: the parent's answers, ticked one by one.
    final building = find.byKey(const ValueKey('plan-building'));
    for (var i = 0; i < 30 && building.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('plan-building-title')), findsOneWidget);
    // Saved profiles follow their own language setting (the test device's).
    expect(find.text('Level for ages 4–5 selected'), findsOneWidget);
    expect(find.text('Favourite topics added: Vehicles'), findsOneWidget);
    expect(find.text('Daily goal: 10 minutes'), findsOneWidget);
    // After the page transition: no back button, nothing ticked yet.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('onboarding-back')), findsNothing);
    expect(find.byKey(const ValueKey('plan-check')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.byKey(const ValueKey('plan-check')), findsWidgets);
    expect(find.byKey(const ValueKey('plan-ready-title')), findsNothing);

    // Moves on by itself after about three seconds.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text("Ada's 7-day plan is ready"), findsOneWidget);
    for (var day = 1; day <= 7; day++) {
      expect(find.byKey(ValueKey('plan-day-$day')), findsOneWidget);
    }
    expect(find.text('Day 1'), findsOneWidget);
    // Only day 1 carries the "Today" chip.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('plan-day-1')),
        matching: find.text('Today'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('plan-today')), findsOneWidget);
    // System Back does not leave the plan (the profile is saved).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-ready-title')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paywall-continue')), findsOneWidget);
    expect(tester.takeException(), isNull);
    state.lockFamily(); // Ends the parent area's five-minute timer.
  }, variant: _host);

  testWidgets('reduced motion ticks every plan line at once', (tester) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'en';
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpOnboarding(tester, state);
    await tapKey(tester, 'welcome-start');
    await tapKey(tester, 'onboarding-continue');
    await tapKey(tester, 'onboarding-skip');
    await tapKey(tester, 'onboarding-skip');
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    final building = find.byKey(const ValueKey('plan-building'));
    for (var i = 0; i < 30 && building.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('plan-check')), findsNWidgets(3));
    expect(find.text('Starting level selected'), findsOneWidget);
    expect(find.text('All topics added'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-ready-title')), findsOneWidget);
    state.lockFamily(); // Ends the parent area's five-minute timer.
  }, variant: _host);

  testWidgets('back returns through steps and keeps answers', (tester) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'en';
    await pumpOnboarding(tester, state);
    await tapKey(tester, 'welcome-start');
    await tapKey(tester, 'age-10');
    await tapKey(tester, 'onboarding-continue');
    await tapKey(tester, 'onboarding-back');
    expect(find.byKey(const ValueKey('child-title')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('age-10')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      isNotNull,
    );
  }, variant: _host);

  testWidgets('system Back walks back through the steps', (tester) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'en';
    await pumpOnboarding(tester, state);
    await tapKey(tester, 'welcome-start');
    await tapKey(tester, 'onboarding-continue');
    expect(find.byKey(const ValueKey('question-favorite')), findsOneWidget);
    await tapKey(tester, 'onboarding-skip');
    expect(find.byKey(const ValueKey('question-known')), findsOneWidget);
    Future<void> systemBack() async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    await systemBack();
    expect(find.byKey(const ValueKey('question-favorite')), findsOneWidget);
    await systemBack();
    expect(find.byKey(const ValueKey('child-title')), findsOneWidget);
    await systemBack();
    expect(find.byKey(const ValueKey('welcome-title')), findsOneWidget);
    expect(state.profiles, isEmpty);
  }, variant: _host);

  testWidgets('every step fits phone portrait at 1x and 2x text in TR/EN', (
    tester,
  ) async {
    await loadFonts(tester);
    for (final locale in ['tr', 'en']) {
      for (final scale in [1.0, 2.0]) {
        final state = await buildState(tester);
        state.locale = locale;
        await pumpOnboarding(
          tester,
          state,
          size: const Size(360, 740),
          textScale: scale,
        );
        final tag = '$locale x$scale';
        Future<void> check(String step) async {
          expect(tester.takeException(), isNull, reason: '$tag $step');
          final button = find.byType(ElevatedButton);
          expect(button, findsWidgets, reason: '$tag $step');
          final rect = tester.getRect(button.first);
          expect(rect.bottom, lessThanOrEqualTo(740), reason: '$tag $step');
          expect(rect.height, greaterThanOrEqualTo(48), reason: '$tag $step');
        }

        await check('welcome');
        await tapKey(tester, 'welcome-start');
        await check('child');
        await tapKey(tester, 'onboarding-continue');
        // First run asks two questions.
        for (var i = 0; i < 2; i++) {
          await check('question $i');
          await tapKey(tester, 'onboarding-continue');
        }
        await check('goal');
        await tapKey(tester, 'onboarding-continue');
        await passPlan(tester, check);
        await passOffer(tester);
        await check('handoff');
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      }
    }
  }, variant: _host);
}
