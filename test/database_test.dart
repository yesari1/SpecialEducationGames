import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/db/app_database.dart';

void main() {
  test(
    'Version-one profiles and progress survive the duration/session migration',
    () async {
      final db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (sqlite) {
            sqlite.execute(
              "CREATE TABLE profiles (id TEXT NOT NULL PRIMARY KEY, nickname TEXT NOT NULL, avatar TEXT NOT NULL DEFAULT 'cat', payload TEXT NOT NULL DEFAULT '{}')",
            );
            sqlite.execute(
              'CREATE TABLE preferences (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
            );
            sqlite.execute(
              'CREATE TABLE trials (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, profile_id TEXT NOT NULL, theme_id TEXT NOT NULL, game_id TEXT NOT NULL, target_id TEXT NOT NULL, difficulty TEXT NOT NULL, wrong_count INTEGER NOT NULL, max_hint INTEGER NOT NULL, latency_ms INTEGER NOT NULL, selected_ids TEXT NOT NULL, at INTEGER NOT NULL)',
            );
            sqlite.execute(
              "INSERT INTO profiles (id,nickname) VALUES ('old','Minik')",
            );
            sqlite.execute(
              "INSERT INTO trials (profile_id,theme_id,game_id,target_id,difficulty,wrong_count,max_hint,latency_ms,selected_ids,at) VALUES ('old','animals','G01','animals.cat','easy',0,0,1000,'[]',1792090000)",
            );
            sqlite.execute('PRAGMA user_version=1');
          },
        ),
      );
      expect((await db.select(db.profiles).get()).single.nickname, 'Minik');
      final trial = (await db.select(db.trials).get()).single;
      expect(trial.targetId, 'animals.cat');
      expect(trial.activeMs, 0);
      expect(trial.idleMs, 0);
      await db
          .into(db.gameSessions)
          .insert(
            GameSessionsCompanion.insert(
              id: 'session',
              profileId: 'old',
              themeId: 'animals',
              gameId: 'G01',
              difficulty: 'easy',
              startedAt: DateTime.now(),
            ),
          );
      expect((await db.select(db.gameSessions).get()).single.completed, false);
      await db.close();
    },
  );
  test('Profiles, language and trial history persist independently', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.profiles)
        .insert(ProfilesCompanion.insert(id: 'p1', nickname: 'Minik'));
    await db.setPreference('locale', 'en');
    await db
        .into(db.trials)
        .insert(
          TrialsCompanion.insert(
            profileId: 'p1',
            themeId: 'animals',
            gameId: 'G01',
            targetId: 'animals.cat',
            difficulty: 'easy',
            wrongCount: 2,
            maxHint: 4,
            latencyMs: 3000,
            selectedIds: '["animals.dog","animals.dog","animals.cat"]',
            at: DateTime(2026, 10, 15),
          ),
        );
    expect((await db.select(db.profiles).get()).single.nickname, 'Minik');
    expect(await db.preference('locale'), 'en');
    expect((await db.select(db.trials).get()).single.maxHint, 4);
    await db.close();
  });
}
