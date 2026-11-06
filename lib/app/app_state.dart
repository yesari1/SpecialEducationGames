import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale, WidgetsBinding;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart';
import '../core/content/content_repository.dart';
import '../core/db/app_database.dart';
import '../core/audio/audio_service.dart';
import '../core/entitlement/entitlement_service.dart';
import '../core/entitlement/billing_repository.dart';
import '../core/entitlement/trial_store.dart';
import '../core/sync/auto_summary_sync.dart';
import '../core/sync/admin_link.dart';
import '../core/sync/push_messages.dart';
import '../core/sync/child_profiles.dart';
import '../core/sync/family_record.dart';
import 'app_version.dart';
import '../core/sync/summary_sync.dart';
import '../core/learning/policies.dart';
import '../core/learning/item_performance.dart';
import '../core/learning/play_time_ledger.dart';
import '../core/learning/parent_pin.dart';
import '../core/learning/daily_path.dart';
import '../core/learning/week_plan.dart';
import '../core/config/app_configuration.dart';
import '../core/config/config_repository.dart';
import '../core/sync/summary_snapshot_cache.dart';
import '../core/reminder/play_reminder.dart';
import '../l10n/app_localizations.dart';

class AppState extends ChangeNotifier {
  final ContentRepository content;
  final AppDatabase db;
  final AudioService audio;
  late final EntitlementService entitlement;
  late final BillingRepository billing;
  final TrialStore trialStore;
  final FamilyRecordStore familyRecords;
  final AdminLink adminLink;
  final ChildProfileStore childStore;

  /// The signed-in Google account (null: signed out). Set by the app.
  String? accountUid;

  /// False until the saved sign-in was read at start (and, when signed in,
  /// its trial, grant and child profiles); the app shows its loading page.
  bool accountReady = false;

  /// After signing out: forget the account's trial and grant here.
  Future<void> signedOut() async {
    await entitlement.clearAccount();
    if (!_disposed) notifyListeners();
  }

  void setAccount(String? uid, {required bool ready}) {
    accountUid = uid;
    accountReady = ready;
    if (!_disposed) notifyListeners();
  }

  /// "Continue with the free version" was chosen on the offer: the app
  /// opens with the free games, no account needed.
  bool freeChosen = false;

  Future<void> chooseFree() async {
    await db.setPreference('account.freeChosen', 'true');
    freeChosen = true;
    unawaited(funnelStep('free'));
    if (!_disposed) notifyListeners();
  }

  /// Free version chosen, or signed in and this account has started its
  /// free trial (running or over, then the free games stay) or has Premium.
  /// Otherwise the app shows the sign-in / trial page.
  bool get accountGatePassed {
    if (freeChosen) return true;
    final uid = accountUid;
    if (uid == null) return false;
    final e = entitlement;
    return e.isPaid ||
        e.grantActive ||
        e.source == PremiumSource.qa ||
        (e.trialUid == uid && e.trialUsed);
  }

  /// "Already have an account?": the account was set up before
  /// (`families/{uid}`) or has started a trial.
  Future<bool> accountHasRecord(String uid) async {
    try {
      if (await childStore.familyExists(uid)) return true;
    } catch (_) {}
    try {
      return await trialStore.read(uid) != null;
    } catch (_) {
      return false;
    }
  }

  static const _childSettings = [
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
    'hiddenGames',
  ];

