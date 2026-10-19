import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/play_time_break.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> buildState(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final state = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await state.load();
        return state;
      }))!;

  Future<void> loadFonts(WidgetTester tester) async {
    await tester.runAsync(() async {
      final nunito = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
      await nunito.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
  }

  testWidgets(
    'Time break stays bounded in landscape and preserves guarded actions',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      await loadFonts(tester);
      final state = await buildState(tester);
      addTearDown(state.dispose);
      final scale = ValueNotifier(1.0);
      addTearDown(scale.dispose);
      final router = GoRouter(
        initialLocation: '/break',
        routes: [
          GoRoute(
            path: '/break',
            builder: (context, route) => ListenableBuilder(
              listenable: state,
              builder: (context, _) => PlayTimeBreak(state: state),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (context, route) => const Text('home destination'),
          ),
        ],
      );
      addTearDown(router.dispose);

      for (final language in ['tr', 'en']) {
        state.locale = language;
        state.notifyListeners();
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          for (final textScale in [1.0, 1.6, 2.0]) {
            scale.value = textScale;
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

            final expectedTitle = language == 'tr'
                ? 'Bugünlük bu kadar, harikaydın!'
                : 'That’s enough for today. You did great!';
            final expectedSubtitle = language == 'tr'
                ? 'Şimdi küçük bir mola verelim.'
                : 'Let’s take a little break now.';
            expect(
              find.text(expectedTitle),
              findsOneWidget,
              reason:
                  '$language $size x$textScale; current=${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).toList()}',
            );
            expect(find.text(expectedSubtitle), findsOneWidget);
            final vertical = tester
                .widgetList<Scrollable>(find.byType(Scrollable))
                .where(
                  (scrollable) =>
                      scrollable.axisDirection == AxisDirection.down ||
                      scrollable.axisDirection == AxisDirection.up,
                );
            expect(vertical, isEmpty, reason: '$language $size x$textScale');

            if (find
                .byKey(const ValueKey('time-limit-pages'))
                .evaluate()
                .isNotEmpty) {
              expect(
                tester
                    .getRect(find.byKey(const ValueKey('time-limit-next')))
                    .height,
                greaterThanOrEqualTo(48),
              );
              await tester.tap(find.byKey(const ValueKey('time-limit-next')));
              await tester.pumpAndSettle();
              expect(
                find.text(language == 'tr' ? 'Mola · 2 / 2' : 'Break · 2 of 2'),
                findsOneWidget,
              );
              expect(
                find.byTooltip(
                  language == 'tr' ? 'Önceki sayfa' : 'Previous page',
                ),
                findsOneWidget,
              );
            }

            final home = find.byKey(const ValueKey('time-limit-home'));
            final extend = find.byKey(const ValueKey('time-limit-extend'));
            expect(home, findsOneWidget, reason: '$language $size x$textScale');
            expect(
              extend,
              findsOneWidget,
              reason: '$language $size x$textScale',
            );
            for (final action in [home, extend]) {
              final rect = tester.getRect(action);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(size.width));
              expect(rect.bottom, lessThanOrEqualTo(size.height));
              expect(rect.height, greaterThanOrEqualTo(48));
            }
            expect(tester.takeException(), isNull);

            if (find
                .byKey(const ValueKey('time-limit-pages'))
                .evaluate()
                .isNotEmpty) {
              await tester.tap(
                find.byKey(const ValueKey('time-limit-previous')),
              );
              await tester.pumpAndSettle();
              expect(find.text(expectedTitle), findsOneWidget);
            }
          }
        }
      }

      final extend = find.byKey(const ValueKey('time-limit-extend'));
      tester.widget<HoldButton>(extend).onHeld();
      await tester.pumpAndSettle();
      expect(find.text('To continue'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(PlayTimeBreak), findsOneWidget);
      expect(find.text('home destination'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('time-limit-home')));
      await tester.pumpAndSettle();
      expect(find.text('home destination'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
