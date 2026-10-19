import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every item photo has precomputed framing bounds', () async {
    // Regenerate with: python -I tools/build_photo_bounds.py
    final bounds =
        jsonDecode(File('assets/content/photo_bounds.json').readAsStringSync())
            as Map<String, dynamic>;
    final content = await ContentRepository.load();
    final missing = <String>{
      for (final item in content.items)
        for (final path in item.images)
          if (!bounds.containsKey(path)) path,
    };
    expect(missing, isEmpty);
    for (final MapEntry(:key, :value) in bounds.entries) {
      final [l, t, r, b] = (value as List).cast<num>();
      expect(l >= 0 && t >= 0 && r <= 1 && b <= 1, isTrue, reason: key);
      expect(r > l && b > t, isTrue, reason: key);
    }
  });
}
