import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/config/announcement_repository.dart';
import 'package:special_education_games/core/config/parent_announcement.dart';
import 'package:special_education_games/core/db/app_database.dart';

Map<String, dynamic> notice([String title = 'News']) => {
  'schemaVersion': 1,
  'title': {'en': title, 'tr': 'Duyuru'},
  'body': {'en': 'Parent information.\nSecond line.', 'tr': 'Ebeveyn bilgisi.'},
};

void main() {
  test(
    'Malformed and missing remote notices never replace validated cache',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var time = DateTime(2026, 10, 16);
      Map<String, dynamic>? response = notice();
      var calls = 0;
      final repository = AnnouncementRepository(
        db,
        now: () => time,
        fetcher: (_) async {
          calls++;
          return response;
        },
      );
      await repository.refresh('news');
      time = time.add(const Duration(hours: 6));
      response = {...notice(), 'url': 'https://example.com'};
      expect((await repository.refresh('news'))!.localizedTitle('en'), 'News');
      await repository.refresh('news');
      expect(calls, 2);
      time = time.add(const Duration(hours: 6));
      response = null;
      expect((await repository.refresh('news'))!.localizedTitle('en'), 'News');
      expect(await repository.refresh('missing'), isNull);
      expect((await repository.load('news'))!.localizedTitle('en'), 'News');
    },
  );
  test('Strict notice schema rejects unsafe, oversized and malformed copy', () {
    final model = ParentAnnouncement.tryParse('news-1', notice())!;
    expect(model.localizedTitle('tr'), 'Duyuru');
    expect(model.localizedTitle('de'), isNull);
    expect(() => model.title['en'] = 'change', throwsUnsupportedError);
    for (final payload in [
      null,
      [],
      {...notice(), 'schemaVersion': 1.0},
      {...notice(), 'schemaVersion': 2},
      {...notice(), 'action': 'buy'},
      {...notice(), 'id': 'another'},
      {...notice()}..remove('body'),
      {
        ...notice(),
        'title': {'de': 'Title'},
      },
      {
        ...notice(),
        'title': {'en': true},
      },
      {
        ...notice(),
        'title': {'en': 'x' * 121},
      },
      {
        ...notice(),
        'body': {'en': 'x' * 1201},
      },
      {
        ...notice(),
        'title': {'en': 'line\nbreak'},
      },
      {
        ...notice(),
        'body': {'en': '<b>markup</b>'},
      },
      {
        ...notice(),
        'body': {'en': 'https://example.com'},
      },
      {
        ...notice(),
        'body': {'en': 'www.example.com'},
      },
      {
        ...notice(),
        'body': {'en': 'bad\u0000text'},
      },
      {
        ...notice(),
        'body': {'en': ' '},
      },
      {...notice(), 'title': {}},
      {
        ...notice(),
        'title': {'tr': 'Title'},
        'body': {'en': 'Body'},
      },
    ]) {
      expect(
        ParentAnnouncement.tryParse('news-1', payload),
        isNull,
        reason: '$payload',
      );
    }
    for (final id in [
      '../news',
      'news/a',
      '',
      'news_id',
      'x' * 129,
      'news\n',
    ]) {
      expect(ParentAnnouncement.tryParse(id, notice()), isNull);
    }
    final partial = ParentAnnouncement.tryParse('news', {
      ...notice(),
      'body': {'en': 'Body'},
    })!;
    expect(partial.localizedTitle('tr'), isNull);
    expect(partial.localizedBody('tr'), isNull);
    expect(partial.localizedTitle('en'), 'News');
    expect(
      ParentAnnouncement.tryParse('x', {
        ...notice(),
        'title': {'en': 'x' * 120},
        'body': {'en': 'x' * 1200},
      }),
      isNotNull,
    );
  });

  test(
    'Validated SQLite cache survives offline restart, corrupt data hides',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = AnnouncementRepository(
        db,
        fetcher: (_) async => notice(),
      );
      expect((await repository.refresh('news'))!.id, 'news');
      final offline = AnnouncementRepository(
        db,
        fetcher: (_) async => throw StateError('offline'),
      );
      expect((await offline.load('news'))!.localizedTitle('en'), 'News');
      expect((await offline.refresh('news'))!.localizedTitle('en'), 'News');
      expect(await offline.load('other'), isNull);
      for (final bad in [
        'broken',
        jsonEncode({'id': 'other', 'payload': notice()}),
        jsonEncode({
          'id': 'news',
          'payload': {...notice(), 'action': 'open'},
        }),
        jsonEncode({'id': 'news', 'payload': notice(), 'extra': true}),
        'x' * 20001,
      ]) {
        await db.setPreference('announcement:news', bad);
        expect(await offline.load('news'), isNull);
      }
    },
  );

  test(
    'Failed attempts throttle six hours per ID and handle clock rollback',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var time = DateTime(2026, 10, 16, 12);
      final calls = <String>[];
      final repository = AnnouncementRepository(
        db,
        now: () => time,
        fetcher: (id) async {
          calls.add(id);
          throw StateError('offline');
        },
      );
      expect(await repository.load('news'), isNull);
      expect(calls, isEmpty);
      await repository.refresh('news');
      await repository.refresh('news');
      await repository.refresh('new-id');
      await repository.refresh('../bad');
      expect(calls, ['news', 'new-id']);
      time = time.subtract(const Duration(days: 1));
      await repository.refresh('news');
      await repository.refresh('news');
      expect(calls.length, 2);
      time = time.add(const Duration(hours: 6));
      await repository.refresh('news');
      expect(calls, ['news', 'new-id', 'news']);
    },
  );

  test(
    'Concurrent reads coalesce and late old ID cannot replace new ID cache',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final old = Completer<Map<String, dynamic>?>();
      var calls = 0;
      final repository = AnnouncementRepository(
        db,
        fetcher: (id) async {
          calls++;
          return id == 'old' ? old.future : notice('New');
        },
      );
      final first = repository.refresh('old');
      final duplicate = repository.refresh('old');
      expect((await repository.refresh('new'))!.localizedTitle('en'), 'New');
      old.complete(notice('Old'));
      expect((await first)!.id, 'old');
      expect((await duplicate)!.id, 'old');
      expect(calls, 2);
      expect((await repository.load('new'))!.localizedTitle('en'), 'New');
      expect((await repository.load('old'))!.localizedTitle('en'), 'Old');
    },
  );
}
