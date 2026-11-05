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

/// One day of the 7-day plan: the first days as full rows, the rest compact.
class PlanDayRow extends StatelessWidget {
  final String day, theme, games;
  final bool compact;
  final Color tint;
  const PlanDayRow({
    super.key,
    required this.day,
    required this.theme,
    required this.games,
    required this.tint,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = Container(
      width: compact ? 64 : 72,
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : SegSpace.s1),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(SegRadius.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        day,
        style: SegText.caption.copyWith(
          color: SegColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SegSpace.s2),
        child: Row(
          children: [
            label,
            const SizedBox(width: SegSpace.s3),
            Expanded(
              child: Text(
                '$theme · $games',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SegText.caption.copyWith(color: SegColors.inkSoft),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: SegSpace.s2),
      padding: const EdgeInsets.symmetric(
        horizontal: SegSpace.s3,
        vertical: SegSpace.s3,
      ),
      decoration: BoxDecoration(
        color: SegColors.surface,
        borderRadius: BorderRadius.circular(SegRadius.md),
        border: Border.all(color: SegColors.line),
      ),
      child: Row(
        children: [
          label,
          const SizedBox(width: SegSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme,
                  style: SegText.label.copyWith(
                    color: SegColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  games,
                  maxLines: 1,
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
