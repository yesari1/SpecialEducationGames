import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show ReplacementMode;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'entitlement_service.dart';

/// Google Play product IDs (create them in Play Console with these IDs):
/// a subscription with base plans `monthly` and `yearly`, and a one-time
/// (non-consumable) lifetime product.
abstract final class BillingProducts {
  static const subscription = 'premium';
  static const lifetime = 'premium_lifetime';
  static const all = {subscription, lifetime};

  /// True when purchases go through the App Store (iOS), not Google Play.
  static bool get appleStore => defaultTargetPlatform == TargetPlatform.iOS;

  /// Where the user manages or cancels the subscription for this store.
  static String get manageSubscriptionUrl => appleStore
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions'
            '?sku=$subscription&package=com.YeS.OzelEgitimOyunlari';

  /// App Store has no base plans: the two subscriptions are separate
  /// products in one subscription group (create them in App Store Connect
  /// with these IDs); the lifetime product keeps its Play ID.
  static const appleMonthly = 'premium_monthly';
  static const appleYearly = 'premium_yearly';
  static const apple = {appleMonthly, appleYearly, lifetime};

  /// The plan (monthly, yearly, lifetime) an App Store product ID stands for.
  static String? applePlan(String productId) => switch (productId) {
    appleMonthly => 'monthly',
    appleYearly => 'yearly',
    lifetime => 'lifetime',
    _ => null,
  };
}

class BillingPlan {
  final ProductDetails product;
  final String id, recurringPrice, period;
  final String? offerToken;
  final bool sevenDayTrial;

  /// Price in micros of the store currency (for the yearly saving badge).
  final int priceMicros;
  bool get lifetime => id == 'lifetime';
  const BillingPlan(
    this.product,
    this.id,
    this.recurringPrice,
    this.period,
    this.offerToken,
    this.sevenDayTrial, {
    this.priceMicros = 0,
  });

  /// Whole-percent saving of a yearly price over twelve monthly payments.
  static int? yearlySaving(List<BillingPlan> plans) {
    final monthly = plans.where((p) => p.id == 'monthly').firstOrNull;
    final yearly = plans.where((p) => p.id == 'yearly').firstOrNull;
    if (monthly == null || yearly == null || monthly.priceMicros <= 0) {
      return null;
    }
    final saving = 1 - yearly.priceMicros / (monthly.priceMicros * 12);
    final percent = (saving * 100).round();
    return percent >= 5 ? percent : null;
  }
}

class BillingRepository extends ChangeNotifier {
  final EntitlementService entitlement;
  final InAppPurchase store;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<BillingPlan> plans = [];
  bool available = false, loading = false, pending = false;

  /// Play itself said the payment is pending (e.g. a slow payment method);
  /// only then does "waiting" outlive the purchase sheet.
  bool _storeReportedPending = false;
  Timer? _settle;

  /// Back in the app after the purchase sheet: if Play has sent nothing
  /// within a few seconds, the sheet was closed, so the buttons come back.
  void appResumed() {
    if (!pending || _storeReportedPending) return;
    _settle?.cancel();
    _settle = Timer(const Duration(seconds: 4), () {
      if (pending && !_storeReportedPending) {
        pending = false;
        notifyListeners();
      }
    });
  }

  String? error;

  /// A new purchase went through (not a restore); for the install funnel.
  final void Function()? onPurchased;

  /// Base plan of the purchase sheet that is open (monthly or yearly).
  String? _buyingPlan;

  /// The active subscription purchase Play reported (for a plan change).
  GooglePlayPurchaseDetails? ownedSubscription;

  BillingRepository(this.entitlement, {InAppPurchase? store, this.onPurchased})
    : store = store ?? InAppPurchase.instance;

  /// Plans were asked for at least once (the app start does that).
  bool started = false;

