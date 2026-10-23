import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'app_state.dart';
import 'orientation.dart';
import 'theme/tokens.dart';
import '../core/content/content_repository.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/child_home/home_screen.dart';
import '../features/family/family_screen.dart';
import '../features/family/subscription_screen.dart';
import '../features/family/credits_screen.dart';
import '../features/family/feedback_screen.dart';
import '../features/family/family_account_screen.dart';
import '../core/auth/family_auth.dart';
import '../core/auth/google_family_auth_backend.dart';
import '../core/sync/summary_snapshot_cache.dart';
import '../features/profiles/profile_editor_screen.dart';
import '../features/game/game_screen.dart';

class EducationApp extends StatefulWidget {
  final AppState state;
  final FamilyAuthBackend? familyAuthBackend;
  const EducationApp({super.key, required this.state, this.familyAuthBackend});
  @override
  State<EducationApp> createState() => _EducationAppState();
}

class _EducationAppState extends State<EducationApp>
    with WidgetsBindingObserver {
  late final GoRouter router;
  late final FamilyAuth familyAuth;
  String? _cachedAccountUid;
  void _accountChanged() {
    final next = familyAuth.account?.uid;
    final old = _cachedAccountUid;
    _cachedAccountUid = next;
    // The free trial belongs to the Google account: read it after sign-in.
    if (next != null && next != old) {
      final email = familyAuth.account?.email;
      // Trial and admin grant first, so the family record carries the plan.
      unawaited(
        Future.wait([
          state.syncTrial(next),
          state.syncGrant(next),
        ]).whenComplete(() => state.recordFamily(next, email)),
      );
      unawaited(state.funnelStep('signedIn'));
      state.autoSync.request();
    }
    if (old != null && old != next) {
      // App-owned cleanup also runs when the account route is no longer mounted.
      unawaited(
        SummarySnapshotCache(
          state.db,
        ).clearAccount(old).catchError((Object _) {}),
      );
    }
  }

  AppState get state => widget.state;
  Widget reactive(Widget Function() child) =>
      ListenableBuilder(listenable: state, builder: (_, _) => child());
  @override
  void initState() {
    super.initState();
    familyAuth = FamilyAuth(
      backend: widget.familyAuthBackend ?? GoogleFamilyAuthBackend(),
      parentAuthorized: () => state.familyUnlocked,
    );
    familyAuth.addListener(_accountChanged);
    WidgetsBinding.instance.addObserver(this);
    router = GoRouter(
      initialLocation: state.active == null ? '/welcome' : '/',
      refreshListenable: state,
      redirect: (context, s) {
        final path = s.uri.path;
        if (state.active == null && path != '/welcome') return '/welcome';
        if (path.startsWith('/family') && !state.familyUnlocked) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => reactive(() => HomeScreen(state: state)),
          routes: [
            // Nested so system Back on a theme returns to home.
            GoRoute(
              path: 'theme/:id',
              builder: (_, s) => reactive(
                () =>
                    ThemeScreen(state: state, themeId: s.pathParameters['id']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/welcome',
          builder: (_, _) =>
              reactive(() => OnboardingScreen(state: state, auth: familyAuth)),
        ),
        GoRoute(
          path: '/game/:theme/:game/:tier',
          builder: (_, s) => reactive(
            // Leaving a game is the deliberate hold-to-leave button, not an
            // accidental Back gesture by the child.
            () => PopScope(
              canPop: false,
              child: GameScreen(
                key: ValueKey(
                  '${s.pathParameters['theme']}_${s.pathParameters['game']}_${s.pathParameters['tier']}',
                ),
                state: state,
                themeId: s.pathParameters['theme']!,
                gameId: s.pathParameters['game']!,
                difficulty: Difficulty.values.byName(s.pathParameters['tier']!),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/family',
          builder: (_, _) =>
              reactive(() => FamilyScreen(state: state, auth: familyAuth)),
          // Nested so system Back on a family page returns to the family area.
          routes: [
            GoRoute(
              path: 'subscription',
              builder: (_, _) => reactive(
                () => SubscriptionScreen(state: state, auth: familyAuth),
              ),
            ),
            GoRoute(
              path: 'feedback',
              builder: (_, _) => FeedbackScreen(state: state, auth: familyAuth),
            ),
            GoRoute(
              path: 'credits',
              builder: (_, _) => reactive(() => CreditsScreen(state: state)),
            ),
            GoRoute(
              path: 'account',
              builder: (_, _) => reactive(
                () => FamilyAccountScreen(state: state, auth: familyAuth),
              ),
            ),
            GoRoute(
              path: 'profile/:id',
              // A new child uses the onboarding's child steps; the editor
              // is for an existing profile.
              builder: (_, s) => s.pathParameters['id'] == 'new'
                  ? OnboardingScreen(
                      state: state,
                      auth: familyAuth,
                      addChild: true,
                    )
                  : reactive(
                      () => ProfileEditorScreen(
                        state: state,
                        profileId: s.pathParameters['id'],
                      ),
                    ),
            ),
          ],
        ),
      ],
      errorBuilder: (_, _) => HomeScreen(state: state),
    );
    router.routerDelegate.addListener(_syncOrientation);
    _syncOrientation();
  }

  void _syncOrientation() {
    final path = router.routerDelegate.currentConfiguration.isEmpty
        ? (state.active == null ? '/welcome' : '/')
        : router.routerDelegate.currentConfiguration.uri.path;
    AppOrientation.apply(path);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      state.autoSync.request();
      state.billing.appResumed();
    }
    if (lifecycle != AppLifecycleState.resumed) state.audio.stop();
    // Only leaving the app locks the parent area. `inactive` alone is a
    // screenshot, the notification shade or a system dialog over the app.
    if (lifecycle == AppLifecycleState.hidden ||
        lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.detached) {
      // The Google account picker and the Play purchase sheet put the app in
      // the background; keep the parent area (and its upright screen) open
      // for them instead of locking it and sending the router to child mode.
      if (!inExternalFlow) state.lockFamily();
    }
  }

  /// A parent-started Google sign-in, trial start or Play purchase is open.
  bool get inExternalFlow =>
      familyAuth.busy || state.billing.pending || state.trialBusy;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.routerDelegate.removeListener(_syncOrientation);
    router.dispose();
    familyAuth.removeListener(_accountChanged);
    familyAuth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: segTheme(),
      routerConfig: router,
      locale: Locale(state.locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}
