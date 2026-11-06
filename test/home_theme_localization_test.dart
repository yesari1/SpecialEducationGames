import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> createState(
    String locale, {
    ContentRepository? repository,
  }) async {
    final state = AppState(
      repository ?? content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Ada', 'cat', {});
    state.locale = locale;
    return state;
  }

  GoRouter routerFor(AppState state, {String initialLocation = '/'}) =>
      GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => HomeScreen(state: state),
          ),
          GoRoute(
            path: '/theme/:id',
            builder: (_, route) =>
                ThemeScreen(state: state, themeId: route.pathParameters['id']!),
          ),
          GoRoute(
            path: '/game/:theme/:game/:tier',
            builder: (_, route) => Text('game:${route.pathParameters['game']}'),
          ),
        ],
      );

  Future<void> pumpApp(
    WidgetTester tester,
    AppState state,
    GoRouter router,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: segTheme(),
        locale: Locale(state.locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> cleanup(
    WidgetTester tester,
    AppState state,
    GoRouter router,
  ) async {
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    state.dispose();
    await state.db.close();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets('Home card copy and theme route use typed locale resources', (
    tester,
  ) async {
    for (final locale in ['tr', 'en']) {
      final state = await createState(locale);
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
        newBadge: const {'animals'},
        featuredTheme: 'animals',
      );
      final router = routerFor(state);
      await pumpApp(tester, state, router);
      final l10n = lookupAppLocalizations(Locale(locale));

      expect(find.text(l10n.greeting('Ada')), findsOneWidget);
      expect(find.text(l10n.homeNewBadge), findsOneWidget);
      final firstThemeCard = find.byType(ThemeGameCard).first;
      expect(tester.widget<ThemeGameCard>(firstThemeCard).theme.id, 'animals');
      expect(
        find.descendant(
          of: firstThemeCard,
          matching: find.text(
            l10n.homeThemeGameCount(state.gamesForTheme('animals').length),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(firstThemeCard);
      await tester.pumpAndSettle();
      final theme = content.theme('animals');
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/theme/animals',
      );
      expect(find.text(theme.name(locale)).first, findsOneWidget);
      expect(find.byTooltip(l10n.themeBack), findsOneWidget);
      expect(find.text(l10n.difficultyEasy), findsOneWidget);
      expect(find.text(l10n.difficultyMedium), findsOneWidget);
      expect(find.text(l10n.difficultyHard), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.themeBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.greeting('Ada')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cleanup(tester, state, router);
    }
  });

  testWidgets('Locked theme game shows localized family-access message', (
    tester,
  ) async {
    for (final locale in ['tr', 'en']) {
      final state = await createState(locale);
      state.configuration = AppConfiguration(
        freeGames: const {},
        gameOrder: const {
          'animals': ['G02'],
        },
      );
      final router = routerFor(state, initialLocation: '/theme/animals');
      await pumpApp(tester, state, router);
      final l10n = lookupAppLocalizations(Locale(locale));
      expect(find.byType(ThemeGameCard), findsOneWidget);
      expect(
        tester.widget<ThemeGameCard>(find.byType(ThemeGameCard)).locked,
        isTrue,
      );

      await tester.tap(find.byType(ThemeGameCard));
      await tester.pumpAndSettle();
      expect(find.text(l10n.lockedGameTitle), findsOneWidget);
      expect(find.text(l10n.lockedGameBody), findsOneWidget);
      expect(find.text('game:G02'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('locked-game-ok')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.lockedGameTitle), findsNothing);
      expect(tester.takeException(), isNull);
      await cleanup(tester, state, router);
    }
  });

  testWidgets(
    'Unavailable G14 Hard shows content message before family access',
    (tester) async {
      final withoutFish = ContentRepository(
        content.themes,
        content.items.where((item) => item.id != 'animals.fish').toList(),
        content.games,
        content.freeGames,
        content.configDefaults,
      );
      for (final locale in ['tr', 'en']) {
        final state = await createState(locale, repository: withoutFish);
        state.configuration = AppConfiguration(
          freeGames: const {},
          gameOrder: const {
            'animals': ['G14'],
          },
        );
        state.difficultyOverride = 'hard';
        state.onlyFree = false;
        expect(state.entitlement.isPremium, isFalse);
        expect(state.canPlay('animals', 'G14', Difficulty.hard), isFalse);
        expect(
          withoutFish.isGameContentAvailable('animals', 'G14', Difficulty.hard),
          isFalse,
        );

        final router = routerFor(state, initialLocation: '/theme/animals');
        await pumpApp(tester, state, router);
        final card = find.byType(ThemeGameCard);
        expect(card, findsOneWidget);
        expect(tester.widget<ThemeGameCard>(card).locked, isTrue);

        await tester.tap(card);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final l10n = lookupAppLocalizations(Locale(locale));
        expect(
          find.text(l10n.gameThereIsNotEnoughContentForThis),
          findsOneWidget,
        );
        expect(find.text('game:G14'), findsNothing);
        expect(tester.takeException(), isNull);
        await cleanup(tester, state, router);
      }
    },
  );

  testWidgets('Empty filtered theme list shows localized empty-state copy', (
    tester,
  ) async {
    for (final locale in ['tr', 'en']) {
      final state = await createState(locale);
      final animalGames = content.theme('animals').games;
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
        disabledGames: animalGames.map((game) => 'animals_$game').toSet(),
      );
      final router = routerFor(state, initialLocation: '/theme/animals');
      await pumpApp(tester, state, router);
      expect(
        find.text(lookupAppLocalizations(Locale(locale)).themeNoUnlockedGames),
        findsOneWidget,
      );
      expect(find.byType(ThemeGameCard), findsNothing);
      expect(tester.takeException(), isNull);
      await cleanup(tester, state, router);
    }
  });
}
