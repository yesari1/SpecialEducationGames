import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

class _Backend implements AudioBackend {
  final loaded = <String>[];
  @override
  Future<Duration?> setAsset(String asset) async {
    loaded.add(asset);
    return Duration.zero;
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<(AppState, _Backend)> pumpHome(WidgetTester tester, String loc) async {
    final backend = _Backend();
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(backend: backend),
    );
    await state.load();
    await state.createProfile('Ada', 'cat', {});
    state.locale = loc;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(923, 411);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        locale: Locale(loc),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: HomeScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();
    return (state, backend);
  }

  for (final loc in ['tr', 'en']) {
    testWidgets('$loc: the three tabs switch and speak their name', (
      tester,
    ) async {
      final (state, backend) = await pumpHome(tester, loc);
      final l10n = lookupAppLocalizations(Locale(loc));
      expect(find.byKey(const ValueKey('home-mascot')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-stickers')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-family')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-tab-stories')));
      await tester.pumpAndSettle();
      expect(state.homeTab, HomeTab.stories);
      expect(backend.loaded.last, 'assets/audio/$loc/sections/tab_stories.mp3');
      expect(find.text(l10n.homeTabStories), findsOneWidget);
      expect(find.text(l10n.homeTabLearn), findsNothing);
      expect(
        find.byKey(ValueKey('story-card-${content.stories.first.id}')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('home-tab-park')));
      await tester.pumpAndSettle();
      expect(state.homeTab, HomeTab.park);
      expect(backend.loaded.last, 'assets/audio/$loc/sections/tab_park.mp3');
      expect(find.text(l10n.parkBubbles), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets('Learn starts with the first row, closed themes hidden', (
    tester,
  ) async {
    final (state, _) = await pumpHome(tester, 'tr');
    final l10n = lookupAppLocalizations(const Locale('tr'));
    final list = find.byKey(const ValueKey('home-learn-list'));
    expect(find.text(l10n.homeRowAnimalsFood), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-map')), findsNothing);
    // Every open theme sits in exactly one row or in the Play Park.
    final inRows = homeRows(l10n).expand((r) => r.$2).toSet();
    for (final t in content.themes) {
      expect(inRows.contains(t.id) || t.id == 'music', isTrue, reason: t.id);
    }
    await tester.dragUntilVisible(
      find.text(l10n.homeRowHomeOutside),
      list,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.homeRowHomeOutside), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
