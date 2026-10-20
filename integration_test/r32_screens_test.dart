import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/parent_gate.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

/// Screenshots of onboarding, the parent gate and the round end on a device
/// (flutter drive with test_driver/integration_test.dart). [prefix] names the
/// build, e.g. --dart-define=SHOT_PREFIX=before.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const prefix = String.fromEnvironment('SHOT_PREFIX', defaultValue: 'r32');

  Widget app(Widget home, {String locale = 'en'}) => MaterialApp(
    theme: segTheme(),
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );

  Future<AppState> makeState(WidgetTester tester, {bool profile = true}) async {
    final content = (await tester.runAsync(ContentRepository.load))!;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final state = AppState(content, db, AudioService());
    await tester.runAsync(state.load);
    if (profile) {
      await tester.runAsync(
        () => state.createProfile('Ada', 'cat', {'ageYears': 4}),
      );
    }
    state.audio.enabled = false;
    return state;
  }

  /// Real frames for [ms], letting images decode and animations run.
  Future<void> frames(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 50) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  Future<void> orient(WidgetTester tester, DeviceOrientation o) async {
    await SystemChrome.setPreferredOrientations([o]);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('onboarding, gate and round end', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    // Onboarding (upright).
    await orient(tester, DeviceOrientation.portraitUp);
    final fresh = await makeState(tester, profile: false);
    fresh.locale = 'en';
    await tester.pumpWidget(app(OnboardingScreen(state: fresh)));
    await tester.pumpAndSettle();
    await frames(tester, 1500);
    await binding.takeScreenshot('$prefix-onboarding-1-welcome');
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pumpAndSettle();
    await frames(tester, 600);
    await binding.takeScreenshot('$prefix-onboarding-2-child');
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.pumpAndSettle();
    await frames(tester, 600);
    await binding.takeScreenshot('$prefix-onboarding-3-favorite');
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();
    await frames(tester, 600);
    await binding.takeScreenshot('$prefix-onboarding-4-known');
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();
    await frames(tester, 600);
    await binding.takeScreenshot('$prefix-onboarding-5-sound');
    await tester.pumpWidget(const SizedBox.shrink());

    // Parent gate, upright and sideways.
    final state = await makeState(tester);
    state.locale = 'en';
    for (final o in [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
    ]) {
      await orient(tester, o);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showParentGate(context, state),
                  child: const Text('Open gate'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open gate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7'));
      await tester.pump();
      await binding.takeScreenshot(
        '$prefix-gate-${o == DeviceOrientation.portraitUp ? 'upright' : 'sideways'}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }

    // Round end ("Well done"), a three-question round.
    state
      ..sound = false
      ..introduction = false
      ..hintSeconds = 0
      ..roundLength = 3;
    await tester.pumpWidget(
      app(
        GameScreen(
          state: state,
          themeId: 'animals',
          gameId: 'G01',
          difficulty: Difficulty.easy,
        ),
      ),
    );
    int? previous;
    for (var round = 0; round < 3; round++) {
      RoundChoicesView? view;
      for (var i = 0; i < 150 && view == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final found = find.byType(RoundChoicesView);
        if (found.evaluate().isEmpty) continue;
        final c = tester.widget<RoundChoicesView>(found);
        if (c.hint.generation != previous &&
            c.hint.visibleChoices == c.spec.choices.length) {
          view = c;
        }
      }
      if (view == null) fail('no round $round');
      await tester.pump(const Duration(milliseconds: 400));
      previous = view.hint.generation;
      await tester.tap(
        find.byKey(ValueKey('$previous:${view.spec.target.id}')),
      );
    }
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey('completion-summary'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await frames(tester, 1400);
    await binding.takeScreenshot('$prefix-round-end');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
