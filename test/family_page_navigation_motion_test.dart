import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/credits_screen.dart';
import 'package:special_education_games/features/family/family_account_card.dart';
import 'package:special_education_games/features/family/family_account_screen.dart';
import 'package:special_education_games/features/family/open_source_licenses_screen.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';

const _firstPackage = 'a-motion-fixture';
const _lastPackage = 'z-motion-fixture';

class _MotionLicense extends LicenseEntry {
  const _MotionLicense(this.package);
  final String package;

  @override
  Iterable<String> get packages => [package];

  @override
  Iterable<LicenseParagraph> get paragraphs => [
    LicenseParagraph(
      List.filled(
        500,
        'This fixture paragraph verifies that complete license text remains readable across horizontal pages.',
      ).join(' '),
      0,
    ),
  ];
}

class _AuthBackend implements FamilyAuthBackend {
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
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async {
    content = await ContentRepository.load();
    for (final package in [_firstPackage, _lastPackage]) {
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(_MotionLicense(package)),
      );
    }
  });

  Future<AppState> makeState() async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Motion test', 'cat', {});
    state.locale = 'en';
    return state;
  }

  Future<void> mount(
    WidgetTester tester,
    AppState state,
    Widget screen, {
    required bool disableAnimations,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: const TextScaler.linear(1.6),
          ),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.takeException(),
      isNull,
      reason: screen.runtimeType.toString(),
    );
  }

  Future<PageController> pageController(
    WidgetTester tester,
    Finder view,
  ) async => tester.widget<PageView>(view).controller!;

  Future<void> verifyCredits(
    WidgetTester tester,
    AppState state, {
    required bool disableAnimations,
    required bool animated,
  }) async {
    await mount(
      tester,
      state,
      CreditsScreen(state: state),
      disableAnimations: disableAnimations,
    );
    final view = find.byKey(const ValueKey('credits-detail-pages'));
    final controller = await pageController(tester, view);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('credits-record-counter')))
          .textSpan!
          .toPlainText(),
      matches(RegExp(r'1 / \d+\s+·\s+1 / [2-9]\d*')),
    );
    await tester.tap(find.byKey(const ValueKey('credits-next-detail')));
    if (animated) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.page!, greaterThan(0));
      expect(controller.page!, lessThan(1));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    expect(controller.page!.round(), 1);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('credits-record-counter')))
          .textSpan!
          .toPlainText(),
      matches(RegExp(r'1 / \d+\s+·\s+2 / \d+')),
    );
    expect(
      find.byKey(const ValueKey('credits-field-0-license')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }

  Future<void> verifyLicenses(
    WidgetTester tester,
    AppState state, {
    required bool disableAnimations,
    required bool animated,
  }) async {
    await mount(
      tester,
      state,
      OpenSourceLicensesScreen(state: state),
      disableAnimations: disableAnimations,
    );
    final packagesView = find.byKey(const ValueKey('license-package-pages'));
    final packages = await pageController(tester, packagesView);
    expect(find.text(_firstPackage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('license-next-package')));
    if (animated) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(packages.page!, greaterThan(0));
      expect(packages.page!, lessThan(1));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    expect(packages.page!.round(), 1);
    expect(find.text(_lastPackage), findsOneWidget);

    final detailView = find.byWidgetPredicate(
      (widget) =>
          widget is PageView &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'license-text-pages-',
          ),
    );
    final details = await pageController(tester, detailView);
    final detailCounter = tester.widget<Text>(
      find.byKey(const ValueKey('license-page-counter')),
    );
    expect(detailCounter.data!.split(' / ').last, isNot('1'));
    await tester.tap(find.byKey(const ValueKey('license-next-page')));
    if (animated) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(details.page!, greaterThan(0));
      expect(details.page!, lessThan(1));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    expect(details.page!.round(), 1);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('license-page-counter')))
          .data,
      matches(RegExp(r'^2 / \d+$')),
    );
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .any(
            (text) =>
                text.key is ValueKey<String> &&
                (text.key! as ValueKey<String>).value.startsWith(
                  'license-fragment-',
                ) &&
                (text.data?.trim().isNotEmpty ?? false),
          ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }

  Future<void> verifyAccount(
    WidgetTester tester,
    AppState state, {
    required bool disableAnimations,
    required bool animated,
  }) async {
    state.unlockFamily();
    final auth = FamilyAuth(
      backend: _AuthBackend(),
      parentAuthorized: () => state.familyUnlocked,
    );
    await mount(
      tester,
      state,
      FamilyAccountScreen(state: state, auth: auth),
      disableAnimations: disableAnimations,
    );
    final tabs = tester.widget<TabBarView>(find.byType(TabBarView)).controller!;
    Finder appBarIcon(IconData icon) => find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == icon,
    );
    await tester.tap(appBarIcon(Icons.sync_rounded));
    if (animated) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tabs.animation!.value, greaterThan(0));
      expect(tabs.animation!.value, lessThan(1));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    expect(tabs.index, 1);
    await tester.tap(appBarIcon(Icons.account_circle_outlined));
    if (animated) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tabs.animation!.value, greaterThan(0));
      expect(tabs.animation!.value, lessThan(1));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    expect(tabs.index, 0);
    await tester.pumpWidget(const SizedBox());
    await mount(
      tester,
      state,
      FamilyAccountScreen(state: state, auth: auth),
      disableAnimations: disableAnimations,
    );
    final card = find.byType(FamilyAccountCard);
    expect(
      find.descendant(of: card, matching: find.text('Family account')),
      findsOneWidget,
    );
    final view = find.descendant(of: card, matching: find.byType(PageView));
    final controller = await pageController(tester, view);
    await tester.tap(find.byTooltip('Next page'));
    if (animated) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.page!, greaterThan(0));
      expect(controller.page!, lessThan(1));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    expect(controller.page!.round(), 1);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(
      find.textContaining('Detailed progress stays on this device'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    state.lockFamily();
  }

  Future<void> verifySubscription(
    WidgetTester tester,
    AppState state, {
    required bool disableAnimations,
    required bool animated,
  }) async {
    await mount(
      tester,
      state,
      SubscriptionScreen(state: state),
      disableAnimations: disableAnimations,
    );
    final view = find.byType(PageView);
    final controller = await pageController(tester, view);
    List<String?> visibleText() => tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .where((text) => text != null && !RegExp(r'^\d+ / \d+$').hasMatch(text))
        .toList();

    final before = visibleText();
    await tester.tap(find.byTooltip('Next page'));
    if (animated) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.page!, greaterThan(0));
      expect(controller.page!, lessThan(1));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    expect(controller.page!.round(), 1);
    expect(visibleText(), isNot(equals(before)));
    expect(visibleText().any((text) => text!.trim().isNotEmpty), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets(
    'AppState reducedMotion and MediaQuery disableAnimations jump every pager while normal motion animates',
    (tester) async {
      final state = await makeState();

      Future<void> verifyAll({
        required bool disableAnimations,
        required bool animated,
      }) async {
        await verifyCredits(
          tester,
          state,
          disableAnimations: disableAnimations,
          animated: animated,
        );
        await verifyLicenses(
          tester,
          state,
          disableAnimations: disableAnimations,
          animated: animated,
        );
        await verifyAccount(
          tester,
          state,
          disableAnimations: disableAnimations,
          animated: animated,
        );
        await verifySubscription(
          tester,
          state,
          disableAnimations: disableAnimations,
          animated: animated,
        );
      }

      await state.setting('reducedMotion', 'true');
      await verifyAll(disableAnimations: false, animated: false);

      await state.setting('reducedMotion', 'false');
      expect(state.reducedMotion, isFalse);
      await verifyAll(disableAnimations: true, animated: false);

      await verifyAll(disableAnimations: false, animated: true);
      await tester.pumpWidget(const SizedBox());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      state.dispose();
    },
  );
}
