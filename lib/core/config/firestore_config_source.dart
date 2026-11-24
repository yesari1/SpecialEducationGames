import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth/firebase_client.dart';

class FirestoreConfigSource {
  static Future<Map<String, dynamic>?> read() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }
    await FirebaseClient.ensureInitialized();
    final firestore = FirebaseFirestore.instance;
    // The persistent cache is enabled by default on Android and iOS; do not reconfigure an
    // instance after it has already served reads.
    final snapshot = await firestore.doc('config/app').get();
    return snapshot.data();
  }
}
