import '../content/content_repository.dart';

class LearningObservation {
  final String itemId;
  final int hint, wrongCount;
  const LearningObservation(this.itemId, this.hint, this.wrongCount);
}

class ItemPerformance {
  final int independentStreak, fullSupportStreak;
  const ItemPerformance({
    this.independentStreak = 0,
    this.fullSupportStreak = 0,
  });
  Duration hintDelay(Difficulty difficulty) {
    final base = [4, 6, 8][difficulty.index];
    if (independentStreak >= 6) return const Duration(seconds: 10);
    if (independentStreak >= 3) return Duration(seconds: base < 8 ? 8 : 10);
    return Duration(seconds: base);
  }

  int fieldSize(int normal) =>
      fullSupportStreak >= 2 ? (normal - 1).clamp(1, 4) : normal;
  static Map<String, ItemPerformance> fromHistory(
    Iterable<LearningObservation> history,
  ) {
    final result = <String, ItemPerformance>{};
    for (final observation in history) {
      final before = result[observation.itemId] ?? const ItemPerformance();
      result[observation.itemId] = ItemPerformance(
        independentStreak: observation.hint == 0 && observation.wrongCount == 0
            ? before.independentStreak + 1
            : 0,
        fullSupportStreak: observation.hint == 4
            ? before.fullSupportStreak + 1
            : 0,
      );
    }
    return result;
  }
}
