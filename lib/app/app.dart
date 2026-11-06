import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/scoped_localizations.dart';
import 'package:go_router/go_router.dart';
import 'app_state.dart';
import 'orientation.dart';
import 'theme/tokens.dart';
import '../core/content/content_repository.dart';
import '../features/stories/story_screens.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/sign_in_screen.dart';
import '../app/ui/components.dart' show showNotice;
import '../core/auth/firebase_client.dart';
import 'package:app_links/app_links.dart';
import '../features/child_home/home_screen.dart';
import '../features/family/family_screen.dart';
import '../features/family/subscription_screen.dart';
import '../features/family/credits_screen.dart';
import '../features/family/feedback_screen.dart';
import '../features/family/family_account_screen.dart';
import '../features/family/account_gate_screen.dart';
import '../core/auth/family_auth.dart';
import '../core/auth/google_family_auth_backend.dart';
import '../core/sync/summary_snapshot_cache.dart';
import '../features/profiles/profile_editor_screen.dart';
import '../features/game/game_screen.dart';

class EducationApp extends StatefulWidget {
  final AppState state;
  final FamilyAuthBackend? familyAuthBackend;

  /// The release app: Google sign-in and a started trial (or Premium) are
  /// required (sign-in / trial page). Widget tests leave it off.
  final bool accountGate;
  const EducationApp({
    super.key,
    required this.state,
    this.familyAuthBackend,
    this.accountGate = false,
  });
  @override
  State<EducationApp> createState() => _EducationAppState();
}

