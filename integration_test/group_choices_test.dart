import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/counted_objects.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G04 group choices are reachable and readable offline', (
    tester,
  ) async {
    final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(viewport.width, greaterThan(viewport.height));
    expect(tester.view.devicePixelRatio, greaterThan(0));

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final content = await tester.runAsync(ContentRepository.load);
    expect(content, isNotNull, reason: 'production content bundle loads');
    final state = AppState(content!, db, AudioService());
    var cleaned = false;
    Future<void> cleanup() async {
      if (cleaned) return;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (DateTime.now().isBefore(deadline)) {
          final sessions = await db.select(db.gameSessions).get();
          if (sessions.isNotEmpty && sessions.every((x) => x.endedAt != null)) {
            await state.refreshTrials();
            final refreshed = await db.select(db.gameSessions).get();
            if (refreshed.isNotEmpty &&
                refreshed.every((x) => x.endedAt != null)) {
              return;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        throw StateError(
          'GameScreen did not finish its session before DB close.',
        );
      });
      state.lockFamily();
      state.dispose();
      await db.close();
      cleaned = true;
    }

    addTearDown(cleanup);
    await tester.runAsync(state.load);
    await tester.runAsync(() => state.createProfile('Local test', 'cat', {}));
    state.locale = 'tr';
    state.sound = false;
    state.audio.enabled = false;
    state.celebration = 'full';
    state.introduction = false;
    state.hintSeconds = 0;
    state.configuration = AppConfiguration(
      freeGames: const {'animals_G04'},
      choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
    );
    expect(state.canPlay('animals', 'G04', Difficulty.medium), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        locale: const Locale('tr'),
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
          gameId: 'G04',
          difficulty: Difficulty.medium,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(RoundChoicesView), findsOneWidget);
    final round = tester.widget<RoundChoicesView>(
      find.byType(RoundChoicesView),
    );
    expect(round.spec.stimulus, isNotNull);
    expect(round.hint.locale, 'tr');
    expect(round.hint.visibleChoices, 4);
    final stimulus = find.byKey(
      ValueKey('group-stimulus-${round.hint.generation}'),
    );
    expect(stimulus, findsOneWidget);
    final stimulusRect = tester.getRect(stimulus);
    expect(stimulusRect.width, greaterThanOrEqualTo(96));
    expect(stimulusRect.height, greaterThanOrEqualTo(96));
    expect(stimulusRect.left, greaterThanOrEqualTo(0));
    expect(stimulusRect.top, greaterThanOrEqualTo(0));
    expect(stimulusRect.right, lessThanOrEqualTo(viewport.width));
    expect(stimulusRect.bottom, lessThanOrEqualTo(viewport.height));
    final prompt = find.text(round.spec.promptTr);
    expect(prompt, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(prompt).didExceedMaxLines,
      isFalse,
    );
    final ids = round.spec.choices.map((item) => item.id).toSet();
    expect(ids, hasLength(4));
    final generation = round.hint.generation;
    final pageFinder = find.byKey(ValueKey('choice-pages-$generation'));
    PageController pager() => tester.widget<PageView>(pageFinder).controller!;
    final visited = <String>{};
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    for (var page = 0; page < 2; page++) {
      if (page == 1) {
        await tester.tap(find.byKey(const ValueKey('choices-next')));
        await tester.pumpAndSettle();
      }
      expect(pager().page, page.toDouble());
      final pageChoices = round.spec.choices.skip(page * 2).take(2);
      for (final item in pageChoices) {
        visited.add(item.id);
        final card = find.byKey(ValueKey('$generation:${item.id}'));
        expect(card, findsOneWidget, reason: 'choice ${item.id}, page $page');
        final rect = tester.getRect(card);
        expect(rect.left, greaterThanOrEqualTo(0), reason: item.id);
        expect(rect.top, greaterThanOrEqualTo(0), reason: item.id);
        expect(rect.right, lessThanOrEqualTo(viewport.width), reason: item.id);
        expect(
          rect.bottom,
          lessThanOrEqualTo(viewport.height),
          reason: item.id,
        );
        expect(rect.width, greaterThanOrEqualTo(48), reason: item.id);
        expect(rect.height, greaterThanOrEqualTo(48), reason: item.id);

        final label = find.text(item.name('tr'));
        expect(label, findsOneWidget, reason: item.id);
        final paragraph = tester.renderObject<RenderParagraph>(label);
        expect(paragraph.didExceedMaxLines, isFalse, reason: item.id);
      }
      final name = 'seg-g04-tr-page${page + 1}';
      await binding.takeScreenshot(name);
    }
    expect(visited, ids, reason: 'both pages must expose every answer');
    final wrong = round.spec.choices.firstWhere(
      (item) => item.id != round.spec.target.id,
    );
    final wrongPage = round.spec.choices.indexOf(wrong) ~/ 2;
    if (wrongPage != 1) {
      await tester.tap(find.byKey(const ValueKey('choices-previous')));
      await tester.pumpAndSettle();
    }
    final wrongCard = find.byKey(ValueKey('$generation:${wrong.id}'));
    await tester.tap(wrongCard);
    await tester.pump();
    await tester.tap(wrongCard);
    await tester.pumpAndSettle();
    final supportedRound = tester.widget<RoundChoicesView>(
      find.byType(RoundChoicesView),
    );
    expect(supportedRound.hint.level, greaterThanOrEqualTo(3));
    expect(pager().page, round.spec.choices.indexOf(round.spec.target) ~/ 2);
    final target = find.byKey(ValueKey('$generation:${round.spec.target.id}'));
    expect(target, findsOneWidget);
    expect(
      tester.widget<ChoiceCard>(target).hintLevel,
      greaterThanOrEqualTo(3),
    );
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final burst = find.byKey(ValueKey('full-celebration-$generation'));
    expect(burst, findsOneWidget);
    const burstName = 'seg-g04-tr-full-celebration';
    await binding.takeScreenshot(burstName);
    expect(tester.takeException(), isNull);
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
    await cleanup();
  });

  testWidgets('G01 English choices fit at native landscape viewport', (
    tester,
  ) async {
    final fixture = await _openGame(
      tester,
      theme: 'animals',
      game: 'G01',
      locale: 'en',
      textScale: 1,
    );
    addTearDown(() => _closeGame(tester, fixture));
    final viewport = fixture.viewport;
    expect(viewport.width, greaterThan(viewport.height));
    expect(find.byType(RoundChoicesView), findsOneWidget);
    final round = tester.widget<RoundChoicesView>(
      find.byType(RoundChoicesView),
    );
    expect(round.hint.locale, 'en');
    expect(round.spec.choices, hasLength(4));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    for (final item in round.spec.choices) {
      final card = find.byKey(ValueKey('${round.hint.generation}:${item.id}'));
      expect(card, findsOneWidget, reason: item.id);
      final rect = tester.getRect(card);
      _expectBounds(rect, viewport, item.id);
      expect(rect.width, greaterThanOrEqualTo(48), reason: item.id);
      expect(rect.height, greaterThanOrEqualTo(48), reason: item.id);
      final label = find.text(item.name('en'));
      expect(label, findsOneWidget, reason: item.id);
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isFalse,
        reason: item.id,
      );
    }
    await binding.takeScreenshot('seg-g01-en-choices');
    expect(_verticalScrollables(tester), isEmpty);

    final target = find.byKey(
      ValueKey('${round.hint.generation}:${round.spec.target.id}'),
    );
    await tester.tap(target);
    await tester.pump();
    final answered = tester.widget<RoundChoicesView>(
      find.byType(RoundChoicesView),
    );
    expect(answered.hint.celebrating, isTrue);
    expect(tester.widget<ChoiceCard>(target).state, ChoiceCardState.correct);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G33 Turkish counted game fits 2x text at native landscape', (
    tester,
  ) async {
    final fixture = await _openGame(
      tester,
      theme: 'numbers',
      game: 'G33',
      locale: 'tr',
      textScale: 2,
    );
    addTearDown(() => _closeGame(tester, fixture));
    final viewport = fixture.viewport;
    expect(viewport.width, greaterThan(viewport.height));
    expect(find.byType(CountedObjects), findsOneWidget);
    final counted = tester.widget<CountedObjects>(find.byType(CountedObjects));
    expect(counted.count, greaterThan(0));
    expect(find.byType(RoundChoicesView), findsOneWidget);
    final round = tester.widget<RoundChoicesView>(
      find.byType(RoundChoicesView),
    );
    expect(round.hint.locale, 'tr');
    expect(round.spec.count, counted.count);
    expect(round.spec.choices, hasLength(4));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    for (var index = 0; index < counted.count; index++) {
      final object = find.byKey(ValueKey('count-object-$index'));
      expect(object, findsOneWidget, reason: 'counted object $index');
      await Scrollable.ensureVisible(
        tester.element(object),
        alignment: 0.5,
        duration: Duration.zero,
      );
      await tester.pump();
      final rect = tester.getRect(object);
      _expectBounds(rect, viewport, 'counted object $index');
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      await tester.tap(object);
      await tester.pump();
    }
    await binding.takeScreenshot('seg-g33-tr-counted-objects');

    for (final item in round.spec.choices) {
      final card = find.byKey(ValueKey('${round.hint.generation}:${item.id}'));
      expect(card, findsOneWidget, reason: item.id);
      final rect = tester.getRect(card);
      _expectBounds(rect, viewport, 'choice ${item.id}');
      expect(rect.width, greaterThanOrEqualTo(48), reason: item.id);
      expect(rect.height, greaterThanOrEqualTo(48), reason: item.id);
    }
    await binding.takeScreenshot('seg-g33-tr-choices');
    expect(_verticalScrollables(tester), isEmpty);

    final target = find.byKey(
      ValueKey('${round.hint.generation}:${round.spec.target.id}'),
    );
    await tester.tap(target);
    await tester.pump();
    expect(
      tester
          .widget<RoundChoicesView>(find.byType(RoundChoicesView))
          .hint
          .celebrating,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

class _NativeGameFixture {
  final AppState state;
  final AppDatabase db;
  final Size viewport;

  const _NativeGameFixture(this.state, this.db, this.viewport);
}

Future<_NativeGameFixture> _openGame(
  WidgetTester tester, {
  required String theme,
  required String game,
  required String locale,
  required double textScale,
}) async {
  final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final content = await tester.runAsync(ContentRepository.load);
  expect(content, isNotNull, reason: 'production content bundle loads');
  final state = AppState(content!, db, AudioService());
  await tester.runAsync(state.load);
  await tester.runAsync(() => state.createProfile('Local test', 'cat', {}));
  state.locale = locale;
  state.sound = false;
  state.audio.enabled = false;
  state.introduction = false;
  state.hintSeconds = 0;
  state.configuration = AppConfiguration(
    freeGames: {'${theme}_$game'},
    choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
  );
  expect(
    state.canPlay(theme, game, Difficulty.medium),
    isTrue,
    reason: '$theme/$game fixture has local access',
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: segTheme(),
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: GameScreen(
        state: state,
        themeId: theme,
        gameId: game,
        difficulty: Difficulty.medium,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  return _NativeGameFixture(state, db, viewport);
}

Future<void> _closeGame(WidgetTester tester, _NativeGameFixture fixture) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final sessions = await fixture.db.select(fixture.db.gameSessions).get();
      if (sessions.isNotEmpty && sessions.every((x) => x.endedAt != null)) {
        await fixture.state.refreshTrials();
        final refreshed = await fixture.db
            .select(fixture.db.gameSessions)
            .get();
        if (refreshed.isNotEmpty && refreshed.every((x) => x.endedAt != null)) {
          break;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final sessions = await fixture.db.select(fixture.db.gameSessions).get();
    if (sessions.isEmpty || sessions.any((x) => x.endedAt == null)) {
      throw StateError(
        'GameScreen did not finish its session before DB close.',
      );
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

Iterable<Scrollable> _verticalScrollables(WidgetTester tester) => tester
    .widgetList<Scrollable>(find.byType(Scrollable))
    .where(
      (scrollable) =>
          scrollable.axisDirection == AxisDirection.down ||
          scrollable.axisDirection == AxisDirection.up,
    );
