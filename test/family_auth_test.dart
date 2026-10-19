import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/auth/family_auth.dart';

class FakeFamilyAuth
    implements FamilyAuthBackend, FamilyReauthenticationBackend {
  int calls = 0;
  int cancellations = 0;
  int reauthenticationCalls = 0;
  String? reauthenticationUid;
  Completer<FamilyAccount?>? pending;
  Completer<void>? reauthenticationPending;
  FamilyAuthFailure? failure;
  FamilyAuthFailure? reauthenticationFailure;
  @override
  Future<FamilyAccount?> restore() async {
    calls++;
    return const FamilyAccount('restored');
  }

  @override
  Future<FamilyAccount?> signIn() async {
    calls++;
    if (failure != null) throw failure!;
    return pending == null
        ? const FamilyAccount('parent', email: 'family@example.com')
        : pending!.future;
  }

  @override
  Future<void> signOut() async {
    calls++;
  }

  @override
  Future<void> reauthenticate({required String expectedUid}) async {
    reauthenticationCalls++;
    reauthenticationUid = expectedUid;
    if (reauthenticationFailure != null) throw reauthenticationFailure!;
    await reauthenticationPending?.future;
  }

  @override
  void cancelPending() {
    cancellations++;
  }
}

class UnsupportedReauthenticationBackend implements FamilyAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

void main() {
  test(
    'Only parent action authenticates; cancellation preserves existing account',
    () async {
      var authorized = false;
      final backend = FakeFamilyAuth();
      final auth = FamilyAuth(
        backend: backend,
        parentAuthorized: () => authorized,
      );
      expect(await auth.reauthenticate(), isFalse);
      await auth.signIn();
      await auth.restore();
      await auth.signOut();
      expect(backend.calls, 0);
      authorized = true;
      await auth.signIn();
      expect(auth.account?.uid, 'parent');
      backend.failure = const FamilyAuthFailure(FamilyAuthIssue.cancelled);
      await auth.signIn();
      expect(auth.account?.uid, 'parent');
      expect(auth.issue, FamilyAuthIssue.cancelled);
      await auth.signOut();
      expect(auth.account, isNull);
      auth.dispose();
    },
  );

  test(
    'Timeout cannot publish late identity and duplicate taps are ignored',
    () async {
      final backend = FakeFamilyAuth()..pending = Completer<FamilyAccount?>();
      final auth = FamilyAuth(
        backend: backend,
        parentAuthorized: () => true,
        timeout: const Duration(milliseconds: 10),
      );
      final operation = auth.signIn();
      await auth.signIn();
      expect(backend.calls, 1);
      await operation;
      expect(auth.issue, FamilyAuthIssue.timeout);
      expect(auth.busy, false);
      expect(backend.cancellations, 1);
      backend.pending!.complete(const FamilyAccount('late'));
      await Future<void>.delayed(Duration.zero);
      expect(auth.account, isNull);
      auth.dispose();
    },
  );

  test(
    'Disposal cancels pending work; configuration/offline are recoverable',
    () async {
      final backend = FakeFamilyAuth();
      final auth = FamilyAuth(backend: backend, parentAuthorized: () => true);
      backend.failure = const FamilyAuthFailure(FamilyAuthIssue.configuration);
      await auth.signIn();
      expect(auth.issue, FamilyAuthIssue.configuration);
      backend.failure = const FamilyAuthFailure(FamilyAuthIssue.offline);
      await auth.signIn();
      expect(auth.issue, FamilyAuthIssue.offline);
      backend.failure = null;
      backend.pending = Completer<FamilyAccount?>();
      final operation = auth.signIn();
      auth.dispose();
      backend.pending!.complete(const FamilyAccount('late'));
      await operation;
      expect(auth.account, isNull);
      expect(backend.cancellations, 1);
    },
  );

  test(
    'Reauthentication is parent gated and preserves the selected account',
    () async {
      var authorized = true;
      final backend = FakeFamilyAuth();
      final auth = FamilyAuth(
        backend: backend,
        parentAuthorized: () => authorized,
      );
      await auth.signIn();
      final existing = auth.account;
      expect(existing?.uid, 'parent');

      authorized = false;
      expect(await auth.reauthenticate(), isFalse);
      expect(backend.reauthenticationCalls, 0);
      expect(identical(auth.account, existing), isTrue);

      authorized = true;
      expect(await auth.reauthenticate(), isTrue);
      expect(backend.reauthenticationCalls, 1);
      expect(backend.reauthenticationUid, 'parent');
      expect(identical(auth.account, existing), isTrue);
      expect(auth.issue, isNull);

      backend.reauthenticationFailure = const FamilyAuthFailure(
        FamilyAuthIssue.cancelled,
      );
      expect(await auth.reauthenticate(), isFalse);
      expect(auth.issue, FamilyAuthIssue.cancelled);
      expect(identical(auth.account, existing), isTrue);
      auth.dispose();

      final unsupported = FamilyAuth(
        backend: UnsupportedReauthenticationBackend(),
        parentAuthorized: () => true,
      )..account = const FamilyAccount('existing');
      expect(await unsupported.reauthenticate(), isFalse);
      expect(unsupported.issue, FamilyAuthIssue.unavailable);
      expect(unsupported.account?.uid, 'existing');
      unsupported.dispose();
    },
  );

  test(
    'Reauthentication timeout cancels pending credentials without changing UID',
    () async {
      final backend = FakeFamilyAuth()
        ..reauthenticationPending = Completer<void>();
      final auth = FamilyAuth(
        backend: backend,
        parentAuthorized: () => true,
        timeout: const Duration(milliseconds: 10),
      );
      await auth.signIn();
      final existing = auth.account;
      expect(await auth.reauthenticate(), isFalse);
      expect(auth.issue, FamilyAuthIssue.timeout);
      expect(backend.cancellations, 1);
      expect(identical(auth.account, existing), isTrue);
      expect(auth.account?.uid, 'parent');
      expect(auth.busy, isFalse);
      backend.reauthenticationPending!.complete();
      auth.dispose();
    },
  );

  test(
    'Parent gate revocation during reauthentication cannot report success',
    () async {
      var authorized = true;
      final backend = FakeFamilyAuth()
        ..reauthenticationPending = Completer<void>();
      final auth = FamilyAuth(
        backend: backend,
        parentAuthorized: () => authorized,
      );
      await auth.signIn();
      final existing = auth.account;
      final operation = auth.reauthenticate();
      expect(backend.reauthenticationCalls, 1);
      authorized = false;
      backend.reauthenticationPending!.complete();
      expect(await operation, isFalse);
      expect(auth.issue, FamilyAuthIssue.cancelled);
      expect(identical(auth.account, existing), isTrue);
      auth.dispose();
    },
  );
}
