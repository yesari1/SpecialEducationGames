import 'package:flutter/material.dart';
import 'components.dart';
import '../theme/tokens.dart';
import '../../core/content/content_repository.dart';

enum ChoiceCardState { idle, hint, faded, correct, dismissed }

class ChoiceCard extends StatefulWidget {
  final ContentItem item;
  final String locale;
  final ChoiceCardState state;
  final int hintLevel, nudgeSerial;
  final bool showLabel, compact, visible, animate;
  final VoidCallback? onTap;
  final Widget? visual;
  const ChoiceCard({
    super.key,
    required this.item,
    required this.locale,
    this.state = ChoiceCardState.idle,
    this.hintLevel = 0,
    this.nudgeSerial = 0,
    this.showLabel = true,
    this.compact = false,
    this.visible = true,
    this.animate = true,
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
  bool get reduced =>
      MediaQuery.disableAnimationsOf(context) || !widget.animate;
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
  }

  @override
  void dispose() {
    breathe.dispose();
    nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final success = widget.state == ChoiceCardState.correct;
    final disabled =
        widget.state == ChoiceCardState.faded ||
        widget.state == ChoiceCardState.dismissed ||
        !widget.visible;
    final opacity = !widget.visible || widget.state == ChoiceCardState.dismissed
        ? 0.0
        : widget.state == ChoiceCardState.faded
        ? 0.25
        : 1.0;
    return ExcludeSemantics(
      excluding: !widget.visible || widget.state == ChoiceCardState.dismissed,
      child: AnimatedOpacity(
        duration: reduced ? SegMotion.tap : SegMotion.fadeHint,
        opacity: opacity,
        child: AnimatedBuilder(
          animation: Listenable.merge([breathe, nudge]),
          builder: (context, child) {
            final pulse = widget.state == ChoiceCardState.hint
                ? breathe.value * .06
                : 0.0;
            final punch = TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 0, end: .12), weight: 40),
              TweenSequenceItem(tween: Tween(begin: .12, end: 0), weight: 60),
            ]).transform(nudge.value);
            return AnimatedScale(
              duration: reduced ? SegMotion.tap : SegMotion.focus,
              scale: success && !reduced ? 1.06 : 1,
              child: Transform.scale(scale: 1 + pulse + punch, child: child),
            );
          },
          child: Semantics(
            button: true,
            label: widget.item.name(widget.locale),
            enabled: !disabled,
            child: Material(
              color: success
                  ? SegColors.successGlow
                  : widget.state == ChoiceCardState.hint
                  ? SegColors.hintGlow
                  : SegColors.surface,
              borderRadius: BorderRadius.circular(SegRadius.lg),
              child: InkWell(
                onTap: disabled ? null : widget.onTap,
                borderRadius: BorderRadius.circular(SegRadius.lg),
                child: Padding(
                  padding: EdgeInsets.all(
                    widget.compact ? SegSpace.s2 : SegSpace.s4,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: widget.visual ?? ItemVisual(widget.item),
                          ),
                          if (widget.showLabel)
                            ExcludeSemantics(
                              child: Text(
                                widget.item.name(widget.locale),
                                style: SegText.item,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (widget.hintLevel >= 3 && !success)
                            const Icon(
                              Icons.touch_app_rounded,
                              color: SegColors.ink,
                            ),
                        ],
                      ),
                      if (success)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: SegColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
