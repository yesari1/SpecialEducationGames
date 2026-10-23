import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/ui/components.dart';
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
  await _loadPhotoBounds();
  final state = AppState(
    await ContentRepository.load(),
    AppDatabase(),
    AudioService(),
  );
  await state.load();
  UiSound.service = state.audio;
  runApp(ProviderScope(child: EducationApp(state: state, accountGate: true)));
  unawaited(state.billing.initialize());
  unawaited(state.refreshConfiguration(FirestoreConfigSource.read));
  unawaited(state.reportInstall());
}

/// Precomputed photo framing (see tools/build_photo_bounds.py). Missing or
/// unreadable data only means photos are measured on first display.
Future<void> _loadPhotoBounds() async {
  try {
    final raw = await rootBundle.loadString('assets/content/photo_bounds.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    PhotoVisual.registerBounds({
      for (final entry in data.entries)
        if (entry.value case [
          final num l,
          final num t,
          final num r,
          final num b,
        ])
          entry.key: Rect.fromLTRB(
            l.toDouble(),
            t.toDouble(),
            r.toDouble(),
            b.toDouble(),
          ),
    });
  } catch (_) {}
}
