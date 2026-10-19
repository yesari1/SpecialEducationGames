import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

class WelcomePane extends StatefulWidget {
  final AppState state;
  final VoidCallback onContinue;
  const WelcomePane({super.key, required this.state, required this.onContinue});
  @override
  State<WelcomePane> createState() => _WelcomePaneState();
}

class _WelcomePaneState extends State<WelcomePane> {
  int _page = 0;
  static const int _count = 5;
  late final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (i < 0 || i >= _count) return;
    if (widget.state.reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(i);
      return;
    }
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  bool _useCompactPager(BuildContext context) {
    final media = MediaQuery.of(context);
    return media.size.height < 500 && media.textScaler.scale(1) > 1.25;
  }

  Widget _overview(Size size, AppLocalizations l10n) {
    final title = Text(
      l10n.welcomeTitle,
      key: const ValueKey('welcome-title'),
      style: SegText.display.copyWith(fontSize: 26),
    );
    final subtitle = Text(
      l10n.welcomeSubtitle,
      key: const ValueKey('welcome-subtitle'),
      style: SegText.body.copyWith(color: SegColors.inkSoft),
    );
    final features = <Widget>[
      _FeatureCard(
        key: const ValueKey('welcome-feature-1'),
        icon: Icons.spa,
        iconColor: SegColors.turquoise,
        label: l10n.noAdsOffline,
      ),
      _FeatureCard(
        key: const ValueKey('welcome-feature-2'),
        icon: Icons.lock_outline,
        iconColor: SegColors.turquoise,
        label: l10n.parentGateSettings,
      ),
      _FeatureCard(
        key: const ValueKey('welcome-feature-3'),
        icon: Icons.person_outline,
        iconColor: SegColors.turquoise,
        label: l10n.noAccountNeeded,
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [title, const SizedBox(height: 8), subtitle],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              features[0],
              const SizedBox(height: 8),
              features[1],
              const SizedBox(height: 8),
              features[2],
            ],
          ),
        ),
      ],
    );
  }

  Widget _compact(BuildContext context, AppLocalizations l10n) {
    final pages = <Widget>[
      Text(l10n.welcomeTitle, style: SegText.display.copyWith(fontSize: 26)),
      Text(
        l10n.welcomeSubtitle,
        style: SegText.body.copyWith(color: SegColors.inkSoft),
      ),
      Text(l10n.noAdsOffline, style: SegText.label),
      Text(l10n.parentGateSettings, style: SegText.label),
      Text(l10n.noAccountNeeded, style: SegText.label),
    ];
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _count,
            itemBuilder: (context, i) =>
                Align(alignment: Alignment.centerLeft, child: pages[i]),
          ),
        ),
        const SizedBox(height: 8),
        Text('${_page + 1} / $_count', style: SegText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: MaterialLocalizations.of(context).previousPageTooltip,
                child: SegButton(
                  key: const ValueKey('welcome-previous'),
                  label: '\u2039',
                  onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SegButton(
                key: const ValueKey('welcome-start'),
                label: l10n.letsGetStarted,
                onPressed: widget.onContinue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: MaterialLocalizations.of(context).nextPageTooltip,
                child: SegButton(
                  key: const ValueKey('welcome-next'),
                  label: '\u203a',
                  onPressed: _page < _count - 1 ? () => _goTo(_page + 1) : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.state.locale);
    final compact = _useCompactPager(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: compact
                    ? _compact(context, l10n)
                    : _overview(MediaQuery.of(context).size, l10n),
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: SegButton(
                    key: const ValueKey('welcome-start'),
                    label: l10n.letsGetStarted,
                    onPressed: widget.onContinue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _FeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: SegText.label)),
          ],
        ),
      ),
    );
  }
}
