import 'package:flutter/foundation.dart';
import '../db/app_database.dart';

/// Device QA only: `--dart-define=QA_PREMIUM=true` unlocks every game in
/// debug and profile test builds so all cards can be tried without a store
/// purchase. Release builds always ignore it (kReleaseMode).
const qaPremium = !kReleaseMode && bool.fromEnvironment('QA_PREMIUM');

/// Why every game is open right now.
enum PremiumSource { none, qa, subscription, lifetime, trial, granted }

/// Access is read on the device: Google Play ownership (subscription or the
/// one-time lifetime product) and the one free trial per Google account,
/// whose start date the server keeps (see TrialStore). When the trial ends
/// the profile is simply back on the free games.
class EntitlementService {
  final AppDatabase db;
  final DateTime Function() now;
  DateTime? lastConfirmedAt;
  bool storeActive = false;

  /// One-time purchase; kept until Play reports it is no longer owned.
  bool lifetimeOwned = false;

  /// Server start of this account's free trial, cached for offline use.
  DateTime? trialStartedAt;
  String? trialUid;

  /// Admin grant (`grants/{uid}`), cached for offline use: Premium until
  /// [grantUntil] (null = no end), and [trialEnded] ends the trial early.
  bool grantPremium = false;
  DateTime? grantUntil;

  /// When the grant was last read from the server.
  DateTime? grantCheckedAt;
  bool trialEnded = false;
  String? grantUid;

  /// Play base plan of the subscription bought on this device.
  String? subscriptionPlan;

  /// When Google Play says the owned product was bought (this device).
  DateTime? purchasedAt;

  bool get grantActive {
    final until = grantUntil, checked = grantCheckedAt;
    final at = now();
    return grantPremium &&
        !clockSetBack &&
        (until == null || at.isBefore(until)) &&
        checked != null &&
        !at.isBefore(checked) &&
        at.difference(checked) < offlineGrace;
  }

  /// Trial length; the app passes the remote `config/app.trialDays`.
  final int Function() trialDaysOf;
  int get trialDays => trialDaysOf();

  EntitlementService(
    this.db, {
    DateTime Function()? now,
    int Function()? trialDaysOf,
  }) : now = now ?? DateTime.now,
       trialDaysOf = trialDaysOf ?? (() => 7);

  /// Offline, a subscription or an admin grant stays valid this long after
  /// it was last confirmed online; then the free games until the next
  /// online check (which happens by itself at start).
  static const offlineGrace = Duration(days: 3);

  /// The latest time this phone has shown; a clock set back before it
  /// (minus an hour) voids time-limited access until an online check.
  DateTime? maxSeenAt;
  bool clockSetBack = false;

  /// A subscription confirmed by Play stays valid [offlineGrace] offline.
  bool activeAt(DateTime at) =>
      storeActive &&
      lastConfirmedAt != null &&
      !at.isBefore(lastConfirmedAt!) &&
      at.difference(lastConfirmedAt!) < offlineGrace;

  DateTime? get trialEndsAt => trialStartedAt?.add(Duration(days: trialDays));
  bool trialActiveAt(DateTime at) {
    final start = trialStartedAt, end = trialEndsAt;
    return !trialEnded &&
        !clockSetBack &&
        start != null &&
        end != null &&
        !at.isBefore(start.subtract(const Duration(minutes: 5))) &&
        at.isBefore(end);
  }

  bool get trialUsed => trialStartedAt != null;
  bool get trialActive => trialActiveAt(now());

  /// Whole days left, counting a started day (e.g. 6.2 days → 7).
  int get trialDaysLeft {
    final end = trialEndsAt;
    if (end == null || !trialActive) return 0;
    final left = end.difference(now());
    return (left.inMinutes / (24 * 60)).ceil().clamp(1, trialDays);
  }

  PremiumSource get source {
    if (qaPremium) return PremiumSource.qa;
    if (lifetimeOwned) return PremiumSource.lifetime;
    if (!clockSetBack && activeAt(now())) return PremiumSource.subscription;
    if (grantActive) return PremiumSource.granted;
    if (trialActive) return PremiumSource.trial;
    return PremiumSource.none;
  }

  bool get isPremium => source != PremiumSource.none;

  /// Paid through Google Play (not QA, not the trial).
  bool get isPaid =>
      source == PremiumSource.subscription || source == PremiumSource.lifetime;

