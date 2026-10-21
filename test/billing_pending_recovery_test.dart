import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/entitlement/billing_repository.dart';
import 'package:special_education_games/core/entitlement/entitlement_service.dart';

class _Store extends Fake implements InAppPurchase {}

void main() {
  late AppDatabase db;
  late BillingRepository billing;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    billing = BillingRepository(EntitlementService(db), store: _Store());
  });
  tearDown(() async {
    billing.dispose();
    await db.close();
  });

  // testWidgets runs in fake time, so the timer can be stepped.
  testWidgets('a closed purchase sheet gives the buttons back after resume', (
    tester,
  ) async {
    billing.pending = true; // The sheet was opened.
    billing.appResumed(); // Back in the app; Play sent nothing.
    await tester.pump(const Duration(seconds: 3));
    expect(billing.pending, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(billing.pending, isFalse);
  });

  testWidgets('resume without a purchase in flight changes nothing', (
    tester,
  ) async {
    billing.appResumed();
    await tester.pump(const Duration(seconds: 10));
    expect(billing.pending, isFalse);
  });
}
