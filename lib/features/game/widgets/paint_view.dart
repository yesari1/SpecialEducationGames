import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/content/child_cast.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// A big picture above the choices. G42 "Boya" ([paint]): the picture is
/// white and the right colour paints it (a soft fade). Scene games show
/// their scene as it is.
class PaintView extends StatelessWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  final bool paint;
  const PaintView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
    this.paint = true,
  });

  @override
  Widget build(BuildContext context) {
    final asset = spec.promptImagePath;
    final color = Color(ItemVisual.colors[spec.target.slug] ?? 0xFFFFFFFF);
    final picture = asset == null
        ? const SizedBox.shrink()
        : !paint
        ? ClipRRect(
            borderRadius: BorderRadius.circular(SegRadius.lg),
            // Fades in when it is ready instead of popping in.
            child: Image.asset(
              ChildCast.of(asset),
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, sync) => sync
                  ? child
                  : AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 220),
                      child: child,
                    ),
            ),
          )
        : _BrushPicture(
            asset: asset,
            color: color,
            painting: hint.celebrating,
            animate: hint.animate,
          );
    final choices = RoundChoicesView(
      spec: spec,
      callbacks: callbacks,
      hint: hint,
    );
    // Landscape: the picture on the left, big choices on the right.
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth > box.maxHeight
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(SegSpace.s3),
                    child: picture,
                  ),
                ),
                Expanded(flex: 3, child: choices),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 3, child: picture),
                const SizedBox(height: SegSpace.s2),
                Expanded(flex: 2, child: choices),
              ],
            ),
    );
  }
}

/// The white picture; when [painting] turns on, a brush sweeps across and
/// the colour follows it. Without motion the picture is simply coloured.
class _BrushPicture extends StatefulWidget {
  final String asset;
  final Color color;
  final bool painting, animate;
  const _BrushPicture({
    required this.asset,
    required this.color,
    required this.painting,
    required this.animate,
  });
  @override
  State<_BrushPicture> createState() => _BrushPictureState();
}

class _BrushPictureState extends State<_BrushPicture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didUpdateWidget(covariant _BrushPicture old) {
    super.didUpdateWidget(old);
    if (widget.painting && !old.painting) {
      if (widget.animate) {
        _sweep.forward(from: 0);
      } else {
        _sweep.value = 1;
      }
    } else if (!widget.painting && old.painting) {
      _sweep.value = 0;
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_sweep.value);
        // Three strokes down the picture, like a child painting.
        final wave = math.sin(t * math.pi * 6);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: PhotoVisual(ChildCast.of(widget.asset))),
            Positioned.fill(
              child: ClipRect(
                clipper: _RevealClip(t),
                child: ColorFiltered(
                  key: const ValueKey('paint-done'),
                  colorFilter: ColorFilter.mode(
                    widget.color,
                    BlendMode.modulate,
                  ),
                  child: PhotoVisual(ChildCast.of(widget.asset)),
                ),
              ),
            ),
            if (_sweep.isAnimating)
              Positioned(
                key: const ValueKey('paint-brush'),
                left: box.maxWidth * t - 12,
                top: box.maxHeight * (.42 + .3 * wave) - 70,
                child: Transform.rotate(
                  angle: .35 * wave,
                  child: const Icon(
                    Icons.brush_rounded,
                    size: 88,
                    color: SegColors.primaryDeep,
                    shadows: [
                      Shadow(color: Colors.white, blurRadius: 3),
                      Shadow(color: Colors.white, blurRadius: 12),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _RevealClip extends CustomClipper<Rect> {
  final double t;
  const _RevealClip(this.t);
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);
  @override
  bool shouldReclip(_RevealClip old) => old.t != t;
}
