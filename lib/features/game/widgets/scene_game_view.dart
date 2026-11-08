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

class _SceneGameViewState extends State<SceneGameView> {
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

  static const _stirDistance = 1400.0;
  static const _stirTapsNeeded = 4;

  SceneStep get step => round.steps[_step];
  bool get _ready =>
      widget.hint.visibleChoices > 0 && !widget.hint.celebrating && !_done;
  String get _lang => widget.hint.locale == 'en' ? 'en' : 'tr';

  @override
  void initState() {
    super.initState();
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
    _cleaned.clear();
    _tool = null;
    _stirred = 0;
    _stirTaps = 0;
    _pieces = [step.piece, ...step.others]
      ..shuffle(math.Random(_generation * 31 + _step));
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
    if (id != step.piece) return _wrong(id);
    UiSound.basketDrop();
    _complete();
  }

  void _complete() {
    final finished = step;
    final last = _step == round.steps.length - 1;
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

  Widget _visual(String id) {
    final item = _item(id);
    return item == null ? const SizedBox.shrink() : ItemVisual(item);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final trayWidth = math.min(box.maxWidth * .34, 320.0);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Center(child: _stage())),
          const SizedBox(width: SegSpace.s3),
          SizedBox(width: trayWidth, child: _tray()),
        ],
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
        final hinting = widget.hint.level > 0 && _ready;
        final toolMode = current != null && current.mode != SceneStepMode.place;
        return DragTarget<String>(
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
                  for (var i = 0; i < round.steps.length; i++)
                    if (_placed.contains(i))
                      at(
                        round.steps[i].zone,
                        HopIn(child: _visual(round.steps[i].piece)),
                        key: ValueKey('scene-placed-$i'),
                      )
                    else if (round.steps[i].shadow)
                      at(
                        round.steps[i].zone,
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            SegColors.ink.withValues(alpha: .28),
                            BlendMode.srcIn,
                          ),
                          child: _visual(round.steps[i].piece),
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
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xCCC9A24A),
                              ),
                            ),
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
                  if (round.recipe) _recipe(size),
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
    final hintLevel = widget.hint.level;
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
          widget.hint.level >= 3 && id != current.piece && _ready;
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
                  return Draggable<String>(
                    data: id,
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
                    childWhenDragging: Opacity(opacity: .25, child: visual),
                    child: GestureDetector(
                      key: ValueKey('scene-piece-$id'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _bring(id),
                      child: visual,
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
