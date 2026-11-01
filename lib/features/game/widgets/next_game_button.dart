import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';

/// "Next game" after a round: a ring runs once around the button and the
/// next game opens when it closes. Tapping opens it at once. The ring waits
/// while [running] is false (the praise is still playing).
class NextGameButton extends StatefulWidget {
  final String label;
  final ValueNotifier<bool> running;
  final bool animate;
  final VoidCallback onNext;
  final Duration duration;
  const NextGameButton({
    super.key,
    required this.label,
    required this.running,
    required this.onNext,
    this.animate = true,
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<NextGameButton> createState() => _NextGameButtonState();
}

class _NextGameButtonState extends State<NextGameButton>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_filled);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    widget.running.addListener(_sync);
    _sync();
  }

  void _sync() {
    if (widget.running.value) {
      if (!_fill.isAnimating && !_done) _fill.forward();
      if (widget.animate && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _fill.reset();
      _pulse.reset();
      _done = false;
    }
  }

  void _filled(AnimationStatus status) {
    if (status == AnimationStatus.completed) _go();
  }

  void _go() {
    if (_done) return;
    _done = true;
    widget.onNext();
  }

  @override
  void dispose() {
    widget.running.removeListener(_sync);
    _fill.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_fill, _pulse]),
    builder: (context, child) => Transform.scale(
      scale: 1 + .04 * Curves.easeInOut.transform(_pulse.value),
      child: CustomPaint(
        foregroundPainter: _RingPainter(_fill.value),
        child: Padding(padding: const EdgeInsets.all(7), child: child),
      ),
    ),
    child: SegButton(
      label: widget.label,
      icon: Icons.play_arrow_rounded,
      onPressed: _go,
    ),
  );
}

/// A soft track around the button and a bright band growing clockwise from
/// the top centre, with a small glowing head.
class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    final shape = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(SegRadius.md + 4),
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = SegColors.star.withValues(alpha: .28);
    canvas.drawRRect(shape, track);
    if (progress <= 0) return;

    // Start at the top centre and run clockwise.
    final metric = (Path()..addRRect(shape)).computeMetrics().first;
    final start = _topCentre(metric, rect);
    final length = metric.length * progress;
    final band = Path();
    final first = math.min(length, metric.length - start);
    band.addPath(metric.extractPath(start, start + first), Offset.zero);
    if (length > first) {
      band.addPath(metric.extractPath(0, length - first), Offset.zero);
    }
    canvas.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [SegColors.star, SegColors.accent],
        ).createShader(rect),
    );
    final head = metric
        .getTangentForOffset((start + length) % metric.length)
        ?.position;
    if (head != null) {
      canvas.drawCircle(
        head,
        7,
        Paint()
          ..color = SegColors.star.withValues(alpha: .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(head, 4.5, Paint()..color = Colors.white);
    }
  }

  /// Distance along [metric] closest to the middle of the top edge.
  double _topCentre(PathMetric metric, Rect rect) {
    final target = Offset(rect.center.dx, rect.top);
    var best = 0.0, bestDistance = double.infinity;
    for (var d = 0.0; d < metric.length; d += 2) {
      final p = metric.getTangentForOffset(d)!.position;
      final distance = (p - target).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = d;
      }
    }
    return best;
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
