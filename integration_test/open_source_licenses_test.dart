import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/licensing/app_licenses.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/open_source_licenses_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android displays real registry licenses in horizontal pages', (
    tester,
  ) async {
    // Integration tests do not invoke main(); register the app asset license
    // explicitly while retaining the genuine Android NOTICES.Z collection.
    AppLicenses.registerNunito();
    var bundledEntries = 0;
    // The integration-test binding intentionally skips ServicesBinding's
    // production license collector. Register the authentic generated Android
    // notices asset using the framework's public LicenseRegistry API/parser.
    LicenseRegistry.addLicense(() async* {
      final licenseBytes = await rootBundle.load('NOTICES.Z');
      final notices = utf8.decode(
        gzip.decode(licenseBytes.buffer.asUint8List()),
      );
      final separator = '\n${'-' * 80}\n';
      for (final text in notices.split(separator)) {
        final paragraphStart = text.indexOf('\n\n');
        final entry = paragraphStart >= 0
            ? LicenseEntryWithLineBreaks(
                text.substring(0, paragraphStart).split('\n'),
                text.substring(paragraphStart + 2),
              )
            : LicenseEntryWithLineBreaks(const <String>[], text);
        bundledEntries++;
        yield entry;
      }
    });

    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('License check', 'cat', {});
    state.unlockFamily();
    await tester.pumpWidget(EducationApp(state: state));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go('/family/credits');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('credits-open-source-licenses')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OpenSourceLicensesScreen), findsOneWidget);

    final licenseBuilder =
        tester
                .widgetList<Widget>(
                  find.descendant(
                    of: find.byType(OpenSourceLicensesScreen),
                    matching: find.byWidgetPredicate(
                      (widget) => widget is FutureBuilder,
                    ),
                  ),
                )
                .single
            as dynamic;
    final Future<dynamic> licenseFuture =
        licenseBuilder.future as Future<dynamic>;
    await tester.runAsync(
      () => licenseFuture.timeout(const Duration(seconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(
      bundledEntries,
      greaterThan(0),
      reason: 'NOTICES.Z must contain real legal entries.',
    );
    final nunitoParagraphs = <LicenseParagraph>[];
    await for (final entry in LicenseRegistry.licenses) {
      if (entry.packages.contains('Nunito')) {
        nunitoParagraphs.addAll(entry.paragraphs);
      }
    }
    expect(nunitoParagraphs, isNotEmpty);
    expect(
      nunitoParagraphs.map((paragraph) => paragraph.text).join('\n\n'),
      contains('Copyright 2014 The Nunito Project Authors'),
    );
    expect(
      nunitoParagraphs.map((paragraph) => paragraph.text).join('\n\n'),
      contains('SIL OPEN FONT LICENSE Version 1.1'),
    );
    if (find
        .byKey(const ValueKey('license-package-counter'))
        .evaluate()
        .isEmpty) {
      final loading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;
      final error = find.text('License information could not be loaded.');
      final empty = find.text('No registered licenses.');
      fail(
        'LicenseRegistry completed without package controls. '
        'loading=$loading errorUi=${error.evaluate().isNotEmpty} '
        'emptyUi=${empty.evaluate().isNotEmpty}',
      );
    }

    final packageCounter = tester.widget<Text>(
      find.byKey(const ValueKey('license-package-counter')),
    );
    final packageCount = int.parse(packageCounter.data!.split(' / ').last);
    expect(packageCount, greaterThanOrEqualTo(3));
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
      reason: 'At least one actual LicenseRegistry paragraph is rendered.',
    );

    final visitedPackages = <String>{};
    for (var i = 0; i < 4 && i < packageCount; i++) {
      final packageName = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (text) =>
                text.key is ValueKey<String> &&
                (text.key! as ValueKey<String>).value.startsWith(
                  'license-package-name-',
                ),
          )
          .data!;
      visitedPackages.add(packageName);
      if (i + 1 < 4 && i + 1 < packageCount) {
        await tester.tap(find.byKey(const ValueKey('license-next-package')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
    expect(visitedPackages, hasLength(packageCount < 4 ? packageCount : 4));

    for (final scrollable in tester.widgetList<Scrollable>(
      find.byType(Scrollable),
    )) {
      expect(scrollable.axisDirection, isNot(AxisDirection.down));
      expect(scrollable.axisDirection, isNot(AxisDirection.up));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
