import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('active themes speak every item in its own language', () async {
    final content = await ContentRepository.load();
    final problems = <String>[];
    for (final item in content.items) {
      final tr = item.audioFor('tr'), en = item.audioFor('en');
      if (tr == null || en == null) {
        problems.add('${item.id}: missing audio');
        continue;
      }
      // Hundreds of bundled loads in a row need the event loop to turn.
      await Future<void>.delayed(Duration.zero);
      final trData = await rootBundle.load(tr);
      final enData = await rootBundle.load(en);
      if (trData.lengthInBytes < 1000 || enData.lengthInBytes < 1000) {
        problems.add('${item.id}: short audio');
      }
      if (tr == en ||
          _same(trData.buffer.asUint8List(), enData.buffer.asUint8List())) {
        problems.add('${item.id}: TR and EN are the same recording');
      }
    }
    expect(problems, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('every spoken instruction is bundled and recorded in the manifest', () {
    final manifest =
        jsonDecode(
              File(
                'assets/content/generated_voice_manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final clips = (manifest['clips'] as Map<String, dynamic>).values
        .cast<Map<String, dynamic>>();
    expect(clips, isNotEmpty);
    for (final clip in clips) {
      final file = File(clip['path'] as String);
      expect(file.existsSync(), isTrue, reason: clip['path'] as String);
      expect(file.lengthSync(), clip['bytes'], reason: clip['path'] as String);
      expect(clip['voice_id'], switch (clip['language']) {
        'tr' => 'uvU9jrgGLWNPeNA4NgNT',
        _ => 'GZ4PpFJV8ikEGUtBrjK7',
      });
      // Turkish clips recorded since Nov 2026 use eleven_v4 (clearer Turkish).
      expect(
        clip['model_id'],
        clip['language'] == 'tr'
            ? anyOf('eleven_multilingual_v2', 'eleven_v4')
            : 'eleven_multilingual_v2',
      );
    }
    for (final lang in ['tr', 'en']) {
      for (final stem in [
        'count',
        'compare_magnitude',
        'compare_numbers',
        'group_membership',
        'find_match',
        'listen_number',
        'listen_sound',
        'sequence_next',
        'sequence_missing',
        'odd_one_out',
        'shadow_match',
        'sort_basket',
        'number_quantity',
        'which_sound',
        'praise',
        'retry',
        for (var n = 1; n <= 7; n++) 'fill_count_$n',
      ]) {
        expect(
          File('assets/audio/$lang/prompts/${stem}_selected.mp3').existsSync(),
          isTrue,
          reason: '$lang $stem',
        );
      }
    }
  });
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