class _EducationAppState extends State<EducationApp>
    with WidgetsBindingObserver {
  late final GoRouter router;
  late final FamilyAuth familyAuth;
  String? _cachedAccountUid;
  String? _recordedPlan;

  /// A purchase (or its end) changes the plan: record it in
  /// `families/{uid}` at once, so other devices of the account see it.
  void _planChanged() {
    final uid = familyAuth.account?.uid;
    final plan = state.entitlement.planName;
    if (uid == null || _recordedPlan == null || plan == _recordedPlan) return;
    _recordedPlan = plan;
    unawaited(state.recordFamily(uid, familyAuth.account?.email));
  }

  void _accountChanged() {
    final next = familyAuth.account?.uid;
    final old = _cachedAccountUid;
    _cachedAccountUid = next;
    // The free trial belongs to the Google account: read it after sign-in.
    if (next != old) state.setAccount(next, ready: next == null);
    if (old != null && next == null) unawaited(state.signedOut());
    if (next != null && next != old) {
      final email = familyAuth.account?.email;
      // Trial, admin grant, plan and child profiles first: the loading page
      // stays until the app knows whether the sign-in / trial page is due.
      unawaited(
        Future.wait([
          state.syncTrial(next),
          state.syncGrant(next),
          state.syncPlan(next),
          state.syncChildren(next),
        ]).whenComplete(() {
          if (familyAuth.account?.uid == next) {
            state.setAccount(next, ready: true);
          }
          _recordedPlan = state.entitlement.planName;
          // No family record yet for a Google account only being checked on
          // the welcome page ("Already have an account?").
          if (state.active == null) return null;
          return state.recordFamily(next, email);
        }),
      );
      // A Google account only being checked on the welcome page ("Already
      // have an account?") is not a sign-in yet; that page stamps it once
      // the account turns out to exist.
      if (state.active != null) unawaited(state.funnelStep('signedIn'));
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

  StreamSubscription<Uri>? _links;

  /// Firebase's password-free sign-in link, opened on this phone (App
  /// Links). It finishes the sign-in started on the "Sign in" page.
  void _listenForSignInLinks() {
    final links = AppLinks();
    _links = links.uriLinkStream.listen(
      (uri) => unawaited(_signInLink(uri)),
      onError: (Object _) {},
    );
  }

  Future<void> _signInLink(Uri uri) async {
    final link = uri.toString();
    try {
      await FirebaseClient.ensureInitialized();
    } catch (_) {
      return;
    }
    if (!familyAuth.isSignInLink(link) || familyAuth.account != null) return;
    final email = await state.db.preference(pendingSignInEmailKey);
    if (email == null || email.isEmpty) return;
    // Started from the welcome page (no profile yet) or from the trial
    // button on a start offer; the link itself is the parent's.
    final welcome = state.profiles.isEmpty;
    if (!welcome && !state.familyUnlocked && state.accountGatePassed) return;
    state.unlockFamily();
    await familyAuth.signInWithLink(email, link);
    final account = familyAuth.account;
    if (account == null) return;
    await state.db.setPreference(pendingSignInEmailKey, '');
    final page = SignInScreen.openPage;
    if (page != null && page.mounted) {
      // The welcome page goes on with its usual account check.
      (page as dynamic).linkSignedIn();
      return;
    }
    // Opened from the trial button (the sign-in page is gone, e.g. the app
    // restarted from the link): start the account's trial here, as the
    // button would have, so the app opens instead of the offer again.
    if (!welcome) {
      final onGate =
          router.routerDelegate.currentConfiguration.uri.path == '/gate';
      for (var i = 0; i < 300 && !state.accountReady; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final e = state.entitlement;
      if (!state.accountGatePassed && !e.trialUsed && !e.isPremium) {
        await state.startTrial(account.uid);
      }
      // On the start page the child takes over next (first run goes on to
      // its hand-off page, which locks the parent area itself).
      if (state.accountGatePassed && onGate) {
        state.lockFamily();
      }
      return;
    }
    // App was started from the link: the same check as the welcome page.
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (!await state.accountHasRecord(account.uid)) {
      await familyAuth.signOut();
      familyAuth.issue = null;
      if (context != null && context.mounted) {
        showNotice(
          context,
          scopedLocalizations(context, state.locale).obNoAccountFound,
          icon: Icons.info_rounded,
          color: SegColors.accent,
        );
      }
      return;
    }
    for (var i = 0; i < 300 && !state.accountReady; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (state.active != null) {
      unawaited(state.recordFamily(account.uid, account.email));
      router.go('/');
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
    state.billing.addListener(_planChanged);
    if (widget.accountGate) _listenForSignInLinks();
    if (widget.accountGate) {
      unawaited(
        familyAuth.restoreAtStart().whenComplete(() {
          if (familyAuth.account == null) state.setAccount(null, ready: true);
        }),
      );
    } else {
      state.accountReady = true;
    }
    WidgetsBinding.instance.addObserver(this);
    router = GoRouter(
      initialLocation: widget.accountGate
          ? '/loading'
          : state.active == null
          ? '/welcome'
          : '/',
      refreshListenable: state,
      redirect: (context, s) {
        final path = s.uri.path;
        final gate = widget.accountGate;
        if (gate && !state.accountReady) {
          // The welcome and sign-in pages show their own loading cover.
          return ['/loading', '/welcome', '/gate'].contains(path)
              ? null
              : '/loading';
        }
        if (path == '/loading') return state.active == null ? '/welcome' : '/';
        if (state.active == null && path != '/welcome') return '/welcome';
        if (gate && path != '/welcome' && !state.accountGatePassed) {
          return path == '/gate' ? null : '/gate';
        }
        if (path == '/gate') return '/';
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
            GoRoute(
              path: 'stories',
              builder: (_, _) =>
                  reactive(() => StoryShelfScreen(state: state)),
            ),
          ],
        ),
        GoRoute(
          path: '/story/:id',
          redirect: (_, s) {
            final story = state.content.story(s.pathParameters['id']!);
            return story == null || !state.canPlayStory(story)
                ? '/stories'
                : null;
          },
          builder: (_, s) => PopScope(
            canPop: false,
            child: StoryPlayerScreen(
              key: ValueKey('story-${s.pathParameters['id']}'),
              state: state,
              story: state.content.story(s.pathParameters['id']!)!,
            ),
          ),
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
                fromPath: s.uri.queryParameters['from'] == 'path',
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/loading',
          builder: (_, _) => const AccountLoadingScreen(),
        ),
        GoRoute(
          path: '/gate',
          builder: (_, _) =>
              reactive(() => AccountGateScreen(state: state, auth: familyAuth)),
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
    // The start-up loading page takes the side of what comes next: upright
    // for a first start (onboarding), sideways for a set-up child.
    AppOrientation.apply(
      path == '/loading' ? (state.active == null ? '/welcome' : '/') : path,
    );
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
    state.billing.removeListener(_planChanged);
    unawaited(_links?.cancel());
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
