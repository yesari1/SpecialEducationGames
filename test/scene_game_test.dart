import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/features/game/round_spec.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/features/game/widgets/scene_game_view.dart';

ContentItem _item(String id) => ContentItem.fromJson({
  'id': id,
  'theme': 'extra',
  'tier': 'easy',
  'name': {'tr': id, 'en': id},
  'images': ['assets/images/props/ball.webp'],
});

void main() {
  final right = _item('props.ball'), wrong = _item('props.book');
  const one = SceneRect(.3, .3, .2, .2);
  const gift = 'assets/images/scenes/gift.jpg';
  const box = 'assets/images/scenes/surprise_box.jpg';

  RoundSpec spec(List<SceneStep> steps) => RoundSpec(
    target: right,
    choices: [right, wrong],
    promptTr: 'Soru',
    promptEn: 'Question',
    fullStage: true,
    scene: SceneRound(
      key: 'a',
      tier: 'easy',
      target: right.id,
      stage: gift,
      text: const {'tr': 'Soru'},
      audio: const {},
      steps: steps,
    ),
    scenePieces: {right.id: right, wrong.id: wrong},
  );

  HintViewState hint({int generation = 1, bool celebrating = false}) =>
      HintViewState(
        level: 0,
        visibleChoices: 2,
        wrongCount: 0,
        generation: generation,
        celebrating: celebrating,
        showLabels: true,
        animate: false,
        locale: 'tr',
      );

  Future<List<ContentItem>> pump(
    WidgetTester tester,
    RoundSpec s,
    List<List<String>> said,
  ) async {
    final selected = <ContentItem>[];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 340);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SceneGameView(
            spec: s,
            hint: hint(),
            callbacks: RoundCallbacks(onSelect: selected.add, onSay: said.add),
          ),
        ),
      ),
    );
    await tester.pump();
    return selected;
  }

  String shown(WidgetTester tester) =>
      (tester
                  .widgetList<Image>(
                    find.descendant(
                      of: find.byKey(const ValueKey('scene-stage')),
                      matching: find.byType(Image),
                    ),
                  )
                  .first
                  .image
              as AssetImage)
          .assetName;

  testWidgets(
    'wrong piece is a wrong answer; right piece changes the picture',
    (tester) async {
      final said = <List<String>>[];
      final selected = await pump(
        tester,
        spec([
          SceneStep(
            mode: SceneStepMode.place,
            piece: right.id,
            others: [wrong.id],
            zone: one,
            after: box,
            doneAudio: const {'tr': 'done.mp3'},
          ),
          SceneStep(
            mode: SceneStepMode.place,
            piece: wrong.id,
            zone: one,
            askAudio: const {'tr': 'ask.mp3'},
          ),
        ]),
        said,
      );
      await tester.tap(find.byKey(ValueKey('scene-piece-${wrong.id}')));
      await tester.pump();
      expect(selected.single.id, wrong.id);
      expect(shown(tester), gift);
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(ValueKey('scene-piece-${right.id}')));
      await tester.pump();
      expect(shown(tester), box);
      expect(said.single, ['done.mp3', 'ask.mp3']);
      expect(selected, hasLength(1));

      await tester.tap(find.byKey(ValueKey('scene-piece-${wrong.id}')));
      await tester.pump();
      expect(
        selected.last.id,
        right.id,
        reason: 'last step finishes the round',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dragging the right piece to the picture works', (tester) async {
    final selected = await pump(
      tester,
      spec([SceneStep(mode: SceneStepMode.place, piece: right.id, zone: one)]),
      [],
    );
    await tester.drag(
      find.byKey(ValueKey('scene-piece-${right.id}')),
      const Offset(-500, 0),
    );
    await tester.pump();
    expect(selected.single.id, right.id);
  });

  testWidgets('gentle round: drag only, a piece not asked yet just goes back', (
    tester,
  ) async {
    final said = <List<String>>[];
    final base = spec([
      SceneStep(
        mode: SceneStepMode.place,
        piece: right.id,
        zone: one,
        stays: true,
      ),
      SceneStep(
        mode: SceneStepMode.place,
        piece: wrong.id,
        zone: one,
        stays: true,
      ),
    ]);
    final gentle = RoundSpec(
      target: right,
      choices: [right],
      promptTr: 'Soru',
      promptEn: 'Question',
      fullStage: true,
      scene: SceneRound(
        key: 'b',
        tier: 'easy',
        target: right.id,
        stage: gift,
        text: const {'tr': 'Soru'},
        audio: const {'tr': 'ask.mp3'},
        steps: base.scene!.steps,
        gentle: true,
      ),
      scenePieces: base.scenePieces,
    );
    final selected = await pump(tester, gentle, said);
    // The finger shows the way when the game opens.
    await tester.pump();
    expect(find.byKey(const ValueKey('scene-finger')), findsOneWidget);
    // Both pieces wait in the tray; tapping does nothing.
    await tester.tap(find.byKey(ValueKey('scene-piece-${right.id}')));
    await tester.pump();
    expect(find.byKey(const ValueKey('scene-placed-0')), findsNothing);
    // The piece that is not asked yet goes back, with the question again.
    await tester.drag(
      find.byKey(ValueKey('scene-piece-${wrong.id}')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(said.single, ['ask.mp3']);
    expect(selected, isEmpty);
    expect(find.byKey(const ValueKey('scene-finger')), findsNothing);
    // Twelve quiet seconds bring the finger back.
    await tester.pump(const Duration(seconds: 13));
    await tester.pump();
    expect(find.byKey(const ValueKey('scene-finger')), findsOneWidget);
    expect(find.byKey(ValueKey('scene-piece-${wrong.id}')), findsOneWidget);
    // The asked piece stays on the table and leaves the tray.
    await tester.drag(
      find.byKey(ValueKey('scene-piece-${right.id}')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scene-placed-0')), findsOneWidget);
    expect(find.byKey(ValueKey('scene-piece-${right.id}')), findsNothing);
  });

  testWidgets('rub step: every spot must go', (tester) async {
    final selected = await pump(
      tester,
      spec([
        SceneStep(
          mode: SceneStepMode.rub,
          piece: right.id,
          zone: one,
          spots: const [SceneRect(.2, .2, .1, .1), SceneRect(.6, .6, .1, .1)],
        ),
      ]),
      [],
    );
    // Brushing, not tapping: the brush (held by its handle) scrubs a stain
    // away little by little.
    final stage = tester.getRect(find.byKey(const ValueKey('scene-stage')));
    final side = stage.shortestSide * .36 * 1.5;
    final head = Offset(-side * 1.3 * .62, side * 1.3 * .03);
    Future<void> scrub(SceneRect r) async {
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('scene-tool'))),
      );
      await tester.pump();
      final at = Offset(
        stage.left + (r.x + r.w / 2) * stage.width,
        stage.top + (r.y + r.h / 2) * stage.height,
      );
      await g.moveTo(at - head);
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await g.moveBy(Offset(i.isEven ? 30 : -30, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump();
    }

    await tester.tap(
      find.byKey(const ValueKey('scene-spot-0')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('scene-spot-0')), findsOneWidget);
    await scrub(const SceneRect(.2, .2, .1, .1));
    expect(find.byKey(const ValueKey('scene-spot-0')), findsNothing);
    expect(selected, isEmpty);
    await scrub(const SceneRect(.6, .6, .1, .1));
    expect(selected.single.id, right.id);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('stir step: a few taps also do it', (tester) async {
    final selected = await pump(
      tester,
      spec([SceneStep(mode: SceneStepMode.stir, piece: right.id, zone: one)]),
      [],
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('scene-stage')));
      await tester.pump();
    }
    expect(selected, isEmpty);
    await tester.tap(find.byKey(const ValueKey('scene-stage')));
    await tester.pump();
    expect(selected.single.id, right.id);
  });
}
