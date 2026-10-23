import 'dart:async';
import 'package:flutter/foundation.dart';

class FamilyAccount {
  final String uid;
  final String? email;
  const FamilyAccount(this.uid, {this.email});
}

enum FamilyAuthIssue { cancelled, offline, configuration, timeout, unavailable }

class FamilyAuthFailure implements Exception {
  final FamilyAuthIssue issue;
  const FamilyAuthFailure(this.issue);
}

abstract interface class FamilyAuthBackend {
  Future<FamilyAccount?> restore();
  Future<FamilyAccount?> signIn();
  Future<void> signOut();
  void cancelPending();
}

/// Optional capability for refreshing credentials on the already selected
/// Firebase identity. This is deliberately separate from sign-in, which may
/// establish a different account.
abstract interface class FamilyReauthenticationBackend {
  Future<void> reauthenticate({required String expectedUid});
}

/// Account actions require a fresh parent authorization. No account is required
/// for local profiles, learning records, purchases or play.
class FamilyAuth extends ChangeNotifier {
  final FamilyAuthBackend backend;
  final bool Function() parentAuthorized;
  final Duration timeout;
  FamilyAccount? account;
  FamilyAuthIssue? issue;
  bool busy = false;
  bool _disposed = false;
  int _generation = 0;

  FamilyAuth({
    required this.backend,
    required this.parentAuthorized,
    this.timeout = const Duration(seconds: 120),
  });

  Future<void> restore() => _run(backend.restore);

  /// App start: reads the saved sign-in. It opens no account picker, so no
  /// parent gate is needed.
  Future<void> restoreAtStart() async {
    if (_disposed || busy) return;
    try {
      account = await backend.restore().timeout(timeout);
    } catch (_) {
      account = null;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> signIn() => _run(backend.signIn);
  Future<bool> reauthenticate() async {
    if (_disposed || busy || !parentAuthorized()) return false;
    final existing = account;
    if (existing == null) return false;
    final reauthenticationBackend = backend is FamilyReauthenticationBackend
        ? backend as FamilyReauthenticationBackend
        : null;
    if (reauthenticationBackend == null) {
      issue = FamilyAuthIssue.unavailable;
      notifyListeners();
      return false;
    }

    final generation = ++_generation;
    busy = true;
    issue = null;
    notifyListeners();
    var completed = false;
    try {
      await reauthenticationBackend
          .reauthenticate(expectedUid: existing.uid)
          .timeout(timeout);
      completed =
          !_disposed &&
          generation == _generation &&
          parentAuthorized() &&
          account?.uid == existing.uid;
      if (!_disposed && generation == _generation && !completed) {
        issue = FamilyAuthIssue.cancelled;
      }
      // Reauthentication refreshes only the provider credential. Never replace
      // the controller's account with a backend result.
    } on TimeoutException {
      backend.cancelPending();
      if (!_disposed && generation == _generation) {
        issue = FamilyAuthIssue.timeout;
      }
    } on FamilyAuthFailure catch (failure) {
      if (!_disposed && generation == _generation) issue = failure.issue;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        issue = FamilyAuthIssue.unavailable;
      }
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
    return completed;
  }

  Future<void> signOut() => _run(() async {
    await backend.signOut();
    return null;
  });

  Future<void> _run(Future<FamilyAccount?> Function() action) async {
    if (_disposed || busy || !parentAuthorized()) return;
    final generation = ++_generation;
    busy = true;
    issue = null;
    notifyListeners();
    try {
      final result = await action().timeout(timeout);
      if (!_disposed && generation == _generation) account = result;
    } on TimeoutException {
      backend.cancelPending();
      issue = FamilyAuthIssue.timeout;
    } on FamilyAuthFailure catch (failure) {
      issue = failure.issue;
    } catch (_) {
      // Never expose SDK exception messages (which can include identifiers).
      issue = FamilyAuthIssue.unavailable;
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    backend.cancelPending();
    super.dispose();
  }
}
