import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/entitlement/entitlement_service.dart';

void main() {
  test(
    'Premium cache expires after seven days and fails closed on clock rollback',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final service = EntitlementService(db);
      await service.load();
      expect(service.isPremium, false);
      await service.confirmStoreState(true);
      final at = service.lastConfirmedAt!;
      expect(service.activeAt(at.add(const Duration(days: 6))), true);
      expect(service.activeAt(at.add(const Duration(days: 7))), false);
      expect(service.activeAt(at.subtract(const Duration(seconds: 1))), false);
      final restored = EntitlementService(db);
      await restored.load();
      expect(restored.storeActive, true);
      await restored.confirmStoreState(false);
      expect(restored.isPremium, false);
      await db.close();
    },
  );
}
