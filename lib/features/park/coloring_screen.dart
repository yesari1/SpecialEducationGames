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
      onBack: () => page == null
          ? context.go('/')
          : setState(() => _page = null),
      child: page == null
          ? _picker()
          : _PaintingBoard(key: ValueKey(page), name: page),
    );
  }

  Widget _picker() => GridView.count(
    key: const ValueKey('coloring-picker'),
    padding: const EdgeInsets.fromLTRB(
      SegSpace.s4,
      0,
      SegSpace.s4,
      SegSpace.s4,
    ),
    crossAxisCount: 5,
    mainAxisSpacing: SegSpace.s3,
    crossAxisSpacing: SegSpace.s3,
    children: [
      for (final name in s.content.coloringPages)
        GestureDetector(
          key: ValueKey('coloring-page-$name'),
          onTap: () {
            UiSound.tap();
            setState(() => _page = name);
          },
          child: Container(
            padding: const EdgeInsets.all(SegSpace.s2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SegRadius.md),
            ),
            child: Image.asset(
              'assets/coloring/${name}_line.png',
              excludeFromSemantics: true,
            ),
          ),
        ),
    ],
  );
}

class _PaintingBoard extends StatefulWidget {
  final String name;
  const _PaintingBoard({super.key, required this.name});
  @override
  State<_PaintingBoard> createState() => _PaintingBoardState();
}

class _PaintingBoardState extends State<_PaintingBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Uint8List? _regions;
  int _width = 0, _height = 0;
  final Map<int, Color> _colors = {};
  ui.Image? _before, _after;
  Offset _tap = Offset.zero;
  Color _paint = _paints.first;

  @override
  void initState() {
    super.initState();
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
    if (mounted) setState(() => _before = _after = blank);
  }

  Future<ui.Image> _compose() {
    final pixels = Uint8List(_width * _height * 4)..fillRange(0, _width * _height * 4, 255);
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
    _colors[region] = _paint;
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

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SegRadius.md),
              child: SizedBox.square(
                dimension: side,
                child: GestureDetector(
                  key: const ValueKey('coloring-board'),
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
                            child: RawImage(image: _after, fit: BoxFit.fill),
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
                            child: const Icon(
                              Icons.brush_rounded,
                              size: 64,
                              color: SegColors.primaryDeep,
                              shadows: [
                                Shadow(color: Colors.white, blurRadius: 8),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: SegSpace.s5),
            SizedBox(
              width: math.min(box.maxWidth * .3, 220),
              child: GridView.count(
                key: const ValueKey('coloring-paints'),
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: SegSpace.s3,
                crossAxisSpacing: SegSpace.s3,
                childAspectRatio: 1.25,
                children: [
                  for (var i = 0; i < _paints.length; i++)
                    GestureDetector(
                      key: ValueKey('coloring-paint-$i'),
                      onTap: () {
                        UiSound.tap();
                        setState(() => _paint = _paints[i]);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: _paints[i],
                          borderRadius: BorderRadius.circular(SegRadius.pill),
                          border: Border.all(
                            color: _paint == _paints[i]
                                ? SegColors.ink
                                : Colors.white,
                            width: _paint == _paints[i] ? 4 : 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
    ..addOval(Rect.fromCircle(center: center, radius: size.longestSide * 1.5 * t));
  @override
  bool shouldReclip(_CircleReveal old) => old.t != t || old.center != center;
}
