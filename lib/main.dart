import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/app_state.dart';
import 'core/audio/audio_service.dart';
import 'core/content/content_repository.dart';
import 'core/db/app_database.dart';
import 'core/config/firestore_config_source.dart';
import 'core/licensing/app_licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLicenses.registerNunito();
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  );
  final state = AppState(
    await ContentRepository.load(),
    AppDatabase(),
    AudioService(),
  );
  await state.load();
  runApp(ProviderScope(child: EducationApp(state: state)));
  unawaited(state.billing.initialize());
  unawaited(state.refreshConfiguration(FirestoreConfigSource.read));
}
