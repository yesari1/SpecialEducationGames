// Run explicitly (R49):
//   flutter test tools/r41_shot_test.dart --update-goldens --dart-define=SHOT=before
// Renders the R41 screens (TR and EN) to artifacts/claude/r41/<SHOT>-*.png:
// theme page with locked games, the locked-game notice, the family progress
// page of a free account, and the paywall with yearly and one-time selected.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/entitlement/billing_repository.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
import 'package:special_education_games/features/family/feedback_screen.dart';
import 'package:special_education_games/features/family/account_gate_screen.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/family/family_account_screen.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

const _shot = String.fromEnvironment('SHOT', defaultValue: 'after');

class _NoGoogle implements FamilyAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => const FamilyAccount(
    'p1',
    email: 'yunus@example.com',
    name: 'Yunus Esari',
  );
  @override
  Future<FamilyAccount?> signIn() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

GooglePlayProductDetails _product() =>
    GooglePlayProductDetails.fromProductDetails(
      const ProductDetailsWrapper(
        description: 'Premium',
        name: 'Premium',
        productId: 'premium_lifetime',
        productType: ProductType.inapp,
        title: 'Premium',
        oneTimePurchaseOfferDetails: OneTimePurchaseOfferDetailsWrapper(
          formattedPrice: '₺799,99',
          priceAmountMicros: 799990000,
          priceCurrencyCode: 'TRY',
        ),
      ),
    ).single;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
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
  matchesGoldenFile('../artifacts/claude/r59/$_shot-$name.png'),
);

void main() {
  testWidgets('r59 shots', (tester) async {
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
    _product();
    for (final locale in ['tr']) {
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
      state.locale = locale;
      final auth = FamilyAuth(
        backend: _NoGoogle(),
        parentAuthorized: () => state.familyUnlocked,
      );
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      await tester.pumpWidget(_app(locale, const AccountLoadingScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await _save(tester, 'loading-$locale');
      state.setAccount(null, ready: true);
      await tester.pumpWidget(
        _app(locale, AccountGateScreen(state: state, auth: auth)),
      );
      await _settle(tester);
      await _save(tester, 'gate-$locale');
      await tester.runAsync(auth.restoreAtStart);
      state.unlockFamily();
      await tester.runAsync(
        () => state.entitlement.setGrant('p1', premium: true, endTrial: false),
      );
      await tester.pumpWidget(
        _app(locale, FamilyScreen(state: state, auth: auth)),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('family-nav-2')));
      await _settle(tester);
      await _save(tester, 'profiles-$locale');
      await tester.pumpWidget(
        _app(locale, FamilyAccountScreen(state: state, auth: auth)),
      );
      await _settle(tester);
      await _save(tester, 'account-$locale');
      await tester.pumpWidget(_app(locale, FeedbackScreen(state: state)));
      await _settle(tester);
      await _save(tester, 'feedback-$locale');
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
      state.dispose();
      await tester.pump(const Duration(minutes: 10));
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
