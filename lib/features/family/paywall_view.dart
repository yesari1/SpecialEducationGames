import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/auth/family_auth.dart';
import '../../core/entitlement/billing_repository.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../l10n/scoped_localizations.dart';
import 'parent_gate.dart';

/// The Premium offer on one screen (no scrolling on a phone): a short
/// hero, a strong headline, three check-mark benefits, full-width plans
/// (yearly preselected, monthly, one-time), ONE primary button that carries
/// the free trial while it is unused, small links and a way to continue free.
/// Pattern notes: docs/paywall-research.md.
///
/// Used in the family area and right after onboarding. Purchases and the
/// trial need the parent area unlocked; the caller is responsible for that.
class PaywallView extends StatefulWidget {
  final AppState state;
  final FamilyAuth? auth;

  /// "Continue with the free version" (and "Close" once Premium is open).
  final VoidCallback onDone;
  const PaywallView({
    super.key,
    required this.state,
    required this.onDone,
    this.auth,
  });

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  AppState get s => widget.state;
  String? _selected; // a plan id

  @override
  void initState() {
    super.initState();
    s.billing.addListener(_changed);
    widget.auth?.addListener(_changed);
    // Plans are loaded at app start (main); "Try again" reloads them.
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    s.billing.removeListener(_changed);
    widget.auth?.removeListener(_changed);
    super.dispose();
  }

  bool get _trialOffered {
    final e = s.entitlement;
    return widget.auth != null && !e.trialUsed && !e.isPremium;
  }

  /// Yearly first (preselected, "Best value"), then monthly, then one-time.
  List<BillingPlan> get _plans {
    const order = {'yearly': 0, 'monthly': 1, 'lifetime': 2};
    return [...s.billing.plans]
      ..sort((a, b) => (order[a.id] ?? 3).compareTo(order[b.id] ?? 3));
  }

  BillingPlan? get _plan {
    final plans = _plans;
    return plans.where((p) => p.id == _selected).firstOrNull ??
        plans.where((p) => p.id == 'yearly').firstOrNull ??
        plans.firstOrNull;
  }

  /// The trial is not a separate option: while it is unused the one
  /// button starts it (unless the one-time purchase is chosen).
  bool get _startsTrial => _trialOffered && !(_plan?.lifetime ?? false);

  /// Purchases need a parent. If the parent area locked meanwhile (time
  /// out), ask again instead of greying the buttons out.
  Future<bool> _parentReady() async {
    if (s.familyUnlocked) return true;
    return showParentGate(context, s);
  }

  Future<void> _restore() async {
    if (await _parentReady()) await s.billing.restore();
  }

  Future<void> _continue() async {
    if (!await _parentReady() || !mounted) return;
    if (_startsTrial) {
      final auth = widget.auth!;
      if (auth.account == null) await auth.signIn();
      final uid = auth.account?.uid;
      if (uid == null || !mounted) return;
      await s.syncTrial(uid);
      if (!s.entitlement.trialUsed) await s.startTrial(uid);
      // The trial is on: leave the offer instead of showing prices.
      if (mounted && s.entitlement.trialActive) {
        final l10n = scopedLocalizations(context, s.locale);
        showNotice(
          context,
          l10n.paywallTrialActive(s.entitlement.trialDaysLeft),
        );
        widget.onDone();
      }
      return;
    }
    final plan = _plan;
    if (plan != null) await s.billing.buy(plan);
  }

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  String _perMonth(BillingPlan plan) => NumberFormat.currency(
    // Same decimal style as the store's own price text ("₺59,99").
    locale: RegExp(r',\d{2}$').hasMatch(plan.recurringPrice) ? 'tr' : 'en',
    symbol: plan.product.currencySymbol,
    decimalDigits: 2,
  ).format(plan.priceMicros / 12 / 1000000);

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final e = s.entitlement;
    final busy =
        s.billing.pending || s.trialBusy || (widget.auth?.busy ?? false);

