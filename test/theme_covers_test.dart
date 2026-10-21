import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every playable theme has a bundled cover of the same size', () async {
    final content = await ContentRepository.load();
    final playable = content.themes.where((t) => t.games.isNotEmpty);
    expect(playable, isNotEmpty);
    for (final theme in playable) {
      expect(themeCovers, contains(theme.id), reason: theme.id);
      final bytes = await rootBundle.load(
        'assets/illustrations/themes/cover_${theme.id}.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      expect([image.width, image.height], [512, 512], reason: theme.id);
    }
  });
}
