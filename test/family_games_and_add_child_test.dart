import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

Future<AppState> _state() async {
  final s = AppState(
    await ContentRepository.load(),
    AppDatabase.forTesting(NativeDatabase.memory()),
    AudioService(),
  );
  await s.load();
  await s.createProfile('Ada', 'cat', {});
  s.audio.enabled = false;
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the family can turn single games off for one child',
    (tester) async {
      await tester.runAsync(() async {
        final s = await _state();
        expect(s.gamesForTheme('animals'), contains('G01'));
        // Parent area locked.
        await expectLater(
          s.setGameShown('animals', 'G01', false),
          throwsStateError,
        );
        s.unlockFamily();
        await s.setGameShown('animals', 'G01', false);
        expect(s.gamesForTheme('animals'), isNot(contains('G01')));
        expect(s.allGamesForTheme('animals'), contains('G01'));
        expect(s.dailyPathSteps, isNot(contains('animals_G01')));
        // Another child keeps every game.
        await s.entitlement.confirmStoreState(true, lifetime: true);
        await s.createProfile('Bora', 'cat', {});
        final second = s.profiles.firstWhere((p) => p.nickname == 'Bora');
        await s.selectProfile(second);
        expect(s.gamesForTheme('animals'), contains('G01'));
        final first = s.profiles.firstWhere((p) => p.nickname == 'Ada');
        await s.selectProfile(first);
        expect(s.gamesForTheme('animals'), isNot(contains('G01')));
        await s.setGameShown('animals', 'G01', true);
        expect(s.gamesForTheme('animals'), contains('G01'));
        s.lockFamily();
        s.dispose();
      });
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'adding a child uses the onboarding child steps',
    (tester) async {
      await tester.runAsync(() async {
        await (FontLoader(
          'Nunito',
        )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
      });
      final s = (await tester.runAsync(_state))!;
      addTearDown(s.dispose);
      s.entitlement.lifetimeOwned = true;
      s.unlockFamily();
      s.locale = 'en';
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/family/new',
        routes: [
          GoRoute(
            path: '/family',
            builder: (_, _) => const Scaffold(body: Text('family-home')),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => OnboardingScreen(state: s, addChild: true),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: segTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      // Starts at the child step (no welcome page, no PIN, no offer).
      expect(find.byKey(const ValueKey('child-title')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('nickname-field')),
        'Can',
      );
      for (var i = 0; i < 12; i++) {
        if (find.byKey(const ValueKey('goal-title')).evaluate().isNotEmpty) {
          break;
        }
        final skip = find.byKey(const ValueKey('onboarding-skip'));
        await tester.tap(
          skip.evaluate().isNotEmpty
              ? skip
              : find.byKey(const ValueKey('onboarding-continue')),
        );
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('goal-title')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(s.profiles.map((p) => p.nickname), containsAll(['Ada', 'Can']));
      expect(find.text('family-home'), findsOneWidget);
      s.lockFamily();
      await tester.pumpWidget(const SizedBox.shrink());
      // The Linux target keeps the Play Billing plugin from connecting.
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
