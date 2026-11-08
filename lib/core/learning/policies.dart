import 'dart:math';
import '../content/content_repository.dart';
import 'age_band.dart';
export 'age_band.dart';

abstract final class HintPolicy {
  static int afterWrong(int count, {int fadeAfterErrors = 2}) =>
      count >= fadeAfterErrors ? 4 : 2;
  static Duration initialDelay(Difficulty difficulty) =>
      Duration(seconds: [4, 6, 8][difficulty.index]);
  static int afterIdle(int seconds, Difficulty difficulty) {
    final first = initialDelay(difficulty).inSeconds;
    return seconds >= first + 8
        ? 3
        : seconds >= first + 4
        ? 2
        : seconds >= first
        ? 1
        : 0;
  }
}

abstract final class DifficultyEngine {
  static Difficulty recommend(Difficulty current, List<int> hints) {
    if (hints.length < 10) return current;
    final recent = hints.sublist(hints.length - 10);
    final independent = recent.where((h) => h == 0).length;
    final high = recent.where((h) => h >= 3).length;
    final full = recent.where((h) => h == 4).length;
    if (independent >= 8 && high <= 1) {
      return Difficulty.values[min(2, current.index + 1)];
    }
    if (independent < 5 || full > 3) {
      return Difficulty.values[max(0, current.index - 1)];
    }
    return current;
  }
}

class ItemScheduler {
  final Random random;
  String? previous;

  /// Medium and hard (Yunus, 8 Nov 2026): nothing is asked twice in one
  /// game. Easy may repeat, to teach.
  bool noRepeat = false;

  /// What this game has already asked.
  final Set<String> used = {};

  /// A round had to repeat something because nothing new was left.
  bool exhausted = false;
  ItemScheduler([Random? random]) : random = random ?? Random();

  /// Keeps only what has not been asked yet; when nothing is left the
  /// whole list comes back and [exhausted] is set.
  List<T> fresh<T>(List<T> options, String Function(T) key) {
    if (!noRepeat) return options;
    final left = options.where((x) => !used.contains(key(x))).toList();
    if (left.isNotEmpty) return left;
    exhausted = true;
    return options;
  }

  ContentItem next(List<ContentItem> all, Map<String, int> struggle) {
    final pool = fresh(all, (x) => x.id);
    final eligible = pool.where((x) => x.id != previous).toList();
    final source = eligible.isEmpty ? pool : eligible;
    if (source.isEmpty) throw StateError('No eligible content');
    final weighted = <ContentItem>[];
    for (final item in source) {
      weighted.addAll(List.filled(1 + min(4, struggle[item.id] ?? 0), item));
    }
    final target = weighted[random.nextInt(weighted.length)];
    previous = target.id;
    used.add(target.id);
    return target;
  }
}

class SurveyResult {
  final Difficulty difficulty;
  final bool introduction, tapAlternative;
  final String celebration;
  final int stages;
  const SurveyResult(
    this.difficulty,
    this.introduction,
    this.tapAlternative,
    this.celebration,
    this.stages,
  );
}

abstract final class SurveyMapper {
  static const knownThemeIds = [
    'animals',
    'produce',
    'colors',
    'numbers',
    'vehicles',
    'shapes',
    'clothes',
    'home',
    'body',
    'emotions',
    'food',
  ];
  static const favoriteThemeIds = [
    'animals',
    'vehicles',
    'colors',
    'numbers',
    'music',
    'food',
    'produce',
    'shapes',
  ];
  static List<int> choices(dynamic value) => value is List
      ? value.whereType<int>().toList()
      : value is int
      ? [value]
      : [];
  static List<String> favorites(Map<String, dynamic> answers) => [
    for (final index in choices(answers['favorite']))
      if (index >= 0 && index < favoriteThemeIds.length)
        favoriteThemeIds[index],
  ];
  static Difficulty initialForTheme(
    Map<String, dynamic> answers,
    String theme,
  ) {
    // With a known age the band's default tier is the "ready" tier and an
    // unfamiliar theme opens one tier lower; without one, Orta/Kolay.
    final band = AgeBand.of(answers);
    final ready = band?.defaultTier ?? Difficulty.medium;
    final lower = Difficulty.values[max(0, ready.index - 1)];
    if (answers['receptive'] == 0) return Difficulty.easy;
    if (theme == 'numbers' && answers.containsKey('counting')) {
      return (answers['counting'] as int) >= 2 ? ready : lower;
    }
    if (answers.containsKey('known')) {
      return choices(answers['known']).any(
            (i) =>
                i >= 0 && i < knownThemeIds.length && knownThemeIds[i] == theme,
          )
          ? ready
          : lower;
    }
    return band?.defaultTier ?? map(answers).difficulty;
  }

  static SurveyResult map(Map<String, dynamic> answers) => SurveyResult(
    answers['receptive'] == 2 ? Difficulty.medium : Difficulty.easy,
    answers['receptive'] != 2,
    answers['motor'] != 2,
    answers['sound'] == 0 ? 'off' : 'simple',
    answers['focus'] == 0
        ? 3
        : answers['focus'] == 2
        ? 8
        : 5,
  );
}
