import '../db/app_database.dart';

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
  bool get isPremium => activeAt(DateTime.now());
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
