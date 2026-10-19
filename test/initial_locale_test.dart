import 'dart:ui' show Locale;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  for (final deviceLanguage in ['tr', 'en', 'de']) {
    test(
      'First launch selects and retains device language $deviceLanguage',
      () async {
        binding.platformDispatcher.localeTestValue = Locale(deviceLanguage);
        addTearDown(binding.platformDispatcher.clearLocaleTestValue);
        final state = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        addTearDown(state.dispose);
        await state.load();
        final expected = deviceLanguage == 'tr' ? 'tr' : 'en';
        expect(state.locale, expected);
        expect(await state.db.preference('locale'), expected);
        await state.createProfile('Explorer', 'cat', {});
        expect(state.locale, expected);

        binding.platformDispatcher.localeTestValue = Locale(
          expected == 'tr' ? 'en' : 'tr',
        );
        await state.load();
        expect(state.locale, expected);

        state.unlockFamily();
        final chosen = expected == 'tr' ? 'en' : 'tr';
        await state.setting('locale', chosen);
        await state.load();
        expect(state.locale, chosen);
        expect(
          await state.db.preference('profile.${state.active!.id}.locale'),
          chosen,
        );
      },
    );
  }

  test(
    'Existing profile language overrides device language without migration',
    () async {
      binding.platformDispatcher.localeTestValue = const Locale('en');
      addTearDown(binding.platformDispatcher.clearLocaleTestValue);
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      addTearDown(state.dispose);
      await state.db.setPreference('locale', 'tr');
      await state.load();
      expect(state.locale, 'tr');
      await state.createProfile('Deniz', 'cat', {});
      state.unlockFamily();
      await state.setting('locale', 'en');
      binding.platformDispatcher.localeTestValue = const Locale('tr');
      await state.load();
      expect(state.locale, 'en');
    },
  );
}
