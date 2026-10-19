import 'family_account_deletion_backend.dart';

enum FamilyAccountDeletionOutcome {
  completed,
  disabled,
  confirmationRequired,
  parentGateRequired,
  busy,
  signedOut,
  parentGateRevoked,
  accountChanged,
  reauthenticationFailed,
  backendRejected,
  unavailable,
}

class FamilyAccountDeletionResult {
  final FamilyAccountDeletionOutcome outcome;
  final FamilyAccountDeletionIssue? backendIssue;

  const FamilyAccountDeletionResult(
    this.outcome, {
    this.backendIssue,
  });
}

/// Orders explicit parent confirmation, same-account reauthentication, and a
/// single backend call. The supplied reauthentication callback should delegate
/// to `FamilyAuth.reauthenticate()` and return its boolean result, retaining
/// FamilyAuth's captured-UID and generation checks across the provider await.
/// A `completed` result confirms deletion of the UID captured at invocation;
/// a future caller must not clear a different current account after awaiting
/// this result. This class does not show UI, change auth state, retry, or
/// perform local data deletion.
class FamilyAccountDeletionCoordinator {
  final bool enabled;
  final bool Function() parentAuthorized;
  final String? Function() currentUid;
  final Future<bool> Function({required String expectedUid}) reauthenticate;
  final Future<void> Function({
    required String expectedUid,
    required bool confirmed,
  }) deleteAccount;

  bool _busy = false;
  bool get busy => _busy;

  FamilyAccountDeletionCoordinator({
    this.enabled = false,
    required this.parentAuthorized,
    required this.currentUid,
    required this.reauthenticate,
    required this.deleteAccount,
  });

  Future<FamilyAccountDeletionResult> delete({
    required bool confirmed,
  }) async {
    if (_busy) {
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.busy,
      );
    }
    if (!enabled) {
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.disabled,
      );
    }
    if (!confirmed) {
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.confirmationRequired,
      );
    }

    late final String? uid;
    try {
      if (!parentAuthorized()) {
        return const FamilyAccountDeletionResult(
          FamilyAccountDeletionOutcome.parentGateRequired,
        );
      }
      uid = currentUid();
    } catch (_) {
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.unavailable,
      );
    }
    if (uid == null || uid.isEmpty) {
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.signedOut,
      );
    }

    _busy = true;
    try {
      final reauthenticated = await reauthenticate(expectedUid: uid);
      final state = _currentAuthorization(uid);
      if (state != null) return state;
      if (!reauthenticated) {
        return const FamilyAccountDeletionResult(
          FamilyAccountDeletionOutcome.reauthenticationFailed,
        );
      }

      // Recheck immediately before the irreversible remote operation. The
      // backend independently checks its enabled/confirmation/UID contract.
      final beforeCall = _currentAuthorization(uid);
      if (beforeCall != null) return beforeCall;
      await deleteAccount(expectedUid: uid, confirmed: true);
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.completed,
      );
    } on FamilyAccountDeletionFailure catch (failure) {
      return FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.backendRejected,
        backendIssue: failure.issue,
      );
    } catch (_) {
      // Do not return provider/backend exception text or identifiers.
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.unavailable,
      );
    } finally {
      _busy = false;
    }
  }

  FamilyAccountDeletionResult? _currentAuthorization(String expectedUid) {
    try {
      if (!parentAuthorized()) {
        return const FamilyAccountDeletionResult(
          FamilyAccountDeletionOutcome.parentGateRevoked,
        );
      }
      if (currentUid() != expectedUid) {
        return const FamilyAccountDeletionResult(
          FamilyAccountDeletionOutcome.accountChanged,
        );
      }
    } catch (_) {
      return const FamilyAccountDeletionResult(
        FamilyAccountDeletionOutcome.unavailable,
      );
    }
    return null;
  }
}
