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
}
