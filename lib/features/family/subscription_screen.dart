import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/page_navigation.dart';
import '../../core/auth/family_auth.dart';
import '../../core/entitlement/billing_repository.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  final AppState state;

  /// Google sign-in for the free trial (one per account). Without it the
  /// trial card stays disabled.
  final FamilyAuth? auth;
  const SubscriptionScreen({super.key, required this.state, this.auth});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  AppState get s => widget.state;
  final PageController _pages = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    s.billing.addListener(_billingChanged);
    widget.auth?.addListener(_billingChanged);
  }

  void _billingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    s.billing.removeListener(_billingChanged);
    widget.auth?.removeListener(_billingChanged);
    _pages.dispose();
    super.dispose();
  }

  List<String> _headingPages(String value) {
    final pages = <String>[];
    var part = '';
    for (final word in value.split(RegExp(r'\s+'))) {
      if (part.isNotEmpty && part.length + word.length + 1 > 22) {
        pages.add(part);
        part = '';
      }
      part = part.isEmpty ? word : '$part $word';
    }
    if (part.isNotEmpty) pages.add(part);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final content = <Widget>[
      for (final part in _headingPages(
        s.configuration.paywallText[s.locale] ?? l10n.subscriptionHeading,
      ))
        _section([Text(part, style: SegText.heading)]),
      for (final feature in [
        l10n.subscriptionAllGames,
        l10n.subscriptionProfiles,
        l10n.subscriptionAdFree,
      ])
        _section([Text(feature)]),
      if (s.entitlement.isPremium)
        _section([Text(l10n.subscriptionActive, style: SegText.heading)]),
      if (!s.entitlement.isPaid) _trialCard(l10n, compact: true),
      _section([
        SegButton(
          label: l10n.subscriptionShowPlans,
          onPressed: s.familyUnlocked ? s.billing.initialize : null,
        ),
        const SizedBox(height: SegSpace.s3),
        if (s.billing.loading) const Center(child: CircularProgressIndicator()),
        if (!s.billing.loading && s.billing.plans.isEmpty)
          Text(l10n.subscriptionUnavailable),
      ]),
      for (final plan in s.billing.plans) ...[
        _section([
          Text(_planName(l10n, plan), style: SegText.heading),
          const SizedBox(height: SegSpace.s3),
          Text(_planPrice(l10n, plan), style: SegText.title),
        ]),
        _section([
          Text(_planNote(l10n, plan)),
          const SizedBox(height: SegSpace.s4),
          SegButton(
            label: _planAction(l10n, plan),
            onPressed: s.billing.pending
                ? null
                : () {
                    if (s.familyUnlocked) s.billing.buy(plan);
                  },
          ),
        ]),
      ],
      _section([
        if (s.billing.error != null) Text(l10n.subscriptionStoreError),
        SegButton(
          label: l10n.subscriptionRestore,
          onPressed: s.familyUnlocked ? s.billing.restore : null,
        ),
      ]),
      _section([
        SegButton(
          label: l10n.subscriptionManage,
          onPressed: s.familyUnlocked
              ? () async {
                  await launchUrl(
                    Uri.parse(
                      'https://play.google.com/store/account/subscriptions?sku=premium&package=com.YeS.OzelEgitimOyunlari',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                }
              : null,
        ),
      ]),
    ];
    return Listener(
      onPointerDown: (_) => s.touchFamily(),
      child: Scaffold(
        backgroundColor: SegColors.familyCanvas,
        appBar: AppBar(
          title: Text(l10n.subscriptionTitle),
          leading: IconButton(
            onPressed: () => context.go('/family'),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: MediaQuery.orientationOf(context) == Orientation.portrait
            ? _portraitBody(context)
            : Padding(
                padding: const EdgeInsets.all(SegSpace.s3),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: content.length,
                        onPageChanged: (index) => setState(() => _page = index),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.all(SegSpace.s3),
                          child: content[index],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.gamePreviousPage,
                          onPressed: _page == 0
                              ? null
                              : () => navigatePage(
                                  context: context,
                                  controller: _pages,
                                  page: _page - 1,
                                  reducedMotion: s.reducedMotion,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              l10n.onboardingStepCount(
                                _page + 1,
                                content.length,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.gameNextPage,
                          onPressed: _page == content.length - 1
                              ? null
                              : () => navigatePage(
                                  context: context,
                                  controller: _pages,
                                  page: _page + 1,
                                  reducedMotion: s.reducedMotion,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _planName(AppLocalizations l10n, BillingPlan plan) =>
      switch (plan.id) {
        'monthly' => l10n.subscriptionMonthly,
        'yearly' => l10n.subscriptionYearly,
        _ => l10n.paywallLifetime,
      };

  String _planPrice(AppLocalizations l10n, BillingPlan plan) => plan.lifetime
      ? plan.recurringPrice
      : l10n.subscriptionPrice(
          plan.recurringPrice,
          plan.id == 'monthly' ? l10n.subscriptionMonth : l10n.subscriptionYear,
        );

  String _planNote(AppLocalizations l10n, BillingPlan plan) => plan.lifetime
      ? l10n.paywallLifetimeNote
      : plan.sevenDayTrial
      ? l10n.subscriptionTrial(plan.recurringPrice)
      : l10n.subscriptionRenewal;

  String _planAction(AppLocalizations l10n, BillingPlan plan) =>
      s.billing.pending
      ? l10n.subscriptionWaiting
      : plan.lifetime
      ? l10n.paywallBuy
      : plan.sevenDayTrial
      ? l10n.subscriptionStartTrial
      : l10n.subscriptionContinue;

  /// Signs in with Google when needed, reads the account's trial and starts
  /// it if it was never used. Parent area only.
  Future<void> _startTrial() async {
    final auth = widget.auth;
    if (auth == null || !s.familyUnlocked) return;
    if (auth.account == null) await auth.signIn();
    final uid = auth.account?.uid;
    if (uid == null || !mounted) return;
    await s.syncTrial(uid);
    if (!s.entitlement.trialUsed) await s.startTrial(uid);
  }

  /// [compact]: one short page of the sideways pager (no body text).
  Widget _trialCard(AppLocalizations l10n, {bool compact = false}) {
    final e = s.entitlement;
    final auth = widget.auth;
    final busy = s.trialBusy || (auth?.busy ?? false);
    final days = e.trialDays;
    final Widget body;
    if (e.trialActive) {
      body = Text(
        l10n.paywallTrialActive(e.trialDaysLeft),
        key: const ValueKey('paywall-trial-active'),
        style: SegText.heading,
      );
    } else if (e.trialUsed) {
      body = Text(
        l10n.paywallTrialUsed,
        key: const ValueKey('paywall-trial-used'),
        style: SegText.body,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.paywallTrialTitle(days), style: SegText.heading),
          if (!compact) ...[
            const SizedBox(height: SegSpace.s2),
            Text(
              l10n.paywallTrialBody(days),
              style: SegText.body.copyWith(color: SegColors.inkSoft),
            ),
          ],
          const SizedBox(height: SegSpace.s3),
          SegButton(
            key: const ValueKey('paywall-trial-start'),
            label: auth?.account == null
                ? l10n.paywallTrialSignIn
                : l10n.paywallTrialStart,
            onPressed: auth == null || busy || !s.familyUnlocked
                ? null
                : _startTrial,
          ),
          if (busy) ...[
            const SizedBox(height: SegSpace.s2),
            const Center(child: CircularProgressIndicator()),
          ],
          if (s.trialIssue != null || auth?.issue != null) ...[
            const SizedBox(height: SegSpace.s2),
            Text(
              l10n.paywallTrialError,
              style: SegText.caption.copyWith(color: SegColors.accentDeep),
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: SegSpace.s2),
            Text(
              l10n.paywallTrialNote,
              style: SegText.caption.copyWith(color: SegColors.inkSoft),
            ),
          ],
        ],
      );
    }
    if (compact) {
      // A bounded pager page: large text scales down instead of overflowing.
      return Align(
        alignment: Alignment.topLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(width: 420, child: body),
        ),
      );
    }
    return SegCard(
      key: const ValueKey('paywall-trial'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/illustrations/family/sign_in.png',
            width: 56,
            height: 56,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: SegSpace.s3),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// Upright layout: one calm scrolling page, benefits first, the free trial,
  /// then prices only as Google Play returns them. No pressure or countdown.
  Widget _portraitBody(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final e = s.entitlement;
    final config = s.configuration;
    Widget benefit(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: SegSpace.s2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDDF6F3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SegColors.turquoiseDeep, size: 22),
          ),
          const SizedBox(width: SegSpace.s3),
          Expanded(child: Text(text, style: SegText.body)),
        ],
      ),
    );
    Widget link(String label, String url) => TextButton(
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(label),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SegSpace.s5,
        SegSpace.s2,
        SegSpace.s5,
        SegSpace.s6,
      ),
      children: [
        Container(
          key: const ValueKey('paywall-hero'),
          padding: const EdgeInsets.all(SegSpace.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SegRadius.xl),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDDF2FD), Color(0xFFFFF6EA)],
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 170,
                child: Image.asset(
                  'assets/illustrations/family/paywall_hero.png',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: SegSpace.s2),
              Text(
                config.paywallText[s.locale] ?? l10n.subscriptionHeading,
                textAlign: TextAlign.center,
                style: SegText.heading.copyWith(color: SegColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: SegSpace.s4),
        benefit(Icons.grid_view_rounded, l10n.subscriptionAllGames),
        benefit(Icons.people_rounded, l10n.subscriptionProfiles),
        benefit(Icons.block_rounded, l10n.subscriptionAdFree),
        benefit(
          Icons.lock_open_rounded,
          l10n.paywallFreeTier(config.freeGames.length),
        ),
        const SizedBox(height: SegSpace.s3),
        if (e.isPaid)
          SegCard(
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
          )
        else
          _trialCard(l10n),
        const SizedBox(height: SegSpace.s4),
        if (e.source != PremiumSource.lifetime)
          for (final plan in s.billing.plans) ...[
            SegCard(
              key: ValueKey('paywall-plan-${plan.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_planName(l10n, plan), style: SegText.heading),
                  const SizedBox(height: SegSpace.s2),
                  Text(_planPrice(l10n, plan), style: SegText.title),
                  const SizedBox(height: SegSpace.s2),
                  Text(
                    _planNote(l10n, plan),
                    style: SegText.caption.copyWith(color: SegColors.inkSoft),
                  ),
                  const SizedBox(height: SegSpace.s3),
                  SegButton(
                    label: _planAction(l10n, plan),
                    onPressed: s.billing.pending || !s.familyUnlocked
                        ? null
                        : () => s.billing.buy(plan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SegSpace.s3),
          ],
        if (s.billing.plans.isEmpty) ...[
          SegButton(
            label: l10n.subscriptionShowPlans,
            onPressed: s.familyUnlocked && !s.billing.loading
                ? s.billing.initialize
                : null,
          ),
          const SizedBox(height: SegSpace.s2),
          if (s.billing.loading)
            const Center(child: CircularProgressIndicator())
          else
            Text(
              l10n.subscriptionUnavailable,
              style: SegText.caption.copyWith(color: SegColors.inkSoft),
            ),
        ],
        if (s.billing.error != null) ...[
          const SizedBox(height: SegSpace.s2),
          Text(l10n.subscriptionStoreError),
        ],
        const SizedBox(height: SegSpace.s4),
        SegButton(
          secondary: true,
          label: l10n.subscriptionRestore,
          onPressed: s.familyUnlocked ? s.billing.restore : null,
        ),
        if (e.source == PremiumSource.subscription) ...[
          const SizedBox(height: SegSpace.s2),
          link(
            l10n.subscriptionManage,
            'https://play.google.com/store/account/subscriptions?sku=${BillingProducts.subscription}&package=com.YeS.OzelEgitimOyunlari',
          ),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            if (config.privacyUrl.isNotEmpty)
              link(l10n.paywallPrivacy, config.privacyUrl),
            if (config.termsUrl.isNotEmpty)
              link(l10n.paywallTerms, config.termsUrl),
          ],
        ),
      ],
    );
  }

  Widget _section(List<Widget> children) => Align(
    alignment: Alignment.topLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
