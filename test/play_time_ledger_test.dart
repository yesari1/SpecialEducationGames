import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/play_time_ledger.dart';

void main() {
  test(
    'Concurrent active ticks persist without loss; profiles and extensions are isolated',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var at = DateTime(2026, 10, 16, 10);
      final ledger = PlayTimeLedger(db, now: () => at);
      expect((await ledger.load('one', seedMs: 5000)).usedMs, 5000);
      await Future.wait(List.generate(20, (_) => ledger.charge('one', 1000)));
      expect((await ledger.load('one', seedMs: 99999)).usedMs, 25000);
      expect((await ledger.load('two')).usedMs, 0);
      final extended = await ledger.extend('one', 10);
      expect(extended.remainingMs(10), 1200000 - 25000);
      final restarted = PlayTimeLedger(db, now: () => at);
      expect((await restarted.load('one')).extraMs, 600000);
      expect((await restarted.load('two')).extraMs, 0);
      at = DateTime(2026, 10, 17, 10);
      expect((await restarted.load('one')).usedMs, 0);
      expect((await restarted.load('one')).extraMs, 0);
    },
  );
  test(
    'A midnight-spanning active interval is split across local days',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var at = DateTime(2026, 10, 17, 0, 0, 2);
      final ledger = PlayTimeLedger(db, now: () => at);
      expect((await ledger.charge('one', 5000)).usedMs, 2000);
      at = DateTime(2026, 10, 16, 23, 59, 59);
      expect((await ledger.load('one')).usedMs, 3000);
      expect(const DailyPlayTime(usedMs: 600000).remainingMs(10), 0);
      expect(const DailyPlayTime(usedMs: 999999).remainingMs(0), -1);
      expect(() => ledger.charge('one', -1), throwsArgumentError);
    },
  );
}
