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

  Future<void> walkToEnd(WidgetTester tester, int total) async {
    final next = find.byKey(const ValueKey('explore-next'));
    for (var index = 0; index < total - 1; index++) {
      await tester.tap(next);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> finishAndClose(WidgetTester tester, AppState state) async {
    await tester.tap(find.byKey(const ValueKey('explore-finish')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('completion-summary')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.pump();
  }

  testWidgets(
    'G02: no Finish at the start; on the last card Next becomes Finish',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final state = (await tester.runAsync(createState))!;
      await mount(tester, state);
      expect(counter(tester), '1 / 5');
      expect(find.byKey(const ValueKey('explore-finish')), findsNothing);
      expect(find.byKey(const ValueKey('explore-next')), findsOneWidget);
      final seen = <String>{};
      for (var index = 0; index < 5; index++) {
        seen.add(
          tester
              .widget<Semantics>(
                find
                    .ancestor(
                      of: find.byType(ItemVisual),
                      matching: find.byWidgetPredicate(
                        (w) => w is Semantics && w.properties.button == true,
                      ),
                    )
                    .first,
              )
              .properties
              .label!,
        );
        if (index < 4) {
          await tester.tap(find.byKey(const ValueKey('explore-next')));
          await tester.pump();
        }
      }
      await tester.pump();
      expect(seen, hasLength(5), reason: 'five distinct cards');
      expect(counter(tester), '5 / 5');
      expect(find.byKey(const ValueKey('explore-next')), findsNothing);
      final finish = find.byKey(const ValueKey('explore-finish'));
      expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
      await finishAndClose(tester, state);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('G02 hard presents fifteen cards', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = (await tester.runAsync(() => createState(hard: true)))!;
    await mount(tester, state, difficulty: Difficulty.hard);
    final total = int.parse(counter(tester).split('/').last.trim());
    expect(
      total,
      state.content
          .pool('animals', Difficulty.hard)
          .where((x) => x.images.isNotEmpty)
          .take(15)
          .length,
    );
    await walkToEnd(tester, total);
    await finishAndClose(tester, state);
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
      expect(
        tester.getSize(find.byType(ItemVisual)).height,
        greaterThanOrEqualTo(80),
      );
      expect(tester.getRect(next).shortestSide, greaterThanOrEqualTo(48));
      expect(hasVerticalScrollable(tester), isFalse, reason: locale);
      expect(tester.takeException(), isNull, reason: locale);
      await walkToEnd(tester, 5);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('explore-finish')))
            .shortestSide,
        greaterThanOrEqualTo(48),
      );
      await finishAndClose(tester, state);
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
