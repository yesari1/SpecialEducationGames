import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in const ['tr', 'en']) {
    testWidgets('G02 bounded sessions work in $locale at native 2x scale', (
      tester,
    ) async {
      var surfaceConverted = false;
      final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(viewport.width, greaterThan(viewport.height));
      expect(tester.view.devicePixelRatio, greaterThan(0));

      final easy = await _openGame(tester, locale, Difficulty.easy);
      addTearDown(() => _closeGame(tester, easy));
      _expectSessionLayout(tester, easy.viewport, locale, expectedCount: 5);
      surfaceConverted = await _capture(
        binding,
        tester,
        'seg-g02-easy-$locale',
        surfaceConverted: surfaceConverted,
      );
      await _tapEveryCardAndFinish(tester, count: 5, locale: locale);
      await _verifyReplay(tester, count: 5, locale: locale);
      await _closeGame(tester, easy);

      final hard = await _openGame(tester, locale, Difficulty.hard);
      addTearDown(() => _closeGame(tester, hard));
      _expectSessionLayout(tester, hard.viewport, locale, expectedCount: 15);
      surfaceConverted = await _capture(
        binding,
        tester,
        'seg-g02-hard-$locale',
        surfaceConverted: surfaceConverted,
      );
      await _tapEveryCardAndFinish(
        tester,
        count: 15,
        locale: locale,
        verifyManual: true,
      );
      await _verifyReplay(tester, count: 15, locale: locale);
    });
  }
}

class _GameFixture {
  final AppState state;
  final AppDatabase db;
  final Size viewport;
  bool closed = false;

  _GameFixture(this.state, this.db, this.viewport);
}

