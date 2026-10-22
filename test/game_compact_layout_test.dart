import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/round_spec.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async {
    content = await ContentRepository.load();
  });

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

  testWidgets(
    'Hard choice, counted, and sequence games fit compact 2x landscape in TR/EN',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadFonts(tester);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);

      for (final locale in ['tr', 'en']) {
        for (final game in [
          (theme: 'animals', id: 'G01'), // Four long-name answer cards.
          (theme: 'animals', id: 'G04'), // Separate group stimulus image.
          (theme: 'numbers', id: 'G33'), // Counted objects plus answers.
          (theme: 'numbers', id: 'G35'), // Sequence prompt plus answers.
          (theme: 'numbers', id: 'G36'), // Quantity-based numeric comparison.
        ]) {
          final state = AppState(
            content,
            AppDatabase.forTesting(NativeDatabase.memory()),
            AudioService(),
          );
          await state.load();
          await state.createProfile('Test', 'cat', {});
          state.locale = locale;
          state.sound = false;
          state.audio.enabled = false;
          state.introduction = false;
          state.hintSeconds = 0;
          // Medium and Hard cards need Premium.
          state.entitlement.lifetimeOwned = true;
          state.configuration = AppConfiguration(
            freeGames: {
              ...content.freeGames,
              'animals_G04',
              'numbers_G33',
              'numbers_G36',
            },
            choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
          );
          expect(
            state.canPlay(game.theme, game.id, Difficulty.medium),
            isTrue,
            reason: '$locale ${game.id} must use local test access',
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: segTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: GameScreen(
                state: state,
                themeId: game.theme,
                gameId: game.id,
                difficulty: Difficulty.medium,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 650));

          final tag = '$locale ${game.id}';
          expect(find.byType(RoundChoicesView), findsOneWidget, reason: tag);
          final round = tester.widget<RoundChoicesView>(
            find.byType(RoundChoicesView),
          );
          expect(round.hint.locale, locale, reason: tag);
          // Groups show at most three baskets/groups side by side.
          final expectedChoices = game.id == 'G36' || game.id == 'G04' ? 3 : 4;
          expect(round.spec.choices, hasLength(expectedChoices), reason: tag);
          expect(round.hint.visibleChoices, expectedChoices, reason: tag);
          if (game.id == 'G04') {
            expect(round.spec.stimulus, isNotNull, reason: tag);
            final stimulus = find.byKey(
              ValueKey('group-stimulus-${round.hint.generation}'),
            );
            expect(stimulus, findsOneWidget, reason: tag);
            final stimulusRect = tester.getRect(stimulus);
            expect(stimulusRect.width, greaterThanOrEqualTo(96), reason: tag);
            expect(stimulusRect.height, greaterThanOrEqualTo(96), reason: tag);
            _expectInBounds(
              tester,
              stimulus,
              const Size(800, 360),
              '$tag group stimulus',
            );
            expect(
              tester.widgetList<ItemVisual>(find.byType(ItemVisual)).length,
              greaterThanOrEqualTo(3),
              reason: '$tag stimulus and answer visuals',
            );
          }
          if (game.id == 'G36') {
            expect(
              round.spec.quantities,
              hasLength(expectedChoices),
              reason: tag,
            );
            expect(
              find.byType(QuantityVisual),
              findsNWidgets(expectedChoices),
              reason: tag,
            );
          }

          final prompt = locale == 'tr'
              ? round.spec.promptTr
              : round.spec.promptEn;
          if (state.showLabels && prompt.isNotEmpty) {
            final promptFinder = find.text(prompt);
            expect(promptFinder, findsOneWidget, reason: tag);
            expect(
              tester
                  .renderObject<RenderParagraph>(promptFinder)
                  .didExceedMaxLines,
              isFalse,
              reason: '$tag prompt must remain readable',
            );
            _expectInBounds(
              tester,
              promptFinder,
              const Size(800, 360),
              '$tag prompt',
            );
          }
          if (round.spec.sequence.isNotEmpty) {
            final sequenceFinder = find.byType(SequenceRow);
            expect(sequenceFinder, findsOneWidget, reason: tag);
            _expectInBounds(
              tester,
              sequenceFinder,
              const Size(800, 360),
              '$tag sequence',
            );
          }

          final generation = round.hint.generation;
          final visitedChoices = <String>{};
          // Groups (at most three) stand in one row without paging.
          const pageCount = 1;
          for (var page = 0; page < pageCount; page++) {
            if (page > 0) {
              await tester.tap(find.byKey(const ValueKey('choices-next')));
              await tester.pumpAndSettle();
            }
            final pageItems = round.spec.choices;
            for (final item in pageItems) {
              visitedChoices.add(item.id);
              final key = ValueKey('$generation:${item.id}');
              final cardFinder = find.byKey(key);
              final rect = tester.getRect(cardFinder);
              expect(
                rect.left,
                greaterThanOrEqualTo(0),
                reason: '$tag ${item.id}',
              );
              expect(
                rect.top,
                greaterThanOrEqualTo(0),
                reason: '$tag ${item.id}',
              );
              expect(
                rect.right,
                lessThanOrEqualTo(800),
                reason: '$tag ${item.id}',
              );
              expect(
                rect.bottom,
                lessThanOrEqualTo(360),
                reason: '$tag ${item.id}',
              );
              expect(
                rect.width,
                greaterThanOrEqualTo(48),
                reason: '$tag ${item.id}',
              );
              expect(
                rect.height,
                greaterThanOrEqualTo(48),
                reason: '$tag ${item.id}',
              );

              if (round.spec.quantities.isEmpty) {
                final labelFinder = find.text(item.name(locale));
                expect(
                  labelFinder,
                  findsOneWidget,
                  reason: '$tag ${item.id} label',
                );
                final paragraph = tester.renderObject<RenderParagraph>(
                  labelFinder,
                );
                expect(
                  paragraph.didExceedMaxLines,
                  isFalse,
                  reason:
                      '$tag ${item.id} label must not be visually truncated',
                );
              }
            }
          }
          expect(
            visitedChoices,
            round.spec.choices.map((item) => item.id).toSet(),
            reason: '$tag every answer must be reachable',
          );

          for (final button in tester.widgetList<IconButton>(
            find.byType(IconButton),
          )) {
            final buttonFinder = find.byWidget(button);
            final rect = tester.getRect(buttonFinder);
            expect(rect.left, greaterThanOrEqualTo(0), reason: '$tag action');
            expect(rect.top, greaterThanOrEqualTo(0), reason: '$tag action');
            expect(rect.right, lessThanOrEqualTo(800), reason: '$tag action');
            expect(rect.bottom, lessThanOrEqualTo(360), reason: '$tag action');
          }
          expect(_verticalScrollables(tester), isEmpty, reason: tag);
          expect(tester.takeException(), isNull, reason: tag);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          state.dispose();
          await state.db.close();
        }
      }
    },
  );

  testWidgets('G14 Hard presents a readable side-by-side photo prompt', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);

    for (final locale in ['tr', 'en']) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final state = AppState(content, db, AudioService());
      await state.load();
      await state.createProfile('Test', 'cat', {});
      state.locale = locale;
      state.sound = false;
      state.audio.enabled = false;
      state.introduction = false;
      state.hintSeconds = 0;
      // Medium and Hard cards need Premium.
      state.entitlement.lifetimeOwned = true;
      state.configuration = AppConfiguration(
        freeGames: const {'animals_G14'},
        choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
      );
      state.entitlement
        ..storeActive = true
        ..lastConfirmedAt = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: GameScreen(
            state: state,
            themeId: 'animals',
            gameId: 'G14',
            difficulty: Difficulty.hard,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      final round = tester.widget<RoundChoicesView>(
        find.byType(RoundChoicesView),
      );
      final visual = find.byKey(
        ValueKey('g14-prompt-${round.hint.generation}'),
      );
      expect(visual, findsOneWidget, reason: locale);
      final rect = tester.getRect(visual);
      expect(rect.width, greaterThanOrEqualTo(96), reason: locale);
      expect(rect.height, greaterThanOrEqualTo(96), reason: locale);
      expect(
        find.text(locale == 'tr' ? 'Aynısını bul' : 'Find the match'),
        findsOneWidget,
        reason: locale,
      );
      expect(_verticalScrollables(tester), isEmpty, reason: locale);
      expect(tester.takeException(), isNull, reason: locale);

      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await db.close();
    }
  });

  testWidgets(
    'G04 choice pager honors hints, reduced motion, and round reset',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadFonts(tester);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);

      final choices = content
          .pool('animals', Difficulty.medium)
          .where((item) => item.images.isNotEmpty)
          .take(4)
          .toList();
      expect(choices, hasLength(4));
      final spec = RoundSpec(
        target: choices.last,
        choices: choices,
        promptTr: 'Görsel grubu',
        promptEn: 'Picture group',
        stimulus: choices.first,
      );
      var hint = HintViewState(
        level: 0,
        visibleChoices: choices.length,
        wrongCount: 0,
        generation: 1,
        celebrating: false,
        showLabels: true,
        animate: true,
        locale: 'tr',
      );
      var disableAnimations = false;
      late StateSetter updateHarness;
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          home: StatefulBuilder(
            builder: (context, setState) {
              updateHarness = setState;
              return MediaQuery(
                data: MediaQueryData(
                  size: const Size(800, 360),
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: disableAnimations,
                ),
                child: Scaffold(
                  body: SizedBox.expand(
                    child: RoundChoicesView(
                      spec: spec,
                      callbacks: RoundCallbacks(onSelect: (_) {}),
                      hint: hint,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      PageController pager() => tester
          .widget<PageView>(
            find.byKey(ValueKey('choice-pages-${hint.generation}')),
          )
          .controller!;
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('choices-next')))
            .onPressed,
        isNotNull,
      );
      tester
          .widget<IconButton>(find.byKey(const ValueKey('choices-next')))
          .onPressed!();
      await tester.pumpAndSettle();
      expect(pager().page, 1);

      hint = HintViewState(
        level: 0,
        visibleChoices: choices.length,
        wrongCount: 0,
        generation: 1,
        celebrating: false,
        showLabels: true,
        animate: false,
        locale: 'tr',
      );
      updateHarness(() {});
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('choices-previous')));
      await tester.pump();
      expect(pager().page, 0, reason: 'AppState reduced-motion signal');

      disableAnimations = true;
      updateHarness(() {});
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('choices-next')));
      await tester.pump();
      expect(pager().page, 1, reason: 'MediaQuery reduced-motion signal');

      hint = HintViewState(
        level: 0,
        visibleChoices: choices.length,
        wrongCount: 0,
        generation: 1,
        celebrating: false,
        showLabels: true,
        animate: false,
        locale: 'tr',
      );
      disableAnimations = false;
      updateHarness(() {});
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('choices-previous')));
      await tester.pump();
      expect(pager().page, 0);
      hint = HintViewState(
        level: 3,
        visibleChoices: choices.length,
        wrongCount: 0,
        generation: 1,
        celebrating: false,
        showLabels: true,
        animate: false,
        locale: 'tr',
      );
      updateHarness(() {});
      await tester.pump();
      await tester.pump();
      expect(pager().page, 1, reason: 'off-page correct answer is revealed');
      final correct = find.byKey(ValueKey('1:${spec.target.id}'));
      expect(correct, findsOneWidget);
      expect(tester.getRect(correct), _fullyWithin(const Size(800, 360)));
      expect(tester.widget<ChoiceCard>(correct).hintLevel, 3);

      hint = HintViewState(
        level: 0,
        visibleChoices: choices.length,
        wrongCount: 0,
        generation: 2,
        celebrating: false,
        showLabels: true,
        animate: false,
        locale: 'tr',
      );
      updateHarness(() {});
      await tester.pump();
      await tester.pump();
      expect(pager().page, 0, reason: 'new round returns to first page');

      hint = HintViewState(
        level: 0,
        visibleChoices: choices.length,
        wrongCount: 2,
        generation: 2,
        celebrating: true,
        showLabels: true,
        animate: false,
        locale: 'tr',
      );
      updateHarness(() {});
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('choices-next')))
            .onPressed,
        isNull,
        reason: 'celebration locks page navigation',
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('choices-previous')))
            .onPressed,
        isNull,
        reason: 'celebration locks page navigation',
      );
      await tester.drag(
        find.byKey(const ValueKey('choice-pages-2')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(pager().page, 0, reason: 'celebration keeps focus on the answer');

      hint = HintViewState(
        level: 0,
        visibleChoices: choices.length,
        wrongCount: 0,
        generation: 3,
        celebrating: false,
        showLabels: true,
        animate: false,
        locale: 'tr',
      );
      updateHarness(() {});
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('choices-next')))
            .onPressed,
        isNotNull,
        reason: 'new round unlocks page navigation',
      );
      await tester.tap(find.byKey(const ValueKey('choices-next')));
      await tester.pump();
      expect(pager().page, 1);
      expect(_verticalScrollables(tester), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Insufficient-content state fits compact large-text landscape', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);

    final tooSmallCategoryPool = ContentRepository(
      content.themes,
      [content.items.firstWhere((item) => item.id == 'animals.frog')],
      content.games,
      content.freeGames,
      content.configDefaults,
    );
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final state = AppState(tooSmallCategoryPool, db, AudioService());
    addTearDown(() async {
      state.dispose();
      await db.close();
    });
    await state.load();
    await state.createProfile('Test', 'cat', {});
    state.locale = 'tr';
    state.sound = false;
    state.audio.enabled = false;
    // Medium and Hard cards need Premium.
    state.entitlement.lifetimeOwned = true;
    state.configuration = AppConfiguration(
      freeGames: const {'animals_G04'},
      choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 360),
            textScaler: TextScaler.linear(2),
          ),
          child: GameScreen(
            state: state,
            themeId: 'animals',
            gameId: 'G04',
            difficulty: Difficulty.medium,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Bu oyun için yeterli içerik henüz hazır değil.'),
      findsOneWidget,
    );
    final back = find.text('Temaya dön');
    expect(back, findsOneWidget);
    final backRect = tester.getRect(back);
    expect(backRect.width, greaterThanOrEqualTo(48));
    expect(backRect.height, greaterThanOrEqualTo(48));
    expect(backRect.left, greaterThanOrEqualTo(0));
    expect(backRect.top, greaterThanOrEqualTo(0));
    expect(backRect.right, lessThanOrEqualTo(800));
    expect(backRect.bottom, lessThanOrEqualTo(360));
    expect(_verticalScrollables(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G14 Hard unavailable notice fits compact TR/EN at 2x', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1600, 720);

    final withoutFishVariants = ContentRepository(
      content.themes,
      content.items.where((item) => item.id != 'animals.fish').toList(),
      content.games,
      content.freeGames,
      content.configDefaults,
    );
    for (final locale in ['tr', 'en']) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final state = AppState(withoutFishVariants, db, AudioService());
      await state.load();
      await state.createProfile('Test', 'cat', {});
      state.locale = locale;
      state.sound = false;
      state.audio.enabled = false;
      state.difficultyOverride = 'hard';
      // Medium and Hard cards need Premium.
      state.entitlement.lifetimeOwned = true;
      state.configuration = AppConfiguration(
        freeGames: const {'animals_G14'},
        choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
      );
      state.entitlement
        ..storeActive = true
        ..lastConfirmedAt = DateTime.now();
      expect(withoutFishVariants.hasG14HardVariants('animals'), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: GameScreen(
            state: state,
            themeId: 'animals',
            gameId: 'G14',
            difficulty: Difficulty.hard,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          locale == 'tr'
              ? 'Bu oyun için yeterli içerik henüz hazır değil.'
              : 'There is not enough content for this game yet.',
        ),
        findsOneWidget,
      );
      final back = find.text(locale == 'tr' ? 'Temaya dön' : 'Back to theme');
      expect(back, findsOneWidget);
      final backRect = tester.getRect(back);
      expect(backRect.width, greaterThanOrEqualTo(48));
      expect(backRect.height, greaterThanOrEqualTo(48));
      expect(backRect.left, greaterThanOrEqualTo(0));
      expect(backRect.top, greaterThanOrEqualTo(0));
      expect(backRect.right, lessThanOrEqualTo(800));
      expect(backRect.bottom, lessThanOrEqualTo(360));
      expect(_verticalScrollables(tester), isEmpty);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await db.close();
    }
  });

  testWidgets('Correct feedback fits a fractional 2x landscape choice card', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadFonts(tester);
    tester.view.devicePixelRatio = 2.375;
    tester.view.physicalSize = const Size(2424, 1080);

    final item = content.items.firstWhere((item) => item.theme == 'numbers');
    var cardState = ChoiceCardState.idle;
    late StateSetter setCardState;
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
          body: Center(
            child: SizedBox(
              width: 160,
              height: 95.291,
              child: StatefulBuilder(
                builder: (context, setState) {
                  setCardState = setState;
                  return ChoiceCard(
                    item: item,
                    locale: 'tr',
                    state: cardState,
                    compact: true,
                    animate: false,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    cardState = ChoiceCardState.correct;
    setCardState(() {});
    await tester.pump();

    // Success is a soft halo behind the object, not a check badge.
    expect(find.byKey(const ValueKey('choice-success-halo')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    final label = find.text(item.name('tr'));
    expect(label, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}

Matcher _fullyWithin(Size size) => predicate<Rect>(
  (rect) =>
      rect.left >= 0 &&
      rect.top >= 0 &&
      rect.right <= size.width &&
      rect.bottom <= size.height,
  'rectangle contained by $size',
);

void _expectInBounds(
  WidgetTester tester,
  Finder finder,
  Size size,
  String reason,
) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.right, lessThanOrEqualTo(size.width), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(size.height), reason: reason);
}

Iterable<Scrollable> _verticalScrollables(WidgetTester tester) => tester
    .widgetList<Scrollable>(find.byType(Scrollable))
    .where(
      (scrollable) =>
          scrollable.axisDirection == AxisDirection.down ||
          scrollable.axisDirection == AxisDirection.up,
    );
