import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/page_navigation.dart';
import '../../l10n/scoped_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  final AppState state;
  const SubscriptionScreen({super.key, required this.state});
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
  }

  void _billingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    s.billing.removeListener(_billingChanged);
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
          Text(
            plan.id == 'monthly'
                ? l10n.subscriptionMonthly
                : l10n.subscriptionYearly,
            style: SegText.heading,
          ),
          const SizedBox(height: SegSpace.s3),
          Text(
            l10n.subscriptionPrice(
              plan.recurringPrice,
              plan.id == 'monthly'
                  ? l10n.subscriptionMonth
                  : l10n.subscriptionYear,
            ),
            style: SegText.title,
          ),
        ]),
        _section([
          Text(
            plan.sevenDayTrial
                ? l10n.subscriptionTrial(plan.recurringPrice)
                : l10n.subscriptionRenewal,
          ),
          const SizedBox(height: SegSpace.s4),
          SegButton(
            label: s.billing.pending
                ? l10n.subscriptionWaiting
                : plan.sevenDayTrial
                ? l10n.subscriptionStartTrial
                : l10n.subscriptionContinue,
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
        body: Padding(
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
                        l10n.onboardingStepCount(_page + 1, content.length),
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

  Widget _section(List<Widget> children) => Align(
    alignment: Alignment.topLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
