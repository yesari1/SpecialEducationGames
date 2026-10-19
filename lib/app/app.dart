import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'app_state.dart';
import 'theme/tokens.dart';
import '../core/content/content_repository.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/child_home/home_screen.dart';
import '../features/family/family_screen.dart';
import '../features/family/subscription_screen.dart';
import '../features/family/credits_screen.dart';
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
        ),
        GoRoute(
          path: '/welcome',
          builder: (_, _) => reactive(() => OnboardingScreen(state: state)),
        ),
        GoRoute(
          path: '/theme/:id',
          builder: (_, s) => reactive(
            () => ThemeScreen(state: state, themeId: s.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/game/:theme/:game/:tier',
          builder: (_, s) => reactive(
            () => GameScreen(
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
        GoRoute(
          path: '/family',
          builder: (_, _) => reactive(() => FamilyScreen(state: state)),
        ),
        GoRoute(
          path: '/family/subscription',
          builder: (_, _) => reactive(() => SubscriptionScreen(state: state)),
        ),
        GoRoute(
          path: '/family/credits',
          builder: (_, _) => reactive(() => CreditsScreen(state: state)),
        ),
        GoRoute(
          path: '/family/account',
          builder: (_, _) => reactive(
            () => FamilyAccountScreen(state: state, auth: familyAuth),
          ),
        ),
        GoRoute(
          path: '/family/profile/:id',
          builder: (_, s) => reactive(
            () => ProfileEditorScreen(
              state: state,
              profileId: s.pathParameters['id'] == 'new'
                  ? null
                  : s.pathParameters['id'],
            ),
          ),
        ),
      ],
      errorBuilder: (_, _) => HomeScreen(state: state),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed) {
      state.audio.stop();
      state.lockFamily();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    familyAuth.removeListener(_accountChanged);
    familyAuth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (_, _) => MaterialApp.router(
      title: state.tr('Özel Eğitim Oyunları', 'Special Education Games'),
      debugShowCheckedModeBanner: false,
      theme: segTheme(),
      routerConfig: router,
      locale: Locale(state.locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}
