import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> makeState() async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Mina', 'cat', {});
    state.sound = false;
    state.audio.enabled = false;
    return state;
  }

  testWidgets(
    'Completed summary and actions stay reachable at landscape sizes and text scales',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final state = await tester.runAsync(makeState);
      addTearDown(state!.dispose);
      final scale = ValueNotifier(1.0);
      addTearDown(scale.dispose);
      final router = GoRouter(
        initialLocation: '/game/vehicles/G02/easy',
        routes: [
          GoRoute(
            path: '/game/:theme/:game/:tier',
            builder: (context, route) => ListenableBuilder(
              listenable: state,
              builder: (context, _) => GameScreen(
                state: state,
                themeId: route.pathParameters['theme']!,
                gameId: route.pathParameters['game']!,
                difficulty: Difficulty.values.byName(
                  route.pathParameters['tier']!,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (context, route) => const Text('path destination'),
          ),
          GoRoute(
            path: '/theme/:id',
            builder: (context, route) => const Text('theme destination'),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: segTheme(),
          routerConfig: router,
          builder: (context, child) => ValueListenableBuilder<double>(
            valueListenable: scale,
            builder: (context, value, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(value)),
              child: child!,
            ),
            child: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(ItemVisual), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }
      await tester.pump();
      final finish = find.byKey(const ValueKey('explore-finish'));
      expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('completion-summary')), findsOneWidget);

      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        state.notifyListeners();
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          for (final value in [1.0, 1.6, 2.0]) {
            scale.value = value;
            await tester.pump();
            expect(
              find.text(state.tr('Aferin!', 'Well done!')),
              findsOneWidget,
            );
            final labels = [
              state.tr('Tekrar', 'Again'),
              state.tr('Bugünün Yolu', 'Today’s Path'),
              state.tr('Temaya dön', 'Back to theme'),
            ];
            for (final label in labels) {
              expect(find.text(label), findsOneWidget);
              final rect = tester.getRect(find.text(label));
              expect(rect.bottom, lessThanOrEqualTo(size.height));
              expect(rect.top, greaterThanOrEqualTo(0));
            }
            expect(_verticalScrollables(tester), isEmpty);
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.tap(find.text(state.tr('Temaya dön', 'Back to theme')));
      await tester.pumpAndSettle();
      expect(find.text('theme destination'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

Iterable<Scrollable> _verticalScrollables(WidgetTester tester) => tester
    .widgetList<Scrollable>(find.byType(Scrollable))
    .where(
      (scrollable) =>
          scrollable.axisDirection == AxisDirection.down ||
          scrollable.axisDirection == AxisDirection.up,
    );
