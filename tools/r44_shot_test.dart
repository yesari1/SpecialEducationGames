// Run explicitly:
//   flutter test tools/r44_shot_test.dart --update-goldens --dart-define=SHOT=after
// Renders Today's Path (child, landscape) and every family tab (portrait,
// tall to see the whole page) in TR and EN to artifacts/claude/r44/.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

const _shot = String.fromEnvironment('SHOT', defaultValue: 'after');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Widget _app(String locale, Widget home) => RepaintBoundary(
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: segTheme(),
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  ),
);

Future<void> _save(WidgetTester tester, String name) => expectLater(
  find.byType(RepaintBoundary).first,
  matchesGoldenFile('../artifacts/claude/r45/$_shot-$name.png'),
);

void main() {
  testWidgets('r44 shots', (tester) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
    });
    for (final locale in ['tr', 'en']) {
      final state = (await tester.runAsync(() async {
        final s = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await s.load();
        await s.createProfile(locale == 'tr' ? 'Deniz' : 'Ella', 'cat', {});
        return s;
      }))!;
      state.locale = locale;
      state.audio.enabled = false;
      tester.view.devicePixelRatio = 2.625;

      // Today's Path.
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pumpWidget(_app(locale, HomeScreen(state: state)));
      await _settle(tester);
      await tester.tap(
        find.text(locale == 'tr' ? 'Bugünün Yolu' : 'Today’s Path'),
      );
      await _settle(tester);
      await _save(tester, 'path-$locale');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));

      // Family tabs.
      state.unlockFamily();
      tester.view.physicalSize = const Size(1080, 5600);
      await tester.pumpWidget(_app(locale, FamilyScreen(state: state)));
      await _settle(tester);
      const tabs = {0: 'progress', 1: 'games', 2: 'profiles', 3: 'settings'};
      for (final MapEntry(key: index, value: name) in tabs.entries) {
        final bar = find.byType(NavigationDestination);
        if (bar.evaluate().length > index) {
          await tester.tap(bar.at(index));
        } else {
          await tester.tap(
            find.text(switch (name) {
              'progress' => locale == 'tr' ? 'Gelişim' : 'Progress',
              'games' => locale == 'tr' ? 'Oyunlar' : 'Games',
              'profiles' => locale == 'tr' ? 'Profiller' : 'Profiles',
              _ => locale == 'tr' ? 'Ayarlar' : 'Settings',
            }).last,
          );
        }
        await _settle(tester);
        await _save(tester, 'family-$name-$locale');
      }
      // Premium: the detailed progress charts.
      state.entitlement.lifetimeOwned = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(locale, FamilyScreen(state: state)));
      await _settle(tester);
      await _save(tester, 'family-progress-premium-$locale');
      await tester.pumpWidget(const SizedBox.shrink());
      state.lockFamily();
      state.dispose();
      await tester.pump(const Duration(minutes: 10));
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
