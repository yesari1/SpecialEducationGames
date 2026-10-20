import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/app.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/daily_path.dart';
import 'package:special_education_games/features/child_home/daily_path_view.dart';

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
          steps: steps.sublist(0, 3),
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
    'Daily sticker persists once, survives reload, and stays isolated to profile',
    () async {
      final state = await fixture();
      addTearDown(state.dispose);
      final first = state.active!;
      expect(state.todayStars, 0);
      await completePath(state);
      expect(state.todayStars, 6);
      expect(state.hasTodaySticker, true);
      await Future.wait([state.refreshTrials(), state.refreshTrials()]);
      final key = 'profile.${first.id}.dailyStickers';
      expect(
        jsonDecode((await state.db.preference(key))!) as List,
        hasLength(1),
      );
      await state.db.setPreference(
        key,
        jsonEncode([
          ...state.dailyStickers,
          '9999-12-31',
          '2026-02-30',
          'not-a-day',
        ]),
      );
      await state.load();
      expect(state.dailyStickers, hasLength(1));
      state.unlockFamily();
      await state.entitlement.confirmStoreState(true);
      await state.createProfile('Ece', 'dog', {});
      expect(state.todayStars, 0);
      expect(state.dailyStickers, isEmpty);
      await state.selectProfile(first);
      expect(state.hasTodaySticker, true);
    },
  );
  test(
    'Path never adds premium games, disabled games or hidden themes',
    () async {
      final state = await fixture();
      addTearDown(state.dispose);
      expect(state.dailyPathSteps, hasLength(6));
      state.configuration = state.configuration.merge({
        'disabledGames': ['animals_G10'],
        'hiddenThemes': ['vehicles'],
      }, state.content);
      expect(state.dailyPathSteps, hasLength(4));
      expect(state.dailyPathSteps, isNot(contains('animals_G10')));
      expect(state.dailyPathSteps, isNot(contains('vehicles_G02')));
      await state.entitlement.confirmStoreState(true);
      expect(state.dailyPathSteps, hasLength(4));
      expect(
        state.dailyPathSteps.every(state.configuration.freeGames.contains),
        true,
      );
    },
  );
  testWidgets(
    'G02 requires five distinct taps and explicit finish before daily progress',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final state = (await tester.runAsync(fixture))!;
      state.sound = false;
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
      expect(tester.widget<SegButton>(finish).onPressed, isNull);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(ItemVisual).first);
        await tester.pump();
        if (i < 4) {
          expect(tester.widget<SegButton>(finish).onPressed, isNull);
          await tester.tap(find.text('Next'));
          await tester.pump();
        }
      }
      expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
      expect(state.dailyPath.count, 0);
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(state.dailyPath.completed, {'vehicles_G02'});
      final chargedBeforeReplay = state.dailyPlayTime.usedMs;
      expect(find.text('Well done!'), findsOneWidget);
      expect(find.byKey(const ValueKey('completion-next')), findsOneWidget);
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
      await tester.tap(find.byKey(const ValueKey('completion-next')));
      await tester.pumpAndSettle();
      expect(find.text('Again'), findsOneWidget);
      await tester.tap(find.text('Again'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      expect(tester.widget<SegButton>(finish).onPressed, isNull);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(ItemVisual).first);
        await tester.pump();
        if (i < 4) {
          await tester.tap(find.text('Next'));
          await tester.pump();
        }
      }
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        state.dailyPlayTime.usedMs,
        greaterThanOrEqualTo(chargedBeforeReplay + 150),
      );
      expect(state.dailyPath.completed, {'vehicles_G02'});
      await tester.tap(find.byKey(const ValueKey('completion-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Today’s Path'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyPathView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets(
    'Daily path and sticker album fit short landscape and tablet in both languages',
    (tester) async {
      final state = (await tester.runAsync(fixture))!;
      addTearDown(state.dispose);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.devicePixelRatio = 1;
      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            MaterialApp(
              theme: segTheme(),
              home: Scaffold(
                body: SafeArea(child: DailyPathView(state: state)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('daily-step-${state.dailyPathSteps.first}')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('sticker-album')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('sticker-album-dialog')),
            findsOneWidget,
          );
          expect(
            find.text(
              state.tr(
                'Bugünün yolunu tamamlayıp ilk çıkartmanı kazanabilirsin.',
                'Complete today’s path to earn your first sticker.',
              ),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(state.tr('Kapat', 'Close')));
          await tester.pumpAndSettle();
        }
      }
      state.locale = 'en';
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SafeArea(child: DailyPathView(state: state)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('daily-step-${state.dailyPathSteps.first}')),
        findsOneWidget,
      );
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
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets(
    'Sticker album pages retain every earned sticker without vertical scrolling',
    (tester) async {
      final state = (await tester.runAsync(fixture))!;
      addTearDown(state.dispose);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      await tester.runAsync(() async {
        await state.db.setPreference(
          'profile.${state.active!.id}.dailyStickers',
          jsonEncode([
            '2026-10-10',
            '2026-10-11',
            '2026-10-12',
            '2026-10-13',
            '2026-10-14',
            '2026-10-15',
            '2026-10-16',
          ]),
        );
        await state.load();
      });
      tester.view.devicePixelRatio = 1;
      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          for (final scale in [1.0, 1.6, 2.0]) {
            tester.view.physicalSize = size;
            await tester.pumpWidget(
              MaterialApp(
                theme: segTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Center(
                    child: Builder(
                      builder: (context) => TextButton(
                        key: const ValueKey('open-sticker-album'),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => StickerAlbumDialog(
                            state: state,
                            days: state.dailyStickers.toList()
                              ..sort((a, b) => b.compareTo(a)),
                          ),
                        ),
                        child: const Text('Open'),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('open-sticker-album')));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('sticker-album-pages')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('sticker-album-page-indicator')),
              findsOneWidget,
            );
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
            final firstIndicator = tester
                .widget<Text>(
                  find.byKey(const ValueKey('sticker-album-page-indicator')),
                )
                .data;
            await tester.tap(find.byKey(const ValueKey('sticker-album-next')));
            await tester.pumpAndSettle();
            final secondIndicator = tester
                .widget<Text>(
                  find.byKey(const ValueKey('sticker-album-page-indicator')),
                )
                .data;
            expect(firstIndicator, contains('1'));
            expect(secondIndicator, contains('2'));
            while (tester
                    .widget<IconButton>(
                      find.byKey(const ValueKey('sticker-album-next')),
                    )
                    .onPressed !=
                null) {
              await tester.tap(
                find.byKey(const ValueKey('sticker-album-next')),
              );
              await tester.pumpAndSettle();
            }
            final finalIndicator = tester
                .widget<Text>(
                  find.byKey(const ValueKey('sticker-album-page-indicator')),
                )
                .data;
            expect(finalIndicator, isNot(secondIndicator));
            expect(tester.takeException(), isNull);
            await tester.tap(find.text(state.tr('Kapat', 'Close')));
            await tester.pumpAndSettle();
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
