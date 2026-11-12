// Run explicitly: flutter test tools/fix_nov12_shot_test.dart --update-goldens
// Renders the child home (three sections) and a few theme pages on two phone
// sizes into artifacts/claude/fix-nov12/.
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
import 'package:special_education_games/l10n/app_localizations.dart';

const _sizes = {
  'p9a': (Size(2424, 1080), 2.625),
  'small': (Size(1480, 720), 2.0),
};

void main() {
  testWidgets('home and themes', (tester) async {
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
    Future<void> shot(String name, Widget Function(AppState) page) async {
      final state = (await tester.runAsync(() async {
        final s = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await s.load();
        await s.createProfile('Deniz', 'cat', {});
        return s;
      }))!;
      state.locale = 'tr';
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: page(state),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/fix-nov12/$name.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump(const Duration(seconds: 1));
    }

    for (final MapEntry(key: device, value: (size, ratio)) in _sizes.entries) {
      tester.view.devicePixelRatio = ratio;
      tester.view.physicalSize = size;
      for (final tab in HomeTab.values) {
        for (final offset in tab == HomeTab.learn ? [0.0, 300.0] : [0.0]) {
          await shot('$device-home-${tab.name}-${offset.toInt()}', (s) {
            s.homeTab = tab;
            s.homeLearnOffset = offset;
            return HomeScreen(state: s);
          });
        }
      }
      for (final theme in ['animals', 'clothes', 'jobs']) {
        await shot(
          '$device-theme-$theme',
          (s) => ThemeScreen(state: s, themeId: theme),
        );
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
