import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/widgets/next_game_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the ring waits for the praise, then opens the next game', (
    tester,
  ) async {
    final running = ValueNotifier(false);
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NextGameButton(
              label: 'Next game',
              running: running,
              onNext: () => opened++,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(opened, 0, reason: 'not started yet');
    running.value = true;
    await tester.pump();
    await tester.pump(const Duration(seconds: 7));
    expect(opened, 0);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(opened, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 1, reason: 'opens once');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping opens the next game at once', (tester) async {
    final running = ValueNotifier(true);
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NextGameButton(
              label: 'Next game',
              running: running,
              onNext: () => opened++,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Next game'));
    expect(opened, 1);
    await tester.pump(const Duration(seconds: 9));
    expect(opened, 1);
    await tester.pumpWidget(const SizedBox());
  });

  test('next game follows where the game was opened from', () async {
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    addTearDown(state.dispose);
    await state.load();
    await state.createProfile('Ada', 'cat', {});
    final steps = state.dailyPath.steps;
    expect(steps.length, greaterThan(1));
    final first = steps.first.split('_');

    // From a theme page: the next game of that same theme, never the path.
    final fromTheme = state.nextGameRoute(first[0], first[1], Difficulty.easy);
    expect(fromTheme, startsWith('/game/${first[0]}/'));
    expect(fromTheme, isNot(contains('from=path')));
    expect(fromTheme, isNot('/game/${first[0]}/${first[1]}/easy'));
  });
}
