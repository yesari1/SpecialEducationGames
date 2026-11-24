import 'dart:async';
import 'package:flutter/foundation.dart';

class FamilyAccount {
  final String uid;
  final String? email;

  /// Google profile name and picture (shown in the family area only).
  final String? name;
  final String? photoUrl;

  /// When the account was created and last signed in (Firebase).
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  const FamilyAccount(
    this.uid, {
    this.email,
    this.name,
    this.photoUrl,
    this.createdAt,
    this.lastSignInAt,
  });
}

enum FamilyAuthIssue {
  cancelled,
  offline,
  configuration,
  timeout,
  unavailable,

  /// E-mail and password did not match (the review account).
  wrongPassword,
}

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

/// E-mail sign-in: a password for the store-review account, and Firebase's
/// password-free sign-in link for everyone else.
abstract interface class FamilyEmailAuthBackend {
  Future<FamilyAccount?> signInWithPassword(String email, String password);
  Future<void> sendSignInLink(String email);
  bool isSignInLink(String link);
  Future<FamilyAccount?> signInWithLink(String email, String link);
}

/// Sign in with Apple (iOS): the App Store asks for it next to Google.
abstract interface class FamilyAppleAuthBackend {
  bool get appleAvailable;
  Future<FamilyAccount?> signInWithApple();
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

  FamilyAppleAuthBackend? get _apple => backend is FamilyAppleAuthBackend
      ? backend as FamilyAppleAuthBackend
      : null;

  /// Sign in with Apple is offered (iOS only).
  bool get appleAvailable => _apple?.appleAvailable ?? false;

  Future<void> signInWithApple() async {
    final apple = _apple;
    if (apple == null) return;
    await _run(apple.signInWithApple);
  }

  FamilyEmailAuthBackend? get _email => backend is FamilyEmailAuthBackend
      ? backend as FamilyEmailAuthBackend
      : null;

  Future<void> signInWithPassword(String email, String password) async {
    final email0 = _email;
    if (email0 == null) return;
    await _run(() => email0.signInWithPassword(email, password));
  }

  /// Sends the sign-in link; false (with [issue]) when it could not.
  Future<bool> sendSignInLink(String email) async {
    final backend0 = _email;
    if (backend0 == null || _disposed || busy || !parentAuthorized()) {
      return false;
    }
    busy = true;
    issue = null;
    notifyListeners();
    var sent = false;
    try {
      await backend0.sendSignInLink(email).timeout(timeout);
      sent = true;
    } on TimeoutException {
      issue = FamilyAuthIssue.timeout;
    } on FamilyAuthFailure catch (failure) {
      issue = failure.issue;
    } catch (_) {
      issue = FamilyAuthIssue.unavailable;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
    return sent;
  }

  bool isSignInLink(String link) {
    try {
      return _email?.isSignInLink(link) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signInWithLink(String email, String link) async {
    final backend0 = _email;
    if (backend0 == null) return;
    await _run(() => backend0.signInWithLink(email, link));
  }

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
