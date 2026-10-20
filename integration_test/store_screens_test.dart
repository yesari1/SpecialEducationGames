import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

class _NoGoogle implements FamilyAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

/// Google Play store screenshots for one language:
/// flutter drive ... --dart-define=SHOT_LOCALE=tr (or en).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const locale = String.fromEnvironment('SHOT_LOCALE', defaultValue: 'tr');

  // A router so screens that navigate (round end → theme) do not throw.
  Widget app(Widget home) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: segTheme(),
    locale: const Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(path: '/theme/:id', builder: (_, _) => const SizedBox()),
      ],
    ),
  );

  Future<void> frames(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 50) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  Future<void> orient(WidgetTester tester, DeviceOrientation o) async {
    await SystemChrome.setPreferredOrientations([o]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await frames(tester, 1500);
  }

  Future<AppState> makeState(
    WidgetTester tester, {
    bool premium = true,
    bool profile = true,
  }) async {
    final content = (await tester.runAsync(ContentRepository.load))!;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final state = AppState(content, db, AudioService());
    await tester.runAsync(state.load);
    if (premium) {
      await tester.runAsync(() => state.entitlement.confirmStoreState(true));
    }
    if (profile) {
      await tester.runAsync(
        () => state.createProfile(locale == 'tr' ? 'Deniz' : 'Ella', 'cat', {
          'ageYears': 5,
        }),
      );
    }
    state
      ..locale = locale
      ..sound = false
      ..introduction = false
      ..hintSeconds = 0;
    state.audio.enabled = false;
    return state;
  }

  Future<void> shot(String name) =>
      binding.takeScreenshot('store-$locale-$name');

  /// Plays [rounds] rounds of [game] correctly, then waits for the next one.
  Future<void> playRounds(WidgetTester tester, int rounds) async {
    int? previous;
    for (var round = 0; round <= rounds; round++) {
      RoundChoicesView? view;
      for (var i = 0; i < 150 && view == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        // The round may be over: stop on the round-end page.
        if (find
            .byKey(const ValueKey('completion-summary'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
        final found = find.byType(RoundChoicesView);
        if (found.evaluate().isEmpty) continue;
        final c = tester.widget<RoundChoicesView>(found);
        if (c.hint.generation != previous &&
            c.hint.visibleChoices == c.spec.choices.length) {
          view = c;
        }
      }
      if (view == null || round == rounds) return;
      previous = view.hint.generation;
      await frames(tester, 400);
      await tester.tap(
        find.byKey(ValueKey('$previous:${view.spec.target.id}')),
      );
    }
  }

  testWidgets('store screenshots ($locale)', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    // 1. Welcome (upright).
    await orient(tester, DeviceOrientation.portraitUp);
    final fresh = await makeState(tester, premium: false, profile: false);
    await tester.pumpWidget(app(OnboardingScreen(state: fresh)));
    await tester.pumpAndSettle();
    await frames(tester, 1500);
    await shot('01-welcome');
    await tester.pumpWidget(const SizedBox.shrink());

    // 2–3. Home and a theme (sideways).
    await orient(tester, DeviceOrientation.landscapeLeft);
    final state = await makeState(tester);
    await tester.pumpWidget(app(HomeScreen(state: state)));
    await tester.pumpAndSettle();
    await frames(tester, 1500);
    await shot('02-home');
    await tester.pumpWidget(app(ThemeScreen(state: state, themeId: 'animals')));
    await tester.pumpAndSettle();
    await frames(tester, 1500);
    await shot('03-theme');

    // 4–6. Games.
    for (final (name, theme, game, rounds) in const [
      ('04-find-animal', 'animals', 'G01', 1),
      ('05-count', 'produce', 'G33', 1),
      ('06-basket', 'vehicles', 'G23', 0),
    ]) {
      await tester.pumpWidget(
        app(
          GameScreen(
            key: ValueKey(name),
            state: state,
            themeId: theme,
            gameId: game,
            difficulty: Difficulty.medium,
          ),
        ),
      );
      await playRounds(tester, rounds);
      await frames(tester, 900);
      await shot(name);
    }

    // 7. Round end with confetti.
    state.roundLength = 3;
    await tester.pumpWidget(
      app(
        GameScreen(
          key: const ValueKey('end'),
          state: state,
          themeId: 'animals',
          gameId: 'G01',
          difficulty: Difficulty.easy,
        ),
      ),
    );
    await playRounds(tester, 3);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey('completion-summary'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await frames(tester, 800);
    await shot('07-well-done');
    await tester.pumpWidget(const SizedBox.shrink());

    // 8. Premium page (upright, free account).
    await orient(tester, DeviceOrientation.portraitUp);
    final free = await makeState(tester, premium: false);
    free.unlockFamily();
    final auth = FamilyAuth(
      backend: _NoGoogle(),
      parentAuthorized: () => free.familyUnlocked,
    );
    await tester.pumpWidget(app(SubscriptionScreen(state: free, auth: auth)));
    await tester.pumpAndSettle();
    await frames(tester, 1500);
    await shot('08-premium');
    await tester.pumpWidget(const SizedBox.shrink());
    free.lockFamily();
    await frames(tester, 300);
  });
}
