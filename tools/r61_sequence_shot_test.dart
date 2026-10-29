// Run explicitly: flutter test tools/r61_sequence_shot_test.dart --update-goldens
// G35 "Next Number": the row and the choice area keep their size and place
// when a number is chosen. Shots to artifacts/claude/r61/.
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

void main() {
  testWidgets('G35 keeps its layout when a number is chosen', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
    });
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(2400, 1080);
    final state = (await tester.runAsync(() async {
      final content = await ContentRepository.load();
      final s = AppState(
        content,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      await s.createProfile('Ada', 'cat', {});
      s.audio.enabled = false;
      s.introduction = false;
      s.hintSeconds = 0;
      s.entitlement
        ..storeActive = true
        ..lastConfirmedAt = DateTime.now();
      return s;
    }))!;
    state.locale = 'en';
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: segTheme(),
          home: GameScreen(
            state: state,
            themeId: 'numbers',
            gameId: 'G35',
            difficulty: Difficulty.easy,
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/r61/g35-start.png'),
    );
    Rect at(Finder f) => tester.getRect(f.first);
    final view = tester.widget<RoundChoicesView>(find.byType(RoundChoicesView));
    final numbers = find.descendant(
      of: find.byType(SequenceRow),
      matching: find.byType(Text),
    );
    final firstBefore = at(numbers);
    final rowBefore = at(find.byType(SequenceRow));
    final choicesBefore = at(find.byType(RoundChoicesView));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/r61/g35-before.png'),
    );
    // A wrong number first: nothing moves either.
    final wrong = view.spec.choices.firstWhere(
      (x) => x.id != view.spec.target.id,
    );
    await tester.tap(
      find.byKey(ValueKey('${view.hint.generation}:${wrong.id}')).first,
    );
    for (final ms in [80, 300, 900]) {
      await tester.pump(Duration(milliseconds: ms));
      debugPrint('wrong +$ms ms: row ${at(find.byType(SequenceRow))}'
          ' choices ${at(find.byType(RoundChoicesView))}');
      expect(at(find.byType(SequenceRow)), rowBefore);
      expect(at(find.byType(RoundChoicesView)), choicesBefore);
    }
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/r61/g35-wrong.png'),
    );
    final target = view.spec.choices.firstWhere(
      (x) => x.id == view.spec.target.id,
    );
    await tester.tap(
      find.byKey(ValueKey('${view.hint.generation}:${target.id}')).first,
    );
    for (final ms in [80, 200, 600, 1000]) {
      await tester.pump(Duration(milliseconds: ms));
      debugPrint(
        'after $ms ms: first ${at(numbers)} row ${at(find.byType(SequenceRow))}'
        ' choices ${at(find.byType(RoundChoicesView))}',
      );
      expect(at(numbers), firstBefore);
      if (ms == 200) {
        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('../artifacts/claude/r61/g35-grow.png'),
        );
      }
      expect(at(find.byType(SequenceRow)), rowBefore);
      expect(at(find.byType(RoundChoicesView)), choicesBefore);
    }
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('../artifacts/claude/r61/g35-after.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 1));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    debugDefaultTargetPlatformOverride = null;
  });
}
