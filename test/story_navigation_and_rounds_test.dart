import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/round_controller.dart';
import 'package:special_education_games/features/game/templates/game_template.dart';
import 'package:special_education_games/features/stories/story_screens.dart';

class _Audio implements AudioBackend {
  final played = <String>[];
  String? _current;
  @override
  Future<Duration?> setAsset(String asset) async {
    _current = asset;
    return const Duration(milliseconds: 10);
  }

  @override
  Future<void> play() async {
    if (_current case final c?) played.add(c);
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

const _pic = 'assets/illustrations/onboarding/opt_feelings.png';

StoryLine _say(String id) => StoryLine(
  {'tr': 'TR $id', 'en': 'EN $id'},
  {'tr': 'tr/$id.mp3', 'en': 'en/$id.mp3'},
);

final _story = Story(
  id: 'nav',
  cover: _pic,
  title: const {'tr': 'Deneme', 'en': 'Test'},
  free: true,
  pages: [
    StoryPage(image: _pic, line: _say('one')),
    StoryPage(
      line: _say('q'),
      choices: [
        const StoryChoice(image: _pic, correct: false),
        StoryChoice(image: _pic, correct: true, result: _say('yes')),
      ],
    ),
    StoryPage(image: _pic, line: _say('two')),
    StoryPage(image: _pic, line: _say('three')),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<(AppState, _Audio)> open(WidgetTester tester) async {
    final audio = _Audio();
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(backend: audio),
    );
    await state.load();
    state.locale = 'en';
    tester.view.physicalSize = const Size(915, 412);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: StoryPlayerScreen(
          state: state,
          story: _story,
          resultPause: const Duration(milliseconds: 100),
          rightPause: const Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return (state, audio);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a tap anywhere on the page goes on, and so does a swipe', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('EN one'), findsOneWidget);
    // The empty part on the right of the screen.
    await tester.tapAt(const Offset(880, 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN q'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-choice-1')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN two'), findsOneWidget);

    await tester.fling(
      find.byKey(const ValueKey('story-page-area')),
      const Offset(-300, 0),
      800,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN three'), findsOneWidget);
    await close(tester);
  });

  testWidgets('the hand shows after a while and the page then turns itself', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const ValueKey('story-hand')), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(const ValueKey('story-hand')), findsOneWidget);
    expect(find.text('EN one'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN q'), findsOneWidget);
    // A question waits for the child, however long it takes.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('EN q'), findsOneWidget);
    await close(tester);
  });

  testWidgets('the right choice is shown and said before the story goes on', (
    tester,
  ) async {
    final (_, audio) = await open(tester);
    await tester.tap(find.byKey(const ValueKey('story-next')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('story-choice-1')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN yes'), findsOneWidget);
    expect(audio.played, contains('en/yes.mp3'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN two'), findsOneWidget);
    await close(tester);
  });

  test('the feeling sound is heard before and after the question', () {
    final context = ModeContext(
      content: content,
      themeId: 'emotions',
      gameId: 'G46',
      difficulty: Difficulty.easy,
      scheduler: ItemScheduler(Random(3)),
      struggle: const {},
    );
    const template = PairTemplate();
    final spec = template.buildRound(context);
    final cues = template.introCues(spec, context, 'en');
    expect(cues, hasLength(3));
    expect(cues.first, startsWith('assets/sfx/feelings/'));
    expect(cues.last, cues.first);
    expect(cues[1], contains('/pairs/'));
  });

  group('medium and hard never ask the same thing twice', () {
    for (final tier in [Difficulty.medium, Difficulty.hard]) {
      for (final (theme, game) in [
        ('animals', 'G01'),
        ('colors', 'G40'),
        ('colors', 'G42'),
        ('shapes', 'G43'),
        ('emotions', 'G44'),
        ('emotions', 'G45'),
        ('emotions', 'G46'),
        ('body', 'G47'),
        ('body', 'G48'),
        ('body', 'G49'),
      ]) {
        test('$theme $game ${tier.name}', () {
          final controller = RoundController(
            content: content,
            themeId: theme,
            gameId: game,
            difficulty: tier,
            total: 30,
            struggle: const {},
            saveTrial: (_) async {},
            playPrompt: (_) async {},
            scheduler: ItemScheduler(Random(7)),
          );
          addTearDown(controller.dispose);
          controller.start();
          expect(controller.error, isNull);
          final asked = <String>{};
          final context = controller.modeContext;
          // The first round was built by start(); ask for the rest.
          asked.add(_key(controller.spec!));
          for (var i = 1; i < controller.total; i++) {
            final spec = controller.template.buildRound(context);
            expect(asked.add(_key(spec)), isTrue, reason: _key(spec));
          }
        });
      }
    }

    test('easy does not repeat either: the game ends when it runs out', () {
      final controller = RoundController(
        content: content,
        themeId: 'colors',
        gameId: 'G40',
        difficulty: Difficulty.easy,
        total: 40,
        struggle: const {},
        saveTrial: (_) async {},
        playPrompt: (_) async {},
        scheduler: ItemScheduler(Random(7)),
      );
      addTearDown(controller.dispose);
      controller.start();
      // Yunus, 15 November 2026: the same question never comes twice in one
      // game, on any level; a game is as long as its different questions.
      expect(controller.total, lessThan(40));
      expect(controller.total, greaterThan(1));
    });
  });
}

String _key(RoundSpec spec) =>
    '${spec.stimulus?.id ?? ''}|${spec.promptTr}|'
    '${spec.stimulus == null ? spec.target.id : ''}';
