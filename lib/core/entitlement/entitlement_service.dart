import 'package:flutter/foundation.dart';
import '../db/app_database.dart';

/// Emulator QA only: `--dart-define=QA_PREMIUM=true` unlocks premium games in
/// debug builds. Release and profile builds ignore it (kDebugMode is false).
const _qaPremium = kDebugMode && bool.fromEnvironment('QA_PREMIUM');

class EntitlementService {
  final AppDatabase db;
  DateTime? lastConfirmedAt;
  bool storeActive = false;
  EntitlementService(this.db);
  bool activeAt(DateTime now) =>
      storeActive &&
      lastConfirmedAt != null &&
      !now.isBefore(lastConfirmedAt!) &&
      now.difference(lastConfirmedAt!) < const Duration(days: 7);
  bool get isPremium => _qaPremium || activeAt(DateTime.now());
  Future<void> load() async {
    storeActive = await db.preference('premium.active') == 'true';
    lastConfirmedAt = DateTime.tryParse(
      await db.preference('premium.lastConfirmedAt') ?? '',
    );
  }

  Future<void> confirmStoreState(bool active) async {
    storeActive = active;
    lastConfirmedAt = DateTime.now();
    await db.setPreference('premium.active', '$active');
    await db.setPreference(
      'premium.lastConfirmedAt',
      lastConfirmedAt!.toIso8601String(),
    );
  }
}
