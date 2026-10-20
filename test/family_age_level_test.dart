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
import 'package:special_education_games/core/learning/age_band.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

// Linux target keeps the Play Billing plugin from connecting on the host.
final _host = TargetPlatformVariant.only(TargetPlatform.linux);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'upright family settings show the age band and shift it by one step',
    (tester) async {
      await tester.runAsync(() async {
        for (final entry in {
          'Nunito': 'assets/fonts/Nunito.ttf',
          'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        }.entries) {
          await (FontLoader(
            entry.key,
          )..addFont(rootBundle.load(entry.value))).load();
        }
      });
      for (final locale in ['tr', 'en']) {
        final state = (await tester.runAsync(() async {
          final state = AppState(
            await ContentRepository.load(),
            AppDatabase.forTesting(NativeDatabase.memory()),
            AudioService(),
          );
          await state.load();
          await state.completeOnboarding(
            name: 'Ada',
            survey: {'ageYears': 4, 'age': 1},
            dailyGoalMinutes: 15,
          );
          state.unlockFamily();
          return state;
        }))!;
        state.locale = locale;
        final l10n = lookupAppLocalizations(Locale(locale));
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
            // The app rebuilds routes on state changes the same way.
            home: ListenableBuilder(
              listenable: state,
              builder: (_, _) => FamilyScreen(state: state),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .widget<FamilyNavBar>(find.byType(FamilyNavBar))
            .onDestinationSelected!(3);
        await tester.pumpAndSettle();

        final band = find.byKey(const ValueKey('age-level-band'));
        await tester.scrollUntilVisible(
          band,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('family-list-3')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(tester.widget<Text>(band).data, l10n.ageBandExplore);
        expect(find.text(l10n.ageBandExploreInfo), findsOneWidget);

        await tester.ensureVisible(find.text(l10n.familyAgeLevelHarder));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.familyAgeLevelHarder));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pumpAndSettle();
        expect(state.ageBand, AgeBand.schoolReady);
        expect(tester.widget<Text>(band).data, l10n.ageBandSchoolReady);
        expect(
          find.text(l10n.familyAgeLevelFromAge(l10n.ageBandExplore)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: locale);
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      }
    },
    variant: _host,
  );
}
