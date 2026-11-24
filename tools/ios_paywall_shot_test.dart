// Run explicitly: flutter test tools/ios_paywall_shot_test.dart --update-goldens
// Paywall with App Store prices, for the in-app purchase review screenshot.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/entitlement/billing_repository.dart';
import 'package:special_education_games/features/family/paywall_view.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  testWidgets('paywall shot', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
            .load();
      }
    });
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(2064, 2752);
    final state = (await tester.runAsync(() async {
      final s = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      await s.createProfile('Ella', 'cat', {});
      s.audio.enabled = false;
      s.sound = false;
      return s;
    }))!;
    state.locale = 'en';
    BillingPlan plan(String id, String store, String price, double raw, String period) =>
        BillingPlan(
          ProductDetails(
            id: store,
            title: 'Premium',
            description: '',
            price: price,
            rawPrice: raw,
            currencyCode: 'TRY',
            currencySymbol: '₺',
          ),
          id,
          price,
          period,
          null,
          false,
          priceMicros: (raw * 1000000).round(),
        );
    state.billing.plans = [
      plan('monthly', BillingProducts.appleMonthly, '₺59,99', 59.99, 'P1M'),
      plan('yearly', BillingProducts.appleYearly, '₺499,99', 499.99, 'P1Y'),
    ];
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: segTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SafeArea(child: PaywallView(state: state, onDone: () {}))),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await _save(tester, 'artifacts/claude/ios-shots/iap-paywall-en.png', 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _save(WidgetTester tester, String path, double ratio) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
