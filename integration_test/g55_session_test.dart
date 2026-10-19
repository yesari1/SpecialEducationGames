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
    testWidgets('G55 bounded discovery works in $locale at native 2x scale', (
      tester,
    ) async {
      var surfaceConverted = false;
      final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(viewport.width, greaterThan(viewport.height));
      expect(tester.view.devicePixelRatio, greaterThan(0));

      final easy = await _openGame(tester, locale, Difficulty.easy);
      addTearDown(() => _closeGame(tester, easy));
      _expectSessionLayout(tester, easy, locale, expectedCount: 4);
      surfaceConverted = await _capture(
        binding,
        tester,
        'seg-g55-easy-$locale',
        surfaceConverted: surfaceConverted,
      );
      await _tapEveryCardAndFinish(tester, easy, count: 4, locale: locale);
      await _verifyReplay(tester, count: 4, locale: locale);
      await _closeGame(tester, easy);

      final hard = await _openGame(tester, locale, Difficulty.hard);
      addTearDown(() => _closeGame(tester, hard));
      _expectSessionLayout(tester, hard, locale, expectedCount: 6);
      surfaceConverted = await _capture(
        binding,
        tester,
        'seg-g55-hard-$locale',
        surfaceConverted: surfaceConverted,
      );
      await _tapEveryCardAndFinish(tester, hard, count: 6, locale: locale);
      await _verifyReplay(tester, count: 6, locale: locale);
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
  await tester.runAsync(() => state.createProfile('G55 local test', 'cat', {}));
  state
    ..locale = locale
    ..sound = false
    ..audio.enabled = false
    ..introduction = false
    ..showLabels = true
    ..automaticDifficulty = false
    ..configuration = AppConfiguration(freeGames: const {'animals_G55'});

  if (difficulty == Difficulty.hard) {
    // Local fixture only: grant access without invoking billing or network APIs.
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
        gameId: 'G55',
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
  _GameFixture fixture,
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
  expect(label, findsOneWidget, reason: 'full localized label: $fullLabel');
  final paragraph = tester.renderObject<RenderParagraph>(label);
  expect(paragraph.didExceedMaxLines, isFalse, reason: fullLabel);
  final labelRect = tester.getRect(label);
  final imageRect = tester.getRect(itemFinder);
  _expectBounds(labelRect, fixture.viewport, 'full card label: $fullLabel');
  _expectBounds(imageRect, fixture.viewport, 'discovery image');
  expect(
    imageRect.height,
    greaterThanOrEqualTo(80),
    reason: 'discovery image area must remain generous',
  );
  expect(
    labelRect.left,
    greaterThanOrEqualTo(imageRect.right - 8),
    reason: 'landscape card keeps the full label beside the image',
  );
  final labelledButton = find.ancestor(
    of: itemFinder,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.button == true &&
          widget.properties.label == fullLabel,
    ),
  );
  expect(
    labelledButton,
    findsOneWidget,
    reason: 'the discovery card exposes its localized button label',
  );
  final semantics = tester.widget<Semantics>(labelledButton);
  expect(semantics.properties.label, fullLabel, reason: locale);

  final cardRect = tester.getRect(labelledButton);
  _expectBounds(cardRect, fixture.viewport, 'discovery card target');
  expect(cardRect.width, greaterThanOrEqualTo(48));
  expect(cardRect.height, greaterThanOrEqualTo(48));

  for (final key in const [
    'explore-previous',
    'explore-finish',
    'explore-next',
  ]) {
    final finder = find.byKey(ValueKey(key));
    final rect = tester.getRect(finder);
    _expectBounds(rect, fixture.viewport, key);
    expect(rect.width, greaterThanOrEqualTo(48), reason: key);
    expect(rect.height, greaterThanOrEqualTo(48), reason: key);
  }
  expect(tester.takeException(), isNull, reason: locale);
}

Future<void> _tapEveryCardAndFinish(
  WidgetTester tester,
  _GameFixture fixture, {
  required int count,
  required String locale,
}) async {
  final itemFinder = find.byType(ItemVisual);
  final next = find.byKey(const ValueKey('explore-next'));
  final previous = find.byKey(const ValueKey('explore-previous'));
  final finish = find.byKey(const ValueKey('explore-finish'));

  expect(tester.widget<SegButton>(previous).onPressed, isNull);
  expect(tester.widget<SegButton>(finish).onPressed, isNull);
  for (var index = 0; index < count; index++) {
    final currentLabel = tester.widget<ItemVisual>(itemFinder).item.name(locale);
    await tester.tap(itemFinder);
    await tester.pump();
    expect(_counter(tester), '${index + 1} / $count');
    if (index < count - 1) {
      expect(
        tester.widget<SegButton>(finish).onPressed,
        isNull,
        reason: 'Finish stays locked until all $count items are tapped',
      );
      expect(tester.widget<SegButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.pump();
      expect(_counter(tester), '${index + 2} / $count');
      expect(
        tester.widget<ItemVisual>(itemFinder).item.name(locale),
        isNot(currentLabel),
        reason: 'Next presents an unexplored item',
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
  expect(find.byIcon(Icons.star_rounded), findsNothing);
  expect(_verticalScrollables(tester), isEmpty, reason: locale);

  final (trials, sessions) = (await tester.runAsync(() async {
    final savedTrials = await fixture.db.select(fixture.db.trials).get();
    final savedSessions = await fixture.db
        .select(fixture.db.gameSessions)
        .get();
    return (savedTrials, savedSessions);
  }))!;
  expect(trials, isEmpty, reason: 'G55 never records right/wrong trials');
  expect(sessions, hasLength(1));
  expect(sessions.single.completed, isTrue);
  expect(sessions.single.endedAt, isNotNull);
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
    reason: '$locale replay requires all items again',
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

void _expectBounds(Rect rect, Size viewport, String reason) {
  expect(rect.left, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.width), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(viewport.height), reason: reason);
}
