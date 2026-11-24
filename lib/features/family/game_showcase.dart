import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/ambient_motion.dart';
import '../../app/ui/components.dart' show ItemVisual;
import '../../app/ui/scene_backdrop.dart';

/// The Premium offer's moving picture (Yunus, 24 Nov 2026): short moments
/// from the real games, one after another, so a parent who has not bought
/// yet sees what the child plays. No words; the same photos and colours as
/// the games.
///
/// 1. Find: a hand taps the cat among three animals; it hops, stars fly.
/// 2. Count: the hand taps three apples, 1, 2, 3 appear over them.
/// 3. Paint: the hand picks red and a brush paints the white balloon.
///
/// With reduced motion it is one still picture (the cat just found).
class GameShowcase extends StatefulWidget {
  final bool animate;
  const GameShowcase({super.key, this.animate = true});

  /// One moment's length; the loop is three of them.
  static const sceneLength = Duration(milliseconds: 4600);

  @override
  State<GameShowcase> createState() => _GameShowcaseState();
}

const _scenes = 3;

/// The photos the moments use (also decoded ahead, see [precache]).
const _cat = 'assets/images/animals/cat_1.webp',
    _dog = 'assets/images/animals/dog_1.webp',
    _rabbit = 'assets/images/animals/rabbit_1.webp',
    _apple = 'assets/images/fruit/apple.webp',
    _balloon = 'assets/images/paint/balloon.webp';

