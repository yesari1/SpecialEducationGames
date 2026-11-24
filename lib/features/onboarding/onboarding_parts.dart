import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/ambient_motion.dart';
import '../../app/ui/scene_backdrop.dart';

/// Progress as small dots; the current step is a longer pill.
class OnboardingDots extends StatelessWidget {
  final int index, count;
  final String label;
  const OnboardingDots({
    super.key,
    required this.index,
    required this.count,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: SegMotion.appear,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= index ? SegColors.primary : SegColors.line,
                borderRadius: BorderRadius.circular(SegRadius.pill),
              ),
            ),
        ],
      ),
    ),
  );
}

class FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const FeatureLine({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SegSpace.s2),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFDDF6F3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: SegColors.turquoiseDeep, size: 22),
        ),
        const SizedBox(width: SegSpace.s3),
        Expanded(
          child: Text(text, style: SegText.body.copyWith(color: SegColors.ink)),
        ),
      ],
    ),
  );
}

/// Shared selectable surface for parent-facing choices: white, rounded,
/// a clear blue ring and check when chosen.
class _ChoiceSurface extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final double minHeight;
  const _ChoiceSurface({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(SegSpace.s3),
    this.minHeight = 56,
  });
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: SegMotion.tap,
    constraints: BoxConstraints(minHeight: minHeight),
    decoration: BoxDecoration(
      color: selected ? SegColors.primarySoft : SegColors.surface,
      borderRadius: BorderRadius.circular(SegRadius.md),
      border: Border.all(
        color: selected ? SegColors.primary : SegColors.line,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: SegColors.ink.withValues(alpha: selected ? .08 : .04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(SegRadius.md),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Girl or boy: the child the games about a child show (Ayşe or Ali).
class GenderChoice extends StatelessWidget {
  /// 'girl', 'boy' or null when nothing is chosen yet.
  final String? value;
  final ValueChanged<String> onChanged;
  final String girlLabel, boyLabel;
  const GenderChoice({
    super.key,
    required this.value,
    required this.onChanged,
    required this.girlLabel,
    required this.boyLabel,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (id, label) in [('girl', girlLabel), ('boy', boyLabel)]) ...[
        if (id == 'boy') const SizedBox(width: SegSpace.s3),
        Expanded(
          child: Semantics(
            button: true,
            selected: value == id,
            label: label,
            excludeSemantics: true,
            child: _ChoiceSurface(
              key: ValueKey('gender-$id'),
              selected: value == id,
              onTap: () => onChanged(id),
              minHeight: 64,
              padding: const EdgeInsets.symmetric(
                horizontal: SegSpace.s3,
                vertical: SegSpace.s1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/wear/${id}_face.webp',
                    height: 52,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: SegSpace.s2),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SegText.heading.copyWith(
                        fontWeight: FontWeight.w800,
                        color: value == id
                            ? SegColors.primaryDeep
                            : SegColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class AgeChoice extends StatelessWidget {
  final String label, semanticsLabel;
  final bool selected;
  final VoidCallback onTap;
  const AgeChoice({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: semanticsLabel,
    excludeSemantics: true,
    child: _ChoiceSurface(
      selected: selected,
      onTap: onTap,
      minHeight: 64,
      child: Center(
        child: Text(
          label,
          style: SegText.title.copyWith(
            color: selected ? SegColors.primaryDeep : SegColors.ink,
          ),
        ),
      ),
    ),
  );
}

/// A picture answer. Multiple-choice options are announced as checkboxes.
class PictureOption extends StatelessWidget {
  final String label;
  final Widget picture;
  final bool selected, multiple, wide;
  final VoidCallback onTap;
  const PictureOption({
    super.key,
    required this.label,
    required this.picture,
    required this.selected,
    required this.multiple,
    required this.onTap,
    this.wide = false,
  });
  @override
  Widget build(BuildContext context) {
    final check = AnimatedOpacity(
      duration: SegMotion.tap,
      opacity: selected ? 1 : 0,
      child: const Icon(Icons.check_circle_rounded, color: SegColors.primary),
    );
    final text = Text(
      label,
      style: SegText.label.copyWith(color: SegColors.ink),
      textAlign: wide ? TextAlign.start : TextAlign.center,
    );
    return Semantics(
      button: !multiple,
      checked: multiple ? selected : null,
      selected: multiple ? null : selected,
      label: label,
      excludeSemantics: true,
      child: _ChoiceSurface(
        selected: selected,
        onTap: onTap,
        child: wide
            ? Row(
                children: [
                  SizedBox(width: 64, height: 64, child: picture),
                  const SizedBox(width: SegSpace.s3),
                  Expanded(child: text),
                  check,
                ],
              )
            // Picture and name in the middle of the card, whatever the
            // name's length.
            : Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    children: [
                      SizedBox.square(dimension: 80, child: picture),
                      const SizedBox(height: SegSpace.s2),
                      text,
                    ],
                  ),
                  Positioned(top: 0, right: 0, child: check),
                ],
              ),
      ),
    );
  }
}

class GoalOption extends StatelessWidget {
  final String label;
  final String? badge;
  final int minutes;
  final bool selected;
  final VoidCallback onTap;
  const GoalOption({
    super.key,
    required this.label,
    required this.minutes,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: badge == null ? label : '$label. $badge',
    excludeSemantics: true,
    child: _ChoiceSurface(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: SegSpace.s4,
        vertical: SegSpace.s3,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(painter: _GoalRingPainter(minutes / 20)),
          ),
          const SizedBox(width: SegSpace.s4),
          Expanded(
            child: Text(
              label,
              style: SegText.heading.copyWith(color: SegColors.ink),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SegSpace.s3,
                vertical: SegSpace.s1,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF6F3),
                borderRadius: BorderRadius.circular(SegRadius.pill),
              ),
              child: Text(
                badge!,
                style: SegText.caption.copyWith(color: SegColors.turquoiseDeep),
              ),
            ),
        ],
      ),
    ),
  );
}

class _GoalRingPainter extends CustomPainter {
  final double fraction;
  const _GoalRingPainter(this.fraction);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = SegColors.line;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction.clamp(0, 1),
      false,
      track
        ..color = SegColors.turquoise
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GoalRingPainter old) => old.fraction != fraction;
}

/// The home screen's "Family" button with a finger tapping it and the
/// parent-check lock that opens next.
class FamilyAccessIllustration extends StatelessWidget {
  final String label;
  const FamilyAccessIllustration({super.key, required this.label});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 150,
      decoration: BoxDecoration(
        color: SegColors.surface,
        borderRadius: BorderRadius.circular(SegRadius.lg),
        border: Border.all(color: SegColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegSpace.s4,
                  vertical: SegSpace.s3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SegRadius.pill),
                  border: Border.all(color: SegColors.line, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      color: SegColors.ink,
                    ),
                    const SizedBox(width: SegSpace.s2),
                    Text(label, style: SegText.label),
                  ],
                ),
              ),
              const Positioned(
                right: -18,
                bottom: -26,
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 40,
                  color: SegColors.accentDeep,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: SegSpace.s5),
            child: Icon(Icons.arrow_forward_rounded, color: SegColors.inkFaint),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: SegColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: SegColors.primaryDeep,
            ),
          ),
        ],
      ),
    ),
  );
}

