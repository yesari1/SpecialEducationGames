import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/config/app_configuration.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/entitlement/entitlement_service.dart';
import 'package:special_education_games/core/entitlement/trial_store.dart';
import 'package:special_education_games/features/family/subscription_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

/// In-memory stand-in for `trials/{uid}`: created once, never changed.
class FakeTrialStore implements TrialStore {
  final Map<String, DateTime> starts = {};
  DateTime Function() clock;
  bool offline = false;
  int claims = 0;
  FakeTrialStore(this.clock);
  @override
  Future<DateTime?> read(String uid) async {
    if (offline) throw const TrialFailure(TrialIssue.offline);
    return starts[uid];
  }

  @override
  Future<DateTime> claim(String uid) async {
    if (offline) throw const TrialFailure(TrialIssue.offline);
    claims++;
    return starts.putIfAbsent(uid, clock);
  }
}

class FakeGoogle implements FamilyAuthBackend {
  FamilyAccount? next = const FamilyAccount('parent-1');
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() async => next;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EntitlementService', () {
    late DateTime now;
    late EntitlementService e;
    setUp(() {
      now = DateTime.utc(2026, 10, 20, 12);
      e = EntitlementService(
        AppDatabase.forTesting(NativeDatabase.memory()),
        now: () => now,
      );
    });

    test('free by default', () {
      expect(e.source, PremiumSource.none);
      expect(e.isPremium, isFalse);
      expect(e.trialUsed, isFalse);
    });

    test('trial opens everything for 7 days, then back to free', () async {
      await e.setTrial('u1', now);
      expect(e.source, PremiumSource.trial);
      expect(e.trialDaysLeft, 7);
      expect(e.isPaid, isFalse);
      now = now.add(const Duration(days: 6, hours: 23));
      expect(e.isPremium, isTrue);
      expect(e.trialDaysLeft, 1);
      now = now.add(const Duration(hours: 1));
      expect(e.isPremium, isFalse);
      expect(e.trialUsed, isTrue);
      expect(e.trialDaysLeft, 0);
    });

    test('trial length follows the remote config', () async {
      final short = EntitlementService(
        AppDatabase.forTesting(NativeDatabase.memory()),
        now: () => now,
        trialDaysOf: () => 3,
      );
      await short.setTrial('u1', now.subtract(const Duration(days: 3)));
      expect(short.isPremium, isFalse);
    });

    test(
      'subscription confirmed by Play wins and lasts a week offline',
      () async {
        await e.setTrial('u1', now);
        await e.confirmStoreState(true);
        expect(e.source, PremiumSource.subscription);
        expect(e.isPaid, isTrue);
        now = now.add(const Duration(days: 8));
        expect(e.source, PremiumSource.none);
      },
    );

    test('lifetime stays until Play reports it is gone', () async {
      await e.confirmStoreState(false, lifetime: true);
      now = now.add(const Duration(days: 400));
      expect(e.source, PremiumSource.lifetime);
      await e.confirmStoreState(false);
      expect(e.isPremium, isFalse);
    });

