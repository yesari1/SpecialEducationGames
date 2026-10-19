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
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: success || hinting ? 1 : 0),
                  duration: reduced ? SegMotion.tap : SegMotion.focus,
                  builder: (context, presence, _) => ObjectHalo(
                    key: success ? const ValueKey('choice-success-halo') : null,
                    color: success ? SegColors.successGlow : SegColors.hintGlow,
                    strength:
                        presence * (hinting ? .65 + breathe.value * .35 : 1),
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
