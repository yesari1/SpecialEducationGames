// Run explicitly: flutter test tools/motion_preview_shot_test.dart
// Records frames of the moving onboarding and Premium page (Turkish, two
// phone sizes) to artifacts/claude/motion-preview/<name>/; join them into a
// video with ffmpeg (see the note printed at the end).
import 'dart:io';
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

const _out = 'artifacts/claude/motion-preview';
const _frame = Duration(milliseconds: 40); // 25 fps

void main() {
  for (final phone in const [
    (name: 'iphone-se', size: Size(750, 1334), ratio: 2.0),
    (name: 'iphone-15-pro-max', size: Size(1290, 2796), ratio: 3.0),
  ]) {
    testWidgets('motion preview ${phone.name}', (tester) async {
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
      final product = _product();
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
      ];
      final auth = FamilyAuth(
        backend: _NoGoogle(),
        parentAuthorized: () => state.familyUnlocked,
      );
      tester.view.devicePixelRatio = phone.ratio;
      tester.view.physicalSize = phone.size;
      final dir = Directory('$_out/${phone.name}');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      var frame = 0;

      Future<void> capture() async {
        final boundary =
            tester.renderObject(find.byType(RepaintBoundary).first)
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${dir.path}/${(frame++).toString().padLeft(5, '0')}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      /// Lets pictures load (real time), without moving the clock much.
      Future<void> load() async {
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 120)),
          );
          await tester.pump();
        }
      }

      Future<void> record(Duration length) async {
        for (var t = Duration.zero; t < length; t += _frame) {
          await tester.pump(_frame);
          await capture();
        }
      }

      Future<void> tap(Finder f) async {
        await tester.tap(f);
        await tester.pump();
      }

      await tester.pumpWidget(
        RepaintBoundary(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: segTheme(),
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: OnboardingScreen(state: state, auth: auth),
          ),
        ),
      );
      await load();
      await record(const Duration(milliseconds: 4200));
      await tap(find.byKey(const ValueKey('welcome-start')));
      await load();
      await record(const Duration(milliseconds: 1200));
      await tester.enterText(
        find.byKey(const ValueKey('nickname-field')),
        'Ada',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(find.byKey(const ValueKey('age-4')));
      await record(const Duration(milliseconds: 600));
      await tap(find.byKey(const ValueKey('onboarding-continue')));
      await load();
      await record(const Duration(milliseconds: 1400));
      await tap(find.byKey(const ValueKey('survey-option-0')));
      await record(const Duration(milliseconds: 600));
      await tap(find.byKey(const ValueKey('onboarding-continue')));
      // Saving the profile runs on the database.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      await load();
      // The Premium page: three moments, a little more than one loop.
      await record(const Duration(milliseconds: 14400));
      await tap(find.byKey(const ValueKey('paywall-continue-free')));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      await record(const Duration(milliseconds: 1600));

      await tester.pumpWidget(const SizedBox.shrink());
      state.lockFamily();
      auth.dispose();
      state.dispose();
      await tester.pump(const Duration(minutes: 10));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      // ignore: avoid_print
      print(
        'ffmpeg -framerate 25 -i ${dir.path}/%05d.png '
        '-pix_fmt yuv420p ${dir.path}.mp4',
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }
}
