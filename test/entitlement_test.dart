import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/entitlement/entitlement_service.dart';

void main() {
  test(
    'Premium cache expires after three offline days and fails closed on clock rollback',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final service = EntitlementService(db);
      await service.load();
      expect(service.isPremium, false);
      await service.confirmStoreState(true);
      final at = service.lastConfirmedAt!;
      expect(service.activeAt(at.add(const Duration(days: 2))), true);
      expect(service.activeAt(at.add(const Duration(days: 3))), false);
      expect(service.activeAt(at.subtract(const Duration(seconds: 1))), false);
      final restored = EntitlementService(db);
      await restored.load();
      expect(restored.storeActive, true);
      await restored.confirmStoreState(false);
      expect(restored.isPremium, false);
      await db.close();
    },
  );

  test('offline grant expires after three days; a clock set back voids '
      'time-limited access until an online check', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    var clock = DateTime(2026, 10, 23, 12);
    final service = EntitlementService(db, now: () => clock);
    await service.load();
    await service.setGrant('p1', premium: true, endTrial: false);
    await service.setTrial('p1', clock);
    expect(service.grantActive, isTrue);
    clock = clock.add(const Duration(days: 2));
    expect(service.grantActive, isTrue);
    clock = clock.add(const Duration(days: 2));
    expect(service.grantActive, isFalse, reason: 'four days offline');

    // Clock moved back two days: trial and grant are off after a restart.
    await service.noteClock();
    clock = clock.subtract(const Duration(days: 2));
    final restarted = EntitlementService(db, now: () => clock);
    await restarted.load();
    expect(restarted.clockSetBack, isTrue);
    expect(restarted.trialActive, isFalse);
    // An online answer trusts the clock again.
    await restarted.setTrial('p1', DateTime(2026, 10, 23, 12));
    expect(restarted.clockSetBack, isFalse);
    expect(restarted.trialActive, isTrue);
    await db.close();
  });
}
