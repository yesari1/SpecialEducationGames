import 'package:flutter/services.dart';

/// Parent-facing routes (onboarding and the family area) are upright; the
/// child's play space (home, themes, games, path, album, breaks) is landscape.
abstract final class AppOrientation {
  static bool isFamilyPath(String path) =>
      path == '/welcome' ||
      path == '/gate' ||
      path == '/family' ||
      path.startsWith('/family/');

  static List<DeviceOrientation> forPath(String path) => isFamilyPath(path)
      ? const [DeviceOrientation.portraitUp]
      : const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ];

  static String? _applied;

  static Future<void> apply(String path) {
    final family = isFamilyPath(path) ? 'family' : 'child';
    if (_applied == family) return Future.value();
    _applied = family;
    // The child's screens use the whole screen: the status and navigation
    // bars are hidden (a swipe from the edge shows them for a moment), so the
    // games are bigger and a small hand does not leave the app by accident.
    // The parent's screens keep the bars.
    SystemChrome.setEnabledSystemUIMode(
      family == 'child' ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    return SystemChrome.setPreferredOrientations(forPath(path));
  }
}
