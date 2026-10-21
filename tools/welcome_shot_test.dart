// Run explicitly: flutter test tools/welcome_shot_test.dart --update-goldens
// Renders the onboarding welcome page (TR and EN, phone portrait) to
// artifacts/claude/r38/ (WELCOME_SHOT_PREFIX picks before/after).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/entitlement/billing_repository.dart';
import 'package:special_education_games/features/onboarding/onboarding_screen.dart';
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

void main() {
  testWidgets('paywall shots', (tester) async {
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
    final product = _product();
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
      state.billing.plans = [
        BillingPlan(
          product,
          'monthly',
          '₺59,99',
          'P1M',
          null,
          false,
          priceMicros: 59990000,
        ),
        BillingPlan(
          product,
          'yearly',
          '₺499,99',
          'P1Y',
          null,
          false,
          priceMicros: 499990000,
        ),
        BillingPlan(
          product,
          'lifetime',
          '₺799,99',
          '',
          null,
          false,
          priceMicros: 799990000,
        ),
      ];
      final auth = FamilyAuth(
        backend: _NoGoogle(),
        parentAuthorized: () => state.familyUnlocked,
      );
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: OnboardingScreen(state: state, auth: auth),
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
        matchesGoldenFile(
          '../artifacts/claude/r38/${const String.fromEnvironment('WELCOME_SHOT_PREFIX', defaultValue: 'after')}-welcome-$locale.png',
        ),
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
