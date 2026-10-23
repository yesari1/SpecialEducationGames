import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../core/auth/family_auth.dart';
import 'paywall_view.dart';
import 'parent_gate.dart';
import '../onboarding/sign_in_screen.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../l10n/scoped_localizations.dart';

/// Full-screen loading page: the app logo with a small spinner. Used while
/// the saved sign-in is read at start and right after a Google account is
/// chosen; nothing behind it can be tapped.
class AccountLoadingScreen extends StatelessWidget {
  const AccountLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    key: ValueKey('account-loading'),
    color: SegColors.familyCanvas,
    child: SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(36)),
            child: Image(
              image: AssetImage('assets/images/app_logo.png'),
              width: 132,
              height: 132,
            ),
          ),
          SizedBox(height: SegSpace.s5),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: SegColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shown over [child] while [busy]: the loading page, which also blocks taps.
class AccountLoadingOverlay extends StatelessWidget {
  final bool busy;
  final Widget child;
  const AccountLoadingOverlay({
    super.key,
    required this.busy,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (busy) const Positioned.fill(child: AccountLoadingScreen()),
    ],
  );
}

/// Sign-in and trial page (no close button): the app is used signed in with
/// Google, with the account's free trial started (or Premium). Shown at
/// every start until that is so, and after signing out.
class AccountGateScreen extends StatelessWidget {
  final AppState state;
  final FamilyAuth auth;
  const AccountGateScreen({super.key, required this.state, required this.auth});

  Future<void> _signIn(BuildContext context) async {
    UiSound.tap();
    // Account actions are for the parent.
    if (!state.familyUnlocked && !await showParentGate(context, state)) {
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SignInScreen(state: state, auth: auth),
      ),
    );
    if (auth.account == null) auth.issue = null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) => AccountLoadingOverlay(
      busy: auth.busy || !state.accountReady,
      child: Scaffold(
        key: const ValueKey('account-gate'),
        backgroundColor: SegColors.familyCanvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SegSpace.s5,
              SegSpace.s4,
              SegSpace.s5,
              SegSpace.s3,
            ),
            child: Column(
              children: [
                Expanded(
                  child: PaywallView(
                    state: state,
                    auth: auth,
                    onDone: () => context.go('/'),
                  ),
                ),
                // Signed out: an existing account signs in here (its trial
                // or Premium then opens the app).
                if (auth.account == null)
                  TextButton(
                    key: const ValueKey('gate-sign-in'),
                    onPressed: () => _signIn(context),
                    child: Text.rich(
                      TextSpan(
                        text:
                            '${scopedLocalizations(context, state.locale).obHaveAccount} ',
                        style: SegText.body.copyWith(color: SegColors.inkSoft),
                        children: [
                          TextSpan(
                            text: scopedLocalizations(
                              context,
                              state.locale,
                            ).obSignIn,
                            style: SegText.body.copyWith(
                              color: SegColors.primaryDeep,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
