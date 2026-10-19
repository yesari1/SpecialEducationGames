import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A child's profile mark: the first letter of the nickname in a soft circle.
/// The colour is stable per name so siblings are easy to tell apart.
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialAvatar({super.key, required this.name, this.size = 48});

  static const _palette = [
    (Color(0xFFE5F4FF), SegColors.primaryDeep),
    (Color(0xFFDDF6F3), SegColors.turquoiseDeep),
    (Color(0xFFFFEBDD), SegColors.accentDeep),
    (Color(0xFFEDEBFF), Color(0xFF5A50B8)),
    (Color(0xFFFFE8EF), Color(0xFFB0476A)),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? null
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    final seed = trimmed.runes.fold<int>(0, (sum, rune) => sum + rune);
    final (fill, ink) = _palette[seed % _palette.length];
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: size * .06),
          boxShadow: [
            BoxShadow(
              color: ink.withValues(alpha: .12),
              blurRadius: size * .2,
              offset: Offset(0, size * .06),
            ),
          ],
        ),
        child: initial == null
            ? Icon(Icons.face_rounded, color: ink, size: size * .52)
            : Text(
                initial,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: size * .46,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1,
                ),
              ),
      ),
    );
  }
}
