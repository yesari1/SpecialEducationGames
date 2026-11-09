import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../../../app/ui/game_object.dart';
import '../../../core/audio/audio_service.dart' show UiSound;
import '../../../core/content/content_repository.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// A game played on a picture ([SceneRound]): the pieces wait in the tray,
/// the right one is dragged to the picture (tapping works too) and the
/// picture changes. Rub steps clean the spots away, stir steps go round.
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
  static const _colors = [Color(0xFFA47B3B), Color(0xFFC49A52), Color(0xFF8A6A35)];
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
        final point = centre + Offset.fromDirection(angle, base * (.6 + random.nextDouble() * .7));
        c == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = _colors[random.nextInt(_colors.length)].withValues(alpha: .92)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_StainPainter old) => old.seed != seed;
}

class _SceneGameViewState extends State<SceneGameView>
    with SingleTickerProviderStateMixin {
  SceneRound get round => widget.spec.scene!;
  int _step = 0;
  int _generation = -1;
  String _picture = '';
  final Set<int> _placed = {};
  final Set<int> _cleaned = {};
  String? _shaking;
  Offset? _tool;
  double _stirred = 0;
  int _stirTaps = 0;
  bool _done = false;
  late List<String> _pieces;

  /// The hint level when this step began: a new step starts without hints.
  int _hintBase = 0;

  // The finger that shows how to drag: when the game opens and again after
  // six seconds with no touch.
  final _rootKey = GlobalKey();
  final _stageKey = GlobalKey();
  final _pieceKeys = <String, GlobalKey>{};
  late final AnimationController _finger = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  (Offset, Offset)? _guide;
  bool _introSeen = false, _dragging = false, _idle = false;
  Timer? _idleTimer;
  bool get _wantsGuide =>
      _ready &&
      !_dragging &&
      step.mode == SceneStepMode.place &&
      (!_introSeen || _idle);

  void _armIdle() {
    _idle = false;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 6), () {
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
  void didUpdateWidget(covariant SceneGameView old) {
    super.didUpdateWidget(old);
    if (widget.hint.generation != _generation) _reset();
  }

  void _reset() {
    _generation = widget.hint.generation;
    _step = 0;
    _picture = round.stage;
    _placed.clear();
    _done = false;
    _enterStep();
  }

  void _enterStep() {
    _armIdle();
    _hintBase = widget.hint.level;
    _cleaned.clear();
    _tool = null;
    _stirred = 0;
    _stirTaps = 0;
    if (round.gentle) {
      // The same places all round; a placed piece just leaves the tray.
      _pieces = [for (final s in round.steps.skip(_step)) s.piece]
        ..shuffle(math.Random(_generation * 31));
      final order = [for (final s in round.steps) s.piece]
        ..shuffle(math.Random(_generation * 31));
      _pieces.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    } else {
      _pieces = [step.piece, ...step.others]
        ..shuffle(math.Random(_generation * 31 + _step));
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _finger.dispose();
    super.dispose();
  }

  /// From the asked piece to its place, measured where they really are.
  void _updateGuide() {
    if (!mounted) return;
    (Offset, Offset)? next;
    if (_wantsGuide) {
      final root = _rootKey.currentContext?.findRenderObject() as RenderBox?;
      final piece =
          _pieceKeys[step.piece]?.currentContext?.findRenderObject()
              as RenderBox?;
      final stage = _stageKey.currentContext?.findRenderObject() as RenderBox?;
      if (root != null && piece != null && stage != null) {
        final zone = step.zone;
        next = (
          root.globalToLocal(
            piece.localToGlobal(piece.size.center(Offset.zero)),
          ),
          root.globalToLocal(
            stage.localToGlobal(
              Offset(
                (zone.x + zone.w / 2) * stage.size.width,
                (zone.y + zone.h / 2) * stage.size.height,
              ),
            ),
          ),
        );
      }
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
        return Positioned(
          left: at.dx - 22,
          top: at.dy - 8,
          child: IgnorePointer(
            child: Opacity(
              opacity: fade,
              child: const Icon(
                Icons.touch_app_rounded,
                size: 68,
                color: SegColors.accent,
                shadows: [Shadow(color: Colors.white, blurRadius: 10)],
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

  void _bring(String id) {
    if (!_ready) return;
    if (step.mode != SceneStepMode.place) return;
    if (id != step.piece) {
      if (!round.gentle) return _wrong(id);
      _introSeen = true;
      final ask = (_step == 0 ? round.audio : step.askAudio)[_lang];
      if (ask != null) widget.callbacks.onSay?.call([ask]);
      return;
    }
    UiSound.basketDrop();
    _complete();
  }

  void _complete() {
    final finished = step;
    final last = _step == round.steps.length - 1;
    _introSeen = true;
    setState(() {
      if (finished.stays) _placed.add(_step);
      if (finished.after case final after?) {
        _picture = after;
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
    if (_cleaned.length == step.spots.length) _complete();
  }

  void _rubAt(Offset point, Size size) {
    setState(() => _tool = point);
    if (step.mode != SceneStepMode.rub) return;
    final reach = size.shortestSide * .09;
    for (var i = 0; i < step.spots.length; i++) {
      final s = step.spots[i];
      final centre = Offset(
        (s.x + s.w / 2) * size.width,
        (s.y + s.h / 2) * size.height,
      );
      if ((centre - point).distance <= reach + s.w * size.width / 2) _clean(i);
      if (_step >= round.steps.length || _done) return;
    }
  }

  void _stirBy(double distance) {
    if (!_ready || step.mode != SceneStepMode.stir) return;
    _stirred += distance;
    if (_stirred >= _stirDistance) _complete();
  }

  void _stirTap() {
    if (!_ready || step.mode != SceneStepMode.stir) return;
    _stirTaps++;
    UiSound.tap();
    setState(() {});
    if (_stirTaps >= _stirTapsNeeded) _complete();
  }

  ContentItem? _item(String id) => widget.spec.scenePieces[id];

  /// A piece as it lies on the picture, turned if its step says so.
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
        final trayWidth = math.min(box.maxWidth * .34, 320.0);
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: Center(child: _stage())),
                    const SizedBox(width: SegSpace.s3),
                    SizedBox(width: trayWidth, child: _tray()),
                  ],
                ),
              ),
              if (_guide != null) _fingerOverlay(),
            ],
          ),
        );
      },
    );
  }

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
        final hinting = _hintLevel > 0 && _ready;
        final toolMode = current != null && current.mode != SceneStepMode.place;
        return DragTarget<String>(
          key: _stageKey,
          onWillAcceptWithDetails: (_) => _ready,
          onAcceptWithDetails: (d) => _bring(d.data),
          builder: (context, _, _) => GestureDetector(
            key: const ValueKey('scene-stage'),
            behavior: HitTestBehavior.opaque,
            onTap: toolMode && current.mode == SceneStepMode.stir
                ? _stirTap
                : null,
            onPanStart: toolMode
                ? (d) => _ready ? _rubAt(d.localPosition, size) : null
                : null,
            onPanUpdate: toolMode
                ? (d) {
                    if (!_ready) return;
                    _rubAt(d.localPosition, size);
                    _stirBy(d.delta.distance);
                  }
                : null,
            onPanEnd: toolMode ? (_) => setState(() => _tool = null) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SegRadius.lg),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: widget.hint.animate
                          ? const Duration(milliseconds: 450)
                          : Duration.zero,
                      child: Image.asset(
                        _picture,
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
                                    _cleaned.length /
                                        math.max(1, current.spots.length)),
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
                        HopIn(child: _onPicture(round.steps[i], size)),
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
                  if (current != null && current.mode == SceneStepMode.rub)
                    for (var i = 0; i < current.spots.length; i++)
                      if (!_cleaned.contains(i))
                        at(
                          current.spots[i],
                          GestureDetector(
                            key: ValueKey('scene-spot-$i'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _clean(i),
                            child: CustomPaint(painter: _StainPainter(i)),
                          ),
                        ),
                  if (hinting)
                    at(
                      current!.zone,
                      IgnorePointer(
                        child: DecoratedBox(
                          key: const ValueKey('scene-hint'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SegColors.star.withValues(alpha: .28),
                            border: Border.all(
                              color: SegColors.star,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (round.recipe && !_done) _recipe(size),
                  if (toolMode && _tool != null)
                    Positioned(
                      left: _tool!.dx - size.shortestSide * .17,
                      top: _tool!.dy - size.shortestSide * .17,
                      width: size.shortestSide * .34,
                      height: size.shortestSide * .34,
                      child: IgnorePointer(child: _visual(current.piece)),
                    ),
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
    final side = math.min(size.height * .17, 56.0);
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
    final prompt = _step == 0
        ? (widget.hint.locale == 'en'
              ? widget.spec.promptEn
              : widget.spec.promptTr)
        : current.askText[_lang] ?? '';
    Widget piece(String id) {
      final item = _item(id);
      final glow = hintLevel > 0 && id == current.piece
          ? SegColors.hintGlow
          : null;
      final faded =
          _hintLevel >= 3 && id != current.piece && _ready;
      final visual = StagedObject(glow: glow, child: _visual(id));
      final shaking = _shaking == id;
      return Expanded(
        child: Semantics(
          button: true,
          label: item?.name(widget.hint.locale) ?? id,
          excludeSemantics: true,
          child: Opacity(
            opacity: faded ? .35 : 1,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('scene-piece-$_step-$id-$shaking'),
              tween: Tween(begin: 0, end: shaking ? 1 : 0),
              duration: const Duration(milliseconds: 450),
              builder: (context, t, child) => Transform.translate(
                offset: Offset(ObjectMotion.shake(t) * 10, 0),
                child: child,
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final side = math.min(box.maxWidth, box.maxHeight);
                  // The shadow stays under the piece however much room there is.
                  final sized = Center(
                    child: SizedBox.square(
                      dimension: math.min(side, 170),
                      child: visual,
                    ),
                  );
                  return Draggable<String>(
                    key: _pieceKeys.putIfAbsent(id, GlobalKey.new),
                    data: id,
                    onDragStarted: () => setState(() => _dragging = true),
                    onDragEnd: (_) => setState(() {
                      _dragging = false;
                      _armIdle();
                    }),
                    maxSimultaneousDrags:
                        _ready && current.mode == SceneStepMode.place ? 1 : 0,
                    feedback: SizedBox(
                      width: side,
                      height: side,
                      child: Material(
                        type: MaterialType.transparency,
                        child: _visual(id),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: .25, child: sized),
                    child: GestureDetector(
                      key: ValueKey('scene-piece-$id'),
                      behavior: HitTestBehavior.opaque,
                      onTap: round.gentle ? null : () => _bring(id),
                      child: sized,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.hint.showLabels && prompt.isNotEmpty)
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
                prompt,
                textAlign: TextAlign.center,
                style: SegText.label,
              ),
            ),
          ),
        if (current.mode == SceneStepMode.place)
          // Two side by side, so each piece stays big enough for a small hand.
          for (var i = 0; i < _pieces.length; i += 2)
            Expanded(
              child: Row(
                children: [
                  for (final id in _pieces.skip(i).take(2)) piece(id),
                ],
              ),
            )
        else
          Expanded(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: .8,
                heightFactor: .8,
                child: StagedObject(
                  glow: hintLevel > 0 ? SegColors.hintGlow : null,
                  child: _visual(current.piece),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
