import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:drift/drift.dart';
import '../core/content/content_repository.dart';
import '../core/db/app_database.dart';
import '../core/audio/audio_service.dart';
import '../core/entitlement/entitlement_service.dart';
import '../core/entitlement/billing_repository.dart';
import '../core/learning/policies.dart';
import '../core/learning/item_performance.dart';
import '../core/learning/play_time_ledger.dart';
import '../core/learning/parent_pin.dart';
import '../core/learning/daily_path.dart';
import '../core/config/app_configuration.dart';
import '../core/config/config_repository.dart';
import '../core/sync/summary_snapshot_cache.dart';

class AppState extends ChangeNotifier {
  final ContentRepository content;
  final AppDatabase db;
  final AudioService audio;
  late final EntitlementService entitlement;
  late final BillingRepository billing;
  late AppConfiguration configuration;
  late final ConfigRepository configs;
  AppConfiguration? _pendingConfiguration;
  int _activeGames = 0;
  bool _disposed = false;
  int _refreshGeneration = 0;
  void enterGame() => _activeGames++;
  void leaveGame() {
    _activeGames = (_activeGames - 1).clamp(0, 100);
    scheduleMicrotask(() {
      if (_disposed || _activeGames != 0 || _pendingConfiguration == null) {
        return;
      }
      configuration = _pendingConfiguration!;
      _pendingConfiguration = null;
      notifyListeners();
    });
  }

  Future<void> refreshConfiguration(ConfigFetcher fetch) async {
    final next = await configs.refresh(fetch);
    if (_disposed || next == null) return;
    if (_activeGames > 0) {
      _pendingConfiguration = next;
      return;
    }
    configuration = next;
    notifyListeners();
  }

  List<String> gamesForTheme(String theme) =>
      (configuration.gameOrder[theme] ?? content.theme(theme).games)
          .where((g) => !configuration.disabledGames.contains('${theme}_$g'))
          .toList();
  List<Profile> profiles = [];
  List<Trial> trials = [];
  List<GameSession> sessions = [];
  Set<String> _dailyStickers = {};
  String? _stickerProfileId;
  Set<String> get dailyStickers => _stickerProfileId == active?.id
      ? Set.unmodifiable(_dailyStickers)
      : const {};
  List<String> get dailyPathSteps => configuration.freeGames.where((key) {
    final parts = key.split('_');
    if (parts.length != 2) return false;
    final effectiveDifficulty = recommendedDifficulty(
      parts[0],
      parts[1],
      Difficulty.easy,
    );
    return parts.length == 2 &&
        canPlay(parts[0], parts[1], Difficulty.easy) &&
        content.isGameContentAvailable(
          parts[0],
          parts[1],
          effectiveDifficulty,
        ) &&
        hasRequiredGameAudio(parts[0], parts[1]);
  }).toList()..sort();
  DailyPathProgress dailyPathAt(DateTime now) => DailyPathProgress.fromSessions(
    steps: dailyPathSteps,
    sessions: sessions,
    profileId: active?.id ?? '',
    now: now,
  );
  DailyPathProgress get dailyPath => dailyPathAt(DateTime.now());
  bool get hasTodaySticker =>
      dailyStickers.contains(DailyPathProgress.dayKey(DateTime.now()));
  Set<String> introduced = {};
  bool introduction = true, automaticDifficulty = true;
  Profile? active;
  String locale = 'tr';
  bool onlyFree = false, showLabels = true, sound = true, reducedMotion = false;
  int speechVolume = 100, effectVolume = 60;
  bool hasRequiredGameAudio(String theme, String game) =>
      // G11 compares natural sounds, so effects must be audible.
      (game == 'G11' && sound && effectVolume > 0) ||
      (game != 'G10' && game != 'G11') ||
      (sound &&
          (theme == 'animals' || theme == 'vehicles'
              ? effectVolume > 0
              : speechVolume > 0) &&
          content.hasLocalizedG10Content(theme, Difficulty.easy, locale));
  String celebration = 'simple';
  int dailyGoalMinutes = 0;
  int screenLimitMinutes = 0;
  late final PlayTimeLedger playTime;
  final DateTime Function() _playTimeNow;
  DailyPlayTime _dailyPlayTime = const DailyPlayTime();
  String _playTimeDay = '';
  DailyPlayTime get dailyPlayTime =>
      _playTimeDay == PlayTimeLedger.dayKey(_playTimeNow())
      ? _dailyPlayTime
      : const DailyPlayTime();
  void _setPlayTime(DailyPlayTime value) {
    _dailyPlayTime = value;
    _playTimeDay = PlayTimeLedger.dayKey(_playTimeNow());
  }

