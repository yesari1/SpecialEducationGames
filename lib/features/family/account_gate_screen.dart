import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../core/auth/family_auth.dart';
import 'paywall_view.dart';

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

/// Sign-in and trial page (no close button): the free trial with Google,
/// Premium, or "Continue with the free version". Shown at every start until
/// one is chosen, and after signing out.
class AccountGateScreen extends StatelessWidget {
  final AppState state;
  final FamilyAuth auth;
  const AccountGateScreen({super.key, required this.state, required this.auth});

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
                    // The child takes over: the parent area locks again.
                    onDone: () {
                      state.lockFamily();
                      context.go('/');
                    },
                    onContinueFree: () async {
                      await state.chooseFree();
                      state.lockFamily();
                      if (context.mounted) context.go('/');
                    },
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
