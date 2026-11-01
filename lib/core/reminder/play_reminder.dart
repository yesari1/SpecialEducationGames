import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// One gentle reminder at [hour] o'clock on each day nothing was played.
///
/// Local notifications only: nothing leaves the device. The next [days]
/// evenings are scheduled ahead and rescheduled whenever the app opens or a
/// game starts, so a day with play drops its own reminder and the following
/// days stay covered even if the app is not opened again.
class PlayReminder {
  static const hour = 18;
  static const days = 7;
  static const _firstId = 7100;
  static const _channel = 'play_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _ready;

  PlayReminder({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// The real device, not the target platform a test pretends to be.
  static bool get supported => !kIsWeb && Platform.isAndroid;

  Future<bool> _init() => _ready ??= () async {
    try {
      return await _plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            ),
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Android's own permission dialog (Android 13+). True when allowed.
  Future<bool> requestPermission() async {
    if (!supported || !await _init()) return false;
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Evenings that get a reminder, from [now] on: today only if nothing was
  /// played yet and it is not past [hour].
  static List<DateTime> evenings(DateTime now, {required bool playedToday}) =>
      [
            for (var d = 0; d < days; d++)
              DateTime(now.year, now.month, now.day + d, hour),
          ]
          .where((at) => at.isAfter(now) && !(playedToday && at.day == now.day))
          .toList();

  /// Drops every planned reminder.
  Future<void> cancel() async {
    if (!supported || !await _init()) return;
    try {
      for (var i = 0; i < days; i++) {
        await _plugin.cancel(id: _firstId + i);
      }
    } catch (_) {}
  }

  Future<void> reschedule({
    required bool playedToday,
    required String title,
    required String body,
    required String channel,
    DateTime? now,
  }) async {
    if (!supported || !await _init()) return;
    await cancel();
    try {
      final at = evenings(now ?? DateTime.now(), playedToday: playedToday);
      for (var i = 0; i < at.length; i++) {
        await _plugin.zonedSchedule(
          id: _firstId + i,
          title: title,
          body: body,
          // An exact instant; the evening was worked out in local time.
          scheduledDate: tz.TZDateTime.from(at[i], tz.UTC),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel,
              channel,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // A reminder is a nicety; never let it break the app.
    }
  }
}
