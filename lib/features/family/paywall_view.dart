import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/auth/family_auth.dart';
import '../../core/entitlement/billing_repository.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../l10n/scoped_localizations.dart';

/// The Premium offer on one screen (no scrolling on a phone): a short
/// header, three benefits, selectable options (free trial, monthly, yearly,
/// one-time), ONE primary button, small links and a way to continue free.
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
  String? _selected; // 'trial' or a plan id

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

  List<String> get _options => [
    if (_trialOffered) 'trial',
    for (final plan in s.billing.plans) plan.id,
  ];

  String? get _choice {
    final options = _options;
    if (_selected != null && options.contains(_selected)) return _selected;
    if (options.contains('trial')) return 'trial';
    if (options.contains('yearly')) return 'yearly';
    return options.firstOrNull;
  }

  Future<void> _continue() async {
    final choice = _choice;
    if (choice == null || !s.familyUnlocked) return;
    if (choice == 'trial') {
      final auth = widget.auth!;
      if (auth.account == null) await auth.signIn();
      final uid = auth.account?.uid;
      if (uid == null || !mounted) return;
      await s.syncTrial(uid);
      if (!s.entitlement.trialUsed) await s.startTrial(uid);
      return;
    }
    final plan = s.billing.plans.where((p) => p.id == choice).firstOrNull;
    if (plan != null) await s.billing.buy(plan);
  }

  void _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final e = s.entitlement;
    final busy =
        s.billing.pending || s.trialBusy || (widget.auth?.busy ?? false);

    final header = Row(
      children: [
        Image.asset(
          'assets/illustrations/family/paywall_hero.png',
          width: 112,
          height: 84,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: SegSpace.s3),
        Expanded(
          child: Text(
            s.configuration.paywallText[s.locale] ?? l10n.paywallHeadline,
            key: const ValueKey('paywall-headline'),
            style: SegText.title.copyWith(color: SegColors.ink),
          ),
        ),
      ],
    );
    Widget benefit(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 22, color: SegColors.turquoiseDeep),
          const SizedBox(width: SegSpace.s2),
          Expanded(child: Text(text, style: SegText.body)),
        ],
      ),
    );
    final benefits = Column(
      children: [
        benefit(Icons.grid_view_rounded, l10n.subscriptionAllGames),
        benefit(Icons.people_rounded, l10n.subscriptionProfiles),
        benefit(Icons.block_rounded, l10n.subscriptionAdFree),
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
      final tiles = <Widget>[
        if (_trialOffered)
          _OptionTile(
            key: const ValueKey('paywall-option-trial'),
            title: l10n.paywallTrialTitle(e.trialDays),
            subtitle: l10n.paywallNoPayment,
            selected: _choice == 'trial',
            highlight: true,
            onTap: () => setState(() => _selected = 'trial'),
          ),
        for (final plan in s.billing.plans)
          _OptionTile(
            key: ValueKey('paywall-option-${plan.id}'),
            title: switch (plan.id) {
              'monthly' => l10n.subscriptionMonthly,
              'yearly' => l10n.subscriptionYearly,
              _ => l10n.paywallLifetime,
            },
            subtitle: plan.lifetime
                ? '${plan.recurringPrice} · ${l10n.paywallOneTimeShort}'
                : l10n.subscriptionPrice(
                    plan.recurringPrice,
                    plan.id == 'monthly'
                        ? l10n.subscriptionMonth
                        : l10n.subscriptionYear,
                  ),
            badge: plan.id == 'yearly' && saving != null
                ? l10n.paywallSave(saving)
                : null,
            selected: _choice == plan.id,
            onTap: () => setState(() => _selected = plan.id),
          ),
      ];
      final status = e.trialActive
          ? l10n.paywallTrialActive(e.trialDaysLeft)
          : null;
      offer = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: SegSpace.s2),
              child: Text(
                status,
                key: const ValueKey('paywall-trial-active'),
                style: SegText.label.copyWith(color: SegColors.turquoiseDeep),
                textAlign: TextAlign.center,
              ),
            ),
          if (tiles.isNotEmpty)
            LayoutBuilder(
              builder: (context, box) {
                const gap = SegSpace.s2;
                final width = (box.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final tile in tiles)
                      SizedBox(width: width, child: tile),
                  ],
                );
              },
            ),
          if (s.billing.plans.isEmpty) ...[
            const SizedBox(height: SegSpace.s2),
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
              s.billing.error != null) ...[
            const SizedBox(height: SegSpace.s2),
            Text(
              s.billing.error != null
                  ? l10n.subscriptionStoreError
                  : l10n.paywallTrialError,
              style: SegText.caption.copyWith(color: SegColors.accentDeep),
              textAlign: TextAlign.center,
            ),
          ],
          if (e.trialUsed && !e.trialActive)
            Padding(
              padding: const EdgeInsets.only(top: SegSpace.s2),
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

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!e.isPaid)
          SegButton(
            key: const ValueKey('paywall-continue'),
            label: busy ? l10n.subscriptionWaiting : l10n.paywallContinue,
            onPressed: busy || _choice == null || !s.familyUnlocked
                ? null
                : _continue,
          ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            _SmallLink(
              key: const ValueKey('paywall-restore'),
              label: l10n.paywallRestoreShort,
              onTap: s.familyUnlocked ? s.billing.restore : null,
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
        TextButton(
          key: const ValueKey('paywall-free'),
          onPressed: widget.onDone,
          child: Text(
            e.isPremium ? l10n.paywallClose : l10n.paywallContinueFree,
            style: SegText.label.copyWith(color: SegColors.primaryDeep),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, box) {
        final landscape = box.maxWidth > box.maxHeight;
        final Widget content = landscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        header,
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
                      children: [
                        offer,
                        const SizedBox(height: SegSpace.s3),
                        actions,
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: SegSpace.s3),
                  benefits,
                  const SizedBox(height: SegSpace.s4),
                  offer,
                  const SizedBox(height: SegSpace.s4),
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

class _OptionTile extends StatelessWidget {
  final String title, subtitle;
  final String? badge;
  final bool selected, highlight;
  final VoidCallback onTap;
  const _OptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected
          ? SegColors.primarySoft
          : highlight
          ? const Color(0xFFFFF6EA)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SegRadius.md),
        side: BorderSide(
          color: selected ? SegColors.primary : SegColors.line,
          width: selected ? 2.5 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(SegRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(SegSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: SegText.label.copyWith(color: SegColors.ink),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: selected ? SegColors.primary : SegColors.inkFaint,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: SegText.caption.copyWith(color: SegColors.inkSoft),
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
