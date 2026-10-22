import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../theme/tokens.dart';

/// Soft elliptical shadow that makes a cutout look like it stands on the scene.
/// [lift] (0..1) shrinks and fades the shadow while the object hops upward.
class GroundShadow extends StatelessWidget {
  final double lift;
  const GroundShadow({super.key, this.lift = 0});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GroundShadowPainter(lift.clamp(0.0, 1.0)));
}

class _GroundShadowPainter extends CustomPainter {
  final double lift;
  const _GroundShadowPainter(this.lift);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = 1 - lift * .35;
    // Paint a unit circle stretched into an ellipse so the gradient follows it.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 2 * scale, size.height / 2 * scale);
    final fade = 1 - lift * .6;
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            SegColors.ink.withValues(alpha: .18 * fade),
            SegColors.ink.withValues(alpha: .08 * fade),
            SegColors.ink.withValues(alpha: 0),
          ],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroundShadowPainter old) => old.lift != lift;
}

/// A soft round glow behind an object (hint = warm, success = mint).
class ObjectHalo extends StatelessWidget {
  final Color color;
  final double strength;
  const ObjectHalo({super.key, required this.color, this.strength = 1});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _HaloPainter(color, strength.clamp(0.0, 1.0)),
      size: Size.infinite,
    ),
  );
}

class _HaloPainter extends CustomPainter {
  final Color color;
  final double strength;
  const _HaloPainter(this.color, this.strength);
  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0 || size.isEmpty) return;
    final radius = size.shortestSide * .62;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    canvas.drawCircle(
      rect.center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .95 * strength),
            color.withValues(alpha: .55 * strength),
            color.withValues(alpha: 0),
          ],
          stops: const [0, .55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.color != color || old.strength != strength;
}

/// Wraps any visual so it reacts to touch like a physical object: it squashes
/// down while pressed and springs back on release. No ripple, no fill.
class PressableObject extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool reducedMotion;

  /// Plays the bubble tap; off where a card makes its own sound.
  final bool tapSound;
  final Alignment pivot;

  /// 1 = full squash for small objects; lower for large cards.
  final double depth;
  const PressableObject({
    super.key,
    required this.child,
    this.onTap,
    this.reducedMotion = false,
    this.tapSound = true,
    this.pivot = Alignment.bottomCenter,
    this.depth = 1,
  });
  @override
  State<PressableObject> createState() => _PressableObjectState();
}

class _PressableObjectState extends State<PressableObject>
    with SingleTickerProviderStateMixin {
  late final AnimationController press = AnimationController(
    vsync: this,
    duration: SegMotion.tap,
    reverseDuration: const Duration(milliseconds: 320),
  );

  bool get reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  void _down() {
    if (widget.onTap == null || reduced) return;
    press.forward();
  }

  void _up() {
    if (press.value > 0 || press.isAnimating) press.reverse();
  }

  @override
  void dispose() {
    press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    // Without a handler the object advertises no tap action to screen readers.
    onTapDown: widget.onTap == null ? null : (_) => _down(),
    onTapUp: widget.onTap == null ? null : (_) => _up(),
    onTapCancel: widget.onTap == null ? null : _up,
    onTap: widget.onTap == null
        ? null
        : () {
            if (widget.tapSound) UiSound.tap();
            widget.onTap!();
          },
    child: AnimatedBuilder(
      animation: press,
      child: widget.child,
      builder: (context, child) {
        final t = press.status == AnimationStatus.reverse
            ? 1 - const ElasticOutCurve(.6).transform(1 - press.value)
            : Curves.easeOut.transform(press.value);
        return Transform(
          alignment: widget.pivot,
          transform: Matrix4.diagonal3Values(
            1 + .06 * t * widget.depth,
            1 - .1 * t * widget.depth,
            1,
          ),
          child: child,
        );
      },
    ),
  );
}

/// One-shot reactions shared by game objects.
abstract final class ObjectMotion {
  /// Happy hop: 0 → up → small bounce → rest. Returns upward offset factor.
  static double hop(double t) {
    if (t <= 0 || t >= 1) return 0;
    if (t < .45) return Curves.easeOut.transform(t / .45);
    if (t < .75) return 1 - Curves.easeIn.transform((t - .45) / .3);
    return math.sin((t - .75) / .25 * math.pi) * .18;
  }

  /// Gentle "no" shake that settles: returns a horizontal offset factor.
  static double shake(double t) {
    if (t <= 0 || t >= 1) return 0;
    return math.sin(t * math.pi * 4) * (1 - t);
  }
}

/// Places a visual on the scene: a ground shadow below and an optional glow.
class StagedObject extends StatelessWidget {
  final Widget child;
  final Color? glow;
  const StagedObject({super.key, required this.child, this.glow});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            duration: SegMotion.focus,
            opacity: glow == null ? 0 : 1,
            child: ObjectHalo(color: glow ?? SegColors.hintGlow, strength: .8),
          ),
        ),
        Positioned(
          left:
              (box.maxWidth -
                  math.min(box.maxWidth * .56, box.maxHeight * .7)) /
              2,
          width: math.min(box.maxWidth * .56, box.maxHeight * .7),
          bottom: 0,
          height: box.maxHeight * .1,
          child: const GroundShadow(),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: box.maxHeight * .07),
          child: child,
        ),
      ],
    ),
  );
}

/// The item name shown under a staged object: soft white pill, no button look.
class ObjectLabel extends StatelessWidget {
  final String text;
  final TextStyle style;
  const ObjectLabel(this.text, {super.key, this.style = SegText.title});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: SegSpace.s4,
      vertical: SegSpace.s1,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(SegRadius.pill),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: style.copyWith(color: SegColors.ink),
    ),
  );
}
