import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/auth/family_account_deletion_coordinator.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/features/family/family_account_card.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

class _Google implements FamilyAuthBackend {
  int signOuts = 0;
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() async => const FamilyAccount('parent-1');
  @override
  Future<void> signOut() async => signOuts++;
  @override
  void cancelPending() {}
}

void main() {
  testWidgets('parent confirms, the same account is deleted, then signed out', (
    tester,
  ) async {
    final google = _Google();
    final auth = FamilyAuth(backend: google, parentAuthorized: () => true);
    addTearDown(auth.dispose);
    await auth.signIn();
    final deleted = <String>[];
    var reauthenticated = 0;
    final deletion = FamilyAccountDeletionCoordinator(
      enabled: true,
      parentAuthorized: () => true,
      currentUid: () => auth.account?.uid,
      reauthenticate: ({required expectedUid}) async {
        reauthenticated++;
        return true;
      },
      deleteAccount: ({required expectedUid, required confirmed}) async {
        if (confirmed) deleted.add(expectedUid);
      },
    );
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FamilyAccountCard(
              auth: auth,
              turkish: false,
              flat: true,
              deletion: deletion,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('family-account-delete')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.familyAccountDeleteTitle), findsOneWidget);
    // Cancel keeps everything.
    await tester.tap(find.text(l10n.familyAccountDeleteCancel));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);

    await tester.tap(find.byKey(const ValueKey('family-account-delete')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('family-account-delete-confirm')),
    );
    await tester.pumpAndSettle();
    expect(reauthenticated, 1);
    expect(deleted, ['parent-1']);
    expect(google.signOuts, 1);
    expect(auth.account, isNull);
    expect(find.text(l10n.familyAccountDeleted), findsOneWidget);
    expect(find.byKey(const ValueKey('family-account-delete')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 3));
  });
}
