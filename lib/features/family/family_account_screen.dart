import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../core/auth/family_auth.dart';
import 'family_account_card.dart';
import 'family_summary_sync_card.dart';
import '../../l10n/scoped_localizations.dart';

class FamilyAccountScreen extends StatefulWidget {
  final AppState state;
  final FamilyAuth auth;
  const FamilyAccountScreen({
    super.key,
    required this.state,
    required this.auth,
  });
  @override
  State<FamilyAccountScreen> createState() => _FamilyAccountScreenState();
}

class _FamilyAccountScreenState extends State<FamilyAccountScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    unawaited(widget.auth.restore());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.state.locale);
    return Scaffold(
      backgroundColor: SegColors.familyCanvas,
      appBar: AppBar(
        title: Text(l10n.accountTitle),
        actions: [
          IconButton(
            tooltip: l10n.familyAccountTitle,
            onPressed: () => _animateTab(context, 0),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: l10n.summarySyncTitle,
            onPressed: () => _animateTab(context, 1),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SegSpace.s3),
            child: ListenableBuilder(
              listenable: widget.state,
              builder: (context, _) => FamilyAccountCard(
                auth: widget.auth,
                turkish: widget.state.locale == 'tr',
                reducedMotion: widget.state.reducedMotion,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SegSpace.s3),
            child: FamilySummarySyncCard(
              state: widget.state,
              auth: widget.auth,
            ),
          ),
        ],
      ),
    );
  }

  void _animateTab(BuildContext context, int index) {
    final reduced =
        widget.state.reducedMotion || MediaQuery.disableAnimationsOf(context);
    _tabs.animateTo(index, duration: reduced ? Duration.zero : null);
  }
}
