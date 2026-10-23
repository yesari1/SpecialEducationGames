import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../auth/firebase_client.dart';

/// What the admin set for one account in `grants/{uid}`.
class AdminGrant {
  final bool premium;
  final DateTime? until;
  final bool endTrial;
  const AdminGrant({this.premium = false, this.until, this.endTrial = false});
}

/// `grants/{uid}` (written by the admin panel, read by the owner) and the
/// app's write-only reports: the anonymous `funnel/{installId}` and
/// `feedback/{autoId}`. Every call may throw; callers stay silent.
abstract interface class AdminLink {
  /// The grant of [uid]; an empty grant when the admin set none.
  Future<AdminGrant> grant(String uid);

  /// Merges [data] into `funnel/{installId}`.
  Future<void> funnel(String installId, Map<String, Object?> data);

  /// Adds one `feedback` document.
  Future<void> feedback(Map<String, Object?> data);
}

class FirestoreAdminLink implements AdminLink {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  const FirestoreAdminLink({this.firestore, this.auth});

  static const _timeout = Duration(seconds: 15);

  Future<FirebaseFirestore> _db() async {
    if (firestore != null) return firestore!;
    await FirebaseClient.ensureInitialized();
    return FirebaseFirestore.instance;
  }

  @override
  Future<AdminGrant> grant(String uid) async {
    if (firestore == null && Firebase.apps.isEmpty) {
      throw StateError('firebase_unavailable');
    }
    if ((auth ?? FirebaseAuth.instance).currentUser?.uid != uid) {
      throw StateError('signed_out');
    }
    final snap = await (await _db())
        .collection('grants')
        .doc(uid)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final data = snap.data();
    if (data == null) return const AdminGrant();
    final until = data['until'];
    return AdminGrant(
      premium: data['plan'] == 'premium',
      until: until is Timestamp ? until.toDate() : null,
      endTrial: data['endTrial'] == true,
    );
  }

  @override
  Future<void> funnel(String installId, Map<String, Object?> data) async {
    await (await _db())
        .collection('funnel')
        .doc(installId)
        .set(data, SetOptions(merge: true))
        .timeout(_timeout);
  }

  @override
  Future<void> feedback(Map<String, Object?> data) async {
    await (await _db()).collection('feedback').add(data).timeout(_timeout);
  }
}

/// Firestore server time, for the stamps the rules expect.
Object serverNow() => FieldValue.serverTimestamp();
