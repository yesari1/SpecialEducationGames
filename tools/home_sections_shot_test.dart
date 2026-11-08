// Run explicitly: flutter test tools/home_sections_shot_test.dart --update-goldens
// Renders the three sections of the child home, phone landscape, into
// artifacts/claude/home-sections/.
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

void main() {
  testWidgets('home sections', (tester) async {
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
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(2424, 1080);
    for (final tab in HomeTab.values) {
      for (final offset in tab == HomeTab.learn ? [0.0, 420.0] : [0.0]) {
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
        state.homeTab = tab;
        state.homeLearnOffset = offset;
        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: segTheme(),
              locale: const Locale('tr'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: HomeScreen(state: state),
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
          matchesGoldenFile(
            '../artifacts/claude/home-sections/1-${tab.name}-${offset.toInt()}.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
        await tester.pump(const Duration(seconds: 1));
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
