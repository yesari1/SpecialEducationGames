import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/app/ui/family_nav_bar.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

/// Plays a few rounds per age band on a device and saves screenshots
/// (run with flutter drive and test_driver/integration_test.dart).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const ages = {
    2: 'first-steps',
    4: 'explore',
    6: 'school-ready',
    9: 'practice',
  };
  const games = [('animals', 'G01'), ('numbers', 'G33'), ('numbers', 'G01')];

  testWidgets('each age band plays rounds with its choices and numbers', (
    tester,
  ) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await tester.pump(const Duration(seconds: 2));
    final content = (await tester.runAsync(ContentRepository.load))!;
    await binding.convertFlutterSurfaceToImage();
    for (final MapEntry(key: age, value: label) in ages.entries) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final state = AppState(content, db, AudioService());
      await tester.runAsync(state.load);
      // Memory DB fixture only: QA plays every card like the QA APK.
      await tester.runAsync(() => state.entitlement.confirmStoreState(true));
      await tester.runAsync(
        () => state.createProfile('Test $age', 'cat', {'ageYears': age}),
      );
      state
        ..locale = 'tr'
        ..sound = false
        ..introduction = false
        ..hintSeconds = 0;
      state.audio.enabled = false;
      final band = state.ageBand!;
      expect(band, AgeBand.forAge(age));
      final tier = band.defaultTier;
      for (final (theme, game) in games) {
        await tester.pumpWidget(
          MaterialApp(
            theme: segTheme(),
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: GameScreen(
              key: ValueKey('$age-$theme-$game'),
              state: state,
              themeId: theme,
              gameId: game,
              difficulty: tier,
            ),
          ),
        );
        int? previous;
        for (var round = 0; round < 3; round++) {
          // Wait for a fresh round with every choice shown.
          RoundChoicesView? view;
          for (var i = 0; i < 150 && view == null; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            final found = find.byType(RoundChoicesView);
            if (found.evaluate().isEmpty) continue;
            final candidate = tester.widget<RoundChoicesView>(found);
            if (candidate.hint.generation != previous &&
                candidate.hint.visibleChoices ==
                    candidate.spec.choices.length) {
              view = candidate;
            }
          }
          if (view == null) {
            await binding.takeScreenshot('r31-$label-$theme-$game-stuck');
            fail('$label $theme $game: no round $round');
          }
          await tester.pump(const Duration(milliseconds: 400));
          previous = view.hint.generation;
          final spec = view.spec, generation = view.hint.generation;
          final reason = '$label $theme $game round $round';
          expect(spec.choices.length, band.choices(tier), reason: reason);
          if (theme == 'numbers') {
            final limit = game == 'G33'
                ? band.countableMax(tier)
                : band.maxNumber(tier);
            for (final item in spec.choices) {
              expect(
                int.parse(item.slug),
                lessThanOrEqualTo(limit),
                reason: reason,
              );
            }
          }
          if (round < 2) {
            await binding.takeScreenshot('r31-$label-$theme-$game-$round');
          }
          final target = find.byKey(ValueKey('$generation:${spec.target.id}'));
          for (var page = 0; page < 3 && target.evaluate().isEmpty; page++) {
            await tester.tap(find.byKey(const ValueKey('choices-next')));
            await tester.pumpAndSettle();
          }
          await tester.tap(target);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));
      state.dispose();
      await tester.runAsync(db.close);
    }
  });

  testWidgets('family settings show the age level card upright', (
    tester,
  ) async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await tester.pump(const Duration(seconds: 2));
    final content = (await tester.runAsync(ContentRepository.load))!;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final state = AppState(content, db, AudioService());
    await tester.runAsync(state.load);
    await tester.runAsync(
      () => state.createProfile('Ada', 'cat', {'ageYears': 4, 'age': 1}),
    );
    state.locale = 'tr';
    state.unlockFamily();
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    final shift = find.byKey(const ValueKey('age-level-shift'));
    await tester.scrollUntilVisible(
      shift,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('family-list-3')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    // Show the whole card: title, band, explanation and the shift buttons.
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('age-level-band'))),
      alignment: 0.12,
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('r31-family-age-level');
    await tester.tap(find.text('Daha zor'));
    for (var i = 0; i < 20 && state.ageBand != AgeBand.schoolReady; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(state.ageBand, AgeBand.schoolReady);
    await binding.takeScreenshot('r31-family-age-level-harder');
    await tester.pumpWidget(const SizedBox.shrink());
    state.lockFamily();
    state.dispose();
    await tester.runAsync(db.close);
  });
}
