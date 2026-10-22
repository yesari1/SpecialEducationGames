import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'components.dart';
import 'game_object.dart';
import '../theme/tokens.dart';
import '../../core/content/content_repository.dart';

enum ChoiceCardState { idle, hint, faded, correct, dismissed }

/// A tappable answer in a game round. It is drawn as an object standing on the
/// scene (cutout + ground shadow), not as a button: it squashes when pressed,
/// glows for hints, hops when correct and gives a small shake when it was a
/// wrong pick. The name stays `ChoiceCard` for the existing round contracts.
class ChoiceCard extends StatefulWidget {
  final ContentItem item;
  final String locale;
  final ChoiceCardState state;
  final int hintLevel, nudgeSerial, shakeSerial;
  final bool showLabel, compact, visible, animate;
  final Duration appearDelay;
  final VoidCallback? onTap;
  final Widget? visual;
  const ChoiceCard({
    super.key,
    required this.item,
    required this.locale,
    this.state = ChoiceCardState.idle,
    this.hintLevel = 0,
    this.nudgeSerial = 0,
    this.shakeSerial = 0,
    this.showLabel = true,
    this.compact = false,
    this.visible = true,
    this.animate = true,
    this.appearDelay = Duration.zero,
    this.onTap,
    this.visual,
  });
  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard> with TickerProviderStateMixin {
  late final AnimationController breathe = AnimationController(
    vsync: this,
    duration: SegMotion.breathe,
  );
  late final AnimationController nudge = AnimationController(
    vsync: this,
    duration: SegMotion.nudge,
  );
  late final AnimationController hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final AnimationController shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final AnimationController appear = AnimationController(
    vsync: this,
    duration: SegMotion.appear + widget.appearDelay,
    value: widget.animate ? 0 : 1,
  );
  bool get reduced =>
      MediaQuery.disableAnimationsOf(context) || !widget.animate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (appear.value == 0 && !appear.isAnimating) {
      if (reduced) {
        appear.value = 1;
      } else {
        appear.forward();
      }
    }
  }

