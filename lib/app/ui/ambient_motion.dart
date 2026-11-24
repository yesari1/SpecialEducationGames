/// Endless decorative motion (the Premium page's game moments, the welcome
/// picture's float). Host tests switch it off (test/flutter_test_config.dart)
/// so `pumpAndSettle` can settle; the app always has it on. Reduced motion
/// is still checked by each widget.
abstract final class AmbientMotion {
  static bool enabled = true;
}
