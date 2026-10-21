// Run explicitly:
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
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

const _shot = String.fromEnvironment('SHOT', defaultValue: 'after');

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
  matchesGoldenFile('../artifacts/claude/r41/$_shot-$name.png'),
);

void main() {
  testWidgets('r41 shots', (tester) async {
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
        await s.createProfile(locale == 'tr' ? 'Deniz' : 'Ella', 'cat', {});
        return s;
      }))!;
      state.locale = locale;
      tester.view.devicePixelRatio = 2.625;

      // Theme page with locked games, then a tap on a locked one.
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pumpWidget(
        _app(locale, ThemeScreen(state: state, themeId: 'animals')),
      );
      await _settle(tester);
      await _save(tester, 'theme-$locale');
      final locked = find.byWidgetPredicate(
        (w) => w is ThemeGameCard && w.locked,
      );
      if (locked.evaluate().isNotEmpty) {
        await tester.tap(locked.first, warnIfMissed: false);
        await _settle(tester);
        await _save(tester, 'locked-tap-$locale');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));

      // Family progress of a free account (tall, to see the whole page).
      state.unlockFamily();
      tester.view.physicalSize = const Size(1080, 5200);
      await tester.pumpWidget(_app(locale, FamilyScreen(state: state)));
      await _settle(tester);
      await _save(tester, 'family-$locale');
      await tester.pumpWidget(const SizedBox.shrink());

      // Paywall, yearly then one-time.
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
      tester.view.physicalSize = const Size(1080, 2400);
      await tester.pumpWidget(
        _app(locale, SubscriptionScreen(state: state, auth: auth)),
      );
      await _settle(tester);
      await _save(tester, 'paywall-yearly-$locale');
      await tester.tap(find.byKey(const ValueKey('paywall-option-lifetime')));
      await _settle(tester);
      await _save(tester, 'paywall-lifetime-$locale');

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
