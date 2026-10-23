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
    return SystemChrome.setPreferredOrientations(forPath(path));
  }
}
