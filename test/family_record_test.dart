import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/sync/family_record.dart';

class _FakeRecords implements FamilyRecordStore {
  final calls = <Map<String, Object?>>[];
  bool fail = false;
  String? stored;
  @override
  Future<String?> plan(String uid) async => stored;
  @override
  Future<void> record({
    required String uid,
    required String locale,
    String? email,
    String? appVersion,
    String? plan,
    String? fcmToken,
  }) async {
    if (fail) throw StateError('offline');
    calls.add({'uid': uid, 'locale': locale, 'email': email, 'plan': plan});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('sign-in records the family with locale and account e-mail', () async {
    final records = _FakeRecords();
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
      familyRecords: records,
    );
    addTearDown(state.dispose);
    await state.load();
    state.locale = 'tr';
    await state.recordFamily('parent-1', 'parent@example.org');
    expect(records.calls.single, {
      'uid': 'parent-1',
      'locale': 'tr',
      'email': 'parent@example.org',
      'plan': 'free',
    });
    // Failures are swallowed: sign-in must never break because of it.
    records.fail = true;
    await state.recordFamily('parent-1', null);
    expect(records.calls, hasLength(1));
  });

  test('a subscription bought on another device keeps its plan', () async {
    final records = _FakeRecords()..stored = 'yearly';
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
      familyRecords: records,
    );
    addTearDown(state.dispose);
    await state.load();
    await state.entitlement.confirmStoreState(true);
    expect(state.entitlement.planName, 'monthly');
    await state.syncPlan('parent-1');
    expect(state.entitlement.planName, 'yearly');
    await state.recordFamily('parent-1', null);
    expect(records.calls.last['plan'], 'yearly');
  });
}
