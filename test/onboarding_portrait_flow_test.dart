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

  /// After the question the profile is saved (real database work), then
  /// the offer shows.
  Future<void> waitForOffer(WidgetTester tester) async {
    final offer = find.byKey(const ValueKey('paywall-continue'));
    for (var i = 0; i < 30 && offer.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// The Premium offer; continue with the free
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
    // First run asks only this question; the profile is saved, the parent
    // area is open for the plan and the offer.
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(state.profiles, hasLength(1));
    expect(state.familyUnlocked, isTrue);
    await waitForOffer(tester);
    await passOffer(tester);

    // The daily goal comes after the offer: no PIN step.
    expect(find.byKey(const ValueKey('goal-title')), findsOneWidget);
    await tapKey(tester, 'goal-20');
    await tapKey(tester, 'onboarding-continue');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await waitForOffer(tester);
    await passOffer(tester);
    await tapKey(tester, 'onboarding-continue'); // goal (15 preselected)
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'final-play');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(state.profiles.single.nickname, 'Little explorer');
    expect(state.dailyGoalMinutes, 15);
    expect(state.hasParentPin, isFalse);
  }, variant: _host);

  testWidgets('the question leads straight to the offer, with no plan pages', (
    tester,
  ) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'tr';
    await pumpOnboarding(tester, state);
    await tapKey(tester, 'welcome-start');
    await tester.enterText(find.byKey(const ValueKey('nickname-field')), 'Ada');
    await tapKey(tester, 'age-4');
    await tapKey(tester, 'onboarding-continue');
    await tapKey(tester, 'survey-option-1');
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await waitForOffer(tester);
    expect(find.byKey(const ValueKey('paywall-continue')), findsOneWidget);
    expect(find.textContaining('7-day plan'), findsNothing);
    expect(find.textContaining('7 günlük plan'), findsNothing);
    expect(tester.takeException(), isNull);
    state.lockFamily(); // Ends the parent area's five-minute timer.
  }, variant: _host);

  testWidgets('Premium already on: the offer has "Continue" and moves on', (
    tester,
  ) async {
    await loadFonts(tester);
    final state = await buildState(tester);
    addTearDown(state.dispose);
    state.locale = 'tr';
    // A purchase restored after reinstalling the app.
    await tester.runAsync(() => state.entitlement.confirmStoreState(true));
    await pumpOnboarding(tester, state);
    await tapKey(tester, 'welcome-start');
    await tester.enterText(find.byKey(const ValueKey('nickname-field')), 'Ada');
    await tapKey(tester, 'age-4');
    await tapKey(tester, 'onboarding-continue');
    await tapKey(tester, 'survey-option-1');
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    final owned = find.byKey(const ValueKey('paywall-owned-continue'));
    for (var i = 0; i < 30 && owned.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(owned, findsOneWidget);
    expect(find.byKey(const ValueKey('paywall-continue')), findsNothing);
    await tapKey(tester, 'paywall-owned-continue');
    expect(owned, findsNothing);
    expect(tester.takeException(), isNull);
    state.lockFamily();
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
    Future<void> systemBack() async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

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
        // First run asks one question.
        await check('question');
        await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
        await waitForOffer(tester);
        await passOffer(tester);
        await check('goal');
        await tapKey(tester, 'onboarding-continue');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pumpAndSettle();
        await check('handoff');
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      }
    }
  }, variant: _host);
}
