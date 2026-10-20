import 'dart:convert';

import 'package:drift/native.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'audio_volume_test.dart' show VolumeBackend;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test(
    'Sound-required games use the correct channel and muted steps leave the daily path',
    () async {
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(backend: VolumeBackend()),
      );
      addTearDown(state.dispose);
      await state.load();
      expect(state.hasRequiredGameAudio('animals', 'G10'), isTrue);
      state.speechVolume = 0;
      expect(state.hasRequiredGameAudio('animals', 'G10'), isTrue);
      expect(state.hasRequiredGameAudio('numbers', 'G10'), isFalse);
      state.effectVolume = 0;
      expect(state.hasRequiredGameAudio('animals', 'G10'), isFalse);
      expect(state.dailyPathSteps, isNot(contains('animals_G10')));
      expect(state.hasRequiredGameAudio('animals', 'G01'), isTrue);
      state.effectVolume = 60;
      state.sound = false;
      expect(state.hasRequiredGameAudio('animals', 'G10'), isFalse);
    },
  );
  test(
    'G10 daily-path eligibility uses selected-locale voice availability',
    () async {
      final content = await ContentRepository.load();
      final state = AppState(
        content,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(backend: VolumeBackend()),
      );
      addTearDown(state.dispose);
      await state.load();
      state.configuration = state.configuration.merge({
        'freeGames': [
          'animals_G01',
          'produce_G01',
          'colors_G01',
          'numbers_G10',
          'numbers_G35',
          'vehicles_G02',
        ],
      }, content);
      // English number names are recorded now, so both locales qualify;
      // silencing speech still removes the game.
      state.locale = 'en';
      expect(state.hasRequiredGameAudio('numbers', 'G10'), isTrue);
      expect(state.dailyPathSteps, contains('numbers_G10'));
      state.speechVolume = 0;
      expect(state.hasRequiredGameAudio('numbers', 'G10'), isFalse);
      expect(state.dailyPathSteps, isNot(contains('numbers_G10')));
      state.speechVolume = 100;
      state.locale = 'tr';
      expect(state.hasRequiredGameAudio('numbers', 'G10'), isTrue);
      expect(state.dailyPathSteps, contains('numbers_G10'));
    },
  );
  test(
    'four licensed vehicle effects satisfy G10 choice minimum and respect audio gates',
    () async {
      final content = await ContentRepository.load();
      final vehicleEffects = content.items
          .where(
            (item) =>
                item.id == 'vehicles.car' ||
                item.id == 'vehicles.train' ||
                item.id == 'vehicles.airplane' ||
                item.id == 'vehicles.helicopter',
          )
          .toList();
      expect(vehicleEffects.map((item) => item.id).toSet(), {
        'vehicles.car',
        'vehicles.train',
        'vehicles.airplane',
        'vehicles.helicopter',
      });
      expect(
        content
            .pool('vehicles', Difficulty.easy, requireSfx: true)
            .map((item) => item.id)
            .toSet(),
        {
          'vehicles.car',
          'vehicles.train',
          'vehicles.airplane',
          'vehicles.helicopter',
        },
      );
      expect(
        content.hasLocalizedG10Content('vehicles', Difficulty.easy, 'en'),
        isTrue,
      );
      expect(
        content.hasLocalizedG10Content('vehicles', Difficulty.easy, 'tr'),
        isTrue,
      );

      final sourceRecords =
          (jsonDecode(await rootBundle.loadString('assets/sfx/sources.json'))
                  as List)
              .cast<Map<String, dynamic>>();
      final vehicleSourceRecords = sourceRecords
          .where(
            (record) =>
                record['itemId'] == 'vehicles.car' ||
                record['itemId'] == 'vehicles.train' ||
                record['itemId'] == 'vehicles.airplane' ||
                record['itemId'] == 'vehicles.helicopter',
          )
          .toList();
      expect(vehicleSourceRecords, hasLength(4));
      for (final item in vehicleEffects) {
        final asset = item.sfx;
        expect(asset, isNotNull);
        final soundBytes = await rootBundle.load(asset!);
        expect(soundBytes.lengthInBytes, greaterThan(1000));
        final source = vehicleSourceRecords.singleWhere(
          (record) => record['itemId'] == item.id,
        );
        expect(source['asset'], asset);
        if (item.id == 'vehicles.car') {
          expect(source['author'], '15HPanska_Ruttner_Jan');
          expect(source['license'], 'CC0-1.0');
          expect(
            source['source'],
            'https://commons.wikimedia.org/wiki/File:Car_Horn.wav',
          );
        } else if (item.id == 'vehicles.train') {
          expect(source['author'], 'Cityedit14');
          expect(source['license'], 'CC-BY-SA-4.0');
          expect(
            source['source'],
            'https://commons.wikimedia.org/wiki/File:4000_class_train_horn.ogg',
          );
          expect(source['adaptationLicense'], 'CC BY-SA 4.0');
        } else if (item.id == 'vehicles.airplane') {
          expect(source['author'], 'Jud McCranie (Bubba73)');
          expect(source['license'], 'CC-BY-SA-4.0');
          expect(
            source['source'],
            'https://commons.wikimedia.org/wiki/File:Jet_airliner_overhead.ogg',
          );
          expect(source['adaptationLicense'], 'CC BY-SA 4.0');
          expect(source['humanListeningApprovalPending'], isTrue);
        } else {
          expect(item.id, 'vehicles.helicopter');
          expect(source['author'], 'JoBrodie');
          expect(source['license'], 'CC0-1.0');
          expect(
            source['source'],
            'https://commons.wikimedia.org/wiki/File:Chinook_helicopter_flying_over_Greenwich_in_London.ogg',
          );
          expect(source['humanListeningApprovalPending'], isTrue);
          expect(source['contentNote'], contains('Generic helicopter'));
        }
        expect(
          sha256.convert(soundBytes.buffer.asUint8List()).toString(),
          source['sha256'],
        );
      }

      final state = AppState(
        content,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(backend: VolumeBackend()),
      );
      addTearDown(state.dispose);
      await state.load();
      state.configuration = state.configuration.merge({
        'freeGames': [
          'animals_G01',
          'produce_G01',
          'colors_G01',
          'animals_G10',
          'numbers_G10',
          'vehicles_G10',
        ],
      }, content);

      // Four licensed vehicle effects exceed G10's minimum in either locale;
      // number G10 still depends on the selected speech locale.
      state.locale = 'en';
      expect(state.hasRequiredGameAudio('vehicles', 'G10'), isTrue);
      expect(state.dailyPathSteps, contains('vehicles_G10'));
      expect(state.hasRequiredGameAudio('numbers', 'G10'), isTrue);

      state.locale = 'tr';
      expect(state.hasRequiredGameAudio('vehicles', 'G10'), isTrue);
      expect(state.hasRequiredGameAudio('numbers', 'G10'), isTrue);
      state.speechVolume = 0;
      expect(state.hasRequiredGameAudio('numbers', 'G10'), isFalse);
      expect(state.hasRequiredGameAudio('vehicles', 'G10'), isTrue);

      state.speechVolume = 100;
      expect(state.hasRequiredGameAudio('animals', 'G10'), isTrue);
      state.effectVolume = 0;
      expect(state.hasRequiredGameAudio('vehicles', 'G10'), isFalse);
      expect(state.hasRequiredGameAudio('animals', 'G10'), isFalse);
      state.effectVolume = 60;
      state.sound = false;
      expect(state.hasRequiredGameAudio('vehicles', 'G10'), isFalse);
      expect(state.hasRequiredGameAudio('animals', 'G10'), isFalse);
    },
  );
  test(
    'Volume levels are guarded, validated, restored and isolated per profile',
    () async {
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(backend: VolumeBackend()),
      );
      addTearDown(state.dispose);
      await state.load();
      await state.createProfile('One', 'cat', {});
      final first = state.active!;
      expect(state.speechVolume, 100);
      expect(state.effectVolume, 60);
      for (final key in ['speechVolume', 'effectVolume']) {
        await expectLater(state.setting(key, '25'), throwsStateError);
      }
      state.unlockFamily();
      for (final value in ['-1', '101', '12.5', 'true']) {
        await expectLater(
          state.setting('speechVolume', value),
          throwsArgumentError,
        );
        await expectLater(
          state.setting('effectVolume', value),
          throwsArgumentError,
        );
      }
      await state.setting('speechVolume', '0');
      await state.setting('effectVolume', '85');
      await state.load();
      expect(state.audio.speechVolume, 0);
      expect(state.audio.effectVolume, 85);
      await state.entitlement.confirmStoreState(true);
      await state.createProfile('Two', 'dog', {});
      expect(state.speechVolume, 100);
      expect(state.effectVolume, 60);
      await state.setting('speechVolume', '40');
      await state.selectProfile(first);
      expect(state.speechVolume, 0);
      expect(state.effectVolume, 85);
      await state.setting('sound', 'false');
      expect(state.audio.enabled, false);
      expect(state.audio.effectVolume, 85);
      await state.db.setPreference('profile.${first.id}.speechVolume', '400');
      await state.load();
      expect(state.speechVolume, 100);
    },
  );
}
