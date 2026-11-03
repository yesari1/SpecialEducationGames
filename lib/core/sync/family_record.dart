import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Keeps `families/{uid}` current for a signed-in parent: `createdAt` once,
/// then `updatedAt`, `lastSeenAt`, `locale`, `appVersion`, `plan` and the
/// account e-mail on every app open while signed in. The
/// admin page lists families from these documents; the rules accept the
/// e-mail only when it equals the signed-in token's e-mail.
abstract interface class FamilyRecordStore {
  Future<void> record({
    required String uid,
    required String locale,
    String? email,
    String? appVersion,
    String? plan,
    String? fcmToken,
  });

  /// The plan last written for [uid] (another device may have bought it).
  Future<String?> plan(String uid);
}

class FirestoreFamilyRecordStore implements FamilyRecordStore {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  const FirestoreFamilyRecordStore({this.firestore, this.auth});

  @override
  Future<String?> plan(String uid) async {
    if (firestore == null && Firebase.apps.isEmpty) return null;
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null || user.uid != uid) return null;
    final snap = await (firestore ?? FirebaseFirestore.instance)
        .collection('families')
        .doc(uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    final value = snap.data()?['plan'];
    return value is String ? value : null;
  }

  @override
  Future<void> record({
    required String uid,
    required String locale,
    String? email,
    String? appVersion,
    String? plan,
    String? fcmToken,
  }) async {
    if (firestore == null && Firebase.apps.isEmpty) return;
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null || user.uid != uid) return;
    final db = firestore ?? FirebaseFirestore.instance;
    final ref = db.collection('families').doc(uid);
    // Only the token's own e-mail is ever written.
    final verifiedEmail = email != null && email == user.email ? email : null;
    await db
        .runTransaction((tx) async {
          final snap = await tx.get(ref);
          tx.set(ref, {
            if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastSeenAt': FieldValue.serverTimestamp(),
            'locale': locale == 'tr' ? 'tr' : 'en',
            if (appVersion != null)
              'appVersion': appVersion.length > 32
                  ? appVersion.substring(0, 32)
                  : appVersion,
            'plan': ?plan,
            'email': ?verifiedEmail,
          }, SetOptions(merge: true));
        })
        .timeout(const Duration(seconds: 15));
    // This phone's push address, for messages from the admin page. A
    // separate write, so a rejection never holds back the rest.
    if (fcmToken != null) {
      try {
        await ref
            .set({'fcmToken': fcmToken}, SetOptions(merge: true))
            .timeout(const Duration(seconds: 15));
      } catch (_) {}
    }
  }
}
