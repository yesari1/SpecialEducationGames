import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/sync/firestore_summary_store.dart';
import 'package:special_education_games/core/sync/summary_export.dart';
import 'package:special_education_games/core/sync/summary_sync.dart';

final now = DateTime.utc(2026, 10, 16, 12);
DailySessionSummary summary({
  int ms = 1000,
  String theme = 'animals',
  int hour = 10,
}) => DailySessionSummary(
  date: '2026-10-16',
  themeId: theme,
  modeId: 'G01',
  difficulty: 'easy',
  activeMs: ms,
  rounds: 1,
  stages: 1,
  independent: 1,
  updatedAt: DateTime.utc(2026, 10, 16, hour),
);

class FakeStore implements SummaryStore {
  List<SummaryDocument> remote = [];
  List<DailySessionSummary> server = [];
  Completer<void>? wait;
  int reads = 0, writes = 0;
  String? scope;
  @override
  Future<List<SummaryDocument>> fetch(
    String uid,
    String profileId, {
    required bool Function() stillAuthorized,
  }) async {
    reads++;
    scope = '$uid/$profileId';
    if (wait != null) await wait!.future;
    return remote;
  }

  @override
  Future<List<DailySessionSummary>> merge(
    String uid,
    String profileId,
    List<DailySessionSummary> summaries, {
    required DateTime now,
    required bool Function() stillAuthorized,
  }) async {
    if (!stillAuthorized()) {
      throw const SummarySyncFailure(SummarySyncIssue.cancelled);
    }
    writes++;
    server = mergeDailySummaries([...server, ...summaries], now: now);
    return server;
  }
}

void main() {
  late FakeStore store;
  String? uid, profile;
  late bool parent, consent;
  late SummarySync sync;
  setUp(() {
    store = FakeStore();
    uid = 'firebase-UID_1';
    profile = '42';
    parent = true;
    consent = true;
    sync = SummarySync(
      store: store,
      currentUid: () => uid,
      currentProfileId: () => profile,
      parentAuthorized: () => parent,
      consentGiven: () => consent,
      now: () => now,
      timeout: const Duration(milliseconds: 40),
    );
  });
  Matcher failure(SummarySyncIssue issue) =>
      isA<SummarySyncFailure>().having((e) => e.issue, 'issue', issue);

  test(
    'explicit consent, parent and safe scope before any backend call',
    () async {
      expect(store.reads, 0);
      consent = false;
      await expectLater(
        sync.synchronize([]),
        throwsA(failure(SummarySyncIssue.unauthorized)),
      );
      consent = true;
      parent = false;
      await expectLater(
        sync.synchronize([]),
        throwsA(failure(SummarySyncIssue.unauthorized)),
      );
      parent = true;
      uid = null;
      await expectLater(
        sync.synchronize([]),
        throwsA(failure(SummarySyncIssue.unauthorized)),
      );
      uid = 'bad/account';
      await expectLater(
        sync.synchronize([]),
        throwsA(failure(SummarySyncIssue.invalidScope)),
      );
      uid = 'safe';
      profile = '../else';
      await expectLater(
        sync.synchronize([]),
        throwsA(failure(SummarySyncIssue.invalidScope)),
      );
      expect(store.reads, 0);
      expect(store.writes, 0);
    },
  );

  test(
    'LWW, ID matching and schema filtering; retry never adds duplicates',
    () async {
      final remote = summary(ms: 2000, hour: 11);
      store.remote = [
        SummaryDocument(remote.documentId, remote.toPayload()),
        SummaryDocument('wrong-id', summary(theme: 'produce').toPayload()),
        SummaryDocument(summary(theme: 'colors').documentId, {
          ...summary(theme: 'colors').toPayload(),
          'email': 'private',
        }),
      ];
      final result = await sync.synchronize([summary(), summary()]);
      expect(result.summaries.single.activeMs, 2000);
      expect(store.scope, 'firebase-UID_1/42');
      expect(
        result.summaries.single.toPayload().keys,
        unorderedEquals([
          'date',
          'themeId',
          'modeId',
          'difficulty',
          'activeMs',
          'rounds',
          'stages',
          'independent',
          'updatedAt',
        ]),
      );
      expect(
        (await sync.synchronize([summary()])).summaries.single.activeMs,
        2000,
      );
      // A different device updates after fetch: the transaction comparison wins.
      store.server = [summary(ms: 3000, hour: 12)];
      expect(
        (await sync.synchronize([summary()])).summaries.single.activeMs,
        3000,
      );
    },
  );

  test(
    'account/profile/consent/authorization changes discard late fetches',
    () async {
      for (final change in [
        () => uid = 'other',
        () => profile = '43',
        () => consent = false,
        () => parent = false,
        () => sync.cancel(),
      ]) {
        uid = 'firebase-UID_1';
        profile = '42';
        consent = true;
        parent = true;
        store.wait = Completer<void>();
        final pending = sync.synchronize([summary()]);
        final assertion = expectLater(
          pending,
          throwsA(failure(SummarySyncIssue.cancelled)),
        );
        change();
        store.wait!.complete();
        await assertion;
      }
      expect(store.writes, 0);
    },
  );

  test(
    'bounded wait invalidates late operation and duplicate requests',
    () async {
      store.wait = Completer<void>();
      final pending = sync.synchronize([summary()]);
      await expectLater(
        sync.synchronize([]),
        throwsA(failure(SummarySyncIssue.busy)),
      );
      await expectLater(pending, throwsA(failure(SummarySyncIssue.timeout)));
      expect(sync.busy, false);
      store.wait!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, 0);
      store.wait = null;
      expect((await sync.synchronize([summary()])).summaries, hasLength(1));
    },
  );

  test(
    'document caps reject partial or oversized backups before write',
    () async {
      store.remote = List.generate(201, (i) => SummaryDocument('$i', {}));
      await expectLater(
        sync.synchronize([]),
        throwsA(failure(SummarySyncIssue.capacity)),
      );
      expect(store.writes, 0);
      store.remote = [];
      await expectLater(
        sync.synchronize(List.generate(201, (i) => summary(theme: 'theme-$i'))),
        throwsA(failure(SummarySyncIssue.capacity)),
      );
      expect(store.reads, 1);
    },
  );

  test('SDK timestamp conversion preserves strict payload validation', () {
    final original = summary().toPayload();
    final sdk = {
      ...original,
      'updatedAt': Timestamp.fromDate(summary().updatedAt),
    };
    expect(
      DailySessionSummary.fromPayload(decodeFirestoreSummary(sdk), now: now),
      isNotNull,
    );
    expect(sdk['updatedAt'], isA<Timestamp>());
    expect(
      DailySessionSummary.fromPayload(
        decodeFirestoreSummary({...sdk, 'updatedAt': '2026-10-16'}),
        now: now,
      ),
      isNull,
    );
    expect(
      DailySessionSummary.fromPayload(
        decodeFirestoreSummary({...sdk, 'nickname': 'private'}),
        now: now,
      ),
      isNull,
    );
  });
}
