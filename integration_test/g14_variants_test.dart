import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in const ['tr', 'en']) {
    testWidgets('G14 Hard shows two fish photos in $locale at 2x text', (
      tester,
    ) async {
      final fixture = await _openHardGame(tester, locale);
      addTearDown(() => _closeGame(tester, fixture));

      final viewport = fixture.viewport;
      expect(viewport.width, greaterThan(viewport.height));
      expect(tester.view.devicePixelRatio, greaterThan(0));
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(RoundChoicesView), findsOneWidget);

      final round = tester.widget<RoundChoicesView>(
        find.byType(RoundChoicesView),
      );
      expect(round.hint.locale, locale);
      expect(round.spec.target.id, 'animals.fish');
      expect(round.spec.target.verifiedPhotoPaths, hasLength(2));
      expect(round.spec.choices, hasLength(4));
      expect(
        round.spec.choices.where((item) => item.id == round.spec.target.id),
        hasLength(1),
      );
      final promptPath = round.spec.promptImagePath;
      final answerPath = round.spec.correctChoiceImagePath;
      expect(promptPath, isNotNull);
      expect(answerPath, isNotNull);
      expect(promptPath, isNot(answerPath));
      expect(round.spec.target.verifiedPhotoPaths, contains(promptPath));
      expect(round.spec.target.verifiedPhotoPaths, contains(answerPath));

      final renderedPhotos = tester.widgetList<PhotoVisual>(
        find.byType(PhotoVisual),
      );
      expect(
        renderedPhotos.map((photo) => photo.asset).toList(),
        containsAllInOrder([promptPath, answerPath]),
      );

      final prompt = find.text(
        locale == 'tr' ? round.spec.promptTr : round.spec.promptEn,
      );
      expect(prompt, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(prompt).didExceedMaxLines,
        isFalse,
      );
      expect(round.spec.promptTr, 'Aynısını bul');
      expect(round.spec.promptEn, 'Find the match');

      final ids = round.spec.choices.map((item) => item.id).toSet();
      expect(ids, hasLength(4));
      final targetCard = find.byKey(
        ValueKey('${round.hint.generation}:${round.spec.target.id}'),
      );
      for (final item in round.spec.choices) {
        final card = find.byKey(
          ValueKey('${round.hint.generation}:${item.id}'),
        );
        expect(card, findsOneWidget, reason: item.id);
        final rect = tester.getRect(card);
        _expectBounds(rect, viewport, item.id);
        expect(rect.width, greaterThanOrEqualTo(48), reason: item.id);
        expect(rect.height, greaterThanOrEqualTo(48), reason: item.id);
        final label = find.text(item.name(locale));
        expect(label, findsOneWidget, reason: item.id);
        expect(
          tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
          isFalse,
          reason: item.id,
        );
      }
      expect(_verticalScrollables(tester), isEmpty);
      expect(tester.takeException(), isNull);

      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('seg-g14-hard-$locale-variants');

      await tester.tap(targetCard);
      await tester.pump();
      final answered = tester.widget<RoundChoicesView>(
        find.byType(RoundChoicesView),
      );
      expect(answered.hint.celebrating, isTrue);
      expect(
        tester.widget<ChoiceCard>(targetCard).state,
        ChoiceCardState.correct,
      );
      expect(_verticalScrollables(tester), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}

class _GameFixture {
  final AppState state;
  final AppDatabase db;
  final Size viewport;

  const _GameFixture(this.state, this.db, this.viewport);
}

Future<_GameFixture> _openHardGame(WidgetTester tester, String locale) async {
  final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final content = await tester.runAsync(ContentRepository.load);
  expect(content, isNotNull, reason: 'production content bundle loads');
  final state = AppState(content!, db, AudioService());
  await tester.runAsync(state.load);
  await tester.runAsync(() => state.createProfile('Local test', 'cat', {}));
  state.locale = locale;
  state.sound = false;
  state.audio.enabled = false;
  state.introduction = false;
  state.hintSeconds = 0;
  state.difficultyOverride = 'hard';
  state.configuration = AppConfiguration(
    freeGames: const {'animals_G14'},
    choiceCounts: const {'easy': 2, 'medium': 3, 'hard': 4},
  );
  // GameScreen's normal parent/settings test seam: a local, in-memory premium
  // entitlement. This does not call billing or change production free-tier
  // policy; hard difficulty is intentionally not granted by `freeGames`.
  state.entitlement
    ..storeActive = true
    ..lastConfirmedAt = DateTime.now();
  expect(state.entitlement.isPremium, isTrue);
  expect(
    state.canPlay('animals', 'G14', Difficulty.hard),
    isTrue,
    reason: 'this test grants local access to G14 only',
  );
  expect(state.content.hasG14HardVariants('animals'), isTrue);
  final fish = state.content.items.singleWhere(
    (item) => item.id == 'animals.fish',
  );
  expect(fish.verifiedPhotoPaths, hasLength(2));

  await tester.pumpWidget(
    MaterialApp(
      theme: segTheme(),
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: GameScreen(
        state: state,
        themeId: 'animals',
        gameId: 'G14',
        difficulty: Difficulty.hard,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  return _GameFixture(state, db, viewport);
}

Future<void> _closeGame(WidgetTester tester, _GameFixture fixture) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final sessions = await fixture.db.select(fixture.db.gameSessions).get();
      if (sessions.isNotEmpty &&
          sessions.every((session) => session.endedAt != null)) {
        await fixture.state.refreshTrials();
        final refreshed = await fixture.db
            .select(fixture.db.gameSessions)
            .get();
        if (refreshed.isNotEmpty &&
            refreshed.every((session) => session.endedAt != null)) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('GameScreen did not finish its session before DB close.');
  });
  fixture.state.lockFamily();
  fixture.state.dispose();
  await fixture.db.close();
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