  int get playTimeRemainingMs => dailyPlayTime.remainingMs(screenLimitMinutes);
  bool get playTimeExpired => playTimeRemainingMs == 0;
  Future<void> chargePlayTime(String profileId, int milliseconds) async {
    final next = await playTime.charge(profileId, milliseconds);
    if (_disposed || active?.id != profileId) return;
    _setPlayTime(next);
    notifyListeners();
  }

  Future<void> extendPlayTime() async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    final profile = active?.id;
    if (profile == null) return;
    final next = await playTime.extend(profile, 10);
    if (_disposed || active?.id != profile) return;
    _setPlayTime(next);
    notifyListeners();
  }

  int roundLength = 0, hintSeconds = -1;
  bool fadeWrongChoices = true;
  String difficultyOverride = 'auto';
  String? _parentPinHash, _parentPinSalt;
  bool get hasParentPin => _parentPinHash != null && _parentPinSalt != null;
  bool verifyParentPin(String candidate) =>
      hasParentPin &&
      ParentPin.verify(candidate, _parentPinSalt!, _parentPinHash!);
  Future<void> setParentPin(String pin) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    final salt = ParentPin.newSalt();
    await db.setPreference('parentPinSalt', salt);
    await db.setPreference('parentPinHash', ParentPin.hash(pin, salt));
    await load();
  }

  Future<void> clearParentPin() async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    await (db.delete(
      db.preferences,
    )..where((p) => p.key.isIn(['parentPinSalt', 'parentPinHash']))).go();
    await load();
  }

  Future<String?> _readSetting(String key) async => active == null
      ? await db.preference(key)
      : (await db.preference('profile.${active!.id}.$key') ??
            await db.preference(key));
  DateTime? _familyUntil;
  Timer? _lockTimer;
  AppState(
    this.content,
    this.db,
    this.audio, {
    DateTime Function()? playTimeNow,
  }) : _playTimeNow = playTimeNow ?? DateTime.now {
    playTime = PlayTimeLedger(db, now: _playTimeNow);
    configuration = AppConfiguration.defaults(content);
    configs = ConfigRepository(db, content);
    entitlement = EntitlementService(db);
    billing = BillingRepository(entitlement);
    billing.addListener(notifyListeners);
  }
  String tr(String turkish, String english) =>
      locale == 'tr' ? turkish : english;
  List<ContentTheme> get orderedThemes {
    final favorites = SurveyMapper.favorites(
      jsonDecode(active?.payload ?? '{}'),
    );
    final themes = content.themes
        .where((t) => !configuration.hiddenThemes.contains(t.id))
        .toList();
    themes.sort((a, b) {
      if (a.id == b.id) return 0;
      if (a.id == configuration.featuredTheme) return -1;
      if (b.id == configuration.featuredTheme) return 1;
      final ai = favorites.indexOf(a.id), bi = favorites.indexOf(b.id);
      return (ai < 0 ? 100 + content.themes.indexOf(a) : ai).compareTo(
        bi < 0 ? 100 + content.themes.indexOf(b) : bi,
      );
    });
    return themes;
  }

  bool get familyUnlocked =>
      _familyUntil != null && DateTime.now().isBefore(_familyUntil!);
  void unlockFamily() {
    touchFamily();
    notifyListeners();
  }

  void touchFamily() {
    _familyUntil = DateTime.now().add(const Duration(minutes: 5));
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(minutes: 5), lockFamily);
  }

  void lockFamily() {
    _familyUntil = null;
    _lockTimer?.cancel();
    notifyListeners();
  }

  bool canPlay(String theme, String game, Difficulty tier) =>
      !configuration.hiddenThemes.contains(theme) &&
      !configuration.disabledGames.contains('${theme}_$game') &&
      (entitlement.isPremium ||
          (tier != Difficulty.hard &&
              configuration.freeGames.contains('${theme}_$game')));
  Future<void> load() async {
    if (_activeGames == 0) configuration = await configs.load();
    await entitlement.load();
    profiles = await (db.select(
      db.profiles,
    )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
    final selected = await db.preference('activeProfile');
    active =
        profiles.where((p) => p.id == selected).firstOrNull ??
        profiles.firstOrNull;
    if (!entitlement.isPremium && profiles.isNotEmpty) active = profiles.first;
    _parentPinHash = await db.preference('parentPinHash');
    _parentPinSalt = await db.preference('parentPinSalt');
    final savedLocale = await _readSetting('locale');
    if (savedLocale == 'tr' || savedLocale == 'en') {
      locale = savedLocale!;
    } else {
      locale =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr'
          ? 'tr'
          : 'en';
      // Choose once on first launch; later language changes belong in Settings.
      await db.setPreference('locale', locale);
    }
    onlyFree = await db.preference('onlyFree') == 'true';
    showLabels = await _readSetting('showLabels') != 'false';
    sound = await _readSetting('sound') != 'false';
    final savedSpeech = int.tryParse(
      await _readSetting('speechVolume') ?? '100',
    );
    final savedEffect = int.tryParse(
      await _readSetting('effectVolume') ?? '60',
    );
    speechVolume = savedSpeech != null && savedSpeech >= 0 && savedSpeech <= 100
        ? savedSpeech
        : 100;
    effectVolume = savedEffect != null && savedEffect >= 0 && savedEffect <= 100
        ? savedEffect
        : 60;
    await audio.updatePreferences(
      enabled: sound,
      speechVolume: speechVolume,
      effectVolume: effectVolume,
    );
    celebration = await _readSetting('celebration') ?? 'simple';
    introduction = await _readSetting('introduction') != 'false';
    automaticDifficulty = await _readSetting('automaticDifficulty') != 'false';
    reducedMotion = await _readSetting('reducedMotion') == 'true';
    final savedLength = int.tryParse(await _readSetting('roundLength') ?? '0');
    roundLength = [0, 3, 5, 8, 10].contains(savedLength) ? savedLength! : 0;
    final savedHint = int.tryParse(await _readSetting('hintSeconds') ?? '-1');
    hintSeconds = [-1, 0, 4, 6, 10].contains(savedHint) ? savedHint! : -1;
    fadeWrongChoices = await _readSetting('fadeWrongChoices') != 'false';
    final savedDifficulty = await _readSetting('difficultyOverride') ?? 'auto';
    difficultyOverride =
        ['auto', 'easy', 'medium', 'hard'].contains(savedDifficulty) &&
            (savedDifficulty != 'hard' || entitlement.isPremium)
        ? savedDifficulty
        : 'auto';
    final savedGoal = int.tryParse(
      await _readSetting('dailyGoalMinutes') ?? '0',
    );
    dailyGoalMinutes = [0, 10, 15, 20, 30].contains(savedGoal) ? savedGoal! : 0;
    final savedLimit = int.tryParse(
      await _readSetting('screenLimitMinutes') ?? '0',
    );
    screenLimitMinutes = [0, 10, 15, 20, 30].contains(savedLimit)
        ? savedLimit!
        : 0;
    final savedIntroductions = active == null
        ? null
        : await db.preference('introduced.${active!.id}');
    introduced = savedIntroductions == null
        ? {}
        : Set<String>.from(jsonDecode(savedIntroductions));
    await refreshTrials();
    final profileId = active?.id;
    final nextTime = profileId == null
        ? const DailyPlayTime()
        : await playTime.load(
            profileId,
            seedMs: sessions
                .where(
                  (x) => DateUtilsHelper.sameDay(x.startedAt, DateTime.now()),
                )
                .fold<int>(0, (sum, x) => sum + x.activeMs),
          );
    if (_disposed || active?.id != profileId) return;
    _setPlayTime(nextTime);
    notifyListeners();
  }

  Future<void> refreshTrials() async {
    final generation = ++_refreshGeneration;
    final profileId = active?.id;
    final List<Trial> nextTrials = profileId == null
        ? []
        : await (db.select(
            db.trials,
          )..where((t) => t.profileId.equals(profileId))).get();
    final List<GameSession> nextSessions = profileId == null
        ? []
        : await (db.select(
            db.gameSessions,
          )..where((t) => t.profileId.equals(profileId))).get();
    if (_disposed ||
        generation != _refreshGeneration ||
        profileId != active?.id) {
      return;
    }
    trials = nextTrials;
    sessions = nextSessions;
    final stickerKey = 'profile.$profileId.dailyStickers';
    final storedStickers = await db.preference(stickerKey);
    if (_disposed ||
        generation != _refreshGeneration ||
        profileId != active?.id) {
      return;
    }
    try {
      _dailyStickers = (jsonDecode(storedStickers ?? '[]') as List)
          .whereType<String>()
          .where(
            (day) => DailyPathProgress.validStickerDay(day, DateTime.now()),
          )
          .toSet();
    } on FormatException {
      _dailyStickers = {};
    } on TypeError {
      _dailyStickers = {};
    }
    _stickerProfileId = profileId;
    if (profileId != null && dailyPath.complete) {
      _dailyStickers.add(DailyPathProgress.dayKey(DateTime.now()));
      await db.setPreference(
        stickerKey,
        jsonEncode(_dailyStickers.toList()..sort()),
      );
      if (_disposed ||
          generation != _refreshGeneration ||
          profileId != active?.id) {
        return;
      }
    }
    introduced.addAll(trials.map((t) => t.targetId));
    notifyListeners();
  }

  Future<void> createProfile(
    String name,
    String avatar,
    Map<String, dynamic> survey,
  ) async {
    if (profiles.isNotEmpty && !familyUnlocked) {
      throw StateError('parent_gate_required');
    }
    name = name.trim();
    if (name.isEmpty ||
        name.length > 24 ||
        !['cat', 'dog', 'rabbit', 'bear'].contains(avatar)) {
      throw ArgumentError('invalid_profile');
    }
    if (profiles.length >= (entitlement.isPremium ? 5 : 1)) {
      throw StateError('profile_limit');
    }
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await db
        .into(db.profiles)
        .insert(
          ProfilesCompanion.insert(
            id: id,
            nickname: name,
            avatar: Value(avatar),
            payload: Value(jsonEncode(survey)),
          ),
        );
    await db.setPreference('activeProfile', id);
    await _applySurveySettings(id, survey, {});
    await load();
  }

  /// First-run setup made by the parent in onboarding: the child profile plus
  /// the daily goal and optional PIN chosen there. Same guard as
  /// [createProfile], so it cannot be replayed to bypass the parent gate.
  Future<void> completeOnboarding({
    required String name,
    required Map<String, dynamic> survey,
    int? dailyGoalMinutes,
    String? pin,
  }) async {
    if (profiles.isNotEmpty && !familyUnlocked) {
      throw StateError('parent_gate_required');
    }
    if (dailyGoalMinutes != null && ![10, 15, 20].contains(dailyGoalMinutes)) {
      throw ArgumentError('dailyGoalMinutes');
    }
    if (pin != null && !ParentPin.valid(pin)) throw ArgumentError('pin');
    await createProfile(name, 'cat', survey);
    final id = active!.id;
    if (dailyGoalMinutes != null) {
      await db.setPreference(
        'profile.$id.dailyGoalMinutes',
        '$dailyGoalMinutes',
      );
    }
    if (pin != null) {
      final salt = ParentPin.newSalt();
      await db.setPreference('parentPinSalt', salt);
      await db.setPreference('parentPinHash', ParentPin.hash(pin, salt));
    }
    await load();
  }

  Future<void> setting(String key, String value) async {
    if (key == 'speechVolume' || key == 'effectVolume') {
      if (!familyUnlocked) throw StateError('parent_gate_required');
      final volume = int.tryParse(value);
      if (volume == null || volume < 0 || volume > 100) {
        throw ArgumentError(key);
      }
    }
    if ([
      'roundLength',
      'hintSeconds',
      'fadeWrongChoices',
      'difficultyOverride',
    ].contains(key)) {
      if (!familyUnlocked) throw StateError('parent_gate_required');
      final valid = switch (key) {
        'roundLength' => [0, 3, 5, 8, 10].contains(int.tryParse(value)),
        'hintSeconds' => [-1, 0, 4, 6, 10].contains(int.tryParse(value)),
        'difficultyOverride' => [
          'auto',
          'easy',
          'medium',
          'hard',
        ].contains(value),
        _ => ['true', 'false'].contains(value),
      };
      if (!valid) throw ArgumentError(key);
      if (key == 'difficultyOverride' &&
          value == 'hard' &&
          !entitlement.isPremium) {
        throw StateError('premium_required');
      }
    }
    if (key == 'dailyGoalMinutes' || key == 'screenLimitMinutes') {
      if (!familyUnlocked) throw StateError('parent_gate_required');
      if (![0, 10, 15, 20, 30].contains(int.tryParse(value))) {
        throw ArgumentError(key);
      }
    }
    final scoped =
        active != null &&
        [
          'locale',
          'sound',
          'speechVolume',
          'effectVolume',
          'showLabels',
          'celebration',
          'introduction',
          'automaticDifficulty',
          'reducedMotion',
          'dailyGoalMinutes',
          'screenLimitMinutes',
          'roundLength',
          'hintSeconds',
          'fadeWrongChoices',
          'difficultyOverride',
        ].contains(key);
    await db.setPreference(scoped ? 'profile.${active!.id}.$key' : key, value);
    await load();
  }

  Future<void> selectProfile(Profile profile) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    if (!canSelectProfile(profile.id)) throw StateError('premium_required');
    await db.setPreference('activeProfile', profile.id);
    await load();
  }

  bool canSelectProfile(String id) =>
      entitlement.isPremium || profiles.firstOrNull?.id == id;
  Future<void> updateProfile(
    String id,
    String name,
    String avatar,
    Map<String, dynamic> survey,
  ) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    final old = profiles.where((p) => p.id == id).firstOrNull;
    if (old == null) throw StateError('profile_missing');
    name = name.trim();
    if (name.isEmpty ||
        name.length > 24 ||
        !['cat', 'dog', 'rabbit', 'bear'].contains(avatar)) {
      throw ArgumentError('invalid_profile');
    }
    await (db.update(db.profiles)..where((p) => p.id.equals(id))).write(
      ProfilesCompanion(
        nickname: Value(name),
        avatar: Value(avatar),
        payload: Value(jsonEncode(survey)),
      ),
    );
    await _applySurveySettings(id, survey, jsonDecode(old.payload));
    await load();
  }

  Future<void> _applySurveySettings(
    String id,
    Map<String, dynamic> answers,
    Map<String, dynamic> before,
  ) async {
    if (answers.containsKey('sound') && answers['sound'] != before['sound']) {
      await db.setPreference('profile.$id.sound', '${answers['sound'] != 0}');
      await db.setPreference(
        'profile.$id.celebration',
        answers['sound'] == 0 ? 'off' : 'simple',
      );
    }
    if (answers.containsKey('language') &&
        answers['language'] != before['language']) {
      await db.setPreference(
        'profile.$id.locale',
        answers['language'] == 0 ? 'tr' : 'en',
      );
    }
  }

  Future<void> deleteProfile(String id) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    if (!profiles.any((p) => p.id == id)) throw StateError('profile_missing');
    // Queue outside the transaction: cache operations share an ordered DB queue.
    await SummarySnapshotCache(db).clearProfile(id);
    await db.transaction(() async {
      await (db.delete(db.trials)..where((t) => t.profileId.equals(id))).go();
      await (db.delete(
        db.gameSessions,
      )..where((t) => t.profileId.equals(id))).go();
      await (db.delete(db.profiles)..where((p) => p.id.equals(id))).go();
      await (db.delete(
        db.preferences,
      )..where((p) => p.key.equals('introduced.$id'))).go();
      await (db.delete(
        db.preferences,
      )..where((p) => p.key.like('profile.$id.%'))).go();
    });
    await load();
  }

  Future<void> record(TrialsCompanion trial) async {
    await db.into(db.trials).insert(trial);
    await refreshTrials();
  }

  Map<String, ItemPerformance> get itemPerformance =>
      ItemPerformance.fromHistory(
        trials.map(
          (t) => LearningObservation(t.targetId, t.maxHint, t.wrongCount),
        ),
      );
  Difficulty recommendedDifficulty(
    String theme,
    String game,
    Difficulty current,
  ) {
    if (difficultyOverride != 'auto') {
      final selected = Difficulty.values.byName(difficultyOverride);
      if (canPlay(theme, game, selected)) return selected;
      return current;
    }
    if (!automaticDifficulty) return current;
    final history = trials
        .where(
          (t) =>
              t.themeId == theme &&
              t.gameId == game &&
              t.difficulty == current.name,
        )
        .map((t) => t.maxHint)
        .toList();
    final next = DifficultyEngine.recommend(current, history);
    return canPlay(theme, game, next) ? next : current;
  }

  Future<void> markIntroduced(String itemId) async {
    introduced.add(itemId);
    if (active != null) {
      await db.setPreference(
        'introduced.${active!.id}',
        jsonEncode(introduced.toList()),
      );
    }
  }

  Future<String> beginSession(
    String theme,
    String game,
    Difficulty difficulty,
  ) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await db
        .into(db.gameSessions)
        .insert(
          GameSessionsCompanion.insert(
            id: id,
            profileId: active!.id,
            themeId: theme,
            gameId: game,
            difficulty: difficulty.name,
            startedAt: DateTime.now(),
          ),
        );
    return id;
  }

  Future<void> finishSession(
    String id,
    int milliseconds,
    bool completed,
  ) async {
    await (db.update(db.gameSessions)..where((t) => t.id.equals(id))).write(
      GameSessionsCompanion(
        activeMs: Value(milliseconds),
        completed: Value(completed),
        endedAt: Value(DateTime.now()),
      ),
    );
    await refreshTrials();
  }

  Future<void> checkpointSession(String id, int milliseconds) async {
    await (db.update(db.gameSessions)
          ..where((t) => t.id.equals(id) & t.endedAt.isNull()))
        .write(GameSessionsCompanion(activeMs: Value(milliseconds)));
  }

  Map<String, int> get struggle {
    final result = <String, int>{};
    for (final t in trials) {
      result[t.targetId] = (result[t.targetId] ?? 0) + (t.maxHint > 0 ? 1 : -1);
    }
    return result.map((k, v) => MapEntry(k, v.clamp(0, 4)));
  }

  int get todayStars => dailyPath.count;
  @override
  void dispose() {
    _disposed = true;
    _lockTimer?.cancel();
    billing.removeListener(notifyListeners);
    billing.dispose();
    unawaited(audio.dispose());
    unawaited(db.close());
    super.dispose();
  }
}

abstract final class DateUtilsHelper {
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