/// An upright phone, a curved arrow and the same phone turned sideways with
/// the calm game scene on it: "turn the phone and hand it over".
class RotatePhoneIllustration extends StatelessWidget {
  const RotatePhoneIllustration({super.key});

  Widget _phone({
    required double width,
    required double height,
    Widget? screen,
  }) => Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: SegColors.ink,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: SegColors.ink.withValues(alpha: .18),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: screen ?? const ColoredBox(color: SegColors.familyCanvas),
    ),
  );

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _phone(
          width: 70,
          height: 130,
          screen: const ColoredBox(
            color: SegColors.familyCanvas,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Line(width: .8),
                  SizedBox(height: 6),
                  _Line(width: .55),
                  SizedBox(height: 6),
                  _Line(width: .7),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: SegSpace.s3),
          child: Icon(
            Icons.screen_rotation_rounded,
            size: 40,
            color: SegColors.accent,
          ),
        ),
        _phone(
          width: 170,
          height: 92,
          screen: const SceneBackdrop(
            tint: SegColors.turquoise,
            child: SizedBox.expand(),
          ),
        ),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  final double width;
  const _Line({required this.width});
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: width,
    child: Container(
      height: 6,
      decoration: BoxDecoration(
        color: SegColors.line,
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}

// --------------------------------------------------------------- motion --

/// Comes in once when its page opens: fades in and rises a little, [index]
/// steps after the first. [pop]: grows in with a small bounce (choices).
/// Without [animate] it is simply there.
class Entrance extends StatefulWidget {
  final int index;
  final bool animate, pop;
  final Widget child;
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.animate = true,
    this.pop = false,
  });

  /// Delay between two items; the tenth and later ones come together.
  static const step = Duration(milliseconds: 60);

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const _length = Duration(milliseconds: 420);
  late final Duration _delay = Entrance.step * math.min(widget.index, 9);
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: _delay + _length,
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _in.forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    final start = _delay.inMicroseconds / (_delay + _length).inMicroseconds;
    final t = CurvedAnimation(
      parent: _in,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    final grow = CurvedAnimation(
      parent: _in,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: t,
      child: widget.pop
          ? ScaleTransition(
              scale: Tween(begin: .82, end: 1.0).animate(grow),
              child: widget.child,
            )
          : SlideTransition(
              position: Tween(
                begin: const Offset(0, .18),
                end: Offset.zero,
              ).animate(t),
              child: widget.child,
            ),
    );
  }
}

