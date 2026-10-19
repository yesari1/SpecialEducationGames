import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/firebase_client.dart';
import 'summary_export.dart';
import 'summary_sync.dart';

/// Converts only the timestamp field; validation of every other field remains
/// strict. A string timestamp is deliberately not parsed.
Map<String, dynamic> decodeFirestoreSummary(Map<String, dynamic> payload) {
  final copy = Map<String, dynamic>.of(payload);
  if (copy['updatedAt'] case final Timestamp timestamp) {
    copy['updatedAt'] = timestamp.toDate();
  }
  return copy;
}

class FirestoreSummaryStore implements SummaryStore {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  FirestoreSummaryStore({this.firestore, this.auth});

  Future<FirebaseFirestore> _ready(
    String uid,
    String profile,
    bool Function() authorized,
  ) async {
    if (!isSafeSyncId(uid) || !isSafeSyncId(profile)) {
      throw const SummarySyncFailure(SummarySyncIssue.invalidScope);
    }
    if (!authorized()) {
      throw const SummarySyncFailure(SummarySyncIssue.cancelled);
    }
    await FirebaseClient.ensureInitialized();
    _check(uid, authorized);
    return firestore ?? FirebaseFirestore.instance;
  }

  void _check(String uid, bool Function() authorized) {
    if (!authorized() ||
        (auth ?? FirebaseAuth.instance).currentUser?.uid != uid) {
      throw const SummarySyncFailure(SummarySyncIssue.cancelled);
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(
    FirebaseFirestore db,
    String uid,
    String profile,
  ) => db
      .collection('families')
      .doc(uid)
      .collection('profiles')
      .doc(profile)
      .collection('sessions');

  @override
  Future<List<SummaryDocument>> fetch(
    String uid,
    String profileId, {
    required bool Function() stillAuthorized,
  }) async {
    final db = await _ready(uid, profileId, stillAuthorized);
    // Server-only avoids treating an incomplete offline cache as a full backup.
    final snapshot = await _collection(db, uid, profileId)
        .limit(SummarySync.maxDocuments + 1)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    _check(uid, stillAuthorized);
    if (snapshot.docs.length > SummarySync.maxDocuments) {
      throw const SummarySyncFailure(SummarySyncIssue.capacity);
    }
    return snapshot.docs
        .map(
          (doc) => SummaryDocument(doc.id, decodeFirestoreSummary(doc.data())),
        )
        .toList();
  }

  @override
  Future<List<DailySessionSummary>> merge(
    String uid,
    String profileId,
    List<DailySessionSummary> summaries, {
    required DateTime now,
    required bool Function() stillAuthorized,
  }) async {
    if (summaries.length > SummarySync.maxDocuments ||
        summaries.any((s) => !s.validAt(now)) ||
        summaries.map((s) => s.documentId).toSet().length != summaries.length) {
      throw const SummarySyncFailure(SummarySyncIssue.capacity);
    }
    final db = await _ready(uid, profileId, stillAuthorized);
    final collection = _collection(db, uid, profileId);
    // Transactions fail offline and do not enqueue writes for later replay.
    // All reads precede all writes; retries recheck authorization and LWW.
    return db.runTransaction<List<DailySessionSummary>>(
      (transaction) async {
        _check(uid, stillAuthorized);
        final existing = <String, DailySessionSummary>{};
        for (final summary in summaries) {
          final doc = await transaction.get(collection.doc(summary.documentId));
          _check(uid, stillAuthorized);
          if (doc.exists) {
            final parsed = DailySessionSummary.fromPayload(
              decodeFirestoreSummary(doc.data()!),
              now: now,
            );
            if (parsed != null && parsed.documentId == doc.id) {
              existing[doc.id] = parsed;
            }
          }
        }
        final winners = mergeDailySummaries([
          ...summaries,
          ...existing.values,
        ], now: now);
        _check(uid, stillAuthorized);
        for (final winner in winners) {
          final payload = winner.toPayload();
          payload['updatedAt'] = Timestamp.fromDate(winner.updatedAt);
          transaction.set(collection.doc(winner.documentId), payload);
        }
        return winners;
      },
      timeout: const Duration(seconds: 15),
      maxAttempts: 3,
    );
  }
}