  Future<CloudChild?> _cloudChild(String id) async {
    final p = await (db.select(
      db.profiles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (p == null) return null;
    final settings = <String, String>{};
    for (final key in _childSettings) {
      final value = await db.preference('profile.$id.$key');
      if (value != null) settings[key] = value;
    }
    final survey = jsonDecode(p.payload) as Map<String, dynamic>;
    final shift = AgeBand.shiftOf(survey);
    if (shift != 0) settings[AgeBand.shiftKey] = '$shift';
    final years = survey['ageYears'];
    return CloudChild(
      id: id,
      name: p.nickname,
      avatar: p.avatar,
      age: years is int ? years : null,
      ageBand: AgeBand.fromAge(survey)?.name,
      settings: settings,
    );
  }

  /// Saves child [id] to the account (best effort; retried at next sign-in).
  Future<void> _pushChild(String id) async {
    final uid = accountUid;
    if (uid == null) return;
    try {
      final child = await _cloudChild(id);
      if (child != null) await childStore.put(uid, child);
    } catch (_) {}
  }

  /// Sign-in: brings back the account's child profiles that are missing
  /// here (new install, cleared data, another device), then saves the ones
  /// that are only here.
  Future<void> syncChildren(String uid) async {
    List<CloudChild> cloud;
    try {
      cloud = await childStore.list(uid);
    } catch (_) {
      return;
    }
    final local = {for (final p in profiles) p.id};
    for (final c in cloud) {
      if (local.contains(c.id)) continue;
      // Only age (or its band) and the parent's shift come back; the other
      // onboarding answers never left the phone that made the profile.
      final band = AgeBand.values.where((b) => b.name == c.ageBand).firstOrNull;
      final shift = int.tryParse(c.settings[AgeBand.shiftKey] ?? '');
      final survey = <String, dynamic>{
        if (c.age != null) 'ageYears': c.age,
        if (c.age == null && band != null) 'age': band.index,
        if (shift != null && shift != 0) AgeBand.shiftKey: shift.clamp(-1, 1),
      };
      await db
          .into(db.profiles)
          .insertOnConflictUpdate(
            ProfilesCompanion.insert(
              id: c.id,
              nickname: c.name.length > 24 ? c.name.substring(0, 24) : c.name,
              avatar: Value(
                ['cat', 'dog', 'rabbit', 'bear'].contains(c.avatar)
                    ? c.avatar
                    : 'cat',
              ),
              payload: Value(jsonEncode(survey)),
            ),
          );
      for (final e in c.settings.entries) {
        if (_childSettings.contains(e.key)) {
          await db.setPreference('profile.${c.id}.${e.key}', e.value);
        }
      }
    }
    if (cloud.isNotEmpty && await db.preference('activeProfile') == null) {
      await db.setPreference('activeProfile', cloud.first.id);
    }
    final cloudIds = {for (final c in cloud) c.id};
    for (final id in local) {
      if (!cloudIds.contains(id)) await _pushChild(id);
    }
    await load();
  }

  /// Daily summaries go to the cloud automatically while a parent is signed
  /// in; the family setting `cloudSync` (default on) turns it off.
  late final AutoSummarySync autoSync;
  bool cloudSync = true;

  /// After every Google sign-in: keep `families/{uid}` (created once,
  /// updated time, locale, account e-mail) for the admin page. Best effort.
  Future<void> recordFamily(String uid, String? email) async {
    try {
      await familyRecords.record(
        uid: uid,
        locale: locale,
        email: email,
        appVersion: appVersion,
        plan: entitlement.planName,
        fcmToken: await db.preference('funnel.fcmToken'),
        deviceModel: await _deviceModel(),
      );
    } catch (_) {
      // Offline or not configured: the next sign-in tries again.
    }
  }

  /// Play says only "subscribed", not monthly or yearly. When this device
  /// did not buy it, the plan recorded in `families/{uid}` by the buying
  /// device is used.
  Future<void> syncPlan(String? uid) async {
    if (uid == null || entitlement.subscriptionPlan != null) return;
    try {
      final plan = await familyRecords.plan(uid);
      if (plan == 'monthly' || plan == 'yearly') {
        await entitlement.setSubscriptionPlan(plan!);
      }
    } catch (_) {
      // Offline: reported as monthly until the next sign-in.
    }
  }

  /// Reads the admin grant of [uid] (`grants/{uid}`). Offline the cached
  /// grant stays; another account's cache is replaced.
  Future<void> syncGrant(String? uid) async {
    if (uid == null) return;
    try {
      final g = await adminLink.grant(uid);
      await entitlement.setGrant(
        uid,
        premium: g.premium,
        until: g.until,
        endTrial: g.endTrial,
      );
    } catch (_) {
      if (entitlement.grantUid != uid) {
        await entitlement.setGrant(uid, premium: false, endTrial: false);
      }
    }
    if (!_disposed) notifyListeners();
  }

  /// Anonymous install funnel (`funnel/{installId}`): a random id made once
  /// on this device, no account or child data. Off until [reportInstall]
  /// runs (the app start), so tests never reach the network.
  bool _funnelOn = false;
  String? _installId;
  String? get installId => _installId;

  static String _newInstallId() {
    final r = math.Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<String> _ensureInstallId() async {
    var id = _installId ?? await db.preference('funnel.installId');
    if (id == null || id.isEmpty) {
      id = _newInstallId();
      await db.setPreference('funnel.installId', id);
    }
    return _installId = id;
  }

  /// App start: the install document once, then any step stamps that did
  /// not get through before. Failures are silent and retried next start.
  Future<void> reportInstall() async {
    _funnelOn = true;
    try {
      final id = await _ensureInstallId();
      if (await db.preference('funnel.sent.install') != 'true') {
        await adminLink.funnel(id, {
          'installedAt': serverNow(),
          'platform': 'android',
          'appVersion': appVersion,
          'locale': locale == 'tr' ? 'tr' : 'en',
        });
        await db.setPreference('funnel.sent.install', 'true');
      }
      for (final step in _funnelSteps) {
        if (await db.preference('funnel.due.$step') == 'true') {
          await funnelStep(step);
        }
      }
      final permission = await db.preference('funnel.due.notifPermission');
      if (permission == 'granted' || permission == 'denied') {
        await reportNotifPermission(permission == 'granted');
      }
      unawaited(_reportPushToken());
      unawaited(_reportDeviceModel());
      unawaited(reportOpenDay());
    } catch (_) {}
  }

  static String _localDay(DateTime d) {
    final l = d.toLocal();
    return '${l.year.toString().padLeft(4, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  /// The local dates this install was opened (the last 60), for day 1 / 7 /
  /// 30 return. Sent at start and when the app comes back to the front;
  /// once a day. Failures are silent and retried next time.
  Future<void> reportOpenDay() async {
    if (!_funnelOn) return;
    try {
      if (await db.preference('funnel.sent.install') != 'true') return;
      final today = _localDay(DateTime.now());
      if (await db.preference('funnel.openSent') == today) return;
      final days = (await db.preference('funnel.openDays') ?? '')
          .split(',')
          .where((d) => d.isNotEmpty)
          .toList();
      if (!days.contains(today)) days.add(today);
      final kept = days.length > 60 ? days.sublist(days.length - 60) : days;
      await db.setPreference('funnel.openDays', kept.join(','));
      await adminLink.funnel(await _ensureInstallId(), {'openDays': kept});
      await db.setPreference('funnel.openSent', today);
    } catch (_) {}
  }

  /// One more opened (or completed) round of a card on the install record:
  /// `cards.<theme>_<game>.opened|completed`. Not retried: a count that
  /// does not get through is simply missing.
  Future<void> reportCard(
    String theme,
    String game, {
    required bool completed,
  }) async {
    if (!_funnelOn) return;
    try {
      final key = '${theme}_$game';
      if (!RegExp(r'^[A-Za-z0-9_]{1,40}$').hasMatch(key)) return;
      if (await db.preference('funnel.sent.install') != 'true') return;
      await adminLink.funnel(await _ensureInstallId(), {
        'cards': {
          key: {completed ? 'completed' : 'opened': countUp()},
        },
      });
    } catch (_) {}
  }

  /// The plan tapped on the offer (the last one tapped).
  Future<void> reportPaywallPlan(String planId) async {
    unawaited(funnelStep('paywallPlanTap'));
    if (!_funnelOn) return;
    try {
      if (!RegExp(r'^[a-z0-9_]{1,32}$').hasMatch(planId)) return;
      if (await db.preference('funnel.sent.install') != 'true') return;
      await adminLink.funnel(await _ensureInstallId(), {
        'paywallPlanId': planId,
      });
    } catch (_) {}
  }

  /// Android's answer in its own notification permission dialog.
  Future<void> reportNotifPermission(bool granted) async {
    if (!_funnelOn) return;
    try {
      final value = granted ? 'granted' : 'denied';
      await db.setPreference('funnel.due.notifPermission', value);
      if (await db.preference('funnel.sent.install') != 'true') return;
      await adminLink.funnel(await _ensureInstallId(), {
        'notifPermission': value,
      });
      await db.setPreference('funnel.due.notifPermission', '');
    } catch (_) {}
  }

  String? _model;

  /// The phone's maker and model ("Google Pixel 9a") for the admin page;
  /// null off Android or when it cannot be read.
  Future<String?> _deviceModel() async {
    if (_model != null) return _model;
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final maker = info.manufacturer.trim();
      final model = info.model.trim();
      final both = model.toLowerCase().startsWith(maker.toLowerCase())
          ? model
          : '${maker.isEmpty ? '' : '${maker[0].toUpperCase()}${maker.substring(1)} '}$model';
      final value = both.trim();
      if (value.isEmpty) return null;
      return _model = value.length > 64 ? value.substring(0, 64) : value;
    } catch (_) {
      return null;
    }
  }

  /// The phone model on the install record, once (again if it changed).
  Future<void> _reportDeviceModel() async {
    try {
      final model = await _deviceModel();
      if (model == null) return;
      if (await db.preference('funnel.deviceModel') == model) return;
      await adminLink.funnel(await _ensureInstallId(), {'deviceModel': model});
      await db.setPreference('funnel.deviceModel', model);
    } catch (_) {}
  }

  /// Sends this install's push address to its funnel record (when it is new
  /// or changed) so the admin page can reach it. Failures are silent.
  Future<void> _reportPushToken() async {
    try {
      await PushMessages.listen(
        onToken: (token) => unawaited(_sendPushToken(token)),
        channelName: tr('Duyurular', 'Announcements'),
      );
      final token = await PushMessages.token();
      if (token != null) await _sendPushToken(token);
    } catch (_) {}
  }

  Future<void> _sendPushToken(String token) async {
    try {
      if (token.isEmpty || token.length > 512) return;
      if (await db.preference('funnel.fcmToken') == token) return;
      await adminLink.funnel(await _ensureInstallId(), {'fcmToken': token});
      await db.setPreference('funnel.fcmToken', token);
      final uid = accountUid;
      if (uid != null) await recordFamily(uid, null);
    } catch (_) {}
  }

  static const _funnelSteps = [
    'obChild',
    'obFavorite',
    'obKnown',
    'onboarding',
    'signedIn',
    'paywall',
    'free',
    'trial',
    'purchased',
    'firstGame',
    'reminderYes',
    'reminderNo',
    'firstRound',
    'paywallTrialTap',
    'paywallPlanTap',
    'paywallBack',
  ];

  /// Stamps `<step>At` once ([_funnelSteps]); the rules reject a second
  /// stamp, so sent steps are remembered here.
  Future<void> funnelStep(String step) async {
    if (!_funnelOn) return;
    try {
      if (await db.preference('funnel.sent.$step') == 'true') return;
      await db.setPreference('funnel.due.$step', 'true');
      final id = await _ensureInstallId();
      if (await db.preference('funnel.sent.install') != 'true') return;
      await adminLink.funnel(id, {'${step}At': serverNow()});
      await db.setPreference('funnel.sent.$step', 'true');
      await db.setPreference('funnel.due.$step', 'false');
    } catch (_) {}
  }

  /// Play time on this install (all profiles, signed in or not) for the
  /// admin page: total, days played, today's time and its date. Rewritten
  /// after each game; kept out of [funnelStep] so a rejected write never
  /// holds back a step stamp. Failures are silent.
  Future<void> reportPlayTime() async {
    if (!_funnelOn) return;
    try {
      if (await db.preference('funnel.sent.install') != 'true') return;
      final id = await _ensureInstallId();
      final ended = await (db.select(
        db.gameSessions,
      )..where((t) => t.endedAt.isNotNull())).get();
      const day = _localDay;
      final today = day(DateTime.now());
      var total = 0, todayMs = 0;
      final days = <String>{};
      for (final s in ended) {
        if (s.activeMs <= 0) continue;
        final d = day(s.endedAt!);
        total += s.activeMs;
        days.add(d);
        if (d == today) todayMs += s.activeMs;
      }
      await adminLink.funnel(id, {
        'playMs': total.clamp(0, 1000000000),
        'playDays': days.length.clamp(0, 10000),
        'todayMs': todayMs.clamp(0, 86400000),
        'playDate': today,
      });
    } catch (_) {}
  }

  /// Device QA only: `--dart-define=SHOW_ASKS=true` shows the survey and
  /// rating cards at once in debug/profile builds (never in release).
  static const _qaAsks = !kReleaseMode && bool.fromEnvironment('SHOW_ASKS');

  bool surveyDone = false;
  bool ratingDone = false;
  DateTime? ratingLaterUntil;

  /// Different days with play and minutes played (active profile).
  int get playDays => sessions
      .map(
        (x) => DateTime(x.startedAt.year, x.startedAt.month, x.startedAt.day),
      )
      .toSet()
      .length;
  int get playMinutes =>
      sessions.fold<int>(0, (sum, x) => sum + x.activeMs) ~/ 60000;

  /// Family area: the short survey after 2 play days or 20 minutes.
  bool get showSurvey =>
      !surveyDone && (_qaAsks || playDays >= 2 || playMinutes >= 20);

  /// Family area: Google Play's rating card after 5 play days, once the
  /// survey is closed; tried again a month later at the earliest.
  bool get showRating {
    if (ratingDone || !surveyDone && !_qaAsks) return false;
    final later = ratingLaterUntil;
    if (later != null && DateTime.now().isBefore(later)) return false;
    return _qaAsks || playDays >= 5;
  }

  Future<void> closeSurvey() async {
    surveyDone = true;
    await db.setPreference('ask.surveyDone', 'true');
    notifyListeners();
  }

  Future<void> closeRating({required bool later}) async {
    if (later) {
      ratingLaterUntil = DateTime.now().add(const Duration(days: 30));
      await db.setPreference(
        'ask.ratingLaterUntil',
        ratingLaterUntil!.toIso8601String(),
      );
    } else {
      ratingDone = true;
      await db.setPreference('ask.ratingDone', 'true');
    }
    notifyListeners();
  }

  bool trialBusy = false;
  TrialIssue? trialIssue;

  /// Reads this Google account's trial from the server (sign-in or restore).
  /// Offline the cached start stays; another account's cache is replaced.
  Future<void> syncTrial(String? uid) async {
    if (uid == null) return;
    try {
      final started = await trialStore.read(uid);
      await entitlement.setTrial(uid, started);
    } on TrialFailure {
      if (entitlement.trialUid != uid) await entitlement.setTrial(uid, null);
    }
    if (!_disposed) notifyListeners();
  }

  /// Starts the one free trial of the signed-in account [uid]. Parent only.
  /// Returns false with [trialIssue] set when it could not be started.
  Future<bool> startTrial(String uid) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    if (trialBusy) return false;
    trialBusy = true;
    trialIssue = null;
    notifyListeners();
    try {
      final started = await trialStore.claim(uid);
      await entitlement.setTrial(uid, started);
      if (entitlement.trialActive) unawaited(funnelStep('trial'));
      return entitlement.trialActive;
    } on TrialFailure catch (failure) {
      trialIssue = failure.issue;
      return false;
    } catch (_) {
      trialIssue = TrialIssue.unavailable;
      return false;
    } finally {
      trialBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  late AppConfiguration configuration;
  late final ConfigRepository configs;
  AppConfiguration? _pendingConfiguration;
  int _activeGames = 0;
  bool _disposed = false;
  int _refreshGeneration = 0;
  void enterGame() => _activeGames++;

  /// True while a game screen is open (another one may have opened before
  /// the previous one is disposed).
  bool get inGame => _activeGames > 0;
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

  /// Games the child sees: the family can turn single games off.
  List<String> gamesForTheme(String theme) => allGamesForTheme(
    theme,
  ).where((g) => !hiddenGames.contains('${theme}_$g')).toList();

  /// Every available game of a theme (the family Games tab lists them all).
  List<String> allGamesForTheme(String theme) =>
      (configuration.gameOrder[theme] ?? content.theme(theme).games)
          .where((g) => !configuration.disabledGames.contains('${theme}_$g'))
          .toList();

  /// Games this child's family turned off (per profile).
  Set<String> hiddenGames = {};

  /// Turns every game of a theme on or off for this child.
  Future<void> setThemeShown(String theme, bool shown) async {
    final keys = {for (final g in allGamesForTheme(theme)) '${theme}_$g'};
    final next = {...hiddenGames};
    shown ? next.removeAll(keys) : next.addAll(keys);
    await setting('hiddenGames', (next.toList()..sort()).join(','));
  }

  Future<void> setGameShown(String theme, String game, bool shown) async {
    final key = '${theme}_$game';
    final next = {...hiddenGames};
    shown ? next.remove(key) : next.add(key);
    await setting('hiddenGames', (next.toList()..sort()).join(','));
  }

  List<Profile> profiles = [];
  List<Trial> trials = [];
  List<GameSession> sessions = [];
  Set<String> _dailyStickers = {};
  String? _stickerProfileId;
  Set<String> get dailyStickers => _stickerProfileId == active?.id
      ? Set.unmodifiable(_dailyStickers)
      : const {};

  /// Cards on today's path (short, so a small child reaches the sticker).
  static const pathLength = 3;

  /// Today's path follows the first-run 7-day plan ([weekPlan], liked themes
  /// first): the plan's day (days since the plan started, then round
  /// again), its cards that can be played, then more of that theme, then
  /// the next days' cards, then any free card.
  List<String> get dailyPathSteps => dailyPathStepsAt(DateTime.now());

  List<String> dailyPathStepsAt(DateTime now) {
    final steps = <String>[];
    void add(String theme, String game) {
      final key = '${theme}_$game';
      if (steps.length < pathLength &&
          !steps.contains(key) &&
          pathPlayable(key)) {
        steps.add(key);
      }
    }

    final plan = weekPlan;
    if (plan.isNotEmpty) {
      final start = planDayAt(now) % plan.length;
      final today = plan[start];
      for (final g in today.games) {
        add(today.theme, g);
      }
      final more = _planGames(today.theme);
      for (final g in [
        ...more.where((g) => g != WeekPlan.learn),
        ...more.where((g) => g == WeekPlan.learn),
      ]) {
        add(today.theme, g);
      }
      for (var i = 1; i < plan.length; i++) {
        final day = plan[(start + i) % plan.length];
        for (final g in day.games) {
          add(day.theme, g);
        }
      }
    }
    for (final key in _freePathCandidates) {
      final parts = key.split('_');
      add(parts[0], parts[1]);
    }
    return steps;
  }

  /// The day the active child's plan started (`YYYY-MM-DD`): set up, or the
  /// first start of this version for children set up before.
  String? _planStart;
  String? _planStartProfileId;

  /// A child set up in the first-run setup: the mascot greets them before
  /// their first game, once.
  bool _mascotHelloDue = false;
  bool get mascotHelloDue =>
      _mascotHelloDue && _planStartProfileId == active?.id;

  Future<void> mascotHelloDone() async {
    _mascotHelloDue = false;
    final id = active?.id;
    if (id != null) await db.setPreference('profile.$id.mascotHello', 'done');
  }

  /// 0 on the plan's first day, 1 the next day, ...
  int planDayAt(DateTime now) {
    final start = _planStartProfileId == active?.id
        ? DateTime.tryParse(_planStart ?? '')
        : null;
    if (start == null) return 0;
    final local = now.toLocal();
    final days = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    return days < 0 ? 0 : days;
  }

  /// The first-run 7-day plan (onboarding): home-screen theme order, each
  /// theme's visible games, the free cards first on the early days.
  List<PlanDay> get weekPlan => WeekPlan.build(
    themes: [
      for (final t in orderedThemes)
        if (_planGames(t.id).isNotEmpty) t.id,
    ],
    gamesOf: _planGames,
    isFree: (theme, game) => configuration.freeGames.contains('${theme}_$game'),
  );

  List<String> _planGames(String theme) => allGamesForTheme(
    theme,
  ).where((g) => !hiddenGames.contains('${theme}_$g')).toList();

  List<String> get _freePathCandidates =>
      configuration.freeGames.where(pathPlayable).toList()..sort();

  /// Whether a card can stand on today's path now (playable, shown, with
  /// its content and the sound it needs).
  bool pathPlayable(String key) {
    final parts = key.split('_');
    if (parts.length != 2) return false;
    final effectiveDifficulty = recommendedDifficulty(
      parts[0],
      parts[1],
      Difficulty.easy,
    );
    return parts.length == 2 &&
        !hiddenGames.contains(key) &&
        canPlay(parts[0], parts[1], Difficulty.easy) &&
        content.isGameContentAvailable(
          parts[0],
          parts[1],
          effectiveDifficulty,
        ) &&
        hasRequiredGameAudio(parts[0], parts[1]);
  }

  DailyPathProgress dailyPathAt(DateTime now) => DailyPathProgress.fromSessions(
    steps: dailyPathStepsAt(now),
    sessions: sessions,
    profileId: active?.id ?? '',
    now: now,
  );
  DailyPathProgress get dailyPath => dailyPathAt(DateTime.now());

  /// Where a finished round leads on its own. Opened from today's path: the
  /// next unplayed stop of the path (the theme once the path is done).
  /// Opened from a theme page: the next open game of that theme. Null when
  /// nothing else can be played.
  String? nextGameRoute(
    String theme,
    String game,
    Difficulty tier, {
    bool fromPath = false,
  }) {
    final current = '${theme}_$game';
    final path = dailyPath;
    if (fromPath) {
      for (final step in path.steps) {
        if (step == current || path.completed.contains(step)) continue;
        final parts = step.split('_');
        return '/game/${parts[0]}/${parts[1]}/easy?from=path';
      }
    }
    final games = gamesForTheme(theme);
    final from = games.indexOf(game);
    for (var i = 1; i < games.length; i++) {
      final next = games[(from + i) % games.length];
      if (next == game || !canPlay(theme, next, tier)) continue;
      final effective = recommendedDifficulty(theme, next, tier);
      if (!content.isGameContentAvailable(theme, next, effective)) continue;
      return '/game/$theme/$next/${tier.name}';
    }
    return null;
  }

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
    TrialStore? trialStore,
    FamilyRecordStore? familyRecords,
    AdminLink? adminLink,
    ChildProfileStore? childStore,
    SummaryStore? summaryStore,
    String? Function()? signedInUid,
  }) : _playTimeNow = playTimeNow ?? DateTime.now,
       trialStore = trialStore ?? FirestoreTrialStore(),
       familyRecords = familyRecords ?? const FirestoreFamilyRecordStore(),
       adminLink = adminLink ?? const FirestoreAdminLink(),
       childStore = childStore ?? const FirestoreChildProfileStore() {
    playTime = PlayTimeLedger(db, now: _playTimeNow);
    configuration = AppConfiguration.defaults(content);
    configs = ConfigRepository(db, content);
    entitlement = EntitlementService(
      db,
      trialDaysOf: () => configuration.trialDays,
    );
    billing = BillingRepository(
      entitlement,
      onPurchased: () => unawaited(funnelStep('purchased')),
    );
    autoSync = AutoSummarySync(
      enabled: () => cloudSync,
      activeProfileId: () => active?.id,
      sessions: () => sessions,
      trials: () => trials,
      store: summaryStore,
      signedInUid: signedInUid,
    );
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
          // Free cards (Learn and two games per theme) are open on every tier.
          configuration.freeGames.contains('${theme}_$game'));
  Future<void> load() async {
    if (_activeGames == 0) configuration = await configs.load();
    if (_activeGames == 0) await _closeLeftoverSessions();
    await entitlement.load();
    freeChosen = await db.preference('account.freeChosen') == 'true';
    surveyDone = await db.preference('ask.surveyDone') == 'true';
    ratingDone = await db.preference('ask.ratingDone') == 'true';
    ratingLaterUntil = DateTime.tryParse(
      await db.preference('ask.ratingLaterUntil') ?? '',
    );
    await _loadReminder();
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
    cloudSync = await db.preference('cloudSync') != 'false';
    final savedLength = int.tryParse(await _readSetting('roundLength') ?? '0');
    roundLength = [0, 3, 5, 8, 10].contains(savedLength) ? savedLength! : 0;
    final savedHint = int.tryParse(await _readSetting('hintSeconds') ?? '-1');
    hintSeconds = [-1, 0, 4, 6, 10].contains(savedHint) ? savedHint! : -1;
    fadeWrongChoices = await _readSetting('fadeWrongChoices') != 'false';
    hiddenGames = {
      for (final key in (await _readSetting('hiddenGames') ?? '').split(','))
        if (key.isNotEmpty) key,
    };
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
    unawaited(refreshReminder());
  }

  /// Daily play reminder (local notifications only).
  final PlayReminder reminder = PlayReminder();

  /// Daily reminder on (the parent said yes) and its hour.
  bool reminderOn = false;
  int reminderHour = PlayReminder.hour;

  Future<void> _loadReminder() async {
    reminderOn = await db.preference('reminder.on') == 'true';
    final hour = int.tryParse(await db.preference('reminder.hour') ?? '');
    reminderHour = PlayReminder.hours.contains(hour)
        ? hour!
        : PlayReminder.hour;
  }

  /// Family area: the reminders on or off (on asks Android's permission).
  Future<void> setReminder(bool on) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    await db.setPreference('reminder.asked', 'true');
    await db.setPreference('reminder.on', '$on');
    reminderOn = on;
    if (on) {
      final granted = await reminder.requestPermission();
      unawaited(reportNotifPermission(granted));
    }
    await refreshReminder();
    if (!_disposed) notifyListeners();
  }

  Future<void> setReminderHour(int hour) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    if (!PlayReminder.hours.contains(hour)) throw ArgumentError('hour');
    await db.setPreference('reminder.hour', '$hour');
    reminderHour = hour;
    await refreshReminder();
    if (!_disposed) notifyListeners();
  }

