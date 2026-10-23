import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/onboarding/sign_in_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

class _Backend implements FamilyAuthBackend, FamilyEmailAuthBackend {
  final passwords = <String>[];
  final links = <String>[];
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
  @override
  Future<FamilyAccount?> signInWithPassword(String email, String p) async {
    passwords.add(email);
    return FamilyAccount('review', email: email);
  }

  @override
  Future<void> sendSignInLink(String email) async => links.add(email);
  @override
  bool isSignInLink(String link) => false;
  @override
  Future<FamilyAccount?> signInWithLink(String email, String link) async =>
      null;
}

void main() {
  testWidgets(
    'e-mail sign-in: password only for the review account',
    (tester) async {
      final state = (await tester.runAsync(() async {
        final s = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await s.load();
        return s;
      }))!;
      state.unlockFamily();
      final backend = _Backend();
      final auth = FamilyAuth(
        backend: backend,
        parentAuthorized: () => state.familyUnlocked,
      );
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => SignInScreen(state: state, auth: auth),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sign-in-google')), findsOneWidget);
      expect(find.byKey(const ValueKey('sign-in-password')), findsNothing);

      // Another e-mail: a sign-in link, no password.
      await tester.enterText(
        find.byKey(const ValueKey('sign-in-email')),
        'parent@example.org',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('sign-in-password')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('sign-in-email-continue')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(backend.links, ['parent@example.org']);
      expect(find.byKey(const ValueKey('sign-in-link-sent')), findsOneWidget);
      expect(
        await tester.runAsync(() => state.db.preference(pendingSignInEmailKey)),
        'parent@example.org',
      );

      // The review account: password field, then signed in.
      await tester.enterText(
        find.byKey(const ValueKey('sign-in-email')),
        reviewAccountEmail,
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('sign-in-password')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('sign-in-password')),
        'secret',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sign-in-email-continue')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(backend.passwords, [reviewAccountEmail]);
      expect(auth.account?.uid, 'review');
      expect(result, isTrue);
      auth.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
