import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../../../app/ui/game_object.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// The eight keys of the toy piano, low to high.
const pianoNotes = ['do', 're', 'mi', 'fa', 'sol', 'la', 'si', 'do2'];
const _noteNames = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si', 'Do'];
const _keyColours = [
  Color(0xFFE76F8E),
  Color(0xFFFF8A32),
  Color(0xFFFFC546),
  Color(0xFF6CC66B),
  Color(0xFF10B7B0),
  Color(0xFF63C6F4),
  Color(0xFF1687D9),
  Color(0xFF7C73DF),
];

String pianoClip(int key) => 'assets/sfx/piano/${pianoNotes[key]}.mp3';

/// "Sen de Çal": a piano. It plays a few notes (the keys light up), then the
/// child plays the same notes in the same order. A wrong key or a long wait
/// shows which key comes next; nothing is lost. On the hard level some notes
/// are long: the key is held down.
class EchoView extends StatefulWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  const EchoView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
  });
  @override
  State<EchoView> createState() => _EchoViewState();
}

class _EchoViewState extends State<EchoView> {
  static const _short = Duration(milliseconds: 550);
  static const _long = Duration(milliseconds: 1200);
  static const _gap = Duration(milliseconds: 260);
  static const _holdNeeded = Duration(milliseconds: 550);

  int _generation = -1;

  /// The demo's lit key; the child's place in the tune; the key shown as
  /// the next one after a mistake or a wait; the key under the finger.
  int? _lit, _shown, _pressed, _shaking;
  int _at = 0;
  bool _demo = false, _turn = false;
  DateTime? _pressedAt;
  final List<Timer> _timers = [];
  Timer? _wait;

