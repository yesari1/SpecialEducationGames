import 'dart:async';

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
import 'package:special_education_games/core/licensing/app_licenses.dart';
import 'package:special_education_games/features/family/credits_screen.dart';
import 'package:special_education_games/features/family/open_source_licenses_screen.dart';

const _fixturePackage = 'z-layout-license-fixture-0123456789-ABCDEFGHIJ';
const _fixtureText =
    'Permission is granted to use, copy, modify, and distribute this software '
    'for any purpose with or without fee, provided that the copyright notice '
    'and this permission notice appear in all copies. The software is provided '
    'as is, without warranty of any kind, express or implied, including but '
    'not limited to merchantability, fitness for a particular purpose and '
    'noninfringement. The authors shall not be liable for any claim, damages '
    'or other liability arising from, out of or in connection with the '
    'software or the use or other dealings in the software.';
const _fixtureUnicode =
    'Türkçe metin: İ ı Ş ş Ç ç, birleşik e\u0301 ve aile emojisi 👩‍👧‍👦.';
const _fixtureIndented =
    'Copyright notice and permission notice shall be included in all copies.';
const _fixtureCentered = 'All rights reserved by the original authors.';
const _fixtureLongUrl =
    'https://licenses.example.org/archive/very-long-license-reference/'
    'segment0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    'segment0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    'segment0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _fixtureParagraphs = <LicenseParagraph>[
  LicenseParagraph(_fixtureText, 0),
  LicenseParagraph(_fixtureUnicode, 0),
  LicenseParagraph(_fixtureIndented, 1),
  LicenseParagraph(_fixtureCentered, LicenseParagraph.centeredIndent),
  LicenseParagraph(_fixtureLongUrl, 0),
];

class _FixtureLicense extends LicenseEntry {
  const _FixtureLicense();

  @override
  Iterable<String> get packages => const [_fixturePackage];

