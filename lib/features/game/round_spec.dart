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
