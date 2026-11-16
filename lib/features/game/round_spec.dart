import '../../core/content/content_repository.dart';

enum GamePromptKey {
  counting,
  compareMagnitude,
  compareNumbers,
  groupMembership,
  findMatch,
  listenForNumber,
  listenForSoundSource,
  sequenceNext,
  sequenceMissing,
  oddOneOut,
  shadowMatch,
  sortIntoBasket,
  numberQuantity,
  fillCount,
  whichSound,
}

/// How answer choices are drawn on the stage.
enum ChoiceLook { object, silhouette, basket, sound }

class RoundSpec {
  final ContentItem target;
  final List<ContentItem> choices;
  final String promptTr, promptEn;
  final GamePromptKey? promptKey;
  final List<String> sequence;
  final int? count;
  final ContentItem? stimulus;
  final ContentItem? quantityItem;
  final String? promptImagePath, correctChoiceImagePath;
  final Map<String, int> quantities;
  final bool introduction;

  /// Choices may be drawn as shadows or baskets instead of plain objects.
  final ChoiceLook look;

  /// The prompt object can be dragged onto a choice (tapping still works).
  final bool dragStimulus;

  /// Fill-the-basket games: how many of [stimulus] go into the basket.
  final int? fillCount;

  /// Group choices: a few member items drawn as the group's picture.
  final Map<String, List<ContentItem>> groupMembers;

  /// Clips that ask this round's own question, per language (pair games).
  final Map<String, List<String>> promptCues;

  /// Clips after a right answer, per language; empty uses the defaults.
  final Map<String, List<String>> successCueOverride;

  /// All choices stay in one row on small phones (no paging), so the right
  /// one is never on a hidden page.
  final bool oneRow;

  /// The question stands beside the stage instead of above it, so a picture
  /// the child taps can use the full height.
  final bool promptBeside;

  /// How long a right answer stays on screen before the next round.
  final Duration rightHold;

  /// The whole round is played on a picture (see SceneGameView).
  final SceneRound? scene;

  /// The cards a scene round's steps use, by id.
  final Map<String, ContentItem> scenePieces;

  /// A picture shown large after a right answer (pair games).
  final String? resultImagePath;

  /// The result picture comes up in the middle of the game instead of over
  /// the whole screen; only the choices make way for it ("Bugün Ne
  /// Giysek?", Yunus 16 November 2026).
  final bool resultInPlace;

  /// The view fills the page under the top bar; it shows the question itself.
  final bool fullStage;

  /// Basket choices drawn big, without a basket (a person, a building).
  final bool plainTargets;

  /// The tune of a piano round: key numbers (0 = Do ... 7 = high Do), and
  /// which places in the tune are long notes.
  final List<int> notes;
  final Set<int> longNotes;
  const RoundSpec({
    required this.target,
    required this.choices,
    required this.promptTr,
    required this.promptEn,
    this.promptKey,
    this.sequence = const [],
    this.count,
    this.stimulus,
    this.quantityItem,
    this.promptImagePath,
    this.correctChoiceImagePath,
    this.quantities = const {},
    this.introduction = false,
    this.look = ChoiceLook.object,
    this.dragStimulus = false,
    this.fillCount,
    this.groupMembers = const {},
    this.promptCues = const {},
    this.successCueOverride = const {},
    this.oneRow = false,
    this.promptBeside = false,
    this.rightHold = const Duration(milliseconds: 1500),
    this.scene,
    this.scenePieces = const {},
    this.resultImagePath,
    this.resultInPlace = false,
    this.fullStage = false,
    this.plainTargets = false,
    this.notes = const [],
    this.longNotes = const {},
  });
  RoundSpec withChoices(List<ContentItem> choices) => RoundSpec(
    target: target,
    choices: choices,
    promptTr: promptTr,
    promptEn: promptEn,
    promptKey: promptKey,
    sequence: sequence,
    count: count,
    stimulus: stimulus,
    quantityItem: quantityItem,
    promptImagePath: promptImagePath,
    correctChoiceImagePath: correctChoiceImagePath,
    quantities: quantities,
    introduction: introduction,
    look: look,
    dragStimulus: dragStimulus,
    fillCount: fillCount,
    groupMembers: groupMembers,
    promptCues: promptCues,
    successCueOverride: successCueOverride,
    oneRow: oneRow,
    promptBeside: promptBeside,
    rightHold: rightHold,
    scene: scene,
    scenePieces: scenePieces,
    resultImagePath: resultImagePath,
    resultInPlace: resultInPlace,
    fullStage: fullStage,
    plainTargets: plainTargets,
    notes: notes,
    longNotes: longNotes,
  );
  RoundSpec asIntroduction() => RoundSpec(
    target: target,
    choices: [target],
    promptTr: 'Bu ${target.name('tr').toLowerCase()}. Dokun.',
    promptEn: 'This is ${target.name('en').toLowerCase()}. Tap it.',
    promptImagePath: promptImagePath,
    correctChoiceImagePath: correctChoiceImagePath,
    introduction: true,
  );
}
