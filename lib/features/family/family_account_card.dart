import 'package:flutter/material.dart';
import '../../app/ui/components.dart';
import '../../app/ui/page_navigation.dart';
import '../../core/auth/family_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

/// Place only inside the parent-gated family route. The controller independently
/// checks authorization again when any account action is requested.
class FamilyAccountCard extends StatefulWidget {
  final FamilyAuth auth;
  final bool turkish;
  final bool reducedMotion;

  /// Show every part at once (upright, scrolling page) instead of paging.
  final bool flat;
  const FamilyAccountCard({
    super.key,
    required this.auth,
    required this.turkish,
    this.reducedMotion = false,
    this.flat = false,
  });

  @override
  State<FamilyAccountCard> createState() => _FamilyAccountCardState();
}

class _FamilyAccountCardState extends State<FamilyAccountCard> {
  final PageController _pages = PageController();
  int _page = 0;

  String _issue(FamilyAuthIssue issue, AppLocalizations l10n) =>
      switch (issue) {
        FamilyAuthIssue.cancelled => l10n.familyAccountCancelled,
        FamilyAuthIssue.offline => l10n.familyAccountOffline,
        FamilyAuthIssue.configuration => l10n.familyAccountConfiguration,
        FamilyAuthIssue.timeout => l10n.familyAccountTimeout,
        FamilyAuthIssue.unavailable => l10n.familyAccountUnavailable,
      };

  void _keepCurrentPageInRange(int pageCount) {
    final targetPage = _page.clamp(0, pageCount - 1);
    if (targetPage == _page) return;
    _page = targetPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.hasClients) _pages.jumpToPage(targetPage);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.turkish ? 'tr' : 'en');
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final pages = <Widget>[
          _pageContent([
            Text(
              l10n.familyAccountTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.auth.account == null
                  ? l10n.familyAccountOptional
                  : l10n.familyAccountSignedIn,
            ),
          ]),
          _pageContent([
            if (widget.auth.account?.email != null)
              Text(widget.auth.account!.email!),
            Text(l10n.familyAccountLocalProgress),
          ]),
          if (widget.auth.issue case final issue?)
            _pageContent([
              Text(_issue(issue, l10n), semanticsLabel: _issue(issue, l10n)),
            ]),
          _pageContent([
            if (widget.auth.busy)
              const LinearProgressIndicator()
            else
              SegButton(
                label: widget.auth.account == null
                    ? l10n.familyAccountSignIn
                    : l10n.familyAccountSignOut,
                icon: widget.auth.account == null
                    ? Icons.account_circle_outlined
                    : Icons.logout,
                onPressed: widget.auth.account == null
                    ? widget.auth.signIn
                    : widget.auth.signOut,
              ),
            if (widget.auth.account == null) Text(l10n.familyAccountNotNow),
          ]),
        ];
        if (widget.flat) {
          return SegCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final page in pages) ...[page, const SizedBox(height: 12)],
              ],
            ),
          );
        }
        _keepCurrentPageInRange(pages.length);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: pages.length,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemBuilder: (context, index) => pages[index],
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
                          : () => navigatePage(
                              context: context,
                              controller: _pages,
                              page: _page - 1,
                              reducedMotion: widget.reducedMotion,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                            ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('${_page + 1} / ${pages.length}'),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).nextPageTooltip,
                      onPressed: _page == pages.length - 1
                          ? null
                          : () => navigatePage(
                              context: context,
                              controller: _pages,
                              page: _page + 1,
                              reducedMotion: widget.reducedMotion,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                            ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pageContent(List<Widget> children) => Align(
    alignment: Alignment.topLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}
