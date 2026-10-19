import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A calm, static pastel scene: soft sky wash, two rounded clouds, faint
/// corner blobs and gentle hills along the bottom. Nothing moves, so it stays
/// low-stimulation; [tint] is the theme accent, [base] the very light floor.
class SceneBackdrop extends StatelessWidget {
  final Color tint;
  final Color base;
  final Widget child;
  final bool hills, clouds;
  const SceneBackdrop({
    super.key,
    required this.child,
    this.tint = SegColors.turquoise,
    this.base = SegColors.canvas,
    this.hills = true,
    this.clouds = true,
  });
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: ScenePainter(
                tint: tint,
                base: base,
                hills: hills,
                clouds: clouds,
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class ScenePainter extends CustomPainter {
  final Color tint, base;
  final bool hills, clouds;
  const ScenePainter({
    required this.tint,
    required this.base,
    this.hills = true,
    this.clouds = true,
  });

  Color _mix(double amount) => Color.lerp(base, tint, amount)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final full = Offset.zero & size;
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(base, SegColors.sky, .10)!, base],
        ).createShader(full),
    );

    // Faint corner blobs give colour without drawing attention.
    void blob(Offset c, double r, Color color) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    blob(Offset(w * .02, h * .05), h * .55, tint.withValues(alpha: .10));
    blob(
      Offset(w * .98, h * .12),
      h * .45,
      SegColors.accent.withValues(alpha: .07),
    );

    if (clouds) {
      final cloud = Paint()..color = Colors.white.withValues(alpha: .9);
      void puff(double x, double y, double s) {
        final r = h * .055 * s;
        final c = Offset(w * x, h * y);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c + Offset(0, r * .35),
              width: r * 4.4,
              height: r * 1.3,
            ),
            Radius.circular(r),
          ),
          cloud,
        );
        canvas.drawCircle(c + Offset(-r * 1.0, r * .1), r * .85, cloud);
        canvas.drawCircle(c + Offset(r * .15, -r * .25), r * 1.15, cloud);
        canvas.drawCircle(c + Offset(r * 1.2, r * .2), r * .75, cloud);
      }

      puff(.2, .2, 1);
      puff(.8, .3, .8);
    }

    if (hills) {
      final back = Path()
        ..moveTo(0, h * .80)
        ..cubicTo(w * .18, h * .70, w * .36, h * .74, w * .52, h * .80)
        ..cubicTo(w * .68, h * .86, w * .84, h * .72, w, h * .76)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(back, Paint()..color = _mix(.16));
      final front = Path()
        ..moveTo(0, h * .90)
        ..cubicTo(w * .22, h * .82, w * .45, h * .95, w * .66, h * .88)
        ..cubicTo(w * .82, h * .83, w * .92, h * .86, w, h * .89)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(front, Paint()..color = _mix(.26));
    }
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      old.tint != tint ||
      old.base != base ||
      old.hills != hills ||
      old.clouds != clouds;
}
