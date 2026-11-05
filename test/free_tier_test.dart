import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every theme with games has Learn and two games free', () async {
    final content = await ContentRepository.load();
    final free = AppConfiguration.defaults(content).freeGames;
    for (final theme in content.themes.where((t) => t.games.isNotEmpty)) {
      final cards = free.where((id) => id.startsWith('${theme.id}_')).toSet();
      expect(cards, hasLength(3), reason: theme.id);
      expect(cards, contains('${theme.id}_G02'), reason: '${theme.id} Learn');
      for (final id in cards) {
        expect(theme.games, contains(id.split('_')[1]), reason: id);
      }
    }
  });

  test(
    'a remote list that leaves a theme without a free card is ignored',
    () async {
      final content = await ContentRepository.load();
      final defaults = AppConfiguration.defaults(content);
      final old = defaults.merge({
        'freeGames': [
          'animals_G01',
          'produce_G01',
          'colors_G01',
          'animals_G10',
          'numbers_G35',
          'vehicles_G02',
        ],
      }, content);
      expect(old.freeGames, defaults.freeGames);
      final custom = defaults.merge({
        'freeGames': [
          for (final t in content.themes.where((t) => t.games.isNotEmpty))
            '${t.id}_${t.games.first}',
        ],
      }, content);
      expect(custom.freeGames, isNot(defaults.freeGames));
    },
  );
}
