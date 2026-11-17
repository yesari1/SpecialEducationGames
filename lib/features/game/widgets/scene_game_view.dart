import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../../../app/ui/game_object.dart';
import '../../../core/audio/audio_service.dart' show UiSound;
import '../../../core/content/child_cast.dart';
import '../../../core/content/content_repository.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// A game played on a picture ([SceneRound]): the pieces wait in the tray,
/// the right one is dragged to the picture (tapping works too) and flies
/// from where it was let go to its place. Rub steps clean the spots away,
/// stir steps go round; their tool is dragged from the tray too.
/// The step of the scene round on screen, so the replayed question (the
/// speaker button, the hint) is the current step's and not the first one
/// (Yunus, 16 November 2026: hand washing asked to rinse again while drying).
abstract final class SceneProgress {
  static SceneRound? round;
  static int step = 0;
}

class SceneGameView extends StatefulWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  const SceneGameView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
  });
  @override
  State<SceneGameView> createState() => _SceneGameViewState();
}

const _ghost = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];

/// Bits of food on one tooth: small uneven brown and yellow specks, kept
/// inside the tooth's rounded shape.
class _StainPainter extends CustomPainter {
  final int seed;
  const _StainPainter(this.seed);
  static const _colors = [
    Color(0xFFA47B3B),
    Color(0xFFC49A52),
    Color(0xFF8A6A35),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed * 11 + 5);
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.shortestSide * .32),
      ),
    );
    final specks = 6 + random.nextInt(4);
    for (var i = 0; i < specks; i++) {
      final centre = Offset(
        size.width * (.18 + random.nextDouble() * .64),
        size.height * (.2 + random.nextDouble() * .6),
      );
      final path = Path();
      final corners = 6 + random.nextInt(3);
      final base = size.shortestSide * (.07 + random.nextDouble() * .11);
      for (var c = 0; c < corners; c++) {
        final angle = c / corners * math.pi * 2;
        final point =
            centre +
            Offset.fromDirection(angle, base * (.6 + random.nextDouble() * .7));
        c == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = _colors[random.nextInt(_colors.length)].withValues(
            alpha: .92,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_StainPainter old) => old.seed != seed;
}

/// Toothpaste foam: white bubbles where the brush went, each fading away
/// over a second and a half.
class _FoamPainter extends CustomPainter {
  final List<(Offset, double, int)> foam;
  final int now;
  const _FoamPainter(this.foam, this.now);
  @override
  void paint(Canvas canvas, Size size) {
    for (final (at, r, born) in foam) {
      final age = (now - born) / 1600;
      if (age >= 1) continue;
      final centre = Offset(at.dx * size.width, at.dy * size.height);
      final radius = r * size.width * (1 + age * .4);
      canvas.drawCircle(
        centre,
        radius,
        Paint()..color = Colors.white.withValues(alpha: .9 * (1 - age)),
      );
      canvas.drawCircle(
        centre - Offset(radius * .3, radius * .3),
        radius * .3,
        Paint()..color = const Color(0xFFDDF4FF).withValues(alpha: 1 - age),
      );
    }
  }

  @override
  bool shouldRepaint(_FoamPainter old) => true;
}

/// A piece on its way: from where it was let go to its place on the
/// picture, or back to its slot in the tray.
class _Flight {
  final String id;
  final Rect from, to;

  /// Radians the piece has turned by when it lands.
  final double turn;

  /// Fades out as it arrives (the picture itself changes there).
  final bool melts;
  final VoidCallback? then;
  const _Flight({
    required this.id,
    required this.from,
    required this.to,
    this.turn = 0,
    this.melts = false,
    this.then,
  });
}

/// What a piece does where it arrived, before the picture changes: a can
/// pours, a sun shines, snow or blossom spreads over the tree.
class _Effect {
  final String id, kind;

  /// Where the piece is, and where its water, light or flakes go.
  final Rect at, over;
  const _Effect(this.id, this.kind, this.at, this.over);
}

/// Water running from the can's spout to the soil.
class _DropsPainter extends CustomPainter {
  final Offset from, to;
  final double t, strength;
  const _DropsPainter(this.from, this.to, this.t, this.strength);
  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFF4FB6F0).withValues(alpha: .9 * strength);
    const drops = 7;
    for (var i = 0; i < drops; i++) {
      final along = (t * 3.2 + i / drops) % 1;
      // Falls faster as it goes, a little to the side of its neighbours.
      final fall = along * along;
      final at =
          Offset.lerp(from, to, fall)! + Offset((i.isEven ? -1 : 1) * 4.0, 0);
      final r = 4.5 + (i % 3);
      canvas.drawOval(
        Rect.fromCenter(center: at, width: r * 1.5, height: r * 2.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DropsPainter old) =>
      old.t != t || old.strength != strength;
}

/// Soft rays turning slowly around the sun.
class _RaysPainter extends CustomPainter {
  final double t, strength;
  const _RaysPainter(this.t, this.strength);
  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final centre = size.center(Offset.zero);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE082).withValues(alpha: .75 * strength),
          const Color(0xFFFFE082).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: centre, radius: size.width * .9));
    canvas.drawCircle(centre, size.width * .9, glow);
    final ray = Paint()
      ..color = const Color(0xFFFFC546).withValues(alpha: .8 * strength)
      ..strokeWidth = size.width * .035
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = i / 12 * math.pi * 2 + t * 1.2;
      final reach = size.width * (.62 + .1 * math.sin(t * 10 + i));
      canvas.drawLine(
        centre + Offset.fromDirection(angle, size.width * .52),
        centre + Offset.fromDirection(angle, reach),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) =>
      old.t != t || old.strength != strength;
}