  @override
  Iterable<LicenseParagraph> get paragraphs => _fixtureParagraphs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async {
    content = await ContentRepository.load();
    AppLicenses.registerNunito();
    LicenseRegistry.addLicense(
      () => Stream<LicenseEntry>.value(const _FixtureLicense()),
    );
  });

  Future<void> loadFonts(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(rootBundle.load(entry.value));
        await loader.load();
      }
    });
  }

  Future<AppState> makeState() async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('License test', 'cat', {});
    return state;
  }

  Future<void> mount(
    WidgetTester tester,
    Size size,
    double scale,
    AppState state,
    Widget screen,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'size=$size scale=$scale locale=${state.locale}',
    );
    for (final scrollable in tester.widgetList<Scrollable>(
      find.byType(Scrollable),
    )) {
      expect(scrollable.axisDirection, isNot(AxisDirection.down));
      expect(scrollable.axisDirection, isNot(AxisDirection.up));
    }
  }

  testWidgets(
    'open-source licenses stay horizontal and preserve complete registered text',
    (tester) async {
      final state = await makeState();
      await loadFonts(tester);

      state.locale = 'en';
      await mount(
        tester,
        const Size(800, 360),
        1.0,
        state,
        CreditsScreen(state: state),
      );
      expect(find.text('Credits and licenses'), findsOneWidget);
      expect(find.byTooltip('Open source software licenses'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('credits-open-source-licenses')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OpenSourceLicensesScreen), findsOneWidget);
      expect(find.byType(PageView), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          for (final scale in [1.0, 1.6, 2.0]) {
            await mount(
              tester,
              size,
              scale,
              state,
              OpenSourceLicensesScreen(state: state),
            );
            expect(
              find.text(
                locale == 'tr'
                    ? 'Açık kaynak yazılım lisansları'
                    : 'Open source software licenses',
              ),
              findsOneWidget,
            );
            expect(
              find.text(locale == 'tr' ? 'Önceki' : 'Previous'),
              findsWidgets,
            );
            expect(
              find.text(locale == 'tr' ? 'Sonraki' : 'Next'),
              findsWidgets,
            );
            expect(
              find.byKey(const ValueKey('license-package-pages')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('license-page-counter')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }

      state.locale = 'tr';
      await mount(
        tester,
        const Size(1280, 800),
        1.0,
        state,
        CreditsScreen(state: state),
      );
      expect(find.text('Kaynaklar ve lisanslar'), findsOneWidget);
      expect(find.textContaining('Sanatçı:'), findsWidgets);
      expect(find.byTooltip('Önceki kayıt'), findsOneWidget);
      expect(find.byTooltip('Sonraki kayıt'), findsOneWidget);
      expect(find.byTooltip('Önceki sayfa'), findsOneWidget);
      expect(find.byTooltip('Sonraki sayfa'), findsOneWidget);
      expect(tester.takeException(), isNull);

      state.locale = 'en';
      await mount(
        tester,
        const Size(800, 360),
        2.0,
        state,
        OpenSourceLicensesScreen(state: state),
      );
      final packageCounter = tester.widget<Text>(
        find.byKey(const ValueKey('license-package-counter')),
      );
      final packageCount = int.parse(packageCounter.data!.split(' / ').last);
      final reachedPackages = <String>{};
      var fixtureIndex = -1;
      for (var i = 0; i < packageCount; i++) {
        final name = tester
            .widgetList<Text>(find.byType(Text))
            .firstWhere(
              (text) =>
                  text.key is ValueKey<String> &&
                  (text.key! as ValueKey<String>).value.startsWith(
                    'license-package-name-',
                  ),
            );
        reachedPackages.add(name.data!);
        if (name.data == _fixturePackage) fixtureIndex = i;
        if (i + 1 < packageCount) {
          await tester.tap(find.byKey(const ValueKey('license-next-package')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      expect(reachedPackages, contains(_fixturePackage));
      expect(reachedPackages, contains('Nunito'));
      expect(reachedPackages, hasLength(packageCount));

      for (var i = fixtureIndex; i < packageCount - 1; i++) {
        await tester.tap(
          find.byKey(const ValueKey('license-previous-package')),
        );
        await tester.pumpAndSettle();
      }

      final fixtureTitle = find.text(_fixturePackage);
      expect(fixtureTitle, findsOneWidget);
      final fragments = <int, Map<int, String>>{};
      var sawCenteredParagraph = false;
      var sawIndentedParagraph = false;
      var sawLongUrlPan = false;
      while (true) {
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          final key = text.key;
          if (key is ValueKey<String> &&
              key.value.startsWith('license-fragment-')) {
            final parts = key.value.split('-');
            final paragraphIndex = int.parse(parts[parts.length - 2]);
            final fragmentIndex = int.parse(parts.last);
            fragments.putIfAbsent(paragraphIndex, () => {})[fragmentIndex] =
                text.data ?? '';
            if (paragraphIndex == 3) {
              expect(text.textAlign, TextAlign.center);
              sawCenteredParagraph = true;
            }
            if (paragraphIndex == 2) {
              final fragmentPadding = tester.widget<Padding>(
                find
                    .ancestor(
                      of: find.byKey(key),
                      matching: find.byType(Padding),
                    )
                    .first,
              );
              expect(fragmentPadding.padding.horizontal, greaterThan(0));
              sawIndentedParagraph = true;
            }
            if (paragraphIndex == 4) {
              expect(
                find.ancestor(
                  of: find.byKey(key),
                  matching: find.byType(SingleChildScrollView),
                ),
                findsOneWidget,
              );
              sawLongUrlPan = true;
            }
          }
        }
        final counter = tester.widget<Text>(
          find.byKey(const ValueKey('license-page-counter')),
        );
        final values = counter.data!.split(' / ').map(int.parse).toList();
        if (values[0] == values[1]) break;
        await tester.tap(find.byKey(const ValueKey('license-next-page')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      final reconstructed = <String>[];
      for (final paragraphIndex in fragments.keys.toList()..sort()) {
        final paragraphFragments = fragments[paragraphIndex]!.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        reconstructed.add(
          paragraphFragments.map((entry) => entry.value).join(),
        );
      }
      expect(reconstructed, _fixtureParagraphs.map((p) => p.text).toList());
      expect(sawCenteredParagraph, isTrue);
      expect(sawIndentedParagraph, isTrue);
      expect(sawLongUrlPan, isTrue);

      final beforeScaleChange = tester.widget<Text>(
        find.byKey(const ValueKey('license-page-counter')),
      );
      expect(beforeScaleChange.data, matches(RegExp(r'^\d+ / \d+$')));
      await mount(
        tester,
        const Size(800, 360),
        1.0,
        state,
        OpenSourceLicensesScreen(state: state),
      );
      final afterScaleChange = tester.widget<Text>(
        find.byKey(const ValueKey('license-page-counter')),
      );
      final pageValues = afterScaleChange.data!
          .split(' / ')
          .map(int.parse)
          .toList();
      expect(pageValues[0], inInclusiveRange(1, pageValues[1]));
      final textPageView = tester.widget<PageView>(
        find.byWidgetPredicate(
          (widget) =>
              widget is PageView &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'license-text-pages-',
              ),
        ),
      );
      expect(textPageView.controller!.page!.round(), pageValues[0] - 1);
      expect(tester.takeException(), isNull);
      state.dispose();
    },
  );
}
