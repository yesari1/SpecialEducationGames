import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/config/config_repository.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Choice counts accept complete bounded monotonic tiers and freeze input',
    () async {
      final content = await ContentRepository.load();
      final defaults = AppConfiguration.defaults(content);
      expect(defaults.choiceCounts, {'easy': 2, 'medium': 3, 'hard': 4});
      for (final counts in [
        {'easy': 2, 'medium': 2, 'hard': 3},
        {'easy': 2, 'medium': 3, 'hard': 4},
        {'easy': 4, 'medium': 4, 'hard': 4},
      ]) {
        final config = defaults.merge({
          'difficultyDefaults': {'choiceCounts': counts},
        }, content);
        expect(config.choiceCounts, counts);
        expect(config.choicesFor(Difficulty.easy), counts['easy']);
        expect(config.choicesFor(Difficulty.medium), counts['medium']);
        expect(config.choicesFor(Difficulty.hard), counts['hard']);
        expect(() => config.choiceCounts['easy'] = 4, throwsUnsupportedError);
        expect(defaults.merge(config.toJson(), content).choiceCounts, counts);
      }
      final input = {'easy': 2, 'medium': 2, 'hard': 3};
      final direct = AppConfiguration(freeGames: {}, choiceCounts: input);
      input['easy'] = 4;
      expect(direct.choicesFor(Difficulty.easy), 2);
    },
  );
  test(
    'Difficulty changes are partial, transactional and explicitly resettable',
    () async {
      final content = await ContentRepository.load();
      final defaults = AppConfiguration.defaults(content);
      final changed = defaults.merge({
        'difficultyDefaults': {
          'fadeAfterErrors': 3,
          'choiceCounts': {'easy': 2, 'medium': 2, 'hard': 3},
        },
      }, content);
      expect(changed.merge({}, content).choiceCounts, changed.choiceCounts);
      final fadeOnly = changed.merge({
        'difficultyDefaults': {'fadeAfterErrors': 1},
      }, content);
      expect(fadeOnly.fadeAfterErrors, 1);
      expect(fadeOnly.choiceCounts, changed.choiceCounts);
      final countOnly = changed.merge({
        'difficultyDefaults': {
          'choiceCounts': {'easy': 3, 'medium': 3, 'hard': 4},
        },
      }, content);
      expect(countOnly.fadeAfterErrors, 3);
      expect(countOnly.choicesFor(Difficulty.easy), 3);
      for (final counts in [
        null,
        [],
        3,
        {},
        {'easy': 2, 'medium': 3},
        {'easy': 2, 'medium': 3, 'hard': 4, 'extra': 2},
        {'easy': true, 'medium': 3, 'hard': 4},
        {'easy': '2', 'medium': 3, 'hard': 4},
        {'easy': 2.0, 'medium': 3, 'hard': 4},
        {'easy': 1, 'medium': 3, 'hard': 4},
        {'easy': 2, 'medium': 3, 'hard': 5},
        {'easy': 3, 'medium': 2, 'hard': 4},
        {'easy': 2, 'medium': 4, 'hard': 3},
      ]) {
        final invalid = changed.merge({
          'difficultyDefaults': {'fadeAfterErrors': 1, 'choiceCounts': counts},
        }, content);
        expect(invalid.fadeAfterErrors, 3);
        expect(invalid.choiceCounts, changed.choiceCounts);
      }
      for (final invalid in [
        {
          'fadeAfterErrors': 0,
          'choiceCounts': AppConfiguration.defaultChoiceCounts,
        },
        {'choiceCounts': AppConfiguration.defaultChoiceCounts, 'unknown': 2},
      ]) {
        final result = changed.merge({'difficultyDefaults': invalid}, content);
        expect(result.fadeAfterErrors, 3);
        expect(result.choiceCounts, changed.choiceCounts);
      }
      final reset = changed.merge({'difficultyDefaults': {}}, content);
      expect(reset.fadeAfterErrors, 2);
      expect(reset.choiceCounts, defaults.choiceCounts);
    },
  );
  test(
    'Choice counts survive persistent configuration reload with fade threshold',
    () async {
      final content = await ContentRepository.load();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ConfigRepository(db, content);
      await repository.refresh(
        () async => {
          'difficultyDefaults': {
            'fadeAfterErrors': 3,
            'choiceCounts': {'easy': 2, 'medium': 2, 'hard': 3},
          },
        },
      );
      final reload = await ConfigRepository(db, content).load();
      expect(reload.fadeAfterErrors, 3);
      expect(reload.choiceCounts, {'easy': 2, 'medium': 2, 'hard': 3});
    },
  );
  test(
    'Announcement IDs are strict, clear explicitly and survive the cache',
    () async {
      final content = await ContentRepository.load();
      final defaults = AppConfiguration.defaults(content);
      final valid = defaults.merge({'announcementId': 'parent-2026'}, content);
      expect(valid.announcementId, 'parent-2026');
      for (final invalid in [
        42,
        true,
        {},
        'a/b',
        '..',
        'a_b',
        'a b',
        'x' * 129,
      ]) {
        expect(
          valid.merge({'announcementId': invalid}, content).announcementId,
          'parent-2026',
        );
      }
      expect(valid.merge({}, content).announcementId, 'parent-2026');
      expect(
        valid.merge({'announcementId': null}, content).announcementId,
        isNull,
      );
      expect(
        valid.merge({'announcementId': ''}, content).announcementId,
        isNull,
      );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.setPreference('appConfig', '{"announcementId":"parent-2026"}');
      expect(
        (await ConfigRepository(db, content).load()).announcementId,
        'parent-2026',
      );
      expect(
        defaults.merge(valid.toJson(), content).announcementId,
        'parent-2026',
      );
    },
  );
  test(
    'Error fade threshold accepts only supported strict integers and can reset',
    () async {
      final content = await ContentRepository.load();
      final defaults = AppConfiguration.defaults(content);
      expect(defaults.fadeAfterErrors, 2);
      for (final threshold in [1, 2, 3]) {
        final config = defaults.merge({
          'difficultyDefaults': {'fadeAfterErrors': threshold},
        }, content);
        expect(config.fadeAfterErrors, threshold);
        expect(
          defaults.merge(config.toJson(), content).fadeAfterErrors,
          threshold,
        );
        expect(config.freeGames, defaults.freeGames);
      }
      final changed = defaults.merge({
        'difficultyDefaults': {'fadeAfterErrors': 3},
      }, content);
      for (final raw in [
        null,
        '3',
        [],
        {'fadeAfterErrors': true},
        {'fadeAfterErrors': '3'},
        {'fadeAfterErrors': 2.0},
        {'fadeAfterErrors': 0},
        {'fadeAfterErrors': 4},
        {'optionCount': 3},
        {'fadeAfterErrors': 1, 'optionCount': 3},
      ]) {
        expect(
          changed.merge({'difficultyDefaults': raw}, content).fadeAfterErrors,
          3,
        );
      }
      expect(changed.merge({}, content).fadeAfterErrors, 3);
      expect(
        changed.merge({'difficultyDefaults': {}}, content).fadeAfterErrors,
        2,
      );
    },
  );
  test(
    'Theme badges and localized titles validate strictly and clear explicitly',
    () async {
      final content = await ContentRepository.load();
      final defaults = AppConfiguration.defaults(content);
      final valid = defaults.merge({
        'newBadge': ['animals', 'vehicles', 'animals'],
        'paywallText': {'tr': ' Ailenle öğren ', 'en': 'Learn together'},
      }, content);
      expect(valid.newBadge, {'animals', 'vehicles'});
      expect(valid.paywallText, {
        'tr': 'Ailenle öğren',
        'en': 'Learn together',
      });
      expect(() => valid.newBadge.add('colors'), throwsUnsupportedError);
      expect(() => valid.paywallText['tr'] = 'change', throwsUnsupportedError);
      expect(valid.freeGames, defaults.freeGames);
      expect(valid.disabledGames, defaults.disabledGames);
      expect(valid.minSupportedVersion, defaults.minSupportedVersion);
      final roundtrip = defaults.merge(valid.toJson(), content);
      expect(roundtrip.newBadge, valid.newBadge);
      expect(roundtrip.paywallText, valid.paywallText);
      for (final invalid in [
        {
          'newBadge': ['unknown'],
          'paywallText': {'de': 'Title'},
        },
        {
          'newBadge': [1],
          'paywallText': {'tr': 42},
        },
        {
          'newBadge': 'animals',
          'paywallText': {'en': 'a' * 121},
        },
        {
          'newBadge': null,
          'paywallText': {'tr': 'line\nbreak'},
        },
        {
          'paywallText': {
            'tr': {'title': 'nested'},
          },
        },
        {
          'paywallText': ['Title'],
        },
      ]) {
        final unchanged = valid.merge(invalid, content);
        expect(unchanged.newBadge, valid.newBadge);
        expect(unchanged.paywallText, valid.paywallText);
      }
      final emptyTitle = valid.merge({
        'paywallText': {'tr': ''},
      }, content);
      expect(emptyTitle.paywallText, isEmpty);
      final whitespaceTitle = valid.merge({
        'paywallText': {'en': '   '},
      }, content);
      expect(whitespaceTitle.paywallText, isEmpty);
      final cleared = valid.merge({'newBadge': [], 'paywallText': {}}, content);
      expect(cleared.newBadge, isEmpty);
      expect(cleared.paywallText, isEmpty);
      expect(cleared.freeGames, defaults.freeGames);
    },
  );

  test(
    'Badge and title overrides survive persistent config cache reload',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final content = await ContentRepository.load();
      final first = ConfigRepository(db, content);
      await first.load();
      await first.refresh(
        () async => {
          'newBadge': ['produce'],
          'paywallText': {'tr': 'Birlikte keşfet', 'en': 'Discover together'},
          'difficultyDefaults': {'fadeAfterErrors': 3},
        },
      );
      final reloaded = await ConfigRepository(db, content).load();
      expect(reloaded.newBadge, {'produce'});
      expect(reloaded.paywallText['en'], 'Discover together');
      expect(reloaded.fadeAfterErrors, 3);
      expect(reloaded.freeGames, content.freeGames);
    },
  );
  test(
    'Remote config validates IDs, types and exactly six free games',
    () async {
      final content = await ContentRepository.load();
      final defaults = AppConfiguration.defaults(content);
      final valid = defaults.merge({
        'disabledGames': ['animals_G01'],
        'hiddenThemes': ['vehicles'],
        'gameOrder': {
          'animals': ['G10', 'G01'],
        },
        'minSupportedVersion': 15,
      }, content);
      expect(valid.disabledGames, {'animals_G01'});
      expect(valid.gameOrder['animals']!.take(2), ['G10', 'G01']);
      expect(
        valid.gameOrder['animals']!.length,
        content.theme('animals').games.length,
      );
      final invalid = valid.merge({
        'freeGames': ['animals_G01'],
        'disabledGames': [12],
        'hiddenThemes': ['unknown'],
        'minSupportedVersion': '999',
        'gameOrder': {
          'animals': ['G99'],
        },
      }, content);
      expect(invalid.freeGames, defaults.freeGames);
      expect(invalid.disabledGames, valid.disabledGames);
      expect(invalid.hiddenThemes, valid.hiddenThemes);
      expect(invalid.minSupportedVersion, 15);
      expect(invalid.gameOrder, valid.gameOrder);
    },
  );
  test(
    'Config survives offline restart and limits failed fetches to six hours',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      var time = DateTime(2026, 10, 16, 2);
      final repo = ConfigRepository(
        db,
        await ContentRepository.load(),
        now: () => time,
      );
      await db.setPreference('appConfig', 'broken-json');
      expect((await repo.load()).freeGames.length, 48);
      var requests = 0;
      final config = await repo.refresh(() async {
        requests++;
        return {
          'disabledGames': ['animals_G01'],
        };
      });
      expect(config!.disabledGames, {'animals_G01'});
      expect((await repo.load()).disabledGames, config.disabledGames);
      await repo.refresh(() async {
        requests++;
        throw StateError('offline');
      });
      expect(requests, 1);
      time = time.add(const Duration(hours: 6));
      expect(
        await repo.refresh(() async {
          requests++;
          throw StateError('offline');
        }),
        isNull,
      );
      expect(requests, 2);
      expect((await repo.load()).disabledGames, config.disabledGames);
    },
  );
}
