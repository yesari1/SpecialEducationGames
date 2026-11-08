import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Vector drawings for the Shapes theme (no photos or generated images):
/// a flat colour with a gentle top-left light, a white sticker rim and a
/// soft darker edge, matching the photo cutouts around them.
class ShapeVisual extends StatelessWidget {
  final String slug;
  final Alignment alignment;

  /// Draw only the flat shadow of the shape (Find the Shadow).
  final bool silhouette;
  const ShapeVisual(
    this.slug, {
    super.key,
    this.alignment = Alignment.center,
    this.silhouette = false,
  });

  static const _colors = {
    'circle': SegColors.primary,
    'square': SegColors.accent,
    'triangle': SegColors.turquoise,
    'star': SegColors.star,
    'rectangle': Color(0xFF7C73DF),
    'heart': Color(0xFFE76F8E),
    'oval': SegColors.sky,
    'crescent': Color(0xFFF2B33D),
    'cross': Color(0xFF4CAF7A),
    'arrow': SegColors.accentDeep,
    'hexagon': SegColors.turquoiseDeep,
    'pentagon': Color(0xFFD9822B),
    'rhombus': Color(0xFF9C6AD6),
    'trapezoid': Color(0xFF2F9BD8),
    'cube': SegColors.accent,
    'sphere': SegColors.primary,
    'cylinder': SegColors.turquoise,
    'cone': Color(0xFFE76F8E),
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final side = math.min(box.maxWidth, box.maxHeight) * .86;
      if (!side.isFinite || side <= 0) return const SizedBox.shrink();
      return Align(
        alignment: alignment,
        child: SizedBox.square(
          dimension: side,
          child: CustomPaint(
            painter: ShapePainter(
              slug,
              _colors[slug] ?? SegColors.primary,
              silhouette: silhouette,
            ),
          ),
        ),
      );
    },
  );
}

class ShapePainter extends CustomPainter {
  final String slug;
  final Color color;

  /// Only the flat shape in the shadow grey photos use (no rim or light).
  final bool silhouette;
  const ShapePainter(this.slug, this.color, {this.silhouette = false});

  /// The same grey as photo silhouettes (components.dart).
  static const shadowColor = Color(0xD95B6670);

