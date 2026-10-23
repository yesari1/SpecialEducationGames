import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_version.dart';

void main() {
  test('appVersion matches pubspec.yaml', () {
    final line = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(appVersion, line.substring('version:'.length).trim());
  });
}
