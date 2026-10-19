import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../auth/firebase_client.dart';
import 'parent_announcement.dart';

class FirestoreAnnouncementSource {
  static Future<Map<String, dynamic>?> read(String id) async {
    if (!ParentAnnouncement.isValidId(id) ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    return _read(id).timeout(const Duration(seconds: 10));
  }

  static Future<Map<String, dynamic>?> _read(String id) async {
    await FirebaseClient.ensureInitialized().timeout(
      const Duration(seconds: 10),
    );
    final snapshot = await FirebaseFirestore.instance
        .doc('announcements/$id')
        .get(const GetOptions(source: Source.server));
    return snapshot.data();
  }
}
