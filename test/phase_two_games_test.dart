import 'dart:math';

import 'package:drift/native.dart';
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
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/round_spec.dart';
import 'package:special_education_games/features/game/templates/game_template.dart';
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

  Future<AppState> mountGame(
    WidgetTester tester,
    String themeId,
    String gameId, {
    String locale = 'tr',
    Size size = const Size(800, 360),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    // Make the premium game playable for the test without a store.
    state.configuration = AppConfiguration(
      freeGames: {...content.freeGames, '${themeId}_$gameId'},
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        home: GameScreen(
          state: state,
          themeId: themeId,
          gameId: gameId,
          difficulty: Difficulty.easy,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    return state;
  }

  RoundChoicesView round(WidgetTester tester) =>
      tester.widget<RoundChoicesView>(find.byType(RoundChoicesView));

  Finder card(WidgetTester tester, String itemId) =>
      find.byKey(ValueKey('${round(tester).hint.generation}:$itemId'));

  Future<void> dragStimulusOnto(WidgetTester tester, Finder target) async {
    final generation = round(tester).hint.generation;
    final stimulus = find.byKey(ValueKey('group-stimulus-$generation'));
    expect(stimulus, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(stimulus));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  test('phase-two games are registered on their themes', () {
    for (final (theme, game) in const [
      ('animals', 'G15'),
      ('animals', 'G17'),
      ('animals', 'G23'),
      ('produce', 'G15'),
      ('produce', 'G17'),
      ('produce', 'G23'),
      ('vehicles', 'G15'),
      ('vehicles', 'G17'),
      ('vehicles', 'G23'),
      ('numbers', 'G37'),
    ]) {
      expect(content.theme(theme).games, contains(game), reason: theme);
      expect(() => TemplateRegistry.resolve(game), returnsNormally);
    }
    // The six free games are unchanged; new games stay premium.
    expect(content.freeGames, hasLength(6));
    expect(
      content.freeGames.where(
        (key) => ['G15', 'G17', 'G23', 'G37'].any(key.endsWith),
      ),
      isEmpty,
    );
  });

  testWidgets('G15 shadow match accepts a drag onto the right shadow', (
    tester,
  ) async {
    await loadFonts(tester);
    await mountGame(tester, 'animals', 'G15');
    final spec = round(tester).spec;
    expect(spec.look, ChoiceLook.silhouette);
    expect(spec.stimulus?.id, spec.target.id);
    final silhouettes = tester
        .widgetList<ItemVisual>(find.byType(ItemVisual))
        .where((visual) => visual.silhouette);
    expect(silhouettes, hasLength(spec.choices.length));
    // Shadows carry no written name.
    expect(find.text(spec.target.name('tr')), findsNothing);

    await dragStimulusOnto(tester, card(tester, spec.target.id));
    expect(round(tester).hint.celebrating, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G23 basket sort works by drag and a wrong basket is refused', (
    tester,
  ) async {
    await loadFonts(tester);
    await mountGame(tester, 'produce', 'G23', locale: 'en');
    final spec = round(tester).spec;
    expect(spec.look, ChoiceLook.basket);
    expect(find.byType(BasketFrame), findsNWidgets(spec.choices.length));
    final wrong = spec.choices.firstWhere((x) => x.id != spec.target.id);
    await dragStimulusOnto(tester, card(tester, wrong.id));
    await tester.pump(const Duration(milliseconds: 700));
    expect(round(tester).hint.wrongCount, 1);
    expect(round(tester).hint.celebrating, isFalse);

    await dragStimulusOnto(tester, card(tester, spec.target.id));
    expect(round(tester).hint.celebrating, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G17 odd one out keeps three objects and accepts a tap', (
    tester,
  ) async {
    await loadFonts(tester);
    await mountGame(tester, 'vehicles', 'G17');
    final spec = round(tester).spec;
    expect(spec.choices.length, greaterThanOrEqualTo(3));
    final odd = spec.target;
    final others = spec.choices.where((x) => x.id != odd.id);
    expect(others.every((x) => x.theme == 'vehicles'), isTrue);
    expect(odd.theme, isNot('vehicles'));
    await tester.tap(card(tester, odd.id));
    await tester.pump();
    expect(round(tester).hint.celebrating, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G37 number and amount pairs a numeral with its quantity', (
    tester,
  ) async {
    await loadFonts(tester);
    await mountGame(tester, 'numbers', 'G37');
    final spec = round(tester).spec;
    expect(spec.stimulus?.id, spec.target.id);
    expect(find.byType(QuantityVisual), findsNWidgets(spec.choices.length));
    expect(
      spec.quantities[spec.target.id],
      int.parse(spec.target.slug),
      reason: 'the right card shows exactly the numeral',
    );
    expect(spec.quantities.values.toSet(), hasLength(spec.choices.length));
    await tester.tap(card(tester, spec.target.id));
    await tester.pump();
    expect(round(tester).hint.celebrating, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('odd one out hard stays within one theme with a different group', () {
    final scheduler = ItemScheduler(Random(3));
    for (var i = 0; i < 12; i++) {
      final spec = const OddOneOutTemplate().buildRound(
        ModeContext(
          content: content,
          themeId: 'produce',
          gameId: 'G17',
          difficulty: Difficulty.hard,
          scheduler: scheduler,
          struggle: const {},
        ),
      );
      expect(spec.choices.every((x) => x.theme == 'produce'), isTrue);
      final group = spec.choices.where((x) => x.id != spec.target.id);
      final shared = group
          .map((x) => x.tags.toSet())
          .reduce((a, b) => a.intersection(b));
      expect(
        shared.intersection(spec.target.tags.toSet()),
        isNot(containsAll(shared)),
        reason: 'the odd item must not belong to the shared group',
      );
    }
  });
}
