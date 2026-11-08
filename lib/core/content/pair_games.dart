/// Games that pair something shown or heard with one of the theme's cards:
/// "What colour is the banana?", "Which one is like a circle?", "How does
/// Ali feel?" (a small scene), "What do we see with?". Each game is data in
/// assets/content/pair_games.json, so new rounds need no code (Nov 2026).
library;

class PairRound {
  /// The card or extra picture shown next to the question; null when the
  /// round is only heard (a sound or a spoken question).
  final String? stimulus;

  /// The right card (an item of the game's theme).
  final String target;

  /// Other cards that would also be right; never offered as wrong choices.
  final List<String> alsoRight;

  /// Sound played before the question (e.g. a laugh), if any.
  final String? sound;
  final Map<String, String> text, audio;
  const PairRound({
    required this.stimulus,
    required this.target,
    required this.text,
    required this.audio,
    this.alsoRight = const [],
    this.sound,
  });

  factory PairRound.fromJson(Map<String, dynamic> j) => PairRound(
    stimulus: j['stimulus'] as String?,
    target: j['target'] as String,
    alsoRight: List<String>.from((j['alsoRight'] ?? const []) as List),
    sound: j['sound'] as String?,
    text: Map<String, String>.from(j['text'] as Map),
    audio: Map<String, String>.from((j['audio'] ?? const {}) as Map),
  );

  String textFor(String locale) => text[locale] ?? text['tr'] ?? '';
}

class PairGame {
  final String id, theme;

  /// "object" (plain cards) or "basket" (the shown thing is put into one
  /// of the baskets).
  final String look;

  /// Where wrong choices come from: the theme's own cards (default) or an
  /// explicit list of card ids.
  final List<String> choicePool;

  /// Clip played after a right answer instead of the card's name.
  final Map<String, String> successAudio;
  final List<PairRound> rounds;
  const PairGame({
    required this.id,
    required this.theme,
    required this.rounds,
    this.look = 'object',
    this.choicePool = const [],
    this.successAudio = const {},
  });

  factory PairGame.fromJson(String id, Map<String, dynamic> j) => PairGame(
    id: id,
    theme: j['theme'] as String,
    look: (j['look'] ?? 'object') as String,
    choicePool: List<String>.from((j['choicePool'] ?? const []) as List),
    successAudio: Map<String, String>.from(
      (j['successAudio'] ?? const {}) as Map,
    ),
    rounds: [
      for (final r in j['rounds'] as List)
        PairRound.fromJson(r as Map<String, dynamic>),
    ],
  );

  /// Every target in this game shown with [stimulus] (they are all right).
  Set<String> rightFor(PairRound round) => {
    round.target,
    ...round.alsoRight,
    for (final other in rounds)
      if (round.stimulus != null && other.stimulus == round.stimulus)
        other.target,
  };
}
