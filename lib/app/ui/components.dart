import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../../core/content/content_repository.dart';

class SegButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  const SegButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.secondary = false,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(SegRadius.md),
      gradient: secondary || onPressed == null
          ? null
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SegColors.accent, Color(0xFFF36D24)],
            ),
      color: onPressed == null ? SegColors.surfaceMuted : SegColors.surface,
      boxShadow: onPressed == null || secondary
          ? null
          : [
              BoxShadow(
                color: SegColors.accent.withValues(alpha: .2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: secondary ? SegColors.primaryDeep : SegColors.ink,
          padding: const EdgeInsets.symmetric(
            horizontal: SegSpace.s5,
            vertical: SegSpace.s4,
          ),
          side: BorderSide(
            color: secondary ? SegColors.line : Colors.white,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SegRadius.md),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: SegSpace.s2),
            ],
            Flexible(
              child: Text(
                label,
                style: SegText.item,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HoldButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onHeld;
  final Duration duration;
  final String semanticsLabel;
  const HoldButton({
    super.key,
    required this.child,
    required this.onHeld,
    this.duration = const Duration(seconds: 2),
    required this.semanticsLabel,
  });
  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  Timer? timer;
  bool held = false;
  void cancel() {
    timer?.cancel();
    if (mounted) setState(() => held = false);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.semanticsLabel,
    onLongPress: widget.onHeld,
    child: Listener(
      onPointerDown: (_) {
        timer?.cancel();
        setState(() => held = true);
        timer = Timer(widget.duration, () {
          cancel();
          widget.onHeld();
        });
      },
      onPointerUp: (_) => cancel(),
      onPointerCancel: (_) => cancel(),
      child: AnimatedContainer(
        duration: SegMotion.tap,
        padding: const EdgeInsets.all(SegSpace.s4),
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        decoration: BoxDecoration(
          color: held ? SegColors.primarySoft : SegColors.surface,
          borderRadius: BorderRadius.circular(SegRadius.pill),
          border: Border.all(color: SegColors.line),
        ),
        child: widget.child,
      ),
    ),
  );
}

class SegCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SegCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SegSpace.s5),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: SegColors.surface,
      borderRadius: BorderRadius.circular(SegRadius.lg),
      border: Border.all(color: SegColors.line),
      boxShadow: [
        BoxShadow(
          color: SegColors.ink.withValues(alpha: .08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class ItemVisual extends StatelessWidget {
  final ContentItem item;
  const ItemVisual(this.item, {super.key});
  static const colors = {
    'red': 0xFFE98A6B,
    'blue': 0xFF5B8FD1,
    'yellow': 0xFFF5C451,
    'green': 0xFF6BAA75,
    'orange': 0xFFF2A65A,
    'purple': 0xFF9C7BC0,
    'pink': 0xFFD07A98,
    'brown': 0xFFA9805B,
    'black': 0xFF2F3A45,
    'white': 0xFFFFFFFF,
    'gray': 0xFF9AA4AE,
    'navy': 0xFF465E7A,
    'light_blue': 0xFFE8F1F7,
    'turquoise': 0xFF4A9C8C,
    'gold': 0xFFD9A52E,
    'silver': 0xFFE4DFD6,
  };
  @override
  Widget build(BuildContext context) {
    if (item.images.isNotEmpty) {
      return PhotoVisual(item.images.first);
    }
    if (item.theme == 'colors') {
      return FractionallySizedBox(
        widthFactor: .78,
        heightFactor: .78,
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: ColorBlobPainter(Color(colors[item.slug] ?? 0xFF9AA4AE)),
          ),
        ),
      );
    }
    if (item.theme == 'numbers') {
      return FittedBox(child: StickerNumber(item.slug));
    }
    final icons = {
      'car': Icons.directions_car_rounded,
      'bus': Icons.directions_bus_rounded,
      'bicycle': Icons.pedal_bike_rounded,
      'motorcycle': Icons.two_wheeler_rounded,
      'airplane': Icons.flight_rounded,
      'train': Icons.train_rounded,
      'boat': Icons.directions_boat_rounded,
      'ship': Icons.directions_boat_rounded,
      'truck': Icons.local_shipping_rounded,
      'ambulance': Icons.emergency_rounded,
      'helicopter': Icons.flight_rounded,
    };
    final icon =
        icons[item.slug] ??
        (item.theme == 'vehicles'
            ? Icons.directions_car_rounded
            : Icons.image_outlined);
    // Sticker-style icon: a white rim drawn from the glyph itself so the
    // placeholder reads as a cut-out object like the photos around it.
    return FittedBox(
      child: Icon(
        icon,
        size: 96,
        color: item.theme == 'vehicles' ? SegColors.primary : SegColors.inkSoft,
        shadows: [
          for (var i = 0; i < 12; i++)
            Shadow(
              color: Colors.white,
              offset: Offset(
                math.cos(i * math.pi / 6) * 3,
                math.sin(i * math.pi / 6) * 3,
              ),
            ),
        ],
      ),
    );
  }
}

/// Palette for counting numbers: calm, distinct, never neon.
const _numberTints = [
  SegColors.accent,
  SegColors.primary,
  SegColors.turquoise,
  Color(0xFF7C73DF),
  Color(0xFFE76F8E),
];

/// A chunky numeral with a white sticker rim and a soft inner tint.
class StickerNumber extends StatelessWidget {
  final String text;
  const StickerNumber(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final tint =
        _numberTints[(int.tryParse(text) ?? text.length) % _numberTints.length];
    final base = SegText.display.copyWith(fontSize: 72, height: 1.1);
    return Stack(
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 14
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: [
              Shadow(
                color: SegColors.ink.withValues(alpha: .12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        Text(text, style: base.copyWith(color: tint)),
      ],
    );
  }
}

/// A soft, slightly glossy paint ball for colour items, with a white rim.
class ColorBlobPainter extends CustomPainter {
  final Color color;
  const ColorBlobPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    final inner = radius * .88;
    final rect = Rect.fromCircle(center: center, radius: inner);
    final light = Color.lerp(color, Colors.white, .35)!;
    final dark = Color.lerp(color, Colors.black, .12)!;
    canvas.drawCircle(
      center,
      inner,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.4),
          radius: 1.05,
          colors: [light, color, dark],
          stops: const [0, .55, 1],
        ).createShader(rect),
    );
    if (color.computeLuminance() > .85) {
      canvas.drawCircle(
        center,
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = SegColors.line,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-inner * .32, -inner * .42),
        width: inner * .5,
        height: inner * .28,
      ),
      Paint()..color = Colors.white.withValues(alpha: .45),
    );
  }

  @override
  bool shouldRepaint(ColorBlobPainter old) => old.color != color;
}

