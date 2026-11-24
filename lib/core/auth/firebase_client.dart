import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One initialization shared by config reads and optional account actions.
class FirebaseClient {
  static Future<void>? _initializing;

  /// The app's Firebase settings for this platform (iOS has its own app in
  /// the project, made from its GoogleService-Info.plist).
  static Future<Map<String, dynamic>> options() async => _options ??=
      jsonDecode(
            await rootBundle.loadString(
              !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                  ? 'assets/firebase/ios_options.json'
                  : 'assets/firebase/android_options.json',
            ),
          )
          as Map<String, dynamic>;
  static Map<String, dynamic>? _options;

  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    final pending = _initializing ??= _initialize();
    try {
      await pending.timeout(const Duration(seconds: 15));
    } finally {
      if (identical(_initializing, pending)) _initializing = null;
    }
  }

  static Future<void> _initialize() async {
    final config = await options();
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey'],
          appId: config['appId'],
          messagingSenderId: config['messagingSenderId'],
          projectId: config['projectId'],
          storageBucket: config['storageBucket'],
          iosClientId: config['iosClientId'],
          iosBundleId: config['iosBundleId'],
        ),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') rethrow;
    }
  }
}
