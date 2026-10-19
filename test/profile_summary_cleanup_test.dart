import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/sync/summary_snapshot_cache.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/family_account_screen.dart';

class _SignedInBackend implements FamilyAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => const FamilyAccount('account-a');
  @override
  Future<FamilyAccount?> signIn() => restore();
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> createState() async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.db.setPreference('locale', 'en');
    await state.load();
    await state.createProfile('First', 'cat', {});
    state.unlockFamily();
    await state.entitlement.confirmStoreState(true);
    await state.createProfile('Second', 'dog', {});
    return state;
  }

  Future<void> addTrial(AppState state, String profile) => state.record(
    TrialsCompanion.insert(
      profileId: profile,
      themeId: 'animals',
      gameId: 'G01',
      targetId: 'cat',
      difficulty: 'easy',
      wrongCount: 0,
      maxHint: 0,
      latencyMs: 1200,
      activeMs: const Value(1200),
      selectedIds: '["cat"]',
      at: DateTime.now(),
    ),
  );

  test(
    'Deleting a profile removes imported copies across accounts while preserving other profiles and raw records',
    () async {
      final state = await createState();
      addTearDown(state.dispose);
      final first = state.profiles.first.id;
      final second = state.profiles.last.id;
      final cache = SummarySnapshotCache(state.db);
      for (final account in ['account-a', 'account-b']) {
        await cache.save(account, first, []);
        await cache.save(account, second, []);
      }
      await addTrial(state, first);
      await addTrial(state, second);
      state.lockFamily();
      await expectLater(state.deleteProfile(first), throwsStateError);
      expect(await cache.load('account-a', first), isNotNull);
      state.unlockFamily();
      await state.deleteProfile(first);
      for (final account in ['account-a', 'account-b']) {
        expect(await cache.load(account, first), isNull);
        expect(await cache.load(account, second), isNotNull);
      }
      expect(state.profiles.single.id, second);
      final trials = await state.db.select(state.db.trials).get();
      expect(trials.single.profileId, second);
    },
  );

  testWidgets(
    'App-owned logout clears all imported profiles when account card is unmounted, preserving other account and raw records',
    (tester) async {
      final state = await createState();
      final cache = SummarySnapshotCache(state.db);
      final profiles = state.profiles.map((p) => p.id).toList();
      await addTrial(state, profiles.first);
      await tester.pumpWidget(
        EducationApp(state: state, familyAuthBackend: _SignedInBackend()),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/family/account');
      await tester.pumpAndSettle();
      final auth = tester
          .widget<FamilyAccountScreen>(find.byType(FamilyAccountScreen))
          .auth;
      expect(auth.account?.uid, 'account-a');
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.byType(FamilyAccountScreen), findsNothing);
      for (final account in ['account-a', 'account-b']) {
        for (final profile in profiles) {
          await cache.save(account, profile, []);
        }
      }
      await auth.signOut();
      await tester.pumpAndSettle();
      for (final profile in profiles) {
        expect(await cache.load('account-a', profile), isNull);
        expect(await cache.load('account-b', profile), isNotNull);
      }
      expect(state.profiles, hasLength(2));
      expect(
        (await state.db.select(state.db.trials).get()).single.profileId,
        profiles.first,
      );
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
