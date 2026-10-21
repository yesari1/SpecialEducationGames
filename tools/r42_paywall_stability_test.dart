// Run explicitly:
//   flutter test tools/r42_paywall_stability_test.dart --update-goldens
// Renders the paywall (TR and EN) on a 1080×2340 and a 720×1600 phone for
// each plan, with the trial unused and used, and with the parent area
// locked (to artifacts/claude/r42/). Then checks that nothing above the
// footnote moves between the states of one screen and that the page fits
// without scaling down.
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

GooglePlayProductDetails _product() =>
    GooglePlayProductDetails.fromProductDetails(
      const ProductDetailsWrapper(
        description: 'Premium',
        name: 'Premium',
        productId: 'premium_lifetime',
        productType: ProductType.inapp,
        title: 'Premium',
        oneTimePurchaseOfferDetails: OneTimePurchaseOfferDetailsWrapper(
          formattedPrice: 'TRY 799.99',
          priceAmountMicros: 799990000,
          priceCurrencyCode: 'TRY',
        ),
      ),
    ).single;

void main() {
  testWidgets(
    'paywall does not move between states',
    (tester) async {
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
      const phones = {
        '1080x2340': (Size(1080, 2340), 2.625),
        '720x1600': (Size(720, 1600), 2.0),
      };
      for (final locale in ['tr', 'en']) {
        for (final MapEntry(key: phone, value: (size, ratio))
            in phones.entries) {
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
          // Prices as Play shows them on an English phone (the longest form).
          state.billing.plans = [
            BillingPlan(
              product,
              'monthly',
              'TRY 59.99',
              'P1M',
              null,
              false,
              priceMicros: 59990000,
            ),
            BillingPlan(
              product,
              'yearly',
              'TRY 499.99',
              'P1Y',
              null,
              false,
              priceMicros: 499990000,
            ),
            BillingPlan(
              product,
              'lifetime',
              'TRY 799.99',
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
          tester.view.devicePixelRatio = ratio;
          tester.view.physicalSize = size;
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
          Future<void> settle() async {
            for (var i = 0; i < 4; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 60)),
              );
              await tester.pump(const Duration(milliseconds: 300));
            }
          }

          Rect rectOf(String key) => tester.getRect(find.byKey(ValueKey(key)));
          final shots = <String, ui.Image>{};
          Future<void> capture(String name) async {
            await settle();
            await expectLater(
              find.byType(RepaintBoundary).first,
              matchesGoldenFile(
                '../artifacts/claude/r42/$phone-$locale-$name.png',
              ),
            );
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byType(RepaintBoundary).first,
            );
            shots[name] = (await tester.runAsync(
              () => boundary.toImage(pixelRatio: 1),
            ))!;
          }

          final reference = <String, Rect>{};
          void same(String state) {
            for (final key in [
              'paywall-headline',
              'paywall-option-yearly',
              'paywall-option-lifetime',
              'paywall-continue',
              'paywall-restore',
            ]) {
              final rect = rectOf(key);
              reference.putIfAbsent(key, () => rect);
              expect(
                rect,
                reference[key],
                reason: '$phone $locale $state $key',
              );
            }
            expect(
              rectOf('paywall-restore').bottom,
              lessThanOrEqualTo(size.height / ratio),
            );
          }

          await capture('yearly');
          same('yearly');
          // The page fits a phone without being scaled down.
          final fitted = tester.widget<FittedBox>(find.byType(FittedBox).first);
          expect(fitted.fit, BoxFit.scaleDown);
          for (final plan in ['monthly', 'lifetime', 'yearly']) {
            await tester.tap(find.byKey(ValueKey('paywall-option-$plan')));
            await capture(plan);
            same(plan);
          }
          // Trial used: purchase labels (one more status line, so a new
        // reference; within this state nothing may move).
        reference.clear();
          await tester.runAsync(
            () => state.entitlement.setTrial(
              'u1',
              DateTime.now().subtract(const Duration(days: 30)),
            ),
          );
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          state.billing.notifyListeners();
          for (final plan in ['yearly', 'monthly', 'lifetime']) {
            await tester.tap(find.byKey(ValueKey('paywall-option-$plan')));
            await capture('trial-used-$plan');
            same('trial-used-$plan');
          }
          // Parent area timed out: the button stays enabled (asks the gate).
          state.lockFamily();
          await capture('locked');
          same('locked');
          final button = find.descendant(
            of: find.byKey(const ValueKey('paywall-continue')),
            matching: find.byType(ElevatedButton),
          );
          expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);

          await tester.pumpWidget(const SizedBox.shrink());
          auth.dispose();
          state.dispose();
          await tester.pump(const Duration(minutes: 10));
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