    final hero = Image.asset(
      'assets/illustrations/family/paywall_hero.png',
      height: 150,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    final headline = Text(
      s.configuration.paywallText[s.locale] ?? l10n.paywallHeadline,
      key: const ValueKey('paywall-headline'),
      style: SegText.display.copyWith(fontSize: 30, color: SegColors.ink),
      textAlign: TextAlign.center,
    );
    Widget benefit(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 22,
            color: SegColors.turquoise,
          ),
          const SizedBox(width: SegSpace.s2),
          Flexible(
            child: Text(
              text,
              style: SegText.body.copyWith(
                color: SegColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    final benefits = Column(
      key: const ValueKey('paywall-benefits'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        benefit(l10n.subscriptionAllGames),
        benefit(l10n.subscriptionProfiles),
        benefit(l10n.subscriptionAdFree),
      ],
    );

    final Widget offer;
    if (e.isPaid) {
      offer = SegCard(
        key: const ValueKey('paywall-owned'),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: SegColors.turquoise),
            const SizedBox(width: SegSpace.s3),
            Expanded(
              child: Text(
                e.source == PremiumSource.lifetime
                    ? l10n.paywallLifetimeOwned
                    : l10n.subscriptionActive,
                style: SegText.heading,
              ),
            ),
          ],
        ),
      );
    } else {
      final saving = BillingPlan.yearlySaving(s.billing.plans);
      final chosen = _plan;
      offer = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (e.trialActive)
            Padding(
              padding: const EdgeInsets.only(bottom: SegSpace.s2),
              child: Text(
                l10n.paywallTrialActive(e.trialDaysLeft),
                key: const ValueKey('paywall-trial-active'),
                style: SegText.label.copyWith(color: SegColors.turquoiseDeep),
                textAlign: TextAlign.center,
              ),
            ),
          for (final plan in _plans) ...[
            _PlanRow(
              key: ValueKey('paywall-option-${plan.id}'),
              title: switch (plan.id) {
                'monthly' => l10n.subscriptionMonthly,
                'yearly' => l10n.subscriptionYearly,
                _ => l10n.paywallLifetime,
              },
              subtitle: switch (plan.id) {
                'monthly' => l10n.paywallCancelShort,
                'yearly' => saving == null ? null : l10n.paywallSave(saving),
                _ => l10n.paywallNoSubscription,
              },
              highlightSubtitle: plan.id == 'yearly',
              price: plan.recurringPrice,
              priceNote: switch (plan.id) {
                'monthly' => l10n.paywallEveryMonth,
                'yearly' when plan.priceMicros > 0 => l10n.paywallPerMonth(
                  _perMonth(plan),
                ),
                'yearly' => null,
                _ => l10n.paywallOnePayment,
              },
              badge: plan.id == 'yearly' ? l10n.paywallBestValue : null,
              selected: chosen?.id == plan.id,
              onTap: () => setState(() => _selected = plan.id),
            ),
            const SizedBox(height: SegSpace.s2),
          ],
          if (s.billing.plans.isEmpty) ...[
            if (s.billing.loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      l10n.paywallPlansFailed,
                      style: SegText.caption.copyWith(color: SegColors.inkSoft),
                    ),
                  ),
                  TextButton(
                    onPressed: s.billing.initialize,
                    child: Text(l10n.paywallRetry),
                  ),
                ],
              ),
          ],
          if (s.trialIssue != null ||
              widget.auth?.issue != null ||
              s.billing.error != null)
            Padding(
              padding: const EdgeInsets.only(top: SegSpace.s1),
              child: Text(
                s.billing.error != null
                    ? l10n.subscriptionStoreError
                    : l10n.paywallTrialError,
                style: SegText.caption.copyWith(color: SegColors.accentDeep),
                textAlign: TextAlign.center,
              ),
            ),
          if (e.trialUsed && !e.trialActive)
            Padding(
              padding: const EdgeInsets.only(top: SegSpace.s1),
              child: Text(
                l10n.paywallTrialUsed,
                key: const ValueKey('paywall-trial-used'),
                style: SegText.caption.copyWith(color: SegColors.inkSoft),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    }

    final plan = _plan;
    final String buttonLabel;
    final String? footnote;
    if (busy) {
      buttonLabel = l10n.subscriptionWaiting;
      footnote = null;
    } else if (_startsTrial) {
      buttonLabel = l10n.paywallStartTrial(e.trialDays);
      footnote = l10n.paywallTrialFootnote;
    } else if (plan != null) {
      buttonLabel = l10n.paywallContinuePrice(plan.recurringPrice);
      footnote = plan.lifetime
          ? l10n.paywallLifetimeNote
          : l10n.paywallCancelAnytime;
    } else {
      buttonLabel = l10n.paywallContinue;
      footnote = null;
    }
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!e.isPaid) ...[
          SegButton(
            key: const ValueKey('paywall-continue'),
            label: buttonLabel,
            // Disabled only while a sign-in, trial start or purchase runs.
            onPressed: busy || (!_startsTrial && plan == null)
                ? null
                : _continue,
          ),
          // Every footnote takes the room of the longest one, so changing
          // the plan never resizes or shifts the page.
          Padding(
            padding: const EdgeInsets.only(top: SegSpace.s2),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final text in [
                  l10n.paywallTrialFootnote,
                  l10n.paywallLifetimeNote,
                  l10n.paywallCancelAnytime,
                ])
                  Visibility(
                    visible: false,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Text(
                      text,
                      style: SegText.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (footnote != null)
                  Text(
                    footnote,
                    key: const ValueKey('paywall-footnote'),
                    style: SegText.caption.copyWith(color: SegColors.inkSoft),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: SegSpace.s1),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            _SmallLink(
              key: const ValueKey('paywall-restore'),
              label: l10n.paywallRestoreShort,
              onTap: _restore,
            ),
            if (e.source == PremiumSource.subscription)
              _SmallLink(
                label: l10n.subscriptionManage,
                onTap: () => _open(
                  'https://play.google.com/store/account/subscriptions?sku=${BillingProducts.subscription}&package=com.YeS.OzelEgitimOyunlari',
                ),
              ),
            if (s.configuration.termsUrl.isNotEmpty)
              _SmallLink(
                label: l10n.paywallTerms,
                onTap: () => _open(s.configuration.termsUrl),
              ),
            if (s.configuration.privacyUrl.isNotEmpty)
              _SmallLink(
                label: l10n.paywallPrivacy,
                onTap: () => _open(s.configuration.privacyUrl),
              ),
          ],
        ),
        // No bottom "close" or "continue free": the X at the top leaves,
        // and the free version simply continues.
      ],
    );

    return LayoutBuilder(
      builder: (context, box) {
        final landscape = box.maxWidth > box.maxHeight;
        final Widget content = landscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        hero,
                        const SizedBox(height: SegSpace.s3),
                        headline,
                        const SizedBox(height: SegSpace.s3),
                        benefits,
                      ],
                    ),
                  ),
                  const SizedBox(width: SegSpace.s5),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [offer, actions],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  hero,
                  const SizedBox(height: SegSpace.s2),
                  headline,
                  const SizedBox(height: SegSpace.s3),
                  Center(child: benefits),
                  const SizedBox(height: SegSpace.s4),
                  offer,
                  const SizedBox(height: SegSpace.s2),
                  actions,
                ],
              );
        // Everything on one page: very large text scales down instead of
        // scrolling.
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: landscape ? box.maxWidth : box.maxWidth.clamp(0, 520),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

