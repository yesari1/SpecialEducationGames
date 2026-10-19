import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/audio/audio_service.dart';

class FakeAudio implements AudioBackend {
  int stops = 0;
  final oldLoad = Completer<Duration?>();
  final playing = Completer<void>();
  bool stallLoad = false;
  @override
  Future<Duration?> setAsset(String asset) => asset == 'old' || stallLoad
      ? oldLoad.future
      : Future.value(const Duration(milliseconds: 1));
  @override
  Future<void> play() => playing.future;
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'A stalled native player cannot leave a child waiting forever',
    () async {
      final backend = FakeAudio();
      final service = AudioService(
        backend: backend,
        playbackTimeout: const Duration(milliseconds: 20),
      );
      await service.playSequence(['cat']);
      expect(service.lastPlaybackFailed, true);
      expect(backend.stops, 2);
      await service.dispose();
    },
  );
  test('A stale failed load does not stop newer audio', () async {
    final backend = FakeAudio();
    final service = AudioService(backend: backend);
    final old = service.playSequence(['old']);
    await Future<void>.delayed(Duration.zero);
    final current = service.playSequence(['cat']);
    await Future<void>.delayed(Duration.zero);
    backend.oldLoad.completeError(StateError('old failed'));
    await old;
    expect(backend.stops, 2);
    expect(service.lastPlaybackFailed, false);
    backend.playing.complete();
    await current;
    await service.dispose();
  });
  test('A stalled asset load is bounded too', () async {
    final backend = FakeAudio()..stallLoad = true;
    final service = AudioService(
      backend: backend,
      loadTimeout: const Duration(milliseconds: 20),
    );
    await service.playSequence(['cat']);
    expect(service.lastPlaybackFailed, true);
    await service.dispose();
  });
}
