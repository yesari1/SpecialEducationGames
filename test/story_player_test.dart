import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/stories/story_screens.dart';

/// Records what is narrated; every clip ends at once.
class RecordingAudio implements AudioBackend {
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

const pic = 'assets/illustrations/onboarding/opt_feelings.png';

StoryLine say(String id) => StoryLine(
  {'tr': 'TR $id', 'en': 'EN $id'},
  {'tr': 'tr/$id.mp3', 'en': 'en/$id.mp3'},
);

final testStory = Story(
  id: 'test',
  cover: pic,
  title: const {'tr': 'Deneme', 'en': 'Test'},
  free: true,
  praise: say('praise'),
  pages: [
    StoryPage(image: pic, line: say('p1')),
    StoryPage(
      line: say('q'),
      retry: say('retry'),
      choices: [
        StoryChoice(image: pic, correct: false, result: say('oops')),
        const StoryChoice(image: pic, correct: true),
      ],
    ),
    StoryPage(image: pic, line: say('p3')),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<(AppState, RecordingAudio)> setUpState(WidgetTester tester) async {
    final audio = RecordingAudio();
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(backend: audio),
    );
    await state.load();
    state.locale = 'en';
    return (state, audio);
  }

  Future<void> open(WidgetTester tester, AppState state) async {
    tester.view.physicalSize = const Size(915, 412);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: StoryPlayerScreen(
          state: state,
          story: testStory,
          resultPause: const Duration(milliseconds: 100),
          rightPause: const Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('pages narrate, a wrong choice shows its result and asks again, '
      'the right one goes on to the end', (tester) async {
    final (state, audio) = await setUpState(tester);
    await open(tester, state);
    expect(find.text('EN p1'), findsOneWidget);
    expect(audio.played, contains('en/p1.mp3'));

    await tester.tap(find.byKey(const ValueKey('story-next')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN q'), findsOneWidget);

    // Wrong: calm result, no scolding, then the retry question.
    await tester.tap(find.byKey(const ValueKey('story-choice-0')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN oops'), findsOneWidget);
    expect(audio.played, contains('en/oops.mp3'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN retry'), findsOneWidget);
    expect(audio.played.last, 'en/retry.mp3');

    // The tried picture no longer answers.
    await tester.tap(find.byKey(const ValueKey('story-choice-0')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN retry'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-choice-1')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN p3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-next')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('story-end')), findsOneWidget);
    expect(find.text('EN praise'), findsOneWidget);
    expect(audio.played.last, 'en/praise.mp3');

    // Again starts from the first page.
    await tester.tap(find.byKey(const ValueKey('story-again')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('EN p1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('every page fits a small landscape phone without overflow', (
    tester,
  ) async {
    final (state, _) = await setUpState(tester);
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: StoryPlayerScreen(state: state, story: testStory),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('story-next')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('story-choice-0')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('a story needs one right choice per question', () {
    expect(
      () => Story.fromJson({
        'id': 'bad',
        'cover': pic,
        'title': {'tr': 'x'},
        'pages': [
          {
            'line': {
              'text': {'tr': 'q'},
            },
            'choices': [
              {'image': pic},
              {'image': pic},
            ],
          },
        ],
      }),
      throwsFormatException,
    );
  });

  test('the story catalog loads and every free story has its files', () async {
    final content = await ContentRepository.load();
    final catalog =
        jsonDecode(File('assets/content/stories.json').readAsStringSync())
            as List;
    expect(content.stories.length, catalog.length);
    for (final story in content.stories) {
      for (final page in story.pages) {
        expect(page.line.text.keys, containsAll(['tr', 'en']));
      }
      final missing = story.assets.where((a) => !File(a).existsSync());
      expect(missing, isEmpty, reason: 'story ${story.id} is missing files');
    }
  });
}