  static Path _polygon(Offset c, double r, int sides, double rotation) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = rotation + i * 2 * math.pi / sides;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  /// The flat silhouette of the shape inside [s] (3D shapes use their outline).
  Path outline(Size s) {
    final w = s.width, h = s.height, c = s.center(Offset.zero);
    final r = math.min(w, h) / 2;
    switch (slug) {
      case 'circle':
      case 'sphere':
        return Path()..addOval(Rect.fromCircle(center: c, radius: r * .92));
      case 'square':
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.6, height: r * 1.6),
            Radius.circular(r * .08),
          ),
        );
      case 'rectangle':
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.9, height: r * 1.15),
            Radius.circular(r * .07),
          ),
        );
      case 'oval':
        return Path()..addOval(
          Rect.fromCenter(center: c, width: r * 1.9, height: r * 1.25),
        );
      case 'triangle':
        return _polygon(c + Offset(0, r * .12), r * .98, 3, -math.pi / 2);
      case 'pentagon':
        return _polygon(c + Offset(0, r * .05), r * .92, 5, -math.pi / 2);
      case 'hexagon':
        return _polygon(c, r * .92, 6, 0);
      case 'rhombus':
        return Path()
          ..moveTo(c.dx, c.dy - r * .95)
          ..lineTo(c.dx + r * .68, c.dy)
          ..lineTo(c.dx, c.dy + r * .95)
          ..lineTo(c.dx - r * .68, c.dy)
          ..close();
      case 'trapezoid':
        return Path()
          ..moveTo(c.dx - r * .55, c.dy - r * .55)
          ..lineTo(c.dx + r * .55, c.dy - r * .55)
          ..lineTo(c.dx + r * .95, c.dy + r * .55)
          ..lineTo(c.dx - r * .95, c.dy + r * .55)
          ..close();
      case 'star':
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final rr = i.isEven ? r * .95 : r * .42;
          final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
      case 'heart':
        return Path()
          ..moveTo(c.dx, c.dy + r * .8)
          ..cubicTo(
            c.dx - r * 1.1,
            c.dy + r * .05,
            c.dx - r * .8,
            c.dy - r * .95,
            c.dx,
            c.dy - r * .45,
          )
          ..cubicTo(
            c.dx + r * .8,
            c.dy - r * .95,
            c.dx + r * 1.1,
            c.dy + r * .05,
            c.dx,
            c.dy + r * .8,
          )
          ..close();
      case 'crescent':
        return Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: c, radius: r * .9)),
          Path()..addOval(
            Rect.fromCircle(
              center: c + Offset(r * .42, -r * .18),
              radius: r * .74,
            ),
          ),
        );
      case 'cross':
        final t = r * .32;
        return Path.combine(
          PathOperation.union,
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: t * 2, height: r * 1.8),
              Radius.circular(t * .3),
            ),
          ),
          Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: r * 1.8, height: t * 2),
              Radius.circular(t * .3),
            ),
          ),
        );
      case 'arrow':
        return Path()
          ..moveTo(c.dx - r * .9, c.dy - r * .22)
          ..lineTo(c.dx + r * .15, c.dy - r * .22)
          ..lineTo(c.dx + r * .15, c.dy - r * .6)
          ..lineTo(c.dx + r * .95, c.dy)
          ..lineTo(c.dx + r * .15, c.dy + r * .6)
          ..lineTo(c.dx + r * .15, c.dy + r * .22)
          ..lineTo(c.dx - r * .9, c.dy + r * .22)
          ..close();
      case 'cube':
        final d = r * .35, e = r * 1.15;
        final front = Rect.fromLTWH(
          c.dx - e / 2 - d / 2,
          c.dy - e / 2 + d / 2,
          e,
          e,
        );
        return Path()
          ..moveTo(front.left, front.top)
          ..lineTo(front.left + d, front.top - d)
          ..lineTo(front.right + d, front.top - d)
          ..lineTo(front.right + d, front.bottom - d)
          ..lineTo(front.right, front.bottom)
          ..lineTo(front.left, front.bottom)
          ..close();
      case 'cylinder':
        final top = Rect.fromCenter(
          center: c - Offset(0, r * .62),
          width: r * 1.3,
          height: r * .45,
        );
        return Path()
          ..addOval(top)
          ..addRect(
            Rect.fromLTRB(top.left, top.center.dy, top.right, c.dy + r * .62),
          )
          ..addOval(top.shift(Offset(0, r * 1.24)));
      case 'cone':
        final base = Rect.fromCenter(
          center: c + Offset(0, r * .62),
          width: r * 1.4,
          height: r * .45,
        );
        return Path()
          ..moveTo(c.dx, c.dy - r * .95)
          ..lineTo(base.right, base.center.dy)
          ..arcTo(base, 0, math.pi, false)
          ..close();
      default:
        return Path()..addOval(Rect.fromCircle(center: c, radius: r * .9));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final r = size.shortestSide / 2;
    // Leave room for the rim inside the box.
    canvas.save();
    canvas.translate(size.width * .06, size.height * .06);
    canvas.scale(.88);
    final path = outline(size);
    if (silhouette) {
      canvas.drawPath(path, Paint()..color = shadowColor);
      canvas.restore();
      return;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = SegColors.ink.withValues(alpha: .10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .1
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .25)!,
            color,
            Color.lerp(color, Colors.black, .12)!,
          ],
        ).createShader(bounds),
    );
    _details(canvas, size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .025
        ..color = Color.lerp(color, Colors.black, .25)!.withValues(alpha: .5),
    );
    canvas.restore();
  }

  /// Faces and highlights that make the 3D shapes read as solids.
  void _details(Canvas canvas, Size s) {
    final c = s.center(Offset.zero), r = s.shortestSide / 2;
    final dark = Paint()..color = Colors.black.withValues(alpha: .14);
    final light = Paint()..color = Colors.white.withValues(alpha: .28);
    switch (slug) {
      case 'sphere':
        canvas.drawCircle(c + Offset(-r * .3, -r * .32), r * .26, light);
        canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 1.84, height: r * .5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .03
            ..color = Colors.white.withValues(alpha: .35),
        );
      case 'cube':
        final d = r * .35, e = r * 1.15;
        final front = Rect.fromLTWH(
          c.dx - e / 2 - d / 2,
          c.dy - e / 2 + d / 2,
          e,
          e,
        );
        canvas.drawPath(
          Path()
            ..moveTo(front.left, front.top)
            ..lineTo(front.left + d, front.top - d)
            ..lineTo(front.right + d, front.top - d)
            ..lineTo(front.right, front.top)
            ..close(),
          light,
        );
        canvas.drawPath(
          Path()
            ..moveTo(front.right, front.top)
            ..lineTo(front.right + d, front.top - d)
            ..lineTo(front.right + d, front.bottom - d)
            ..lineTo(front.right, front.bottom)
            ..close(),
          dark,
        );
      case 'cylinder':
        final top = Rect.fromCenter(
          center: c - Offset(0, r * .62),
          width: r * 1.3,
          height: r * .45,
        );
        canvas.drawOval(top, light);
        canvas.drawRect(
          Rect.fromLTRB(
            top.center.dx + r * .25,
            top.center.dy,
            top.right,
            c.dy + r * .62,
          ),
          dark,
        );
      case 'cone':
        final base = Rect.fromCenter(
          center: c + Offset(0, r * .62),
          width: r * 1.4,
          height: r * .45,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r * .95)
            ..lineTo(base.right, base.center.dy)
            ..lineTo(c.dx + r * .2, base.center.dy + r * .2)
            ..close(),
          dark,
        );
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(ShapePainter old) =>
      old.slug != slug || old.color != color || old.silhouette != silhouette;
}
