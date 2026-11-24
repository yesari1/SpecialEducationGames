import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'family_auth.dart';
import 'firebase_client.dart';

/// Native SDKs own their secure session persistence. Tokens never enter SQLite,
/// preferences, logs or Firestore. Requests are serialized so a late cancelled
/// sign-in cannot replace a later account selection.
class GoogleFamilyAuthBackend
    implements
        FamilyAuthBackend,
        FamilyReauthenticationBackend,
        FamilyEmailAuthBackend,
        FamilyAppleAuthBackend {
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
    final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android && !ios) {
      throw const FamilyAuthFailure(FamilyAuthIssue.unavailable);
    }
    await FirebaseClient.ensureInitialized();
    // iOS signs in with its own OAuth client (from GoogleService-Info.plist).
    final iosClientId = ios
        ? (await FirebaseClient.options())['iosClientId'] as String?
        : null;
    _google ??= GoogleSignIn(
      clientId: iosClientId,
      serverClientId: _serverClientId,
      scopes: const ['email'],
    );
  }

  FamilyAccount? _account(User? user) => user == null
      ? null
      : FamilyAccount(
          user.uid,
          email: user.email,
          name: user.displayName,
          photoUrl: user.photoURL,
          createdAt: user.metadata.creationTime,
          lastSignInAt: user.metadata.lastSignInTime,
        );

  /// The project's default Firebase Hosting domain: sign-in links come from
  /// it, and its assetlinks.json lets Android open the app from them.
  static const _linkDomain = 'specialeducationgames.firebaseapp.com';

  static FamilyAuthIssue _emailIssue(FirebaseAuthException error) =>
      switch (error.code) {
        'network-request-failed' => FamilyAuthIssue.offline,
        'wrong-password' ||
        'invalid-credential' ||
        'user-not-found' ||
        'invalid-email' ||
        'user-disabled' => FamilyAuthIssue.wrongPassword,
        'operation-not-allowed' ||
        'invalid-api-key' ||
        'app-not-authorized' ||
        'unauthorized-continue-uri' ||
        'invalid-continue-uri' => FamilyAuthIssue.configuration,
        _ => FamilyAuthIssue.unavailable,
      };

  @override
  Future<FamilyAccount?> signInWithPassword(String email, String password) =>
      _serial(() async {
        await _initialize();
        try {
          final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          return _account(result.user);
        } on FirebaseAuthException catch (error) {
          throw FamilyAuthFailure(_emailIssue(error));
        }
      });

  @override
  Future<void> sendSignInLink(String email) => _serial(() async {
    await _initialize();
    try {
      // The e-mail in the phone's language (Turkish or English).
      await FirebaseAuth.instance.setLanguageCode(
        PlatformDispatcher.instance.locale.languageCode == 'tr' ? 'tr' : 'en',
      );
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://$_linkDomain/sign-in',
          // No `linkDomain`: Firebase refuses the default Hosting domains
          // there, and without it the link comes from that domain anyway.
          handleCodeInApp: true,
          androidPackageName: 'com.YeS.OzelEgitimOyunlari',
          androidInstallApp: false,
          iOSBundleId: 'com.YeS.OzelEgitimOyunlari',
        ),
      );
    } on FirebaseAuthException catch (error) {
      throw FamilyAuthFailure(_emailIssue(error));
    }
  });

  @override
  bool isSignInLink(String link) =>
      Firebase.apps.isNotEmpty &&
      FirebaseAuth.instance.isSignInWithEmailLink(link);

  @override
  Future<FamilyAccount?> signInWithLink(String email, String link) =>
      _serial(() async {
        await _initialize();
        try {
          final result = await FirebaseAuth.instance.signInWithEmailLink(
            email: email,
            emailLink: link,
          );
          return _account(result.user);
        } on FirebaseAuthException catch (error) {
          throw FamilyAuthFailure(_emailIssue(error));
        }
      });

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

  static FamilyAuthIssue _appleIssue(FirebaseAuthException error) =>
      switch (error.code) {
        'network-request-failed' => FamilyAuthIssue.offline,
        // The person closed Apple's sheet.
        'canceled' || 'web-context-canceled' => FamilyAuthIssue.cancelled,
        'operation-not-allowed' ||
        'invalid-credential' ||
        'invalid-api-key' ||
        'app-not-authorized' => FamilyAuthIssue.configuration,
        'user-mismatch' || 'user-not-found' => FamilyAuthIssue.cancelled,
        _ => FamilyAuthIssue.unavailable,
      };

  static AppleAuthProvider get _appleProvider => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  @override
  bool get appleAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<FamilyAccount?> signInWithApple() {
    final generation = ++_generation;
    return _serial(() async {
      if (!appleAvailable) {
        throw const FamilyAuthFailure(FamilyAuthIssue.unavailable);
      }
      try {
        await _initialize();
        if (generation != _generation) return null;
        // Apple's own sign-in sheet; Firebase gets the identity from it.
        final result = await FirebaseAuth.instance.signInWithProvider(
          _appleProvider,
        );
        if (generation != _generation) {
          await FirebaseAuth.instance.signOut();
          return null;
        }
        return _account(result.user);
      } on FirebaseAuthException catch (error) {
        throw FamilyAuthFailure(_appleIssue(error));
      } on PlatformException catch (_) {
        throw const FamilyAuthFailure(FamilyAuthIssue.unavailable);
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
        // An Apple account confirms with Apple again, not with Google.
        if (appleAvailable &&
            existing.providerData.any((p) => p.providerId == 'apple.com')) {
          try {
            final result = await existing.reauthenticateWithProvider(
              _appleProvider,
            );
            if (generation != _generation) return;
            if (result.user?.uid != expectedUid ||
                FirebaseAuth.instance.currentUser?.uid != expectedUid) {
              throw const FamilyAuthFailure(FamilyAuthIssue.cancelled);
            }
            return;
          } on FirebaseAuthException catch (error) {
            throw FamilyAuthFailure(_appleIssue(error));
          }
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
