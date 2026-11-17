import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// "Sign in with Google" in Google's own button style: white, a thin grey
/// border and the four-colour "G" on the left.
class GoogleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GoogleSignInButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F1F),
        side: const BorderSide(color: Color(0xFF747775)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SegRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: SegSpace.s4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 22,
            child: CustomPaint(painter: _GoogleGPainter()),
          ),
          const SizedBox(width: SegSpace.s3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SegText.label.copyWith(
                color: const Color(0xFF1F1F1F),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// "Sign in with Apple" in Apple's own style: black, the white Apple logo,
/// the same size and shape as the Google button next to it.
class AppleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const AppleSignInButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SegRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: SegSpace.s4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apple, size: 24),
          const SizedBox(width: SegSpace.s3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SegText.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The Google "G": four coloured arcs and the blue bar.
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * .2;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: (s - stroke) / 2,
    );
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double rad(double deg) => deg * math.pi / 180;
    // Angles clockwise from 3 o'clock.
    canvas.drawArc(
      rect,
      rad(-40),
      rad(-90),
      false,
      arc(const Color(0xFFEA4335)),
    );
    canvas.drawArc(
      rect,
      rad(-130),
      rad(-95),
      false,
      arc(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      rect,
      rad(-225),
      rad(-90),
      false,
      arc(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      rect,
      rad(45),
      rad(-45),
      false,
      arc(const Color(0xFF4285F4)),
    );
    // The bar into the middle.
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke / 4, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
