import 'dart:ui' show Tristate;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
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
    'localized answer choices expose enabled state and 48px targets at 2x landscape',
    (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadFonts(tester);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);

      for (final locale in ['tr', 'en']) {
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
        state.configuration = AppConfiguration(
          freeGames: content.freeGames.toSet(),
          fadeAfterErrors: 1,
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
              themeId: 'animals',
              gameId: 'G01',
              difficulty: Difficulty.easy,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));

        final choices = tester.widget<RoundChoicesView>(
          find.byType(RoundChoicesView),
        );
        expect(choices.hint.locale, locale);
        expect(choices.spec.choices, hasLength(greaterThanOrEqualTo(2)));
        expect(
          choices.spec.choices.map((item) => item.name(locale)).toSet().length,
          choices.spec.choices.length,
          reason: '$locale choices need distinct spoken labels for this check',
        );
        expect(choices.hint.visibleChoices, choices.spec.choices.length);

        Finder cardFor(String itemId, int generation) =>
            find.byKey(ValueKey('$generation:$itemId'));

        SemanticsData dataFor(String label) => tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();

        final generation = choices.hint.generation;
        for (final item in choices.spec.choices) {
          final card = cardFor(item.id, generation);
          expect(find.text(item.name(locale)), findsOneWidget);
          expect(dataFor(item.name(locale)).label, item.name(locale));
          expect(dataFor(item.name(locale)).flagsCollection.isButton, isTrue);
          expect(
            dataFor(item.name(locale)).flagsCollection.isEnabled,
            Tristate.isTrue,
          );
          expect(
            dataFor(item.name(locale)).hasAction(SemanticsAction.tap),
            isTrue,
          );
          final rect = tester.getRect(card);
          expect(
            rect.width,
            greaterThanOrEqualTo(48),
            reason: '$locale ${item.id} width',
          );
          expect(
            rect.height,
            greaterThanOrEqualTo(48),
            reason: '$locale ${item.id} height',
          );
        }

        final wrong = choices.spec.choices.firstWhere(
          (item) => item.id != choices.spec.target.id,
        );
        final target = choices.spec.target;
        await tester.tap(cardFor(wrong.id, generation));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));

        final updated = tester.widget<RoundChoicesView>(
          find.byType(RoundChoicesView),
        );
        expect(updated.hint.wrongCount, 1);
        expect(updated.hint.level, 4);
        final wrongData = dataFor(wrong.name(locale));
        final targetData = dataFor(target.name(locale));
        expect(wrongData.label, wrong.name(locale));
        expect(wrongData.flagsCollection.isButton, isTrue);
        expect(wrongData.flagsCollection.isEnabled, Tristate.isFalse);
        expect(wrongData.hasAction(SemanticsAction.tap), isFalse);
        expect(targetData.label, target.name(locale));
        expect(targetData.flagsCollection.isEnabled, Tristate.isTrue);
        expect(targetData.hasAction(SemanticsAction.tap), isTrue);

        // Exercise the same action a screen reader invokes, rather than only
        // checking that the node advertises a tap action.
        final targetNode = tester.getSemantics(
          find.bySemanticsLabel(target.name(locale)),
        );
        targetNode.owner!.performAction(targetNode.id, SemanticsAction.tap);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final celebrating = tester.widget<RoundChoicesView>(
          find.byType(RoundChoicesView),
        );
        expect(celebrating.hint.celebrating, isTrue);
        expect(find.bySemanticsLabel(target.name(locale)), findsOneWidget);
        for (final item in celebrating.spec.choices.where(
          (item) => item.id != target.id,
        )) {
          expect(
            tester.widget<ChoiceCard>(cardFor(item.id, generation)).state,
            ChoiceCardState.dismissed,
          );
          expect(
            find.semantics.byLabel(item.name(locale)),
            findsNothing,
            reason: '$locale dismissed choice ${item.id} must leave semantics',
          );
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale 800x360 scale 2',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        state.dispose();
        await state.db.close();
      }
      semantics.dispose();
    },
  );
}