/// The welcome picture: floats gently up and down, small sparkles twinkle
/// around it. Still with reduced motion.
class LivelyPicture extends StatefulWidget {
  final bool animate;
  final Widget child;
  const LivelyPicture({super.key, required this.child, this.animate = true});
  @override
  State<LivelyPicture> createState() => _LivelyPictureState();
}

class _LivelyPictureState extends State<LivelyPicture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  /// Sparkles: where (fractions of the card), size and phase.
  static const _sparkles = [
    (x: .09, y: .16, size: 18.0, phase: 0.0),
    (x: .88, y: .12, size: 22.0, phase: .35),
    (x: .93, y: .62, size: 14.0, phase: .6),
    (x: .05, y: .7, size: 14.0, phase: .8),
  ];

  bool get _moving => widget.animate && AmbientMotion.enabled;

  @override
  void initState() {
    super.initState();
    if (_moving) _loop.repeat();
  }

  @override
  void didUpdateWidget(LivelyPicture old) {
    super.didUpdateWidget(old);
    if (_moving && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!_moving) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _loop,
        child: widget.child,
        builder: (context, child) {
          final t = _loop.value;
          final wave = math.sin(t * math.pi * 2);
          return Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, -5 * wave),
                child: Transform.rotate(angle: .012 * wave, child: child),
              ),
              for (final s in _sparkles)
                () {
                  // Each sparkle shines for a part of the loop.
                  final local = (t - s.phase) % 1;
                  final glow = local < .4
                      ? math.sin(local / .4 * math.pi)
                      : 0.0;
                  return Positioned(
                    left: box.maxWidth * s.x - s.size / 2,
                    top: box.maxHeight * s.y - s.size / 2,
                    child: Opacity(
                      opacity: glow,
                      child: Transform.scale(
                        scale: .5 + .5 * glow,
                        child: Transform.rotate(
                          angle: local * math.pi,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: s.size,
                            color: SegColors.star,
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    );
  }
}

/// A small wiggle now and then (the gift on the welcome page).
class Wiggle extends StatefulWidget {
  final bool animate;
  final Widget child;
  const Wiggle({super.key, required this.child, this.animate = true});
  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  bool get _moving => widget.animate && AmbientMotion.enabled;

  @override
  void initState() {
    super.initState();
    if (_moving) _loop.repeat();
  }

  @override
  void didUpdateWidget(Wiggle old) {
    super.didUpdateWidget(old);
    if (_moving && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!_moving) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return AnimatedBuilder(
      animation: _loop,
      child: widget.child,
      builder: (context, child) {
        // The first fifth of the loop wiggles, the rest is still.
        final t = (_loop.value / .2).clamp(0.0, 1.0);
        final angle = t >= 1 ? 0.0 : math.sin(t * math.pi * 4) * .2 * (1 - t);
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 1 + .12 * math.sin(t * math.pi),
            child: child,
          ),
        );
      },
    );
  }
}
