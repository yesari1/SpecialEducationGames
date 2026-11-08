import 'package:flutter/material.dart';

/// Mascot spot on the welcome page and the first game's hello. [asset] null keeps the spot empty; the final mascot art
/// replaces [mascotCloud] later.
class MascotSlot extends StatelessWidget {
  /// The cloud character of the app icon (transparent launcher foreground).
  static const mascotCloud = 'assets/illustrations/onboarding/mascot_cloud.png';

  final String? asset;
  final double height;
  const MascotSlot({super.key, this.asset = mascotCloud, this.height = 96});

  @override
  Widget build(BuildContext context) {
    final image = asset;
    if (image == null) {
      return const SizedBox.shrink(key: ValueKey('mascot-slot'));
    }
    return SizedBox(
      key: const ValueKey('mascot-slot'),
      height: height,
      child: Image.asset(
        image,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}
