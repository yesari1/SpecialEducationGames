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
    String? deviceModel,
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
    String? deviceModel,
  }) async {
    if (firestore == null && Firebase.apps.isEmpty) return;
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null || user.uid != uid) return;
    final db = firestore ?? FirebaseFirestore.instance;
    final ref = db.collection('families').doc(uid);
    // Only the token's own e-mail is ever written.
    final verifiedEmail = email != null && email == user.email ? email : null;
    // No Firestore transaction here. When a transaction runs out of time on
    // a slow connection, the Android plugin's next read throws an
    // AssertionError on its own thread ("A transaction object cannot be used
    // after its update callback has been invoked") and the whole app closes
    // (Play vitals, 2.0.43-2.0.52). A plain read followed by a write cannot
    // do that.
    const wait = Duration(seconds: 15);
    final snap = await ref.get().timeout(wait);
    await ref
        .set({
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
        }, SetOptions(merge: true))
        .timeout(wait);
    // This phone's push address (messages from the admin page) and model.
    // A separate write, so a rejection never holds back the rest.
    if (fcmToken != null || deviceModel != null) {
      try {
        await ref
            .set({
              'fcmToken': ?fcmToken,
              'deviceModel': ?deviceModel,
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 15));
      } catch (_) {}
    }
  }
}
