import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> setup(WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Test', 'cat', {});
    return state;
  }

  Future<void> dispose(WidgetTester tester, AppState state) async {
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets(
    'New badge is localized and limited to configured visible category',
    (tester) async {
      final state = await setup(tester);
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
        newBadge: const {'animals', 'vehicles'},
        hiddenThemes: const {'vehicles'},
      );
      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(key: ValueKey(locale), state: state),
          ),
        );
        await tester.pumpAndSettle();
        final cards = tester
            .widgetList<ThemeGameCard>(find.byType(ThemeGameCard))
            .toList();
        final badged = cards.where((c) => c.badgeText != null).toList();
        expect(badged.single.theme.id, 'animals');
        expect(badged.single.badgeText, locale == 'tr' ? 'Yeni' : 'New');
        expect(cards.any((c) => c.theme.id == 'vehicles'), isFalse);
        expect(find.text(locale == 'tr' ? 'Yeni' : 'New'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await dispose(tester, state);
    },
  );

  testWidgets(
    'Paywall uses configured language title and localized fallback without inventing products',
    (tester) async {
      final state = await setup(tester);
      state.unlockFamily();
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
        paywallText: const {
          'tr': 'Daha fazla birlikte keşif',
          'en': 'Explore more together',
        },
      );
      String headline() => tester
          .widget<Text>(find.byKey(const ValueKey('paywall-headline')))
          .data!;
      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        await tester.pumpWidget(
          MaterialApp(
            home: SubscriptionScreen(key: ValueKey(locale), state: state),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          headline(),
          locale == 'tr'
              ? 'Daha fazla birlikte keşif'
              : 'Explore more together',
        );
        // No store on the host: no plan is invented, a retry is offered.
        expect(state.billing.plans, isEmpty);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'paywall-option-',
                ),
          ),
          findsNothing,
        );
        expect(
          find.text(
            locale == 'tr'
                ? 'Planlar yüklenemedi.'
                : 'Plans could not be loaded.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
      );
      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        await tester.pumpWidget(
          MaterialApp(
            home: SubscriptionScreen(
              key: ValueKey('fallback-$locale'),
              state: state,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          headline(),
          locale == 'tr' ? 'Tüm oyunları aç' : 'Unlock every game',
        );
        expect(state.billing.plans, isEmpty);
      }
      await dispose(tester, state);
    },
  );

  testWidgets('Configured paywall remains behind parent route guard', (
    tester,
  ) async {
    final state = await setup(tester);
    state.configuration = AppConfiguration(
      freeGames: content.freeGames.toSet(),
      paywallText: const {'en': 'Parent only discoveries'},
    );
    state.locale = 'en';
    await tester.pumpWidget(EducationApp(state: state));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go('/family/subscription');
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsNothing);
    expect(find.text('Parent only'), findsNothing);
    expect(find.text('discoveries'), findsNothing);
    state.unlockFamily();
    router.go('/family/subscription');
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsOneWidget);
    expect(find.text('Parent only discoveries'), findsOneWidget);
    await dispose(tester, state);
  });

  testWidgets(
    'Remote presentation refresh waits for all active games to exit',
    (tester) async {
      final state = await setup(tester);
      state.configuration = AppConfiguration(
        freeGames: content.freeGames.toSet(),
      );
      var notifications = 0;
      state.addListener(() => notifications++);
      state.enterGame();
      state.enterGame();
      var fetches = 0;
      await state.refreshConfiguration(() async {
        fetches++;
        return {
          'newBadge': ['animals'],
          'paywallText': {'tr': 'Yeni keşifler', 'en': 'Fresh discoveries'},
          'difficultyDefaults': {
            'fadeAfterErrors': 3,
            'choiceCounts': {'easy': 2, 'medium': 2, 'hard': 3},
          },
        };
      });
      expect(fetches, 1);
      expect(state.configuration.newBadge, isEmpty);
      expect(state.configuration.paywallText, isEmpty);
      expect(state.configuration.fadeAfterErrors, 2);
      expect(state.configuration.choicesFor(Difficulty.medium), 3);
      expect(notifications, 0);
      state.leaveGame();
      await tester.pump();
      expect(state.configuration.newBadge, isEmpty);
      expect(state.configuration.fadeAfterErrors, 2);
      expect(state.configuration.choicesFor(Difficulty.medium), 3);
      expect(notifications, 0);
      state.leaveGame();
      await tester.pump();
      expect(state.configuration.newBadge, {'animals'});
      expect(state.configuration.paywallText['en'], 'Fresh discoveries');
      expect(state.configuration.fadeAfterErrors, 3);
      expect(state.configuration.choicesFor(Difficulty.medium), 2);
      expect(notifications, 1);
      await dispose(tester, state);
    },
  );
}
