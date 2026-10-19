import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'app_database.g.dart';

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text()();
  TextColumn get avatar => text().withDefault(const Constant('cat'))();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  @override
  Set<Column> get primaryKey => {id};
}

class Trials extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get profileId => text()();
  TextColumn get themeId => text()();
  TextColumn get gameId => text()();
  TextColumn get targetId => text()();
  TextColumn get difficulty => text()();
  IntColumn get wrongCount => integer()();
  IntColumn get maxHint => integer()();
  IntColumn get latencyMs => integer()();
  IntColumn get idleMs => integer().withDefault(const Constant(0))();
  IntColumn get activeMs => integer().withDefault(const Constant(0))();
  TextColumn get selectedIds => text()();
  DateTimeColumn get at => dateTime()();
}

class GameSessions extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get themeId => text()();
  TextColumn get gameId => text()();
  TextColumn get difficulty => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get activeMs => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Profiles, Trials, Preferences, GameSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'special_education_games'));
  AppDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(trials, trials.idleMs);
        await m.addColumn(trials, trials.activeMs);
        await m.createTable(gameSessions);
      }
    },
  );
  Future<String?> preference(String key) async => (await (select(
    preferences,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;
  Future<void> setPreference(String key, String value) => into(
    preferences,
  ).insertOnConflictUpdate(PreferencesCompanion.insert(key: key, value: value));
}
