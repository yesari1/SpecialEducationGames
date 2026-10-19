import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/tap_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> createState({
    String gameId = 'G02',
    bool hard = false,
    ContentRepository? repository,
  }) async {
    final state = AppState(
      repository ?? content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Card test', 'cat', {});
    state
      ..locale = 'en'
      ..sound = false
      ..automaticDifficulty = false
      ..configuration = AppConfiguration(freeGames: {'animals_$gameId'});
    state.audio.enabled = false;
    if (hard) {
      state.entitlement
        ..storeActive = true
        ..lastConfirmedAt = DateTime.now();
    }
    return state;
  }

  Future<void> mount(
    WidgetTester tester,
    AppState state, {
    String gameId = 'G02',
    Difficulty difficulty = Difficulty.easy,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: GameScreen(
          state: state,
          themeId: 'animals',
          gameId: gameId,
          difficulty: difficulty,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

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

  bool hasVerticalScrollable(WidgetTester tester) => tester
      .widgetList<Scrollable>(find.byType(Scrollable))
      .any(
        (scrollable) =>
            scrollable.axisDirection == AxisDirection.down ||
            scrollable.axisDirection == AxisDirection.up,
      );

  String counter(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('explore-card-counter')))
      .data!;

  Future<void> cleanG55State(WidgetTester tester, AppState state) async {
    final finish = find.byKey(const ValueKey('explore-finish'));
    if (finish.evaluate().isNotEmpty) {
      if (tester.widget<SegButton>(finish).onPressed == null) {
        final total = int.parse(counter(tester).split('/').last.trim());
        var current = int.parse(counter(tester).split('/').first.trim());
        final previous = find.byKey(const ValueKey('explore-previous'));
        while (current > 1) {
          await tester.tap(previous);
          await tester.pump();
          current--;
        }
        final next = find.byKey(const ValueKey('explore-next'));
        for (var index = 0; index < total; index++) {
          await tester.tap(find.byType(ItemVisual));
          await tester.pump();
          if (index < total - 1) {
            await tester.tap(next);
            await tester.pump();
          }
        }
      }
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.pump();
  }

  testWidgets('G02 easy is bounded to five distinct cards and needs all five', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = (await tester.runAsync(createState))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump();
    });
    await mount(tester, state);

    expect(counter(tester), '1 / 5');
    expect(
      tester
          .widget<SegButton>(find.byKey(const ValueKey('explore-previous')))
          .onPressed,
      isNull,
    );
    final finish = find.byKey(const ValueKey('explore-finish'));
    final next = find.byKey(const ValueKey('explore-next'));
    expect(tester.widget<SegButton>(finish).onPressed, isNull);

    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byType(ItemVisual));
      await tester.pump();
      if (index < 4) {
        expect(tester.widget<SegButton>(finish).onPressed, isNull);
        await tester.tap(next);
        await tester.pump();
        expect(counter(tester), '${index + 2} / 5');
      }
    }

    expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
    expect(tester.widget<SegButton>(next).onPressed, isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('G02 hard presents fifteen cards and remains manual', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = (await tester.runAsync(() => createState(hard: true)))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump();
    });
    await mount(tester, state, difficulty: Difficulty.hard);

    expect(counter(tester), '1 / 15');
    final firstLabel = tester
        .widget<Semantics>(
          find
              .ancestor(
                of: find.byType(ItemVisual),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .properties
        .label;
    final next = find.byKey(const ValueKey('explore-next'));
    final finish = find.byKey(const ValueKey('explore-finish'));
    expect(tester.widget<SegButton>(finish).onPressed, isNull);
    await tester.tap(find.byType(ItemVisual));
    await tester.pump(const Duration(seconds: 2));
    expect(counter(tester), '1 / 15', reason: 'tapping never auto-advances');
    expect(tester.widget<SegButton>(finish).onPressed, isNull);
    expect(
      tester
          .widget<Semantics>(
            find
                .ancestor(
                  of: find.byType(ItemVisual),
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .properties
          .label,
      firstLabel,
    );

    for (var index = 1; index < 15; index++) {
      await tester.tap(next);
      await tester.pump();
      expect(counter(tester), '${index + 1} / 15');
      await tester.tap(find.byType(ItemVisual));
      await tester.pump();
    }
    expect(counter(tester), '15 / 15');
    expect(tester.widget<SegButton>(next).onPressed, isNull);
    expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
    expect(tester.getRect(finish).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(finish);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('completion-pages')), findsOneWidget);
    final completionPager = tester.widget<PageView>(
      find.byKey(const ValueKey('completion-pages')),
    );
    completionPager.controller!.jumpToPage(1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    expect(counter(tester), '1 / 15');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('G02 short tier pool reports and completes its actual size', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final firstThree = content.items
        .where((item) => item.theme == 'animals' && item.tier == 'easy')
        .take(3)
        .toList();
    final shortContent = ContentRepository(
      content.themes,
      firstThree,
      content.games,
      content.freeGames,
      content.configDefaults,
    );
    final state = (await tester.runAsync(
      () => createState(repository: shortContent),
    ))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump();
    });
    await mount(tester, state);

    expect(counter(tester), '1 / 3');
    final finish = find.byKey(const ValueKey('explore-finish'));
    final next = find.byKey(const ValueKey('explore-next'));
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byType(ItemVisual));
      await tester.pump();
      if (index < 2) {
        expect(tester.widget<SegButton>(finish).onPressed, isNull);
        await tester.tap(next);
        await tester.pump();
      }
    }
    expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
    expect(tester.widget<SegButton>(next).onPressed, isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('G55 uses bounded 4/5/6 item sessions and requires every item', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    for (final entry in {
      Difficulty.easy: 4,
      Difficulty.medium: 5,
      Difficulty.hard: 6,
    }.entries) {
      final state = (await tester.runAsync(
        () => createState(gameId: 'G55', hard: entry.key == Difficulty.hard),
      ))!;
      await mount(tester, state, gameId: 'G55', difficulty: entry.key);

      expect(counter(tester), '1 / ${entry.value}');
      final finish = find.byKey(const ValueKey('explore-finish'));
      final next = find.byKey(const ValueKey('explore-next'));
      expect(tester.widget<SegButton>(finish).onPressed, isNull);
      expect(
        tester
            .widget<SegButton>(find.byKey(const ValueKey('explore-previous')))
            .onPressed,
        isNull,
      );
      for (var index = 0; index < entry.value; index++) {
        await tester.tap(find.byType(ItemVisual));
        await tester.pump();
        if (index < entry.value - 1) {
          expect(tester.widget<SegButton>(finish).onPressed, isNull);
          await tester.tap(next);
          await tester.pump();
        }
      }
      expect(counter(tester), '${entry.value} / ${entry.value}');
      expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
      expect(tester.widget<SegButton>(next).onPressed, isNull);
      expect(find.byType(TapDiscovery), findsOneWidget);
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('completion-pages')), findsOneWidget);
      final (savedTrials, savedSessions) = (await tester.runAsync(() async {
        final trials = await state.db.select(state.db.trials).get();
        final sessions = await state.db.select(state.db.gameSessions).get();
        return (trials, sessions);
      }))!;
      expect(savedTrials, isEmpty);
      expect(savedSessions, hasLength(1));
      expect(savedSessions.single.completed, isTrue);

      // Replay starts at the first item and clears the explored set.
      await tester.tap(find.byKey(const ValueKey('completion-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Again'));
      await tester.pumpAndSettle();
      expect(counter(tester), '1 / ${entry.value}');
      expect(tester.widget<SegButton>(finish).onPressed, isNull);
      await cleanG55State(tester, state);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('G55 short pool shows and completes its actual item count', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final firstThree = content.items
        .where((item) => item.theme == 'animals' && item.tier == 'easy')
        .take(3)
        .toList();
    final shortContent = ContentRepository(
      content.themes,
      firstThree,
      content.games,
      content.freeGames,
      content.configDefaults,
    );
    final state = (await tester.runAsync(
      () => createState(gameId: 'G55', repository: shortContent),
    ))!;
    addTearDown(() async {
      await cleanG55State(tester, state);
    });
    await mount(tester, state, gameId: 'G55');

    expect(counter(tester), '1 / 3');
    final finish = find.byKey(const ValueKey('explore-finish'));
    final next = find.byKey(const ValueKey('explore-next'));
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byType(ItemVisual));
      await tester.pump();
      if (index < 2) {
        expect(tester.widget<SegButton>(finish).onPressed, isNull);
        await tester.tap(next);
        await tester.pump();
      }
    }
    expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
    expect(tester.widget<SegButton>(next).onPressed, isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('G55 counter and controls fit at 2x in Turkish and English', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);

    for (final locale in ['tr', 'en']) {
      final state = (await tester.runAsync(
        () => createState(gameId: 'G55'),
      ))!;
      state.locale = locale;
      await mount(
        tester,
        state,
        gameId: 'G55',
        textScaler: const TextScaler.linear(2),
      );
      expect(counter(tester), '1 / 4', reason: locale);
      final firstItemName = state.content
          .pool('animals', Difficulty.easy)
          .where((item) => item.images.isNotEmpty)
          .first
          .name(locale);
      expect(find.text(firstItemName), findsOneWidget, reason: locale);
      expect(
        tester.getSize(find.byType(ItemVisual)).height,
        greaterThanOrEqualTo(80),
        reason: 'the exploration image must have a substantial height',
      );
      expect(
        tester
            .widget<SegButton>(find.byKey(const ValueKey('explore-next')))
            .onPressed,
        isNotNull,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('explore-finish'))).shortestSide,
        greaterThanOrEqualTo(48),
      );
      expect(hasVerticalScrollable(tester), isFalse, reason: locale);
      expect(tester.takeException(), isNull, reason: locale);
      await cleanG55State(tester, state);
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('G02 counter and navigation fit at 2x in Turkish and English', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);

    for (final locale in ['tr', 'en']) {
      final state = (await tester.runAsync(createState))!;
      state.locale = locale;
      await mount(tester, state, textScaler: const TextScaler.linear(2));

      final next = find.byKey(const ValueKey('explore-next'));
      expect(counter(tester), '1 / 5', reason: locale);
      final firstItemName = state.content
          .pool('animals', Difficulty.easy)
          .where((item) => item.images.isNotEmpty)
          .first
          .name(locale);
      expect(find.text(firstItemName), findsOneWidget, reason: locale);
      expect(
        tester.getSize(find.byType(ItemVisual)).height,
        greaterThanOrEqualTo(80),
        reason: 'the exploration image must have a substantial height',
      );
      expect(
        tester.widget<SegButton>(next).onPressed,
        isNotNull,
        reason: locale,
      );
      expect(tester.getRect(next).shortestSide, greaterThanOrEqualTo(48));
      expect(
        tester
            .getRect(
              find
                  .ancestor(
                    of: find.byType(ItemVisual),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .shortestSide,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getRect(
              find
                  .ancestor(
                    of: find.byType(ItemVisual),
                    matching: find.byType(GestureDetector),
                  )
                  .first,
            )
            .shortestSide,
        greaterThanOrEqualTo(48),
        reason: 'the full card gesture target must remain at least 48 px',
      );
      expect(hasVerticalScrollable(tester), isFalse, reason: locale);
      expect(tester.takeException(), isNull, reason: locale);

      final finish = find.byKey(const ValueKey('explore-finish'));
      for (var index = 0; index < 5; index++) {
        await tester.tap(find.byType(ItemVisual));
        await tester.pump();
        if (index < 4) {
          await tester.tap(next);
          await tester.pump();
        }
      }
      expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
      await tester.tap(finish);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('completion-pages')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump();
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
