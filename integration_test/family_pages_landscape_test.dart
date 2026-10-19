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
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/licensing/app_licenses.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/credits_screen.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/family/open_source_licenses_screen.dart';

const _minimumTapTargetExtent = 48 - 1e-6;

class _OfflineAuthBackend implements FamilyAuthBackend {
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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final locale in const ['tr', 'en']) {
    testWidgets('Family pages fit native landscape at 2x text in $locale', (
      tester,
    ) async {
      AppLicenses.registerNunito();
      LicenseRegistry.addLicense(() async* {
        final licenseBytes = await rootBundle.load('NOTICES.Z');
        final notices = utf8.decode(
          gzip.decode(licenseBytes.buffer.asUint8List()),
        );
        final separator = '\n${'-' * 80}\n';
        for (final text in notices.split(separator)) {
          final paragraphStart = text.indexOf('\n\n');
          yield paragraphStart >= 0
              ? LicenseEntryWithLineBreaks(
                  text.substring(0, paragraphStart).split('\n'),
                  text.substring(paragraphStart + 2),
                )
              : LicenseEntryWithLineBreaks(const <String>[], text);
        }
      });

      final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(viewport.width, greaterThan(viewport.height));
      expect(tester.view.devicePixelRatio, greaterThan(0));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final content = await tester.runAsync(ContentRepository.load);
      expect(content, isNotNull, reason: 'production content bundle loads');
      final state = AppState(content!, db, AudioService());
      await tester.runAsync(state.load);
      await tester.runAsync(() => state.createProfile('Mina', 'cat', {}));
      state
        ..locale = locale
        ..configuration = AppConfiguration(
          freeGames: content.freeGames.toSet(),
          announcementId: 'family-layout-update',
        );
      state.unlockFamily();
      final cachedNotice = {
        'schemaVersion': 1,
        'title': {'tr': 'Öğrenme duyurusu', 'en': 'Learning update'},
        'body': {
          'tr': 'Yeni etkinlikler aile bölümünde sizi bekliyor.',
          'en': 'New activities are waiting for your family.',
        },
      };
      await tester.runAsync(() async {
        await db.setPreference(
          'announcement:family-layout-update',
          jsonEncode({'id': 'family-layout-update', 'payload': cachedNotice}),
        );
        await db.setPreference(
          'announcementCheckedAt:family-layout-update',
          DateTime.now().toIso8601String(),
        );
      });

      try {
        await tester.pumpWidget(
          EducationApp(state: state, familyAuthBackend: _OfflineAuthBackend()),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
        router.go('/family');
        await tester.pumpAndSettle();
        expect(find.byType(FamilyScreen), findsOneWidget);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(FamilyScreen)),
          ).scale(1),
          2,
        );

        var surfaceConverted = false;
        Future<void> capture(String name) async {
          if (!surfaceConverted) {
            await binding.convertFlutterSurfaceToImage();
            surfaceConverted = true;
          }
          await tester.pump();
          await binding.takeScreenshot(name);
        }

        void expectBounded(String stage) {
          for (final scrollable in tester.widgetList<Scrollable>(
            find.byType(Scrollable),
          )) {
            expect(
              scrollable.axisDirection,
              isNot(AxisDirection.down),
              reason: '$stage has no downward vertical scrollable',
            );
            expect(
              scrollable.axisDirection,
              isNot(AxisDirection.up),
              reason: '$stage has no upward vertical scrollable',
            );
          }
          expect(tester.takeException(), isNull, reason: '$stage overflow');
          for (final type in [
            IconButton,
            TextButton,
            ElevatedButton,
            OutlinedButton,
            FilledButton,
          ]) {
            for (final element in find.byType(type).evaluate()) {
              final target = find.byElementPredicate(
                (candidate) => identical(candidate, element),
              );
              final rect = tester.getRect(target);
              if (!rect.overlaps(Offset.zero & viewport)) continue;
              expect(
                rect.width,
                greaterThanOrEqualTo(_minimumTapTargetExtent),
                reason: '$stage $type width',
              );
              expect(
                rect.height,
                greaterThanOrEqualTo(_minimumTapTargetExtent),
                reason: '$stage $type height',
              );
              expect(
                rect.left,
                greaterThanOrEqualTo(0),
                reason: '$stage $type left',
              );
              expect(
                rect.top,
                greaterThanOrEqualTo(0),
                reason: '$stage $type top',
              );
              expect(
                rect.right,
                lessThanOrEqualTo(viewport.width),
                reason: '$stage $type right',
              );
              expect(
                rect.bottom,
                lessThanOrEqualTo(viewport.height),
                reason: '$stage $type bottom',
              );
            }
          }
          final bar = find.byType(NavigationBar);
          if (bar.evaluate().isNotEmpty) {
            expect(
              tester.getRect(bar).height,
              greaterThanOrEqualTo(_minimumTapTargetExtent),
            );
          }
        }

        Future<bool> advanceFamilyPages(
          String stage, {
          Finder? stopWhenVisible,
        }) async {
          final tooltip = find.byTooltip(
            locale == 'tr' ? 'Sonraki bölüm' : 'Next section',
          );
          expect(
            tooltip,
            findsOneWidget,
            reason: '$stage family pager tooltip',
          );
          final next = find
              .ancestor(of: tooltip, matching: find.byType(IconButton))
              .first;
          expect(next, findsOneWidget, reason: '$stage family pager button');
          final header = find
              .ancestor(of: tooltip, matching: find.byType(Row))
              .first;
          final counter = find.descendant(
            of: header,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  RegExp(r'^\d+ / \d+$').hasMatch(widget.data ?? ''),
            ),
          );
          expect(counter, findsOneWidget, reason: stage);
          var reachedEnd = false;
          var expectedTotal = 0;
          for (var page = 0; page < 64; page++) {
            expectBounded('$stage page $page');
            if (stopWhenVisible != null &&
                stopWhenVisible.evaluate().isNotEmpty) {
              return true;
            }
            final beforeMatch = RegExp(
              r'^(\d+) / (\d+)$',
            ).firstMatch(tester.widget<Text>(counter).data!);
            expect(beforeMatch, isNotNull, reason: '$stage page counter');
            final beforePage = int.parse(beforeMatch!.group(1)!) - 1;
            final total = int.parse(beforeMatch.group(2)!);
            if (page == 0) {
              expectedTotal = total;
            } else {
              expect(
                total,
                expectedTotal,
                reason: '$stage page count stays stable',
              );
            }
            final button = tester.widget<IconButton>(next);
            if (button.onPressed == null) {
              expect(
                beforePage,
                total - 1,
                reason: '$stage disabled button is on final page',
              );
              reachedEnd = true;
              break;
            }
            await tester.tap(next);
            await tester.pumpAndSettle();
            final afterMatch = RegExp(
              r'^(\d+) / (\d+)$',
            ).firstMatch(tester.widget<Text>(counter).data!);
            expect(afterMatch, isNotNull, reason: '$stage next-page counter');
            expect(int.parse(afterMatch!.group(1)!), beforePage + 2);
            expect(int.parse(afterMatch.group(2)!), expectedTotal);
          }
          expect(reachedEnd, isTrue, reason: '$stage page traversal bounded');
          return false;
        }

        final progressTab = find.text(locale == 'tr' ? 'Gelişim' : 'Progress');
        final settingsTab = find.text(locale == 'tr' ? 'Ayarlar' : 'Settings');
        final gamesTab = find.text(locale == 'tr' ? 'Oyunlar' : 'Games');
        final profilesTab = find.text(
          locale == 'tr' ? 'Profiller' : 'Profiles',
        );
        expectBounded('family dashboard and announcement');
        expect(
          find.text(locale == 'tr' ? 'Öğrenme duyurusu' : 'Learning update'),
          findsOneWidget,
        );
        await capture('seg-family-announcement-$locale');
        await advanceFamilyPages('family progress report');

        await tester.tap(settingsTab);
        await tester.pumpAndSettle();
        expectBounded('family settings');
        await capture('seg-family-settings-$locale');
        await advanceFamilyPages('family settings pages');
        final creditsLabel = locale == 'tr'
            ? 'Kaynaklar ve lisanslar'
            : 'Credits and licenses';
        final creditsButton = find.text(creditsLabel);
        // The link lives on a privacy card before two final information cards;
        // revisit Settings and stop on that actual route page after checking all.
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();
        expect(
          await advanceFamilyPages(
            'family settings route discovery',
            stopWhenVisible: creditsButton,
          ),
          isTrue,
          reason: 'settings exposes credits route on its privacy page',
        );
        expect(creditsButton, findsOneWidget);
        await tester.tap(creditsButton);
        await tester.pumpAndSettle();
        expect(find.byType(CreditsScreen), findsOneWidget);
        expectBounded('credits');
        expect(
          find.byKey(const ValueKey('credits-group-sounds')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('credits-group-photos')),
          findsOneWidget,
        );
        await capture('seg-family-credits-$locale');
        await tester.tap(
          find.byKey(const ValueKey('credits-open-source-licenses')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(OpenSourceLicensesScreen), findsOneWidget);
        for (var attempt = 0; attempt < 20; attempt++) {
          if (find
              .byKey(const ValueKey('license-package-counter'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.byKey(const ValueKey('license-package-counter')),
          findsOneWidget,
        );
        expectBounded('open-source licenses');
        expect(
          find.byKey(const ValueKey('license-next-package')),
          findsOneWidget,
        );
        await capture('seg-family-licenses-$locale');

        final licenseContext = tester.element(
          find.byType(OpenSourceLicensesScreen),
        );
        final licenseBack = find.byTooltip(
          MaterialLocalizations.of(licenseContext).backButtonTooltip,
        );
        expect(
          licenseBack,
          findsOneWidget,
          reason: 'licenses app-bar back control',
        );
        await tester.tap(licenseBack);
        await tester.pumpAndSettle();
        expect(find.byType(CreditsScreen), findsOneWidget);
        expectBounded('return from open-source licenses to credits');
        router.go('/family');
        await tester.pumpAndSettle();
        await tester.tap(gamesTab);
        await tester.pumpAndSettle();
        expectBounded('family game settings');
        await advanceFamilyPages('family game pages');
        await tester.tap(profilesTab);
        await tester.pumpAndSettle();
        expectBounded('family profiles');
        await advanceFamilyPages('family profile pages');
        await tester.tap(progressTab);
        await tester.pumpAndSettle();
        expectBounded('family progress return');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        state.lockFamily();
        state.dispose();
        await tester.runAsync(db.close);
      }
    });
  }
}
