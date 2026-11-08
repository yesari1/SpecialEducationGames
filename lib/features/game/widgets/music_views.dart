import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../../../app/ui/game_object.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// "Sen de Çal": the instrument plays 2 to 4 beats, then the child plays the
/// same number. After a short quiet the taps are counted; too few or too many
/// only means listening again.
class EchoView extends StatefulWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;

  /// The clip that says "let's listen again".
  final Map<String, String> againAudio;
  const EchoView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
    this.againAudio = const {},
  });
  @override
  State<EchoView> createState() => _EchoViewState();
}

class _EchoViewState extends State<EchoView> {
  static const _beatGap = Duration(milliseconds: 800);
  static const _quiet = Duration(milliseconds: 1300);
  int _generation = -1, _taps = 0, _beat = 0;
  bool _listening = false, _yourTurn = false, _bounce = false;
  final List<Timer> _timers = [];
  Timer? _judge;

  int get beats => widget.spec.fillCount ?? 2;

  @override
  void initState() {
    super.initState();
    _generation = widget.hint.generation;
  }

  @override
  void didUpdateWidget(covariant EchoView old) {
    super.didUpdateWidget(old);
    if (widget.hint.generation != _generation) {
      _generation = widget.hint.generation;
      _stop();
      _taps = 0;
      _yourTurn = false;
      _listening = false;
    }
    if (widget.hint.visibleChoices > 0 &&
        !_listening &&
        !_yourTurn &&
        !widget.hint.celebrating) {
      _demonstrate();
    }
  }

  void _stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _judge?.cancel();
  }

  void _demonstrate() {
    _stop();
    _listening = true;
    _beat = 0;
    for (var i = 0; i < beats; i++) {
      _timers.add(Timer(_beatGap * i, () => _hit(demo: true)));
    }
    _timers.add(
      Timer(_beatGap * beats, () {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _yourTurn = true;
          _beat = 0;
          _taps = 0;
        });
      }),
    );
  }

  void _hit({bool demo = false}) {
    if (!mounted) return;
    widget.callbacks.onListen?.call(widget.spec.target);
    setState(() {
      _bounce = !_bounce;
      if (demo) _beat++;
    });
  }

  void _tap() {
    if (!_yourTurn || widget.hint.celebrating) return;
    _hit();
    setState(() => _taps++);
    _judge?.cancel();
    _judge = Timer(_quiet, _decide);
  }

  void _decide() {
    if (!mounted) return;
    if (_taps == beats) {
      setState(() => _yourTurn = false);
      widget.callbacks.onSelect(widget.spec.target);
      return;
    }
    final wrong = widget.spec.choices
        .where((c) => c.id != widget.spec.target.id)
        .firstOrNull;
    if (wrong != null) widget.callbacks.onSelect(wrong);
    setState(() {
      _yourTurn = false;
      _taps = 0;
    });
    final again = widget.againAudio[widget.hint.locale == 'en' ? 'en' : 'tr'];
    if (again != null) widget.callbacks.onSay?.call([again]);
    _timers.add(Timer(const Duration(milliseconds: 2200), () {
      if (mounted && !widget.hint.celebrating) _demonstrate();
    }));
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = _yourTurn ? _taps : _beat;
    return Column(
      children: [
        Text(
          widget.hint.locale == 'en'
              ? widget.spec.promptEn
              : widget.spec.promptTr,
          style: SegText.heading,
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: GestureDetector(
            key: const ValueKey('echo-instrument'),
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: AnimatedScale(
              scale: _bounce ? 1.06 : 1,
              duration: const Duration(milliseconds: 90),
              child: StagedObject(
                glow: _yourTurn ? SegColors.hintGlow : null,
                child: ItemVisual(widget.spec.target),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < beats; i++)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  i < filled ? Icons.circle : Icons.circle_outlined,
                  size: 26,
                  color: SegColors.accent,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Çal Bakalım": every instrument, nothing to get wrong; plays until the
/// child is done.
class FreePlayView extends StatelessWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  final String doneLabel;
  const FreePlayView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
    required this.doneLabel,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, box) {
            final rows = (spec.choices.length / 5).ceil();
            final side = (box.maxHeight / rows).clamp(60.0, 170.0);
            return Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final item in spec.choices)
                    SizedBox.square(
                      dimension: side,
                      child: PressableObject(
                        key: ValueKey('music-pad-${item.slug}'),
                        tapSound: false,
                        onTap: () => callbacks.onListen?.call(item),
                        child: Padding(
                          padding: const EdgeInsets.all(SegSpace.s2),
                          child: StagedObject(child: ItemVisual(item)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(width: SegSpace.s3),
      SegButton(
        key: const ValueKey('music-done'),
        label: doneLabel,
        icon: Icons.check_rounded,
        onPressed: hint.celebrating
            ? null
            : () => callbacks.onSelect(spec.target),
      ),
    ],
  );
}