/// One full-width plan row: radio, name (+ line, badge) and, on the right,
/// the large price with a small note under it.
class _PlanRow extends StatelessWidget {
  final String title, price;
  final String? subtitle, priceNote, badge;
  final bool selected, highlightSubtitle;
  final VoidCallback onTap;
  const _PlanRow({
    super.key,
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.priceNote,
    this.badge,
    this.highlightSubtitle = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? SegColors.primarySoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SegRadius.lg),
        side: BorderSide(
          color: selected ? SegColors.primary : SegColors.line,
          width: selected ? 2.5 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(SegRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(SegSpace.s3),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 24,
                color: selected ? SegColors.primary : SegColors.inkFaint,
              ),
              const SizedBox(width: SegSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SegText.heading.copyWith(color: SegColors.ink),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: highlightSubtitle
                            ? SegText.label.copyWith(
                                color: SegColors.accentDeep,
                                fontWeight: FontWeight.w800,
                              )
                            : SegText.caption.copyWith(
                                color: SegColors.inkSoft,
                              ),
                      ),
                    if (badge != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SegColors.accentStrong,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge!,
                          style: SegText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: SegSpace.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    key: ValueKey('paywall-price-$title'),
                    style: SegText.title.copyWith(color: SegColors.ink),
                  ),
                  if (priceNote != null)
                    Text(
                      priceNote!,
                      style: SegText.caption.copyWith(color: SegColors.inkSoft),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SmallLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SmallLink({super.key, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 40),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
    child: Text(label, style: SegText.caption),
  );
}
