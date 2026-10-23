import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/ui/google_sign_in_button.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/auth/family_auth.dart';
import '../../l10n/scoped_localizations.dart';
import '../family/account_gate_screen.dart';

/// The store-review account signs in with a password; every other e-mail
/// gets Firebase's password-free sign-in link.
const reviewAccountEmail = 'test@yesastudio.com';

/// Preference holding the e-mail a sign-in link was sent to (the link is
/// completed with it when the parent opens it on this phone).
const pendingSignInEmailKey = 'auth.pendingEmail';

/// "Already have an account?": Google sign-in on top, "or", then e-mail.
/// Pops `true` once an account is signed in; the welcome page then checks
/// the account as before.
class SignInScreen extends StatefulWidget {
  final AppState state;
  final FamilyAuth auth;
  const SignInScreen({super.key, required this.state, required this.auth});

  /// The page while it is open (a sign-in link may finish meanwhile).
  static State<SignInScreen>? openPage;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SignInScreen.openPage = this;
  }

  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _linkSentTo;

  AppState get s => widget.state;
  FamilyAuth get auth => widget.auth;

  bool get _isReview => _email.text.trim().toLowerCase() == reviewAccountEmail;

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  /// A sign-in link completed while this page is open: back to the welcome
  /// page, which checks the account.
  void linkSignedIn() => _done();

  @override
  void dispose() {
    if (SignInScreen.openPage == this) SignInScreen.openPage = null;
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _done() {
    if (mounted && auth.account != null) Navigator.of(context).pop(true);
  }

  Future<void> _google() async {
    UiSound.tap();
    if (auth.account == null) await auth.signIn();
    if (auth.account == null) auth.issue = null;
    _done();
  }

  Future<void> _continue() async {
    UiSound.tap();
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    if (_isReview) {
      await auth.signInWithPassword(email, _password.text);
      _done();
      return;
    }
    if (await auth.sendSignInLink(email)) {
      await s.db.setPreference(pendingSignInEmailKey, email);
      if (mounted) setState(() => _linkSentTo = email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final issue = auth.issue;
        return AccountLoadingOverlay(
          busy: auth.busy,
          child: Scaffold(
            key: const ValueKey('sign-in-page'),
            backgroundColor: SegColors.familyCanvas,
            appBar: AppBar(
              backgroundColor: SegColors.familyCanvas,
              leading: IconButton(
                tooltip: l10n.obBack,
                onPressed: () {
                  UiSound.tap();
                  Navigator.of(context).pop(false);
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            // Everything sits in the middle of the page; it scrolls when the
            // keyboard leaves too little room.
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    SegSpace.s5,
                    0,
                    SegSpace.s5,
                    SegSpace.s5,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, box.maxHeight - SegSpace.s5),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.signInTitle,
                              textAlign: TextAlign.center,
                              style: SegText.title.copyWith(
                                color: SegColors.ink,
                              ),
                            ),
                            const SizedBox(height: SegSpace.s5),
                            GoogleSignInButton(
                              key: const ValueKey('sign-in-google'),
                              label: l10n.familyAccountSignIn,
                              onPressed: _google,
                            ),
                            const SizedBox(height: SegSpace.s4),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: SegSpace.s3,
                                  ),
                                  child: Text(
                                    l10n.signInOr,
                                    style: SegText.label.copyWith(
                                      color: SegColors.inkSoft,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: SegSpace.s4),
                            TextField(
                              key: const ValueKey('sign-in-email'),
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l10n.signInEmail,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    SegRadius.lg,
                                  ),
                                ),
                              ),
                            ),
                            if (_isReview) ...[
                              const SizedBox(height: SegSpace.s3),
                              TextField(
                                key: const ValueKey('sign-in-password'),
                                controller: _password,
                                obscureText: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: InputDecoration(
                                  labelText: l10n.signInPassword,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      SegRadius.lg,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: SegSpace.s4),
                            SegButton(
                              key: const ValueKey('sign-in-email-continue'),
                              label: l10n.signInContinue,
                              secondary: true,
                              onPressed:
                                  !_emailValid ||
                                      (_isReview && _password.text.isEmpty)
                                  ? null
                                  : _continue,
                            ),
                            if (_linkSentTo != null && !_isReview) ...[
                              const SizedBox(height: SegSpace.s4),
                              Text(
                                l10n.signInLinkSent(_linkSentTo!),
                                key: const ValueKey('sign-in-link-sent'),
                                style: SegText.body.copyWith(
                                  color: SegColors.turquoiseDeep,
                                ),
                              ),
                            ],
                            if (issue != null &&
                                issue != FamilyAuthIssue.cancelled) ...[
                              const SizedBox(height: SegSpace.s3),
                              Text(
                                switch (issue) {
                                  FamilyAuthIssue.wrongPassword =>
                                    l10n.signInWrongPassword,
                                  FamilyAuthIssue.offline =>
                                    l10n.familyAccountOffline,
                                  FamilyAuthIssue.timeout =>
                                    l10n.familyAccountTimeout,
                                  FamilyAuthIssue.configuration =>
                                    l10n.familyAccountConfiguration,
                                  _ => l10n.familyAccountUnavailable,
                                },
                                style: SegText.body.copyWith(
                                  color: SegColors.accentDeep,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
