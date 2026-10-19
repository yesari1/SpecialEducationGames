import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A collected day sticker: a round badge with a white rim; the motif and
/// colour vary by date so the album feels like a collection.
class DaySticker extends StatelessWidget {
  final String day;
  final double size;
  const DaySticker({super.key, required this.day, required this.size});
  static const _motifs = [
    (Icons.star_rounded, SegColors.star),
    (Icons.wb_sunny_rounded, SegColors.accent),
    (Icons.favorite_rounded, Color(0xFFE76F8E)),
    (Icons.local_florist_rounded, SegColors.turquoise),
    (Icons.cloud_rounded, SegColors.sky),
    (Icons.emoji_nature_rounded, Color(0xFF7C73DF)),
  ];
  @override
  Widget build(BuildContext context) {
    final (icon, color) = _motifs[day.hashCode.abs() % _motifs.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, color, .22),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * .07),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .25),
            blurRadius: size * .2,
            offset: Offset(0, size * .06),
          ),
        ],
      ),
      child: Icon(icon, size: size * .55, color: color),
    );
  }
}
