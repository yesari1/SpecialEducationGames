import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/parent_gate.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadFonts(WidgetTester tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
  }

  Future<AppState> buildState(WidgetTester tester, {String? pin}) async {
    return (await tester.runAsync(() async {
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await state.load();
      if (pin != null) {
        state.unlockFamily();
        await state.setParentPin(pin);
        state.lockFamily();
      }
      return state;
    }))!;
  }

  void withLinux() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  }

  void testGate(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      withLinux();
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.platformDispatcher.clearLocaleTestValue();
      }
    });
  }

  void disposeState(WidgetTester tester, AppState state) {
    addTearDown(() async {
      // Cancel any production unlock timer during teardown, after real
      // assertions have run but before the AppState is disposed.
      if (state.familyUnlocked) state.lockFamily();
      await tester.runAsync(() async => state.dispose());
    });
  }

  Widget wrap(
    AppState state, {
    double scale = 1.0,
    void Function(bool)? onResult,
  }) {
    return MaterialApp(
      key: ValueKey<int>(identityHashCode(state)),
      theme: segTheme(),
      locale: Locale(state.locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final r = await showParentGate(context, state);
                onResult?.call(r);
              },
              child: const Text('Open gate'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openGate(
    WidgetTester tester,
    AppState state,
    double scale,
  ) async {
    // Keep the platform locale opposite the saved profile locale to prove the
    // gate follows the active profile override rather than the device.
    tester.platformDispatcher.localeTestValue = Locale(
      state.locale == 'tr' ? 'en' : 'tr',
    );
    await tester.pumpWidget(wrap(state, scale: scale));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open gate'));
    await tester.pumpAndSettle();
  }

  Future<void> tapKeys(WidgetTester tester, List<String> keys) async {
    for (final k in keys) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
  }

  double buttonExtent(WidgetTester tester, String key) {
    final btn = find.ancestor(
      of: find.text(key),
      matching: find.byType(FilledButton),
      matchRoot: false,
    );
    expect(btn, findsWidgets, reason: 'no FilledButton ancestor for $key');
    final s = tester.getSize(btn.first);
    return s.shortestSide;
  }

  testGate(
    'Matrix: no vertical Scrollables, keypad and cancel within viewport',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      await loadFonts(tester);

      for (final language in ['tr', 'en']) {
        for (final pin in [null, '2468']) {
          for (final size in [const Size(800, 360), const Size(1280, 800)]) {
            for (final scale in [1.0, 1.6, 2.0]) {
              final state = await buildState(tester, pin: pin);
              state.locale = language;
              disposeState(tester, state);
              tester.view.physicalSize = size;
              await openGate(tester, state, scale);

              final l10n = lookupAppLocalizations(Locale(language));
              expect(find.text(l10n.parentGateTitle), findsOneWidget);
              expect(
                find.text(
                  pin == null
                      ? l10n.parentGateContinuePrompt
                      : l10n.parentGateEnterPin,
                ),
                findsOneWidget,
              );
              final copy = <Finder>[
                find.text(l10n.parentGateTitle),
                find.text(
                  pin == null
                      ? l10n.parentGateContinuePrompt
                      : l10n.parentGateEnterPin,
                ),
                find.text(l10n.parentGateCancel),
                if (pin != null) find.text(l10n.parentGateForgotPin),
              ];
              if (pin != null) {
                expect(find.text(l10n.parentGateForgotPin), findsOneWidget);
              }
              for (final text in copy) {
                final rect = tester.getRect(text);
                expect(rect.left, greaterThanOrEqualTo(0));
                expect(rect.right, lessThanOrEqualTo(size.width));
                expect(rect.top, greaterThanOrEqualTo(0));
                expect(rect.bottom, lessThanOrEqualTo(size.height));
              }
              final vertical = tester
                  .widgetList<Scrollable>(find.byType(Scrollable))
                  .where(
                    (s) =>
                        s.axisDirection == AxisDirection.down ||
                        s.axisDirection == AxisDirection.up,
                  );
              expect(
                vertical,
                isEmpty,
                reason: '$language $pin $size $scale no vertical scroll',
              );

              final cancel = find.text(l10n.parentGateCancel);
              expect(
                cancel,
                findsOneWidget,
                reason: '$language $pin $size $scale cancel',
              );
              final cancelRect = tester.getRect(cancel);
              expect(cancelRect.left, greaterThanOrEqualTo(0));
              expect(cancelRect.right, lessThanOrEqualTo(size.width));
              expect(cancelRect.top, greaterThanOrEqualTo(0));
              expect(cancelRect.bottom, lessThanOrEqualTo(size.height));

              for (final k in ['1', '5', '9', '\u2713']) {
                final f = find.text(k);
                expect(
                  f,
                  findsOneWidget,
                  reason: '$k $language $pin $size $scale',
                );
                final r = tester.getRect(f);
                expect(r.left, greaterThanOrEqualTo(0));
                expect(r.right, lessThanOrEqualTo(size.width));
                expect(r.top, greaterThanOrEqualTo(0));
                expect(r.bottom, lessThanOrEqualTo(size.height));
                expect(
                  buttonExtent(tester, k),
                  greaterThanOrEqualTo(48),
                  reason: '$k tap target $language $pin $size $scale',
                );
              }

              await tester.tap(cancel);
              await tester.pumpAndSettle();
              expect(find.text('Open gate'), findsOneWidget);
              expect(
                tester.takeException(),
                isNull,
                reason: '$language $pin $size $scale localized gate layout',
              );
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            }
          }
        }
      }
    },
  );

  testGate('Math success parses displayed operands', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await loadFonts(tester);
    final state = await buildState(tester);
    state.locale = 'tr';
    disposeState(tester, state);

    await openGate(tester, state, 1.0);
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    final mathText = textWidgets
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.contains('\u00d7'), orElse: () => '');
    expect(mathText.isNotEmpty, isTrue);
    final m = RegExp('(\\d+)\\s*\u00d7\\s*(\\d+)').firstMatch(mathText)!;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final product = (a * b).toString();
    await tapKeys(tester, product.split(''));
    await tester.tap(find.text('\u2713'));
    await tester.pumpAndSettle();
    expect(find.text('Open gate'), findsOneWidget);
    expect(state.familyUnlocked, isTrue);
    state.lockFamily();
  });

  testGate('Wrong math answer retry is localized for profile locale', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await loadFonts(tester);
    final state = await buildState(tester);
    disposeState(tester, state);

    for (final language in ['tr', 'en']) {
      state.locale = language;
      final l10n = lookupAppLocalizations(Locale(language));
      await openGate(tester, state, 1.0);
      String mathText() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((s) => s.contains('\u00d7'), orElse: () => '');
      final before = mathText();
      expect(before.isNotEmpty, isTrue);
      expect(before, endsWith('?'));
      await tapKeys(tester, ['0', '0']);
      await tester.tap(find.text('\u2713'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.parentGateWrongMath), findsOneWidget);
      expect(
        mathText(),
        endsWith('?'),
        reason: 'answer display must reset to ? after wrong answer',
      );
      expect(state.familyUnlocked, isFalse);
      await tester.tap(find.text(l10n.parentGateCancel));
      await tester.pumpAndSettle();
      expect(find.text('Open gate'), findsOneWidget);
    }
  });

  testGate('4 digit PIN success unlocks and closes', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await loadFonts(tester);
    final state = await buildState(tester, pin: '2468');
    disposeState(tester, state);
    expect(
      state.familyUnlocked,
      isFalse,
      reason: 'buildState must not leave family unlocked',
    );

    for (final language in ['tr', 'en']) {
      state.locale = language;
      final l10n = lookupAppLocalizations(Locale(language));
      await openGate(tester, state, 1.0);
      expect(state.familyUnlocked, isFalse);
      await tapKeys(tester, ['0', '0', '0', '0']);
      await tester.tap(find.text('\u2713'));
      await tester.pumpAndSettle();
      expect(state.familyUnlocked, isFalse);
      expect(find.text(l10n.parentGateWrongPin), findsOneWidget);

      await tapKeys(tester, ['2', '4', '6', '8']);
      await tester.tap(find.text('\u2713'));
      await tester.pumpAndSettle();
      expect(find.text('Open gate'), findsOneWidget);
      expect(state.familyUnlocked, isTrue);
      state.lockFamily();
    }
  });

  testGate('Forgot PIN fallback uses multiplication; cancel returns false', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    await loadFonts(tester);
    final state = await buildState(tester, pin: '1357');
    disposeState(tester, state);

    expect(
      state.familyUnlocked,
      isFalse,
      reason: 'buildState must not leave family unlocked',
    );

    for (final language in ['tr', 'en']) {
      state.locale = language;
      final l10n = lookupAppLocalizations(Locale(language));
      await openGate(tester, state, 1.0);
      expect(state.familyUnlocked, isFalse);
      final fallback = find.text(l10n.parentGateForgotPin);
      expect(fallback, findsOneWidget);
      await tester.tap(fallback);
      await tester.pumpAndSettle();
      expect(find.text(l10n.parentGateContinuePrompt), findsOneWidget);
      final mathText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((s) => s.contains('\u00d7'), orElse: () => '');
      expect(mathText.isNotEmpty, isTrue);
      final m = RegExp('(\\d+)\\s*\u00d7\\s*(\\d+)').firstMatch(mathText)!;
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      await tapKeys(tester, (a * b).toString().split(''));
      await tester.tap(find.text('\u2713'));
      await tester.pumpAndSettle();
      expect(state.familyUnlocked, isTrue);

      state.lockFamily();
      bool? result;
      await tester.pumpWidget(wrap(state, onResult: (r) => result = r));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open gate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.parentGateCancel));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(state.familyUnlocked, isFalse);
    }
  });
}
