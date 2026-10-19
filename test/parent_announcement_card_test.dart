import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/announcement_repository.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/parent_announcement_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> setup() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Local', 'cat', {});
    state.locale = 'en';
    return state;
  }

  void configure(AppState state, String? id) {
    state.configuration = AppConfiguration(
      freeGames: content.freeGames.toSet(),
      announcementId: id,
    );
  }

  Map<String, dynamic> payload(String title, {bool englishOnly = false}) => {
    'schemaVersion': 1,
    'title': {'en': title, if (!englishOnly) 'tr': 'Türkçe $title'},
    'body': {
      'en': 'A calm learning update.\nAvailable offline after loading.',
      if (!englishOnly) 'tr': 'Sakin bir öğrenme haberi.',
    },
  };

  Future<void> show(
    WidgetTester tester,
    AppState state,
    AnnouncementRepository repository,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParentAnnouncementCard(state: state, repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester, AppState state) async {
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('No announcement ID and locked parent access never fetch', (
    tester,
  ) async {
    final state = await setup();
    var calls = 0;
    final repository = AnnouncementRepository(
      state.db,
      fetcher: (_) async {
        calls++;
        return payload('Updates');
      },
    );
    configure(state, null);
    state.unlockFamily();
    await show(tester, state, repository);
    expect(calls, 0);
    state.lockFamily();
    configure(state, 'news-one');
    await show(tester, state, repository);
    expect(calls, 0);
    expect(find.text('Updates'), findsNothing);
    await dispose(tester, state);
  });

  testWidgets(
    'Unlocked exact ID loads plain text once across ordinary rebuilds',
    (tester) async {
      final state = await setup();
      final ids = <String>[];
      final repository = AnnouncementRepository(
        state.db,
        fetcher: (id) async {
          ids.add(id);
          return payload('New learning ideas');
        },
      );
      configure(state, 'news-one');
      state.unlockFamily();
      await show(tester, state, repository);
      expect(ids, ['news-one']);
      expect(find.text('New learning ideas'), findsOneWidget);
      expect(
        find.text('A calm learning update.\nAvailable offline after loading.'),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(
        find.text('A calm learning update.\nAvailable offline after loading.'),
        findsOneWidget,
      );
      state.touchFamily();
      await show(tester, state, repository);
      expect(ids, ['news-one']);
      expect(tester.takeException(), isNull);
      await dispose(tester, state);
    },
  );

  testWidgets('Changed ID and revoked parent access hide late results', (
    tester,
  ) async {
    final state = await setup();
    final first = Completer<Map<String, dynamic>?>();
    final second = Completer<Map<String, dynamic>?>();
    final ids = <String>[];
    final repository = AnnouncementRepository(
      state.db,
      fetcher: (id) {
        ids.add(id);
        return id == 'first' ? first.future : second.future;
      },
    );
    configure(state, 'first');
    state.unlockFamily();
    await show(tester, state, repository);
    expect(ids, ['first']);
    configure(state, 'second');
    state.unlockFamily();
    await tester.pumpAndSettle();
    expect(ids, ['first', 'second']);
    first.complete(payload('Stale first notice'));
    await tester.pumpAndSettle();
    expect(find.text('Stale first notice'), findsNothing);
    state.lockFamily();
    second.complete(payload('Late locked notice'));
    await tester.pumpAndSettle();
    expect(find.text('Late locked notice'), findsNothing);
    expect(find.text('News'), findsNothing);
    await dispose(tester, state);
  });

  testWidgets(
    'Missing current-language pair hides notice and changing locale reveals it without another fetch',
    (tester) async {
      final state = await setup();
      state.locale = 'tr';
      var calls = 0;
      final repository = AnnouncementRepository(
        state.db,
        fetcher: (_) async {
          calls++;
          return payload('English notice', englishOnly: true);
        },
      );
      configure(state, 'english-only');
      state.unlockFamily();
      await show(tester, state, repository);
      expect(calls, 1);
      expect(find.text('English notice'), findsNothing);
      state.locale = 'en';
      state.unlockFamily();
      await tester.pumpAndSettle();
      expect(find.text('English notice'), findsOneWidget);
      expect(calls, 1);
      await dispose(tester, state);
    },
  );

  testWidgets('Cached parent notice remains visible when refresh is offline', (
    tester,
  ) async {
    final state = await setup();
    var now = DateTime(2026, 10, 16, 10);
    var calls = 0;
    var offline = false;
    final repository = AnnouncementRepository(
      state.db,
      now: () => now,
      fetcher: (_) async {
        calls++;
        if (offline) throw StateError('Private SDK details must stay hidden');
        return payload('Cached news');
      },
    );
    await repository.refresh('cached');
    now = now.add(const Duration(hours: 7));
    offline = true;
    configure(state, 'cached');
    state.unlockFamily();
    await show(tester, state, repository);
    expect(calls, 2);
    expect(find.text('Cached news'), findsOneWidget);
    expect(find.textContaining('Private SDK'), findsNothing);
    expect(tester.takeException(), isNull);
    await dispose(tester, state);
  });
}
