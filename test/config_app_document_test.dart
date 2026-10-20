import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'the config/app document created in Firestore is accepted as-is',
    () async {
      final content = await ContentRepository.load();
      final base = AppConfiguration.defaults(content);
      // Same fields as tools/create_config_app.cjs writes.
      final merged = base.merge({
        'freeGames': [
          'animals_G01',
          'produce_G01',
          'colors_G01',
          'animals_G10',
          'numbers_G35',
          'vehicles_G02',
        ],
        'disabledGames': <String>[],
        'hiddenThemes': <String>[],
        'newBadge': <String>[],
        'paywallText': <String, String>{},
        'trialDays': 7,
        'privacyUrl': AppConfiguration.defaultPrivacyUrl,
        'termsUrl': AppConfiguration.defaultTermsUrl,
        'minSupportedVersion': 0,
        'difficultyDefaults': {
          'fadeAfterErrors': 2,
          'choiceCounts': {'easy': 2, 'medium': 3, 'hard': 4},
        },
      }, content);
      expect(merged.toJson(), base.toJson());
    },
  );
}
