import 'dart:async';
import 'dart:math';
import '../../core/learning/policies.dart';

class HintController {
  final void Function(int level) onChanged;
  Timer? _timer;
  int level = 0, maximum = 0;
  HintController({required this.onChanged});
  void start({
    required Duration? initialDelay,
    required int Function() elapsedMs,
    required bool Function() paused,
  }) {
    reset();
    if (initialDelay == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (paused()) return;
      final seconds = elapsedMs() ~/ 1000, first = initialDelay.inSeconds;
      final next = seconds >= first + 8
          ? 3
          : seconds >= first + 4
          ? 2
          : seconds >= first
          ? 1
          : 0;
      if (next > level) _set(next);
    });
  }

  void wrong(
    int wrongCount, {
    bool fadeWrongChoices = true,
    int fadeAfterErrors = 2,
  }) => _set(
    fadeWrongChoices
        ? HintPolicy.afterWrong(wrongCount, fadeAfterErrors: fadeAfterErrors)
        : 2,
  );
  void _set(int next) {
    level = max(level, next);
    maximum = max(maximum, level);
    onChanged(level);
  }

  void reset() {
    _timer?.cancel();
    level = 0;
    maximum = 0;
  }

  void stop() => _timer?.cancel();
  void dispose() => stop();
}
