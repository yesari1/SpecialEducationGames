import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G10 localized compact choices fit at 2x and answer correctly', (
    tester,
  ) async {
    final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(viewport.width, greaterThan(viewport.height));
    expect(tester.view.devicePixelRatio, greaterThan(0));

    for (final locale in ['tr', 'en']) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final backend = _ImmediateAudioBackend();
      final content = await tester.runAsync(ContentRepository.load);
      expect(content, isNotNull, reason: 'production content must load');
      final state = AppState(content!, db, AudioService(backend: backend));
      try {
        await tester.runAsync(state.load);
        await tester.runAsync(
          () => state.createProfile('Local G10 test', 'cat', {}),
        );
        state.locale = locale;
        state.sound = true;
        state.audio.enabled = true;
        state.effectVolume = 60;
        state.audio.effectVolume = 60;
        state.introduction = false;
        state.hintSeconds = 0;
        state.reducedMotion = true;
        state.celebration = 'full';
        state.configuration = AppConfiguration(
          freeGames: const {'animals_G10'},
          choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
        );

        expect(
          state.hasRequiredGameAudio('animals', 'G10'),
          isTrue,
          reason: '$locale G10 has eligible production audio',
        );
        expect(
          state.canPlay('animals', 'G10', Difficulty.medium),
          isTrue,
          reason: 'test access does not replace production eligibility',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: segTheme(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: false,
              ),
              child: child!,
            ),
            home: GameScreen(
              state: state,
              themeId: 'animals',
              gameId: 'G10',
              difficulty: Difficulty.medium,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();

        expect(find.byType(GameScreen), findsOneWidget);
        expect(find.byType(RoundChoicesView), findsOneWidget);
        expect(
          backend.playCount,
          greaterThan(0),
          reason: '$locale G10 must complete its audio-gated prompt',
        );
        expect(
          backend.assets.any((asset) => asset.startsWith('assets/sfx/')),
          isTrue,
          reason: 'production G10 should play its animal sound effect',
        );

        final round = tester.widget<RoundChoicesView>(
          find.byType(RoundChoicesView),
        );
        expect(round.hint.locale, locale);
        expect(round.hint.visibleChoices, 4);
        expect(round.spec.choices, hasLength(4));
        expect(round.spec.choices.map((item) => item.id).toSet(), hasLength(4));
        expect(round.hint.animate, isFalse);

        for (final item in round.spec.choices) {
          final reason = '$locale ${item.id}';
          final card = find.byKey(
            ValueKey('${round.hint.generation}:${item.id}'),
          );
          expect(card, findsOneWidget, reason: reason);
          final rect = tester.getRect(card);
          _expectBounds(rect, viewport, reason);
          expect(rect.width, greaterThanOrEqualTo(48), reason: reason);
          expect(rect.height, greaterThanOrEqualTo(48), reason: reason);
          final label = find.text(item.name(locale));
          expect(label, findsOneWidget, reason: reason);
          expect(
            tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
            isFalse,
            reason: '$reason label must remain complete at 2x',
          );
        }
        expect(_verticalScrollables(tester), isEmpty, reason: locale);

        final target = find.byKey(
          ValueKey('${round.hint.generation}:${round.spec.target.id}'),
        );
        await tester.tap(target);
        await tester.pump();
        final answered = tester.widget<RoundChoicesView>(
          find.byType(RoundChoicesView),
        );
        expect(answered.hint.celebrating, isTrue, reason: locale);
        expect(
          tester.widget<ChoiceCard>(target).state,
          ChoiceCardState.correct,
          reason: locale,
        );
        expect(
          find.byKey(ValueKey('full-celebration-${round.hint.generation}')),
          findsNothing,
          reason: 'profile reduced-motion flag suppresses the full burst',
        );
        expect(tester.takeException(), isNull, reason: locale);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() async {
          final deadline = DateTime.now().add(const Duration(seconds: 5));
          while (DateTime.now().isBefore(deadline)) {
            final sessions = await db.select(db.gameSessions).get();
            if (sessions.isNotEmpty &&
                sessions.every((x) => x.endedAt != null)) {
              await state.refreshTrials();
              final refreshed = await db.select(db.gameSessions).get();
              if (refreshed.isNotEmpty &&
                  refreshed.every((x) => x.endedAt != null)) {
                return;
              }
            }
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          throw StateError(
            'GameScreen did not finish its session before DB close.',
          );
        });
        state.lockFamily();
        state.dispose();
        await db.close();
      }
    }
  });
}

// Completes asset requests immediately so this emulator layout test stays
// bounded. It verifies G10's audio gate/cue selection, not native playback.
class _ImmediateAudioBackend implements AudioBackend {
  final List<String> assets = [];
  int playCount = 0;

  @override
  Future<Duration?> setAsset(String asset) async {
    assets.add(asset);
    return const Duration(milliseconds: 1);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> play() async {
    playCount++;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void _expectBounds(Rect rect, Size viewport, String reason) {
  expect(rect.left, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(0), reason: reason);
  expect(rect.right, lessThanOrEqualTo(viewport.width), reason: reason);
  expect(rect.bottom, lessThanOrEqualTo(viewport.height), reason: reason);
}

Iterable<Scrollable> _verticalScrollables(WidgetTester tester) => tester
    .widgetList<Scrollable>(find.byType(Scrollable))
    .where(
      (scrollable) =>
          scrollable.axisDirection == AxisDirection.down ||
          scrollable.axisDirection == AxisDirection.up,
    );
