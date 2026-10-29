import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../onboarding/sign_in_screen.dart';

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

  /// First run and the start page: a "Continue with the free version"
  /// button under the trial button (no account needed).
  final VoidCallback? onContinueFree;
  const PaywallView({
    super.key,
    required this.state,
    required this.onDone,
    this.auth,
    this.onContinueFree,
  });

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  AppState get s => widget.state;

  /// Height of everything under the picture (portrait), measured once laid
  /// out; the picture gets what is left.
  double? _restHeight;
  String? _selected; // a plan id

  @override
  void initState() {
    super.initState();
    s.billing.addListener(_changed);
    widget.auth?.addListener(_changed);
    // Plans are loaded at app start (main); when that did not get them (Play
    // not ready yet), ask again now. "Try again" reloads them too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          s.billing.started &&
          s.billing.plans.isEmpty &&
          !s.billing.loading) {
        s.billing.initialize();
      }
    });
    s.funnelStep('paywall');
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

  /// Monthly first, then yearly ("Best value"). While the
  /// free trial is offered it is the first row and chosen: the button
  /// starts it, and tapping a plan switches the button to that purchase.
  List<BillingPlan> get _plans {
    const order = {'monthly': 0, 'yearly': 1};
    // The one-time purchase is not offered for now.
    return [...s.billing.plans.where((p) => !p.lifetime)]
      ..sort((a, b) => (order[a.id] ?? 2).compareTo(order[b.id] ?? 2));
  }

  BillingPlan? get _plan {
    final plans = _plans;
    final chosen = plans.where((p) => p.id == _selected).firstOrNull;
    if (chosen != null || _trialOffered) return chosen;
    return plans.where((p) => p.id == 'yearly').firstOrNull ??
        plans.firstOrNull;
  }

  /// While the trial is unused and no plan is tapped, the one button
  /// starts it.
  bool get _startsTrial => _trialOffered && _plan == null;

  /// Purchases need a parent. If the parent area locked meanwhile (time
  /// out), ask again instead of greying the buttons out.
  Future<bool> _parentReady() async {
    if (s.familyUnlocked) return true;
    // The start offers (first run and the start page): whoever opens the app
    // there is the parent, and nothing works before it; no question.
    if (widget.onContinueFree != null) {
      s.unlockFamily();
      return true;
    }
    return showParentGate(context, s);
  }

  Future<void> _restore() async {
    if (await _parentReady()) await s.billing.restore();
  }

  Future<void> _continue() async {
    if (!await _parentReady() || !mounted) return;
    if (_startsTrial) {
      final auth = widget.auth!;
      if (auth.account == null) {
        // Google or e-mail, on the shared sign-in page.
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => SignInScreen(state: s, auth: auth),
          ),
        );
        if (auth.account == null) auth.issue = null;
      }
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
          icon: Icons.celebration_rounded,
          color: SegColors.turquoise,
        );
        widget.onDone();
      }
      return;
    }
    final plan = _plan;
    if (plan == null) return;
    // A subscription does not stop by itself when the one-time purchase is
    // bought: say so first, with the way to cancel it.
    if (plan.lifetime &&
        s.entitlement.source == PremiumSource.subscription &&
        !await _lifetimeWhileSubscribed()) {
      return;
    }
    await s.billing.buy(plan);
  }

  Future<bool> _lifetimeWhileSubscribed() async {
    final l10n = scopedLocalizations(context, s.locale);
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('lifetime-cancel-note'),
        title: Text(l10n.paywallLifetimeSubscribedTitle),
        content: Text(l10n.paywallLifetimeSubscribedBody),
        actions: [
          TextButton(
            onPressed: () => _open(
              'https://play.google.com/store/account/subscriptions'
              '?sku=${BillingProducts.subscription}'
              '&package=com.YeS.OzelEgitimOyunlari',
            ),
            child: Text(l10n.subscriptionManage),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.parentGateCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.paywallLifetimeSubscribedContinue),
          ),
        ],
      ),
    );
    return go == true;
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
          if (_trialOffered) ...[
            _PlanRow(
              key: const ValueKey('paywall-option-trial'),
              title: l10n.paywallTrialOption(e.trialDays),
              subtitle: l10n.paywallTrialOptionNote,
              highlightSubtitle: true,
              // "₺0" in the store's currency; the word when plans are not in.
              price: s.billing.plans.isEmpty
                  ? l10n.paywallFreePrice
                  : '${s.billing.plans.first.product.currencySymbol}0',
              fitSubtitle: true,
              selected: _selected == null,
              onTap: () => setState(() => _selected = null),
            ),
            const SizedBox(height: SegSpace.s2),
          ],
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
            // Room for the badge on the yearly row's top border.
            if (plan.id == 'yearly') const SizedBox(height: SegSpace.s2),
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
      buttonLabel = l10n.paywallStartFreeTrial;
      // The trial row already says it all: no note under the button.
      footnote = null;
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
          if (widget.onContinueFree != null) ...[
            const SizedBox(height: SegSpace.s3),
            Center(
              child: TextButton(
                key: const ValueKey('paywall-continue-free'),
                onPressed: busy ? null : widget.onContinueFree,
                // A large tap area around the short text.
                style: TextButton.styleFrom(
                  minimumSize: const Size(240, 52),
                  padding: const EdgeInsets.symmetric(horizontal: SegSpace.s5),
                ),
                child: Text(
                  l10n.paywallContinueFree,
                  style: SegText.body.copyWith(
                    color: SegColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
    // Restore, terms and privacy (and the plan's note) stay at the bottom.
    final bottom = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The plan's note above the links; it always takes the same room,
        // so changing the plan never shifts the page.
        if (!e.isPaid)
          Padding(
            padding: const EdgeInsets.only(bottom: SegSpace.s1),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final text in [l10n.paywallCancelAnytime])
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
        // One line; smaller on a narrow phone.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            key: const ValueKey('paywall-links'),
            mainAxisSize: MainAxisSize.min,
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
        ),
        // No bottom "close": the X at the top leaves the family-area offer.
      ],
    );

    final page = LayoutBuilder(
      builder: (context, box) {
        final landscape = box.maxWidth > box.maxHeight;
        final Widget? content = landscape
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
            : null;
        if (content == null) {
          // Portrait: the text, plans and buttons keep their full size and
          // width; the picture takes the height that is left (at most 150).
          // Only when even a small picture does not fit does the page scale
          // down as a whole.
          final width = box.maxWidth.clamp(0.0, 520.0);
          final rest = _MeasureHeight(
            onHeight: (h) {
              if (h != _restHeight) setState(() => _restHeight = h);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headline,
                const SizedBox(height: SegSpace.s3),
                Center(child: benefits),
                const SizedBox(height: SegSpace.s4),
                offer,
                const SizedBox(height: SegSpace.s2),
                actions,
              ],
            ),
          );
          final measured = _restHeight;
          final heroHeight = measured == null
              ? 150.0
              : (box.maxHeight - measured - SegSpace.s2).clamp(0.0, 150.0);
          final column = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: heroHeight < 70 ? 70 : heroHeight,
                child: Image.asset(
                  'assets/illustrations/family/paywall_hero.png',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: SegSpace.s2),
              rest,
            ],
          );
          return Opacity(
            // One frame to measure before the page shows.
            opacity: measured == null ? 0 : 1,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(width: width, child: column),
              ),
            ),
          );
        }
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
    return Column(
      children: [
        Expanded(child: page),
        const SizedBox(height: SegSpace.s2),
        bottom,
      ],
    );
  }
}