class _SceneGameViewState extends State<SceneGameView>
    with TickerProviderStateMixin {
  SceneRound get round => widget.spec.scene!;
  int _step = 0;
  int _generation = -1;
  String _picture = '';
  final Set<int> _placed = {};

  /// Stirred: the bowl shows the cut pieces of the fruit put in.
  bool _mixed = false;
  final Set<int> _cleaned = {};

  // Brushing (rub steps): the stains of this play, chosen anew each time
  // from the round's teeth, how far each is scrubbed (0..1), and the foam
  // the brush leaves (in the picture's fractions).
  List<SceneRect> _stains = const [];
  final Map<int, double> _scrub = {};
  final List<(Offset, double, int)> _foam = [];
  late final AnimationController _foamTick = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  /// Pieces that left the tray for good (gentle rounds keep every slot).
  final Set<String> _gone = {};
  String? _shaking;
  double _stirred = 0;
  int _stirTaps = 0;
  bool _done = false;

  /// The tray's slots; a gentle round keeps them for the whole round.
  late List<String> _pieces;

  /// The hint level when this step began: a new step starts without hints.
  int _hintBase = 0;

  // Dragging: the piece under the finger, in the root's coordinates.
  String? _dragId;
  Offset? _dragAt;
  double _dragSide = 0;

  // The tool of a rub or stir step while it is carried.
  Offset? _toolAt;

  _Flight? _flight;
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  _Effect? _effect;
  bool _effectLanded = false;
  late final AnimationController _fx =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..addListener(() {
          // The picture starts to change while the water still runs.
          if (_effect != null && !_effectLanded && _fx.value >= .62) {
            _effectLanded = true;
            _complete();
          }
        });
  bool get _busy => _flight?.then != null || _effect != null;

  // The finger that shows how to drag: when the game opens and again after
  // six seconds with no touch (or as soon as a hint is due).
  final _rootKey = GlobalKey();
  final _stageKey = GlobalKey();
  final _toolKey = GlobalKey();
  final _pieceKeys = <String, GlobalKey>{};
  late final AnimationController _finger = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  (Offset, Offset)? _guide;
  bool _introSeen = false, _idle = false;
  Timer? _idleTimer;
  bool get _dragging => _dragId != null || _toolAt != null;
  bool get _wantsGuide =>
      _ready &&
      !_dragging &&
      _flight == null &&
      _effect == null &&
      step.mode == SceneStepMode.place &&
      // Shown once when an easy game opens, and to a child who has not
      // touched the screen for a while; never to one who is playing.
      ((!_introSeen && round.tier == 'easy') || _idle);

  void _armIdle() {
    _idle = false;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _idle = true);
    });
  }

  int get _hintLevel => math.max(0, widget.hint.level - _hintBase);

  static const _stirDistance = 1400.0;
  static const _stirTapsNeeded = 4;

  SceneStep get step => round.steps[_step];
  bool get _ready =>
      widget.hint.visibleChoices > 0 && !widget.hint.celebrating && !_done;
  String get _lang => widget.hint.locale == 'en' ? 'en' : 'tr';

  @override
  void initState() {
    super.initState();
    _finger.value = 0;
    _reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precache();
  }

  /// Every picture of the round is ready before it is needed, so a change
  /// never shows an empty frame.
  void _precache() {
    for (final path in {
      round.stage,
      ?round.front,
      for (final s in round.steps) ?s.after,
    }) {
      unawaited(precacheImage(AssetImage(path), context, onError: (_, _) {}));
    }
  }

  @override
  void didUpdateWidget(covariant SceneGameView old) {
    super.didUpdateWidget(old);
    if (widget.hint.generation != _generation) {
      _reset();
      _precache();
    }
  }

  void _reset() {
    _generation = widget.hint.generation;
    _step = 0;
    _picture = round.stage;
    _placed.clear();
    _mixed = false;
    _gone.clear();
    _done = false;
    _dragId = null;
    _dragAt = null;
    _flight = null;
    _fly.stop();
    _effect = null;
    _fx.stop();
    if (round.gentle) {
      _pieces = [for (final s in round.steps) s.piece, ...round.extras]
        ..shuffle(math.Random(_generation * 31));
    }
    _enterStep();
  }

  void _enterStep() {
    SceneProgress.round = round;
    SceneProgress.step = _step;
    _armIdle();
    _hintBase = widget.hint.level;
    _cleaned.clear();
    _scrub.clear();
    _foam.clear();
    _stains = step.mode != SceneStepMode.rub
        ? const []
        : round.tints.length >= step.spots.length
        ? (List.of(round.tints)..shuffle()).take(step.spots.length).toList()
        : step.spots;
    _toolAt = null;
    _stirred = 0;
    _stirTaps = 0;
    if (!round.gentle) {
      _pieces = [step.piece, ...step.others]
        ..shuffle(math.Random(_generation * 31 + _step));
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _finger.dispose();
    _fly.dispose();
    _fx.dispose();
    _foamStop?.cancel();
    _foamTick.dispose();
    super.dispose();
  }

  RenderBox? _box(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  Offset _toRoot(Offset global) =>
      _box(_rootKey)?.globalToLocal(global) ?? global;

  /// A widget's place in the root's coordinates.
  Rect? _rectOf(GlobalKey? key) {
    final root = _box(_rootKey);
    final box = key == null ? null : _box(key);
    if (root == null || box == null) return null;
    return root.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
  }

  /// A step's place on the picture, in the root's coordinates.
  Rect? _zoneRect(SceneStep step) {
    final stage = _rectOf(_stageKey);
    if (stage == null) return null;
    final z = step.zone;
    final rect = Rect.fromLTWH(
      stage.left + z.x * stage.width,
      stage.top + z.y * stage.height,
      z.w * stage.width,
      z.h * stage.height,
    );
    if (step.turn == 0) return rect;
    // A turned piece is drawn as a square in the middle of its place.
    return Rect.fromCenter(
      center: rect.center,
      width: rect.height * .72,
      height: rect.height * .72,
    );
  }

  /// From the asked piece to its place, measured where they really are.
  void _updateGuide() {
    if (!mounted) return;
    (Offset, Offset)? next;
    if (_wantsGuide) {
      final piece = _rectOf(_pieceKeys[step.piece]);
      final zone = _zoneRect(step);
      if (piece != null && zone != null) next = (piece.center, zone.center);
    }
    if (next == _guide) return;
    setState(() => _guide = next);
    if (next == null) {
      _finger.stop();
    } else if (widget.hint.animate) {
      _finger.repeat();
    } else {
      _finger.value = .4;
    }
  }

  Widget _fingerOverlay() {
    final guide = _guide!;
    return AnimatedBuilder(
      key: const ValueKey('scene-finger'),
      animation: _finger,
      builder: (context, _) {
        final t = _finger.value;
        // Holds the piece, carries it over, rests, then starts again.
        final travel = Curves.easeInOut.transform(
          ((t - .15) / .55).clamp(0.0, 1.0),
        );
        final fade = t > .9 ? (1 - t) / .1 : 1.0;
        final at = Offset.lerp(guide.$1, guide.$2, travel)!;
        // The finger carries a picture of the piece along.
        return Positioned(
          left: at.dx - 50,
          top: at.dy - 50,
          width: 100,
          height: 118,
          child: IgnorePointer(
            child: Opacity(
              opacity: fade,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox.square(
                    dimension: 100,
                    child: Opacity(opacity: .85, child: _visual(step.piece)),
                  ),
                  const Positioned(
                    left: 30,
                    top: 46,
                    child: Icon(
                      Icons.touch_app_rounded,
                      size: 68,
                      color: SegColors.accent,
                      shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _wrong(String id) {
    setState(() => _shaking = id);
    final wrong = widget.spec.choices
        .where((c) => c.id != widget.spec.target.id)
        .firstOrNull;
    if (wrong != null) widget.callbacks.onSelect(wrong);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _shaking == id) setState(() => _shaking = null);
    });
  }

  /// Starts a flight; without animations it lands at once.
  void _launch(_Flight flight, {Duration? duration}) {
    if (!widget.hint.animate || flight.from == flight.to) {
      flight.then?.call();
      return;
    }
    setState(() => _flight = flight);
    _fly.duration = duration ?? const Duration(milliseconds: 420);
    _fly.forward(from: 0).whenComplete(() {
      if (!mounted || _flight != flight) return;
      setState(() => _flight = null);
      flight.then?.call();
    });
  }

  /// Back to its slot in the tray, from where it was let go.
  void _flyBack(String id, Rect? from) {
    final slot = _rectOf(_pieceKeys[id]);
    if (from == null || slot == null) return;
    _launch(
      _Flight(id: id, from: from, to: slot),
      duration: const Duration(milliseconds: 300),
    );
  }

  /// The piece [id] was brought to the picture; [from] is where it is now.
  void _bring(String id, Rect? from) {
    // One piece at a time: nothing new while one is landing.
    if (_busy) return;
    if (!_ready || step.mode != SceneStepMode.place) return _flyBack(id, from);
    if (id != step.piece) {
      _flyBack(id, from);
      // A piece of this round that is not asked yet is not a mistake.
      if (!round.gentle || round.extras.contains(id)) return _wrong(id);
      _introSeen = true;
      final ask = (_step == 0 ? round.audio : step.askAudio)[_lang];
      if (ask != null) widget.callbacks.onSay?.call([ask]);
      return;
    }
    UiSound.basketDrop();
    final zone = _zoneRect(step);
    final stage = _rectOf(_stageKey);
    final landing = step;
    if (from == null || zone == null || stage == null) return _complete();
    final effect = widget.hint.animate ? landing.effect : null;
    final side = stage.shortestSide * .42;
    // Where the piece does its work: a can beside and above the pot, a sun
    // in the sky, a seed small in the soil.
    final to = switch (effect) {
      'pour' => Rect.fromCenter(
        center: Offset(zone.center.dx + side * .62, zone.top - side * .5),
        width: side,
        height: side,
      ),
      'shine' => Rect.fromCenter(
        center: Offset(stage.right - side * .55, stage.top + side * .55),
        width: side * .8,
        height: side * .8,
      ),
      'plant' => Rect.fromCenter(
        center: zone.center,
        width: zone.height * .7,
        height: zone.height * .7,
      ),
      _ => zone,
    };
    final acts = const {'pour', 'shine', 'sprinkle'}.contains(effect);
    _launch(
      _Flight(
        id: id,
        from: from,
        to: to,
        turn: landing.turn,
        melts: !landing.stays && !acts,
        then: acts ? () => _act(_Effect(id, effect!, to, zone)) : _complete,
      ),
    );
  }

  void _act(_Effect effect) {
    _effectLanded = false;
    setState(() => _effect = effect);
    _fx.duration = Duration(
      milliseconds: switch (effect.kind) {
        'pour' => 2200,
        'shine' => 2000,
        _ => 1300,
      },
    );
    _fx.forward(from: 0).whenComplete(() {
      if (!mounted || _effect != effect) return;
      setState(() => _effect = null);
      if (!_effectLanded) _complete();
    });
  }

  Widget _effectOverlay(_Effect e) => AnimatedBuilder(
    animation: _fx,
    builder: (context, _) {
      final t = _fx.value;
      double span(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
      final leaving = 1 - span(.82, 1);
      final at = e.at;
      switch (e.kind) {
        case 'pour':
          // The can tips towards its spout (on its left) and the water
          // runs down to the soil.
          final tip = Curves.easeInOut.transform(span(0, .18)) * leaving;
          final spout = Offset(
            at.left + at.width * .12,
            at.top + at.height * .62,
          );
          final water = span(.14, .22) * (1 - span(.7, .8));
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DropsPainter(spout, e.over.center, t, water),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: at,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: leaving,
                    child: Transform.rotate(
                      angle: -.7 * tip,
                      child: _visual(e.id),
                    ),
                  ),
                ),
              ),
            ],
          );
        case 'shine':
          final glow = span(0, .2) * leaving;
          return Positioned.fromRect(
            rect: at,
            child: IgnorePointer(
              child: Opacity(
                opacity: leaving,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _RaysPainter(t, glow)),
                    Transform.scale(
                      scale: 1 + .06 * math.sin(t * math.pi * 6),
                      child: _visual(e.id),
                    ),
                  ],
                ),
              ),
            ),
          );
        default:
          // Small copies drift from the piece out over its place.
          final random = math.Random(7);
          final spread = Curves.easeOut.transform(span(0, .7));
          final small = at.shortestSide * .34;
          return Stack(
            children: [
              Positioned.fromRect(
                rect: at,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 1 - span(.1, .45),
                    child: _visual(e.id),
                  ),
                ),
              ),
              for (var i = 0; i < 12; i++)
                () {
                  final end = Offset(
                    e.over.left + random.nextDouble() * e.over.width,
                    e.over.top + random.nextDouble() * e.over.height,
                  );
                  final here = Offset.lerp(at.center, end, spread)!;
                  return Positioned(
                    left: here.dx - small / 2,
                    top: here.dy - small / 2,
                    width: small,
                    height: small,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: span(0, .15) * (1 - span(.55, .95)),
                        child: _visual(e.id),
                      ),
                    ),
                  );
                }(),
            ],
          );
      }
    },
  );

  void _complete() {
    final finished = step;
    final last = _step == round.steps.length - 1;
    _introSeen = true;
    setState(() {
      if (finished.mode == SceneStepMode.place) _gone.add(finished.piece);
      if (finished.stays) _placed.add(_step);
      if (finished.after case final after?) {
        _picture = after;
        _placed.clear();
      }
      if (finished.mode == SceneStepMode.stir && round.pieces.isNotEmpty) {
        _mixed = true;
        _placed.clear();
      }
      if (last) {
        _done = true;
      } else {
        _step++;
        _enterStep();
      }
    });
    if (last) {
      // The round's own closing line and the praise follow (see the
      // template's success cues).
      widget.callbacks.onSelect(widget.spec.target);
      return;
    }
    final next = round.steps[_step];
    widget.callbacks.onSay?.call([
      ?finished.doneAudio[_lang],
      ?next.askAudio[_lang],
    ]);
  }

  void _clean(int spot) {
    if (!_ready || _cleaned.contains(spot)) return;
    setState(() => _cleaned.add(spot));
    UiSound.tap();
    if (_cleaned.length == _stains.length) _complete();
  }

  /// The brush head at [point] (fractions of the picture) scrubs the stains
  /// under it a little more with every stroke and leaves foam.
  void _rubAt(Offset point, double moved) {
    if (step.mode != SceneStepMode.rub || !_ready) return;
    const reach = .035;
    var touched = false;
    for (var i = 0; i < _stains.length; i++) {
      if (_cleaned.contains(i)) continue;
      final s = _stains[i];
      final rect = Rect.fromLTWH(s.x, s.y, s.w, s.h).inflate(reach);
      if (!rect.contains(point)) continue;
      touched = true;
      final next = (_scrub[i] ?? 0) + moved / 700;
      _scrub[i] = next;
      if (next >= 1) _clean(i);
      if (_step >= round.steps.length || _done) return;
    }
    if (moved > 1.5 && (touched || _foam.length < 12)) {
      final random = math.Random();
      _foam.add((
        point +
            Offset(
              (random.nextDouble() - .5) * .04,
              (random.nextDouble() - .5) * .04,
            ),
        .006 + random.nextDouble() * .012,
        DateTime.now().millisecondsSinceEpoch,
      ));
      if (_foam.length > 70) _foam.removeAt(0);
      if (!_foamTick.isAnimating) _foamTick.repeat();
      _foamStop?.cancel();
      _foamStop = Timer(const Duration(milliseconds: 1800), () {
        _foamTick.stop();
        if (mounted) setState(_foam.clear);
      });
    }
    setState(() {});
  }

  /// Where the picture's point [local] (in the stage box) really is, when
  /// the picture is drawn close up.
  Offset _pictureFraction(Offset local, Size size) {
    final f = round.focus;
    if (f == null) return Offset(local.dx / size.width, local.dy / size.height);
    final centre = Offset(size.width * .5, size.height * .55);
    final p =
        (local - centre) / f[2] + Offset(f[0] * size.width, f[1] * size.height);
    return Offset(p.dx / size.width, p.dy / size.height);
  }

  /// A brush in the hand is drawn bigger than other tools, next to the
  /// close-up mouth.
  static const _brushScale = 1.5;
  Timer? _foamStop;

  /// The brush is held by its handle: its head is up and to the right of
  /// the finger.
  Offset get _brushHead {
    final side = _toolSide() * _brushScale;
    // Turned level (see the tool overlay): the bristles are to the left of
    // the hand and point down, at the teeth.
    return Offset(-side * .67, side * .1);
  }

  void _stirBy(double distance) {
    if (!_ready || step.mode != SceneStepMode.stir) return;
    setState(() => _stirred += distance);
    if (_stirred >= _stirDistance) _complete();
  }

  void _stirTap() {
    if (!_ready || step.mode != SceneStepMode.stir) return;
    _stirTaps++;
    UiSound.tap();
    setState(() => _stirred += _stirDistance / _stirTapsNeeded * .6);
    if (_stirTaps >= _stirTapsNeeded) _complete();
  }

  /// The tool follows the finger; over the picture it rubs or stirs.
  void _toolMove(Offset global, double moved) {
    if (!_ready || step.mode == SceneStepMode.place) return;
    setState(() => _toolAt = _toRoot(global));
    final stage = _box(_stageKey);
    if (stage == null) return;
    if (step.mode == SceneStepMode.rub) {
      final local = stage.globalToLocal(global + _brushHead);
      if (!(Offset.zero & stage.size).inflate(12).contains(local)) return;
      _rubAt(_pictureFraction(local, stage.size), moved);
      return;
    }
    final local = stage.globalToLocal(global);
    if (!(Offset.zero & stage.size).inflate(12).contains(local)) return;
    if (_done || step.mode != SceneStepMode.stir) return;
    _stirBy(moved);
  }

  void _toolDrop() {
    final at = _toolAt;
    if (at == null) return;
    final rest = _rectOf(_toolKey);
    final side = _toolSide();
    final id = _done ? null : step.piece;
    setState(() => _toolAt = null);
    if (rest == null || id == null || step.mode == SceneStepMode.place) return;
    _launch(
      _Flight(
        id: id,
        from: Rect.fromCenter(center: at, width: side, height: side),
        to: rest,
      ),
      duration: const Duration(milliseconds: 260),
    );
  }

  double _toolSide() {
    final stage = _box(_stageKey)?.size ?? const Size(300, 200);
    return stage.shortestSide * .36;
  }

  ContentItem? _item(String id) => widget.spec.scenePieces[id];

  /// A piece as it lies on the picture, turned if its step says so.
  /// Two pieces of every fruit put in, heaped in the bowl (back row first,
  /// so the front row overlaps it), each turned a little differently.
  List<Widget> _saladPieces(Size size) {
    final pictures = [for (final s in round.steps) ?round.pieces[s.piece]];
    final all = [...pictures, ...pictures.reversed];
    final back = (all.length + 1) ~/ 2;
    // A heap in the middle of the bowl: the pieces overlap a little and the
    // front row sits lower and in between.
    const w = .2, h = w * 1.5, step = w * .72;
    final out = <Widget>[];
    for (var i = 0; i < all.length; i++) {
      final front = i >= back;
      final row = front ? all.length - back : back;
      final n = front ? i - back : i;
      final left = .5 - ((row - 1) * step + w) / 2 + n * step;
      out.add(
        Positioned(
          key: ValueKey('scene-piece-$i'),
          left: left * size.width,
          top: (front ? .24 : .15) * size.height,
          width: w * size.width,
          height: h * size.height,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: ((i * 37) % 70 - 35) * math.pi / 180,
              child: Image.asset(
                all[i],
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  Widget _onPicture(SceneStep step, Size size) {
    final visual = _visual(step.piece);
    if (step.turn == 0) return visual;
    final side = step.zone.h * size.height;
    return OverflowBox(
      maxWidth: side,
      maxHeight: side,
      child: Transform.rotate(
        angle: step.turn,
        child: SizedBox.square(dimension: side * .72, child: visual),
      ),
    );
  }

  Widget _visual(String id) {
    final item = _item(id);
    return item == null ? const SizedBox.shrink() : ItemVisual(item);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGuide());
    return LayoutBuilder(
      builder: (context, box) {
        // The picture takes the height; the tray gets what is left, without
        // growing so wide that the pieces drift away from the picture.
        const gap = SegSpace.s3;
        final stageWidth = math.min(
          box.maxWidth * .64,
          box.maxHeight * round.aspect,
        );
        final trayWidth = math.min(
          box.maxWidth - stageWidth - gap,
          // An upright picture (a child to dress) leaves the tray more room.
          math.max(
            box.maxWidth * (round.aspect < 1 ? .52 : .34),
            box.maxHeight * .95,
          ),
        );
        final current = _done ? null : step;
        final toolMode = current != null && current.mode != SceneStepMode.place;
        final toolSide = _toolSide();
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            _introSeen = true;
            setState(_armIdle);
          },
          child: Stack(
            key: _rootKey,
            children: [
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: stageWidth,
                      child: Center(child: _stage()),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(width: trayWidth, child: _tray()),
                  ],
                ),
              ),
              if (_guide != null) _fingerOverlay(),
              if (toolMode && _toolAt != null)
                Positioned(
                  // A brush is held by its handle (the finger on the grip).
                  left:
                      _toolAt!.dx -
                      (current.mode == SceneStepMode.rub
                          ? toolSide * _brushScale * .3
                          : toolSide * .5),
                  top:
                      _toolAt!.dy -
                      (current.mode == SceneStepMode.rub
                          ? toolSide * _brushScale * .7
                          : toolSide * .5),
                  width: current.mode == SceneStepMode.rub
                      ? toolSide * _brushScale
                      : toolSide,
                  height: current.mode == SceneStepMode.rub
                      ? toolSide * _brushScale
                      : toolSide,
                  child: IgnorePointer(
                    child: current.mode == SceneStepMode.rub
                        // Held the way people brush (Yunus's drawing, 17
                        // Nov 2026): level, the handle to the right in the
                        // hand, the head on the left in the mouth, the
                        // bristles down on the teeth. Turned round the grip.
                        ? Transform.rotate(
                            angle: -math.pi * 3 / 4,
                            origin: Offset(
                              toolSide * _brushScale * -.2,
                              toolSide * _brushScale * .2,
                            ),
                            child: _visual(current.piece),
                          )
                        : _visual(current.piece),
                  ),
                ),
              if (_flight case final flight?) _flightOverlay(flight),
              if (_effect case final effect?)
                Positioned.fill(
                  child: Stack(children: [_effectOverlay(effect)]),
                ),
              if (_dragId case final id?)
                Positioned(
                  left: _dragAt!.dx - _dragSide / 2,
                  top: _dragAt!.dy - _dragSide / 2,
                  width: _dragSide,
                  height: _dragSide,
                  child: IgnorePointer(
                    key: const ValueKey('scene-carried'),
                    child: Transform.scale(scale: 1.08, child: _visual(id)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _flightOverlay(_Flight flight) => AnimatedBuilder(
    animation: _fly,
    builder: (context, _) {
      final t = Curves.easeInOutCubic.transform(_fly.value);
      final rect = Rect.lerp(flight.from, flight.to, t)!;
      // A small arc, so the piece is put down rather than slid along.
      final lift = math.sin(t * math.pi) * 14;
      return Positioned(
        left: rect.left,
        top: rect.top - lift,
        width: rect.width,
        height: rect.height,
        child: IgnorePointer(
          child: Opacity(
            opacity: flight.melts ? (1 - (t - .7) / .3).clamp(0.0, 1.0) : 1,
            child: Transform.rotate(
              angle: flight.turn * t,
              child: _visual(flight.id),
            ),
          ),
        ),
      );
    },
  );

  Widget _stage() => AspectRatio(
    aspectRatio: round.aspect,
    child: LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        Positioned at(SceneRect r, Widget child, {Key? key}) => Positioned(
          key: key,
          left: r.x * size.width,
          top: r.y * size.height,
          width: r.w * size.width,
          height: r.h * size.height,
          child: child,
        );
        final current = _done ? null : step;
        final toolMode = current != null && current.mode != SceneStepMode.place;
        final stirring = current?.mode == SceneStepMode.stir;
        return GestureDetector(
          key: const ValueKey('scene-stage'),
          behavior: HitTestBehavior.opaque,
          onTap: toolMode && stirring ? _stirTap : null,
          onPanStart: toolMode ? (d) => _toolMove(d.globalPosition, 0) : null,
          onPanUpdate: toolMode
              ? (d) => _toolMove(d.globalPosition, d.delta.distance)
              : null,
          onPanEnd: toolMode ? (_) => _toolDrop() : null,
          onPanCancel: toolMode ? _toolDrop : null,
          child: ClipRRect(
            key: _stageKey,
            borderRadius: BorderRadius.circular(SegRadius.lg),
            child: Transform(
              // A close-up (the mouth): the looked-at place comes to the
              // middle, drawn bigger (see [_pictureFraction]).
              transform: round.focus == null
                  ? Matrix4.identity()
                  : (Matrix4.translationValues(
                        size.width * .5,
                        size.height * .55,
                        0,
                      )
                      ..scaleByDouble(round.focus![2], round.focus![2], 1, 1)
                      ..translateByDouble(
                        -round.focus![0] * size.width,
                        -round.focus![1] * size.height,
                        0,
                        1,
                      )),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: !widget.hint.animate
                          ? Duration.zero
                          : Duration(milliseconds: round.rise ? 900 : 450),
                      // A sprout or a flower comes up out of the pot.
                      transitionBuilder: (child, animation) => !round.rise
                          ? FadeTransition(opacity: animation, child: child)
                          : FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                alignment: const Alignment(0, .35),
                                scale: Tween(begin: .82, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                                child: child,
                              ),
                            ),
                      child: Image.asset(
                        ChildCast.of(_picture),
                        key: ValueKey(_picture),
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  // Still yellowish; clears as the stains go.
                  if (current != null && round.tints.isNotEmpty)
                    for (final tint in round.tints)
                      at(
                        tint,
                        IgnorePointer(
                          child: Opacity(
                            opacity:
                                .55 *
                                (1 -
                                        _stains.indexed
                                                .map(
                                                  (e) => _cleaned.contains(e.$1)
                                                      ? 1.0
                                                      : (_scrub[e.$1] ?? 0)
                                                            .clamp(0.0, 1.0),
                                                )
                                                .fold(0.0, (a, b) => a + b) /
                                            math.max(1, _stains.length))
                                    .clamp(0.0, 1.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDB65E),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  for (var i = 0; i < round.steps.length; i++)
                    if (_placed.contains(i))
                      at(
                        round.steps[i].zone,
                        // While it is stirred, everything in the bowl goes round.
                        Transform.translate(
                          offset: stirring
                              ? Offset.fromDirection(
                                  _stirred / 55 + i * 1.7,
                                  size.shortestSide * .035,
                                )
                              : Offset.zero,
                          child: _onPicture(round.steps[i], size),
                        ),
                        key: ValueKey('scene-placed-$i'),
                      )
                    else if (round.steps[i].shadow)
                      at(
                        round.steps[i].zone,
                        // The piece's own shape, faint and without colour.
                        Opacity(
                          opacity: .34,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix(_ghost),
                            child: _onPicture(round.steps[i], size),
                          ),
                        ),
                        key: ValueKey('scene-shadow-$i'),
                      ),
                  if (_mixed) ..._saladPieces(size),
                  // The near side of the picture (a bowl's front wall): what
                  // is put in goes behind it.
                  if (round.front case final front?
                      when _picture == round.stage)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Image.asset(
                          front,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  // Stains fade as they are scrubbed; foam where the brush went.
                  if (current != null && current.mode == SceneStepMode.rub)
                    for (var i = 0; i < _stains.length; i++)
                      if (!_cleaned.contains(i))
                        at(
                          _stains[i],
                          IgnorePointer(
                            key: ValueKey('scene-spot-$i'),
                            child: Opacity(
                              opacity: (1 - (_scrub[i] ?? 0))
                                  .clamp(0.0, 1.0)
                                  .toDouble(),
                              child: CustomPaint(painter: _StainPainter(i)),
                            ),
                          ),
                        ),
                  if (_foam.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _foamTick,
                          builder: (context, _) => CustomPaint(
                            painter: _FoamPainter(
                              List.of(_foam),
                              DateTime.now().millisecondsSinceEpoch,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (round.recipe && !_done) _recipe(size),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  /// The picture recipe: what goes in; each one fades when it is in.
  Widget _recipe(Size size) {
    final pieces = [
      for (final s in round.steps)
        if (s.mode == SceneStepMode.place) s.piece,
    ];
    final side = math.min(size.height * .15, 48.0);
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < pieces.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: _step > i || _done ? .3 : 1,
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: _visual(pieces[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tray() {
    if (_done) return const SizedBox.shrink();
    final current = step;
    final hintLevel = _hintLevel;
    final placing = current.mode == SceneStepMode.place;
    final prompt = _step == 0
        ? (widget.hint.locale == 'en'
              ? widget.spec.promptEn
              : widget.spec.promptTr)
        : current.askText[_lang] ?? '';
    final shownPrompt = ChildCast.of(prompt);

    Widget piece(String id, double side) {
      final item = _item(id);
      final glow = hintLevel > 0 && id == current.piece
          ? SegColors.hintGlow
          : null;
      final faded = _hintLevel >= 3 && id != current.piece && _ready;
      final shaking = _shaking == id;
      final away = _dragId == id || _flight?.id == id;
      final canDrag = _ready && placing && !_busy;
      final key = _pieceKeys.putIfAbsent(id, GlobalKey.new);
      if (_gone.contains(id)) return SizedBox.square(key: key, dimension: side);
      return Semantics(
        button: true,
        label: item?.name(widget.hint.locale) ?? id,
        excludeSemantics: true,
        child: Opacity(
          opacity: away ? 0 : (faded ? .35 : 1),
          child: TweenAnimationBuilder<double>(
            key: ValueKey('scene-shake-$id-$shaking'),
            tween: Tween(begin: 0, end: shaking ? 1 : 0),
            duration: const Duration(milliseconds: 450),
            builder: (context, t, child) => Transform.translate(
              offset: Offset(ObjectMotion.shake(t) * 10, 0),
              child: child,
            ),
            child: SizedBox.square(
              key: key,
              dimension: side,
              child: GestureDetector(
                key: ValueKey('scene-piece-$id'),
                behavior: HitTestBehavior.opaque,
                // The piece is under the finger from the first touch.
                dragStartBehavior: DragStartBehavior.down,
                onTap: round.gentle || !canDrag
                    ? null
                    : () => _bring(id, _rectOf(key)),
                onPanStart: canDrag
                    ? (d) => setState(() {
                        _introSeen = true;
                        _dragId = id;
                        _dragSide = side;
                        _dragAt = _toRoot(d.globalPosition);
                      })
                    : null,
                onPanUpdate: canDrag
                    ? (d) {
                        if (_dragId != id) return;
                        setState(() => _dragAt = _toRoot(d.globalPosition));
                      }
                    : null,
                onPanEnd: canDrag ? (_) => _drop(id) : null,
                onPanCancel: canDrag ? () => _drop(id) : null,
                child: StagedObject(glow: glow, child: _visual(id)),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.hint.showLabels && shownPrompt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: SegSpace.s2),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SegSpace.s3,
                vertical: SegSpace.s2,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(SegRadius.md),
              ),
              child: Text(
                shownPrompt,
                textAlign: TextAlign.center,
                style: SegText.label,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              if (!placing) {
                final side = math.min(
                  math.min(box.maxWidth, box.maxHeight) * .8,
                  190.0,
                );
                return Center(
                  child: Opacity(
                    opacity: _toolAt != null || _flight?.id == current.piece
                        ? .2
                        : 1,
                    child: GestureDetector(
                      key: const ValueKey('scene-tool'),
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onPanStart: (d) => _toolMove(d.globalPosition, 0),
                      onPanUpdate: (d) =>
                          _toolMove(d.globalPosition, d.delta.distance),
                      onPanEnd: (_) => _toolDrop(),
                      onPanCancel: _toolDrop,
                      child: SizedBox.square(
                        key: _toolKey,
                        dimension: side,
                        child: StagedObject(
                          glow: hintLevel > 0 ? SegColors.hintGlow : null,
                          child: _visual(current.piece),
                        ),
                      ),
                    ),
                  ),
                );
              }
              // As many columns as keep the pieces biggest for a small hand.
              final count = _pieces.length;
              var columns = 1, side = 0.0;
              for (var c = 1; c <= 4; c++) {
                final rows = (count / c).ceil();
                final fits = math.min(box.maxWidth / c, box.maxHeight / rows);
                if (fits > side + 1) {
                  side = fits;
                  columns = c;
                }
              }
              side = math.min(side, 170);
              return Center(
                child: SizedBox(
                  width: columns * side,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [for (final id in _pieces) piece(id, side)],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The carried piece was let go.
  void _drop(String id) {
    final at = _dragAt;
    if (_dragId != id || at == null) return;
    final from = Rect.fromCenter(
      center: at,
      width: _dragSide,
      height: _dragSide,
    );
    setState(() {
      _dragId = null;
      _dragAt = null;
      _armIdle();
    });
    final stage = _rectOf(_stageKey);
    if (stage != null && stage.inflate(24).contains(at)) {
      _bring(id, from);
    } else {
      _flyBack(id, from);
    }
  }
}
