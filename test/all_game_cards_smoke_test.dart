import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/body_map_view.dart';
import 'package:special_education_games/features/game/widgets/fill_basket_view.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/features/game/widgets/scene_game_view.dart';

/// Every card in every active theme, every tier, both languages: the game
/// opens without errors, shows something to answer, and a correct answer
/// moves the round on (or Learn reaches its Finish button).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  testWidgets(
    'every game card opens and answers in every tier',
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 460);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final problems = <String>[];
      var answered = 0, learn = 0, unavailableCount = 0;
      // One premium profile for all cards (the DB stays open across games).
      final state = (await tester.runAsync(() async {
        final state = AppState(
          content,
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await state.load();
        await state.createProfile('Smoke', 'cat', {});
        state.entitlement
          ..storeActive = true
          ..lastConfirmedAt = DateTime.now();
        return state;
      }))!;
      for (final theme in content.themes) {
        for (final gameId in theme.games) {
          for (final tier in Difficulty.values) {
            for (final locale in ['tr', 'en']) {
              final tag = '${theme.id}/$gameId/${tier.name}/$locale';
              state
                ..locale = locale
                ..introduction = false
                ..hintSeconds = 0;
              state.audio.enabled = false;
              await tester.pumpWidget(
                MaterialApp(
                  theme: segTheme(),
                  home: GameScreen(
                    state: state,
                    themeId: theme.id,
                    gameId: gameId,
                    difficulty: tier,
                  ),
                ),
              );
              await tester.pump(const Duration(milliseconds: 300));
              await tester.pump(const Duration(milliseconds: 900));
              final error = tester.takeException();
              if (error != null) problems.add('$tag: $error');
              final unavailable =
                  find.textContaining('not enough').evaluate().isNotEmpty ||
                  find.textContaining('yeterli').evaluate().isNotEmpty;
              if (unavailable) {
                unavailableCount++;
              }
              if (gameId == 'G02') {
                learn++;
                if (find
                        .byKey(const ValueKey('explore-next'))
                        .evaluate()
                        .isEmpty &&
                    find
                        .byKey(const ValueKey('explore-finish'))
                        .evaluate()
                        .isEmpty) {
                  problems.add('$tag: Learn shows no navigation');
                }
              } else if (find.byType(RoundChoicesView).evaluate().isNotEmpty) {
                final view = tester.widget<RoundChoicesView>(
                  find.byType(RoundChoicesView),
                );
                if (view.spec.choices.isEmpty) problems.add('$tag: no choices');
                view.callbacks.onSelect(view.spec.target);
                await tester.pump();
                final after = tester.widget<RoundChoicesView>(
                  find.byType(RoundChoicesView),
                );
                answered++;
                if (!after.hint.celebrating) {
                  problems.add('$tag: correct answer not accepted');
                }
              } else if (find.byType(BodyMapView).evaluate().isNotEmpty) {
                final view = tester.widget<BodyMapView>(
                  find.byType(BodyMapView),
                );
                view.callbacks.onSelect(view.spec.target);
                await tester.pump();
                answered++;
                if (!tester
                    .widget<BodyMapView>(find.byType(BodyMapView))
                    .hint
                    .celebrating) {
                  problems.add('$tag: correct body place not accepted');
                }
              } else if (find.byType(SceneGameView).evaluate().isNotEmpty) {
                // The steps themselves are covered by scene_game_test.
                final view = tester.widget<SceneGameView>(
                  find.byType(SceneGameView),
                );
                if (view.spec.scene!.steps.isEmpty) {
                  problems.add('$tag: scene without steps');
                }
                view.callbacks.onSelect(view.spec.target);
                await tester.pump();
                answered++;
                if (!tester
                    .widget<SceneGameView>(find.byType(SceneGameView))
                    .hint
                    .celebrating) {
                  problems.add('$tag: finished scene not accepted');
                }
              } else if (find.byType(FillBasketView).evaluate().isNotEmpty) {
                // Covered by its own widget test.
              } else if (!unavailable) {
                problems.add('$tag: nothing to answer');
              }
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump(const Duration(seconds: 3));
            }
          }
        }
      }
      // ignore: avoid_print
      print('answered $answered learn $learn unavailable $unavailableCount');
      for (final p in problems) {
        // ignore: avoid_print
        print('PROBLEM $p');
      }
      expect(answered, greaterThan(150));
      expect(problems, isEmpty);
    },
  );
}