  @override
  void didUpdateWidget(ChoiceCard old) {
    super.didUpdateWidget(old);
    if (widget.state == ChoiceCardState.hint &&
        old.state != ChoiceCardState.hint &&
        !reduced) {
      breathe.repeat(reverse: true, count: 6);
    }
    if (widget.state != ChoiceCardState.hint) {
      breathe.stop();
      breathe.value = 0;
    }
    if (widget.nudgeSerial != old.nudgeSerial &&
        widget.nudgeSerial > 0 &&
        !reduced) {
      nudge.forward(from: 0);
    }
    if (widget.state == ChoiceCardState.correct &&
        old.state != ChoiceCardState.correct &&
        !reduced) {
      hop.forward(from: 0);
    }
    if (widget.shakeSerial != old.shakeSerial &&
        widget.shakeSerial > 0 &&
        !reduced) {
      shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    breathe.dispose();
    nudge.dispose();
    hop.dispose();
    shake.dispose();
    appear.dispose();
    super.dispose();
  }

  static final _punch = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: .12), weight: 40),
    TweenSequenceItem(tween: Tween(begin: .12, end: 0), weight: 60),
  ]);

  @override
  Widget build(BuildContext context) {
    final success = widget.state == ChoiceCardState.correct;
    final hinting = widget.state == ChoiceCardState.hint;
    final disabled =
        widget.state == ChoiceCardState.faded ||
        widget.state == ChoiceCardState.dismissed ||
        !widget.visible;
    final opacity = !widget.visible || widget.state == ChoiceCardState.dismissed
        ? 0.0
        : widget.state == ChoiceCardState.faded
        ? 0.25
        : 1.0;
    final appearDelayFraction = appear.duration!.inMicroseconds == 0
        ? 0.0
        : widget.appearDelay.inMicroseconds / appear.duration!.inMicroseconds;
    final appearCurve = CurvedAnimation(
      parent: appear,
      curve: Interval(appearDelayFraction, 1, curve: Curves.easeOutBack),
    );

    Widget object = AnimatedBuilder(
      animation: Listenable.merge([breathe, nudge, hop, shake, appear]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final pulse = hinting ? breathe.value * .06 : 0.0;
          final punch = _punch.transform(nudge.value);
          final lift = ObjectMotion.hop(hop.value);
          final sway = ObjectMotion.shake(shake.value);
          final grow = appearCurve.value;
          final shadowWidth = math.min(box.maxWidth * .64, box.maxHeight * .8);
          final visual = Padding(
            padding: EdgeInsets.fromLTRB(
              box.maxWidth * .04,
              box.maxHeight * .02,
              box.maxWidth * .04,
              box.maxHeight * .09,
            ),
            child:
                widget.visual ??
                ItemVisual(widget.item, alignment: Alignment.bottomCenter),
          );
          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              // Hints glow softly; a correct answer gets a small burst of
              // coloured sparkles behind it instead of a green glow.
              if (!success)
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: hinting ? 1 : 0),
                    duration: reduced ? SegMotion.tap : SegMotion.focus,
                    builder: (context, presence, _) => ObjectHalo(
                      color: SegColors.hintGlow,
                      strength: presence * (.65 + breathe.value * .35),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey('choice-success-halo'),
                      painter: _SparkleBurst(reduced ? 1 : hop.value),
                    ),
                  ),
                ),
              Positioned(
                left: (box.maxWidth - shadowWidth) / 2,
                width: shadowWidth,
                bottom: box.maxHeight * .03,
                height: box.maxHeight * .14,
                child: GroundShadow(lift: lift),
              ),
              Transform.translate(
                offset: Offset(
                  sway * box.maxWidth * .05,
                  -lift * box.maxHeight * .16,
                ),
                child: Opacity(
                  opacity: 1 - (sway.abs() * .35),
                  child: Transform.scale(
                    alignment: Alignment.bottomCenter,
                    scale: (.6 + .4 * grow) * (1 + pulse + punch),
                    child: visual,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return ExcludeSemantics(
      excluding: !widget.visible || widget.state == ChoiceCardState.dismissed,
      child: AnimatedOpacity(
        duration: reduced ? SegMotion.tap : SegMotion.fadeHint,
        opacity: opacity,
        child: Semantics(
          button: true,
          label: widget.item.name(widget.locale),
          enabled: !disabled,
          child: PressableObject(
            onTap: disabled ? null : widget.onTap,
            reducedMotion: reduced,
            child: Padding(
              padding: EdgeInsets.all(
                widget.compact ? SegSpace.s1 : SegSpace.s2,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedScale(
                      duration: reduced ? SegMotion.tap : SegMotion.focus,
                      curve: Curves.easeOutCubic,
                      scale: success && !reduced ? 1.08 : 1,
                      child: object,
                    ),
                  ),
                  if (widget.showLabel)
                    ExcludeSemantics(
                      child: Text(
                        widget.item.name(widget.locale),
                        style: SegText.item.copyWith(
                          color: SegColors.ink,
                          shadows: const [
                            Shadow(color: Colors.white, blurRadius: 6),
                            Shadow(color: Colors.white, blurRadius: 2),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (widget.hintLevel >= 3 && !success)
                    const Icon(
                      Icons.touch_app_rounded,
                      color: SegColors.accentDeep,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short burst of small coloured sparkles flying out from behind the
/// object (progress 0 → 1), then gone. Calm: few, soft, quick.
class _SparkleBurst extends CustomPainter {
  final double progress;
  _SparkleBurst(this.progress);

  static const _colors = [
    SegColors.star,
    SegColors.accent,
    SegColors.turquoise,
    Color(0xFFE76F8E),
    SegColors.sky,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final t = Curves.easeOutCubic.transform(progress);
    final fade = 1 - Curves.easeIn.transform(progress);
    final center = Offset(size.width / 2, size.height * .5);
    final reach = math.min(size.width, size.height) * .62;
    const count = 14;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count + (i.isEven ? .12 : -.12);
      final distance = reach * (.55 + .6 * t) * (i.isEven ? 1 : .82);
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      final radius = (i.isEven ? 10.0 : 7.0) * (1.15 - .45 * t);
      if (i % 3 == 0) {
        // A tiny four-pointed star.
        final star = Path();
        for (var k = 0; k < 8; k++) {
          final a = k * math.pi / 4;
          final r = k.isEven ? radius * 1.6 : radius * .55;
          final point = position + Offset(math.cos(a), math.sin(a)) * r;
          k == 0
              ? star.moveTo(point.dx, point.dy)
              : star.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(star..close(), paint);
      } else {
        canvas.drawCircle(position, radius, paint);
      }
    }
    // A soft white ring that widens once.
    canvas.drawCircle(
      center,
      reach * (.3 + .55 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade
        ..color = Colors.white.withValues(alpha: .8 * fade),
    );
  }

  @override
  bool shouldRepaint(covariant _SparkleBurst old) => old.progress != progress;
}
