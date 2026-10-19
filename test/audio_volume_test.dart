import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/audio/audio_service.dart';

class VolumeBackend implements AudioBackend {
  final assets = <String>[];
  final volumes = <double>[];
  int plays = 0;
  Completer<void>? firstVolume;
  @override
  Future<Duration?> setAsset(String asset) async {
    assets.add(asset);
    return const Duration(milliseconds: 1);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
    if (volumes.length == 1 && firstVolume != null) await firstVolume!.future;
  }

  @override
  Future<void> play() async {
    plays++;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'Mixed narration/effects apply independent native levels before play',
    () async {
      final backend = VolumeBackend();
      final service = AudioService(backend: backend);
      await service.playSequence([
        'assets/audio/tr/cat.mp3',
        'assets/sfx/cat.mp3',
      ]);
      expect(backend.volumes, [1.0, .6]);
      expect(backend.plays, 2);
      await service.updatePreferences(
        enabled: true,
        speechVolume: 35,
        effectVolume: 0,
      );
      await service.playSequence([
        'assets/sfx/cat.mp3',
        'assets/audio/en/cat.mp3',
      ]);
      expect(
        backend.assets.length,
        3,
      ); // Muted effects aren't loaded or played.
      expect(backend.volumes.last, .35);
      expect(backend.plays, 3);
      await service.updatePreferences(
        enabled: true,
        speechVolume: 0,
        effectVolume: 80,
      );
      await service.playSequence([
        'assets/audio/tr/cat.mp3',
        'assets/sfx/cat.mp3',
      ]);
      expect(backend.volumes.last, .8);
      expect(backend.plays, 4);
      await service.updatePreferences(
        enabled: false,
        speechVolume: 35,
        effectVolume: 60,
      );
      await service.playSequence([
        'assets/sfx/cat.mp3',
        'assets/audio/en/cat.mp3',
      ]);
      expect(backend.plays, 4);
      expect(service.lastPlaybackFailed, false);
      await service.dispose();
    },
  );

  test(
    'Stale native volume completion cannot start obsolete narration',
    () async {
      final backend = VolumeBackend()..firstVolume = Completer<void>();
      final service = AudioService(backend: backend);
      final obsolete = service.playSequence(['assets/audio/tr/cat.mp3']);
      await Future<void>.delayed(Duration.zero);
      await service.updatePreferences(
        enabled: true,
        speechVolume: 20,
        effectVolume: 75,
      );
      await service.playSequence(['assets/sfx/cat.mp3']);
      backend.firstVolume!.complete();
      await obsolete;
      expect(backend.volumes, [1.0, .75]);
      expect(backend.plays, 1);
      expect(service.lastPlaybackFailed, false);
      await service.dispose();
    },
  );

  test('A stalled native volume operation is bounded', () async {
    final backend = VolumeBackend()..firstVolume = Completer<void>();
    final service = AudioService(
      backend: backend,
      loadTimeout: const Duration(milliseconds: 20),
    );
    await service.playSequence(['assets/audio/tr/cat.mp3']);
    expect(backend.plays, 0);
    expect(service.lastPlaybackFailed, true);
    await service.dispose();
  });
}
