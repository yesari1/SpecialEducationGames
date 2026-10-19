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
import 'package:special_education_games/features/family/family_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> makeState({String nickname = 'Mina'}) async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile(nickname, 'cat', {'sound': 1, 'language': 0});
    state.unlockFamily();
    return state;
  }

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

  Future<void> mount(
    WidgetTester tester,
    AppState state,
    Size size,
    double scale,
  ) async {
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
          builder: (context, _) => FamilyScreen(
            key: ValueKey('family-${state.locale}-$size-$scale'),
            state: state,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectNoVerticalScroll(WidgetTester tester, String tag) {
    final vertical = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (scrollable) =>
              scrollable.axisDirection == AxisDirection.down ||
              scrollable.axisDirection == AxisDirection.up,
        );
    expect(vertical, isEmpty, reason: '$tag must not scroll vertically');
  }

  Future<void> selectTab(WidgetTester tester, int index) async {
    tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .onDestinationSelected!(index);
    await tester.pumpAndSettle();
  }

  Future<void> findByHorizontalPaging(
    WidgetTester tester,
    String copy,
    String tag,
  ) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (find.text(copy).evaluate().isNotEmpty) return;
      final englishNext = find.byTooltip('Next section');
      final turkishNext = find.byTooltip('Sonraki bölüm');
      final next = englishNext.evaluate().isNotEmpty
          ? englishNext
          : turkishNext;
      final nextButton = find.ancestor(
        of: next,
        matching: find.byType(IconButton),
      );
      if (next.evaluate().isNotEmpty &&
          nextButton.evaluate().isNotEmpty &&
          tester.widget<IconButton>(nextButton.first).onPressed != null) {
        await tester.tap(nextButton.first);
      } else {
        final pages = find.byType(PageView);
        expect(
          pages,
          findsWidgets,
          reason: '$tag needs bounded horizontal pages',
        );
        await tester.drag(
          pages.first,
          Offset(-tester.view.physicalSize.width * .65, 0),
        );
      }
      await tester.pumpAndSettle();
    }
    expect(find.text(copy), findsWidgets, reason: '$tag copy reachable');
  }

  testWidgets('family sections stay bounded and text remains reachable', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await makeState();
    await loadFonts(tester);
    addTearDown(state.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    try {
      for (final locale in ['tr', 'en']) {
        state.locale = locale;
        for (final size in [const Size(800, 360), const Size(1280, 800)]) {
          for (final scale in [1.0, 1.6, 2.0]) {
            final tag = '$locale $size x$scale';
            await mount(tester, state, size, scale);
            expectNoVerticalScroll(tester, '$tag progress');
            expect(tester.takeException(), isNull, reason: '$tag progress');
            for (final button in find.byType(IconButton).evaluate()) {
              final finder = find.byElementPredicate(
                (element) => identical(element, button),
              );
              expect(tester.getRect(finder).height, greaterThanOrEqualTo(48));
            }
            expect(
              tester.getRect(find.byType(NavigationBar)).height,
              greaterThanOrEqualTo(48),
            );
            await findByHorizontalPaging(
              tester,
              locale == 'tr' ? 'İpucusuz doğru' : 'Independent answers',
              '$tag progress stats',
            );
            expectNoVerticalScroll(tester, '$tag progress stats');

            await selectTab(tester, 1);
            await findByHorizontalPaging(
              tester,
              locale == 'tr'
                  ? 'Yalnızca açık oyunları göster'
                  : 'Show unlocked games only',
              '$tag games',
            );
            expectNoVerticalScroll(tester, '$tag games');

            await selectTab(tester, 2);
            await findByHorizontalPaging(tester, 'Mina', '$tag profiles');
            await findByHorizontalPaging(
              tester,
              locale == 'tr' ? 'Daha fazla profil' : 'More profiles',
              '$tag profile limit',
            );
            expectNoVerticalScroll(tester, '$tag profiles');

            await selectTab(tester, 3);
            for (final copy in [
              locale == 'tr' ? 'Genel zorluk' : 'Default difficulty',
              locale == 'tr' ? 'Günlük dakika hedefi' : 'Daily minute goal',
              locale == 'tr' ? 'Ebeveyn kilidi' : 'Parent gate',
              locale == 'tr' ? 'Hareketleri azalt' : 'Reduce motion',
              locale == 'tr' ? 'Gizlilik' : 'Privacy',
            ]) {
              await findByHorizontalPaging(tester, copy, '$tag $copy');
              expectNoVerticalScroll(tester, '$tag $copy');
              expect(tester.takeException(), isNull, reason: '$tag $copy');
            }
            expect(find.byType(FittedBox), findsNothing, reason: tag);
            for (final text in tester.widgetList<Text>(find.byType(Text))) {
              expect(text.overflow, isNot(TextOverflow.ellipsis), reason: tag);
            }
            expect(tester.takeException(), isNull, reason: tag);
          }
        }
      }
    } finally {
      state.lockFamily();
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('family controls retain profile-scoped preferences and data', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await makeState();
    addTearDown(state.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await loadFonts(tester);
      state.locale = 'en';
      await mount(tester, state, const Size(800, 360), 2);
      await selectTab(tester, 3);
      await findByHorizontalPaging(tester, 'Reduce motion', 'reduce motion');
      final label = find.text('Reduce motion');
      await tester.tap(
        find.ancestor(of: label, matching: find.byType(SwitchListTile)).first,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(state.reducedMotion, isTrue);
      final profileId = state.active!.id;
      expect(
        await state.db.preference('profile.$profileId.reducedMotion'),
        'true',
      );
      expect(state.profiles, hasLength(1));
      expect(state.active!.nickname, 'Mina');
      expect(await state.db.preference('activeProfile'), profileId);
      expect(await state.db.preference('profile.$profileId.locale'), 'tr');
      expect(tester.takeException(), isNull);
    } finally {
      state.lockFamily();
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('parent PIN and profile deletion dialogs fit without scrolling', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await makeState();
    addTearDown(state.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await loadFonts(tester);
      state.locale = 'en';
      await mount(tester, state, const Size(800, 360), 2);
      await selectTab(tester, 3);
      await findByHorizontalPaging(tester, 'Parent gate', 'parent PIN entry');
      await tester.tap(find.text('Multiplication question'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expectNoVerticalScroll(tester, 'parent PIN dialog');
      expect(tester.takeException(), isNull, reason: 'parent PIN dialog');
      for (final text in ['4-digit PIN', 'Repeat PIN', 'Cancel', 'Save']) {
        final finder = find.text(text);
        expect(finder, findsOneWidget);
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(-0.5));
        expect(rect.top, greaterThanOrEqualTo(-0.5));
        expect(rect.right, lessThanOrEqualTo(800.5));
        expect(rect.bottom, lessThanOrEqualTo(360.5));
      }
      await tester.enterText(find.byType(TextField).at(0), '1234');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Save'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(state.hasParentPin, isTrue);

      await selectTab(tester, 2);
      await findByHorizontalPaging(tester, 'Mina', 'profile deletion entry');
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(state.tr('Profili sil', 'Delete profile')).last,
      );
      await tester.pumpAndSettle();
      expectNoVerticalScroll(tester, 'delete profile dialog');
      expect(
        find.text(
          state.tr(
            'Mina profilinin bu cihazdaki oyun ve gelişim kayıtları silinecek.',
            'Game and progress records for Mina will be deleted from this device.',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'delete profile dialog');
      await tester.tap(find.text(state.tr('Vazgeç', 'Cancel')));
      await tester.pumpAndSettle();
      expect(state.profiles, hasLength(1));
      expect(state.active!.nickname, 'Mina');
    } finally {
      state.lockFamily();
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('24-character profile name stays reachable in landscape dialogs', (
    tester,
  ) async {
    const nickname = 'ABCDEFGHIJKLMNOPQRSTUVWX';
    expect(nickname.length, 24);
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await makeState(nickname: nickname);
    addTearDown(state.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await loadFonts(tester);
      state.locale = 'en';
      await mount(tester, state, const Size(800, 360), 2);
      await selectTab(tester, 2);
      await findByHorizontalPaging(tester, nickname, '24-character profile');
      expectNoVerticalScroll(tester, '24-character profile label');
      final label = tester.getRect(find.text(nickname).first);
      expect(label.left, greaterThanOrEqualTo(-0.5));
      expect(label.top, greaterThanOrEqualTo(-0.5));
      expect(label.right, lessThanOrEqualTo(800.5));
      expect(label.bottom, lessThanOrEqualTo(360.5));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(state.tr('Profili sil', 'Delete profile')).last,
      );
      await tester.pumpAndSettle();
      expectNoVerticalScroll(tester, '24-character delete confirmation');
      final copy = state.tr(
        '$nickname profilinin bu cihazdaki oyun ve gelişim kayıtları silinecek.',
        'Game and progress records for $nickname will be deleted from this device.',
      );
      expect(find.text(copy), findsOneWidget);
      for (final text in [copy, 'Cancel']) {
        final rect = tester.getRect(find.text(text));
        expect(rect.left, greaterThanOrEqualTo(-0.5));
        expect(rect.top, greaterThanOrEqualTo(-0.5));
        expect(rect.right, lessThanOrEqualTo(800.5));
        expect(rect.bottom, lessThanOrEqualTo(360.5));
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(state.profiles.single.nickname, nickname);
      expect(state.active!.nickname, nickname);
    } finally {
      state.lockFamily();
      debugDefaultTargetPlatformOverride = null;
      await tester.pumpWidget(const SizedBox());
    }
  });
}
