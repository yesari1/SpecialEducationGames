import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/features/game/round_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy English mapping is unavailable while Turkish remains usable',
    () async {
      // The catalog now uses real English recordings; the quarantine still
      // applies to any item pointing at a legacy Turkish-in-English file.
      final bird = ContentItem.fromJson({
        'id': 'animals.bird',
        'theme': 'animals',
        'tier': 'easy',
        'name': {'tr': 'Kuş', 'en': 'Bird'},
        'audio': {
          'tr': 'assets/audio/tr/animals/bird.mp3',
          'en': 'assets/audio/en/animals/bird.mp3',
        },
      });
      expect(bird.audioFor('tr'), bird.audio['tr']);
      expect(bird.audioFor('en'), isNull);
      final content = await ContentRepository.load();
      final catalogBird = content.items.firstWhere((x) => x.id == bird.id);
      expect(catalogBird.audioFor('en'), endsWith('bird_selected.mp3'));
    },
  );

  test('equal labels may use the other locale asset as a safe fallback', () {
    final item = ContentItem.fromJson({
      'id': 'colors.gray',
      'theme': 'colors',
      'tier': 'easy',
      'name': {'tr': 'Gray', 'en': 'Gray'},
      'audio': {'tr': 'assets/audio/tr/gray.mp3'},
    });
    expect(item.audioFor('en'), 'assets/audio/tr/gray.mp3');
  });

  test('a corrected English asset path is no longer quarantined', () {
    final item = ContentItem.fromJson({
      'id': 'animals.bird',
      'theme': 'animals',
      'tier': 'easy',
      'name': {'tr': 'Kuş', 'en': 'Bird'},
      'audio': {'en': 'assets/audio/en/animals/bird_corrected.mp3'},
    });
    expect(item.audioFor('en'), 'assets/audio/en/animals/bird_corrected.mp3');
  });

  test('G10 localized candidate eligibility matches locale policy', () async {
    final content = await ContentRepository.load();
    expect(
      content.hasLocalizedG10Content('animals', Difficulty.easy, 'en'),
      true,
      reason: 'animal G10 uses its existing sound effects',
    );
    // English colour names are recorded now (Laura voice).
    expect(
      content.hasLocalizedG10Content('colors', Difficulty.easy, 'en'),
      true,
    );
    expect(
      content.hasLocalizedG10Content('colors', Difficulty.easy, 'tr'),
      true,
    );

    RoundController controller(String locale) => RoundController(
      content: content,
      themeId: 'colors',
      gameId: 'G10',
      locale: locale,
      difficulty: Difficulty.easy,
      struggle: {},
      saveTrial: (_) async {},
      playPrompt: (_) async {},
    );

    final english = controller('en')..start();
    expect(english.error, isNull);
    expect(english.spec!.target.audioFor('en'), endsWith('_selected.mp3'));
    english.dispose();
    final turkish = controller('tr')..start();
    expect(turkish.spec, isNotNull);
    expect(turkish.spec!.target.audioFor('tr'), isNotNull);
    turkish.dispose();
  });
}
