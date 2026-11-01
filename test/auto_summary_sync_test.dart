import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/sync/summary_export.dart';
import 'package:special_education_games/core/sync/summary_sync.dart';

class _Store implements SummaryStore {
  final merged = <String, List<DailySessionSummary>>{};
  bool offline = false;
  @override
  Future<List<SummaryDocument>> fetch(
    String uid,
    String profileId, {
    required bool Function() stillAuthorized,
  }) async {
    if (offline) throw StateError('offline');
    return const [];
  }

  @override
  Future<List<DailySessionSummary>> merge(
    String uid,
    String profileId,
    List<DailySessionSummary> summaries, {
    required DateTime now,
    required bool Function() stillAuthorized,
  }) async {
    merged['$uid/$profileId'] = summaries;
    return summaries;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<(AppState, _Store, List<String?>)> setup() async {
    final store = _Store();
    final uid = <String?>['parent-1'];
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
      summaryStore: store,
      signedInUid: () => uid.first,
    );
    await state.load();
    await state.createProfile('Ada', 'cat', {});
    final id = await state.beginSession('animals', 'G01', Difficulty.easy);
    // Active time can never exceed the wall-clock length of the session.
    await state.finishSession(id, 0, true);
    state.autoSync.cancel(); // the test drives run() itself
    return (state, store, uid);
  }

  test('signed-in parent: daily summary is sent automatically', () async {
    final (state, store, _) = await setup();
    addTearDown(state.dispose);
    expect(state.cloudSync, isTrue, reason: 'default on');
    await state.autoSync.run();
    final sent = store.merged['parent-1/${state.active!.id}'];
    expect(sent, isNotNull);
    expect(sent!.single.themeId, 'animals');
    expect(sent.single.modeId, 'G01');
    expect(sent.single.rounds, 1);
  });

  test('nothing is sent when signed out or switched off', () async {
    final (state, store, uid) = await setup();
    addTearDown(state.dispose);
    uid[0] = null;
    await state.autoSync.run();
    expect(store.merged, isEmpty);
    uid[0] = 'parent-1';
    await expectLater(state.setting('cloudSync', 'false'), throwsStateError);
    state.unlockFamily();
    await state.setting('cloudSync', 'false');
    expect(state.cloudSync, isFalse);
    await state.autoSync.run();
    expect(store.merged, isEmpty);
    await state.setting('cloudSync', 'true');
    await state.autoSync.run();
    expect(store.merged, isNotEmpty);
  });

  test('offline is quiet and retried later', () async {
    final (state, store, _) = await setup();
    addTearDown(state.dispose);
    store.offline = true;
    await state.autoSync.run();
    expect(state.autoSync.lastIssue, SummarySyncIssue.unavailable);
    store.offline = false;
    await state.autoSync.run();
    expect(state.autoSync.lastIssue, isNull);
    expect(store.merged, isNotEmpty);
  });

  test('leaving the app mid-game sends the time played so far', () async {
    final (state, store, _) = await setup();
    addTearDown(state.dispose);
    final id = await state.beginSession('colors', 'G02', Difficulty.easy);
    // Stored times are whole seconds; let a full second pass.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await state.checkpointSession(id, 20);
    await state.suspendSession(id, 30);
    // Sent right away, without the usual debounce.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final sent = store.merged['parent-1/${state.active!.id}']!;
    final colors = sent.singleWhere((s) => s.themeId == 'colors');
    expect(colors.activeMs, 30);
    expect(colors.rounds, 0);
    // Coming back reopens the round; finishing it counts it in full.
    await state.resumeSession(id);
    await state.checkpointSession(id, 35);
    await state.finishSession(id, 40, true);
    final row = state.sessions.singleWhere((s) => s.id == id);
    expect(row.activeMs, 40);
    expect(row.completed, isTrue);
  });

  test('a game the app was killed in ends at its last checkpoint', () async {
    final (state, _, _) = await setup();
    addTearDown(state.dispose);
    // Session ids are clock based; keep them apart from the setup's.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final id = await state.beginSession('colors', 'G02', Difficulty.easy);
    await state.checkpointSession(id, 25);
    await state.load();
    final row = state.sessions.singleWhere((s) => s.id == id);
    expect(row.activeMs, 25);
    expect(row.endedAt, row.startedAt.add(const Duration(seconds: 1)));
  });
}
