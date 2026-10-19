import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/sync/summary_export.dart';
import 'package:special_education_games/core/sync/summary_snapshot_cache.dart';
import 'package:special_education_games/core/sync/summary_sync.dart';
import 'package:special_education_games/features/family/family_summary_sync_card.dart';

class _Backend implements FamilyAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => const FamilyAccount('parent');
  @override
  Future<FamilyAccount?> signIn() => restore();
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

class _Store implements SummaryStore {
  int fetches = 0, merges = 0;
  Completer<List<SummaryDocument>>? pending;
  @override
  Future<List<SummaryDocument>> fetch(
    String uid,
    String profileId, {
    required bool Function() stillAuthorized,
  }) async {
    fetches++;
    return pending == null ? [] : pending!.future;
  }

  @override
  Future<List<DailySessionSummary>> merge(
    String uid,
    String profileId,
    List<DailySessionSummary> summaries, {
    required DateTime now,
    required bool Function() stillAuthorized,
  }) async {
    merges++;
    expect(stillAuthorized(), isTrue);
    return summaries;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());
  Future<(AppState, FamilyAuth, _Store)> setup(WidgetTester tester) async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Local child', 'cat', {});
    state.unlockFamily();
    final auth = FamilyAuth(
      backend: _Backend(),
      parentAuthorized: () => state.familyUnlocked,
    );
    await auth.signIn();
    final store = _Store();
    addTearDown(() {
      auth.dispose();
      state.dispose();
    });
    return (state, auth, store);
  }

  Future<void> show(
    WidgetTester tester,
    AppState state,
    FamilyAuth auth,
    _Store store, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: FamilySummarySyncCard(
              state: state,
              auth: auth,
              store: store,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pageTo(WidgetTester tester, String key, Finder finder) async {
    final target = key == 'summary-consent'
        ? 2
        : key == 'summary-sync'
        ? 3
        : key == 'summary-snapshot'
        ? 4
        : 0;
    for (var i = 0; i < 5 && finder.evaluate().isEmpty; i++) {
      final pageLabel = find.byWidgetPredicate(
        (widget) =>
            widget is Text && RegExp(r'^\d / 5$').hasMatch(widget.data ?? ''),
      );
      final current = pageLabel.evaluate().isEmpty
          ? 0
          : int.parse(tester.widget<Text>(pageLabel).data!.split(' ').first) -
                1;
      await tester.tap(
        find.byTooltip(current < target ? 'Next page' : 'Previous page'),
      );
      await tester.pumpAndSettle();
    }
    if (finder.evaluate().isNotEmpty) await tester.ensureVisible(finder);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await pageTo(tester, key, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'No automatic network; explicit consent and action; revocation clears snapshot only',
    (tester) async {
      final (state, auth, store) = await setup(tester);
      await show(tester, state, auth, store);
      expect(store.fetches, 0);
      await tap(tester, 'summary-sync');
      expect(store.fetches, 0);
      await tap(tester, 'summary-consent');
      expect(store.fetches, 0);
      await tap(tester, 'summary-sync');
      expect(store.fetches, 1);
      expect(store.merges, 1);
      expect(find.byKey(const ValueKey('summary-snapshot')), findsOneWidget);
      final cache = SummarySnapshotCache(state.db);
      expect(await cache.load('parent', state.active!.id), isNotNull);
      await tap(tester, 'summary-consent');
      expect(await cache.load('parent', state.active!.id), isNull);
      expect(state.profiles.single.nickname, 'Local child');
      expect(find.byKey(const ValueKey('summary-snapshot')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.lockFamily();
    },
  );

  testWidgets(
    'Programmatic sync result page honors AppState and MediaQuery reduced motion',
    (tester) async {
      for (final scenario in [
        (reducedMotion: true, disableAnimations: false),
        (reducedMotion: false, disableAnimations: true),
      ]) {
        final (state, auth, store) = await setup(tester);
        await state.setting('reducedMotion', scenario.reducedMotion.toString());
        await show(
          tester,
          state,
          auth,
          store,
          disableAnimations: scenario.disableAnimations,
        );
        expect(store.fetches, 0, reason: 'Viewing the card must not sync.');
        final pages = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        await pageTo(
          tester,
          'summary-consent',
          find.byKey(const ValueKey('summary-consent')),
        );
        await tester.tap(find.byKey(const ValueKey('summary-consent')));
        await tester.pumpAndSettle();
        expect(store.fetches, 0);
        await pageTo(
          tester,
          'summary-sync',
          find.byKey(const ValueKey('summary-sync')),
        );
        await tester.tap(find.byKey(const ValueKey('summary-sync')));
        await tester.pumpAndSettle();
        expect(store.fetches, 1);
        expect(store.merges, 1);
        expect(pages.page!.round(), 4);
        expect(find.byKey(const ValueKey('summary-snapshot')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.lockFamily();
      }
    },
  );

  testWidgets('Parent lock cancels pending response and resets permission', (
    tester,
  ) async {
    final (state, auth, store) = await setup(tester);
    store.pending = Completer<List<SummaryDocument>>();
    await show(tester, state, auth, store);
    await tap(tester, 'summary-consent');
    await pageTo(
      tester,
      'summary-sync',
      find.byKey(const ValueKey('summary-sync')),
    );
    await tester.tap(find.byKey(const ValueKey('summary-sync')));
    await tester.pump();
    expect(store.fetches, 1);
    state.lockFamily();
    await tester.pump();
    store.pending!.complete([]);
    await tester.pumpAndSettle();
    expect(store.merges, 0);
    expect(find.byKey(const ValueKey('summary-snapshot')), findsNothing);
    state.unlockFamily();
    await tester.pumpAndSettle();
    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('summary-consent')),
    );
    expect(checkbox.value, isFalse);
    await tester.pumpWidget(const SizedBox());
    state.lockFamily();
  });

  testWidgets(
    'Logout cancels pending result and clears previous downloaded scope',
    (tester) async {
      final (state, auth, store) = await setup(tester);
      final profile = state.active!.id;
      await SummarySnapshotCache(state.db).save('parent', profile, []);
      store.pending = Completer<List<SummaryDocument>>();
      await show(tester, state, auth, store);
      await tap(tester, 'summary-consent');
      await pageTo(
        tester,
        'summary-sync',
        find.byKey(const ValueKey('summary-sync')),
      );
      await tester.tap(find.byKey(const ValueKey('summary-sync')));
      await tester.pump();
      await auth.signOut();
      store.pending!.complete([]);
      await tester.pumpAndSettle();
      expect(store.merges, 0);
      expect(
        await SummarySnapshotCache(state.db).load('parent', profile),
        isNull,
      );
      expect(find.byKey(const ValueKey('summary-snapshot')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      state.lockFamily();
    },
  );

  testWidgets('TR and EN landscape layouts fit without overflow', (
    tester,
  ) async {
    final (state, auth, store) = await setup(tester);
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 1;
    for (final locale in ['tr', 'en']) {
      state.locale = locale;
      for (final size in [const Size(800, 360), const Size(1280, 800)]) {
        tester.view.physicalSize = size;
        await show(tester, state, auth, store);
        await pageTo(
          tester,
          'summary-sync',
          find.byKey(const ValueKey('summary-sync')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
    expect(store.fetches, 0);
    await tester.pumpWidget(const SizedBox());
    state.lockFamily();
  });

  for (final change in ['revoke', 'profile']) {
    testWidgets(
      '$change cancels late response without uploading or publishing',
      (tester) async {
        final (state, auth, store) = await setup(tester);
        store.pending = Completer<List<SummaryDocument>>();
        await show(tester, state, auth, store);
        await tap(tester, 'summary-consent');
        await pageTo(
          tester,
          'summary-sync',
          find.byKey(const ValueKey('summary-sync')),
        );
        await tester.tap(find.byKey(const ValueKey('summary-sync')));
        await tester.pump();
        if (change == 'revoke') {
          await pageTo(
            tester,
            'summary-consent',
            find.byKey(const ValueKey('summary-consent')),
          );
          await tester.tap(find.byKey(const ValueKey('summary-consent')));
        } else {
          await state.entitlement.confirmStoreState(true);
          await state.createProfile('Second local child', 'dog', {});
        }
        await tester.pump();
        store.pending!.complete([]);
        await tester.pumpAndSettle();
        expect(store.fetches, 1);
        expect(store.merges, 0);
        expect(find.byKey(const ValueKey('summary-snapshot')), findsNothing);
        expect(
          tester
              .widget<CheckboxListTile>(
                find.byKey(const ValueKey('summary-consent')),
              )
              .value,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox());
        state.lockFamily();
      },
    );
  }
}