  Future<void> load() async {
    storeActive = await db.preference('premium.active') == 'true';
    lifetimeOwned = await db.preference('premium.lifetime') == 'true';
    lastConfirmedAt = DateTime.tryParse(
      await db.preference('premium.lastConfirmedAt') ?? '',
    );
    trialStartedAt = DateTime.tryParse(
      await db.preference('trial.startedAt') ?? '',
    );
    trialUid = await db.preference('trial.uid');
    grantUid = await db.preference('grant.uid');
    grantPremium = await db.preference('grant.premium') == 'true';
    grantUntil = DateTime.tryParse(await db.preference('grant.until') ?? '');
    grantCheckedAt = DateTime.tryParse(
      await db.preference('grant.checkedAt') ?? '',
    );
    await noteClock();
    trialEnded = await db.preference('grant.endTrial') == 'true';
    subscriptionPlan = await db.preference('premium.basePlan');
    purchasedAt = DateTime.tryParse(
      await db.preference('premium.purchasedAt') ?? '',
    );
  }

  /// Plan name for the admin list: free | trial | monthly | yearly |
  /// lifetime | granted.
  String get planName => switch (source) {
    PremiumSource.lifetime => 'lifetime',
    PremiumSource.subscription =>
      subscriptionPlan == 'yearly' ? 'yearly' : 'monthly',
    PremiumSource.granted => 'granted',
    PremiumSource.trial => 'trial',
    PremiumSource.none || PremiumSource.qa => 'free',
  };

  Future<void> setPurchasedAt(DateTime? at) async {
    purchasedAt = at;
    await db.setPreference(
      'premium.purchasedAt',
      at?.toUtc().toIso8601String() ?? '',
    );
  }

  Future<void> setSubscriptionPlan(String basePlan) async {
    subscriptionPlan = basePlan;
    await db.setPreference('premium.basePlan', basePlan);
  }

  /// Sign-out: the account's trial and admin grant no longer apply on this
  /// phone (Play purchases belong to the Play account and stay).
  Future<void> clearAccount() async {
    trialUid = null;
    trialStartedAt = null;
    grantUid = null;
    grantPremium = false;
    grantUntil = null;
    trialEnded = false;
    for (final key in [
      'trial.uid',
      'trial.startedAt',
      'grant.uid',
      'grant.premium',
      'grant.until',
      'grant.endTrial',
    ]) {
      await db.setPreference(key, '');
    }
  }

  /// Caches the admin grant of [uid] (all false/null: no grant).
  Future<void> setGrant(
    String uid, {
    required bool premium,
    DateTime? until,
    required bool endTrial,
  }) async {
    await _onlineNow();
    grantUid = uid;
    grantPremium = premium;
    grantUntil = until;
    trialEnded = endTrial;
    grantCheckedAt = now();
    await db.setPreference(
      'grant.checkedAt',
      grantCheckedAt!.toUtc().toIso8601String(),
    );
    await db.setPreference('grant.uid', uid);
    await db.setPreference('grant.premium', '$premium');
    await db.setPreference(
      'grant.until',
      until?.toUtc().toIso8601String() ?? '',
    );
    await db.setPreference('grant.endTrial', '$endTrial');
  }

  /// Remembers the latest time seen; flags a clock set back before it.
  Future<void> noteClock() async {
    final at = now();
    maxSeenAt ??= DateTime.tryParse(
      await db.preference('clock.maxSeenAt') ?? '',
    );
    final seen = maxSeenAt;
    if (seen != null && at.isBefore(seen.subtract(const Duration(hours: 1)))) {
      clockSetBack = true;
      return;
    }
    if (seen == null || at.isAfter(seen)) {
      maxSeenAt = at;
      await db.setPreference('clock.maxSeenAt', at.toUtc().toIso8601String());
    }
  }

  /// An online answer (Play or our server) trusts the clock again.
  Future<void> _onlineNow() async {
    clockSetBack = false;
    maxSeenAt = now();
    await db.setPreference(
      'clock.maxSeenAt',
      maxSeenAt!.toUtc().toIso8601String(),
    );
  }

  /// Play's answer about what this device owns right now.
  Future<void> confirmStoreState(bool active, {bool lifetime = false}) async {
    await _onlineNow();
    storeActive = active;
    lifetimeOwned = lifetime;
    lastConfirmedAt = now();
    await db.setPreference('premium.active', '$active');
    await db.setPreference('premium.lifetime', '$lifetime');
    await db.setPreference(
      'premium.lastConfirmedAt',
      lastConfirmedAt!.toIso8601String(),
    );
  }

  /// Caches the server's trial start for [uid] (null: this account has none).
  Future<void> setTrial(String uid, DateTime? startedAt) async {
    await _onlineNow();
    trialUid = uid;
    trialStartedAt = startedAt;
    await db.setPreference('trial.uid', uid);
    await db.setPreference(
      'trial.startedAt',
      startedAt?.toUtc().toIso8601String() ?? '',
    );
  }
}
