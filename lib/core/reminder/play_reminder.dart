import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// One gentle reminder at the chosen hour (18:00 unless the parent picks
/// another) on each day nothing was played, and a weekly summary on Sunday
/// evening.
///
/// Local notifications only: nothing leaves the device. The next evenings
/// are scheduled ahead ([dayOffsets]: every day for a week, then a few more
/// over the month, so the reminders go on even if the app stays closed) and
/// rescheduled whenever the app opens or a game starts or ends, so a day
/// with play drops its own reminder.
class PlayReminder {
  static const hour = 18;
  static const hours = [17, 18, 19, 20];
  static const dayOffsets = [0, 1, 2, 3, 4, 5, 6, 9, 13, 20, 29];
  static const _firstId = 7100;
  static const _weeklyId = 7150;
  static const _channel = 'play_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _ready;

  PlayReminder({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// The real device, not the target platform a test pretends to be.
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<bool> _init() => _ready ??= () async {
    try {
      final ready = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // iOS asks for permission only through [requestPermission].
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      // iOS reports whether permission is already given here; that is
      // asked separately, so a finished setup counts as ready.
      return Platform.isIOS || (ready ?? false);
    } catch (_) {
      return false;
    }
  }();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// The system's own permission dialog (Android 13+, iOS). True when allowed.
  Future<bool> requestPermission() async {
    if (!supported || !await _init()) return false;
    try {
      if (Platform.isIOS) {
        return await _ios?.requestPermissions(alert: true, sound: true) ??
            false;
      }
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Evenings that get a reminder, from [now] on: today only if nothing was
  /// played yet and it is not past [at] o'clock.
  static List<DateTime> evenings(
    DateTime now, {
    required bool playedToday,
    int at = hour,
  }) =>
      [
            for (final d in dayOffsets)
              DateTime(now.year, now.month, now.day + d, at),
          ]
          .where(
            (e) =>
                e.isAfter(now) &&
                !(playedToday &&
                    e.year == now.year &&
                    e.month == now.month &&
                    e.day == now.day),
          )
          .toList();

  /// The weekly summary: the coming Sunday one hour after [at] o'clock
  /// (today when it is Sunday and that time is still ahead).
  static DateTime weeklyAt(DateTime now, {int at = hour}) {
    final days = (DateTime.sunday - now.weekday) % 7;
    final sunday = DateTime(now.year, now.month, now.day + days, at + 1);
    return sunday.isAfter(now) ? sunday : sunday.add(const Duration(days: 7));
  }

  /// Drops every planned reminder and the weekly summary.
  Future<void> cancel() async {
    if (!supported || !await _init()) return;
    try {
      for (var i = 0; i < dayOffsets.length; i++) {
        await _plugin.cancel(id: _firstId + i);
      }
      await _plugin.cancel(id: _weeklyId);
    } catch (_) {}
  }

  /// [weekly]: the summary text for [weeklyAt] (title, body), or null.
  Future<void> reschedule({
    required bool playedToday,
    required String title,
    required String body,
    required String channel,
    int at = hour,
    (String, String)? weekly,
    DateTime? now,
  }) async {
    if (!supported || !await _init()) return;
    await cancel();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel,
        channel,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final from = now ?? DateTime.now();
    try {
      final times = evenings(from, playedToday: playedToday, at: at);
      for (var i = 0; i < times.length; i++) {
        await _plugin.zonedSchedule(
          id: _firstId + i,
          title: title,
          body: body,
          // An exact instant; the evening was worked out in local time.
          scheduledDate: tz.TZDateTime.from(times[i], tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      if (weekly != null) {
        await _plugin.zonedSchedule(
          id: _weeklyId,
          title: weekly.$1,
          body: weekly.$2,
          scheduledDate: tz.TZDateTime.from(weeklyAt(from, at: at), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // A reminder is a nicety; never let it break the app.
    }
  }
}
