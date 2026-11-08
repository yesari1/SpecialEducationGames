// Run explicitly: flutter test tools/onboarding_flow_shot_test.dart --update-goldens
// Renders the first-run setup (welcome, child, question, offer, daily goal)
// in Turkish on a phone, to artifacts/claude/onboarding-flow/.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  testWidgets('onboarding flow', (tester) async {
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
    final state = (await tester.runAsync(() async {
      final s = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      return s;
    }))!;
    state.locale = 'tr';
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: segTheme(),
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: OnboardingScreen(state: state),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)),
        );
        await tester.pump(const Duration(milliseconds: 400));
      }
    }

    Future<void> shot(String name) async {
      await settle();
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/onboarding-flow/$name.png'),
      );
    }

    Future<void> tap(String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
    }

    await shot('1-karsilama');
    await tap('welcome-start');
    await settle();
    await tester.enterText(find.byKey(const ValueKey('nickname-field')), 'Ada');
    await tap('age-4');
    await shot('2-cocuk');
    await tap('onboarding-continue');
    await settle();
    await tap('survey-option-1');
    await shot('3-soru');
    await tap('onboarding-continue');
    await shot('4-premium-teklifi');
    await tester.tap(find.text('Ücretsiz sürümle devam et'));
    await shot('5-gunluk-hedef');
    state.lockFamily();
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
    await tester.pump(const Duration(minutes: 10));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
