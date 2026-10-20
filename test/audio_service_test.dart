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
  test('every clip in a sequence plays to its end (number chains)', () async {
    final backend = StickyPlayingAudio();
    final service = AudioService(backend: backend);
    await service.playSequence(['five', 'six', 'which_next']);
    expect(backend.played, ['five', 'six', 'which_next']);
    await service.dispose();
  });
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
  test('A replay while narration plays does not restart it', () async {
    final backend = FakeAudio();
    final service = AudioService(backend: backend);
    final first = service.playSequence(['listen', 'which_number']);
    await Future<void>.delayed(Duration.zero);
    expect(service.busy, isTrue);
    final stopsBefore = backend.stops;
    await service.playSequenceIfIdle(['listen', 'which_number']);
    // Nothing was stopped or restarted.
    expect(backend.stops, stopsBefore);
    expect(service.busy, isTrue);
    backend.playing.complete();
    await first;
    expect(service.busy, isFalse);
    // Once finished, a replay plays again.
    final again = StickyPlayingAudio();
    final idle = AudioService(backend: again);
    await idle.playSequenceIfIdle(['listen']);
    expect(again.played, ['listen']);
    await service.dispose();
    await idle.dispose();
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

/// Mimics just_audio: after a clip finishes the player still reports
/// "playing", and play() on a playing player returns at once.
class StickyPlayingAudio implements AudioBackend {
  bool playing = false;
  final played = <String>[];
  String? _current;
  @override
  Future<Duration?> setAsset(String asset) async {
    _current = asset;
    return const Duration(milliseconds: 10);
  }

  @override
  Future<void> play() async {
    if (playing) return;
    playing = true;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    played.add(_current!);
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> stop() async => playing = false;
  @override
  Future<void> dispose() async {}
}

