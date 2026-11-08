import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/day_sticker.dart';
import '../../l10n/scoped_localizations.dart';
import 'home_screen.dart' show gameIcon;

class DailyPathView extends StatelessWidget {
  final AppState state;

  /// The home screen paints the map behind the whole screen itself.
  final bool background;

  /// The home screen has its own stickers button in the top bar.
  final bool albumButton;
  const DailyPathView({
    super.key,
    required this.state,
    this.background = true,
    this.albumButton = true,
  });

  static const mapAsset = 'assets/illustrations/path/map_background.jpg';

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
    // A small adventure map: the day's games are stops on a winding road
    // across a sunny meadow, with the sticker waiting at the end.
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, background ? 12 : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(background ? SegRadius.xl : 0),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            final n = progress.steps.length;
            final stop = (h * .3).clamp(56.0, 130.0);
            Offset at(int i) => Offset(
              w * (.09 + .72 * (n == 1 ? 0 : i / (n - 1))),
              h * (i.isEven ? .44 : .72),
            );
            final points = [
              for (var i = 0; i < n; i++) at(i),
              Offset(w * .92, h * .5),
            ];
            return Stack(
              children: [
                if (background)
                  Positioned.fill(
                    child: Image.asset(
                      mapAsset,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, .15),
                      excludeFromSemantics: true,
                    ),
                  ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoadPainter(
                      points,
                      done: progress.steps
                          .takeWhile(progress.completed.contains)
                          .length,
                    ),
                  ),
                ),
                // The sticker at the end of the road.
                Positioned(
                  left: points.last.dx - stop * .45,
                  top: points.last.dy - stop * .45,
                  width: stop * .9,
                  height: stop * .9,
                  child: _Goal(earned: state.hasTodaySticker),
                ),
                for (var i = 0; i < n; i++)
                  Positioned(
                    left: points[i].dx - stop / 2,
                    top: points[i].dy - stop / 2,
                    width: stop,
                    height: stop,
                    child: _Stop(
                      key: ValueKey('daily-step-${progress.steps[i]}'),
                      state: state,
                      stepKey: progress.steps[i],
                      number: i + 1,
                      done: progress.completed.contains(progress.steps[i]),
                      next: i == nextIndex,
                    ),
                  ),
                if (albumButton)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: .9),
                      shape: const StadiumBorder(),
                      child: TextButton.icon(
                        key: const ValueKey('sticker-album'),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(l10n.dailyPathMyStickers),
                        onPressed: () => openAlbum(context, state),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static void openAlbum(BuildContext context, AppState state) {
    final days = state.dailyStickers.toList()..sort((a, b) => b.compareTo(a));
    showDialog<void>(
      context: context,
      builder: (_) => StickerAlbumDialog(state: state, days: days),
    );
  }
}

/// The sandy road through the stops; the part already walked is golden.
class _RoadPainter extends CustomPainter {
  final List<Offset> points;
  final int done;
  _RoadPainter(this.points, {required this.done});

  Path _through(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final mid = (b.dx - a.dx) / 2;
      path.cubicTo(a.dx + mid, a.dy, b.dx - mid, b.dy, b.dx, b.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final road = _through(points);
    final width = (size.height * .085).clamp(16.0, 34.0);
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFFC79A5B)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width + 6,
    );
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0xFFF3D9A4)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width,
    );
    if (done > 0) {
      canvas.drawPath(
        _through(points.take(done + 1).toList()),
        Paint()
          ..color = SegColors.star
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width * .45,
      );
    }
    // Little white stepping dashes along the middle of the road.
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width * .16;
    for (final metric in road.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += width * 1.4) {
        canvas.drawPath(metric.extractPath(d, d + width * .5), dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) =>
      old.points != points || old.done != done;
}

/// One stop on the road: the game's picture in a round badge with its
/// number; a star once played; the next one bobs gently and says "Play".
class _Stop extends StatefulWidget {
  final AppState state;
  final String stepKey;
  final int number;
  final bool done, next;
  const _Stop({
    super.key,
    required this.state,
    required this.stepKey,
    required this.number,
    required this.done,
    required this.next,
  });
  @override
  State<_Stop> createState() => _StopState();
}

class _StopState extends State<_Stop> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Stop old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.next && !widget.state.reducedMotion) {
      // A few gentle bobs, then it rests (calm, and the screen can idle).
      if (!_bob.isAnimating && _bob.value == 0) {
        _bob.repeat(reverse: true, count: 6);
      }
    } else {
      _bob.stop();
      _bob.value = 0;
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    final parts = widget.stepKey.split('_');
    final theme = s.content.theme(parts[0]);
    final game = s.content.game(parts[1]);
    final hero = s.content.items.firstWhere((x) => x.id == theme.hero);
    final ring = widget.done
        ? SegColors.star
        : widget.next
        ? SegColors.accent
        : Colors.white;
    return Semantics(
      button: true,
      label:
          '${game.name(s.locale)}, ${theme.name(s.locale)}, '
          '${widget.done ? l10n.dailyPathCompleted : l10n.dailyPathPlay}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          UiSound.gameOpen();
          context.go('/game/${parts[0]}/${parts[1]}/easy?from=path');
        },
        child: AnimatedBuilder(
          animation: _bob,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -6 * Curves.easeInOut.transform(_bob.value)),
            child: child,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final size = box.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: ring, width: size * .07),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (widget.next ? SegColors.accent : SegColors.ink)
                                    .withValues(alpha: widget.next ? .4 : .18),
                            blurRadius: widget.next ? 16 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(size * .12),
                      child: ItemVisual(hero),
                    ),
                  ),
                  // Step number flag.
                  Positioned(
                    left: -size * .04,
                    top: -size * .04,
                    child: Container(
                      width: size * .34,
                      height: size * .34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.done ? SegColors.turquoise : theme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: widget.done
                          ? Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: size * .22,
                            )
                          : Text(
                              '${widget.number}',
                              style: SegText.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: size * .18,
                              ),
                            ),
                    ),
                  ),
                  if (widget.next)
                    Positioned(
                      left: -size,
                      right: -size,
                      bottom: -size * .2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: SegColors.accent,
                            borderRadius: BorderRadius.circular(SegRadius.pill),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                gameIcon(game.id),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.dailyPathPlay,
                                style: SegText.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The sticker waiting at the end of the road.
class _Goal extends StatelessWidget {
  final bool earned;
  const _Goal({required this.earned});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: earned
            ? const [Color(0xFFFFE08A), SegColors.star]
            : const [Colors.white, Color(0xFFFFF1D6)],
      ),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: SegColors.starDeep.withValues(alpha: .3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: FractionallySizedBox(
      widthFactor: .62,
      heightFactor: .62,
      child: FittedBox(
        child: Icon(
          Icons.emoji_events_rounded,
          color: earned ? SegColors.starDeep : const Color(0xFFE0B04A),
        ),
      ),
    ),
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