class _GameShowcaseState extends State<GameShowcase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: GameShowcase.sceneLength * _scenes,
  );

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final a in const [_cat, _dog, _rabbit, _apple, _balloon]) {
        precacheImage(AssetImage(a), context);
      }
    }
    _sync();
  }

  @override
  void didUpdateWidget(GameShowcase old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _moving =>
      widget.animate &&
      AmbientMotion.enabled &&
      !MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (_moving) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
      // The cat just found, stars around it.
      _loop.value = .78 / _scenes;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SegRadius.lg),
        child: LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            return AnimatedBuilder(
              animation: _loop,
              builder: (context, _) {
                final all = _loop.value * _scenes;
                final index = all.floor() % _scenes;
                final p = all - all.floor();
                // A short cross-fade into the next moment.
                const edge = .07;
                final fadeOut = _iv(p, 1 - edge, 1);
                final next = (index + 1) % _scenes;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (fadeOut > 0) _scene(next, 0, size),
                    Opacity(
                      opacity: 1 - fadeOut,
                      child: _scene(index, p, size),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    ),
  );

  Widget _scene(int index, double p, Size size) => SceneBackdrop(
    key: ValueKey('showcase-scene-$index'),
    tint: switch (index) {
      0 => SegColors.turquoise,
      1 => SegColors.accent,
      _ => SegColors.sky,
    },
    child: Stack(
      clipBehavior: Clip.none,
      children: switch (index) {
        0 => _find(p, size),
        1 => _count(p, size),
        _ => _paint(p, size),
      },
    ),
  );

  // ------------------------------------------------------------- moments --

  /// Find: three animals stand up, the hand taps the cat.
  List<Widget> _find(double p, Size size) {
    final w = size.width, h = size.height;
    final s = math.min(h * .66, w / 3.6);
    final ground = h * .86;
    const pictures = [_cat, _dog, _rabbit];
    const target = 0;
    final xs = [w * .2, w * .5, w * .8];
    final tap = _iv(p, .5, .56);
    final found = _iv(p, .55, .9);
    final hop = math.sin(found * math.pi) * h * .14;
    final others = 1 - .62 * _iv(p, .56, .66);
    final at = Offset(xs[target], ground - s * .5);
    return [
      // A soft glow behind the right answer.
      if (found > 0)
        _centered(
          at,
          s * 1.05,
          Opacity(
            opacity: (1 - _iv(p, .8, .95)).clamp(0, 1) * .9,
            child: Transform.scale(
              scale: .6 + .5 * Curves.easeOut.transform(_iv(p, .55, .7)),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SegColors.successGlow,
                ),
              ),
            ),
          ),
        ),
      for (var i = 0; i < 3; i++)
        _standing(
          pictures[i],
          x: xs[i],
          ground: ground,
          size: s,
          appear: _iv(p, .02 + i * .07, .16 + i * .07),
          lift: i == target ? hop : 0,
          opacity: i == target ? 1 : others,
          press: i == target ? _press(tap) : 1,
        ),
      ..._stars(at.translate(0, -hop), s, _iv(p, .57, .92)),
      _hand(
        from: Offset(w * .96, h * 1.1),
        to: at.translate(s * .12, s * .18),
        move: _iv(p, .26, .5),
        tap: tap,
        fade: _iv(p, .62, .72),
        size: s,
      ),
    ];
  }

  /// Count: three apples, the hand taps each; its number pops above it.
  List<Widget> _count(double p, Size size) {
    final w = size.width, h = size.height;
    final s = math.min(h * .5, w / 4.4);
    final ground = h * .88;
    final xs = [w * .24, w * .5, w * .76];
    // The hand reaches the first apple, then each next one.
    final reach = [.24, .44, .64];
    final widgets = <Widget>[];
    var hand = Offset(w * .96, h * 1.1);
    double handTap = 0;
    for (var i = 0; i < 3; i++) {
      final at = Offset(xs[i], ground - s * .5);
      final arrive = _iv(p, reach[i] - .12, reach[i]);
      if (arrive > 0) {
        hand = Offset.lerp(hand, at.translate(s * .1, s * .2), _ease(arrive))!;
      }
      final t = _iv(p, reach[i], reach[i] + .06);
      if (t > 0 && t < 1) handTap = t;
    }
    // All three jump together at the end.
    final cheer = math.sin(_iv(p, .78, .92) * math.pi) * h * .08;
    for (var i = 0; i < 3; i++) {
      final counted = _iv(p, reach[i] + .02, reach[i] + .14);
      final bounce = math.sin(_iv(p, reach[i], reach[i] + .12) * math.pi);
      widgets.add(
        _standing(
          _apple,
          x: xs[i],
          ground: ground,
          size: s,
          appear: _iv(p, .02 + i * .05, .14 + i * .05),
          lift: bounce * h * .05 + cheer,
          press: _press(_iv(p, reach[i], reach[i] + .06)),
        ),
      );
      if (counted > 0) {
        widgets.add(
          _centered(
            Offset(xs[i], ground - s * 1.28 - cheer),
            s * .62,
            Transform.scale(
              scale: Curves.elasticOut.transform(counted),
              child: _NumberBubble(number: i + 1),
            ),
          ),
        );
      }
    }
    widgets
      ..addAll(
        _stars(Offset(w * .5, ground - s * .9), s * 1.3, _iv(p, .8, .98)),
      )
      ..add(
        _hand(
          from: Offset(w * .96, h * 1.1),
          to: hand,
          move: 1,
          tap: handTap,
          fade: _iv(p, .7, .78),
          size: s * 1.3,
          enter: _iv(p, .1, .14),
        ),
      );
    return widgets;
  }

  /// Paint: the hand picks red, a brush paints the white balloon red.
  List<Widget> _paint(double p, Size size) {
    final w = size.width, h = size.height;
    final s = math.min(h * .84, w * .46);
    final picture = Offset(w * .36, h * .5);
    final red = Color(ItemVisual.colors['red']!);
    final swatches = [
      red,
      Color(ItemVisual.colors['blue']!),
      Color(ItemVisual.colors['yellow']!),
    ];
    final dot = math.min(h * .2, w * .1);
    final swatchAt = [
      for (var i = 0; i < 3; i++) Offset(w * .8, h * (.24 + i * .26)),
    ];
    final tap = _iv(p, .32, .38);
    final sweep = Curves.easeInOut.transform(_iv(p, .4, .78));
    final wave = math.sin(sweep * math.pi * 6);
    final pictureRect = Rect.fromCenter(center: picture, width: s, height: s);
    return [
      // The white picture, and the red one revealed behind the brush.
      Positioned.fromRect(
        rect: pictureRect,
        child: Opacity(
          opacity: _iv(p, .02, .12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_balloon, fit: BoxFit.contain),
              if (sweep > 0)
                ClipRect(
                  clipper: _Reveal(sweep),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(red, BlendMode.modulate),
                    child: Image.asset(_balloon, fit: BoxFit.contain),
                  ),
                ),
            ],
          ),
        ),
      ),
      for (var i = 0; i < 3; i++)
        _centered(
          swatchAt[i],
          dot,
          Transform.scale(
            scale:
                Curves.easeOutBack.transform(
                  _iv(p, .06 + i * .05, .18 + i * .05),
                ) *
                (i == 0 ? _press(tap) + .18 * _iv(p, .36, .42) : 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: swatches[i],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: SegColors.ink.withValues(alpha: .18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (sweep > 0 && sweep < 1)
        Positioned(
          left: pictureRect.left + s * sweep - s * .05,
          top: pictureRect.top + s * (.42 + .3 * wave) - s * .32,
          child: Transform.rotate(
            angle: .35 * wave,
            child: Icon(
              Icons.brush_rounded,
              size: s * .36,
              color: SegColors.primaryDeep,
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 3),
                Shadow(color: Colors.white, blurRadius: 10),
              ],
            ),
          ),
        ),
      ..._stars(picture, s * .8, _iv(p, .78, .98)),
      _hand(
        from: Offset(w * .96, h * 1.1),
        to: swatchAt[0].translate(dot * .2, dot * .35),
        move: _iv(p, .16, .32),
        tap: tap,
        fade: _iv(p, .42, .5),
        size: dot * 2.2,
      ),
    ];
  }

  // ---------------------------------------------------------------- parts --

  /// A cut-out photo standing on the scene with a soft ground shadow (as the
  /// game draws its answers).
  Widget _standing(
    String asset, {
    required double x,
    required double ground,
    required double size,
    required double appear,
    double lift = 0,
    double opacity = 1,
    double press = 1,
  }) {
    if (appear <= 0) return const SizedBox.shrink();
    final pop = Curves.easeOutBack.transform(appear);
    return Positioned(
      left: x - size / 2,
      top: ground - size,
      width: size,
      height: size * 1.08,
      child: Opacity(
        opacity: (appear * 2).clamp(0, 1) * opacity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Ground shadow, smaller while the picture is up.
            Positioned(
              bottom: 0,
              child: Container(
                width: size * .62 * (1 - (lift / size).clamp(0, .5)),
                height: size * .1,
                decoration: BoxDecoration(
                  color: SegColors.ink.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: size,
              child: Transform.translate(
                offset: Offset(0, -lift),
                child: Transform.scale(
                  scale: pop * press,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The pointing hand that shows where to tap.
  Widget _hand({
    required Offset from,
    required Offset to,
    required double move,
    required double tap,
    required double fade,
    required double size,
    double enter = 1,
  }) {
    if (move <= 0 || fade >= 1) return const SizedBox.shrink();
    final at = Offset.lerp(from, to, _ease(move))!;
    final hand = size * .55;
    return Positioned(
      left: at.dx - hand * .3,
      top: at.dy - hand * .08,
      child: Opacity(
        opacity: (1 - fade) * enter.clamp(0, 1),
        child: Transform.scale(
          scale: _press(tap),
          alignment: Alignment.topLeft,
          child: Icon(
            Icons.touch_app_rounded,
            size: hand,
            color: Colors.white,
            shadows: [
              Shadow(
                color: SegColors.ink.withValues(alpha: .45),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Stars flying out of [at]; [t] runs 0..1.
  List<Widget> _stars(Offset at, double size, double t) {
    if (t <= 0 || t >= 1) return const [];
    const count = 7;
    final out = Curves.easeOutCubic.transform(t);
    return [
      for (var i = 0; i < count; i++)
        () {
          final angle = -math.pi / 2 + (i - (count - 1) / 2) * .48;
          final r = size * (.35 + .5 * out);
          final star = size * (i.isEven ? .2 : .15);
          return _centered(
            at + Offset(math.cos(angle) * r, math.sin(angle) * r * .9),
            star,
            Opacity(
              opacity: (1 - t * t).clamp(0, 1),
              child: Transform.rotate(
                angle: out * (i.isEven ? 1.2 : -1.2),
                child: Icon(
                  Icons.star_rounded,
                  size: star,
                  color: SegColors.star,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                ),
              ),
            ),
          );
        }(),
    ];
  }

  Widget _centered(Offset at, double size, Widget child) => Positioned(
    left: at.dx - size / 2,
    top: at.dy - size / 2,
    width: size,
    height: size,
    child: child,
  );
}

/// The round number that pops over a counted apple.
class _NumberBubble extends StatelessWidget {
  final int number;
  const _NumberBubble({required this.number});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: SegColors.primary,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: SegColors.ink.withValues(alpha: .2),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            '$number',
            style: SegText.title.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Reveal extends CustomClipper<Rect> {
  final double t;
  const _Reveal(this.t);
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);
  @override
  bool shouldReclip(_Reveal old) => old.t != t;
}

/// Where [p] is between [a] and [b], as 0..1.
double _iv(double p, double a, double b) => ((p - a) / (b - a)).clamp(0.0, 1.0);

double _ease(double t) => Curves.easeInOutCubic.transform(t);

/// A quick press: down to 85 % and back.
double _press(double t) =>
    t <= 0 || t >= 1 ? 1 : 1 - .15 * math.sin(t * math.pi);
