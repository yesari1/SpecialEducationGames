import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/content/content_repository.dart';
import '../../l10n/scoped_localizations.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.hasTodaySticker
                      ? l10n.dailyPathYouEarnedTodaysSticker
                      : l10n.dailyPathEachCompletedGameIsOneStep,
                  style: SegText.label.copyWith(color: SegColors.inkSoft),
                ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final compact = constraints.maxHeight < 340 || textScale >= 1.6;
              final nodeSize = compact
                  ? textScale >= 1.6
                        ? 44.0
                        : (constraints.maxHeight * .35).clamp(44.0, 72.0)
                  : 108.0;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                itemCount: progress.steps.length,
                separatorBuilder: (_, _) => Center(
                  child: Container(
                    width: 24,
                    height: 6,
                    decoration: BoxDecoration(
                      color: SegColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                itemBuilder: (context, index) {
                  final key = progress.steps[index];
                  final parts = key.split('_');
                  final theme = state.content.theme(parts[0]);
                  final game = state.content.game(parts[1]);
                  final done = progress.completed.contains(key);
                  final hero = state.content.items.firstWhere(
                    (x) => x.id == theme.hero,
                  );
                  return SizedBox(
                    width: compact ? (textScale >= 1.6 ? 400 : 240) : 194,
                    child: Semantics(
                      button: true,
                      label:
                          '${game.name(state.locale)}, ${theme.name(state.locale)}, ${done ? l10n.dailyPathCompleted : l10n.dailyPathPlay}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey('daily-step-$key'),
                          borderRadius: BorderRadius.circular(28),
                          onTap: () =>
                              context.go('/game/${parts[0]}/${parts[1]}/easy'),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: compact
                                ? Row(
                                    children: [
                                      _pathNode(hero, done, nodeSize),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.dailyPathStepTitle(
                                                index + 1,
                                                game.name(state.locale),
                                              ),
                                              style: SegText.label,
                                            ),
                                            Text(
                                              theme.name(state.locale),
                                              style: SegText.caption.copyWith(
                                                color: SegColors.inkSoft,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _pathNode(hero, done, nodeSize),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.dailyPathStepTitle(
                                          index + 1,
                                          game.name(state.locale),
                                        ),
                                        textAlign: TextAlign.center,
                                        style: SegText.label,
                                      ),
                                      Text(
                                        theme.name(state.locale),
                                        textAlign: TextAlign.center,
                                        style: SegText.caption.copyWith(
                                          color: SegColors.inkSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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

  Widget _pathNode(ContentItem hero, bool done, double nodeSize) => Container(
    width: nodeSize,
    height: nodeSize,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: done ? SegColors.star : SegColors.primarySoft,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1618334B),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: done
        ? Icon(
            Icons.star_rounded,
            size: nodeSize * .55,
            color: SegColors.starDeep,
          )
        : ItemVisual(hero),
  );
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
                                        Icon(
                                          Icons.workspace_premium_rounded,
                                          size: iconSize,
                                          color: SegColors.accent,
                                        ),
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
