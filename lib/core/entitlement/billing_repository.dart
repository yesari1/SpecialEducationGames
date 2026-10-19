import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'entitlement_service.dart';

class BillingPlan {
  final GooglePlayProductDetails product;
  final String id, recurringPrice, period;
  final String? offerToken;
  final bool sevenDayTrial;
  const BillingPlan(
    this.product,
    this.id,
    this.recurringPrice,
    this.period,
    this.offerToken,
    this.sevenDayTrial,
  );
}

class BillingRepository extends ChangeNotifier {
  final EntitlementService entitlement;
  final InAppPurchase store;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<BillingPlan> plans = [];
  bool available = false, loading = false, pending = false;
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
      final response = await store.queryProductDetails({'premium'});
      if (response.error != null) {
        error = 'store_error';
        return;
      }
      plans = [];
      for (final product
          in response.productDetails.whereType<GooglePlayProductDetails>()) {
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
        );
        final existing = plans.indexWhere((p) => p.id == plan.id);
        if (existing < 0) {
          plans.add(plan);
        } else if (plan.sevenDayTrial) {
          plans[existing] = plan;
        }
      }
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
                p.productID == 'premium' &&
                (p.status == PurchaseStatus.purchased ||
                    p.status == PurchaseStatus.restored),
          )
          .toList();
      await entitlement.confirmStoreState(current.isNotEmpty);
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
      if (p.productID != 'premium') continue;
      if (p.status == PurchaseStatus.pending) {
        pending = true;
        continue;
      }
      pending = false;
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
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
