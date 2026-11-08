import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/ui/family_nav_bar.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/credits_screen.dart';
import 'package:special_education_games/features/family/family_account_screen.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/family/open_source_licenses_screen.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

class _AuthBackend implements FamilyAuthBackend {
  int restores = 0, signsIn = 0, signsOut = 0;
  @override
  Future<FamilyAccount?> restore() async {
    restores++;
    return null;
  }

  @override
  Future<FamilyAccount?> signIn() async {
    signsIn++;
    return null;
  }

  @override
  Future<void> signOut() async {
    signsOut++;
  }

  @override
  void cancelPending() {}
}

class _CreditsFixtureBundle extends CachingAssetBundle {
  final Map<String, String> strings;
  _CreditsFixtureBundle(this.strings);

  @override
  Future<ByteData> load(String key) {
    final text = strings[key];
    if (text == null) {
      return Future.error(
        FlutterError('Unexpected asset request in credits fixture: $key'),
      );
    }
    final bytes = Uint8List.fromList(utf8.encode(text));
    return SynchronousFuture<ByteData>(ByteData.sublistView(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture<String>(strings[key]!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  late List<dynamic> sounds;
  late Map<String, dynamic> manifest;
  late List<dynamic> animalsCatalog;
  late Map<String, int> fishAssetByteLengths;
  late _CreditsFixtureBundle creditsFixtureBundle;
  setUpAll(() async {
    content = await ContentRepository.load();
    final soundsJson = await rootBundle.loadString('assets/sfx/sources.json');
    final photoManifestJson = await rootBundle.loadString(
      'assets/content/real_photo_manifest.json',
    );
    sounds = jsonDecode(soundsJson) as List;
    manifest = jsonDecode(photoManifestJson) as Map<String, dynamic>;
    creditsFixtureBundle = _CreditsFixtureBundle({
      'assets/sfx/sources.json': soundsJson,
      'assets/content/real_photo_manifest.json': photoManifestJson,
    });
    animalsCatalog =
        jsonDecode(
              await rootBundle.loadString('assets/content/items/animals.json'),
            )
            as List;
    final fishItem = animalsCatalog.cast<Map<String, dynamic>>().singleWhere(
      (item) => item['id'] == 'animals.fish',
    );
    final fishImages = (fishItem['images'] as List).cast<String>();
    fishAssetByteLengths = {};
    for (final path in [...fishImages, 'assets/images/animals/fish_1.webp']) {
      fishAssetByteLengths[path] = (await rootBundle.load(path)).lengthInBytes;
    }
  });

  Widget creditsScreen(AppState state) =>
      CreditsScreen(state: state, assetBundle: creditsFixtureBundle);

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
    await state.createProfile('Test', 'cat', {});
    return state;
  }

  Future<void> mount(
    WidgetTester tester,
    Size size,
    double scale,
    Widget screen, {
    double devicePixelRatio = 1,
    EdgeInsets safePadding = EdgeInsets.zero,
  }) async {
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.physicalSize = size * devicePixelRatio;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: safePadding,
            viewPadding: safePadding,
          ),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
    final exception = tester.takeException();
    if (exception != null) {
      fail('size=$size scale=$scale screen=${screen.runtimeType}: $exception');
    }
    for (final scrollable in tester.widgetList<Scrollable>(
      find.byType(Scrollable),
    )) {
      expect(
        scrollable.axisDirection,
        isNot(AxisDirection.down),
        reason: '${scrollable.runtimeType}',
      );
      expect(
        scrollable.axisDirection,
        isNot(AxisDirection.up),
        reason: '${scrollable.runtimeType}',
      );
    }
  }

  ({int record, int recordCount, int detail, int detailCount}) creditsCounter(
    WidgetTester tester,
  ) {
    final counter = tester.widget<Text>(
      find.byKey(const ValueKey('credits-record-counter')),
    );
    final pattern = RegExp(r'(\d+) / (\d+)\s+·\s+(\d+) / (\d+)');
    final match = pattern.firstMatch(counter.textSpan!.toPlainText())!;
    return (
      record: int.parse(match.group(1)!),
      recordCount: int.parse(match.group(2)!),
      detail: int.parse(match.group(3)!),
      detailCount: int.parse(match.group(4)!),
    );
  }

  void expectNoVerticalScroll(WidgetTester tester) {
    for (final scrollable in tester.widgetList<Scrollable>(
      find.byType(Scrollable),
    )) {
      expect(scrollable.axisDirection, isNot(AxisDirection.down));
      expect(scrollable.axisDirection, isNot(AxisDirection.up));
    }
  }

  testWidgets(
    'All family pages stay horizontally navigable without vertical scroll',
    (tester) async {
      final carSoundRecords = sounds
          .cast<Map<String, dynamic>>()
          .where((source) => source['itemId'] == 'vehicles.car')
          .toList();
      expect(carSoundRecords, hasLength(1));
      expect(carSoundRecords.single['asset'], 'assets/sfx/vehicles/car.mp3');
      expect(carSoundRecords.single['license'], 'CC0-1.0');
      expect(
        carSoundRecords.single['licenseUrl'],
        'https://creativecommons.org/publicdomain/zero/1.0/',
      );
      expect(
        (await rootBundle.load(
          carSoundRecords.single['asset'] as String,
        )).lengthInBytes,
        greaterThan(1000),
      );
      final trainSoundRecords = sounds
          .cast<Map<String, dynamic>>()
          .where((source) => source['itemId'] == 'vehicles.train')
          .toList();
      expect(trainSoundRecords, hasLength(1));
      expect(
        trainSoundRecords.single['asset'],
        'assets/sfx/vehicles/train.mp3',
      );
      expect(trainSoundRecords.single['author'], 'Cityedit14');
      expect(trainSoundRecords.single['license'], 'CC-BY-SA-4.0');
      expect(
        trainSoundRecords.single['licenseUrl'],
        'https://creativecommons.org/licenses/by-sa/4.0/',
      );
      expect(
        (await rootBundle.load(
          trainSoundRecords.single['asset'] as String,
        )).lengthInBytes,
        greaterThan(1000),
      );
      final airplaneSoundRecords = sounds
          .cast<Map<String, dynamic>>()
          .where((source) => source['itemId'] == 'vehicles.airplane')
          .toList();
      expect(airplaneSoundRecords, hasLength(1));
      expect(
        airplaneSoundRecords.single['asset'],
        'assets/sfx/vehicles/airplane.mp3',
      );
      expect(airplaneSoundRecords.single['author'], 'Jud McCranie (Bubba73)');
      expect(airplaneSoundRecords.single['license'], 'CC-BY-SA-4.0');
      expect(
        airplaneSoundRecords.single['licenseUrl'],
        'https://creativecommons.org/licenses/by-sa/4.0/',
      );
      expect(airplaneSoundRecords.single['adaptationLicense'], 'CC BY-SA 4.0');
      expect(
        airplaneSoundRecords.single['humanListeningApprovalPending'],
        isTrue,
      );
      expect(
        (await rootBundle.load(
          airplaneSoundRecords.single['asset'] as String,
        )).lengthInBytes,
        greaterThan(1000),
      );
      final helicopterSoundRecords = sounds
          .cast<Map<String, dynamic>>()
          .where((source) => source['itemId'] == 'vehicles.helicopter')
          .toList();
      expect(helicopterSoundRecords, hasLength(1));
      final helicopterSound = helicopterSoundRecords.single;
      expect(helicopterSound['asset'], 'assets/sfx/vehicles/helicopter.mp3');
      expect(helicopterSound['author'], 'JoBrodie');
      expect(helicopterSound['license'], 'CC0-1.0');
      expect(helicopterSound['humanListeningApprovalPending'], isTrue);
      final helicopterSoundBytes = await rootBundle.load(
        helicopterSound['asset'] as String,
      );
      expect(helicopterSoundBytes.lengthInBytes, greaterThan(1000));
      expect(
        sha256.convert(helicopterSoundBytes.buffer.asUint8List()).toString(),
        helicopterSound['sha256'],
      );
      final photoAssets = manifest['assets'] as List;
      final helicopterPhoto = photoAssets
          .cast<Map<String, dynamic>>()
          .singleWhere((source) => source['id'] == 'vehicles.helicopter');
      expect(
        helicopterPhoto['path'],
        'assets/images/vehicles/helicopter_real.webp',
      );
      expect(helicopterPhoto['author'], contains('Iain Thomson'));
      expect(helicopterPhoto['license'], 'Open Government Licence v1.0');
      expect(helicopterPhoto['licenseVerified'], isTrue);
      expect(
        helicopterPhoto['humanContentReviewPending'],
        contains('dark backlit'),
      );
      final helicopterPhotoBytes = await rootBundle.load(
        helicopterPhoto['path'] as String,
      );
      expect(
        sha256.convert(helicopterPhotoBytes.buffer.asUint8List()).toString(),
        helicopterPhoto['sha256'],
      );
      final state = await makeState();
      await loadFonts(tester);
      state.unlockFamily();
      final backend = _AuthBackend();
      final auth = FamilyAuth(
        backend: backend,
        parentAuthorized: () => state.familyUnlocked,
      );
      state.locale = 'en';
      await mount(
        tester,
        const Size(800, 360),
        1.0,
        FamilyAccountScreen(state: state, auth: auth),
      );
      expect(find.byType(TabBarView), findsOneWidget);
      await tester.tap(find.byTooltip('Sync daily summaries'));
      await tester.pumpAndSettle();
      expect(find.text('Sync daily summaries'), findsOneWidget);

      for (final size in [const Size(800, 360), const Size(1280, 800)]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          state.locale = 'en';
          await mount(tester, size, scale, SubscriptionScreen(state: state));
          expect(state.billing.loading, isFalse);
          expect(state.billing.plans, isEmpty);
          // One page: the primary action and the links are visible.
          for (final key in ['paywall-continue', 'paywall-restore']) {
            final rect = tester.getRect(find.byKey(ValueKey(key)));
            expect(rect.bottom, lessThanOrEqualTo(size.height), reason: key);
            expect(rect.top, greaterThanOrEqualTo(0), reason: key);
          }

          for (final creditLocale in ['en', 'tr']) {
            state.locale = creditLocale;
            await mount(tester, size, scale, creditsScreen(state));
            expect(find.byType(PageView), findsOneWidget);
            expect(
              find.byKey(const ValueKey('credits-group-sounds')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('credits-group-photos')),
              findsOneWidget,
            );
            expect(creditsCounter(tester).recordCount, sounds.length);
            expect(
              creditsCounter(tester).detailCount,
              scale < 1.6 && size.height > 400 ? 1 : 5,
            );
            if (size == const Size(800, 360) &&
                scale == 1.0 &&
                creditLocale == 'en') {
              await tester.tap(
                find.byKey(const ValueKey('credits-group-photos')),
              );
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('credits-record-title-1-0')),
                findsOneWidget,
              );
              expect(tester.takeException(), isNull);
              expectNoVerticalScroll(tester);
              await tester.tap(
                find.byKey(const ValueKey('credits-group-sounds')),
              );
              await tester.pumpAndSettle();
            }
          }
        }
      }

      state.locale = 'tr';
      await mount(tester, const Size(800, 360), 2.0, creditsScreen(state));
      final photos = flattenRealPhotoCreditEntries(photoAssets);
      // 31 earlier verified photos, ten Food & Drinks photos, the R32
      // single-object cucumber, mandarin and onion, and the R45 watermelon.
      expect(photoAssets.length, 45);
      // Ten animal recordings plus the round-end applause.
      expect(sounds.length, 11);
      expect(sounds.length + photos.length, greaterThanOrEqualTo(40));
      final fishPhoto = photoAssets.cast<Map<String, dynamic>>().singleWhere(
        (source) => source['id'] == 'animals.fish',
      );
      expect(fishPhoto['path'], 'assets/images/animals/fish_real.webp');
      expect(fishPhoto['author'], contains('Ellicrum'));
      expect(fishPhoto['author'], contains('Ffish.asia'));
      expect(fishPhoto['originalLicense'], 'CC BY 4.0');
      expect(fishPhoto['originalLicenseUrl'], contains('/licenses/by/4.0/'));
      expect(fishPhoto['license'], 'CC BY-SA 4.0');
      expect(fishPhoto['adaptationLicense'], 'CC BY-SA 4.0');
      expect(
        fishPhoto['sha256'],
        '4d7581d9fc6c17aba5168f6beeb3b4d8e8707346c9fb884416b7c28317a1ac61',
      );
      final fishItem = animalsCatalog.cast<Map<String, dynamic>>().singleWhere(
        (item) => item['id'] == 'animals.fish',
      );
      final fishImages = (fishItem['images'] as List).cast<String>();
      final fishVariants =
          (fishPhoto['additionalVariants'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
      expect(fishImages, <String>[
        fishPhoto['path'] as String,
        ...fishVariants.map((variant) => variant['path'] as String),
      ]);
      expect(
        fishAssetByteLengths.keys,
        containsAll([...fishImages, 'assets/images/animals/fish_1.webp']),
      );
      expect(fishAssetByteLengths.values, everyElement(greaterThan(0)));

      for (var group = 0; group < 2; group++) {
        if (group == 1) {
          await tester.tap(find.byKey(const ValueKey('credits-group-photos')));
          await tester.pumpAndSettle();
        }
        final sourceRecords = group == 0 ? sounds : photos;
        expect(creditsCounter(tester).recordCount, sourceRecords.length);
        for (var record = 0; record < sourceRecords.length; record++) {
          final source = sourceRecords[record] as Map<String, dynamic>;
          expect(
            find.byKey(ValueKey('credits-record-title-$group-$record')),
            findsOneWidget,
          );
          final expectedFields = <String>{
            'author',
            'license',
            'source',
            'license-url',
            'changes',
            if (group == 1) 'adaptation-license',
            if (group == 1 && source['existingBackgroundRemoval'] != null)
              'previous-author',
          };
          final expectedValues = <String, String>{
            'author': source['author'].toString(),
            'license': source['license'].toString(),
            'source': source['source'].toString(),
            'license-url': source['licenseUrl'].toString(),
            'changes': 'Düzenleme',
            if (group == 1)
              'adaptation-license': source['adaptationLicense'].toString(),
            if (group == 1 && source['existingBackgroundRemoval'] != null)
              'previous-author': source['existingBackgroundRemoval'].toString(),
          };
          final expectedTitle = (source[group == 0 ? 'title' : 'id'])
              .toString();
          expect(
            tester
                .widget<Text>(
                  find.byKey(ValueKey('credits-record-title-$group-$record')),
                )
                .data,
            expectedTitle,
          );
          final foundFields = <String>{};
          while (true) {
            final counter = creditsCounter(tester);
            for (final field in expectedFields) {
              final finder = find.byKey(
                ValueKey('credits-field-$record-$field'),
              );
              if (finder.evaluate().isNotEmpty) {
                foundFields.add(field);
                final rendered = tester
                    .widget<Text>(finder)
                    .textSpan!
                    .toPlainText();
                expect(rendered, contains(expectedValues[field]!));
              }
            }
            final nextDetail = tester.widget<IconButton>(
              find.byKey(const ValueKey('credits-next-detail')),
            );
            if (nextDetail.onPressed == null) break;
            await tester.tap(find.byKey(const ValueKey('credits-next-detail')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(creditsCounter(tester).detail, counter.detail + 1);
            expectNoVerticalScroll(tester);
          }
          expect(foundFields, containsAll(expectedFields));
          if (record + 1 < sourceRecords.length) {
            await tester.tap(find.byKey(const ValueKey('credits-next-record')));
            await tester.pumpAndSettle();
            expect(creditsCounter(tester).record, record + 2);
            expectNoVerticalScroll(tester);
          }
        }
      }
      expect(backend.signsIn, 0);
      expect(backend.signsOut, 0);
      expect(state.billing.loading, isFalse);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      state.dispose();
    },
  );

  testWidgets('Family section tooltip resolves its horizontal pager button', (
    tester,
  ) async {
    final state = await makeState();
    addTearDown(state.dispose);
    state
      ..locale = 'en'
      ..unlockFamily();
    await loadFonts(tester);
    await mount(tester, const Size(800, 360), 2, FamilyScreen(state: state));

    final tooltip = find.byTooltip('Next section');
    expect(tooltip, findsOneWidget);
    final button = find
        .ancestor(of: tooltip, matching: find.byType(IconButton))
        .first;
    expect(button, findsOneWidget);
    expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    final header = find.ancestor(of: tooltip, matching: find.byType(Row)).first;
    final counter = find.descendant(
      of: header,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^\d+ / \d+$').hasMatch(widget.data ?? ''),
      ),
    );
    expect(counter, findsOneWidget);
    final before = tester.widget<Text>(counter).data;
    final pager = tester.widget<PageView>(
      find.byKey(const ValueKey('family-tab-0')),
    );
    expect(pager.scrollDirection, Axis.horizontal);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(counter).data, isNot(before));
    expect(tester.takeException(), isNull);
    expectNoVerticalScroll(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    state.lockFamily();
  });

  testWidgets(
    'Family progress cards fit intermediate landscape at 2x in TR and EN',
    (tester) async {
      const logicalViewport = Size(1020.63, 454.74);
      const devicePixelRatio = 2.375;
      final state = await makeState();
      addTearDown(state.dispose);
      await loadFonts(tester);
      state
        ..configuration = AppConfiguration(
          freeGames: content.freeGames.toSet(),
          announcementId: 'family-layout-update',
        )
        ..unlockFamily();
      // Detailed report pages are Premium; cover their layout.
      state.entitlement.lifetimeOwned = true;
      await tester.runAsync(() async {
        await state.db.setPreference(
          'announcement:family-layout-update',
          jsonEncode({
            'id': 'family-layout-update',
            'payload': {
              'schemaVersion': 1,
              'title': {'tr': 'Öğrenme duyurusu', 'en': 'Learning update'},
              'body': {
                'tr': 'Yeni etkinlikler aile bölümünde sizi bekliyor.',
                'en': 'New activities are waiting for your family.',
              },
            },
          }),
        );
        await state.db.setPreference(
          'announcementCheckedAt:family-layout-update',
          DateTime.now().toIso8601String(),
        );
      });

      const insetCases = [
        EdgeInsets.only(top: 52, bottom: 24),
        EdgeInsets.only(top: 60, bottom: 24),
      ];
      for (final locale in ['tr', 'en']) {
        for (final safePadding in insetCases) {
          state.locale = locale;
          await mount(
            tester,
            logicalViewport,
            2,
            FamilyScreen(state: state),
            devicePixelRatio: devicePixelRatio,
            safePadding: safePadding,
          );
          final actualViewport =
              tester.view.physicalSize / tester.view.devicePixelRatio;
          expect(actualViewport.width, closeTo(logicalViewport.width, 0.01));
          expect(actualViewport.height, closeTo(logicalViewport.height, 0.01));
          final tooltip = find.byTooltip(
            locale == 'tr' ? 'Sonraki bölüm' : 'Next section',
          );
          final button = find
              .ancestor(of: tooltip, matching: find.byType(IconButton))
              .first;
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
          expect(counter, findsOneWidget);
          var reachedWeekly = false;
          for (var attempt = 0; attempt < 64; attempt++) {
            final match = RegExp(
              r'^(\d+) / (\d+)$',
            ).firstMatch(tester.widget<Text>(counter).data!);
            final current = int.parse(match!.group(1)!) - 1;
            final total = int.parse(match.group(2)!);
            expectNoVerticalScroll(tester);
            expect(
              tester.takeException(),
              isNull,
              reason:
                  '$locale progress page $current at $logicalViewport x2 safe=$safePadding',
            );
            if (current == 8) {
              expect(
                find.text(
                  locale == 'tr'
                      ? 'Son 7 gün · Oynama süresi (dk)'
                      : 'Last 7 days · Play time (min)',
                ),
                findsOneWidget,
                reason: '$locale weekly card retains its full heading',
              );
            }
            if (current == 8) reachedWeekly = true;
            final next = tester.widget<IconButton>(button);
            if (next.onPressed == null) {
              expect(current, total - 1);
              break;
            }
            await tester.tap(button);
            await tester.pumpAndSettle();
          }
          expect(
            reachedWeekly,
            isTrue,
            reason: '$locale report page 7 is covered',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
      state.lockFamily();
    },
  );

  testWidgets(
    'Family routes fit actual-phone landscape with safe insets at 2x',
    (tester) async {
      const logicalViewport = Size(1020.63, 454.74);
      const devicePixelRatio = 2.375;
      const insets = [
        EdgeInsets.only(left: 59.8, top: 52, bottom: 24),
        EdgeInsets.only(left: 59.8, top: 60, bottom: 24),
      ];
      final state = await makeState();
      addTearDown(state.dispose);
      await loadFonts(tester);
      state
        ..configuration = AppConfiguration(
          freeGames: content.freeGames.toSet(),
          announcementId: 'family-layout-update',
        )
        ..unlockFamily();
      await tester.runAsync(() async {
        await state.db.setPreference(
          'announcement:family-layout-update',
          jsonEncode({
            'id': 'family-layout-update',
            'payload': {
              'schemaVersion': 1,
              'title': {'tr': 'Öğrenme duyurusu', 'en': 'Learning update'},
              'body': {
                'tr': 'Yeni etkinlikler aile bölümünde sizi bekliyor.',
                'en': 'New activities are waiting for your family.',
              },
            },
          }),
        );
        await state.db.setPreference(
          'announcementCheckedAt:family-layout-update',
          DateTime.now().toIso8601String(),
        );
      });
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks(const [
          'family-layout-license-fixture',
        ], 'Local test license text for safe-area layout checks.');
      });

      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        for (final safePadding in insets) {
          await mount(
            tester,
            logicalViewport,
            2,
            FamilyScreen(state: state),
            devicePixelRatio: devicePixelRatio,
            safePadding: safePadding,
          );
          final actualViewport =
              tester.view.physicalSize / tester.view.devicePixelRatio;
          expect(actualViewport.width, closeTo(logicalViewport.width, 0.01));
          expect(actualViewport.height, closeTo(logicalViewport.height, 0.01));
          expectNoVerticalScroll(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale progress announcement',
          );
          expect(
            find.text(locale == 'tr' ? 'Öğrenme duyurusu' : 'Learning update'),
            findsOneWidget,
          );

          Future<void> checkCurrentPage(String stage) async {
            expectNoVerticalScroll(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '$locale $stage safe=$safePadding',
            );
          }

          Future<void> traverseTab(int tab, String stage) async {
            final navigation = tester.widget<FamilyNavBar>(
              find.byType(FamilyNavBar),
            );
            navigation.onDestinationSelected!(tab);
            await tester.pumpAndSettle();
            expect(find.byKey(ValueKey('family-tab-$tab')), findsOneWidget);
            final tooltip = find.byTooltip(
              locale == 'tr' ? 'Sonraki bölüm' : 'Next section',
            );
            final next = find
                .ancestor(of: tooltip, matching: find.byType(IconButton))
                .first;
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
            expect(counter, findsOneWidget, reason: '$stage counter');
            // The games tab grew with the Feelings, Our Body and Our Home
            // themes (Nov 2026).
            for (var page = 0; page < 128; page++) {
              await checkCurrentPage('$stage page $page');
              final button = tester.widget<IconButton>(next);
              if (button.onPressed == null) return;
              await tester.tap(next);
              await tester.pumpAndSettle();
            }
            fail('$stage exceeded bounded page traversal');
          }

          // Progress (including the cached announcement), games, profiles, and
          // every compact settings card use the same native-shaped constraints.
          for (var tab = 0; tab < 4; tab++) {
            await traverseTab(tab, 'family tab $tab');
          }

          await mount(
            tester,
            logicalViewport,
            2,
            creditsScreen(state),
            devicePixelRatio: devicePixelRatio,
            safePadding: safePadding,
          );
          expect(find.byType(CreditsScreen), findsOneWidget);
          await checkCurrentPage('credits');
          final openLicenses = find.byKey(
            const ValueKey('credits-open-source-licenses'),
          );
          expect(openLicenses, findsOneWidget);
          await tester.tap(openLicenses);
          await tester.pumpAndSettle();
          expect(find.byType(OpenSourceLicensesScreen), findsOneWidget);
          await checkCurrentPage('open-source licenses');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
      state.lockFamily();
    },
  );

  testWidgets(
    'Settings privacy card opens the real credits route in TR and EN',
    (tester) async {
      const viewport = Size(1020.63, 454.74);
      const dpr = 2.375;
      const safePadding = EdgeInsets.only(left: 59.8, top: 52.2, bottom: 24);
      final state = await makeState();
      addTearDown(state.dispose);
      await loadFonts(tester);
      state.unlockFamily();
      final router = GoRouter(
        initialLocation: '/family',
        routes: [
          GoRoute(
            path: '/family',
            builder: (_, _) => FamilyScreen(state: state),
          ),
          GoRoute(
            path: '/family/credits',
            builder: (_, _) => creditsScreen(state),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view
        ..devicePixelRatio = dpr
        ..physicalSize = viewport * dpr;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        router.go('/family');
        await tester.pumpWidget(
          MaterialApp.router(
            theme: segTheme(),
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                padding: safePadding,
                viewPadding: safePadding,
              ),
              child: child!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(FamilyScreen), findsOneWidget);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(FamilyScreen)),
          ).scale(1),
          2,
        );
        expectNoVerticalScroll(tester);

        final nav = tester.widget<FamilyNavBar>(find.byType(FamilyNavBar));
        nav.onDestinationSelected!(3);
        await tester.pumpAndSettle();
        final credits = find.text(
          locale == 'tr' ? 'Kaynaklar ve lisanslar' : 'Credits and licenses',
        );
        var foundCreditsPage = false;
        for (var attempt = 0; attempt < 64; attempt++) {
          expectNoVerticalScroll(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale settings page $attempt',
          );
          if (credits.evaluate().isNotEmpty) {
            foundCreditsPage = true;
            break;
          }
          final next = find
              .ancestor(
                of: find.byTooltip(
                  locale == 'tr' ? 'Sonraki bölüm' : 'Next section',
                ),
                matching: find.byType(IconButton),
              )
              .first;
          if (tester.widget<IconButton>(next).onPressed == null) break;
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(foundCreditsPage, isTrue, reason: '$locale settings route page');
        await tester.tap(credits);
        await tester.pumpAndSettle();
        expect(find.byType(CreditsScreen), findsOneWidget);
        expectNoVerticalScroll(tester);
        expect(tester.takeException(), isNull, reason: '$locale credits route');
        await tester.tap(
          find.byKey(const ValueKey('credits-open-source-licenses')),
        );
        // LicenseRegistry is an asynchronous stream and may keep the page's
        // loading indicator animating during a full-suite run. Pump the route
        // transition once without waiting for that unrelated stream to settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(OpenSourceLicensesScreen), findsOneWidget);
        final licenseContext = tester.element(
          find.byType(OpenSourceLicensesScreen),
        );
        final licenseBack = find.byTooltip(
          MaterialLocalizations.of(licenseContext).backButtonTooltip,
        );
        expect(licenseBack, findsOneWidget);
        await tester.tap(licenseBack);
        await tester.pumpAndSettle();
        expect(find.byType(CreditsScreen), findsOneWidget);
        expectNoVerticalScroll(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale licenses back to credits',
        );
      }
      state.lockFamily();
    },
  );
}
