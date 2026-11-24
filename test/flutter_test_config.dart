import 'dart:async';

import 'package:special_education_games/app/ui/ambient_motion.dart';

/// Endless decorative loops never settle; host tests see them still.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AmbientMotion.enabled = false;
  await testMain();
}
