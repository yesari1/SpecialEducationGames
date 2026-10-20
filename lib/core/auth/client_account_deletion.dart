import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'family_account_deletion_backend.dart';

/// Deletes the signed-in family's cloud data and its Firebase account from
/// the device, without a server function: every document under
/// `families/{uid}` (profiles and their sessions, progress and item stats),
/// then the Firebase Auth user. Firestore rules let only the owner delete.
///
/// The `trials/{uid}` record (a start time only) is not deletable by clients,
/// so a trial cannot be restarted; once the account is deleted it no longer
/// belongs to anyone. Local data on the device is left alone.
///
/// Use through [FamilyAccountDeletionCoordinator], which asks the parent to
/// confirm and reauthenticates the same Google account first.
class ClientAccountDeletion {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  /// Profile IDs known on this device. Summaries live under
  /// `profiles/{id}/sessions` without a profile document, so a listing of
  /// `profiles` alone would not find them.
  final Iterable<String> Function() profileIds;
  ClientAccountDeletion({
    this.firestore,
    this.auth,
    Iterable<String> Function()? profileIds,
  }) : profileIds = profileIds ?? (() => const []);

  static const _children = ['sessions', 'progress', 'itemStats'];

  Future<void> call({
    required String expectedUid,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.confirmationRequired,
      );
    }
    if (auth == null && Firebase.apps.isEmpty) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.unavailable,
      );
    }
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null || user.uid != expectedUid) {
      throw const FamilyAccountDeletionFailure(
        FamilyAccountDeletionIssue.accountMismatch,
      );
    }
    final db = firestore ?? FirebaseFirestore.instance;
    final family = db.collection('families').doc(expectedUid);
    const server = GetOptions(source: Source.server);
    try {
      final refs = <DocumentReference<Map<String, dynamic>>>[];
      final listed = await family.collection('profiles').get(server);
      final profiles = {
        for (final doc in listed.docs) doc.reference.path: doc.reference,
        for (final id in profileIds())
          if (id.isNotEmpty)
            family.collection('profiles').doc(id).path: family
                .collection('profiles')
                .doc(id),
      };
      for (final profile in profiles.values) {
        for (final name in _children) {
          final docs = await profile.collection(name).get(server);
          refs.addAll(docs.docs.map((d) => d.reference));
        }
        refs.add(profile);
      }
      refs.add(family);
      for (var i = 0; i < refs.length; i += 400) {
        final batch = db.batch();
        for (final ref in refs.skip(i).take(400)) {
          batch.delete(ref);
        }
        await batch.commit();
      }
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw FamilyAccountDeletionFailure(
        error.code == 'requires-recent-login'
            ? FamilyAccountDeletionIssue.recentLoginOrServerNotConfigured
            : FamilyAccountDeletionIssue.unavailable,
      );
    } on FirebaseException catch (error) {
      throw FamilyAccountDeletionFailure(
        error.code == 'unavailable'
            ? FamilyAccountDeletionIssue.retryableUnavailable
            : FamilyAccountDeletionIssue.unavailable,
      );
    }
  }
}
