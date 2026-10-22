import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../core/auth/family_auth.dart';
import '../../l10n/scoped_localizations.dart';
import 'paywall_view.dart';

/// Family › Premium: the one-screen offer ([PaywallView]).
class SubscriptionScreen extends StatelessWidget {
  final AppState state;

  /// Google sign-in for the free trial (one per account).
  final FamilyAuth? auth;
  const SubscriptionScreen({super.key, required this.state, this.auth});

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    return Listener(
      onPointerDown: (_) => state.touchFamily(),
      child: Scaffold(
        backgroundColor: SegColors.familyCanvas,
        appBar: AppBar(
          title: Text(l10n.subscriptionTitle),
          leading: IconButton(
            tooltip: l10n.paywallClose,
            onPressed: () {
              UiSound.tap();
              context.go('/family');
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SegSpace.s5,
              0,
              SegSpace.s5,
              SegSpace.s3,
            ),
            child: PaywallView(
              state: state,
              auth: auth,
              onDone: () => context.go('/family'),
            ),
          ),
        ),
      ),
    );
  }
}
