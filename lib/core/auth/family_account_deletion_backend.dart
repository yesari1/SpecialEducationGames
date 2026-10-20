import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

enum FamilyAccountDeletionIssue {
  disabled,
  confirmationRequired,
  invalidExpectedUid,
  accountMismatch,
  authenticationOrAppCheck,
  recentLoginOrServerNotConfigured,
  invalidRequest,
  retryableUnavailable,
  unavailable,
  invalidResponse,
}

class FamilyAccountDeletionFailure implements Exception {
  final FamilyAccountDeletionIssue issue;

  const FamilyAccountDeletionFailure(this.issue);
}

/// Contract for a later parent-gated caller: call only after successful recent
/// reauthentication of the same UID and explicit parent confirmation. This
/// adapter performs neither operation itself and is disabled by default.
///
/// The callable accepts exactly `{confirmDelete: true}`. The UID is checked
/// locally against the currently selected Firebase identity and is never sent.
class FamilyAccountDeletionBackend {
  static const callableName = 'deleteFamilyAccount';

  final bool enabled;
  final String? Function() currentUid;
  final Future<Object?> Function(Map<String, Object?> data) call;

  const FamilyAccountDeletionBackend({
    this.enabled = false,
    required this.currentUid,
    required this.call,
  });

  /// Production bridge. It reads only an already initialized Firebase Auth
  /// user and never initializes an SDK during deletion preflight or transport.
  /// Region is omitted to match the server's default Functions region (the
  /// callable has no explicit region override).
  factory FamilyAccountDeletionBackend.firebase({bool enabled = false}) {
    return FamilyAccountDeletionBackend(
      enabled: enabled,
      currentUid: () =>
          Firebase.apps.isEmpty ? null : FirebaseAuthCurrentUser.uid,
      call: (data) async {
        final app = Firebase.apps.isEmpty ? null : Firebase.app();
        if (app == null) {
          throw const FamilyAccountDeletionFailure(
            FamilyAccountDeletionIssue.unavailable,
          );
        }
        final callable = FirebaseFunctions.instanceFor(
          app: app,
        ).httpsCallable(callableName);
        final result = await callable.call<Map<String, Object?>>(data);
        return result.data;
      },
    );
  }

  Future<void> deleteAccount({
    required String expectedUid,
    required bool confirmed,
  }) async {
    if (!enabled) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.disabled,
      );
    }
    if (!confirmed) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.confirmationRequired,
      );
    }
    if (!_isValidUid(expectedUid)) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.invalidExpectedUid,
      );
    }
    late final String? activeUid;
    try {
      activeUid = currentUid();
    } catch (_) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.unavailable,
      );
    }
    if (activeUid != expectedUid) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.accountMismatch,
      );
    }

    late final Object? response;
    try {
      response = await call(const {'confirmDelete': true});
    } on FirebaseFunctionsException catch (error) {
      throw FamilyAccountDeletionFailure(_translateCode(error.code));
    } on FamilyAccountDeletionFailure {
      rethrow;
    } catch (_) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.unavailable,
      );
    }

    if (response is Map &&
        response.length == 1 &&
        response['deleted'] == true) {
      return;
    }
    throw const FamilyAccountDeletionFailure(
      FamilyAccountDeletionIssue.invalidResponse,
    );
  }

  static bool _isValidUid(String value) =>
      value.isNotEmpty &&
      value.length <= 128 &&
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

  static FamilyAccountDeletionIssue _translateCode(
    String code,
  ) => switch (code) {
    'unauthenticated' ||
    'permission-denied' => FamilyAccountDeletionIssue.authenticationOrAppCheck,
    // The server intentionally uses failed-precondition for both stale auth
    // and its disabled opt-in gate. The client cannot safely distinguish them.
    'failed-precondition' =>
      FamilyAccountDeletionIssue.recentLoginOrServerNotConfigured,
    'invalid-argument' => FamilyAccountDeletionIssue.invalidRequest,
    'unavailable' ||
    'deadline-exceeded' ||
    'resource-exhausted' => FamilyAccountDeletionIssue.retryableUnavailable,
    _ => FamilyAccountDeletionIssue.unavailable,
  };
}

/// Reads the UID from an app that the normal sign-in flow already initialized.
abstract final class FirebaseAuthCurrentUser {
  static String? get uid => FirebaseAuth.instance.currentUser?.uid;
}
