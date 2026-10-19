import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/onboarding/welcome_pane.dart';
import 'package:special_education_games/l10n/scoped_localizations.dart';

void main() {
  Future<AppState> buildState(WidgetTester tester) async {
    final state = (await tester.runAsync(() async {
      final s = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      return s;
    }))!;
    return state;
  }

  Future<void> loadFonts(WidgetTester tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
  }

  Widget wrap({
    required AppState state,
    required String language,
    required double scale,
    required VoidCallback onContinue,
    required Key key,
  }) {
    return MaterialApp(
      theme: segTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: WelcomePane(key: key, state: state, onContinue: onContinue),
    );
  }

  testWidgets(
    'Overview shows all five texts at once in two columns, compact pages '
    'navigate via real controls',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      final state = await buildState(tester);
      addTearDown(state.dispose);
      await loadFonts(tester);

      for (final language in ['tr', 'en']) {
        state.locale = language;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          for (final scale in [1.0, 1.6, 2.0]) {
            var tapped = false;
            await tester.pumpWidget(
              wrap(
                state: state,
                language: language,
                scale: scale,
                onContinue: () => tapped = true,
                key: ValueKey('$language-$size-$scale'),
              ),
            );
            await tester.pumpAndSettle();

            final verticalScrollables = tester
                .widgetList<Scrollable>(find.byType(Scrollable))
                .where(
                  (scrollable) =>
                      scrollable.axisDirection == AxisDirection.down ||
                      scrollable.axisDirection == AxisDirection.up,
                );
            expect(
              verticalScrollables,
              isEmpty,
              reason: '$language $size $scale must not scroll vertically',
            );

            final start = find.byKey(const ValueKey('welcome-start'));
            expect(start, findsOneWidget);
            final bounds = tester.getRect(start);
            expect(
              bounds.top,
              greaterThanOrEqualTo(0),
              reason: '$language $size $scale',
            );
            expect(
              bounds.bottom,
              lessThanOrEqualTo(size.height),
              reason: '$language $size $scale',
            );
            expect(bounds.height, greaterThanOrEqualTo(64));

            final l10n = scopedLocalizations(
              tester.element(find.byType(WelcomePane)),
              language,
            );
            final expected = [
              l10n.welcomeTitle,
              l10n.welcomeSubtitle,
              l10n.noAdsOffline,
              l10n.parentGateSettings,
              l10n.noAccountNeeded,
            ];

            final compact = size.height < 500 && scale > 1.25;
            if (!compact) {
              for (var i = 0; i < expected.length; i++) {
                final finder = find
                    .text(expected[i], skipOffstage: false)
                    .hitTestable();
                expect(
                  finder,
                  findsOneWidget,
                  reason: '$language $size $scale text $i',
                );
                final rect = tester.getRect(finder);
                expect(rect.left, greaterThanOrEqualTo(0));
                expect(rect.right, lessThanOrEqualTo(size.width));
                expect(rect.top, greaterThanOrEqualTo(0));
                expect(rect.bottom, lessThanOrEqualTo(size.height));
                expect(
                  rect.bottom,
                  lessThan(tester.getRect(start).top),
                  reason: '$language $size $scale text $i must sit above CTA',
                );
              }
              expect(find.byKey(const ValueKey('welcome-next')), findsNothing);
              expect(
                find.byKey(const ValueKey('welcome-previous')),
                findsNothing,
              );
              await tester.tap(start);
              expect(tapped, isTrue);
              tapped = false;
              expect(tester.takeException(), isNull);
              continue;
            }

            // Compact mode: each of the 5 texts reachable via real controls.
            expect(find.byKey(const ValueKey('welcome-next')), findsOneWidget);
            expect(
              find.byKey(const ValueKey('welcome-previous')),
              findsOneWidget,
            );
            expect(find.text(expected[0], skipOffstage: false), findsOneWidget);
            for (var page = 0; page < expected.length; page++) {
              final current = find
                  .text(expected[page], skipOffstage: false)
                  .hitTestable();
              expect(
                current,
                findsOneWidget,
                reason: '$language $size $scale page $page',
              );
              final rect = tester.getRect(current);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(size.width));
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(rect.bottom, lessThanOrEqualTo(size.height));
              expect(
                rect.bottom,
                lessThan(tester.getRect(start).top),
                reason: '$language $size $scale page $page above CTA',
              );
              if (page < expected.length - 1) {
                await tester.tap(find.byKey(const ValueKey('welcome-next')));
                await tester.pumpAndSettle();
                expect(tapped, isFalse, reason: 'next must not continue $page');
              }
            }
            for (var page = expected.length - 1; page > 0; page--) {
              await tester.tap(find.byKey(const ValueKey('welcome-previous')));
              await tester.pumpAndSettle();
              expect(
                tapped,
                isFalse,
                reason: 'previous must not continue $page',
              );
              expect(
                find
                    .text(expected[page - 1], skipOffstage: false)
                    .hitTestable(),
                findsOneWidget,
                reason: '$language $size $scale back to page ${page - 1}',
              );
            }
            await tester.tap(start);
            expect(tapped, isTrue);
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
