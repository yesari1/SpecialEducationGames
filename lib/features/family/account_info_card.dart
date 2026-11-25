import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/auth/family_auth.dart';
import '../../core/entitlement/billing_repository.dart';
import '../../core/entitlement/entitlement_service.dart';
import '../../l10n/scoped_localizations.dart';
import 'account_header.dart';

/// Family › Account: who is signed in and what the account has (plan, trial
/// end, account dates, purchase date). Next payment dates live in Google
/// Play's subscriptions page, which "Manage subscription" opens.
class AccountInfoCard extends StatelessWidget {
  final AppState state;
  final FamilyAuth auth;
  const AccountInfoCard({super.key, required this.state, required this.auth});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([state, auth]),
    builder: (context, _) {
      final l10n = scopedLocalizations(context, state.locale);
      final account = auth.account;
      final e = state.entitlement;
      final date = DateFormat.yMMMMd(state.locale);
      final plan = switch (e.source) {
        PremiumSource.subscription =>
          e.planName == 'yearly'
              ? l10n.accountPlanYearly
              : l10n.accountPlanMonthly,
        PremiumSource.lifetime => l10n.familyPlanLifetime,
        PremiumSource.trial => l10n.familyPlanTrial(e.trialDaysLeft),
        PremiumSource.granted => l10n.familyPlanGranted,
        PremiumSource.qa => l10n.familyPlanTest,
        PremiumSource.none => l10n.familyPlanFree,
      };
      Widget row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: SegSpace.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 128,
              child: Text(
                label,
                style: SegText.caption.copyWith(color: SegColors.inkSoft),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: SegText.label.copyWith(color: SegColors.ink),
              ),
            ),
          ],
        ),
      );
      final trialEnds = e.trialEndsAt;
      return SegCard(
        key: const ValueKey('account-info-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (account != null) ...[
              AccountHeader(account: account, premium: e.isPremium),
              const SizedBox(height: SegSpace.s3),
              const Divider(height: 1),
            ],
            row(l10n.familyAccountPlan, plan),
            if (e.source == PremiumSource.trial && trialEnds != null)
              row(l10n.accountTrialEnds, date.format(trialEnds.toLocal())),
            if (e.source == PremiumSource.granted && e.grantUntil != null)
              row(
                l10n.accountPremiumUntil,
                date.format(e.grantUntil!.toLocal()),
              ),
            if (e.isPaid && e.purchasedAt != null)
              row(l10n.accountPurchased, date.format(e.purchasedAt!.toLocal())),
            if (account?.createdAt case final created?)
              row(l10n.accountCreated, date.format(created.toLocal())),
            if (account?.lastSignInAt case final last?)
              row(l10n.accountLastSignIn, date.format(last.toLocal())),
            if (e.source == PremiumSource.subscription) ...[
              const SizedBox(height: SegSpace.s3),
              Text(
                BillingProducts.appleStore
                    ? l10n.accountNextPaymentNoteApple
                    : l10n.accountNextPaymentNote,
                style: SegText.caption.copyWith(color: SegColors.inkSoft),
              ),
              const SizedBox(height: SegSpace.s2),
              SegButton(
                key: const ValueKey('account-manage-subscription'),
                label: l10n.subscriptionManage,
                icon: Icons.open_in_new_rounded,
                secondary: true,
                onPressed: BillingProducts.openManageSubscriptions,
              ),
            ],
          ],
        ),
      );
    },
  );
}
