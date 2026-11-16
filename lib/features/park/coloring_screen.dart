import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import 'park_scaffold.dart';

const _paints = [
  Color(0xFFE5534B), Color(0xFFFF8A32), Color(0xFFFFC546), Color(0xFF6CC66B), //
  Color(0xFF10B7B0), Color(0xFF1687D9), Color(0xFF7C73DF), Color(0xFFE76F8E),
  Color(0xFF9B6A43), Color(0xFF63C6F4), Color(0xFF8E9AA6), Color(0xFF2F3E4D),
];

/// Boyama: the child picks a drawing, then a colour, then taps a part of the
/// drawing and a brush paints it. There is nothing wrong to do here.
class ColoringScreen extends StatefulWidget {
  final AppState state;
  const ColoringScreen({super.key, required this.state});
  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  AppState get s => widget.state;
  String? _page;

  @override
  void initState() {
    super.initState();
    s.enterGame();
  }

  @override
  void dispose() {
    s.leaveGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = parkL10n(context, s);
    final page = _page;
    return ParkScaffold(
      title: l10n.parkColoring,
      background: 'assets/illustrations/home/bg_park.jpg',
      onBack: () =>
          page == null ? context.go('/') : setState(() => _page = null),
      child: page == null
          ? _picker()
          : _PaintingBoard(key: ValueKey(page), state: s, name: page),
    );
  }

