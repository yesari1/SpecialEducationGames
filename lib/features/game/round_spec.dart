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
}

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