    test('state survives a restart from the database', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final first = EntitlementService(db, now: () => now);
      await first.setTrial('u1', now.subtract(const Duration(days: 2)));
      await first.confirmStoreState(false, lifetime: true);
      final again = EntitlementService(db, now: () => now);
      await again.load();
      expect(again.trialUid, 'u1');
      expect(again.trialDaysLeft, 5);
      expect(again.lifetimeOwned, isTrue);
    });
  });

  test('remote config: trialDays and https links are validated', () async {
    final content = await ContentRepository.load();
    final base = AppConfiguration.defaults(content);
    expect(base.trialDays, 7);
    final merged = base.merge({
      'trialDays': 14,
      'privacyUrl': 'https://example.org/privacy',
      'termsUrl': 'http://insecure.example.org',
    }, content);
    expect(merged.trialDays, 14);
    expect(merged.privacyUrl, 'https://example.org/privacy');
    // An insecure link is ignored: the default site page stays.
    expect(merged.termsUrl, AppConfiguration.defaultTermsUrl);
    expect(base.privacyUrl, AppConfiguration.defaultPrivacyUrl);
    expect(base.merge({'privacyUrl': ''}, content).privacyUrl, '');
    expect(base.merge({'trialDays': 90}, content).trialDays, 7);
  });

  group('AppState trial', () {
    late DateTime now;
    late FakeTrialStore store;
    late AppState state;
    setUp(() async {
      // Keeps the Play Billing plugin from connecting on the host.
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      now = DateTime.utc(2026, 10, 20, 12);
      store = FakeTrialStore(() => now);
      state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
        trialStore: store,
      );
      await state.load();
      await state.createProfile('Ada', 'cat', {});
    });
    tearDown(() {
      state.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    test('starting needs the parent gate and unlocks premium games', () async {
      expect(state.canPlay('animals', 'G01', Difficulty.hard), isFalse);
      await expectLater(state.startTrial('parent-1'), throwsStateError);
      state.unlockFamily();
      expect(await state.startTrial('parent-1'), isTrue);
      expect(state.entitlement.source, PremiumSource.trial);
      expect(state.canPlay('animals', 'G01', Difficulty.hard), isTrue);
    });

    test('the same account cannot start a second trial', () async {
      state.unlockFamily();
      store.starts['parent-1'] = DateTime.utc(2026, 9, 1);
      await state.syncTrial('parent-1');
      expect(state.entitlement.trialUsed, isTrue);
      expect(state.entitlement.isPremium, isFalse);
      expect(await state.startTrial('parent-1'), isFalse);
      expect(store.starts['parent-1'], DateTime.utc(2026, 9, 1));
    });

    test('offline start reports the issue and keeps the free tier', () async {
      state.unlockFamily();
      store.offline = true;
      expect(await state.startTrial('parent-1'), isFalse);
      expect(state.trialIssue, TrialIssue.offline);
      expect(state.entitlement.isPremium, isFalse);
    });
  });

  testWidgets(
    'paywall: sign in with Google, then the trial runs',
    (tester) async {
      await tester.runAsync(() async {
        for (final entry in {
          'Nunito': 'assets/fonts/Nunito.ttf',
          'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        }.entries) {
          await (FontLoader(
            entry.key,
          )..addFont(rootBundle.load(entry.value))).load();
        }
      });
      final store = FakeTrialStore(DateTime.now);
      final state = (await tester.runAsync(() async {
        final state = AppState(
          await ContentRepository.load(),
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
          trialStore: store,
        );
        await state.load();
        await state.createProfile('Ada', 'cat', {});
        state.unlockFamily();
        return state;
      }))!;
      addTearDown(state.dispose);
      final auth = FamilyAuth(
        backend: FakeGoogle(),
        parentAuthorized: () => state.familyUnlocked,
      );
      addTearDown(auth.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = lookupAppLocalizations(const Locale('en'));
      state.locale = 'en';
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ListenableBuilder(
            listenable: state,
            builder: (_, _) => SubscriptionScreen(state: state, auth: auth),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The trial is not a separate option: the one button carries it.
      expect(find.byKey(const ValueKey('paywall-option-trial')), findsNothing);
      expect(find.textContaining('Try free for'), findsOneWidget);
      final start = find.byKey(const ValueKey('paywall-continue'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(auth.account?.uid, 'parent-1');
      expect(store.claims, 1);
      expect(
        find.byKey(const ValueKey('paywall-trial-active')),
        findsOneWidget,
      );
      expect(find.text(l10n.paywallTrialActive(7)), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Let the sign-in timeout timer expire before the test ends.
      await tester.pumpWidget(const SizedBox.shrink());
      state.lockFamily();
      await tester.pump(const Duration(minutes: 10));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