  /// Days in a row with play, up to today (a day not played yet today does
  /// not break it until the day is over).
  int dayStreakAt(DateTime now) {
    String key(DateTime d) => DailyPathProgress.dayKey(d);
    final played = {
      for (final x in sessions)
        if (x.activeMs > 0 || x.completed) key(x.startedAt),
    };
    var day = DateTime(now.year, now.month, now.day);
    if (!played.contains(key(day))) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var streak = 0;
    while (played.contains(key(day))) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  int get dayStreak => dayStreakAt(DateTime.now());

  /// Re-plans the evening reminders (none today once a game was started)
  /// and the Sunday summary of the week.
  Future<void> refreshReminder() async {
    if (active == null || !PlayReminder.supported) return;
    await _loadReminder();
    // Only after the parent said yes.
    if (!reminderOn) {
      await reminder.cancel();
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final played = await (db.select(
      db.gameSessions,
    )..where((t) => t.startedAt.isBiggerOrEqualValue(today))).get();
    final l10n = lookupAppLocalizations(Locale(locale));
    // The summary covers Monday to the Sunday it is shown on.
    final sunday = PlayReminder.weeklyAt(now, at: reminderHour);
    final monday = DateTime(sunday.year, sunday.month, sunday.day - 6);
    final week = await (db.select(db.gameSessions)..where(
          (t) =>
              t.profileId.equals(active!.id) &
              t.startedAt.isBiggerOrEqualValue(monday),
        ))
        .get();
    final days = {
      for (final x in week)
        if (x.activeMs > 0) DailyPathProgress.dayKey(x.startedAt),
    }.length;
    final minutes = (week.fold<int>(0, (sum, x) => sum + x.activeMs) / 60000)
        .round();
    final name = active!.nickname;
    await reminder.reschedule(
      playedToday: played.isNotEmpty,
      title: l10n.reminderTitle,
      body: l10n.reminderBody,
      channel: l10n.reminderChannel,
      at: reminderHour,
      weekly: (
        l10n.weeklySummaryTitle,
        days == 0
            ? l10n.weeklySummaryNone(name)
            : l10n.weeklySummaryBody(name, days, minutes < 1 ? 1 : minutes),
      ),
    );
  }

  /// The reminder is offered once: in setup right after the daily goal, or
  /// for families set up earlier, when the family area first opens.
  Future<bool> shouldOfferReminder() async =>
      active != null &&
      PlayReminder.supported &&
      await db.preference('reminder.asked') != 'true';

  /// The parent's answer to our own offer; only a yes brings up Android's
  /// permission dialog. Either way it is not offered again.
  Future<void> answerReminderOffer(bool yes) async {
    await db.setPreference('reminder.asked', 'true');
    await db.setPreference('reminder.on', '$yes');
    reminderOn = yes;
    unawaited(funnelStep(yes ? 'reminderYes' : 'reminderNo'));
    if (!yes) return;
    final granted = await reminder.requestPermission();
    unawaited(reportNotifPermission(granted));
    await refreshReminder();
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
    final planKey = 'profile.$profileId.planStart';
    var planStart = await db.preference(planKey);
    if (profileId != null && DateTime.tryParse(planStart ?? '') == null) {
      planStart = DailyPathProgress.dayKey(DateTime.now());
      await db.setPreference(planKey, planStart);
    }
    final hello = await db.preference('profile.$profileId.mascotHello');
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
    _planStart = planStart;
    _planStartProfileId = profileId;
    _mascotHelloDue = hello == 'due';
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
    if (profiles.length >= profileLimit) {
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
    unawaited(_pushChild(id));
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
    await db.setPreference('profile.$id.mascotHello', 'due');
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
    unawaited(_pushChild(id));
    unawaited(funnelStep('onboarding'));
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
    if (key == 'hiddenGames') {
      if (!familyUnlocked) throw StateError('parent_gate_required');
      final known = {
        for (final t in content.themes)
          for (final g in t.games) '${t.id}_$g',
      };
      if (value.split(',').any((k) => k.isNotEmpty && !known.contains(k))) {
        throw ArgumentError(key);
      }
    }
    if (key == 'cloudSync') {
      if (!familyUnlocked) throw StateError('parent_gate_required');
      if (!['true', 'false'].contains(value)) throw ArgumentError(key);
      if (value == 'false') autoSync.cancel();
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
          'hiddenGames',
        ].contains(key);
    await db.setPreference(scoped ? 'profile.${active!.id}.$key' : key, value);
    await load();
    if (scoped) unawaited(_pushChild(active!.id));
  }

  Future<void> selectProfile(Profile profile) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    if (!canSelectProfile(profile.id)) throw StateError('premium_required');
    await db.setPreference('activeProfile', profile.id);
    await load();
  }

  /// Up to five children with paid Premium; one in the free version and
  /// during the free trial.
  int get profileLimit =>
      entitlement.isPaid ||
          entitlement.source == PremiumSource.qa ||
          entitlement.source == PremiumSource.granted
      ? 5
      : 1;

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
    unawaited(_pushChild(id));
  }

  Map<String, dynamic> get activeSurvey =>
      jsonDecode(active?.payload ?? '{}') as Map<String, dynamic>;

  /// Age band of the active profile before the parent's shift.
  AgeBand? get ageBandFromAge => AgeBand.fromAge(activeSurvey);

  /// The band games use (after the parent's shift).
  AgeBand? get ageBand => AgeBand.of(activeSurvey);
  int get ageLevelShift => AgeBand.shiftOf(activeSurvey);

  /// Parent's ±1 adjustment of the active profile's age band (family
  /// settings, behind the parent gate). Stored with the survey.
  Future<void> setAgeLevelShift(int shift) async {
    if (!familyUnlocked) throw StateError('parent_gate_required');
    if (shift < -1 || shift > 1) throw ArgumentError('ageLevelShift');
    final profile = active;
    if (profile == null) return;
    final survey = jsonDecode(profile.payload) as Map<String, dynamic>;
    if (shift == 0) {
      survey.remove(AgeBand.shiftKey);
    } else {
      survey[AgeBand.shiftKey] = shift;
    }
    await (db.update(db.profiles)..where((p) => p.id.equals(profile.id))).write(
      ProfilesCompanion(payload: Value(jsonEncode(survey))),
    );
    await load();
    unawaited(_pushChild(profile.id));
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
    final uid = accountUid;
    if (uid != null) {
      unawaited(childStore.delete(uid, id).catchError((Object _) {}));
    }
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
    unawaited(funnelStep('firstGame'));
    unawaited(reportCard(theme, game, completed: false));
    unawaited(refreshReminder());
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
    autoSync.request();
    unawaited(reportPlayTime());
    // The Sunday summary counts this game too.
    unawaited(refreshReminder());
    if (completed) {
      unawaited(funnelStep('firstRound'));
      final s = await (db.select(
        db.gameSessions,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (s != null) {
        unawaited(reportCard(s.themeId, s.gameId, completed: true));
      }
    }
  }

  /// The database keeps whole seconds; rounding the end up keeps the active
  /// time within the stored start and end, which the summaries require.
  static DateTime _endAfter(DateTime start, int milliseconds) {
    final end = start.add(Duration(milliseconds: milliseconds));
    final whole = end.subtract(
      Duration(microseconds: end.microsecondsSinceEpoch % 1000000),
    );
    return whole == end ? end : whole.add(const Duration(seconds: 1));
  }

  /// A game the app was closed in (killed before it could record leaving)
  /// ends at its last checkpoint, so its play time still counts.
  Future<void> _closeLeftoverSessions() async {
    final open = await (db.select(
      db.gameSessions,
    )..where((t) => t.endedAt.isNull())).get();
    for (final session in open) {
      await (db.update(
        db.gameSessions,
      )..where((t) => t.id.equals(session.id))).write(
        GameSessionsCompanion(
          endedAt: Value(_endAfter(session.startedAt, session.activeMs)),
        ),
      );
    }
  }

  /// The app left the foreground mid-game: record the round so far as an
  /// interrupted one and send it now, since the app may be closed for good.
  /// [resumeSession] reopens it if the child comes back.
  Future<void> suspendSession(String id, int milliseconds) async {
    final open = await (db.select(
      db.gameSessions,
    )..where((t) => t.id.equals(id) & t.endedAt.isNull())).getSingleOrNull();
    if (open == null) return;
    // Stored in whole seconds: keep the active time within start and end
    // (the summaries skip a session claiming more time than it lasted).
    final now = DateTime.now();
    final stored = now.subtract(
      Duration(microseconds: now.microsecondsSinceEpoch % 1000000),
    );
    final lasted = stored.difference(open.startedAt).inMilliseconds;
    await (db.update(db.gameSessions)..where((t) => t.id.equals(id))).write(
      GameSessionsCompanion(
        activeMs: Value(milliseconds.clamp(0, lasted < 0 ? 0 : lasted)),
        endedAt: Value(now),
      ),
    );
    await refreshTrials();
    unawaited(autoSync.run());
    unawaited(reportPlayTime());
  }

  Future<void> resumeSession(String id) async {
    await (db.update(db.gameSessions)
          ..where((t) => t.id.equals(id) & t.completed.equals(false)))
        .write(const GameSessionsCompanion(endedAt: Value(null)));
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
    autoSync.dispose();
    unawaited(audio.dispose());
    unawaited(db.close());
    super.dispose();
  }
}

abstract final class DateUtilsHelper {
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
