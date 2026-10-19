import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/family_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

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

  String exactLength(String phrase, int length) {
    final buffer = StringBuffer();
    while (buffer.toString().runes.length < length) {
      buffer.write('$phrase ');
    }
    var value = buffer.toString().trimRight();
    while (value.runes.length > length) {
      value = value.substring(0, value.length - 1);
    }
    while (value.runes.length < length) {
      value += 'x';
    }
    return value;
  }

  String complexBody(String phrase, int length) {
    var value =
        '$phrase starts here with Unicode 🚂 — naïve text.\n\n'
        '${List.filled(36, 'UnbrokenToken').join()}\n\n'
        '$phrase continues after the blank line.\n\n';
    while (value.runes.length < length) {
      value += '\n$phrase and the message continues.';
    }
    final runes = value.runes.toList().take(length).toList();
    while (runes.isNotEmpty &&
        const [0x0a, 0x0d, 0x20, 0x09].contains(runes.last)) {
      runes.removeLast();
    }
    while (runes.length < length) {
      runes.add(0x78);
    }
    return String.fromCharCodes(runes);
  }

  testWidgets(
    'maximum valid announcement text is fully reachable on the actual family page',
    (tester) async {
      final state = AppState(
        content,
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await loadFonts(tester);
        await state.load();
        await state.createProfile('Mina', 'cat', {});
        state.configuration = AppConfiguration(
          freeGames: content.freeGames.toSet(),
          announcementId: 'long-announcement',
        );
        state.unlockFamily();

        final expectedTitles = {
          'en': exactLength('Learning update', 120),
          'tr': exactLength('Öğrenme duyurusu', 120),
        };
        final expectedBodies = {
          'en': complexBody('Learning update', 1200),
          'tr': complexBody('Öğrenme duyurusu', 1200),
        };
        for (final body in expectedBodies.values) {
          expect(body, contains('\n\n'));
          expect(body, contains('🚂'));
          expect(body, contains(List.filled(36, 'UnbrokenToken').join()));
        }
        final cachedAnnouncement = {
          'schemaVersion': 1,
          'title': expectedTitles,
          'body': expectedBodies,
        };
        await state.db.setPreference(
          'announcement:long-announcement',
          jsonEncode({
            'id': 'long-announcement',
            'payload': cachedAnnouncement,
          }),
        );
        await state.db.setPreference(
          'announcementCheckedAt:long-announcement',
          DateTime.now().toIso8601String(),
        );

        Future<void> mount(
          String locale,
          Size size,
          double scale, {
          required String key,
        }) async {
          state.locale = locale;
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            MaterialApp(
              theme: segTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: ListenableBuilder(
                listenable: state,
                builder: (context, _) =>
                    FamilyScreen(key: ValueKey(key), state: state),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        for (final locale in ['tr', 'en']) {
          state.locale = locale;
          for (final size in [const Size(800, 360), const Size(1280, 800)]) {
            for (final scale in [1.0, 1.6, 2.0]) {
              final tag = '$locale $size scale $scale';
              await mount(locale, size, scale, key: tag);
              expect(tester.takeException(), isNull, reason: '$tag initial');

              final verticalScrollables = tester
                  .widgetList<Scrollable>(find.byType(Scrollable))
                  .where(
                    (scrollable) =>
                        scrollable.axisDirection == AxisDirection.down ||
                        scrollable.axisDirection == AxisDirection.up,
                  );
              expect(verticalScrollables, isEmpty, reason: tag);
              expect(
                find.text(locale == 'tr' ? 'Yenilikler' : 'News'),
                findsOneWidget,
              );

              final titles = <String>[];
              final bodies = <String>[];
              final indicator = find.byKey(
                const ValueKey('announcement-page-indicator'),
              );
              final pageCount = int.parse(
                tester.widget<Text>(indicator).data!.split(' / ').last,
              );
              expect(pageCount, greaterThan(1), reason: tag);

              for (var page = 0; page < pageCount; page++) {
                final titleKey = ValueKey('announcement-title-page-$page');
                final bodyKey = ValueKey('announcement-body-page-$page');
                final viewport = tester.getRect(find.byType(PageView).last);
                bool fullyVisible(Finder finder) {
                  if (finder.evaluate().isEmpty) return false;
                  final rect = tester.getRect(finder);
                  return rect.left >= viewport.left - 1 &&
                      rect.right <= viewport.right + 1 &&
                      rect.top >= viewport.top - 1 &&
                      rect.bottom <= viewport.bottom + 1;
                }

                final visibleTitle = fullyVisible(find.byKey(titleKey));
                final visibleBody = fullyVisible(find.byKey(bodyKey));
                expect(visibleTitle != visibleBody, isTrue, reason: tag);
                if (visibleTitle) {
                  titles.add(tester.widget<Text>(find.byKey(titleKey)).data!);
                }
                if (visibleBody) {
                  bodies.add(tester.widget<Text>(find.byKey(bodyKey)).data!);
                }
                expect(
                  tester.widget<Text>(indicator).data,
                  '${page + 1} / $pageCount',
                  reason: tag,
                );
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '$tag page $page',
                );
                if (page + 1 < pageCount) {
                  await tester.tap(find.byTooltip('Next page'));
                  await tester.pumpAndSettle();
                }
              }
              expect(titles.join(), expectedTitles[locale], reason: tag);
              expect(bodies.join(), expectedBodies[locale], reason: tag);
              expect(tester.takeException(), isNull, reason: '$tag complete');
            }
          }
        }

        const runtimeSize = Size(800, 360);
        await mount('en', runtimeSize, 2, key: 'runtime-text-scale');
        final runtimeIndicator = find.byKey(
          const ValueKey('announcement-page-indicator'),
        );
        final oldPageCount = int.parse(
          tester.widget<Text>(runtimeIndicator).data!.split(' / ').last,
        );
        for (var page = 1; page < oldPageCount; page++) {
          await tester.tap(find.byTooltip('Next page'));
          await tester.pumpAndSettle();
        }
        final runtimePager = tester.widget<PageView>(
          find.byType(PageView).last,
        );
        final runtimeController = runtimePager.controller!;
        expect(runtimeController.page!.round(), oldPageCount - 1);

        await mount('en', runtimeSize, 1, key: 'runtime-text-scale');
        final newPageCount = int.parse(
          tester.widget<Text>(runtimeIndicator).data!.split(' / ').last,
        );
        expect(newPageCount, lessThan(oldPageCount));
        expect(runtimeController.page!.round(), newPageCount - 1);
        expect(
          tester.widget<Text>(runtimeIndicator).data,
          '$newPageCount / $newPageCount',
        );
        expect(tester.takeException(), isNull, reason: 'runtime scale clamp');
      } finally {
        await tester.pumpWidget(const SizedBox());
        state.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
