import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../db/app_database.dart';
import 'firestore_summary_store.dart';
import 'summary_export.dart';
import 'summary_sync.dart';

/// Sends the active profile's daily summaries to the cloud automatically
/// while a parent is signed in and the family setting allows it (default on).
///
/// Requests are debounced (several game ends in a row send once), failures
/// are quiet and retried on the next request (offline, not configured), and
/// nothing is sent without a signed-in account. Only the summary fields of
/// [DailySessionSummary] leave the device: no names, answers or identifiers.
class AutoSummarySync {
  final SummaryStore store;
  final String? Function() signedInUid;
  final bool Function() enabled;
  final String? Function() activeProfileId;
  final Iterable<GameSession> Function() sessions;
  final Iterable<Trial> Function() trials;
  final Duration delay;
  Timer? _timer;
  SummarySync? _sync;
  bool _disposed = false;

  /// Completed after each attempt (for tests).
  int attempts = 0, sent = 0;
  SummarySyncIssue? lastIssue;

  AutoSummarySync({
    required this.enabled,
    required this.activeProfileId,
    required this.sessions,
    required this.trials,
    SummaryStore? store,
    String? Function()? signedInUid,
    this.delay = const Duration(seconds: 5),
  }) : store = store ?? FirestoreSummaryStore(),
       signedInUid = signedInUid ?? _firebaseUid;

  /// The Firebase user, only if Firebase was already started (a sign-in or
  /// the config read starts it); never starts it on its own.
  static String? _firebaseUid() =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  /// Ask for a sync soon (game end, app resume, sign-in).
  void request() {
    // Nothing to do without the setting or a signed-in parent: no timer.
    if (_disposed || !enabled() || signedInUid() == null) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(run()));
  }

  /// Sends now. Returns quietly when it may not or cannot.
  Future<void> run() async {
    if (_disposed || !enabled()) return;
    final uid = signedInUid();
    final profile = activeProfileId();
    if (uid == null || profile == null) return;
    final sync = _sync ??= SummarySync(
      store: store,
      currentUid: signedInUid,
      currentProfileId: activeProfileId,
      // The parent turned this on in the family area while signed in.
      parentAuthorized: () => true,
      consentGiven: enabled,
    );
    if (sync.busy) {
      request();
      return;
    }
    attempts++;
    try {
      final local = prepareDailySummaries(
        profileId: profile,
        sessions: sessions(),
        trials: trials(),
        now: DateTime.now(),
      );
      if (local.isEmpty) return;
      await sync.synchronize(local);
      sent++;
      lastIssue = null;
    } on SummarySyncFailure catch (failure) {
      lastIssue = failure.issue;
    } catch (_) {
      lastIssue = SummarySyncIssue.unavailable;
    }
  }

  /// Stops any pending or running send (setting turned off, sign-out).
  void cancel() {
    _timer?.cancel();
    _sync?.cancel();
  }

  void dispose() {
    _disposed = true;
    cancel();
    _sync?.dispose();
  }
}
