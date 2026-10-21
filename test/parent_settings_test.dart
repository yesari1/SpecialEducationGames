import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/play_time_ledger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Settings tests exercise local policy, not a native Play Billing connection.
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test(
    'Manual difficulty is parent guarded, profile scoped and respects downgrade',
    () async {
      final playTimeAt = DateTime(2026, 10, 17, 12);
      final state = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
        playTimeNow: () => playTimeAt,
      );
      addTearDown(state.dispose);
      await state.load();
      await state.createProfile('Bir', 'cat', {});
      await expectLater(
        state.setting('difficultyOverride', 'medium'),
        throwsStateError,
      );
      state.unlockFamily();
      await expectLater(
        state.setting('screenLimitMinutes', '5'),
        throwsArgumentError,
      );
      await state.setting('screenLimitMinutes', '10');
      await state.chargePlayTime(state.active!.id, 600000);
      expect(state.playTimeExpired, true);
      state.lockFamily();
      await expectLater(state.extendPlayTime(), throwsStateError);
      await expectLater(
        state.setting('screenLimitMinutes', '0'),
        throwsStateError,
      );
      state.unlockFamily();
      await state.extendPlayTime();
      expect(state.playTimeRemainingMs, 600000);
      await expectLater(
        state.setting('difficultyOverride', 'unknown'),
        throwsArgumentError,
      );
      await expectLater(
        state.setting('difficultyOverride', 'hard'),
        throwsStateError,
      );
      await state.setting('difficultyOverride', 'medium');
      // Free cards are Easy only, so the choice waits for Premium.
      expect(
        state.recommendedDifficulty('animals', 'G01', Difficulty.easy),
        Difficulty.easy,
      );
      await state.entitlement.confirmStoreState(
        true,
      ); // Memory DB fixture only.
      final first = state.active!;
      await state.setting('difficultyOverride', 'hard');
      expect(
        state.recommendedDifficulty('animals', 'G01', Difficulty.easy),
        Difficulty.hard,
      );
      await state.createProfile('İki', 'dog', {});
      expect(state.screenLimitMinutes, 0);
      expect(state.dailyPlayTime.usedMs, 0);
      expect(state.difficultyOverride, 'auto');
      await state.selectProfile(first);
      expect(state.screenLimitMinutes, 10);
      expect(state.playTimeRemainingMs, 600000);
      expect(state.difficultyOverride, 'hard');
      await state.entitlement.confirmStoreState(false);
      await state.load();
      expect(state.difficultyOverride, 'auto');
      expect(
        state.recommendedDifficulty('animals', 'G01', Difficulty.easy),
        Difficulty.easy,
      );
      // Keep the parent's preference for a later subscription restoration.
      expect(
        await state.db.preference('profile.${first.id}.difficultyOverride'),
        'hard',
      );
    },
  );

  test(
    'Play-time allowance rolls over while preserving the prior day ledger',
    () async {
      var playTimeAt = DateTime(2026, 10, 17, 12);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final state = AppState(
        await ContentRepository.load(),
        db,
        AudioService(),
        playTimeNow: () => playTimeAt,
      );
      addTearDown(state.dispose);
      await state.load();
      await state.createProfile('Bir', 'cat', {});
      state.unlockFamily();
      await state.setting('screenLimitMinutes', '10');

      final profileId = state.active!.id;
      await state.chargePlayTime(profileId, 600000);
      expect(state.dailyPlayTime.usedMs, 600000);
      expect(state.playTimeExpired, isTrue);

      playTimeAt = DateTime(2026, 10, 18, 0, 1);
      await state.load();
      expect(state.dailyPlayTime.usedMs, 0);
      expect(state.playTimeRemainingMs, 600000);
      expect(state.playTimeExpired, isFalse);
      expect(
        await db.preference(
          'profile.$profileId.playTime.${PlayTimeLedger.dayKey(DateTime(2026, 10, 17, 12))}',
        ),
        contains('"usedMs":600000'),
      );
    },
  );
}
