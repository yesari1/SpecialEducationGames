import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/app.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/daily_path.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDownAll(() => debugDefaultTargetPlatformOverride = null);
  final now = DateTime(2026, 10, 16, 12);
  const steps = [
    'animals_G01',
    'animals_G10',
    'colors_G01',
    'numbers_G35',
    'produce_G01',
    'vehicles_G02',
  ];
  GameSession session(
    String id,
    String key, {
    String profile = 'a',
    DateTime? end,
    bool complete = true,
    int ms = 6000,
  }) {
    final parts = key.split('_');
    return GameSession(
      id: id,
      profileId: profile,
      themeId: parts[0],
      gameId: parts[1],
      difficulty: 'easy',
      startedAt: (end ?? now).subtract(const Duration(minutes: 1)),
      endedAt: end ?? now,
      activeMs: ms,
      completed: complete,
    );
  }

  test(
    'Daily progress counts distinct finished games, not trials, future or interrupted sessions',
    () {
      final sessions = [
        session('1', steps[0]),
        session('2', steps[0]),
        session('3', steps[1], complete: false),
        session('4', steps[2], profile: 'b'),
        session('5', steps[3], end: now.add(const Duration(seconds: 1))),
        session('6', steps[4], end: now.subtract(const Duration(days: 1))),
        session('7', steps[5], ms: 0),
        session('8', 'animals_G55'),
      ];
      final progress = DailyPathProgress.fromSessions(
        steps: steps,
        sessions: sessions,
        profileId: 'a',
        now: now,
      );
      expect(progress.completed, {steps[0]});
      expect(progress.complete, false);
      expect(
        DailyPathProgress.fromSessions(
          steps: steps,
          sessions: sessions,
          profileId: 'a',
          now: now.add(const Duration(days: 1)),
        ).count,
        0,
      );
      expect(
        DailyPathProgress.fromSessions(
          steps: steps,
          sessions: sessions,
          profileId: 'b',
          now: now,
        ).completed,
        {steps[2]},
      );
    },
  );
  test(
    'Midnight completion belongs to ending day; hidden/unavailable steps do not count',
    () {
      final midnight = DateTime(2026, 10, 17, 0, 0, 10);
      final completed = [
        for (var i = 0; i < steps.length; i++)
          session('$i', steps[i], end: midnight),
      ];
      final progress = DailyPathProgress.fromSessions(
        steps: steps,
        sessions: completed,
        profileId: 'a',
        now: midnight,
      );
      expect(progress.count, 6);
      expect(progress.complete, true);
      expect(
        DailyPathProgress.fromSessions(
          steps: steps.sublist(0, 5),
          sessions: completed,
          profileId: 'a',
          now: midnight,
        ).count,
        5,
      );
      expect(
        DailyPathProgress.fromSessions(
          steps: steps.sublist(0, 2),
          sessions: completed,
          profileId: 'a',
          now: midnight,
        ).complete,
        false,
      );
      expect(
        DailyPathProgress.fromSessions(
          steps: [],
          sessions: completed,
          profileId: 'a',
          now: midnight,
        ).complete,
        false,
      );
    },
  );

  Future<AppState> fixture() async {
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Ada', 'cat', {});
    // Items now have real recordings; keep host playback off.
    state.audio.enabled = false;
    return state;
  }

  Future<void> completePath(AppState state) async {
    final ended = DateTime.now().subtract(const Duration(seconds: 1));
    for (final key in state.dailyPathSteps) {
      final parts = key.split('_');
      await state.db
          .into(state.db.gameSessions)
          .insert(
            GameSessionsCompanion.insert(
              id: key,
              profileId: state.active!.id,
              themeId: parts[0],
              gameId: parts[1],
              difficulty: 'easy',
              startedAt: ended.subtract(const Duration(minutes: 1)),
              endedAt: Value(ended),
              activeMs: const Value(6000),
              completed: const Value(true),
            ),
          );
    }
    await state.refreshTrials();
  }

  test(
    'No new daily stickers; earned ones stay, valid and per profile',
    () async {
      final state = await fixture();
      addTearDown(state.dispose);
      final first = state.active!;
      await completePath(state);
      final key = 'profile.${first.id}.dailyStickers';
      expect(await state.db.preference(key), isNull);
      await state.db.setPreference(
        key,
        jsonEncode(['2026-11-01', '9999-12-31', '2026-02-30', 'not-a-day']),
      );
      await state.load();
      expect(state.dailyStickers, {'2026-11-01'});
      state.unlockFamily();
      await state.entitlement.confirmStoreState(true);
      await state.createProfile('Ece', 'dog', {});
      expect(state.dailyStickers, isEmpty);
      await state.selectProfile(first);
      expect(state.dailyStickers, {'2026-11-01'});
    },
  );
  test(
    'Free path never adds premium games, disabled games or hidden themes',
    () async {
      final state = await fixture();
      addTearDown(state.dispose);
      expect(state.dailyPathSteps, hasLength(AppState.pathLength));
      state.configuration = state.configuration.merge({
        'disabledGames': ['animals_G01'],
        'hiddenThemes': ['vehicles'],
      }, state.content);
      expect(state.dailyPathSteps, hasLength(AppState.pathLength));
      expect(state.dailyPathSteps, isNot(contains('animals_G01')));
      expect(
        state.dailyPathSteps.where((key) => key.startsWith('vehicles_')),
        isEmpty,
      );
      for (var day = 0; day < 7; day++) {
        final steps = state.dailyPathStepsAt(
          DateTime.now().add(Duration(days: day)),
        );
        expect(steps, hasLength(AppState.pathLength));
        expect(state.configuration.freeGames, containsAll(steps));
      }
      // Premium: the plan's Premium cards may join the path.
      await state.entitlement.confirmStoreState(true);
      expect(state.dailyPathSteps, hasLength(AppState.pathLength));
    },
  );
  test(
    'Path follows the 7-day plan: favorite theme first, a new day each day',
    () async {
      final state = await fixture();
      addTearDown(state.dispose);
      final plan = state.weekPlan;
      final now = DateTime.now();
      // Day 1 is the plan's first day and its theme.
      expect(state.planDayAt(now), 0);
      expect(state.dailyPathSteps.first, startsWith('${plan[0].theme}_'));
      for (var day = 0; day < 7; day++) {
        final at = DateTime(now.year, now.month, now.day + day, 12);
        expect(state.planDayAt(at), day);
        final steps = state.dailyPathStepsAt(at);
        expect(steps.first, startsWith('${plan[day].theme}_'));
      }
      // After the seventh day the plan starts again.
      expect(
        state.dailyPathStepsAt(DateTime(now.year, now.month, now.day + 7, 12)),
        state.dailyPathStepsAt(DateTime(now.year, now.month, now.day, 12)),
      );
    },
  );
  test('Path starts with the favorite theme', () async {
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    addTearDown(state.dispose);
    await state.load();
    state.audio.enabled = false;
    await state.completeOnboarding(
      name: 'Can',
      // Favorite option 1 = Vehicles.
      survey: {
        'favorite': [1],
      },
    );
    expect(state.dailyPathSteps.first, startsWith('vehicles_'));
  });
  test('A child set up in setup gets the mascot hello once', () async {
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    addTearDown(state.dispose);
    await state.load();
    expect(state.mascotHelloDue, isFalse);
    await state.completeOnboarding(name: 'Can', survey: {});
    expect(state.mascotHelloDue, isTrue);
    await state.mascotHelloDone();
    await state.load();
    expect(state.mascotHelloDue, isFalse);
  });
  testWidgets(
    'G02 requires five distinct taps and explicit finish before daily progress',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final state = (await tester.runAsync(fixture))!;
      state.sound = false;
      // Only vehicles is free here, so its Learn card is a path step.
      state.configuration = state.configuration.merge({
        'freeGames': ['vehicles_G01', 'vehicles_G02'],
        'hiddenThemes': [
          for (final t in state.content.themes)
            if (t.id != 'vehicles' && t.games.isNotEmpty) t.id,
        ],
      }, state.content);
      addTearDown(state.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      await tester.pumpWidget(EducationApp(state: state));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go('/game/vehicles/G02/easy');
      await tester.pumpAndSettle();
      expect(state.dailyPath.count, 0);
      final finish = find.byKey(const ValueKey('explore-finish'));
      expect(finish, findsNothing, reason: 'Finish appears on the last card');
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }
      await tester.pump();
      expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
      expect(state.dailyPath.count, 0);
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      // Stay on the result page: the "Next game" ring would move on after
      // a few seconds (no sound in tests, so it starts at once).
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(state.dailyPath.completed, {'vehicles_G02'});
      final chargedBeforeReplay = state.dailyPlayTime.usedMs;
      expect(find.text('Well done!'), findsOneWidget);
      expect(find.byKey(const ValueKey('completion-again')), findsOneWidget);
      expect(
        tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where(
              (scrollable) =>
                  scrollable.axisDirection == AxisDirection.down ||
                  scrollable.axisDirection == AxisDirection.up,
            ),
        isEmpty,
      );
      final again = find.byKey(const ValueKey('completion-again'));
      expect(again, findsOneWidget);
      await tester.tap(again);
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      expect(finish, findsNothing);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }
      await tester.pump();
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      // Stay on the result page: the "Next game" ring would move on after
      // a few seconds (no sound in tests, so it starts at once).
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        state.dailyPlayTime.usedMs,
        greaterThanOrEqualTo(chargedBeforeReplay + 150),
      );
      expect(state.dailyPath.completed, {'vehicles_G02'});
      // The next game comes from today's path once the ring closes.
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('completion-summary')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