  List<int> get notes => widget.spec.notes;
  bool _isLong(int index) => widget.spec.longNotes.contains(index);

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
      _at = 0;
      _turn = false;
      _demo = false;
      _shown = null;
    }
    if (widget.hint.visibleChoices > 0 &&
        !_demo &&
        !_turn &&
        !widget.hint.celebrating) {
      _demonstrate();
    }
  }

  void _stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _wait?.cancel();
  }

  void _play(int key) => widget.callbacks.onSay?.call([pianoClip(key)]);

  void _demonstrate() {
    _stop();
    setState(() {
      _demo = true;
      _turn = false;
      _at = 0;
      _shown = null;
    });
    var when = const Duration(milliseconds: 500);
    for (var i = 0; i < notes.length; i++) {
      final key = notes[i];
      final held = _isLong(i) ? _long : _short;
      _timers.add(
        Timer(when, () {
          if (!mounted) return;
          _play(key);
          setState(() {
            _lit = key;
            _at = i + 1;
          });
        }),
      );
      _timers.add(
        Timer(when + held, () {
          if (mounted) setState(() => _lit = null);
        }),
      );
      when += held + _gap;
    }
    _timers.add(
      Timer(when + const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          _demo = false;
          _turn = true;
          _at = 0;
        });
        _armWait();
      }),
    );
  }

  /// A child who waits is shown the next key.
  void _armWait() {
    _wait?.cancel();
    _wait = Timer(const Duration(seconds: 5), () {
      if (mounted && _turn && _at < notes.length) {
        setState(() => _shown = notes[_at]);
      }
    });
  }

  void _down(int key) {
    if (widget.hint.celebrating || _demo) return;
    _play(key);
    setState(() {
      _pressed = key;
      _pressedAt = DateTime.now();
    });
    if (!_turn) return;
    if (key != notes[_at]) {
      final wrong = widget.spec.choices
          .where((c) => c.id != widget.spec.target.id)
          .firstOrNull;
      if (wrong != null) widget.callbacks.onSelect(wrong);
      setState(() {
        _shaking = key;
        _shown = notes[_at];
      });
      _timers.add(
        Timer(const Duration(milliseconds: 450), () {
          if (mounted) setState(() => _shaking = null);
        }),
      );
      _armWait();
      return;
    }
    // A short note counts at once; a long one when it has been held.
    if (!_isLong(_at)) _advance();
  }

  void _up(int key) {
    final since = _pressedAt;
    final was = _pressed;
    setState(() => _pressed = null);
    if (!_turn || was != key || since == null || _at >= notes.length) return;
    if (key != notes[_at] || !_isLong(_at)) return;
    if (DateTime.now().difference(since) >= _holdNeeded) {
      _advance();
    } else {
      // Let go too soon: the same key again, and longer.
      setState(() => _shown = key);
      _armWait();
    }
  }

  void _advance() {
    setState(() {
      _at++;
      _shown = null;
    });
    if (_at < notes.length) return _armWait();
    _wait?.cancel();
    setState(() => _turn = false);
    widget.callbacks.onSelect(widget.spec.target);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.hint.locale == 'en';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The tune: one mark for each note, a long mark for a long note.
            for (var i = 0; i < notes.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: _isLong(i) ? 46 : 22,
                height: 22,
                decoration: BoxDecoration(
                  color: i < _at
                      ? _keyColours[notes[i]]
                      : Colors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(SegRadius.pill),
                  border: Border.all(color: _keyColours[notes[i]], width: 3),
                ),
              ),
            const SizedBox(width: SegSpace.s4),
            // Listen once more.
            Semantics(
              button: true,
              label: en ? 'Listen again' : 'Bir daha dinle',
              child: GestureDetector(
                key: const ValueKey('piano-again'),
                onTap: _demo || widget.hint.celebrating ? null : _demonstrate,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.replay_rounded,
                    color: _demo ? SegColors.inkFaint : SegColors.primaryDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SegSpace.s3),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4A3A),
                  borderRadius: BorderRadius.circular(SegRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: SegColors.ink.withValues(alpha: .18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var key = 0; key < pianoNotes.length; key++)
                      Expanded(child: _key(key)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _key(int key) {
    final colour = _keyColours[key];
    final down = _pressed == key || _lit == key;
    final next = _shown == key && _turn;
    final holding =
        _pressed == key && _turn && _at < notes.length && _isLong(_at);
    return Semantics(
      button: true,
      label: _noteNames[key],
      excludeSemantics: true,
      child: Listener(
        key: ValueKey('piano-key-$key'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _down(key),
        onPointerUp: (_) => _up(key),
        onPointerCancel: (_) => _up(key),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('piano-shake-$key-${_shaking == key}'),
          tween: Tween(begin: 0, end: _shaking == key ? 1 : 0),
          duration: const Duration(milliseconds: 400),
          builder: (context, t, child) => Transform.translate(
            offset: Offset(ObjectMotion.shake(t) * 6, 0),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            margin: EdgeInsets.fromLTRB(4, 0, 4, down ? 0 : 8),
            decoration: BoxDecoration(
              color: down ? colour : Color.lerp(Colors.white, colour, .16),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(18),
              ),
              border: Border.all(
                color: next ? SegColors.star : colour,
                width: next ? 6 : 3,
              ),
              boxShadow: [
                if (next)
                  BoxShadow(
                    color: SegColors.star.withValues(alpha: .7),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                if (!down)
                  BoxShadow(
                    color: Color.lerp(colour, SegColors.ink, .35)!,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (next)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Icon(
                      Icons.touch_app_rounded,
                      size: 40,
                      color: SegColors.accent,
                    ),
                  ),
                // Holding a long note fills the key's bar.
                if (holding)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: _holdNeeded,
                      builder: (context, t, _) => LinearProgressIndicator(
                        value: t,
                        minHeight: 8,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: FittedBox(
                    child: Text(
                      _noteNames[key],
                      style: SegText.heading.copyWith(
                        fontWeight: FontWeight.w900,
                        color: down
                            ? Colors.white
                            : Color.lerp(colour, SegColors.ink, .45),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Çal Bakalım": every instrument and nothing to finish. The child taps
/// whatever they like for as long as they like and leaves with the back
/// button; there are no stars and no "done".
class FreePlayView extends StatelessWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  const FreePlayView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final count = spec.choices.length;
      // As many columns as keep the instruments biggest.
      var side = 0.0;
      for (var columns = 1; columns <= count; columns++) {
        final rows = (count / columns).ceil();
        final fits = [
          box.maxWidth / columns,
          box.maxHeight / rows,
        ].reduce((a, b) => a < b ? a : b);
        if (fits > side) side = fits;
      }
      side = side.clamp(60.0, 190.0);
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
  );
}
