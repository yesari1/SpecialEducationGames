import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../auth/firebase_client.dart';

enum TrialIssue { signedOut, offline, unavailable }

class TrialFailure implements Exception {
  final TrialIssue issue;
  const TrialFailure(this.issue);
}

/// Where the one free trial per Google account is recorded. The server keeps
/// only the start time, so reinstalling or a new device cannot restart it.
abstract interface class TrialStore {
  /// The trial start for [uid], or null if the account never started one.
  Future<DateTime?> read(String uid);

  /// Starts the trial if it was never started and returns the start time
  /// (the existing one when it had already been started).
  Future<DateTime> claim(String uid);
}

/// `trials/{uid}` = {startedAt: server timestamp}; created once by the
/// signed-in owner and never changed or deleted by clients (firestore.rules).
class FirestoreTrialStore implements TrialStore {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  final Duration timeout;
  FirestoreTrialStore({
    this.firestore,
    this.auth,
    this.timeout = const Duration(seconds: 15),
  });

  Future<DocumentReference<Map<String, dynamic>>> _doc(String uid) async {
    // A Google sign-in always initializes Firebase first; without it there
    // is no account whose trial could be read.
    if (firestore == null && Firebase.apps.isEmpty) {
      throw const TrialFailure(TrialIssue.signedOut);
    }
    try {
      await FirebaseClient.ensureInitialized();
    } catch (_) {
      throw const TrialFailure(TrialIssue.unavailable);
    }
    if ((auth ?? FirebaseAuth.instance).currentUser?.uid != uid) {
      throw const TrialFailure(TrialIssue.signedOut);
    }
    return (firestore ?? FirebaseFirestore.instance)
        .collection('trials')
        .doc(uid);
  }

  @override
  Future<DateTime?> read(String uid) async {
    final doc = await _doc(uid);
    try {
      final snap = await doc
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);
      final value = snap.data()?['startedAt'];
      return value is Timestamp ? value.toDate() : null;
    } on FirebaseException catch (e) {
      throw TrialFailure(
        e.code == 'unavailable' ? TrialIssue.offline : TrialIssue.unavailable,
      );
    } catch (_) {
      throw const TrialFailure(TrialIssue.offline);
    }
  }

  @override
  Future<DateTime> claim(String uid) async {
    final existing = await read(uid);
    if (existing != null) return existing;
    final doc = await _doc(uid);
    try {
      // The rules reject a second create, so a race still ends with one start.
      await doc
          .set({'startedAt': FieldValue.serverTimestamp()})
          .timeout(timeout);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        throw TrialFailure(
          e.code == 'unavailable' ? TrialIssue.offline : TrialIssue.unavailable,
        );
      }
    } catch (_) {
      throw const TrialFailure(TrialIssue.offline);
    }
    final started = await read(uid);
    if (started == null) throw const TrialFailure(TrialIssue.unavailable);
    return started;
  }
}
