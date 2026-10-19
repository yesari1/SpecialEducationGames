import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'family_auth.dart';
import 'firebase_client.dart';

/// Native SDKs own their secure session persistence. Tokens never enter SQLite,
/// preferences, logs or Firestore. Requests are serialized so a late cancelled
/// sign-in cannot replace a later account selection.
class GoogleFamilyAuthBackend
    implements FamilyAuthBackend, FamilyReauthenticationBackend {
  static const _serverClientId =
      '579874152426-e7a15kto2l2nhmfnhfdmoc3a5cnnpfk6.apps.googleusercontent.com';
  GoogleSignIn? _google;
  Future<void> _tail = Future<void>.value();
  int _generation = 0;

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> _initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const FamilyAuthFailure(FamilyAuthIssue.unavailable);
    }
    await FirebaseClient.ensureInitialized();
    _google ??= GoogleSignIn(
      serverClientId: _serverClientId,
      scopes: const ['email'],
    );
  }

  FamilyAccount? _account(User? user) =>
      user == null ? null : FamilyAccount(user.uid, email: user.email);

  @override
  Future<FamilyAccount?> restore() => _serial(() async {
    await _initialize();
    return _account(FirebaseAuth.instance.currentUser);
  });

  @override
  Future<FamilyAccount?> signIn() {
    final generation = ++_generation;
    return _serial(() async {
      try {
        await _initialize();
        if (generation != _generation) return null;
        final selected = await _google!.signIn();
        if (generation != _generation) {
          await _google!.signOut();
          return null;
        }
        if (selected == null) {
          throw const FamilyAuthFailure(FamilyAuthIssue.cancelled);
        }
        final tokens = await selected.authentication;
        if (generation != _generation) return null;
        if (tokens.idToken == null) {
          throw const FamilyAuthFailure(FamilyAuthIssue.configuration);
        }
        final result = await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
          ),
        );
        if (generation != _generation) {
          await FirebaseAuth.instance.signOut();
          await _google!.signOut();
          return null;
        }
        return _account(result.user);
      } on FirebaseAuthException catch (error) {
        throw FamilyAuthFailure(switch (error.code) {
          'network-request-failed' => FamilyAuthIssue.offline,
          'operation-not-allowed' ||
          'invalid-credential' ||
          'invalid-api-key' ||
          'app-not-authorized' => FamilyAuthIssue.configuration,
          _ => FamilyAuthIssue.unavailable,
        });
      } on PlatformException catch (error) {
        throw FamilyAuthFailure(switch (error.code) {
          'sign_in_canceled' => FamilyAuthIssue.cancelled,
          'network_error' => FamilyAuthIssue.offline,
          'sign_in_failed' => FamilyAuthIssue.configuration,
          _ => FamilyAuthIssue.unavailable,
        });
      }
    });
  }

  @override
  Future<void> reauthenticate({required String expectedUid}) {
    final generation = ++_generation;
    return _serial(() async {
      try {
        await _initialize();
        if (generation != _generation) return;
        final existing = FirebaseAuth.instance.currentUser;
        if (existing == null || existing.uid != expectedUid) {
          throw const FamilyAuthFailure(FamilyAuthIssue.cancelled);
        }
        final selected = await _google!.signIn();
        if (generation != _generation) return;
        if (selected == null) {
          throw const FamilyAuthFailure(FamilyAuthIssue.cancelled);
        }
        final tokens = await selected.authentication;
        if (generation != _generation) return;
        if (tokens.idToken == null) {
          throw const FamilyAuthFailure(FamilyAuthIssue.configuration);
        }
        // Recheck the current user immediately before refreshing credentials.
        // This path never calls signInWithCredential and cannot select a new UID.
        final current = FirebaseAuth.instance.currentUser;
        if (current == null || current.uid != expectedUid) {
          throw const FamilyAuthFailure(FamilyAuthIssue.cancelled);
        }
        final result = await current.reauthenticateWithCredential(
          GoogleAuthProvider.credential(
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
          ),
        );
        if (generation != _generation) return;
        if (result.user?.uid != expectedUid ||
            FirebaseAuth.instance.currentUser?.uid != expectedUid) {
          throw const FamilyAuthFailure(FamilyAuthIssue.cancelled);
        }
      } on FirebaseAuthException catch (error) {
        throw FamilyAuthFailure(switch (error.code) {
          'network-request-failed' => FamilyAuthIssue.offline,
          'operation-not-allowed' ||
          'invalid-credential' ||
          'invalid-api-key' ||
          'app-not-authorized' => FamilyAuthIssue.configuration,
          'user-mismatch' || 'user-not-found' => FamilyAuthIssue.cancelled,
          _ => FamilyAuthIssue.unavailable,
        });
      } on PlatformException catch (error) {
        throw FamilyAuthFailure(switch (error.code) {
          'sign_in_canceled' => FamilyAuthIssue.cancelled,
          'network_error' => FamilyAuthIssue.offline,
          'sign_in_failed' => FamilyAuthIssue.configuration,
          _ => FamilyAuthIssue.unavailable,
        });
      }
    });
  }

  @override
  Future<void> signOut() {
    cancelPending();
    return _serial(() async {
      await _initialize();
      await FirebaseAuth.instance.signOut();
      await _google!.signOut();
    });
  }

  @override
  void cancelPending() {
    _generation++;
  }
}
