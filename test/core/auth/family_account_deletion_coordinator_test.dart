import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/auth/family_account_deletion_backend.dart';
import 'package:special_education_games/core/auth/family_account_deletion_coordinator.dart';

void main() {
  const uid = 'family_123';

  test('default disabled and refused confirmation do no work', () async {
    var reauthCalls = 0;
    var deleteCalls = 0;
    final coordinator = FamilyAccountDeletionCoordinator(
      parentAuthorized: () => true,
      currentUid: () => uid,
      reauthenticate: ({required expectedUid}) async {
        reauthCalls++;
        return true;
      },
      deleteAccount: ({required expectedUid, required confirmed}) async {
        deleteCalls++;
      },
    );

    expect(
      (await coordinator.delete(confirmed: true)).outcome,
      FamilyAccountDeletionOutcome.disabled,
    );
    expect(reauthCalls, 0);
    expect(deleteCalls, 0);

    final enabled = FamilyAccountDeletionCoordinator(
      enabled: true,
      parentAuthorized: () => true,
      currentUid: () => uid,
      reauthenticate: ({required expectedUid}) async {
        reauthCalls++;
        return true;
      },
      deleteAccount: ({required expectedUid, required confirmed}) async {
        deleteCalls++;
      },
    );
    expect(
      (await enabled.delete(confirmed: false)).outcome,
      FamilyAccountDeletionOutcome.confirmationRequired,
    );
    expect(reauthCalls, 0);
    expect(deleteCalls, 0);
  });

  test(
    'closed parent gate or missing account prevents reauthentication',
    () async {
      var allowed = false;
      String? activeUid = uid;
      var reauthCalls = 0;
      final coordinator = FamilyAccountDeletionCoordinator(
        enabled: true,
        parentAuthorized: () => allowed,
        currentUid: () => activeUid,
        reauthenticate: ({required expectedUid}) async {
          reauthCalls++;
          return true;
        },
        deleteAccount: ({required expectedUid, required confirmed}) async {},
      );

      expect(
        (await coordinator.delete(confirmed: true)).outcome,
        FamilyAccountDeletionOutcome.parentGateRequired,
      );
      expect(reauthCalls, 0);

      allowed = true;
      activeUid = null;
      expect(
        (await coordinator.delete(confirmed: true)).outcome,
        FamilyAccountDeletionOutcome.signedOut,
      );
      expect(reauthCalls, 0);
    },
  );

  test(
    'failed or canceled reauthentication never calls deletion backend',
    () async {
      var deleteCalls = 0;
      final coordinator = FamilyAccountDeletionCoordinator(
        enabled: true,
        parentAuthorized: () => true,
        currentUid: () => uid,
        reauthenticate: ({required expectedUid}) async => false,
        deleteAccount: ({required expectedUid, required confirmed}) async {
          deleteCalls++;
        },
      );

      expect(
        (await coordinator.delete(confirmed: true)).outcome,
        FamilyAccountDeletionOutcome.reauthenticationFailed,
      );
      expect(deleteCalls, 0);
    },
  );

  test(
    'reauth exception releases busy and a later user retry can succeed',
    () async {
      var reauthCalls = 0;
      var deleteCalls = 0;
      final coordinator = FamilyAccountDeletionCoordinator(
        enabled: true,
        parentAuthorized: () => true,
        currentUid: () => uid,
        reauthenticate: ({required expectedUid}) async {
          reauthCalls++;
          if (reauthCalls == 1) throw StateError('private provider detail');
          return true;
        },
        deleteAccount: ({required expectedUid, required confirmed}) async {
          deleteCalls++;
        },
      );

      final failed = await coordinator.delete(confirmed: true);
      expect(failed.outcome, FamilyAccountDeletionOutcome.unavailable);
      expect(deleteCalls, 0);
      expect(coordinator.busy, isFalse);

      final retried = await coordinator.delete(confirmed: true);
      expect(retried.outcome, FamilyAccountDeletionOutcome.completed);
      expect(reauthCalls, 2);
      expect(deleteCalls, 1);
      expect(coordinator.busy, isFalse);
    },
  );

  for (final revoked in [false, true]) {
    test(
      revoked
          ? 'parent gate revocation while reauth is pending blocks backend'
          : 'UID switch while reauth is pending blocks backend',
      () async {
        final pendingReauth = Completer<bool>();
        var allowed = true;
        var activeUid = uid;
        var deleteCalls = 0;
        final coordinator = FamilyAccountDeletionCoordinator(
          enabled: true,
          parentAuthorized: () => allowed,
          currentUid: () => activeUid,
          reauthenticate: ({required expectedUid}) => pendingReauth.future,
          deleteAccount: ({required expectedUid, required confirmed}) async {
            deleteCalls++;
          },
        );

        final pending = coordinator.delete(confirmed: true);
        expect(coordinator.busy, isTrue);
        if (revoked) {
          allowed = false;
        } else {
          activeUid = 'different_family';
        }
        pendingReauth.complete(true);
        final result = await pending;
        expect(
          result.outcome,
          revoked
              ? FamilyAccountDeletionOutcome.parentGateRevoked
              : FamilyAccountDeletionOutcome.accountChanged,
        );
        expect(deleteCalls, 0);
        expect(coordinator.busy, isFalse);
      },
    );
  }

  test(
    'duplicate request is rejected and successful path calls once',
    () async {
      final pendingReauth = Completer<bool>();
      var reauthCalls = 0;
      var deleteCalls = 0;
      String? deletedUid;
      bool? confirmationSent;
      final coordinator = FamilyAccountDeletionCoordinator(
        enabled: true,
        parentAuthorized: () => true,
        currentUid: () => uid,
        reauthenticate: ({required expectedUid}) {
          reauthCalls++;
          expect(expectedUid, uid);
          return pendingReauth.future;
        },
        deleteAccount: ({required expectedUid, required confirmed}) async {
          deleteCalls++;
          deletedUid = expectedUid;
          confirmationSent = confirmed;
        },
      );

      final first = coordinator.delete(confirmed: true);
      final duplicate = await coordinator.delete(confirmed: true);
      expect(duplicate.outcome, FamilyAccountDeletionOutcome.busy);
      pendingReauth.complete(true);
      final result = await first;

      expect(result.outcome, FamilyAccountDeletionOutcome.completed);
      expect(reauthCalls, 1);
      expect(deleteCalls, 1);
      expect(deletedUid, uid);
      expect(confirmationSent, isTrue);
    },
  );

  test(
    'duplicate request while backend is pending cannot start another call',
    () async {
      final pendingDelete = Completer<void>();
      var reauthCalls = 0;
      var deleteCalls = 0;
      final coordinator = FamilyAccountDeletionCoordinator(
        enabled: true,
        parentAuthorized: () => true,
        currentUid: () => uid,
        reauthenticate: ({required expectedUid}) async {
          reauthCalls++;
          return true;
        },
        deleteAccount: ({required expectedUid, required confirmed}) {
          deleteCalls++;
          return pendingDelete.future;
        },
      );

      final first = coordinator.delete(confirmed: true);
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.busy, isTrue);
      expect(deleteCalls, 1);

      final duplicate = await coordinator.delete(confirmed: true);
      expect(duplicate.outcome, FamilyAccountDeletionOutcome.busy);
      expect(reauthCalls, 1);
      expect(deleteCalls, 1);

      pendingDelete.complete();
      expect((await first).outcome, FamilyAccountDeletionOutcome.completed);
      expect(deleteCalls, 1);
      expect(coordinator.busy, isFalse);
    },
  );

  test('retains backend failure as typed outcome without retrying', () async {
    var deleteCalls = 0;
    final coordinator = FamilyAccountDeletionCoordinator(
      enabled: true,
      parentAuthorized: () => true,
      currentUid: () => uid,
      reauthenticate: ({required expectedUid}) async => true,
      deleteAccount: ({required expectedUid, required confirmed}) async {
        deleteCalls++;
        throw const FamilyAccountDeletionFailure(
          FamilyAccountDeletionIssue.retryableUnavailable,
        );
      },
    );

    final result = await coordinator.delete(confirmed: true);
    expect(result.outcome, FamilyAccountDeletionOutcome.backendRejected);
    expect(
      result.backendIssue,
      FamilyAccountDeletionIssue.retryableUnavailable,
    );
    expect(deleteCalls, 1);
  });
}
