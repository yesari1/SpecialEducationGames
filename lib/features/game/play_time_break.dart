import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/scene_backdrop.dart';
import '../family/parent_gate.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

class PlayTimeBreak extends StatefulWidget {
  final AppState state;
  const PlayTimeBreak({super.key, required this.state});

  @override
  State<PlayTimeBreak> createState() => _PlayTimeBreakState();
}

class _PlayTimeBreakState extends State<PlayTimeBreak> {
  late final PageController _pages = PageController();
  int _page = 0;
  AppState get state => widget.state;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SceneBackdrop(
      tint: SegColors.sky,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final strings = scopedLocalizations(context, state.locale);
            final compact = constraints.maxHeight < 500;
            final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
            final summary = _summary(strings, compact);
            final actions = _actions(context, strings);

            if (compact && largeText) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        key: const ValueKey('time-limit-pages'),
                        controller: _pages,
                        onPageChanged: (page) => setState(() => _page = page),
                        children: [summary, actions],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          key: const ValueKey('time-limit-previous'),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: strings.gamePreviousPage,
                          onPressed: _page == 0 ? null : () => _goToPage(0),
                        ),
                        Text(
                          strings.playTimeBreakPageCount(_page + 1, 2),
                          key: const ValueKey('time-limit-page-indicator'),
                          style: SegText.caption,
                        ),
                        IconButton(
                          key: const ValueKey('time-limit-next'),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: strings.gameNextPage,
                          onPressed: _page == 1 ? null : () => _goToPage(1),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(SegSpace.s4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            _RestSun(size: compact ? 72 : 112),
                            const SizedBox(width: SegSpace.s4),
                            Expanded(child: _breakText(strings)),
                          ],
                        ),
                      ),
                      const SizedBox(width: SegSpace.s5),
                      Expanded(flex: 2, child: actions),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _summary(AppLocalizations strings, bool compact) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: Row(
        children: [
          _RestSun(size: compact ? 72 : 112),
          const SizedBox(width: SegSpace.s4),
          Expanded(child: _breakText(strings)),
        ],
      ),
    ),
  );

  Widget _breakText(AppLocalizations strings) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        strings.playTimeBreakTitle,
        style: SegText.title,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: SegSpace.s3),
      Text(
        strings.playTimeBreakSubtitle,
        style: SegText.item,
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _actions(BuildContext context, AppLocalizations strings) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegButton(
              key: const ValueKey('time-limit-home'),
              label: strings.playTimeHome,
              onPressed: () => context.go('/'),
            ),
          ),
          const SizedBox(height: SegSpace.s4),
          SizedBox(
            width: double.infinity,
            child: HoldButton(
              key: const ValueKey('time-limit-extend'),
              semanticsLabel: strings.playTimeExtendHint,
              onHeld: () async {
                if (!await showParentGate(context, state) || !context.mounted) {
                  return;
                }
                await state.extendPlayTime();
                if (context.mounted) context.go('/');
              },
              child: Padding(
                padding: const EdgeInsets.all(SegSpace.s4),
                child: Text(strings.playTimeExtend, style: SegText.item),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _goToPage(int page) {
    _pages.animateToPage(
      page,
      duration: SegMotion.pageSlide,
      curve: Curves.easeOutCubic,
    );
  }
}

/// A calm resting sun in a soft halo: the break screen's illustration.
class _RestSun extends StatelessWidget {
  final double size;
  const _RestSun({required this.size});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            SegColors.star.withValues(alpha: .45),
            SegColors.star.withValues(alpha: .12),
          ],
        ),
        border: Border.all(color: Colors.white, width: size * .06),
      ),
      child: Icon(
        Icons.wb_sunny_rounded,
        size: size * .5,
        color: SegColors.starDeep,
      ),
    ),
  );
}
