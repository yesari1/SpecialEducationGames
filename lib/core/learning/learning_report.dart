import '../db/app_database.dart';

class ReportDay {
  final DateTime date;
  final List<Trial> trials;
  final List<GameSession> sessions;
  const ReportDay(this.date, this.trials, this.sessions);
  double get minutes =>
      sessions.fold<int>(0, (sum, x) => sum + x.activeMs) / 60000;
  double? get independence =>
      trials.isEmpty ? null : trials.where(independent).length / trials.length;
  double? get latencySeconds => trials.isEmpty
      ? null
      : trials.fold<int>(0, (sum, x) => sum + x.latencyMs) /
            trials.length /
            1000;
  double? get idleSeconds => trials.isEmpty
      ? null
      : trials.fold<int>(0, (sum, x) => sum + x.idleMs) / trials.length / 1000;
  static bool independent(Trial t) => t.maxHint == 0 && t.wrongCount == 0;
}

class LearningReport {
  final List<ReportDay> days;
  late final List<Trial> previousTrials;
  LearningReport(List<Trial> trials, List<GameSession> sessions, DateTime now)
    : days = List.generate(7, (i) {
        final date = DateTime(now.year, now.month, now.day - 6 + i);
        final next = DateTime(date.year, date.month, date.day + 1);
        bool onDay(DateTime time) =>
            !time.isBefore(date) && time.isBefore(next) && !time.isAfter(now);
        return ReportDay(
          date,
          trials.where((x) => onDay(x.at)).toList(),
          sessions.where((x) => onDay(x.startedAt)).toList(),
        );
      }) {
    final start = DateTime(now.year, now.month, now.day - 6);
    final previousStart = DateTime(start.year, start.month, start.day - 7);
    previousTrials = trials
        .where((x) => !x.at.isBefore(previousStart) && x.at.isBefore(start))
        .toList();
  }
  List<Trial> get trials => days.expand((x) => x.trials).toList();
  int get completedRounds =>
      days.expand((x) => x.sessions).where((x) => x.completed).length;
  List<Trial> forSkill(String skill) =>
      trials.where((x) => gameSkills[x.gameId] == skill).toList();
  double? skillTrend(String skill) {
    final current = forSkill(skill);
    final previous = previousTrials
        .where((x) => gameSkills[x.gameId] == skill)
        .toList();
    if (current.length < 3 || previous.length < 3) return null;
    return current.where(ReportDay.independent).length / current.length -
        previous.where(ReportDay.independent).length / previous.length;
  }

  static const skillNames = {
    'receptive_language': ['Alıcı Dil ve Kelime', 'Receptive language'],
    'visual_perception': ['Görsel Algı', 'Visual perception'],
    'auditory': ['İşitsel Dikkat', 'Auditory attention'],
    'categorization': ['Kavram ve Sınıflama', 'Categorization'],
    'math_readiness': ['Sayılar ve Matematik Öncesi', 'Math readiness'],
    'fine_motor': ['İnce Motor', 'Fine motor'],
    'memory_sequence': ['Dikkat, Hafıza ve Sıralama', 'Attention and memory'],
    'social_emotional': ['Sosyal-Duygusal', 'Social and emotional'],
    'daily_living': ['Günlük Yaşam ve Öz Bakım', 'Daily living'],
  };
  static const gameSkills = {
    'G01': 'receptive_language',
    'G34': 'receptive_language',
    'G14': 'visual_perception',
    'G10': 'auditory',
    'G04': 'categorization',
    'G33': 'math_readiness',
    'G35': 'math_readiness',
    'G36': 'math_readiness',
  };
}

class ItemLearningSummary {
  final String itemId;
  final List<Trial> observations;
  ItemLearningSummary(this.itemId, Iterable<Trial> trials)
    : observations = trials.toList()..sort((a, b) => a.at.compareTo(b.at));
  int get independentStreak {
    var count = 0;
    for (final trial in observations.reversed) {
      if (!ReportDay.independent(trial)) break;
      count++;
    }
    return count;
  }

  bool get independentlyAnswered => independentStreak >= 3;
  bool get needsSupport =>
      observations.length >= 3 &&
      observations.reversed
              .take(3)
              .where((x) => x.maxHint >= 3 || x.wrongCount >= 2)
              .length >=
          2;
  static List<ItemLearningSummary> fromTrials(
    List<Trial> trials,
    DateTime now,
  ) {
    final grouped = <String, List<Trial>>{};
    for (final trial in trials.where((x) => !x.at.isAfter(now))) {
      grouped.putIfAbsent(trial.targetId, () => []).add(trial);
    }
    return grouped.entries
        .map((x) => ItemLearningSummary(x.key, x.value))
        .toList()
      ..sort(
        (a, b) => b.observations.last.at.compareTo(a.observations.last.at),
      );
  }
}
