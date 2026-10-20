import 'dart:math';
import '../content/content_repository.dart';

/// The four age bands set where a profile starts. Kolay/Orta/Zor stay as they
/// are (Zor premium, free-tier rules unchanged); a band only decides what each
/// tier looks like for this child: choices, number range, questions per game
/// and hint timing. Onboarding answers and the automatic difficulty still
/// move the tier, and the parent can shift the band one step either way.
enum AgeBand {
  /// 2–3 "İlk adımlar / First steps".
  firstSteps,

  /// 4–5 "Keşif / Explore".
  explore,

  /// 6–7 "Okula hazırlık / School ready".
  schoolReady,

  /// 8+ "Pekiştirme / Practice".
  practice;

  static AgeBand forAge(int years) => years <= 3
      ? firstSteps
      : years <= 5
      ? explore
      : years <= 7
      ? schoolReady
      : practice;

  /// Band of a stored survey: the exact `ageYears` when present, otherwise
  /// the legacy `age` range index (0: 2–3 … 3: 8+). Null when no age is known.
  static AgeBand? fromAge(Map<String, dynamic> survey) {
    final years = survey['ageYears'];
    if (years is int) return forAge(years);
    final legacy = survey['age'];
    if (legacy is int && legacy >= 0 && legacy < values.length) {
      return values[legacy];
    }
    return null;
  }

  /// Parent's adjustment stored with the survey: -1 easier, 1 harder.
  static int shiftOf(Map<String, dynamic> survey) {
    final value = survey[shiftKey];
    return value is int ? value.clamp(-1, 1) : 0;
  }

  static const shiftKey = 'ageLevelShift';

  /// The band games use: the age band moved by the parent's shift.
  static AgeBand? of(Map<String, dynamic> survey) {
    final band = fromAge(survey);
    if (band == null) return null;
    return values[(band.index + shiftOf(survey)).clamp(0, values.length - 1)];
  }

  /// The tier a theme opens on when no survey answer says otherwise. Zor is
  /// never a default because it stays premium.
  Difficulty get defaultTier =>
      this == firstSteps ? Difficulty.easy : Difficulty.medium;

  /// Questions per game.
  int get stages => const [5, 6, 8, 10][index];

  /// Seconds added to the automatic hint delay: sooner for the youngest,
  /// later for practice.
  int get hintOffsetSeconds => const [-1, 0, 0, 2][index];

  /// 2–3 sees the tap games first; drag games move to the end of the list.
  bool get prefersTap => this == firstSteps;

  /// Games that ask for a drag (shadow match, basket sort, fill the basket).
  static const dragGames = {'G15', 'G23', 'G38'};

  /// 8+ also sees less familiar items (one content tier up).
  Difficulty contentTier(Difficulty tier) => this == practice
      ? Difficulty.values[min(tier.index + 1, Difficulty.hard.index)]
      : tier;

  /// Level 0–3 for a tier: the band itself at [defaultTier], one step per
  /// tier away from it.
  int level(Difficulty tier) =>
      (index + tier.index - defaultTier.index).clamp(0, 3);

  int choices(Difficulty tier) => const [2, 3, 4, 4][level(tier)];

  /// Highest number in number games.
  int maxNumber(Difficulty tier) => const [3, 5, 10, 20][level(tier)];

  /// Games that draw the objects to count stay at 10 or below.
  int countableMax(Difficulty tier) => min(10, maxNumber(tier));

  /// Round length: an explicit parent setting wins; then the band, two
  /// shorter when the survey says the child focuses for only 1–2 minutes.
  int stagesFor(Map<String, dynamic> survey) =>
      survey['focus'] == 0 ? max(3, stages - 2) : stages;
}