/// A photographic cutout with a contour following its alpha, never its frame.
/// AssetImage uses Flutter's shared decoded cache; each tile is a repaint boundary.
class PhotoVisual extends StatefulWidget {
  final String asset;
  const PhotoVisual(this.asset, {super.key});
  @override
  State<PhotoVisual> createState() => _PhotoVisualState();
}

class _PhotoVisualState extends State<PhotoVisual> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener((image, _) {
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
    });
  });

  void _resolve() {
    final next = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _image?.dispose();
    _image = null;
    _stream = next..addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant PhotoVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PhotoContourPainter(_image?.image),
      size: Size.infinite,
    ),
  );
}

class _PhotoContourPainter extends CustomPainter {
  final ui.Image? image;
  _PhotoContourPainter(this.image);
  @override
  void paint(Canvas canvas, Size size) {
    final photo = image;
    if (photo == null || size.shortestSide <= 8) return;
    const stroke = 4.0;
    final available = Size(size.width - stroke * 2, size.height - stroke * 2);
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(photo.width.toDouble(), photo.height.toDouble()),
      available,
    );
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final source = Rect.fromLTWH(
      0,
      0,
      photo.width.toDouble(),
      photo.height.toDouble(),
    );
    final outline = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn);
    // Circular dilation retains the source alpha and all original photo pixels.
    for (var step = 0; step < 24; step++) {
      final angle = step * math.pi * 2 / 24;
      canvas.drawImageRect(
        photo,
        source,
        destination.shift(
          Offset(math.cos(angle) * stroke, math.sin(angle) * stroke),
        ),
        outline,
      );
    }
    canvas.drawImageRect(
      photo,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoContourPainter oldDelegate) =>
      oldDelegate.image != image;
}

class ThemeGameCard extends StatelessWidget {
  final ContentTheme theme;
  final String title, subtitle;
  final String? badgeText;
  final Widget visual;
  final bool locked;
  final VoidCallback onTap;
  const ThemeGameCard({
    super.key,
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.visual,
    required this.onTap,
    this.locked = false,
    this.badgeText,
  });
  Color get accent => switch (theme.id) {
    'animals' => SegColors.turquoise,
    'produce' => SegColors.accent,
    'colors' => SegColors.primary,
    'numbers' => const Color(0xFF7C73DF),
    'vehicles' => SegColors.sky,
    _ => SegColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final horizontalContent = textScale >= 1.6;

    Widget cardVisual() => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: .18),
            accent.withValues(alpha: .04),
          ],
        ),
        borderRadius: BorderRadius.circular(SegRadius.md),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(opacity: locked ? .55 : 1, child: visual),
          if (locked)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: SegColors.inkSoft,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );

    Widget labelContent() => Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (badgeText case final text?) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: SegText.label.copyWith(color: SegColors.ink),
              ),
            ),
          ),
          const SizedBox(height: SegSpace.s1),
        ],
        Text(
          title,
          style: SegText.item.copyWith(color: SegColors.ink),
          textAlign: TextAlign.center,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: SegSpace.s1),
          Text(
            subtitle,
            style: SegText.label.copyWith(color: SegColors.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      label: '$title. $subtitle${badgeText == null ? '' : '. $badgeText'}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SegRadius.lg),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: SegColors.surface,
          borderRadius: BorderRadius.circular(SegRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SegRadius.lg),
                border: Border.all(
                  color: accent.withValues(alpha: .3),
                  width: 2,
                ),
              ),
              padding: EdgeInsets.all(horizontalContent ? 4 : 10),
              child: horizontalContent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cardVisual()),
                        const SizedBox(height: SegSpace.s1),
                        labelContent(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cardVisual()),
                        const SizedBox(height: SegSpace.s2),
                        labelContent(),
                        const SizedBox(height: SegSpace.s1),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalCards extends StatelessWidget {
  final int count;
  final Widget Function(int) builder;
  const HorizontalCards({
    super.key,
    required this.count,
    required this.builder,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth > 900;
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final shortLargeText = c.maxHeight < 500 && textScale >= 1.6;
      final width = shortLargeText
          ? c.maxWidth * .78
          : c.maxWidth < 600
          ? c.maxWidth * .78
          : (c.maxWidth - SegSpace.s5 * (wide ? 5 : 4)) / (wide ? 4 : 3);
      return ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: SegSpace.s5,
          vertical: c.maxHeight < 300 ? SegSpace.s2 : SegSpace.s5,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: SegSpace.s5),
        itemBuilder: (_, i) => SizedBox(width: width, child: builder(i)),
      );
    },
  );
}
