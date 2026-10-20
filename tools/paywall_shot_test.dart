// Run explicitly: flutter test tools/paywall_shot_test.dart --update-goldens
// Renders the upright Premium page (TR and EN) to artifacts/claude/r33/.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

class _NoGoogle implements FamilyAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

void main() {
  testWidgets('paywall shots', (tester) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
            .load();
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
        await s.createProfile('Ada', 'cat', {});
        s.unlockFamily();
        return s;
      }))!;
      state.locale = locale;
      final auth = FamilyAuth(
        backend: _NoGoogle(),
        parentAuthorized: () => state.familyUnlocked,
      );
      tester.view.devicePixelRatio = 2.6;
      tester.view.physicalSize = const Size(1080, 2400);
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SubscriptionScreen(state: state, auth: auth),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/r33/paywall-$locale.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      state.lockFamily();
      auth.dispose();
      state.dispose();
      await tester.pump(const Duration(minutes: 10));
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