/// One full-width plan row: radio, name (+ line, badge) and, on the right,
/// the large price with a small note under it.
class _PlanRow extends StatelessWidget {
  final String title, price;
  final String? subtitle, priceNote, badge;
  final bool selected, highlightSubtitle, fitSubtitle;
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
    this.fitSubtitle = false,
  });

  Widget _subtitleText() => Text(
    subtitle!,
    softWrap: false,
    overflow: fitSubtitle ? null : TextOverflow.fade,
    style: highlightSubtitle
        ? SegText.label.copyWith(
            color: SegColors.accentDeep,
            fontWeight: FontWeight.w800,
          )
        : SegText.caption.copyWith(color: SegColors.inkSoft),
  );

  /// The badge ("Best value") sits on the middle of the top border. When
  /// that row is chosen, its orange border grows out of the badge to both
  /// sides at once and meets at the bottom.
  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      selected: selected,
      button: true,
      child: Material(
        // The border changes at once with the choice (no shape animation).
        animationDuration: Duration.zero,
        color: selected ? SegColors.primarySoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SegRadius.md),
          // A badge row draws its chosen (orange) border on top instead.
          side: BorderSide(
            color: selected && badge == null
                ? SegColors.primary
                : SegColors.line,
            width: selected && badge == null ? 2.5 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(SegRadius.md),
          onTap: onTap,
          // Every row has the same height, whatever its lines.
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: SegSpace.s3),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SegText.heading.copyWith(color: SegColors.ink),
                      ),
                      if (subtitle != null)
                        if (fitSubtitle)
                          // One line, made smaller instead of cut.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _subtitleText(),
                          )
                        else
                          _subtitleText(),
                    ],
                  ),
                ),
                const SizedBox(width: SegSpace.s2),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        style: SegText.caption.copyWith(
                          color: SegColors.inkSoft,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (badge == null) return row;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: selected ? 1 : 0),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          builder: (context, t, child) =>
              CustomPaint(foregroundPainter: _GrowingBorder(t), child: child),
          child: row,
        ),
        Positioned(
          top: -12,
          child: IgnorePointer(
            child: Container(
              key: const ValueKey('paywall-badge'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: SegColors.accentStrong,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                badge!,
                maxLines: 1,
                style: SegText.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
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

/// Reports its child's laid-out height after each layout that changes it.
class _MeasureHeight extends SingleChildRenderObjectWidget {
  final ValueChanged<double> onHeight;
  const _MeasureHeight({required this.onHeight, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureHeight renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderMeasureHeight extends RenderProxyBox {
  ValueChanged<double> onHeight;
  double? _last;
  _RenderMeasureHeight(this.onHeight);

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _last) return;
    _last = h;
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(h));
  }
}

/// The chosen border of a badge row: from the top middle along both sides,
/// [t] of the way round (0 none, 1 closed at the bottom).
class _GrowingBorder extends CustomPainter {
  final double t;
  const _GrowingBorder(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    const stroke = 2.5;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final r = SegRadius.md - stroke / 2;
    final cx = rect.center.dx;
    // One loop, clockwise, starting and ending at the top middle.
    final path = Path()
      ..moveTo(cx, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r), radius: Radius.circular(r))
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(
        Offset(rect.right - r, rect.bottom),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(
        Offset(rect.left, rect.bottom - r),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top), radius: Radius.circular(r))
      ..close();
    final metric = path.computeMetrics().first;
    final half = metric.length / 2 * t;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = SegColors.accentStrong;
    canvas.drawPath(metric.extractPath(0, half), paint);
    canvas.drawPath(
      metric.extractPath(metric.length - half, metric.length),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GrowingBorder old) => old.t != t;
}