  Future<void> initialize() async {
    if (loading) return;
    started = true;
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (kIsWeb || !_android && !_apple) {
        available = false;
        return;
      }
      available = await store.isAvailable();
      if (!available) return;
      _subscription ??= store.purchaseStream.listen(
        _purchases,
        onError: (_) {
          error = 'store_error';
          pending = false;
          notifyListeners();
        },
      );
      final response = await store.queryProductDetails(
        _apple ? BillingProducts.apple : BillingProducts.all,
      );
      if (response.error != null) {
        error = 'store_error';
        return;
      }
      plans = [];
      if (_apple) {
        for (final product in response.productDetails) {
          final id = BillingProducts.applePlan(product.id);
          if (id == null || plans.any((p) => p.id == id)) continue;
          plans.add(
            BillingPlan(
              product,
              id,
              product.price,
              switch (id) {
                'monthly' => 'P1M',
                'yearly' => 'P1Y',
                _ => '',
              },
              null,
              false,
              priceMicros: (product.rawPrice * 1000000).round(),
            ),
          );
        }
      }
      for (final product
          in _apple
              ? const <GooglePlayProductDetails>[]
              : response.productDetails.whereType<GooglePlayProductDetails>()) {
        if (product.id == BillingProducts.lifetime) {
          if (!plans.any((p) => p.lifetime)) {
            plans.add(
              BillingPlan(
                product,
                'lifetime',
                product.price,
                '',
                null,
                false,
                priceMicros: (product.rawPrice * 1000000).round(),
              ),
            );
          }
          continue;
        }
        final index = product.subscriptionIndex;
        final offers = product.productDetails.subscriptionOfferDetails;
        if (index == null || offers == null) continue;
        final offer = offers[index];
        if (!['monthly', 'yearly'].contains(offer.basePlanId) ||
            offer.pricingPhases.isEmpty) {
          continue;
        }
        final recurring = offer.pricingPhases.last;
        final trial =
            offer.offerId == 'trial-7d' &&
            offer.pricingPhases.first.priceAmountMicros == 0 &&
            offer.pricingPhases.first.billingPeriod == 'P7D';
        if (offer.offerId != null && !trial) continue;
        final plan = BillingPlan(
          product,
          offer.basePlanId,
          recurring.formattedPrice,
          recurring.billingPeriod,
          offer.offerIdToken,
          trial,
          priceMicros: recurring.priceAmountMicros,
        );
        final existing = plans.indexWhere((p) => p.id == plan.id);
        if (existing < 0) {
          plans.add(plan);
        } else if (plan.sevenDayTrial) {
          plans[existing] = plan;
        }
      }
      // Monthly, yearly, then the one-time purchase.
      const order = ['monthly', 'yearly', 'lifetime'];
      plans.sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
      await restore();
    } catch (_) {
      error = 'store_error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _apple => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// App Store purchases a restore reported (null while none is running).
  List<PurchaseDetails>? _appleRestored;

  /// App Store: the current entitlements arrive on the purchase stream as
  /// "restored" (StoreKit 2, no sign-in prompt) before the call returns.
  Future<void> _restoreApple() async {
    final restored = _appleRestored = [];
    try {
      await store.restorePurchases();
      // Let the stream deliver what the call sent before it returned.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      _appleRestored = null;
    }
    final current = restored
        .where((p) => BillingProducts.apple.contains(p.productID))
        .toList();
    final plan = current
        .map((p) => BillingProducts.applePlan(p.productID))
        .where((id) => id == 'monthly' || id == 'yearly')
        .firstOrNull;
    if (plan != null && entitlement.subscriptionPlan != plan) {
      await entitlement.setSubscriptionPlan(plan);
    }
    await entitlement.confirmStoreState(
      plan != null,
      lifetime: current.any((p) => p.productID == BillingProducts.lifetime),
    );
    final times = [
      for (final p in current)
        if (int.tryParse(p.transactionDate ?? '') case final ms?)
          DateTime.fromMillisecondsSinceEpoch(ms),
    ]..sort();
    await entitlement.setPurchasedAt(times.lastOrNull);
    for (final p in current) {
      if (p.pendingCompletePurchase) await store.completePurchase(p);
    }
    notifyListeners();
  }

  Future<void> restore() async {
    if (!available) return;
    if (_apple) {
      try {
        await _restoreApple();
      } catch (_) {
        error = 'store_error';
        notifyListeners();
      }
      return;
    }
    try {
      final addition = store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final result = await addition.queryPastPurchases();
      if (result.error != null) {
        error = 'store_error';
        notifyListeners();
        return;
      }
      final current = result.pastPurchases
          .where(
            (p) =>
                BillingProducts.all.contains(p.productID) &&
                (p.status == PurchaseStatus.purchased ||
                    p.status == PurchaseStatus.restored),
          )
          .toList();
      await entitlement.confirmStoreState(
        current.any((p) => p.productID == BillingProducts.subscription),
        lifetime: current.any((p) => p.productID == BillingProducts.lifetime),
      );
      // Purchase time Play reports for what is owned (milliseconds).
      final times = [
        for (final p in current)
          if (int.tryParse(p.transactionDate ?? '') case final ms?)
            DateTime.fromMillisecondsSinceEpoch(ms),
      ]..sort();
      await entitlement.setPurchasedAt(times.lastOrNull);
      ownedSubscription = current
          .whereType<GooglePlayPurchaseDetails>()
          .where((p) => p.productID == BillingProducts.subscription)
          .firstOrNull;
      for (final p in current) {
        if (p.pendingCompletePurchase) await store.completePurchase(p);
      }
      notifyListeners();
    } catch (_) {
      error = 'store_error';
      notifyListeners();
    }
  }

  Future<void> buy(BillingPlan plan) async {
    if (!available || pending) return;
    pending = true;
    error = null;
    _buyingPlan = plan.id;
    notifyListeners();
    try {
      // Monthly <-> yearly is a plan change of the same subscription: to
      // yearly at once (full yearly price, unused monthly days credited by
      // Play), to monthly when the paid year ends.
      if (_apple) {
        // Monthly <-> yearly in one subscription group: the App Store
        // handles the change (and its timing) itself.
        final launched = await store.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: plan.product),
        );
        if (!launched) pending = false;
        notifyListeners();
        return;
      }
      final owned = ownedSubscription;
      final change =
          owned != null &&
              !plan.lifetime &&
              entitlement.subscriptionPlan != plan.id
          ? ChangeSubscriptionParam(
              oldPurchaseDetails: owned,
              replacementMode: plan.id == 'yearly'
                  ? ReplacementMode.chargeFullPrice
                  : ReplacementMode.deferred,
            )
          : null;
      final launched = await store.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: plan.product,
          offerToken: plan.offerToken,
          changeSubscriptionParam: change,
        ),
      );
      if (!launched) pending = false;
    } catch (_) {
      error = 'purchase_error';
      pending = false;
    }
    notifyListeners();
  }

  Future<void> _purchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      final restoring = _appleRestored;
      if (restoring != null && p.status == PurchaseStatus.restored) {
        restoring.add(p);
        continue;
      }
      if (!BillingProducts.all.contains(p.productID) &&
          !(_apple && BillingProducts.apple.contains(p.productID))) {
        continue;
      }
      if (p.status == PurchaseStatus.pending) {
        pending = true;
        _storeReportedPending = true;
        continue;
      }
      pending = false;
      _storeReportedPending = false;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.status == PurchaseStatus.purchased) {
          final plan = _buyingPlan;
          if (p.productID == BillingProducts.subscription &&
              (plan == 'monthly' || plan == 'yearly')) {
            await entitlement.setSubscriptionPlan(plan!);
          }
          onPurchased?.call();
        }
        if (_apple && p.status == PurchaseStatus.purchased) {
          // StoreKit verified this transaction: unlock at once. A restore
          // here runs inside this listener and can miss its own events, which
          // left the offer open (and Premium off) until the next app start.
          final id = BillingProducts.applePlan(p.productID);
          if ((id == 'monthly' || id == 'yearly') &&
              entitlement.subscriptionPlan != id) {
            await entitlement.setSubscriptionPlan(id!);
          }
          final lifetime = id == 'lifetime';
          await entitlement.confirmStoreState(
            !lifetime || entitlement.storeActive,
            lifetime: lifetime || entitlement.lifetimeOwned,
          );
          if (int.tryParse(p.transactionDate ?? '') case final ms?) {
            await entitlement.setPurchasedAt(
              DateTime.fromMillisecondsSinceEpoch(ms),
            );
          }
          if (p.pendingCompletePurchase) await store.completePurchase(p);
          continue;
        }
        // Refresh active ownership from Play before unlocking access.
        await restore();
        if (p.pendingCompletePurchase) await store.completePurchase(p);
      } else if (p.status == PurchaseStatus.error) {
        error = 'purchase_error';
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _settle?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
