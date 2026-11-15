/// Social stories: a few pages, each one picture and one narrated sentence,
/// with some pages asking the child to pick one of two or three pictures.
/// Stories are data (assets/content/stories.json); adding one needs no code.
library;

import 'child_cast.dart';

/// A text in each app language with its narration clip.
class StoryLine {
  final Map<String, String> text, audio;
  const StoryLine(this.text, this.audio);

  factory StoryLine.fromJson(Map<String, dynamic> j) => StoryLine(
    Map<String, String>.from(j['text'] as Map),
    Map<String, String>.from((j['audio'] ?? const {}) as Map),
  );

  String textFor(String locale) =>
      ChildCast.of(text[locale] ?? text['tr'] ?? '');

  /// The clip in [locale] only: a Turkish clip must never play under an
  /// English sentence.
  String? audioFor(String locale) => audio[locale];
}

/// One picture the child can choose on a question page.
class StoryChoice {
  final String image;
  final bool correct;

  /// What a wrong choice leads to: the gentle result (picture and sentence)
  /// shown before the question is asked again. Null shows no result page.
  final StoryLine? result;
  final String? resultImage;
  final Map<String, String> label;
  const StoryChoice({
    required this.image,
    required this.correct,
    this.result,
    this.resultImage,
    this.label = const {},
  });

  factory StoryChoice.fromJson(Map<String, dynamic> j) => StoryChoice(
    image: j['image'] as String,
    correct: j['correct'] == true,
    result: j['result'] == null
        ? null
        : StoryLine.fromJson(j['result'] as Map<String, dynamic>),
    resultImage: j['resultImage'] as String?,
    label: Map<String, String>.from((j['label'] ?? const {}) as Map),
  );

  String labelFor(String locale) => label[locale] ?? label['tr'] ?? '';
}

class StoryPage {
  /// Shown on a narration page; on a question page it is optional.
  final String? image;
  final StoryLine line;

  /// Empty for a narration page.
  final List<StoryChoice> choices;

  /// Asked again after a wrong choice ("What else can he do?"). Falls back
  /// to [line].
  final StoryLine? retry;
  const StoryPage({
    required this.line,
    this.image,
    this.choices = const [],
    this.retry,
  });

  bool get isQuestion => choices.isNotEmpty;

  factory StoryPage.fromJson(Map<String, dynamic> j) => StoryPage(
    image: j['image'] as String?,
    line: StoryLine.fromJson(j['line'] as Map<String, dynamic>),
    choices: [
      for (final c in (j['choices'] ?? const []) as List)
        StoryChoice.fromJson(c as Map<String, dynamic>),
    ],
    retry: j['retry'] == null
        ? null
        : StoryLine.fromJson(j['retry'] as Map<String, dynamic>),
  );
}

class Story {
  final String id, cover;
  final Map<String, String> title;

  /// Free stories play without Premium.
  final bool free;
  final List<StoryPage> pages;

  /// Said on the end screen ("Well done! You helped Ali.").
  final StoryLine? praise;
  const Story({
    required this.id,
    required this.cover,
    required this.title,
    required this.pages,
    this.free = false,
    this.praise,
  });

  String titleFor(String locale) =>
      ChildCast.of(title[locale] ?? title['tr'] ?? id);

  factory Story.fromJson(Map<String, dynamic> j) {
    final story = Story(
      id: j['id'] as String,
      cover: j['cover'] as String,
      title: Map<String, String>.from(j['title'] as Map),
      free: j['free'] == true,
      pages: [
        for (final p in j['pages'] as List)
          StoryPage.fromJson(p as Map<String, dynamic>),
      ],
      praise: j['praise'] == null
          ? null
          : StoryLine.fromJson(j['praise'] as Map<String, dynamic>),
    );
    story.validate();
    return story;
  }

  /// Catches content mistakes when the catalog loads instead of on the
  /// child's screen.
  void validate() {
    if (pages.isEmpty) throw FormatException('story $id has no pages');
    for (final (i, page) in pages.indexed) {
      if (!page.isQuestion && page.image == null) {
        throw FormatException('story $id page ${i + 1} has no picture');
      }
      if (page.isQuestion) {
        if (page.choices.length < 2 || page.choices.length > 3) {
          throw FormatException('story $id page ${i + 1}: 2 or 3 choices');
        }
        if (page.choices.where((c) => c.correct).length != 1) {
          throw FormatException('story $id page ${i + 1}: one right choice');
        }
      }
    }
  }

  /// Every asset the story refers to (checked by the catalog test).
  Iterable<String> get assets sync* {
    yield cover;
    for (final page in pages) {
      if (page.image case final image?) yield image;
      yield* page.line.audio.values;
      if (page.retry case final retry?) yield* retry.audio.values;
      for (final choice in page.choices) {
        yield choice.image;
        if (choice.resultImage case final image?) yield image;
        if (choice.result case final result?) yield* result.audio.values;
      }
    }
    if (praise case final praise?) yield* praise.audio.values;
  }
}