  /// The drawings side by side, big enough to see what each one is; the
  /// row scrolls sideways like the rest of the Play Park.
  Widget _picker() => LayoutBuilder(
    builder: (context, box) {
      final side = (box.maxHeight - SegSpace.s5).clamp(120.0, 300.0);
      return Center(
        child: SizedBox(
          height: side,
          child: ListView.separated(
            key: const ValueKey('coloring-picker'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SegSpace.s5),
            itemCount: s.content.coloringPages.length,
            separatorBuilder: (_, _) => const SizedBox(width: SegSpace.s4),
            itemBuilder: (context, i) {
              final name = s.content.coloringPages[i];
              return GestureDetector(
                key: ValueKey('coloring-page-$name'),
                onTap: () {
                  UiSound.tap();
                  setState(() => _page = name);
                },
                child: Container(
                  width: side,
                  padding: const EdgeInsets.all(SegSpace.s3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(SegRadius.lg),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C73DF).withValues(alpha: .22),
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/coloring/${name}_line.png',
                    excludeFromSemantics: true,
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _PaintingBoard extends StatefulWidget {
  final AppState state;
  final String name;
  const _PaintingBoard({super.key, required this.state, required this.name});
  @override
  State<_PaintingBoard> createState() => _PaintingBoardState();
}

class _PaintingBoardState extends State<_PaintingBoard>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  /// The opening demonstration: the finger taps the chosen colour, then a
  /// part of the drawing; the part is painted for a moment and turns white
  /// again (Yunus, 16 November 2026).
  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  Uint8List? _regions;
  int _width = 0, _height = 0;
  final Map<int, Color> _colors = {};
  ui.Image? _before, _after;
  Offset _tap = Offset.zero;
  Color _paint = _paints.first;
  final _rootKey = GlobalKey();
  final _boardKey = GlobalKey();
  final _chipKeys = List.generate(_paints.length, (_) => GlobalKey());

  /// The colour carried from a chip to the drawing, under the finger (in
  /// the root's coordinates).
  Offset? _carry;
  (Offset, Offset)? _demoPath;
  Offset? _demoPoint;
  int? _demoRegion;
  bool _demoPainted = false;

  @override
  void initState() {
    super.initState();
    _demo.addListener(_demoTick);
    unawaited(_load());
  }

  Future<void> _load() async {
    final data = await rootBundle.load(
      'assets/coloring/${widget.name}_regions.png',
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData();
    if (!mounted || bytes == null) return;
    final w = frame.image.width, h = frame.image.height;
    final map = Uint8List(w * h);
    for (var i = 0; i < w * h; i++) {
      map[i] = bytes.getUint8(i * 4);
    }
    _regions = map;
    _width = w;
    _height = h;
    final blank = await _compose();
    if (!mounted) return;
    setState(() => _before = _after = blank);
    // "Elmayı istediğin renge boyayabilirsin." and the finger shows how.
    final lang = widget.state.locale == 'en' ? 'en' : 'tr';
    unawaited(
      widget.state.audio.playSequence([
        'assets/audio/$lang/coloring/${widget.name}.mp3',
      ]),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDemo());
  }

  void _startDemo() {
    if (!mounted || _regions == null) return;
    final root = _rectOf(_rootKey);
    final chip = _rectOf(_chipKeys[_paints.indexOf(_paint)]);
    final board = _rectOf(_boardKey);
    final point = _demoSpot();
    if (root == null || chip == null || board == null || point == null) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) return;
    final side = board.width;
    final local = Offset(point.$1 / _width * side, point.$2 / _height * side);
    setState(() {
      _demoRegion = point.$3;
      _demoPoint = local;
      _demoPainted = false;
      _demoPath = (
        chip.center - root.topLeft,
        board.topLeft - root.topLeft + local,
      );
    });
    unawaited(_demo.forward(from: 0));
  }

  /// A point inside the biggest part of the drawing (not the space around
  /// it), as (x, y, region) in the region map's pixels.
  (int, int, int)? _demoSpot() {
    final map = _regions!;
    final outside = map[0];
    final counts = <int, int>{};
    final sx = <int, int>{}, sy = <int, int>{};
    for (var y = 0; y < _height; y += 2) {
      for (var x = 0; x < _width; x += 2) {
        final id = map[y * _width + x];
        if (id == 0 || id == outside) continue;
        counts[id] = (counts[id] ?? 0) + 1;
        sx[id] = (sx[id] ?? 0) + x;
        sy[id] = (sy[id] ?? 0) + y;
      }
    }
    if (counts.isEmpty) return null;
    final id = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final cx = sx[id]! / counts[id]!, cy = sy[id]! / counts[id]!;
    (int, int, int)? best;
    var bestDist = double.infinity;
    for (var y = 0; y < _height; y += 2) {
      for (var x = 0; x < _width; x += 2) {
        if (map[y * _width + x] != id) continue;
        final d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
        if (d < bestDist) {
          bestDist = d;
          best = (x, y, id);
        }
      }
    }
    return best;
  }

  void _demoTick() {
    final t = _demo.value;
    final region = _demoRegion;
    if (region == null) return;
    if (!_demoPainted && t >= .58) {
      _demoPainted = true;
      unawaited(_fill(region, _paint, _demoPoint!));
    }
    if (_demoPainted && t >= .86 && _colors.containsKey(region)) {
      unawaited(_unfill(region));
    }
    if (t >= 1) _stopDemo();
  }

  /// The child takes over: the demonstration stops and its paint goes.
  void _stopDemo() {
    if (_demoPath == null) return;
    _demo.stop();
    final region = _demoRegion;
    setState(() {
      _demoPath = null;
      _demoRegion = null;
    });
    if (region != null && _demoPainted && _colors.containsKey(region)) {
      unawaited(_unfill(region));
    }
  }

  Future<void> _unfill(int region) async {
    _colors.remove(region);
    final blank = await _compose();
    if (!mounted) return;
    _sweep.stop();
    setState(() => _before = _after = blank);
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<ui.Image> _compose() {
    final pixels = Uint8List(_width * _height * 4)
      ..fillRange(0, _width * _height * 4, 255);
    final map = _regions!;
    for (var i = 0; i < map.length; i++) {
      final color = _colors[map[i]];
      if (color == null) continue;
      pixels[i * 4] = (color.r * 255).round();
      pixels[i * 4 + 1] = (color.g * 255).round();
      pixels[i * 4 + 2] = (color.b * 255).round();
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      _width,
      _height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }

  Future<void> _paintAt(Offset point, double side) async {
    final map = _regions;
    if (map == null || _sweep.isAnimating) return;
    final x = (point.dx / side * _width).floor().clamp(0, _width - 1);
    final y = (point.dy / side * _height).floor().clamp(0, _height - 1);
    final region = _nearestRegion(x, y);
    if (region == 0) return;
    await _fill(region, _paint, point);
  }

  Future<void> _fill(int region, Color color, Offset point) async {
    _colors[region] = color;
    UiSound.tap();
    final next = await _compose();
    if (!mounted) return;
    setState(() {
      _before = _after;
      _after = next;
      _tap = point;
    });
    unawaited(_sweep.forward(from: 0));
  }

  /// The drawn line itself counts as the part next to it.
  int _nearestRegion(int x, int y) {
    final map = _regions!;
    for (var reach = 0; reach <= 6; reach++) {
      for (var dy = -reach; dy <= reach; dy++) {
        for (var dx = -reach; dx <= reach; dx++) {
          final nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= _width || ny >= _height) continue;
          final id = map[ny * _width + nx];
          if (id != 0) return id;
        }
      }
    }
    return 0;
  }

  /// A colour is chosen on the first touch, before the finger lifts or
  /// moves.
  void _choose(int i) {
    _stopDemo();
    if (_paint == _paints[i]) return;
    UiSound.tap();
    setState(() => _paint = _paints[i]);
  }

  /// A colour pressed and carried onto the drawing paints where it is let
  /// go; the brush is under the finger all the way.
  void _carryTo(Offset global) {
    final root = _rectOf(_rootKey);
    if (root == null) return;
    setState(() => _carry = global - root.topLeft);
  }

  void _drop() {
    final carry = _carry;
    setState(() => _carry = null);
    final root = _rectOf(_rootKey), board = _rectOf(_boardKey);
    if (carry == null || root == null || board == null) return;
    final local = carry + root.topLeft - board.topLeft;
    if (!(Offset.zero & board.size).contains(local)) return;
    unawaited(_paintAt(local, board.width));
  }

  @override
  void dispose() {
    _demo.dispose();
    _sweep.dispose();
    super.dispose();
  }

  Widget _brush(Color color) => Icon(
    Icons.brush_rounded,
    size: 64,
    color: color,
    shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
  );

  /// The finger of the demonstration: to the colour, a tap, to the drawing,
  /// a tap, then it fades.
  Widget _demoFinger() {
    final path = _demoPath!;
    return AnimatedBuilder(
      key: const ValueKey('coloring-demo-finger'),
      animation: _demo,
      builder: (context, _) {
        final t = _demo.value;
        final start = path.$1 + const Offset(90, 70);
        final Offset at;
        if (t < .18) {
          at = Offset.lerp(start, path.$1, Curves.easeOut.transform(t / .18))!;
        } else if (t < .3) {
          at = path.$1;
        } else if (t < .52) {
          at = Offset.lerp(
            path.$1,
            path.$2,
            Curves.easeInOut.transform((t - .3) / .22),
          )!;
        } else {
          at = path.$2;
        }
        final press = (t > .22 && t < .28) || (t > .54 && t < .6) ? .85 : 1.0;
        final fade = t < .06
            ? t / .06
            : t > .9
            ? (1 - t) / .1
            : 1.0;
        return Positioned(
          left: at.dx - 22,
          top: at.dy - 6,
          child: IgnorePointer(
            child: Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: press,
                child: const Icon(
                  Icons.touch_app_rounded,
                  size: 68,
                  color: SegColors.accent,
                  shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      SegSpace.s4,
      0,
      SegSpace.s4,
      SegSpace.s3,
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final side = box.maxHeight;
        return Stack(
          key: _rootKey,
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SegRadius.md),
                  child: SizedBox.square(
                    key: _boardKey,
                    dimension: side,
                    child: GestureDetector(
                      key: const ValueKey('coloring-board'),
                      onTapDown: (_) => _stopDemo(),
                      onTapUp: (d) => _paintAt(d.localPosition, side),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Colors.white),
                          if (_before != null)
                            RawImage(image: _before, fit: BoxFit.fill),
                          if (_after != null)
                            AnimatedBuilder(
                              animation: _sweep,
                              builder: (context, _) => ClipPath(
                                clipper: _CircleReveal(
                                  _tap,
                                  _sweep.isDismissed ? 1 : _sweep.value,
                                ),
                                child: RawImage(
                                  image: _after,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          Image.asset(
                            'assets/coloring/${widget.name}_line.png',
                            fit: BoxFit.fill,
                            excludeFromSemantics: true,
                          ),
                          AnimatedBuilder(
                            animation: _sweep,
                            builder: (context, _) {
                              if (!_sweep.isAnimating) {
                                return const SizedBox.shrink();
                              }
                              final t = _sweep.value;
                              final wave = math.sin(t * math.pi * 4);
                              return Positioned(
                                key: const ValueKey('coloring-brush'),
                                left: _tap.dx - 20 + wave * side * .06,
                                top: _tap.dy - 60,
                                child: _brush(_paint),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SegSpace.s5),
                // Every colour fits the height: three columns, never a
                // colour out of reach. The chosen one is big and holds the
                // brush.
                Builder(
                  builder: (context) {
                    const columns = 3, gap = SegSpace.s3;
                    final rows = (_paints.length / columns).ceil();
                    final chip = ((side - gap * (rows - 1)) / rows).clamp(
                      36.0,
                      76.0,
                    );
                    return SizedBox(
                      key: const ValueKey('coloring-paints'),
                      width: chip * columns + gap * (columns - 1),
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (var i = 0; i < _paints.length; i++)
                            GestureDetector(
                              key: ValueKey('coloring-paint-$i'),
                              onTapDown: (_) => _choose(i),
                              onPanDown: (_) => _choose(i),
                              onPanStart: (d) => _carryTo(d.globalPosition),
                              onPanUpdate: (d) => _carryTo(d.globalPosition),
                              onPanEnd: (_) => _drop(),
                              onPanCancel: () => setState(() => _carry = null),
                              child: AnimatedScale(
                                key: _chipKeys[i],
                                scale: _paint == _paints[i] ? 1.12 : .88,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  width: chip,
                                  height: chip,
                                  decoration: BoxDecoration(
                                    color: _paints[i],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: _paint == _paints[i] ? 5 : 3,
                                    ),
                                    boxShadow: [
                                      if (_paint == _paints[i])
                                        BoxShadow(
                                          color: _paints[i].withValues(
                                            alpha: .6,
                                          ),
                                          blurRadius: 14,
                                          spreadRadius: 2,
                                        ),
                                    ],
                                  ),
                                  child: _paint == _paints[i]
                                      ? Icon(
                                          Icons.brush_rounded,
                                          color: Colors.white,
                                          size: chip * .5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            // The brush goes where the finger carries the colour.
            if (_carry case final carry?)
              Positioned(
                key: const ValueKey('coloring-carry'),
                left: carry.dx - 20,
                top: carry.dy - 60,
                child: IgnorePointer(child: _brush(_paint)),
              ),
            if (_demoPath != null) _demoFinger(),
          ],
        );
      },
    ),
  );
}

class _CircleReveal extends CustomClipper<Path> {
  final Offset center;
  final double t;
  const _CircleReveal(this.center, this.t);
  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(center: center, radius: size.longestSide * 1.5 * t),
    );
  @override
  bool shouldReclip(_CircleReveal old) => old.t != t || old.center != center;
}
