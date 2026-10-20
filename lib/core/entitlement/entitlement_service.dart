import 'package:flutter/foundation.dart';
import '../db/app_database.dart';

/// Device QA only: `--dart-define=QA_PREMIUM=true` unlocks every game in
/// debug and profile test builds so all cards can be tried without a store
/// purchase. Release builds always ignore it (kReleaseMode).
const qaPremium = !kReleaseMode && bool.fromEnvironment('QA_PREMIUM');

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
  bool get isPremium => qaPremium || activeAt(DateTime.now());
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
