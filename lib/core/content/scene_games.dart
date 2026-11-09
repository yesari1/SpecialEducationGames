/// Games played on a picture: the child brings the right thing to the scene
/// and the scene changes (a seed gets water, Ali gets his hat, the table gets
/// its plate). Each game is data in assets/content/scene_games.json.
library;

/// Part of a picture, as fractions of its width and height.
class SceneRect {
  final double x, y, w, h;
  const SceneRect(this.x, this.y, this.w, this.h);
  factory SceneRect.fromJson(List<dynamic> j) => SceneRect(
    (j[0] as num).toDouble(),
    (j[1] as num).toDouble(),
    (j[2] as num).toDouble(),
    (j[3] as num).toDouble(),
  );
}

enum SceneStepMode {
  /// The right piece is dragged to the picture (or tapped).
  place,

  /// The tool is rubbed over the spots until they are gone (or they are
  /// tapped one by one).
  rub,

  /// The tool is moved around the zone for a while (or tapped a few times).
  stir,
}

class SceneStep {
  final SceneStepMode mode;

  /// The right piece; on rub and stir steps, the tool.
  final String piece;

  /// Wrong pieces offered beside it.
  final List<String> others;

  /// Where the piece goes and where the hint shows.
  final SceneRect zone;

  /// The piece stays on the picture here after it is placed.
  final bool stays;

  /// Its shadow waits on the picture until it is placed.
  final bool shadow;

  /// Turned by this many radians on the picture (a diagonal drawing laid
  /// straight, like the knife beside a plate).
  final double turn;

  /// The whole picture after this step, if it changes.
  final String? after;

  /// Stains to rub away (rub steps).
  final List<SceneRect> spots;

  /// Spoken when this step starts (not for the first, the round's question
  /// says it) and after it is done.
  final Map<String, String> askAudio, doneAudio;
  final Map<String, String> askText;
  const SceneStep({
    required this.mode,
    required this.piece,
    required this.zone,
    this.others = const [],
    this.stays = false,
    this.shadow = false,
    this.turn = 0,
    this.after,
    this.spots = const [],
    this.askAudio = const {},
    this.doneAudio = const {},
    this.askText = const {},
  });

  factory SceneStep.fromJson(Map<String, dynamic> j) => SceneStep(
    mode: SceneStepMode.values.byName((j['mode'] ?? 'place') as String),
    piece: j['piece'] as String,
    others: List<String>.from((j['others'] ?? const []) as List),
    zone: SceneRect.fromJson(j['zone'] as List),
    stays: (j['stays'] ?? false) as bool,
    shadow: (j['shadow'] ?? false) as bool,
    turn: ((j['turn'] ?? 0) as num).toDouble(),
    after: j['after'] as String?,
    spots: [
      for (final s in (j['spots'] ?? const []) as List)
        SceneRect.fromJson(s as List),
    ],
    askAudio: Map<String, String>.from((j['askAudio'] ?? const {}) as Map),
    doneAudio: Map<String, String>.from((j['doneAudio'] ?? const {}) as Map),
    askText: Map<String, String>.from((j['askText'] ?? const {}) as Map),
  );
}

class SceneRound {
  /// Different rounds have different keys (medium and hard never repeat one).
  final String key, tier;

  /// The item this round is recorded under in the family's reports.
  final String target;

  /// The picture the round starts from, and its width / height.
  final String stage;
  final double aspect;

  /// Shows the pieces to bring at the top of the picture (a picture recipe).
  final bool recipe;
  final Map<String, String> text, audio;
  final List<SceneStep> steps;

  /// Spoken after the last step, before the praise.
  final Map<String, String> finishAudio;
  const SceneRound({
    required this.key,
    required this.tier,
    required this.target,
    required this.stage,
    required this.text,
    required this.audio,
    required this.steps,
    this.aspect = 1.5,
    this.recipe = false,
    this.finishAudio = const {},
  });

  factory SceneRound.fromJson(Map<String, dynamic> j) => SceneRound(
    key: j['key'] as String,
    tier: j['tier'] as String,
    target: j['target'] as String,
    stage: j['stage'] as String,
    aspect: ((j['aspect'] ?? 1.5) as num).toDouble(),
    recipe: (j['recipe'] ?? false) as bool,
    text: Map<String, String>.from(j['text'] as Map),
    audio: Map<String, String>.from((j['audio'] ?? const {}) as Map),
    steps: [
      for (final s in j['steps'] as List)
        SceneStep.fromJson(s as Map<String, dynamic>),
    ],
    finishAudio: Map<String, String>.from(
      (j['finishAudio'] ?? const {}) as Map,
    ),
  );
}

class SceneGame {
  final String id, theme;
  final List<SceneRound> rounds;
  const SceneGame({required this.id, required this.theme, required this.rounds});
  factory SceneGame.fromJson(String id, Map<String, dynamic> j) => SceneGame(
    id: id,
    theme: j['theme'] as String,
    rounds: [
      for (final r in j['rounds'] as List)
        SceneRound.fromJson(r as Map<String, dynamic>),
    ],
  );
}
