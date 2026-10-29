// Run explicitly: flutter test tools/r62_signin_shot_test.dart --update-goldens
// The "check your e-mail" page after a sign-in link was sent, TR and EN,
// to artifacts/claude/r62/.
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
import 'package:special_education_games/features/onboarding/sign_in_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

class _Backend implements FamilyAuthBackend, FamilyEmailAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
  @override
  Future<FamilyAccount?> signInWithPassword(String e, String p) async => null;
  @override
  Future<void> sendSignInLink(String email) async {}
  @override
  bool isSignInLink(String link) => false;
  @override
  Future<FamilyAccount?> signInWithLink(String e, String l) async => null;
}

void main() {
  testWidgets('link sent page', (tester) async {
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
    tester.view.physicalSize = const Size(1080, 2400);
    for (final locale in ['tr', 'en']) {
      final state = (await tester.runAsync(() async {
        final s = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await s.load();
        return s;
      }))!;
      state.locale = locale;
      state.unlockFamily();
      final auth = FamilyAuth(
        backend: _Backend(),
        parentAuthorized: () => state.familyUnlocked,
      );
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SignInScreen(state: state, auth: auth),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('sign-in-email')),
        'aile@ornek.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sign-in-email-continue')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('../artifacts/claude/r62/link-sent-$locale.png'),
      );
      auth.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await tester.pump(const Duration(minutes: 10));
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
