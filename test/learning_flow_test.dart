import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/learning/item_performance.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/round_controller.dart';

class ControlledStopwatch extends Stopwatch {
  int milliseconds = 0;
  bool running = false;
  @override
  int get elapsedMilliseconds => milliseconds;
  @override
  bool get isRunning => running;
  @override
  void start() => running = true;
  @override
  void stop() => running = false;
  @override
  void reset() => milliseconds = 0;
  void advance(int ms) {
    if (running) milliseconds += ms;
  }
}

ContentItem item(String id) => ContentItem.fromJson({
  'id': 'animals.$id',
  'theme': 'animals',
  'tier': 'easy',
  'name': {'tr': id, 'en': id},
  'audio': {},
  'images': ['test.png'],
  'tags': [],
});
void main() {
  final repo = ContentRepository(
    [],
    [item('cat'), item('dog'), item('rabbit')],
    [],
    {},
  );
  testWidgets(
    'Parent hint override disables idle hints but preserves error support',
    (tester) async {
      final clock = ControlledStopwatch();
      final c = RoundController(
        content: repo,
        themeId: 'animals',
        gameId: 'G01',
        difficulty: Difficulty.easy,
        struggle: {},
        saveTrial: (_) async {},
        playPrompt: (_) async {},
        responseClock: clock,
        total: 3,
        hintSeconds: 0,
        fadeWrongChoices: false,
      );
      c.start();
      await tester.pump();
      clock.advance(30000);
      await tester.pump(const Duration(seconds: 30));
      expect(c.hint, 0);
      final wrong = c.spec!.choices.firstWhere(
        (x) => x.id != c.spec!.target.id,
      );
      await c.choose(wrong);
      await c.choose(wrong);
      expect(c.hint, 2);
      expect(c.total, 3);
      c.dispose();
    },
  );
  testWidgets('Explicit hint delay overrides item fading delay', (
    tester,
  ) async {
    final clock = ControlledStopwatch();
    final c = RoundController(
      content: repo,
      themeId: 'animals',
      gameId: 'G01',
      difficulty: Difficulty.easy,
      struggle: {},
      saveTrial: (_) async {},
      playPrompt: (_) async {},
      responseClock: clock,
      hintSeconds: 10,
    );
    c.start();
    await tester.pump();
    clock.advance(6000);
    await tester.pump(const Duration(seconds: 6));
    expect(c.hint, 0);
    clock.advance(4000);
    await tester.pump(const Duration(seconds: 4));
    expect(c.hint, 1);
    c.dispose();
  });
  testWidgets('Counting touches are responses and do not count as idle time', (
    tester,
  ) async {
    final clock = ControlledStopwatch();
    final c = RoundController(
      content: repo,
      themeId: 'animals',
      gameId: 'G01',
      difficulty: Difficulty.easy,
      struggle: {},
      saveTrial: (_) async {},
      playPrompt: (_) async {},
      responseClock: clock,
    );
    c.start();
    await tester.pump();
    clock.advance(2000);
    c.noteInteraction(itemId: 'count.dot');
    clock.advance(2000);
    c.noteInteraction(itemId: 'count.dot');
    await tester.pump(const Duration(seconds: 4));
    expect(c.hint, 0);
    expect(c.firstLatency, 2000);
    expect(c.idleMs, 0);
    clock.advance(4000);
    await c.choose(c.spec!.target);
    expect(c.firstLatency, 2000);
    expect(c.idleMs, 1000);
    expect(c.selected.length, 3);
    c.dispose();
  });
  test('Fading follows independent and full-support streaks separately', () {
    final history = ItemPerformance.fromHistory([
      const LearningObservation('cat', 0, 0),
      const LearningObservation('cat', 0, 0),
      const LearningObservation('cat', 0, 0),
      const LearningObservation('dog', 4, 2),
      const LearningObservation('dog', 4, 2),
    ]);
    expect(
      history['cat']!.hintDelay(Difficulty.easy),
      const Duration(seconds: 8),
    );
    expect(history['dog']!.fieldSize(3), 2);
    expect(
      ItemPerformance.fromHistory([
        const LearningObservation('cat', 0, 0),
        const LearningObservation('cat', 2, 1),
      ])['cat']!.independentStreak,
      0,
    );
  });
  testWidgets(
    'Introduction is ungraded and leads to the same target with choices',
    (tester) async {
      var records = 0;
      final introduced = <String>[];
      final c = RoundController(
        content: repo,
        themeId: 'animals',
        gameId: 'G01',
        difficulty: Difficulty.easy,
        struggle: {},
        saveTrial: (_) async {
          records++;
        },
        playPrompt: (_) async {},
        introduceNewItems: true,
        onIntroduced: (id) async {
          introduced.add(id);
        },
        scheduler: ItemScheduler(Random(7)),
      );
      c.start();
      await tester.pump();
      expect(c.spec!.introduction, true);
      expect(c.spec!.choices.length, 1);
      final target = c.spec!.target;
      await c.choose(target);
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      expect(records, 0);
      expect(introduced, [target.id]);
      expect(c.stage, 0);
      expect(c.spec!.introduction, false);
      expect(c.spec!.target.id, target.id);
      expect(c.spec!.choices.length, 2);
      c.dispose();
    },
  );
  testWidgets(
    'Background time is excluded from latency, idle time and hint timing',
    (tester) async {
      final clock = ControlledStopwatch();
      final c = RoundController(
        content: repo,
        themeId: 'animals',
        gameId: 'G01',
        difficulty: Difficulty.easy,
        struggle: {},
        saveTrial: (_) async {},
        playPrompt: (_) async {},
        responseClock: clock,
      );
      c.start();
      await tester.pump();
      clock.advance(2000);
      c.pause();
      clock.advance(60000);
      await tester.pump(const Duration(seconds: 20));
      expect(c.hint, 0);
      expect(c.activeMs, 2000);
      c.resume();
      clock.advance(3500);
      await tester.pump(const Duration(seconds: 1));
      expect(c.hint, 1);
      await c.choose(c.spec!.target);
      expect(c.firstLatency, 5500);
      expect(c.idleMs, 2500);
      expect(c.activeMs, 5500);
      c.dispose();
    },
  );
  testWidgets(
    'Repeated full support reduces the field only once across introduction',
    (tester) async {
      final performance = {
        for (final i in repo.items)
          i.id: const ItemPerformance(fullSupportStreak: 2),
      };
      final c = RoundController(
        content: repo,
        themeId: 'animals',
        gameId: 'G01',
        difficulty: Difficulty.medium,
        struggle: {},
        performance: performance,
        saveTrial: (_) async {},
        playPrompt: (_) async {},
        introduceNewItems: true,
      );
      c.start();
      await tester.pump();
      await c.choose(c.spec!.target);
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      expect(c.spec!.choices.length, 2);
      c.dispose();
    },
  );
}
