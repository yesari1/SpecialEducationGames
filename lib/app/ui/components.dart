import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../theme/tokens.dart';
import '../../core/content/child_cast.dart';
import '../../core/content/content_repository.dart';
import 'game_object.dart';
import 'scene_backdrop.dart';
import 'shape_visual.dart';

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
              colors: [SegColors.accent, SegColors.accentStrong],
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
        onPressed: onPressed == null
            ? null
            : () {
                UiSound.tap();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          // White on the orange gradient; every primary button shares it.
          foregroundColor: secondary ? SegColors.primaryDeep : Colors.white,
          disabledForegroundColor: SegColors.inkSoft,
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
                style: SegText.item.copyWith(
                  color: onPressed == null
                      ? SegColors.inkSoft
                      : secondary
                      ? SegColors.primaryDeep
                      : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The round white pill used for "back" and "Family". A single tap acts;
/// the child lock lives behind it (the parent gate), not in a long hold.
class PillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String semanticsLabel;

  /// A lower pill for a bar that must stay small (the child home).
  final bool compact;
  const PillButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticsLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticsLabel,
    excludeSemantics: true,
    child: Material(
      color: SegColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: SegColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          UiSound.tap();
          onPressed();
        },
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(
                  horizontal: SegSpace.s3,
                  vertical: SegSpace.s1,
                )
              : const EdgeInsets.all(SegSpace.s4),
          constraints: compact
              ? const BoxConstraints(minWidth: 44, minHeight: 44)
              : const BoxConstraints(minWidth: 64, minHeight: 64),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
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
      border: Border.all(color: const Color(0xFFE7F0F5)),
      boxShadow: [
        BoxShadow(
          color: SegColors.ink.withValues(alpha: .05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class ItemVisual extends StatelessWidget {
  final ContentItem item;

  /// Where a photo sits in its box; game objects stand on the bottom edge.
  final Alignment alignment;

  /// Draw the photo as a flat shadow (alpha shape only), for shadow games.
  final bool silhouette;
  const ItemVisual(
    this.item, {
    super.key,
    this.alignment = Alignment.center,
    this.silhouette = false,
  });
  // True, clearly named colours (Yunus, 8 Nov 2026: the old soft palette
  // read red as salmon and navy as grey).
  static const colors = {
    'red': 0xFFE53935,
    'blue': 0xFF1E6FD9,
    'yellow': 0xFFFFD21F,
    'green': 0xFF2EAA4A,
    'orange': 0xFFFF8A1A,
    'purple': 0xFF8E44C9,
    'pink': 0xFFFF6FAE,
    'brown': 0xFF8B5A2B,
    'black': 0xFF222222,
    'white': 0xFFFFFFFF,
    'gray': 0xFF858585,
    'navy': 0xFF1F2F6B,
    'light_blue': 0xFF7CC8F5,
    'turquoise': 0xFF1CC7C1,
    'gold': 0xFFD4A017,
    'silver': 0xFFD5DBE2,
  };
  @override
  Widget build(BuildContext context) {
    // Shapes are always drawn, even where a legacy bitmap is listed.
    if (item.theme == 'shapes') {
      return ShapeVisual(
        item.slug,
        alignment: alignment,
        silhouette: silhouette,
      );
    }
    if (item.images.isNotEmpty) {
      return PhotoVisual(
        ChildCast.of(item.images.first),
        alignment: alignment,
        silhouette: silhouette,
      );
    }
    if (item.theme == 'colors') {
      final paint = ColorBlobPainter(Color(colors[item.slug] ?? 0xFF9AA4AE));
      return LayoutBuilder(
        builder: (context, box) {
          final side = math.min(box.maxWidth, box.maxHeight) * .82;
          return Align(
            alignment: alignment,
            child: SizedBox.square(
              dimension: side,
              child: CustomPaint(painter: paint),
            ),
          );
        },
      );
    }
    if (item.theme == 'numbers') {
      return FittedBox(alignment: alignment, child: StickerNumber(item.slug));
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
      alignment: alignment,
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

/// The tint a number's sticker uses ([StickerNumber]).
Color numberTint(String text) =>
    _numberTints[(int.tryParse(text) ?? text.length) % _numberTints.length];

/// A chunky numeral with a white sticker rim and a soft inner tint.
class StickerNumber extends StatelessWidget {
  final String text;
  const StickerNumber(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final tint = numberTint(text);
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
    final light = Color.lerp(color, Colors.white, .2)!;
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
  final Alignment alignment;
  final bool silhouette;
  const PhotoVisual(
    this.asset, {
    super.key,
    this.alignment = Alignment.center,
    this.silhouette = false,
  });
  @override
  State<PhotoVisual> createState() => _PhotoVisualState();

  /// Opaque bounds per asset as fractions (0..1) of the image, so subjects
  /// are framed by their pixels rather than the square file's margin.
  static final Map<String, Rect> _opaqueBounds = {};

  /// Bounds precomputed by `tools/build_photo_bounds.py`; assets missing here
  /// are measured once at runtime.
  static void registerBounds(Map<String, Rect> bounds) =>
      _opaqueBounds.addAll(bounds);

  /// The part of [asset] that is drawn (fractions of the image), when known.
  static Rect? boundsOf(String asset) => _opaqueBounds[asset];
}

class _PhotoVisualState extends State<PhotoVisual> {
  static Map<String, Rect> get _opaqueBounds => PhotoVisual._opaqueBounds;

  /// The picture drawn: for a girl's profile, the girl's version of a
  /// picture of the boy (story choices and results too, Yunus 16 Nov 2026).
  String get _asset => ChildCast.of(widget.asset);
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
    _measure(_asset, image.image);
  });

  void _measure(String asset, ui.Image image) {
    if (_opaqueBounds.containsKey(asset)) return;
    final handle = image.clone();
    handle
        .toByteData()
        .then((data) {
          final width = handle.width, height = handle.height;
          handle.dispose();
          if (data == null) return;
          var left = width, top = height, right = -1, bottom = -1;
          for (var y = 0; y < height; y += 2) {
            final row = y * width * 4;
            for (var x = 0; x < width; x += 2) {
              if (data.getUint8(row + x * 4 + 3) > 24) {
                if (x < left) left = x;
                if (x > right) right = x;
                if (y < top) top = y;
                if (y > bottom) bottom = y;
              }
            }
          }
          const whole = Rect.fromLTWH(0, 0, 1, 1);
          _opaqueBounds[asset] = right < 0
              ? whole
              : Rect.fromLTRB(
                  (left - 4) / width,
                  (top - 4) / height,
                  (right + 6) / width,
                  (bottom + 6) / height,
                ).intersect(whole);
          if (mounted && _asset == asset) setState(() {});
        })
        .catchError((Object _) {
          handle.dispose();
        });
  }

  void _resolve() {
    final next = AssetImage(
      _asset,
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
      painter: _PhotoContourPainter(
        _image?.image,
        widget.alignment,
        _opaqueBounds[_asset],
        silhouette: widget.silhouette,
      ),
      size: Size.infinite,
    ),
  );
}

class _PhotoContourPainter extends CustomPainter {
  final ui.Image? image;
  final Alignment alignment;
  final Rect? crop;
  final bool silhouette;
  _PhotoContourPainter(
    this.image,
    this.alignment,
    this.crop, {
    this.silhouette = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final photo = image;
    if (photo == null || size.shortestSide <= 8) return;
    // A thin white rim (about half the earlier 4 px) keeps the cutout look.
    const stroke = 2.0;
    final available = Size(size.width - stroke * 2, size.height - stroke * 2);
    final w = photo.width.toDouble(), h = photo.height.toDouble();
    final fraction = crop;
    final source = fraction == null
        ? Rect.fromLTWH(0, 0, w, h)
        : Rect.fromLTRB(
            fraction.left * w,
            fraction.top * h,
            fraction.right * w,
            fraction.bottom * h,
          );
    final fitted = applyBoxFit(BoxFit.contain, source.size, available);
    final destination = alignment.inscribe(
      fitted.destination,
      (Offset.zero & size).deflate(stroke),
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
      Paint()
        ..filterQuality = FilterQuality.medium
        // Shadows keep only the alpha shape, in the design system's grey.
        ..colorFilter = silhouette
            ? const ColorFilter.mode(Color(0xD95B6670), BlendMode.srcIn)
            : null,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoContourPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.alignment != alignment ||
      oldDelegate.crop != crop ||
      oldDelegate.silhouette != silhouette;
}

const _greyscale = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];

class ThemeGameCard extends StatelessWidget {
  final ContentTheme theme;
  final String title, subtitle;
  final String? badgeText;
  final Widget visual;
  final IconData? modeIcon;
  final bool locked;
  final VoidCallback onTap;

  /// The visual is already normalized (illustrated theme covers): draw it at
  /// full size instead of the per-theme photo scale.
  final bool normalizedVisual;

  /// False for cards that play their own sound (opening a game).
  final bool tapSound;

  /// A smaller card: smaller title, tighter padding (rows of the home).
  final bool dense;
  const ThemeGameCard({
    super.key,
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.visual,
    required this.onTap,
    this.modeIcon,
    this.locked = false,
    this.badgeText,
    this.normalizedVisual = false,
    this.tapSound = true,
    this.dense = false,
  });

  /// Each theme's own colour, so a row of cards is not all one blue.
  Color get accent => theme.accent;

  /// The theme colour of a theme card (also the 7-day plan's thumbnails).
  static Color accentFor(String themeId) => switch (themeId) {
    'animals' => SegColors.turquoise,
    'produce' => SegColors.accent,
    'colors' => SegColors.primary,
    'numbers' => const Color(0xFF7C73DF),
    'vehicles' => SegColors.sky,
    'shapes' => const Color(0xFF9C6AD6),
    'food' => const Color(0xFFE8A24D),
    'stories' => SegColors.accent,
    _ => SegColors.primary,
  };

  /// Round, compact subjects read as oversized when they fill the scene.
  double get _heroScale => heroScaleFor(theme.id, normalized: normalizedVisual);

  static double heroScaleFor(String themeId, {required bool normalized}) =>
      normalized
      ? 1
      : switch (themeId) {
          'produce' || 'colors' || 'shapes' => .7,
          'food' => .8,
          'numbers' => .85,
          _ => 1,
        };

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final horizontalContent = textScale >= 1.6;
    final deep = Color.lerp(accent, SegColors.ink, .35)!;
    final titleStyle = dense
        ? SegText.item.copyWith(fontSize: 17, height: 1.2)
        : SegText.item;

    // A small scene: the hero object stands on soft hills in the theme colour.
    // Locked cards are grey and faded, with a large lock in the middle.
    // Only a locked card is filtered, and only its picture: a colour filter
    // costs an extra layer per card on every frame, which made rows of cards
    // stutter when it wrapped every card twice.
    Widget grey(Widget child) => locked
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(_greyscale),
            child: child,
          )
        : child;
    Widget cardVisual() => ClipRRect(
      borderRadius: BorderRadius.circular(SegRadius.md),
      child: grey(
        SceneBackdrop(
          tint: accent,
          base: Color.lerp(SegColors.canvas, accent, .06)!,
          clouds: !horizontalContent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
                child: Opacity(
                  opacity: locked ? .35 : 1,
                  child: StagedObject(
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      widthFactor: _heroScale,
                      heightFactor: _heroScale,
                      child: visual,
                    ),
                  ),
                ),
              ),
              if (modeIcon case final icon?)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: deep.withValues(alpha: .18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 34, color: deep),
                  ),
                ),
              if (locked)
                Center(
                  child: Container(
                    key: const ValueKey('game-card-lock'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SegColors.ink.withValues(alpha: .18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: SegColors.ink,
                      size: 34,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
                color: accent.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: SegText.label.copyWith(color: deep),
              ),
            ),
          ),
          const SizedBox(height: SegSpace.s1),
        ],
        // Every title reserves two lines, so one- and two-line names leave
        // the pictures the same size from card to card.
        ConstrainedBox(
          constraints: BoxConstraints(
            // Large text lays the card out sideways; no reserve there.
            minHeight: horizontalContent
                ? 0
                : MediaQuery.textScalerOf(
                    context,
                  ).scale(titleStyle.fontSize! * titleStyle.height! * 2),
          ),
          child: Center(
            child: Text(
              title,
              maxLines: dense ? 2 : null,
              overflow: dense ? TextOverflow.ellipsis : null,
              style: titleStyle.copyWith(
                color: locked ? SegColors.inkSoft : SegColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
      excludeSemantics: true,
      child: PressableObject(
        onTap: onTap,
        tapSound: tapSound,
        pivot: Alignment.center,
        depth: .35,
        // Locked: the picture is black and white (see [grey]) and the
        // card's own accents are grey.
        child: KeyedSubtree(
          child: Container(
            decoration: BoxDecoration(
              color: SegColors.surface,
              borderRadius: BorderRadius.circular(SegRadius.lg),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (locked ? SegColors.inkFaint : accent).withValues(
                    alpha: .22,
                  ),
                  blurRadius: 0,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: SegColors.ink.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(horizontalContent ? 4 : (dense ? 6 : 8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cardVisual()),
                SizedBox(
                  height: horizontalContent || dense
                      ? SegSpace.s1
                      : SegSpace.s2,
                ),
                labelContent(),
                if (!horizontalContent && !dense)
                  const SizedBox(height: SegSpace.s1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two or three calm choices in one white pill; a tinted capsule slides
/// behind the selected one. Used for Games/Path and difficulty.
class PillToggle<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final IconData Function(T)? icon;
  final ValueChanged<T>? onChanged;
  const PillToggle({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SegColors.surface,
        borderRadius: BorderRadius.circular(SegRadius.pill),
        border: Border.all(color: SegColors.line),
        boxShadow: [
          BoxShadow(
            color: SegColors.ink.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in values)
            Semantics(
              button: true,
              selected: value == selected,
              enabled: onChanged != null,
              label: label(value),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null
                    ? null
                    : () {
                        UiSound.tap();
                        onChanged!(value);
                      },
                child: AnimatedContainer(
                  duration: reduced ? Duration.zero : SegMotion.appear,
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: SegSpace.s4,
                    vertical: SegSpace.s2,
                  ),
                  decoration: BoxDecoration(
                    color: value == selected
                        ? SegColors.primarySoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(SegRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon!(value),
                          size: 20,
                          color: value == selected
                              ? SegColors.primaryDeep
                              : SegColors.inkSoft,
                        ),
                        const SizedBox(width: SegSpace.s2),
                      ],
                      Text(
                        label(value),
                        style: SegText.label.copyWith(
                          color: value == selected
                              ? SegColors.primaryDeep
                              : SegColors.inkSoft,
                          fontWeight: value == selected
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HorizontalCards extends StatelessWidget {
  final int count;
  final Widget Function(int) builder;

  /// Width of one card for its height; without it the cards share the width
  /// (three or four on screen).
  final double? cardAspect;

  /// Room kept clear under the cards (a bar floating over the row).
  final double bottomInset;

  /// Tight rows keep only a little room above and below the cards.
  final bool tight;

  /// A row shorter than the screen sits in the middle instead of at the left.
  final bool centered;
  const HorizontalCards({
    super.key,
    required this.count,
    required this.builder,
    this.cardAspect,
    this.bottomInset = 0,
    this.tight = false,
    this.centered = false,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth > 900;
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final shortLargeText = c.maxHeight < 500 && textScale >= 1.6;
      final vertical = tight || c.maxHeight < 300 ? SegSpace.s2 : SegSpace.s5;
      final shared = shortLargeText
          ? c.maxWidth * .78
          : c.maxWidth < 600
          ? c.maxWidth * .78
          : (c.maxWidth - SegSpace.s5 * (wide ? 5 : 4)) / (wide ? 4 : 3);
      final width = cardAspect == null || shortLargeText
          ? shared
          : math.min(
              shared,
              (c.maxHeight - vertical * 2 - bottomInset) * cardAspect!,
            );
      final gap = tight ? SegSpace.s4 : SegSpace.s5;
      final all = count * width + (count - 1) * gap;
      final side = centered
          ? math.max(SegSpace.s5, (c.maxWidth - all) / 2)
          : SegSpace.s5;
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(
          side,
          vertical,
          side,
          vertical + bottomInset,
        ),
        // A short row can still be pulled, so a pull past its end is felt
        // (the home turns it into the next section).
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: (_, i) => SizedBox(width: width, child: builder(i)),
      );
    },
  );
}

/// A woven-looking basket that holds a group's example object. Used by the
/// sorting game so the choices read as containers, not buttons.
class BasketFrame extends StatelessWidget {
  final Widget child;
  final Color tint;
  const BasketFrame({super.key, required this.child, required this.tint});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Examples stand on the rim in their own area above the basket; the
      // basket never covers them and nothing leaves the slot.
      final width = math.min(box.maxWidth, box.maxHeight * 1.5);
      final basketHeight = box.maxHeight * .28;
      return Center(
        child: SizedBox(
          width: width,
          height: box.maxHeight,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * .1),
                  child: child,
                ),
              ),
              SizedBox(
                width: width,
                height: basketHeight,
                child: CustomPaint(painter: _BasketPainter(tint)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BasketPainter extends CustomPainter {
  final Color tint;
  const _BasketPainter(this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(0, h * .18)
      ..lineTo(w, h * .18)
      ..lineTo(w * .88, h)
      ..lineTo(w * .12, h)
      ..close();
    final fill = Color.lerp(const Color(0xFFE8B77A), tint, .25)!;
    final dark = Color.lerp(fill, Colors.black, .18)!;
    canvas.drawPath(body, Paint()..color = fill);
    final weave = Paint()
      ..color = dark.withValues(alpha: .45)
      ..strokeWidth = 2;
    for (var i = 1; i < 4; i++) {
      final y = h * .18 + (h * .82) * i / 4;
      final inset = w * .12 * (y - h * .18) / (h * .82);
      canvas.drawLine(Offset(inset, y), Offset(w - inset, y), weave);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * .03, 0, w * 1.06, h * .24),
        Radius.circular(h * .12),
      ),
      Paint()..color = dark,
    );
  }

  @override
  bool shouldRepaint(_BasketPainter old) => old.tint != tint;
}

/// A group shown as up to three of its members side by side, each in its
/// own square so they never cover one another.
class GroupCluster extends StatelessWidget {
  final List<ContentItem> members;
  const GroupCluster(this.members, {super.key});
  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        // Three examples when they still read well, otherwise two larger ones.
        final roomy = box.maxWidth / 3 >= math.min(box.maxHeight, 96) * .9;
        final shown = members.take(roomy ? 3 : 2).toList();
        final gap = box.maxWidth * .04;
        final side = math.min(
          (box.maxWidth - gap * (shown.length - 1)) / shown.length,
          box.maxHeight,
        );
        return Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                SizedBox.square(
                  key: ValueKey('group-member-${shown[i].id}'),
                  dimension: side,
                  child: ItemVisual(
                    shown[i],
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Where the prompt object is on screen, so a sorted item can hop from there
/// (not from the top of its basket) into its group.
abstract final class HopOrigin {
  static _HopOriginMarkerState? _marker;

  /// Where a drag was let go; used once, for the hop that follows.
  static Rect? dropped;

  /// The prompt object's place on screen right now (measured live, so an
  /// entrance animation can never leave a stale start point behind).
  static Rect? get rect {
    final drop = dropped;
    if (drop != null) {
      dropped = null;
      return drop;
    }
    return _marker?._rect();
  }
}

/// Wraps the prompt object so [HopOrigin.rect] can measure it.
class HopOriginMarker extends StatefulWidget {
  final Widget child;
  const HopOriginMarker({super.key, required this.child});
  @override
  State<HopOriginMarker> createState() => _HopOriginMarkerState();
}

class _HopOriginMarkerState extends State<HopOriginMarker> {
  final _key = GlobalKey();

  Rect? _rect() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void initState() {
    super.initState();
    HopOrigin._marker = this;
  }

  @override
  void dispose() {
    if (HopOrigin._marker == this) HopOrigin._marker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// The sorted item hopping in an arc into its group after a correct answer.
/// With [fromOrigin] it starts where the prompt object was ([HopOrigin]) and
/// flies smoothly from there; otherwise it drops in from above.
class HopIn extends StatefulWidget {
  final Widget child;
  final bool animate;
  final bool fromOrigin;
  const HopIn({
    super.key,
    required this.child,
    this.animate = true,
    this.fromOrigin = false,
  });
  @override
  State<HopIn> createState() => _HopInState();
}

class _HopInState extends State<HopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  final _key = GlobalKey();
  Offset? _start;
  double _startScale = 1;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _measured = true;
      _controller.value = 1;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        final origin = widget.fromOrigin ? HopOrigin.rect : null;
        final box = _key.currentContext?.findRenderObject() as RenderBox?;
        if (origin != null && box != null && box.hasSize) {
          final here = box.localToGlobal(Offset.zero) & box.size;
          _start = origin.center - here.center;
          _startScale = (origin.shortestSide / math.max(1.0, here.shortestSide))
              .clamp(.4, 2.5);
        }
        _controller.forward().then((_) {
          if (mounted && widget.fromOrigin) UiSound.basketDrop();
        });
      }
      setState(() => _measured = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  // The key sits outside the transform so the measured place is where the
  // item rests, not where the animation currently draws it.
  Widget build(BuildContext context) => KeyedSubtree(
    key: _key,
    child: LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOutSine.transform(_controller.value);
          final start = _start;
          final Offset offset;
          final double scale;
          if (start != null) {
            // A smooth arc from the prompt object down into the basket.
            final lift = math.max(36.0, start.distance * .18);
            offset = start * (1 - t) + Offset(0, -math.sin(t * math.pi) * lift);
            scale = _startScale + (1 - _startScale) * t;
          } else {
            offset = Offset(
              0,
              -box.maxHeight * (1 - t) -
                  math.sin(t * math.pi) * box.maxHeight * .35,
            );
            scale = 1.25 - .25 * t;
          }
          return Opacity(
            opacity: _measured ? 1 : 0,
            child: Transform.translate(
              offset: offset,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: widget.child,
      ),
    ),
  );
}

bool _lockedNoticeOpen = false;

/// The friendly "this game is locked" card for the child: a big lock, two
/// short lines and one button. Shown once; taps while it is open do nothing.
/// No purchase prompt in child mode.
Future<void> showLockedGameNotice(
  BuildContext context, {
  required String title,
  required String body,
  required String ok,
}) async {
  if (_lockedNoticeOpen) return;
  _lockedNoticeOpen = true;
  try {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: ok,
      barrierColor: SegColors.ink.withValues(alpha: .35),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
      pageBuilder: (context, _, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            key: const ValueKey('locked-game-notice'),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SegRadius.xl),
              side: const BorderSide(color: Colors.white, width: 4),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SegSpace.s5,
                SegSpace.s4,
                SegSpace.s5,
                SegSpace.s4,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFC46B), SegColors.accent],
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: SegSpace.s3),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: SegText.title.copyWith(color: SegColors.ink),
                    ),
                    const SizedBox(height: SegSpace.s2),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: SegText.body.copyWith(color: SegColors.inkSoft),
                    ),
                    const SizedBox(height: SegSpace.s4),
                    SegButton(
                      key: const ValueKey('locked-game-ok'),
                      label: ok,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    _lockedNoticeOpen = false;
  }
}

String? _visibleNotice;
OverlayEntry? _noticeEntry;

/// Shows a short message once: tapping again while the same message is on
/// screen does nothing, and a different message replaces it instead of
/// queueing behind it.
///
/// A small rounded white toast with a coloured icon at the top of the
/// screen (never over the buttons at the bottom), without a shadow.
void showNotice(
  BuildContext context,
  String message, {
  TextStyle? style,
  IconData icon = Icons.info_rounded,
  Color color = SegColors.primary,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || _visibleNotice == message) return;
  _noticeEntry?.remove();
  _visibleNotice = message;
  late final OverlayEntry entry;
  void close() {
    if (_noticeEntry != entry) return;
    entry.remove();
    _noticeEntry = null;
    _visibleNotice = null;
  }

  entry = OverlayEntry(
    builder: (context) => _TopNotice(
      message: message,
      style: style,
      icon: icon,
      color: color,
      onDone: close,
    ),
  );
  _noticeEntry = entry;
  overlay.insert(entry);
}

class _TopNotice extends StatefulWidget {
  final String message;
  final TextStyle? style;
  final IconData icon;
  final Color color;
  final VoidCallback onDone;
  const _TopNotice({
    required this.message,
    required this.style,
    required this.icon,
    required this.color,
    required this.onDone,
  });
  @override
  State<_TopNotice> createState() => _TopNoticeState();
}

class _TopNoticeState extends State<_TopNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + SegSpace.s3,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -.4),
              end: Offset.zero,
            ).animate(curve),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                key: const ValueKey('seg-notice'),
                width: math.min(width - 2 * SegSpace.s4, 520),
                padding: const EdgeInsets.fromLTRB(
                  SegSpace.s3,
                  SegSpace.s3,
                  SegSpace.s4,
                  SegSpace.s3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SegRadius.xl),
                  border: Border.all(
                    color: widget.color.withValues(alpha: .25),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 24),
                    ),
                    const SizedBox(width: SegSpace.s3),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: (widget.style ?? SegText.body).copyWith(
                          color: SegColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
