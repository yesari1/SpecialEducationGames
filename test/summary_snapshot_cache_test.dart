import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/sync/summary_export.dart';
import 'package:special_education_games/core/sync/summary_snapshot_cache.dart';

void main() {
  late AppDatabase db;
  late DateTime at;
  late SummarySnapshotCache cache;
  DailySessionSummary sample({String theme = 'animals', DateTime? updated}) =>
      DailySessionSummary(
        date: '2026-10-16',
        themeId: theme,
        modeId: 'G01',
        difficulty: 'easy',
        activeMs: 1000,
        rounds: 1,
        stages: 2,
        independent: 1,
        updatedAt: updated ?? at,
      );
  Future<String> storedKey() async =>
      (await db.select(db.preferences).get()).single.key;
  Future<Map<String, dynamic>> stored() async =>
      jsonDecode((await db.select(db.preferences).get()).single.value)
          as Map<String, dynamic>;
  Future<void> corrupt(Object payload) async => db.setPreference(
    await storedKey(),
    payload is String ? payload : jsonEncode(payload),
  );
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    at = DateTime.utc(2026, 10, 16, 12);
    cache = SummarySnapshotCache(db, now: () => at);
  });
  tearDown(() => db.close());

  test(
    'Reload is immutable, isolated by account/profile, and stores only scoped aggregates',
    () async {
      await db.setPreference('unrelated', 'keep');
      final input = [sample()];
      await cache.save('uid_one', '123', input);
      input.clear();
      final restarted = SummarySnapshotCache(db, now: () => at);
      final snapshot = (await restarted.load('uid_one', '123'))!;
      expect(snapshot.savedAt, at);
      expect(snapshot.summaries.single.activeMs, 1000);
      expect(() => snapshot.summaries.clear(), throwsUnsupportedError);
      expect(await restarted.load('uid_two', '123'), isNull);
      expect(await restarted.load('uid_one', '456'), isNull);
      final rows = await db.select(db.preferences).get();
      final imported = rows.singleWhere((row) => row.key != 'unrelated');
      expect(
        imported.key,
        matches(RegExp(r'^sync\.imported\.v2\.[a-f0-9]{64}\.[a-f0-9]{64}$')),
      );
      expect(imported.value, isNot(contains('uid_one')));
      expect(imported.value, isNot(contains('123')));
      expect(await db.select(db.profiles).get(), isEmpty);
      expect(await db.select(db.trials).get(), isEmpty);
      expect(await db.select(db.gameSessions).get(), isEmpty);
    },
  );

  test(
    'Serialized writes are idempotent and revocation clear wins over pending saves',
    () async {
      await Future.wait(
        List.generate(8, (_) => cache.save('uid', 'p', [sample()])),
      );
      expect((await cache.load('uid', 'p'))!.summaries, hasLength(1));
      await cache.save('other', 'p', [sample()]);
      final pending = cache.save('uid', 'p', [sample()]);
      final clear = SummarySnapshotCache(db, now: () => at).clear('uid', 'p');
      await Future.wait([pending, clear]);
      expect(await cache.load('uid', 'p'), isNull);
      expect(await cache.load('other', 'p'), isNotNull);
      await cache.clear('uid', 'p');
    },
  );

  test('Invalid scopes never escape the cache namespace', () async {
    for (final scope in [
      ('uid/x', 'p'),
      ('uid', '../p'),
      ('uid', 'under_score'),
      ('', 'p'),
    ]) {
      expect(await cache.load(scope.$1, scope.$2), isNull);
      await expectLater(
        cache.save(scope.$1, scope.$2, []),
        throwsArgumentError,
      );
      await expectLater(cache.clear(scope.$1, scope.$2), throwsArgumentError);
    }
    expect(await db.select(db.preferences).get(), isEmpty);
    await cache.save('uid', 'p', []);
    expect((await cache.load('uid', 'p'))!.summaries, isEmpty);
  });

  test(
    'Profile deletion clears every account copy and preserves other profiles and preferences',
    () async {
      await db.setPreference('profile.p.keep', 'local-setting');
      await cache.save('first', 'p', [sample()]);
      await cache.save('second', 'p', [sample()]);
      await cache.save('first', 'p-other', [sample()]);
      final pending = cache.save('third', 'p', [sample()]);
      final clear = SummarySnapshotCache(db, now: () => at).clearProfile('p');
      await Future.wait([pending, clear]);
      for (final uid in ['first', 'second', 'third']) {
        expect(await cache.load(uid, 'p'), isNull);
      }
      expect(await cache.load('first', 'p-other'), isNotNull);
      expect(await db.preference('profile.p.keep'), 'local-setting');
      await expectLater(cache.clearProfile('p%'), throwsArgumentError);
      await expectLater(cache.clearProfile('p_'), throwsArgumentError);
      expect(await cache.load('first', 'p-other'), isNotNull);
      await cache.clearProfile('p');
    },
  );

  test(
    'Account deletion clears every profile copy and preserves other accounts',
    () async {
      await db.setPreference('unrelated', 'keep');
      await cache.save('uid_one', 'p', [sample()]);
      await cache.save('uid_one', 'p-other', [sample()]);
      await cache.save('uid_two', 'p', [sample()]);
      final pending = cache.save('uid_one', 'pending', [sample()]);
      final clear = SummarySnapshotCache(
        db,
        now: () => at,
      ).clearAccount('uid_one');
      await Future.wait([pending, clear]);
      for (final profile in ['p', 'p-other', 'pending']) {
        expect(await cache.load('uid_one', profile), isNull);
      }
      expect(await cache.load('uid_two', 'p'), isNotNull);
      expect(await db.preference('unrelated'), 'keep');
      await expectLater(cache.clearAccount('uid%'), throwsArgumentError);
      expect(await cache.load('uid_two', 'p'), isNotNull);
      await cache.clearAccount('uid_one');
    },
  );

  test(
    'Malformed, future, rollback, schema and invalid summary records fail closed',
    () async {
      await cache.save('uid', 'p', [sample()]);
      final valid = await stored();
      final variants = <Object>[
        '{broken',
        [],
        {...valid, 'version': 2},
        {...valid, 'version': 1.0},
        {...valid, 'extra': true},
        {...valid, 'savedAt': '2026-02-30T12:00:00.000Z'},
        {
          ...valid,
          'savedAt': at.add(const Duration(seconds: 1)).toIso8601String(),
        },
        {...valid, 'summaries': 'not-a-list'},
      ];
      for (final field in ['activeMs', 'updatedAt', 'themeId', 'independent']) {
        final doc = Map<String, dynamic>.from(
          (valid['summaries'] as List).single as Map,
        );
        doc[field] = switch (field) {
          'activeMs' => 1.5,
          'updatedAt' => at.millisecondsSinceEpoch,
          'themeId' => 'bad/slash',
          _ => 99,
        };
        variants.add({
          ...valid,
          'summaries': [doc],
        });
      }
      final futureDoc = Map<String, dynamic>.from(
        (valid['summaries'] as List).single as Map,
      )..['updatedAt'] = at.add(const Duration(seconds: 1)).toIso8601String();
      variants.add({
        ...valid,
        'summaries': [futureDoc],
      });
      for (final variant in variants) {
        await corrupt(variant);
        expect(await cache.load('uid', 'p'), isNull, reason: '$variant');
      }
      await corrupt(valid);
      at = at.subtract(const Duration(seconds: 1));
      expect(await cache.load('uid', 'p'), isNull);
    },
  );

  test(
    'Capacity, duplicate IDs, and invalid saves preserve prior snapshot',
    () async {
      await cache.save('uid', 'p', [sample()]);
      final valid = await stored();
      final doc = (valid['summaries'] as List).single;
      for (final payload in [
        {
          ...valid,
          'summaries': [doc, doc],
        },
        {...valid, 'summaries': List.filled(201, doc)},
        {
          ...valid,
          'summaries': [
            {...(doc as Map), 'themeId': 'a' * 5000},
          ],
        },
        ' ' * (SummarySnapshotCache.maxBytes + 1),
      ]) {
        await corrupt(payload);
        expect(await cache.load('uid', 'p'), isNull);
      }
      await corrupt(valid);
      for (final summaries in [
        [sample(), sample()],
        List.filled(201, sample()),
        [sample(theme: 'a' * 5000)],
        [sample(updated: at.add(const Duration(seconds: 1)))],
      ]) {
        await expectLater(
          cache.save('uid', 'p', summaries),
          throwsArgumentError,
        );
        expect((await cache.load('uid', 'p'))!.summaries.single.activeMs, 1000);
      }
    },
  );
}
