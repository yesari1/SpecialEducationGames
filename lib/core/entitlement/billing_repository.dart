import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'entitlement_service.dart';

/// Google Play product IDs (create them in Play Console with these IDs):
/// a subscription with base plans `monthly` and `yearly`, and a one-time
/// (non-consumable) lifetime product.
abstract final class BillingProducts {
  static const subscription = 'premium';
  static const lifetime = 'premium_lifetime';
  static const all = {subscription, lifetime};
}

class BillingPlan {
  final GooglePlayProductDetails product;
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
  BillingRepository(this.entitlement, {InAppPurchase? store})
    : store = store ?? InAppPurchase.instance;
  Future<void> initialize() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
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
      final response = await store.queryProductDetails(BillingProducts.all);
      if (response.error != null) {
        error = 'store_error';
        return;
      }
      plans = [];
      for (final product
          in response.productDetails.whereType<GooglePlayProductDetails>()) {
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

  Future<void> restore() async {
    if (!available) return;
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
    notifyListeners();
    try {
      final launched = await store.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: plan.product,
          offerToken: plan.offerToken,
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
      if (!BillingProducts.all.contains(p.productID)) continue;
      if (p.status == PurchaseStatus.pending) {
        pending = true;
        _storeReportedPending = true;
        continue;
      }
      pending = false;
      _storeReportedPending = false;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
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
