import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/family_nav_bar.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';
import 'package:special_education_games/features/profiles/profile_editor_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

// Linux target keeps the Play Billing plugin from connecting on the host.
final _host = TargetPlatformVariant.only(TargetPlatform.linux);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<void> loadFonts(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(rootBundle.load(entry.value));
        await loader.load();
      }
    });
  }

  Future<AppState> makeState(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final state = AppState(
          content,
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await state.load();
        await state.completeOnboarding(
          name: 'Ada',
          survey: {'ageYears': 5, 'age': 1},
          dailyGoalMinutes: 15,
        );
        state.unlockFamily();
        return state;
      }))!;

  Future<void> mount(
    WidgetTester tester,
    Widget screen,
    String locale,
    double scale,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'upright family tabs scroll vertically without overflow at 1x and 2x',
    (tester) async {
      await loadFonts(tester);
      for (final locale in ['tr', 'en']) {
        for (final scale in [1.0, 2.0]) {
          final state = await makeState(tester);
          state.locale = locale;
          await mount(tester, FamilyScreen(state: state), locale, scale);
          final tag = '$locale x$scale';
          expect(tester.takeException(), isNull, reason: tag);
          final bar = find.byType(FamilyNavBar);
          expect(bar, findsOneWidget, reason: tag);
          expect(
            tester.getRect(bar).bottom,
            lessThanOrEqualTo(915),
            reason: tag,
          );
          for (var tab = 0; tab < 4; tab++) {
            tester.widget<FamilyNavBar>(bar).onDestinationSelected!(tab);
            await tester.pumpAndSettle();
            expect(
              find.byKey(ValueKey('family-list-$tab')),
              findsOneWidget,
              reason: '$tag tab $tab uses the upright list',
            );
            await tester.fling(
              find.byKey(ValueKey('family-list-$tab')),
              const Offset(0, -3000),
              3000,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$tag tab $tab');
          }
          await tester.pumpWidget(const SizedBox.shrink());
          state.dispose();
        }
      }
    },
    variant: _host,
  );

  testWidgets('upright subscription and profile editor stay readable at 2x', (
    tester,
  ) async {
    await loadFonts(tester);
    for (final locale in ['tr', 'en']) {
      final state = await makeState(tester);
      state.locale = locale;
      await mount(tester, SubscriptionScreen(state: state), locale, 2);
      expect(tester.takeException(), isNull, reason: '$locale paywall');
      expect(find.byType(PageView), findsNothing, reason: locale);

      await mount(
        tester,
        ProfileEditorScreen(state: state, profileId: state.active!.id),
        locale,
        2,
      );
      expect(tester.takeException(), isNull, reason: '$locale editor');
      expect(find.byKey(const ValueKey('profile-initial')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-editor-continue')));
      await tester.pumpAndSettle();
      // The first question is the exact-age grid, with 5 preselected.
      expect(find.byKey(const ValueKey('profile-age-grid')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-age-7')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$locale age');
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    }
  }, variant: _host);
}