Future<_GameFixture> _openGame(
  WidgetTester tester,
  String locale,
  Difficulty difficulty,
) async {
  final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final content = await tester.runAsync(ContentRepository.load);
  expect(content, isNotNull, reason: 'production content bundle loads');
  final state = AppState(content!, db, AudioService());
  await tester.runAsync(state.load);
  await tester.runAsync(() => state.createProfile('G02 local test', 'cat', {}));
  state
    ..locale = locale
    ..sound = false
    ..audio.enabled = false
    ..introduction = false
    ..showLabels = true
    ..automaticDifficulty = false
    ..configuration = AppConfiguration(freeGames: const {'animals_G02'});

  if (difficulty == Difficulty.hard) {
    // Local fixture only: this grants the test access without invoking billing.
    state.entitlement
      ..storeActive = true
      ..lastConfirmedAt = DateTime.now();
    expect(state.entitlement.isPremium, isTrue);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: segTheme(),
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: GameScreen(
        state: state,
        themeId: 'animals',
        gameId: 'G02',
        difficulty: difficulty,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  return _GameFixture(state, db, viewport);
}

void _expectSessionLayout(
  WidgetTester tester,
  Size viewport,
  String locale, {
  required int expectedCount,
}) {
  expect(find.byType(GameScreen), findsOneWidget);
  expect(_counter(tester), '1 / $expectedCount', reason: locale);
  expect(_verticalScrollables(tester), isEmpty, reason: locale);

  final itemFinder = find.byType(ItemVisual);
  expect(itemFinder, findsOneWidget);
  final item = tester.widget<ItemVisual>(itemFinder).item;
  final fullLabel = item.name(locale);
  final label = find.text(fullLabel);
  expect(
    label,
    findsOneWidget,
    reason: 'full localized card label: $fullLabel',
  );
  final paragraph = tester.renderObject<RenderParagraph>(label);
  expect(paragraph.didExceedMaxLines, isFalse, reason: fullLabel);
  _expectBounds(tester.getRect(label), viewport, 'full card label: $fullLabel');
  final semantics = tester.widget<Semantics>(
    find.ancestor(of: itemFinder, matching: find.byType(Semantics)).first,
  );
  expect(semantics.properties.label, fullLabel, reason: locale);

  final cardTarget = find
      .ancestor(of: itemFinder, matching: find.byType(GestureDetector))
      .first;
  final cardRect = tester.getRect(cardTarget);
  _expectBounds(cardRect, viewport, 'card target');
  expect(cardRect.width, greaterThanOrEqualTo(48));
  expect(cardRect.height, greaterThanOrEqualTo(48));

  for (final key in const [
    'explore-previous',
    'explore-finish',
    'explore-next',
  ]) {
    final finder = find.byKey(ValueKey(key));
    final rect = tester.getRect(finder);
    _expectBounds(rect, viewport, key);
    expect(rect.width, greaterThanOrEqualTo(48), reason: key);
    expect(rect.height, greaterThanOrEqualTo(48), reason: key);
  }
  expect(tester.takeException(), isNull, reason: locale);
}

Future<void> _tapEveryCardAndFinish(
  WidgetTester tester, {
  required int count,
  required String locale,
  bool verifyManual = false,
}) async {
  final itemFinder = find.byType(ItemVisual);
  final next = find.byKey(const ValueKey('explore-next'));
  final previous = find.byKey(const ValueKey('explore-previous'));
  final finish = find.byKey(const ValueKey('explore-finish'));

  expect(tester.widget<SegButton>(previous).onPressed, isNull);
  expect(tester.widget<SegButton>(finish).onPressed, isNull);
  for (var index = 0; index < count; index++) {
    final currentLabel = tester
        .widget<ItemVisual>(itemFinder)
        .item
        .name(locale);
    await tester.tap(itemFinder);
    if (verifyManual && index == 0) {
      await tester.pump(const Duration(seconds: 2));
    } else {
      await tester.pump();
    }
    expect(_counter(tester), '${index + 1} / $count');
    if (verifyManual && index == 0) {
      expect(
        tester.widget<ItemVisual>(itemFinder).item.name(locale),
        currentLabel,
        reason: 'Hard card remains in place until manually advanced',
      );
    }
    if (index < count - 1) {
      expect(
        tester.widget<SegButton>(finish).onPressed,
        isNull,
        reason: 'Finish stays locked until all $count cards are tapped',
      );
    }
    if (index < count - 1) {
      expect(tester.widget<SegButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.pump();
      expect(_counter(tester), '${index + 2} / $count');
      expect(
        tester.widget<ItemVisual>(itemFinder).item.name(locale),
        isNot(currentLabel),
        reason: 'next presents a new card before it is explored',
      );
    }
  }
  expect(_counter(tester), '$count / $count');
  expect(tester.widget<SegButton>(next).onPressed, isNull);
  expect(tester.widget<SegButton>(finish).onPressed, isNotNull);
  await tester.tap(finish);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('completion-pages')), findsOneWidget);
  expect(_verticalScrollables(tester), isEmpty, reason: locale);
  expect(tester.takeException(), isNull, reason: locale);
}

Future<void> _verifyReplay(
  WidgetTester tester, {
  required int count,
  required String locale,
}) async {
  final pager = tester.widget<PageView>(
    find.byKey(const ValueKey('completion-pages')),
  );
  pager.controller!.jumpToPage(1);
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(tester.element(find.byType(PageView)));
  final again = find.text(l10n.gameAgain);
  expect(again, findsOneWidget);
  await tester.tap(again);
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  expect(_counter(tester), '1 / $count', reason: '$locale replay resets');
  expect(
    tester
        .widget<SegButton>(find.byKey(const ValueKey('explore-finish')))
        .onPressed,
    isNull,
    reason: '$locale replay requires all cards again',
  );
  expect(_verticalScrollables(tester), isEmpty, reason: locale);
}

String _counter(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('explore-card-counter')))
    .data!;

Iterable<Scrollable> _verticalScrollables(WidgetTester tester) => tester
    .widgetList<Scrollable>(find.byType(Scrollable))
    .where(
      (scrollable) =>
          scrollable.axisDirection == AxisDirection.down ||
          scrollable.axisDirection == AxisDirection.up,
    );

void _expectBounds(Rect rect, Size viewport, String reason) {
  expect(rect.left, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.width), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(viewport.height), reason: reason);
}

Future<bool> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name, {
  required bool surfaceConverted,
}) async {
  if (!surfaceConverted) await binding.convertFlutterSurfaceToImage();
  await tester.pump();
  await binding.takeScreenshot(name);
  return true;
}

Future<void> _closeGame(WidgetTester tester, _GameFixture fixture) async {
  if (fixture.closed) return;
  fixture.closed = true;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final sessions = await fixture.db.select(fixture.db.gameSessions).get();
      if (sessions.isNotEmpty &&
          sessions.every((session) => session.endedAt != null)) {
        await fixture.state.refreshTrials();
        final refreshed = await fixture.db
            .select(fixture.db.gameSessions)
            .get();
        if (refreshed.isNotEmpty &&
            refreshed.every((session) => session.endedAt != null)) {
          break;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  fixture.state.lockFamily();
  fixture.state.dispose();
  await fixture.db.close();
}
