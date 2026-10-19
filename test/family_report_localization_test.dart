import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/learning_report.dart';
import 'package:special_education_games/features/family/goal_ring.dart';
import 'package:special_education_games/features/family/item_insights.dart';
import 'package:special_education_games/features/family/progress_charts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async {
    content = await ContentRepository.load();
  });

  Future<AppState> makeState() async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Rapor', 'cat', {});
    state.dailyGoalMinutes = 10;
    return state;
  }

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

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    required String deviceLocale,
    required Size size,
    required double scale,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(deviceLocale),
        theme: segTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .where(
            (scrollable) =>
                scrollable.axisDirection == AxisDirection.down ||
                scrollable.axisDirection == AxisDirection.up,
          ),
      isEmpty,
    );
    expect(find.byType(FittedBox), findsNothing);
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
    expect(
      tester.takeException(),
      isNull,
      reason: '$size at text scale $scale',
    );
  }

  void resetView(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets('charts use profile locale and expose dates and minutes', (
    tester,
  ) async {
    await loadFonts(tester);
    final state = await makeState();
    final now = DateTime.now();
    final profileId = state.active!.id;
    state.locale = 'tr';
    await mount(
      tester,
      WeeklyCharts(
        state: state,
        report: LearningReport(const [], const [], now),
      ),
      deviceLocale: 'en',
      size: const Size(1280, 800),
      scale: 1,
    );
    expect(
      find.textContaining('İlk oyundan sonra gelişimi burada görebilirsiniz.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await state.db
        .into(state.db.gameSessions)
        .insert(
          GameSessionsCompanion.insert(
            id: 'report-session',
            profileId: profileId,
            themeId: content.themes.first.id,
            gameId: 'G01',
            difficulty: 'easy',
            startedAt: now,
            activeMs: const Value(120000),
            completed: const Value(true),
          ),
        );
    await state.db
        .into(state.db.trials)
        .insert(
          TrialsCompanion.insert(
            profileId: profileId,
            themeId: content.themes.first.id,
            gameId: 'G01',
            targetId: content.items.first.id,
            difficulty: 'easy',
            wrongCount: 0,
            maxHint: 0,
            latencyMs: 1250,
            idleMs: const Value(500),
            activeMs: const Value(2000),
            selectedIds: '[]',
            at: now,
          ),
        );
    await state.refreshTrials();
    final report = LearningReport(state.trials, state.sessions, now);
    addTearDown(state.dispose);
    addTearDown(() => resetView(tester));

    for (final (locale, deviceLocale, scales) in [
      ('en', 'tr', [1.0, 1.6, 2.0]),
      ('tr', 'en', [1.0]),
    ]) {
      state.locale = locale;
      for (final scale in scales) {
        await mount(
          tester,
          WeeklyCharts(state: state, report: report),
          deviceLocale: deviceLocale,
          size: const Size(1280, 800),
          scale: scale,
        );
        expect(
          find.text(locale == 'en' ? 'Last 7 days' : 'Son 7 gün'),
          findsOneWidget,
        );
        expect(
          find.text(
            locale == 'en'
                ? 'Progress will appear here after the first game.'
                : 'İlk oyundan sonra gelişimi burada görebilirsiniz.',
          ),
          findsNothing,
        );
        final day = report.days.last;
        final semanticsLabel =
            '${day.date.day}/${day.date.month}: 2.0 ${locale == 'en' ? 'minutes' : 'dakika'}';
        final semantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == semanticsLabel,
        );
        expect(semantics, findsOneWidget);
        expect(
          tester
              .getRect(semantics)
              .overlaps(Offset.zero & tester.view.physicalSize),
          isTrue,
        );
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('item insight empty and populated summaries use state locale', (
    tester,
  ) async {
    await loadFonts(tester);
    addTearDown(() => resetView(tester));

    for (final (locale, deviceLocale) in [('en', 'tr'), ('tr', 'en')]) {
      final state = await makeState();
      state.locale = locale;
      await mount(
        tester,
        ItemInsights(state: state),
        deviceLocale: deviceLocale,
        size: const Size(1280, 800),
        scale: 2,
      );
      expect(find.text(locale == 'en' ? 'Items' : 'Öğeler'), findsOneWidget);
      if (find
          .text(
            locale == 'en'
                ? '3 stages · latest 3 answers independent'
                : '3 aşama · son 3 yanıt bağımsız',
          )
          .evaluate()
          .isEmpty) {
        await tester.tap(
          find.text(
            locale == 'en'
                ? 'Independently answered'
                : 'Bağımsız yanıtladıkları',
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(
        find.text(
          locale == 'en'
              ? 'Items appear here after at least three observations.'
              : 'En az üç aşamanın ardından burada öğeler görünür.',
        ),
        findsOneWidget,
      );

      final now = DateTime.now();
      final profileId = state.active!.id;
      for (var index = 0; index < 3; index++) {
        await state.db
            .into(state.db.trials)
            .insert(
              TrialsCompanion.insert(
                profileId: profileId,
                themeId: content.themes.first.id,
                gameId: 'G01',
                targetId: content.items.first.id,
                difficulty: 'easy',
                wrongCount: 0,
                maxHint: 0,
                latencyMs: 1000,
                selectedIds: '[]',
                at: now.subtract(Duration(minutes: 3 - index)),
              ),
            );
      }
      await state.refreshTrials();
      await mount(
        tester,
        ItemInsights(state: state),
        deviceLocale: deviceLocale,
        size: const Size(1280, 800),
        scale: 2,
      );
      if (find
          .text(
            locale == 'en'
                ? '3 stages · latest 3 answers independent'
                : '3 aşama · son 3 yanıt bağımsız',
          )
          .evaluate()
          .isEmpty) {
        await tester.tap(
          find.text(
            locale == 'en'
                ? 'Independently answered'
                : 'Bağımsız yanıtladıkları',
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(
        find.text(
          locale == 'en'
              ? '3 stages · latest 3 answers independent'
              : '3 aşama · son 3 yanıt bağımsız',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    }
  });

  testWidgets('attention and skills summaries localize dynamic values', (
    tester,
  ) async {
    await loadFonts(tester);

    for (final (locale, deviceLocale) in [('en', 'tr'), ('tr', 'en')]) {
      final state = await makeState();
      state.locale = locale;
      final now = DateTime.now();
      final profileId = state.active!.id;
      for (var index = 0; index < 6; index++) {
        await state.db
            .into(state.db.trials)
            .insert(
              TrialsCompanion.insert(
                profileId: profileId,
                themeId: content.themes.first.id,
                gameId: 'G01',
                targetId: content.items.first.id,
                difficulty: 'easy',
                wrongCount: 0,
                maxHint: 0,
                latencyMs: 1250,
                idleMs: const Value(500),
                selectedIds: '[]',
                at: index < 3
                    ? now.subtract(Duration(days: 8, minutes: index))
                    : now.subtract(Duration(minutes: index - 2)),
              ),
            );
      }
      await state.refreshTrials();
      final report = LearningReport(state.trials, state.sessions, now);

      await mount(
        tester,
        AttentionChart(state: state, report: report),
        deviceLocale: deviceLocale,
        size: const Size(1280, 800),
        scale: 1,
      );
      expect(
        find.text(
          locale == 'en'
              ? 'Attention · daily average seconds'
              : 'Dikkat · günlük ortalama saniye',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          locale == 'en'
              ? '0–1.25 seconds. Time in the background is excluded.'
              : '0–1.25 saniye. Arka planda geçen süre dahil değildir.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.text(locale == 'en' ? 'Numeric view' : 'Sayısal görünüm'),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          locale == 'en' ? 'First response: 1.3 s' : 'İlk tepki: 1.3 sn',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await mount(
        tester,
        SkillsCard(state: state, report: report),
        deviceLocale: deviceLocale,
        size: const Size(1600, 1000),
        scale: 1,
      );
      expect(
        find.text(locale == 'en' ? 'Skill areas' : 'Beceri alanları'),
        findsOneWidget,
      );
      expect(
        find.textContaining(locale == 'en' ? '3 stages' : '3 aşama'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          locale == 'en'
              ? '0 points · compared with the previous week'
              : '0 puan · önceki haftaya göre',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    }
  });

  testWidgets('goal ring localizes typed minute and goal semantics', (
    tester,
  ) async {
    await loadFonts(tester);
    final state = await makeState();
    addTearDown(state.dispose);
    addTearDown(() => resetView(tester));

    for (final (locale, deviceLocale) in [('en', 'tr'), ('tr', 'en')]) {
      state.locale = locale;
      await mount(
        tester,
        GoalRing(state: state, minutes: 4.5),
        deviceLocale: deviceLocale,
        size: const Size(800, 360),
        scale: 2,
      );
      expect(
        tester
            .widget<Semantics>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label ==
                        (locale == 'en'
                            ? 'Today’s goal: 4.5 / 10 minutes'
                            : 'Bugünkü hedef: 4.5 / 10 dakika'),
              ),
            )
            .properties
            .label,
        locale == 'en'
            ? 'Today’s goal: 4.5 / 10 minutes'
            : 'Bugünkü hedef: 4.5 / 10 dakika',
      );
      expect(
        find.text(
          locale == 'en' ? 'Daily minute goal' : 'Günlük dakika hedefi',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });
}
