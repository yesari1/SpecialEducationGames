import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

/// Mascot spot on the onboarding framing pages (welcome, plan building,
/// plan ready). [asset] null keeps the spot empty; the final mascot art
/// replaces [mascotCloud] later.
class MascotSlot extends StatelessWidget {
  /// The cloud character of the app icon (transparent launcher foreground).
  static const mascotCloud = 'assets/illustrations/onboarding/mascot_cloud.png';

  final String? asset;
  final double height;
  const MascotSlot({super.key, this.asset = mascotCloud, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final image = asset;
    if (image == null) {
      return const SizedBox.shrink(key: ValueKey('mascot-slot'));
    }
    return SizedBox(
      key: const ValueKey('mascot-slot'),
      height: height,
      child: Image.asset(
        image,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// "Building the plan": a soft progress bar and the parent's answers ticked
/// one by one, then [onDone] after [duration]. Reduced motion shows every
/// line ticked at once and still waits, so the page can be read.
class PlanBuildingView extends StatefulWidget {
  final List<String> lines;
  final bool reduced;
  final Duration duration;
  final VoidCallback onDone;
  const PlanBuildingView({
    super.key,
    required this.lines,
    required this.reduced,
    required this.onDone,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<PlanBuildingView> createState() => _PlanBuildingViewState();
}

class _PlanBuildingViewState extends State<PlanBuildingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController progress = AnimationController(
    vsync: this,
    // The bar is full a little before the page moves on.
    duration: widget.duration * 0.9,
  );
  Timer? _done;

  @override
  void initState() {
    super.initState();
    widget.reduced ? progress.value = 1 : progress.forward();
    _done = Timer(widget.duration, widget.onDone);
  }

  @override
  void dispose() {
    _done?.cancel();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, _) {
      final n = widget.lines.length;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SegRadius.pill),
            child: LinearProgressIndicator(
              key: const ValueKey('plan-progress'),
              value: progress.value,
              minHeight: 10,
              backgroundColor: SegColors.primarySoft,
              color: SegColors.turquoise,
            ),
          ),
          const SizedBox(height: SegSpace.s5),
          for (var i = 0; i < n; i++)
            _PlanLine(
              key: ValueKey('plan-line-$i'),
              text: widget.lines[i],
              // Line i is ticked once the bar passes its share.
              done: progress.value >= (i + 1) / (n + 0.4),
            ),
        ],
      );
    },
  );
}

class _PlanLine extends StatelessWidget {
  final String text;
  final bool done;
  const _PlanLine({super.key, required this.text, required this.done});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: SegSpace.s3),
    child: Row(
      children: [
        AnimatedContainer(
          duration: SegMotion.appear,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? SegColors.turquoise : SegColors.surfaceMuted,
            border: Border.all(
              color: done ? SegColors.turquoise : SegColors.line,
              width: 2,
            ),
          ),
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  key: ValueKey('plan-check'),
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
        const SizedBox(width: SegSpace.s3),
        Expanded(
          child: AnimatedOpacity(
            duration: SegMotion.appear,
            opacity: done ? 1 : 0.55,
            child: Text(
              text,
              style: SegText.body.copyWith(
                color: SegColors.ink,
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// One day of the 7-day plan. Every day is the same row: a coloured day
/// badge, the theme's home-card picture, the theme name and its games.
/// [today] (day 1) adds a "Today" chip and a soft tint. [height] fixes the
/// row height (rows share the page evenly); null keeps the natural height
/// (large text, the page scrolls).
class PlanDayRow extends StatelessWidget {
  final String day, theme, games;
  final Color tint;
  final Widget thumbnail;
  final String? today;
  final double? height;
  const PlanDayRow({
    super.key,
    required this.day,
    required this.theme,
    required this.games,
    required this.tint,
    required this.thumbnail,
    this.today,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final fixed = height != null;
    final thumb = fixed ? (height! - 2 * SegSpace.s2).clamp(36.0, 52.0) : 52.0;
    final chip = today;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(
        horizontal: SegSpace.s3,
        vertical: SegSpace.s2,
      ),
      decoration: BoxDecoration(
        color: chip != null
            ? Color.lerp(SegColors.surface, SegColors.primary, .06)
            : SegColors.surface,
        borderRadius: BorderRadius.circular(SegRadius.md),
        border: Border.all(
          color: chip != null
              ? SegColors.primary.withValues(alpha: .45)
              : SegColors.line,
          width: chip != null ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 60),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SegSpace.s2,
                vertical: SegSpace.s1,
              ),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(SegRadius.xs),
              ),
              child: Text(
                day,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: SegText.caption.copyWith(
                  color: SegColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: SegSpace.s3),
          SizedBox.square(dimension: thumb, child: thumbnail),
          const SizedBox(width: SegSpace.s3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        theme,
                        maxLines: fixed ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: SegText.label.copyWith(
                          color: SegColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (chip != null) ...[
                      const SizedBox(width: SegSpace.s2),
                      Container(
                        key: const ValueKey('plan-today'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: SegSpace.s2,
                        ),
                        decoration: BoxDecoration(
                          color: SegColors.primary,
                          borderRadius: BorderRadius.circular(SegRadius.pill),
                        ),
                        child: Text(
                          chip,
                          maxLines: 1,
                          style: SegText.caption.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  games,
                  maxLines: fixed ? 1 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: SegText.caption.copyWith(color: SegColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The plan page body: the mascot beside the title, then the seven days.
/// At normal text size the rows share the height evenly (no scrolling);
/// large text or a very short screen keeps the rows readable and scrolls.
class PlanReadyBody extends StatelessWidget {
  final Widget title;
  final int count;
  final Widget Function(int index, double? height) day;
  const PlanReadyBody({
    super.key,
    required this.title,
    required this.count,
    required this.day,
  });

  static const _minRow = 56.0, _maxRow = 80.0, _gap = SegSpace.s2;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        const MascotSlot(height: 68),
        const SizedBox(width: SegSpace.s3),
        Expanded(child: title),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return SingleChildScrollView(
        key: const ValueKey('plan-scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: SegSpace.s4),
            for (var i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: _gap),
                child: day(i, null),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: SegSpace.s4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final share = (box.maxHeight - (count - 1) * _gap) / count;
              if (share < _minRow) {
                return ListView(
                  key: const ValueKey('plan-scroll'),
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < count; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _gap),
                        child: day(i, _minRow),
                      ),
                  ],
                );
              }
              final row = share.clamp(_minRow, _maxRow);
              // Space left by full-height rows goes evenly between them.
              final gap = count < 2
                  ? 0.0
                  : ((box.maxHeight - count * row) / (count - 1)).clamp(
                      _gap,
                      SegSpace.s5,
                    );
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    day(i, row),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
