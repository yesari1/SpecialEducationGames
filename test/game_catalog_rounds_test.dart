import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/game/templates/game_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async => content = await ContentRepository.load());

  test('Vehicles G10 Hard presents four distinct licensed sound targets', () {
    final available = content
        .pool('vehicles', Difficulty.hard, requireSfx: true)
        .map((item) => item.id)
        .toSet();
    expect(available, {
      'vehicles.car',
      'vehicles.train',
      'vehicles.airplane',
      'vehicles.helicopter',
    });
    for (final locale in const ['tr', 'en']) {
      final context = ModeContext(
        content: content,
        themeId: 'vehicles',
        gameId: 'G10',
        locale: locale,
        difficulty: Difficulty.hard,
        scheduler: ItemScheduler(Random(23)),
        struggle: const {},
        choiceCount: Difficulty.hard.choices,
      );
      final round = TemplateRegistry.resolve('G10').buildRound(context);
      expect(round.choices, hasLength(4));
      expect(round.choices.map((item) => item.id).toSet(), hasLength(4));
      expect(round.choices.map((item) => item.id).toSet(), available);
      expect(round.choices.every((item) => item.sfx != null), isTrue);
      expect(round.choices.every((item) => item.name(locale).isNotEmpty), isTrue);
    }
  });

  test('Declared catalog rounds remain buildable across bounded seeds', () {
    final failures = <String>[];
    var probed = 0;
    var unavailableG14HardCases = 0;
    var buildableAnimalG14HardCases = 0;

    void require(bool condition, String context, String issue) {
      if (!condition) failures.add('$context: $issue');
    }

    for (final theme in content.themes) {
      for (final gameId in theme.games) {
        for (final locale in const ['tr', 'en']) {
          // GameScreen gates G10 on this same locale-aware audio availability.
          if (gameId == 'G10' &&
              !content.hasLocalizedG10Content(
                theme.id,
                Difficulty.easy,
                locale,
              )) {
            continue;
          }

          for (final difficulty in Difficulty.values) {
            if (gameId == 'G14' && difficulty == Difficulty.hard) {
              final available = content.isGameContentAvailable(
                theme.id,
                gameId,
                difficulty,
              );
              if (!available) {
                final unavailableContext = ModeContext(
                  content: content,
                  themeId: theme.id,
                  gameId: gameId,
                  locale: locale,
                  difficulty: difficulty,
                  scheduler: ItemScheduler(Random(0)),
                  struggle: const {},
                  choiceCount: difficulty.choices,
                );
                probed++;
                unavailableG14HardCases++;
                expect(
                  () => TemplateRegistry.resolve(
                    gameId,
                  ).buildRound(unavailableContext),
                  throwsA(isA<StateError>()),
                  reason:
                      '${theme.id}/$gameId/${difficulty.name}/$locale is correctly unavailable',
                );
                continue;
              }
            }
            for (var seed = 0; seed < 8; seed++) {
              final context = ModeContext(
                content: content,
                themeId: theme.id,
                gameId: gameId,
                locale: locale,
                difficulty: difficulty,
                scheduler: ItemScheduler(Random(seed)),
                struggle: const {},
                choiceCount: difficulty.choices,
              );
              final label =
                  '${theme.id}/$gameId/${difficulty.name}/$locale/seed=$seed';
              probed++;

              try {
                final spec = TemplateRegistry.resolve(
                  gameId,
                ).buildRound(context);
                if (theme.id == 'animals' &&
                    gameId == 'G14' &&
                    difficulty == Difficulty.hard) {
                  buildableAnimalG14HardCases++;
                  require(
                    spec.promptImagePath != null &&
                        spec.correctChoiceImagePath != null &&
                        spec.promptImagePath != spec.correctChoiceImagePath,
                    label,
                    'available animal hard round must use two distinct verified photos',
                  );
                }
                final ids = spec.choices.map((item) => item.id).toList();
                final uniqueIds = ids.toSet();
                final singleChoice = gameId == 'G02' || gameId == 'G55';
                final specialThree =
                    gameId == 'G36' && difficulty == Difficulty.hard;
                final maxChoices = singleChoice
                    ? 1
                    : specialThree
                    ? 3
                    : difficulty.choices;

                require(spec.choices.isNotEmpty, label, 'no choices');
                require(
                  uniqueIds.length == ids.length,
                  label,
                  'duplicate choice IDs: $ids',
                );
                require(
                  uniqueIds.contains(spec.target.id),
                  label,
                  'target ${spec.target.id} is absent from choices',
                );
                require(
                  ids.where((id) => id == spec.target.id).length == 1,
                  label,
                  'target must occur exactly once',
                );
                require(
                  ids.length <= maxChoices,
                  label,
                  '${ids.length} choices exceed expected maximum $maxChoices',
                );
                if (!singleChoice) {
                  require(
                    ids.length >= 2,
                    label,
                    'non-exploratory round has fewer than two choices',
                  );
                }
                for (final choice in spec.choices) {
                  require(
                    choice.name(locale).trim().isNotEmpty,
                    label,
                    '${choice.id} has no $locale label',
                  );
                }

                switch (gameId) {
                  case 'G04':
                    require(
                      spec.stimulus != null,
                      label,
                      'group round has no stimulus',
                    );
                    require(
                      spec.target.id.startsWith('group.'),
                      label,
                      'group target ID is malformed: ${spec.target.id}',
                    );
                    break;
                  case 'G33':
                    require(spec.count != null, label, 'count is missing');
                    require(
                      int.tryParse(spec.target.slug) == spec.count,
                      label,
                      'count ${spec.count} does not match target ${spec.target.id}',
                    );
                    break;
                  case 'G35':
                    require(
                      spec.sequence.length == 3 &&
                          spec.sequence.where((part) => part == '?').length ==
                              1,
                      label,
                      'sequence must contain three parts and one blank: ${spec.sequence}',
                    );
                    require(
                      int.tryParse(spec.target.slug) != null,
                      label,
                      'sequence target is not numeric: ${spec.target.id}',
                    );
                    break;
                  case 'G36':
                    if (difficulty == Difficulty.hard) {
                      require(
                        spec.choices.length == 3 &&
                            spec.sequence.length == 3 &&
                            spec.sequence[1] == '?',
                        label,
                        'hard comparison must retain three relations and a missing-value prompt',
                      );
                    } else {
                      require(
                        spec.quantities.keys.toSet().containsAll(uniqueIds) &&
                            uniqueIds.containsAll(spec.quantities.keys),
                        label,
                        'comparison quantities do not match answer choices',
                      );
                    }
                    break;
                }
              } catch (error) {
                failures.add('$label: ${error.runtimeType}: $error');
              }
            }
          }
        }
      }
    }

    expect(probed, greaterThan(0));
    expect(unavailableG14HardCases, greaterThan(0));
    expect(buildableAnimalG14HardCases, 16);
    expect(
      failures,
      isEmpty,
      reason: 'Round-generation audit ($probed cases):\n${failures.join('\n')}',
    );
  });
}
