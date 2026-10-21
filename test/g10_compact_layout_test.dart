import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
    'Sound-ready G10 stays readable and respects both reduced-motion flags',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadFonts(tester);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);

      for (final scenario in [
        (locale: 'tr', appReduced: true, systemDisabled: false),
        (locale: 'en', appReduced: false, systemDisabled: true),
      ]) {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final backend = _ImmediateAudioBackend();
        final state = AppState(content, db, AudioService(backend: backend));
        try {
          await state.load();
          await state.createProfile('Local test', 'cat', {});
          state.locale = scenario.locale;
          state.sound = true;
          state.audio.enabled = true;
          state.effectVolume = 60;
          state.audio.effectVolume = 60;
          state.introduction = false;
          state.hintSeconds = 0;
          state.reducedMotion = scenario.appReduced;
          state.celebration = 'full';
          // Medium and Hard cards need Premium.
          state.entitlement.lifetimeOwned = true;
          state.configuration = AppConfiguration(
            freeGames: const {'animals_G10'},
            choiceCounts: const {'easy': 2, 'medium': 4, 'hard': 4},
          );

          expect(
            state.hasRequiredGameAudio('animals', 'G10'),
            isTrue,
            reason: '${scenario.locale} fixture has localized animal audio',
          );
          expect(
            state.canPlay('animals', 'G10', Difficulty.medium),
            isTrue,
            reason: 'test-only access must not change production gating',
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: segTheme(),
              locale: Locale(scenario.locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: scenario.systemDisabled,
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
            reason: 'G10 must pass its sound-ready prompt gate',
          );
          expect(
            backend.assets.any((asset) => asset.startsWith('assets/sfx/')),
            isTrue,
          );
          final round = tester.widget<RoundChoicesView>(
            find.byType(RoundChoicesView),
          );
          expect(round.hint.locale, scenario.locale);
          expect(round.hint.visibleChoices, 4);
          expect(round.spec.choices, hasLength(4));
          expect(round.hint.animate, !scenario.appReduced);

          final viewport =
              tester.view.physicalSize / tester.view.devicePixelRatio;
          for (final item in round.spec.choices) {
            final tag = '${scenario.locale} ${item.id}';
            final card = find.byKey(
              ValueKey('${round.hint.generation}:${item.id}'),
            );
            expect(card, findsOneWidget, reason: tag);
            final rect = tester.getRect(card);
            _expectBounds(rect, viewport, tag);
            expect(rect.width, greaterThanOrEqualTo(48), reason: tag);
            expect(rect.height, greaterThanOrEqualTo(48), reason: tag);
            final label = find.text(item.name(scenario.locale));
            expect(label, findsOneWidget, reason: tag);
            expect(
              tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
              isFalse,
              reason: '$tag label must stay complete',
            );
          }
          expect(
            _verticalScrollables(tester),
            isEmpty,
            reason: scenario.locale,
          );

          final target = find.byKey(
            ValueKey('${round.hint.generation}:${round.spec.target.id}'),
          );
          await tester.tap(target);
          await tester.pump();
          final answered = tester.widget<RoundChoicesView>(
            find.byType(RoundChoicesView),
          );
          expect(answered.hint.celebrating, isTrue);
          expect(
            tester.widget<ChoiceCard>(target).state,
            ChoiceCardState.correct,
          );
          expect(
            tester
                .widget<AnimatedScale>(
                  find.descendant(
                    of: target,
                    matching: find.byType(AnimatedScale),
                  ),
                )
                .duration,
            SegMotion.tap,
            reason: 'reduced motion should select the short transition',
          );
          expect(
            find.byKey(ValueKey('full-celebration-${round.hint.generation}')),
            findsNothing,
            reason: 'reduced-motion settings suppress the full burst',
          );
          expect(tester.takeException(), isNull, reason: scenario.locale);
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
                break;
              }
              await Future<void>.delayed(const Duration(milliseconds: 20));
            }
          });
          state.lockFamily();
          state.dispose();
          await db.close();
        }
      }
    },
  );
}

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
