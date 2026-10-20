import 'dart:math';
import 'package:just_audio/just_audio.dart';

abstract interface class AudioBackend {
  Future<Duration?> setAsset(String asset);
  Future<void> setVolume(double volume);
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();
}

class _JustAudioBackend implements AudioBackend {
  AudioPlayer? _player;
  AudioPlayer get player => _player ??= AudioPlayer();
  @override
  Future<Duration?> setAsset(String asset) => player.setAsset(asset);
  @override
  Future<void> setVolume(double volume) => player.setVolume(volume);
  @override
  Future<void> play() => player.play();
  @override
  Future<void> stop() => _player?.stop() ?? Future.value();
  @override
  Future<void> dispose() => _player?.dispose() ?? Future.value();
}

class AudioService {
  final AudioBackend _backend;
  final Duration loadTimeout, stopTimeout;
  final Duration? playbackTimeout;
  AudioService({
    AudioBackend? backend,
    this.loadTimeout = const Duration(seconds: 5),
    this.stopTimeout = const Duration(seconds: 2),
    this.playbackTimeout,
  }) : _backend = backend ?? _JustAudioBackend();
  int _generation = 0;
  bool enabled = true, _disposed = false, lastPlaybackFailed = false;
  int speechVolume = 100, effectVolume = 60;

  Future<void> updatePreferences({
    required bool enabled,
    required int speechVolume,
    required int effectVolume,
  }) async {
    if (speechVolume < 0 ||
        speechVolume > 100 ||
        effectVolume < 0 ||
        effectVolume > 100) {
      throw ArgumentError('volume');
    }
    final changed =
        this.enabled != enabled ||
        this.speechVolume != speechVolume ||
        this.effectVolume != effectVolume;
    this.enabled = enabled;
    this.speechVolume = speechVolume;
    this.effectVolume = effectVolume;
    // Stop the old profile's voice instead of letting it continue at old levels.
    if (changed) await stop();
  }

  Future<void> _safeStop() async {
    try {
      await _backend.stop().timeout(stopTimeout);
    } catch (_) {
      /* Native audio may be unavailable. */
    }
  }

  Future<void> playSequence(List<String> assets) async {
    if (_disposed) return;
    final generation = ++_generation;
    lastPlaybackFailed = false;
    await _safeStop();
    if (!enabled || generation != _generation || _disposed) return;
    for (final asset in assets) {
      if (generation != _generation || _disposed || !enabled) return;
      final volume = asset.startsWith('assets/sfx/')
          ? effectVolume
          : speechVolume;
      if (volume == 0) continue;
      try {
        final duration = await _backend.setAsset(asset).timeout(loadTimeout);
        if (generation != _generation || _disposed) return;
        await _backend.setVolume(volume / 100).timeout(loadTimeout);
        if (generation != _generation || _disposed || !enabled) return;
        final limit =
            playbackTimeout ??
            Duration(
              milliseconds: min(
                8000,
                max(2000, (duration?.inMilliseconds ?? 3000) + 1000),
              ),
            );
        await _backend.play().timeout(limit);
        // A finished clip leaves the player "playing"; without a stop the
        // next play() returns at once and the following clip cuts it off.
        if (generation != _generation || _disposed) return;
        await _safeStop();
      } catch (_) {
        // An old failed load must never stop newer narration.
        if (generation != _generation || _disposed) return;
        lastPlaybackFailed = true;
        await _safeStop();
        return; // The caller can continue with the visible prompt.
      }
    }
  }

  Future<void> stop() async {
    ++_generation;
    await _safeStop();
  }

  Future<void> dispose() async {
    _disposed = true;
    ++_generation;
    try {
      await _backend.dispose().timeout(stopTimeout);
    } catch (_) {
      /* Best effort native cleanup. */
    }
  }
}
