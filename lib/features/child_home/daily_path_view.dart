import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/day_sticker.dart';
import '../../l10n/scoped_localizations.dart';
import 'home_screen.dart' show gameIcon;

class DailyPathView extends StatelessWidget {
  final AppState state;
  const DailyPathView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final progress = state.dailyPath;
    if (progress.steps.isEmpty) {
      return Center(
        child: Text(
          l10n.dailyPathNoGamesAreAvailableToday,
          style: SegText.heading,
        ),
      );
    }
    final nextIndex = progress.steps.indexWhere(
      (x) => !progress.completed.contains(x),
    );
    return Column(
      children: [
        // Today's progress: one coloured segment per step, then the sticker.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < progress.steps.length; i++)
                      Expanded(
                        child: Container(
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color:
                                progress.completed.contains(progress.steps[i])
                                ? SegColors.turquoise
                                : i == nextIndex
                                ? SegColors.accent.withValues(alpha: .45)
                                : SegColors.line,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: SegSpace.s2),
              Icon(
                Icons.emoji_events_rounded,
                color: state.hasTodaySticker
                    ? SegColors.starDeep
                    : SegColors.inkFaint,
                size: 28,
              ),
              TextButton.icon(
                key: const ValueKey('sticker-album'),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(l10n.dailyPathMyStickers),
                onPressed: () => _album(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: HorizontalCards(
            count: progress.steps.length,
            builder: (index) {
              final key = progress.steps[index];
              final parts = key.split('_');
              final theme = state.content.theme(parts[0]);
              final game = state.content.game(parts[1]);
              final done = progress.completed.contains(key);
              final next = index == nextIndex;
              final hero = state.content.items.firstWhere(
                (x) => x.id == theme.hero,
              );
              final card = ThemeGameCard(
                theme: theme,
                title: game.name(state.locale),
                subtitle: '',
                badgeText: done
                    ? l10n.dailyPathCompleted
                    : l10n.dailyPathStepTitle(
                        index + 1,
                        theme.name(state.locale),
                      ),
                visual: done
                    ? const FittedBox(
                        child: Icon(Icons.star_rounded, color: SegColors.star),
                      )
                    : ItemVisual(hero, alignment: Alignment.bottomCenter),
                normalizedVisual: done,
                modeIcon: done ? Icons.check_rounded : gameIcon(game.id),
                onTap: () => context.go('/game/${parts[0]}/${parts[1]}/easy'),
              );
              return Semantics(
                key: ValueKey('daily-step-$key'),
                label:
                    '${game.name(state.locale)}, ${theme.name(state.locale)}, '
                    '${done ? l10n.dailyPathCompleted : l10n.dailyPathPlay}',
                child: next
                    // The step to play next glows orange.
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(SegRadius.lg + 4),
                          boxShadow: [
                            BoxShadow(
                              color: SegColors.accent.withValues(alpha: .45),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: card,
                      )
                    : card,
              );
            },
          ),
        ),
      ],
    );
  }

  void _album(BuildContext context) {
    final days = state.dailyStickers.toList()..sort((a, b) => b.compareTo(a));
    showDialog<void>(
      context: context,
      builder: (_) => StickerAlbumDialog(state: state, days: days),
    );
  }
}

class StickerAlbumDialog extends StatefulWidget {
  final AppState state;
  final List<String> days;
  const StickerAlbumDialog({
    super.key,
    required this.state,
    required this.days,
  });

  @override
  State<StickerAlbumDialog> createState() => _StickerAlbumDialogState();
}

class _StickerAlbumDialogState extends State<StickerAlbumDialog> {
  final PageController _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = scopedLocalizations(context, state.locale);
    final screen = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final pageSize = textScale >= 1.5 ? 2 : 3;
    final pageCount = widget.days.isEmpty
        ? 0
        : (widget.days.length + pageSize - 1) ~/ pageSize;
    final page = pageCount == 0 ? 0 : _page.clamp(0, pageCount - 1).toInt();
    final dialogHeight = (screen.height - 24).clamp(220.0, 600.0).toDouble();
    final dialogWidth = (screen.width - 32).clamp(280.0, 500.0).toDouble();
    final iconSize = dialogHeight < 380 ? 40.0 : 64.0;

    return Dialog(
      key: const ValueKey('sticker-album-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                l10n.dailyPathMyStickers,
                style: SegText.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: widget.days.isEmpty
                    ? Center(
                        child: Text(
                          l10n.dailyPathCompleteTodaysPathToEarnYourFirst,
                          textAlign: TextAlign.center,
                          style: SegText.body,
                        ),
                      )
                    : PageView.builder(
                        key: const ValueKey('sticker-album-pages'),
                        controller: _pages,
                        itemCount: pageCount,
                        onPageChanged: (value) => setState(() => _page = value),
                        itemBuilder: (context, pageIndex) {
                          final start = pageIndex * pageSize;
                          final end = (start + pageSize)
                              .clamp(0, widget.days.length)
                              .toInt();
                          final stickers = widget.days.sublist(start, end);
                          return Row(
                            children: [
                              for (final day in stickers)
                                Expanded(
                                  child: Semantics(
                                    label:
                                        '${l10n.dailyPathEarnedSticker}: $day',
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        DaySticker(day: day, size: iconSize),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            day,
                                            textAlign: TextAlign.center,
                                            style: SegText.caption,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              if (widget.days.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const ValueKey('sticker-album-previous'),
                      tooltip: l10n.dailyPathPreviousPage,
                      onPressed: page == 0
                          ? null
                          : () => _pages.previousPage(
                              duration: SegMotion.pageSlide,
                              curve: Curves.easeOutCubic,
                            ),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      l10n.dailyPathPageCurrentOfTotal(page + 1, pageCount),
                      key: const ValueKey('sticker-album-page-indicator'),
                      textAlign: TextAlign.center,
                      style: SegText.caption,
                    ),
                    IconButton(
                      key: const ValueKey('sticker-album-next'),
                      tooltip: l10n.dailyPathNextPage,
                      onPressed: page >= pageCount - 1
                          ? null
                          : () => _pages.nextPage(
                              duration: SegMotion.pageSlide,
                              curve: Curves.easeOutCubic,
                            ),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.dailyPathClose, style: SegText.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
