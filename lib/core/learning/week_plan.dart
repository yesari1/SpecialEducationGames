/// One day of the first-run "7-day plan" (onboarding). Built from the same
/// inputs as the home screen: the theme order (liked themes first) and each
/// theme's available games; nothing is stored, the home screen and today's
/// path stay the real planners.
class PlanDay {
  final String theme;
  final List<String> games;
  const PlanDay(this.theme, this.games);
}

abstract final class WeekPlan {
  /// The Learn card's game id (free in every theme).
  static const learn = 'G02';

  /// Days that only use free cards (a free child can play all of them).
  static const freeDays = 3;

  /// [themes]: theme ids in home-screen order (liked themes first), only
  /// themes with games. [gamesOf]: a theme's available games in card order.
  /// [isFree]: whether a card is free. Each day takes the next theme and up
  /// to [perDay] games: on the first [freeDays] days free games only (Learn
  /// last), afterwards new games first so the week shows what Premium adds.
  static List<PlanDay> build({
    required List<String> themes,
    required List<String> Function(String theme) gamesOf,
    required bool Function(String theme, String game) isFree,
    int days = 7,
    int perDay = 2,
  }) {
    if (themes.isEmpty) return const [];
    return [
      for (var day = 0; day < days; day++)
        _day(themes[day % themes.length], day, gamesOf, isFree, perDay),
    ];
  }

  static PlanDay _day(
    String theme,
    int day,
    List<String> Function(String) gamesOf,
    bool Function(String, String) isFree,
    int perDay,
  ) {
    final all = gamesOf(theme);
    final free = all.where((g) => isFree(theme, g));
    final games = [
      ...free.where((g) => g != learn),
      ...free.where((g) => g == learn),
    ];
    if (day >= freeDays) {
      final paid = all.where((g) => !isFree(theme, g) && g != learn).toList();
      games.insertAll(0, paid.take(1));
    }
    return PlanDay(theme, games.toSet().take(perDay).toList());
  }
}
