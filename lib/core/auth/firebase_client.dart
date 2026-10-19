import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// One initialization shared by config reads and optional account actions.
class FirebaseClient {
  static Future<void>? _initializing;

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
    final config =
        jsonDecode(
              await rootBundle.loadString(
                'assets/firebase/android_options.json',
              ),
            )
            as Map<String, dynamic>;
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey'],
          appId: config['appId'],
          messagingSenderId: config['messagingSenderId'],
          projectId: config['projectId'],
          storageBucket: config['storageBucket'],
        ),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') rethrow;
    }
  }
}
