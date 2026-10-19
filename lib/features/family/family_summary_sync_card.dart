import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/ui/components.dart';
import '../../app/ui/page_navigation.dart';
import '../../core/auth/family_auth.dart';
import '../../core/sync/firestore_summary_store.dart';
import '../../core/sync/summary_export.dart';
import '../../core/sync/summary_snapshot_cache.dart';
import '../../core/sync/summary_sync.dart';
import '../../l10n/scoped_localizations.dart';

/// Consent is deliberately session-local and scoped to the current account and
/// profile. Opening this card never contacts a summary server.
class FamilySummarySyncCard extends StatefulWidget {
  final AppState state;
  final FamilyAuth auth;
  final SummaryStore? store;
  const FamilySummarySyncCard({
    super.key,
    required this.state,
    required this.auth,
    this.store,
  });

  @override
  State<FamilySummarySyncCard> createState() => _FamilySummarySyncCardState();
}

class _FamilySummarySyncCardState extends State<FamilySummarySyncCard> {
  final PageController _pages = PageController();
  int _page = 0;
  late final SummarySnapshotCache _cache;
  late final SummarySync _sync;
  String? _uid, _profile;
  bool _authorized = false, _consent = false, _busy = false;
  int _generation = 0;
  SummarySnapshot? _snapshot;
  SummarySyncIssue? _issue;

  bool get _parent => widget.state.familyUnlocked && !widget.auth.busy;

  Future<void> _navigateToPage(int page) => navigatePage(
    context: context,
    controller: _pages,
    page: page,
    reducedMotion: widget.state.reducedMotion,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _cache = SummarySnapshotCache(widget.state.db);
    _sync = SummarySync(
      store: widget.store ?? FirestoreSummaryStore(),
      currentUid: () => widget.auth.account?.uid,
      currentProfileId: () => widget.state.active?.id,
      parentAuthorized: () => _parent,
      consentGiven: () => _consent,
    );
    _uid = widget.auth.account?.uid;
    _profile = widget.state.active?.id;
    _authorized = _parent;
    widget.auth.addListener(_changed);
    widget.state.addListener(_changed);
  }

  bool _valid(int generation, String uid, String profile) =>
      mounted &&
      generation == _generation &&
      _consent &&
      _parent &&
      widget.auth.account?.uid == uid &&
      widget.state.active?.id == profile;

  Future<void> _clear(String? uid, String? profile) async {
    if (uid == null || profile == null) return;
    try {
      await _cache.clear(uid, profile);
    } catch (_) {
      // A local storage failure must never restart a network operation.
    }
  }

  void _changed() {
    final uid = widget.auth.account?.uid;
    final profile = widget.state.active?.id;
    if (uid != _uid || profile != _profile || _parent != _authorized) {
      final oldUid = _uid, oldProfile = _profile;
      _generation++;
      _sync.cancel();
      _consent = false;
      _busy = false;
      _snapshot = null;
      _issue = null;
      _uid = uid;
      _profile = profile;
      _authorized = _parent;
      unawaited(_clear(oldUid, oldProfile));
      if (_page > 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_navigateToPage(2));
          }
        });
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _setConsent(bool value) async {
    if (!_parent || _uid == null || _profile == null) return;
    _generation++;
    _sync.cancel();
    setState(() {
      _consent = value;
      _busy = false;
      _snapshot = null;
      _issue = null;
    });
    final uid = _uid!, profile = _profile!, generation = _generation;
    if (!value) {
      await _clear(uid, profile);
      return;
    }
    try {
      final saved = await _cache.load(uid, profile);
      if (_valid(generation, uid, profile)) setState(() => _snapshot = saved);
    } catch (_) {
      // A missing or unreadable local snapshot does not prevent explicit retry.
    }
  }

  Future<void> _synchronize() async {
    final uid = _uid, profile = _profile;
    if (uid == null || profile == null || !_consent || !_parent || _busy) {
      return;
    }
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _issue = null;
    });
    try {
      final local = prepareDailySummaries(
        profileId: profile,
        sessions: widget.state.sessions,
        trials: widget.state.trials,
        now: DateTime.now(),
      );
      final result = await _sync.synchronize(local);
      if (!_valid(generation, uid, profile)) return;
      await _cache.save(uid, profile, result.summaries);
      if (!_valid(generation, uid, profile)) {
        // Revocation/scope listeners queue a clear behind this save. Do not
        // queue another clear here: a newer explicit sync may already exist.
        return;
      }
      final saved = await _cache.load(uid, profile);
      if (_valid(generation, uid, profile)) {
        setState(() => _snapshot = saved);
        unawaited(_navigateToPage(4));
      }
    } on SummarySyncFailure catch (failure) {
      if (_valid(generation, uid, profile)) {
        setState(() => _issue = failure.issue);
        unawaited(_navigateToPage(4));
      }
    } catch (_) {
      if (_valid(generation, uid, profile)) {
        setState(() => _issue = SummarySyncIssue.unavailable);
        unawaited(_navigateToPage(4));
      }
    } finally {
      if (_valid(generation, uid, profile)) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    widget.auth.removeListener(_changed);
    widget.state.removeListener(_changed);
    _sync.dispose();
    _pages.dispose();
    if (_busy) unawaited(_clear(_uid, _profile));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.state.locale);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  _content(context, [
                    Text(
                      l10n.summarySyncTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.summarySyncDescription),
                  ]),
                  _content(context, [Text(l10n.summarySyncRequirements)]),
                  _content(context, [
                    CheckboxListTile(
                      key: const ValueKey('summary-consent'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _consent,
                      onChanged: _parent && _uid != null && _profile != null
                          ? (v) => _setConsent(v ?? false)
                          : null,
                      title: Text(l10n.summarySyncConsent),
                    ),
                  ]),
                  _content(context, [
                    Text(l10n.summarySyncManualNotice),
                    const SizedBox(height: 12),
                    SegButton(
                      key: const ValueKey('summary-sync'),
                      label: l10n.summarySyncNow,
                      icon: Icons.sync,
                      onPressed: _consent && _parent && !_busy
                          ? _synchronize
                          : null,
                    ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      ),
                  ]),
                  _content(context, [
                    if (_snapshot case final saved?)
                      Text(
                        l10n.summarySyncSnapshot(
                          saved.summaries.length,
                          saved.savedAt.toLocal().toString(),
                        ),
                        key: const ValueKey('summary-snapshot'),
                      ),
                    if (_snapshot == null && _issue == null)
                      Text(l10n.summarySyncTitle),
                    if (_issue != null)
                      Text(
                        _issue == SummarySyncIssue.capacity
                            ? l10n.summarySyncCapacity
                            : l10n.summarySyncUnavailable,
                      ),
                  ]),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).previousPageTooltip,
                  onPressed: _page == 0
                      ? null
                      : () => _navigateToPage(_page - 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(child: Center(child: Text('${_page + 1} / 5'))),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                  onPressed: _page == 4
                      ? null
                      : () => _navigateToPage(_page + 1),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<Widget> children) => Align(
    alignment: Alignment.topLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
