import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../auth/firebase_client.dart';

/// Push messages sent from the admin page (seg-notify worker). Android shows
/// one arriving in the background by itself; one arriving while the app is
/// open is shown here. The install's push address goes to its funnel record.
class PushMessages {
  static const _channel = 'announcements';
  static bool _listening = false;
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// The real device, not the target platform a test pretends to be.
  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// This install's push address (no permission prompt).
  static Future<String?> token() async {
    if (!supported) return null;
    await FirebaseClient.ensureInitialized();
    return FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 15),
    );
  }

  /// Once per app run: new addresses go to [onToken], messages arriving in
  /// the foreground are shown under [channelName].
  static Future<void> listen({
    required void Function(String token) onToken,
    required String channelName,
  }) async {
    if (!supported || _listening) return;
    _listening = true;
    FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
    } catch (_) {}
    FirebaseMessaging.onMessage.listen((message) async {
      final n = message.notification;
      if (n == null) return;
      try {
        await _plugin.show(
          id: message.hashCode & 0x7fffffff,
          title: n.title,
          body: n.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(_channel, channelName),
          ),
        );
      } catch (_) {
        // A message is a nicety; never let it break the app.
      }
    });
  }
}
