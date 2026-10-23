import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/templates/game_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ContentItem item(
    String id, {
    required List<String> images,
    Map<String, dynamic>? provenance,
    Map<String, dynamic>? audio,
    String? sfx,
    String theme = 'animals',
  }) {
    final data = <String, dynamic>{
      'id': id,
      'theme': theme,
      'tier': 'easy',
      'name': {'tr': id, 'en': id},
      'images': images,
      'audio': audio ?? const <String, dynamic>{},
      'sfx': sfx,
    };
    if (provenance != null) data['imageProvenance'] = provenance;
    return ContentItem.fromJson(data);
  }

  Map<String, dynamic> photo(String path, String suffix) => {
    'path': path,
    'author': 'Fixture author $suffix',
    'source': 'https://example.test/photo-$suffix',
    'license': 'CC0 1.0',
    'licenseUrl': 'https://creativecommons.org/publicdomain/zero/1.0/',
    'sha256': suffix.padLeft(64, 'a'),
    'licenseVerified': true,
  };

  ContentRepository repository({required bool withVariants}) {
    final photos = <String, dynamic>{};
    if (withVariants) {
      photos['assets/images/animals/target-a.png'] = photo(
        'assets/images/animals/target-a.png',
        '1',
      );
      photos['assets/images/animals/target-b.png'] = photo(
        'assets/images/animals/target-b.png',
        '2',
      );
    }
    return ContentRepository(
      [],
      [
        item(
          'animals.target',
          images: withVariants
              ? photos.keys.toList()
              : ['assets/images/animals/target-a.png'],
          provenance: photos,
        ),
        item('animals.dog', images: ['assets/images/animals/dog.png']),
        item('animals.cat', images: ['assets/images/animals/cat.png']),
      ],
      [],
      {},
    );
  }

  ModeContext context(
    ContentRepository content,
    Difficulty difficulty, {
    int seed = 7,
  }) => ModeContext(
    content: content,
    themeId: 'animals',
    gameId: 'G14',
    difficulty: difficulty,
    scheduler: ItemScheduler(Random(seed)),
    struggle: const {},
    choiceCount: 3,
  );

  test('G14 Hard uses two verified photos of the same target', () {
    final content = repository(withVariants: true);
    expect(content.hasG14HardVariants('animals'), isTrue);

    final spec = const IdentifyTemplate().buildRound(
      context(content, Difficulty.hard),
    );
    expect(spec.target.id, 'animals.target');
    expect(
      spec.choices.where((choice) => choice.id == spec.target.id),
      hasLength(1),
    );
    expect(spec.promptImagePath, isNot(spec.correctChoiceImagePath));
    expect(spec.target.verifiedPhotoPaths, contains(spec.promptImagePath));
    expect(
      spec.target.verifiedPhotoPaths,
      contains(spec.correctChoiceImagePath),
    );
    expect(
      spec.choices
          .where((choice) => choice.id != spec.target.id)
          .map((x) => x.id)
          .toSet(),
      {'animals.dog', 'animals.cat'},
    );

    final rebuilt = spec.withChoices(spec.choices.reversed.toList());
    expect(rebuilt.promptImagePath, spec.promptImagePath);
    expect(rebuilt.correctChoiceImagePath, spec.correctChoiceImagePath);
  });

  test('G14 Hard is unavailable without two verified photos', () {
    final content = repository(withVariants: false);
    expect(content.hasG14HardVariants('animals'), isFalse);
    expect(
      () => const IdentifyTemplate().buildRound(
        context(content, Difficulty.hard),
      ),
      throwsStateError,
    );
  });

  test('G14 Easy retains the same image on prompt and correct answer', () {
    final content = repository(withVariants: true);
    final spec = const IdentifyTemplate().buildRound(
      context(content, Difficulty.easy),
    );
    expect(spec.promptImagePath, isNull);
    expect(spec.correctChoiceImagePath, isNull);
    expect(spec.target.images, isNotEmpty);
  });

  test('unproven legacy paths do not qualify as hard variants', () {
    final itemWithLegacyImages = item(
      'animals.target',
      images: const ['legacy-a.png', 'legacy-b.png'],
    );
    expect(itemWithLegacyImages.verifiedPhotoPaths, isEmpty);
  });

  test('duplicate file hashes are not treated as two different photos', () {
    const firstPath = 'assets/images/animals/duplicate-a.png';
    const secondPath = 'assets/images/animals/duplicate-b.png';
    final duplicate = item(
      'animals.target',
      images: const [firstPath, secondPath],
      provenance: {
        firstPath: {
          'path': firstPath,
          'author': 'Fixture photographer',
          'source': 'https://example.test/a',
          'license': 'CC0 1.0',
          'licenseUrl': 'https://example.test/license',
          'sha256': 'A' * 64,
          'licenseVerified': true,
        },
        secondPath: {
          'path': secondPath,
          'author': 'Fixture photographer',
          'source': 'https://example.test/b',
          'license': 'CC0 1.0',
          'licenseUrl': 'https://example.test/license',
          'sha256': 'a' * 64,
          'licenseVerified': true,
        },
      },
    );
    expect(duplicate.verifiedPhotoPaths, [firstPath]);
  });

  test('G10 chooses its target from the localized audio-filtered pool', () {
    final content = ContentRepository(
      [],
      [
        item('produce.no-audio', images: ['no-audio.png'], theme: 'produce'),
        item(
          'produce.audio-a',
          images: ['audio-a.png'],
          audio: const {'tr': 'assets/audio/tr/a.mp3'},
          theme: 'produce',
        ),
        item(
          'produce.audio-b',
          images: ['audio-b.png'],
          audio: const {'tr': 'assets/audio/tr/b.mp3'},
          theme: 'produce',
        ),
      ],
      [],
      {},
    );
    for (var seed = 0; seed < 20; seed++) {
      final spec = const IdentifyTemplate().buildRound(
        ModeContext(
          content: content,
          themeId: 'produce',
          gameId: 'G10',
          locale: 'tr',
          difficulty: Difficulty.easy,
          scheduler: ItemScheduler(Random(seed)),
          struggle: const {},
        ),
      );
      expect(spec.target.audioFor('tr'), isNotNull);
    }
  });

  test(
    'daily path excludes G14 when its effective difficulty is unavailable',
    () {
      // Not Android: no Google Play billing connection left behind.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final content = repository(withVariants: false);
      final state = AppState(
        content,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      addTearDown(state.dispose);
      state.configuration = AppConfiguration(freeGames: {'animals_G14'});
      state.entitlement
        ..storeActive = true
        ..lastConfirmedAt = DateTime.now();
      state.difficultyOverride = 'hard';
      expect(state.dailyPathSteps, isEmpty);

      state.difficultyOverride = 'easy';
      expect(state.dailyPathSteps, ['animals_G14']);
    },
  );
}
