import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:drift/native.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/round_controller.dart';
import 'package:special_education_games/features/game/widgets/tap_discovery.dart';
import 'package:special_education_games/features/game/play_time_break.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/onboarding/survey_questions.dart';
import 'package:special_education_games/features/family/credits_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Daily active-play limit pauses, blocks re-entry, and extends through PIN',
    (tester) async {
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await state.load();
      await state.createProfile('Mola', 'cat', {});
      await state.setting('sound', 'false');
      await state.setting('introduction', 'false');
      state.unlockFamily();
      await state.setting('locale', 'en');
      await state.setting('screenLimitMinutes', '10');
      await state.setParentPin('4826');
      state.lockFamily();
      await tester.pumpWidget(EducationApp(state: state));
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/game/animals/G01/easy');
      await tester.pumpAndSettle();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      final pausedTime = state.dailyPlayTime.usedMs;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      expect(
        state.dailyPlayTime.usedMs,
        pausedTime,
        reason: 'Background does not consume allowance',
      );
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await state.chargePlayTime(
        state.active!.id,
        (600000 - state.dailyPlayTime.usedMs - 500).clamp(0, 600000),
      );
      for (
        var i = 0;
        i < 15 && find.byType(PlayTimeBreak).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
      }
      expect(find.byType(PlayTimeBreak), findsOneWidget);
      expect(state.playTimeExpired, true);
      final dynamic pausedScreen = tester.state(find.byType(GameScreen));
      expect((pausedScreen.controller as RoundController).paused, true);
      await tester.tap(find.byKey(const ValueKey('time-limit-home')));
      await tester.pumpAndSettle();
      router.go('/game/animals/G01/easy');
      await tester.pumpAndSettle();
      expect(find.byType(PlayTimeBreak), findsOneWidget);
      final dynamic blockedScreen = tester.state(find.byType(GameScreen));
      expect(blockedScreen.controller, isNull);
      await expectLater(state.extendPlayTime(), throwsStateError);
      await tester.ensureVisible(
        find.byKey(const ValueKey('time-limit-extend')),
      );
      final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('time-limit-extend'))),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2200)),
      );
      await tester.pump();
      await hold.up();
      await tester.pumpAndSettle();
      expect(
        find.byType(Dialog),
        findsOneWidget,
        reason: 'Real two-second parent hold opens the fullscreen gate',
      );
      expect(find.text('Enter PIN'), findsOneWidget);
      for (final digit in ['4', '8', '2', '5']) {
        await tester.ensureVisible(find.widgetWithText(FilledButton, digit));
        await tester.tap(find.widgetWithText(FilledButton, digit));
        await tester.pump();
      }
      await tester.ensureVisible(find.widgetWithText(FilledButton, '✓'));
      await tester.tap(find.widgetWithText(FilledButton, '✓'));
      await tester.pumpAndSettle();
      expect(
        state.playTimeExpired,
        true,
        reason: 'Wrong PIN grants no extra time',
      );
      expect(find.text('Try your PIN again.'), findsOneWidget);
      for (final digit in ['4', '8', '2', '6']) {
        await tester.ensureVisible(find.widgetWithText(FilledButton, digit));
        await tester.tap(find.widgetWithText(FilledButton, digit));
        await tester.pump();
      }
      await tester.ensureVisible(find.widgetWithText(FilledButton, '✓'));
      await tester.tap(find.widgetWithText(FilledButton, '✓'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(state.playTimeRemainingMs, greaterThan(590000));
      expect(tester.takeException(), isNull);
      router.go('/game/animals/G01/easy');
      await tester.pumpAndSettle();
      expect(find.byType(PlayTimeBreak), findsNothing);
      router.go('/');
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Animal sound round becomes answerable on Android; muted game is guarded',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.setPreference('locale', 'tr');
      final state = AppState(
        await ContentRepository.load(),
        db,
        AudioService(),
      );
      await state.load();
      await state.createProfile('Ses', 'cat', {});
      await state.setting('sound', 'false');
      await tester.pumpWidget(EducationApp(state: state));
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/game/animals/G10/easy');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Bu oyun için ses gerekli. Ebeveyn ayarlarından sesi açabilirsiniz.',
        ),
        findsOneWidget,
      );
      router.go('/');
      await tester.pumpAndSettle();
      await state.setting('sound', 'true');
      state.unlockFamily();
      await state.setting('effectVolume', '0');
      state.lockFamily();
      router.go('/game/animals/G10/easy');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Bu oyun için ses gerekli. Ebeveyn ayarlarından sesi açabilirsiniz.',
        ),
        findsOneWidget,
      );
      final dynamic silentScreen = tester.state(find.byType(GameScreen));
      expect(silentScreen.controller, isNull);
      router.go('/');
      await tester.pumpAndSettle();
      state.unlockFamily();
      await state.setting('effectVolume', '60');
      state.lockFamily();
      router.go('/game/animals/G10/easy');
      await tester.pumpAndSettle();
      final dynamic screen = tester.state(find.byType(GameScreen));
      final RoundController c = screen.controller;
      // Native playback or its bounded fallback must finish.
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (c.phase != RoundPhase.answering &&
          DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(c.phase, RoundPhase.answering);
      expect(c.error, isNull);
      expect(c.spec!.target.sfx, isNotNull);
      router.go('/');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      state.dispose();
    },
  );
  testWidgets(
    'Onboarding, hints, completed round, protected reports, English',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.setPreference('locale', 'tr');
      final state = AppState(
        await ContentRepository.load(),
        db,
        AudioService(),
      );
      await state.load();
      await state.setting('sound', 'false');
      await state.setting('introduction', 'false');
      await tester.pumpWidget(EducationApp(state: state));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Birlikte başlayalım'));
      await tester.tap(find.text('Birlikte başlayalım'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Deniz');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Devam et'));
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();
      for (var i = 0; i < surveyQuestions.length; i++) {
        await tester.ensureVisible(find.text('Bu soruyu atla'));
        await tester.tap(find.text('Bu soruyu atla'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Oyunlara geç'));
      await tester.tap(find.text('Oyunlara geç'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(state.active!.nickname, 'Deniz');

      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/family');
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      router.go('/game/animals/G01/easy');
      await tester.pumpAndSettle();
      final dynamic screen = tester.state(find.byType(GameScreen));
      final RoundController c = screen.controller;
      for (var stage = 0; stage < c.total; stage++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (stage == 0) {
          final wrong = c.spec!.choices.firstWhere(
            (x) => x.id != c.spec!.target.id,
          );
          final wrongFinder = find.byWidgetPredicate(
            (w) => w is ItemVisual && w.item.id == wrong.id,
          );
          await tester.tap(wrongFinder);
          await tester.pump();
          await tester.tap(wrongFinder);
          await tester.pump(const Duration(milliseconds: 650));
          expect(c.hint, 4);
        }
        final target = c.spec!.target.id;
        await tester.tap(
          find.byWidgetPredicate((w) => w is ItemVisual && w.item.id == target),
        );
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();
      }
      expect(state.trials.length, 4);
      expect(state.trials.first.maxHint, 4);
      expect(find.text('Aferin!'), findsOneWidget);
      expect(state.dailyPath.completed, contains('animals_G01'));

      expect(find.text('Aferin!'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('completion-next')));
      await tester.pumpAndSettle();
      expect(find.text('Özet · sayfa 2 / 2'), findsOneWidget);
      await tester.tap(find.text('Temaya dön'));
      await tester.pumpAndSettle();
      state.unlockFamily();
      router.go('/family');
      await tester.pumpAndSettle();
      expect(find.text('Gelişim'), findsWidgets);

      await state.setting('locale', 'en');
      await tester.pumpAndSettle();
      expect(find.text('Progress'), findsWidgets);

      router.go('/family/credits');
      await tester.pumpAndSettle();
      expect(find.byType(CreditsScreen), findsOneWidget);
      final creditsVerticalScrollables = tester
          .widgetList<Scrollable>(
            find.descendant(
              of: find.byType(CreditsScreen),
              matching: find.byType(Scrollable),
            ),
          )
          .where(
            (scrollable) =>
                scrollable.axisDirection == AxisDirection.down ||
                scrollable.axisDirection == AxisDirection.up,
          );
      expect(creditsVerticalScrollables, isEmpty);
      await tester.tap(find.byKey(const ValueKey('credits-group-photos')));
      await tester.pumpAndSettle();
      expect(find.text('animals.cat'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('credits-field-0-author')),
        findsOneWidget,
      );
      expect(find.textContaining('Matsu1024'), findsOneWidget);
      var photoRecord = 0;
      for (
        var attempt = 0;
        attempt < 20 && find.text('produce.banana').evaluate().isEmpty;
        attempt++
      ) {
        await tester.tap(find.byKey(const ValueKey('credits-next-record')));
        await tester.pumpAndSettle();
        photoRecord++;
      }
      expect(find.text('produce.banana'), findsOneWidget);
      expect(
        find.byKey(ValueKey('credits-field-$photoRecord-author')),
        findsOneWidget,
      );
      expect(find.textContaining('Evan-Amos'), findsOneWidget);

      state.lockFamily();
      router.go('/');
      await tester.pumpAndSettle();
      await state.entitlement.confirmStoreState(
        true,
      ); // Isolated in-memory test fixture.
      for (final size in [const Size(800, 360), const Size(1280, 800)]) {
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        await binding.setSurfaceSize(size);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Home at $size');
        router.go('/theme/animals');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Theme at $size');
        router.go('/game/animals/G01/medium');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Game at $size');
        router.go('/game/animals/G36/medium');
        await tester.pumpAndSettle();
        final dynamic quantityScreen = tester.state(find.byType(GameScreen));
        expect((quantityScreen.controller as RoundController).gameId, 'G36');
        expect(
          (quantityScreen.controller as RoundController).spec!.quantities,
          isNotEmpty,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Quantity comparison at $size',
        );
        router.go('/game/produce/G04/medium');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Categories at $size');
        router.go('/game/animals/G33/medium');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('count-object-0')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Tap to count at $size');
        router.go('/game/vehicles/G02/easy');
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Vehicle cards at $size',
        );
        router.go('/game/animals/G55/easy');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TapDiscovery));
        await tester.pumpAndSettle();
        expect(state.trials.length, 4, reason: 'Discovery is ungraded');
        expect(tester.takeException(), isNull, reason: 'Discovery at $size');
        router.go('/');
        await tester.pumpAndSettle();
      }
      await binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      state.unlockFamily();
      await state.entitlement.confirmStoreState(true);
      final firstProfile = state.profiles.first;
      state.lockFamily();
      await expectLater(state.setting('roundLength', '3'), throwsStateError);
      state.unlockFamily();
      await state.setting('dailyGoalMinutes', '15');
      await state.setting('roundLength', '3');
      await state.setting('hintSeconds', '10');
      await state.setting('fadeWrongChoices', 'false');
      await expectLater(state.setting('hintSeconds', '5'), throwsArgumentError);
      await state.createProfile('İkinci', 'dog', {
        'sound': 0,
        'language': 0,
        'known': [0, 2],
        'favorite': [1],
      });
      final secondProfile = state.active!;
      expect(state.dailyGoalMinutes, 0);
      expect(state.roundLength, 0);
      expect(state.hintSeconds, -1);
      expect(state.fadeWrongChoices, true);
      expect(state.sound, false);
      expect(state.locale, 'tr');
      expect(state.trials, isEmpty);
      await state.setting('showLabels', 'false');
      await state.selectProfile(firstProfile);
      expect(state.dailyGoalMinutes, 15);
      expect(state.roundLength, 3);
      expect(state.hintSeconds, 10);
      expect(state.fadeWrongChoices, false);
      expect(state.trials.length, 4);
      expect(state.locale, 'en');
      expect(state.showLabels, true);
      await state.selectProfile(secondProfile);
      expect(state.showLabels, false);
      expect(state.trials, isEmpty);
      await state.setParentPin('4826');
      expect(state.verifyParentPin('4826'), true);
      expect(state.verifyParentPin('4825'), false);
      await state.clearParentPin();
      expect(state.hasParentPin, false);
      await state.updateProfile(secondProfile.id, 'Yeni Ad', 'rabbit', {
        'sound': 0,
        'language': 0,
      });
      expect(state.active!.nickname, 'Yeni Ad');
      for (var i = 0; i < 3; i++) {
        await state.createProfile('Profil $i', 'cat', {});
      }
      expect(state.profiles.length, 5);
      await expectLater(
        state.createProfile('Altıncı', 'cat', {}),
        throwsStateError,
      );
      await state.entitlement.confirmStoreState(false);
      await state.load();
      expect(state.active!.id, firstProfile.id);
      expect(state.canSelectProfile(secondProfile.id), false);
      await state.deleteProfile(secondProfile.id);
      expect(state.profiles.length, 4);
      expect(state.trials.length, 4);
      expect(
        await db.preference('profile.${secondProfile.id}.showLabels'),
        isNull,
      );
      router.go('/family');
      await tester.pumpAndSettle();
      // The compact family dashboard now presents its content as bounded
      // horizontal pages. The goal ring is a later page, not part of the
      // initially visible dashboard subtree.
      for (
        var section = 0;
        section < 20 && find.text('Today’s goal').evaluate().isEmpty;
        section++
      ) {
        final nextSection = find.byTooltip('Next section');
        expect(nextSection, findsOneWidget);
        await tester.tap(nextSection);
        await tester.pumpAndSettle();
      }
      expect(find.text('Today’s goal'), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await state.setting('difficultyOverride', 'medium');
      expect(
        tester.takeException(),
        isNull,
        reason: 'Profile goal settings layout',
      );
      router.go('/game/animals/G01/easy');
      await tester.pumpAndSettle();
      final dynamic manualScreen = tester.state(find.byType(GameScreen));
      expect(
        (manualScreen.controller as RoundController).difficulty,
        Difficulty.medium,
      );
      expect((manualScreen.controller as RoundController).total, 3);
      expect((manualScreen.controller as RoundController).hintSeconds, 10);
      expect(
        (manualScreen.controller as RoundController).fadeWrongChoices,
        false,
      );
      await state.refreshConfiguration(
        () async => {
          'disabledGames': ['animals_G01'],
        },
      );
      expect(state.canPlay('animals', 'G01', Difficulty.easy), true);
      router.go('/');
      await tester.pumpAndSettle();
      expect(state.canPlay('animals', 'G01', Difficulty.easy), false);
      expect(state.gamesForTheme('animals'), isNot(contains('G01')));
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      await tester.pumpAndSettle();
    },
  );
}
