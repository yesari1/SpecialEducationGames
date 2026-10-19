import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/content/content_repository.dart';
import '../../../core/learning/policies.dart';
import '../round_spec.dart';
import '../widgets/round_choices_view.dart';

class ModeContext {
  final ContentRepository content;
  final String themeId, gameId;
  final String locale;
  final Difficulty difficulty;
  final int? _choiceCount;
  int get choiceCount => _choiceCount ?? difficulty.choices;
  final ItemScheduler scheduler;
  final Map<String, int> struggle;
  const ModeContext({
    required this.content,
    required this.themeId,
    required this.gameId,
    this.locale = 'tr',
    required this.difficulty,
    required this.scheduler,
    required this.struggle,
    int? choiceCount,
  }) : _choiceCount = choiceCount;
}

abstract class GameTemplate {
  const GameTemplate();
  String get id;
  RoundSpec buildRound(ModeContext ctx);
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) => RoundChoicesView(spec: spec, callbacks: callbacks, hint: hint);
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) {
    if (ctx.gameId == 'G33') return [];
    if (ctx.gameId == 'G35') {
      if (ctx.difficulty == Difficulty.hard) return [];
      return [
        for (final number in spec.sequence.where((x) => x != '?'))
          if (ctx.content.items
                  .where((x) => x.id == 'numbers.$number')
                  .firstOrNull
                  ?.audioFor(locale)
              case final String cue)
            cue,
        'assets/audio/$locale/prompts/next_number.mp3',
      ];
    }
    if (ctx.gameId == 'G36') {
      return ['assets/audio/$locale/prompts/compare.mp3'];
    }
    final cue = ctx.gameId == 'G10' && ctx.themeId != 'numbers'
        ? spec.target.sfx
        : spec.target.audioFor(locale);
    return [?cue];
  }

  List<String> successCues(RoundSpec spec, String locale) => [
    'assets/audio/$locale/prompts/praise.mp3',
    if (spec.target.audioFor(locale) case final String cue) cue,
  ];
}

class IdentifyTemplate extends GameTemplate {
  const IdentifyTemplate();
  @override
  String get id => 'identify';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    var pool = ctx.content.pool(ctx.themeId, ctx.difficulty);
    // Unavailable images must not become indistinguishable answer cards.
    if (ctx.themeId != 'numbers' &&
        ctx.themeId != 'colors' &&
        ctx.gameId != 'G02' &&
        ctx.gameId != 'G55') {
      pool = pool.where((x) => x.images.isNotEmpty).toList();
    }
    final g14Hard = ctx.gameId == 'G14' && ctx.difficulty == Difficulty.hard;
    final g14Targets = g14Hard
        ? ctx.content.g14HardTargetPool(ctx.themeId, ctx.difficulty)
        : pool;
    if (g14Hard && g14Targets.isEmpty) {
      throw StateError('G14 hard requires two verified photos of one item');
    }
    if (ctx.gameId == 'G10') {
      pool = pool
          .where(
            (x) => ctx.themeId == 'animals' || ctx.themeId == 'vehicles'
                ? x.sfx != null
                : x.audioFor(ctx.locale) != null,
          )
          .toList();
    }
    if (pool.length < 2) throw StateError('Not enough distinct visual choices');
    final targetPool = g14Hard ? g14Targets : pool;
    final target = ctx.scheduler.next(targetPool, ctx.struggle);
    final distractors = pool.where((x) => x.id != target.id).toList()
      ..shuffle(ctx.scheduler.random);
    final choices = [target, ...distractors.take(ctx.choiceCount - 1)]
      ..shuffle(ctx.scheduler.random);
    String? promptImagePath;
    String? correctChoiceImagePath;
    if (g14Hard) {
      final variants = target.verifiedPhotoPaths;
      final first = ctx.scheduler.random.nextInt(variants.length);
      final second =
          (first + 1 + ctx.scheduler.random.nextInt(variants.length - 1)) %
          variants.length;
      promptImagePath = variants[first];
      correctChoiceImagePath = variants[second];
    }
    return RoundSpec(
      target: target,
      choices: choices,
      promptImagePath: promptImagePath,
      correctChoiceImagePath: correctChoiceImagePath,
      promptTr: ctx.gameId == 'G14'
          ? 'Aynısını bul'
          : ctx.gameId == 'G10'
          ? (ctx.themeId == 'numbers'
                ? 'Dinle. Hangi sayı?'
                : 'Dinle. Ses kimden geliyor?')
          : '${target.name('tr')} hangisi?',
      promptEn: ctx.gameId == 'G14'
          ? 'Find the match'
          : ctx.gameId == 'G10'
          ? (ctx.themeId == 'numbers'
                ? 'Listen. Which number?'
                : 'Listen. What makes this sound?')
          : 'Find ${target.name('en').toLowerCase()}',
      promptKey: ctx.gameId == 'G14'
          ? GamePromptKey.findMatch
          : ctx.gameId == 'G10'
          ? (ctx.themeId == 'numbers'
                ? GamePromptKey.listenForNumber
                : GamePromptKey.listenForSoundSource)
          : null,
    );
  }
}

class CountTemplate extends GameTemplate {
  const CountTemplate();
  @override
  String get id => "count";
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final maximum = [3, 5, 10][ctx.difficulty.index];
    final numeric = ctx.content.items
        .where(
          (x) =>
              x.theme == 'numbers' &&
              int.parse(x.slug) >= 1 &&
              int.parse(x.slug) <= maximum,
        )
        .toList();
    final target = ctx.scheduler.next(numeric, ctx.struggle);
    final others = numeric.where((x) => x.id != target.id).toList()
      ..shuffle(ctx.scheduler.random);
    final choices = [target, ...others.take(ctx.choiceCount - 1)]
      ..shuffle(ctx.scheduler.random);
    final visual = ctx.content
        .pool(ctx.themeId, Difficulty.easy)
        .where((i) => i.images.isNotEmpty)
        .firstOrNull;
    return RoundSpec(
      target: target,
      choices: choices,
      promptTr: 'Kaç tane var?',
      promptEn: 'How many are there?',
      promptKey: GamePromptKey.counting,
      count: int.parse(target.slug),
      stimulus: visual,
    );
  }
}

class CompareTemplate extends GameTemplate {
  const CompareTemplate();
  @override
  String get id => "compare";
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final maximum = ctx.difficulty == Difficulty.easy
        ? 3
        : ctx.difficulty == Difficulty.medium
        ? 5
        : 20;
    final a = ctx.scheduler.random.nextInt(maximum) + 1,
        b = ctx.scheduler.random.nextInt(maximum) + 1;
    if (ctx.difficulty != Difficulty.hard) {
      final amounts = List.generate(maximum, (i) => i + 1)
        ..shuffle(ctx.scheduler.random);
      final selected = amounts.take(ctx.difficulty.choices).toSet();
      final numbers = ctx.content.items
          .where(
            (x) => x.theme == 'numbers' && selected.contains(int.parse(x.slug)),
          )
          .toList();
      final target = numbers.firstWhere(
        (x) => int.parse(x.slug) == selected.reduce(max),
      );
      return RoundSpec(
        target: target,
        choices: numbers..shuffle(ctx.scheduler.random),
        promptTr: 'Hangisi daha çok?',
        promptEn: 'Which has more?',
        promptKey: GamePromptKey.compareMagnitude,
        quantities: {for (final item in numbers) item.id: int.parse(item.slug)},
        quantityItem: ctx.content
            .pool(ctx.themeId, ctx.difficulty)
            .where((x) => x.images.isNotEmpty)
            .firstOrNull,
      );
    }
    ContentItem relation(String symbol, String tr, String en) =>
        ContentItem.fromJson({
          'id': 'numbers.$symbol',
          'theme': 'numbers',
          'tier': 'easy',
          'name': {'tr': tr, 'en': en},
          'images': [],
          'audio': {},
          'tags': [],
        });
    final options = [
      relation('>', 'Büyüktür', 'Greater than'),
      relation('=', 'Eşittir', 'Equal to'),
      relation('<', 'Küçüktür', 'Less than'),
    ];
    final target =
        options[a > b
            ? 0
            : a == b
            ? 1
            : 2];
    return RoundSpec(
      target: target,
      choices: options,
      promptTr: 'Bu sayıları karşılaştır',
      promptEn: 'Compare these numbers',
      promptKey: GamePromptKey.compareNumbers,
      sequence: ['$a', '?', '$b'],
    );
  }
}

class GroupTemplate extends GameTemplate {
  const GroupTemplate();
  @override
  String get id => "group_choice";
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final pool = ctx.content
        .pool(ctx.themeId, ctx.difficulty)
        .where((x) => x.images.isNotEmpty)
        .toList();
    final stimulus = ctx.scheduler.next(pool, ctx.struggle);
    const labels = {
      'evcil': ['Evcil hayvanlar', 'Pets'],
      'ciftlik': ['Çiftlik hayvanları', 'Farm animals'],
      'vahsi': ['Vahşi hayvanlar', 'Wild animals'],
      'deniz': ['Deniz', 'Sea'],
      'bocek': ['Böcekler', 'Insects'],
      'kus': ['Kuşlar', 'Birds'],
      'meyve': ['Meyveler', 'Fruits'],
      'sebze': ['Sebzeler', 'Vegetables'],
      'kara': ['Kara taşıtları', 'Road vehicles'],
      'hava': ['Hava taşıtları', 'Aircraft'],
      'rayli': ['Raylı taşıtlar', 'Rail vehicles'],
      'is_makinesi': ['İş makineleri', 'Construction vehicles'],
    };
    final groups = pool.expand((x) => x.tags).where(labels.containsKey).toSet();
    final validTargets = stimulus.tags.where(groups.contains).toList();
    if (validTargets.isEmpty) throw StateError('No category for stimulus');
    final targetTag =
        validTargets[ctx.scheduler.random.nextInt(validTargets.length)];
    ContentItem category(String tag) {
      final hero = pool.firstWhere((x) => x.tags.contains(tag));
      return ContentItem.fromJson({
        'id': 'group.$tag',
        'theme': ctx.themeId,
        'tier': 'easy',
        'name': {'tr': labels[tag]![0], 'en': labels[tag]![1]},
        'images': hero.images,
        'audio': {},
        'tags': [tag],
      });
    }

    final target = category(targetTag);
    final others =
        groups
            .where((tag) => !stimulus.tags.contains(tag))
            .map(category)
            .toList()
          ..shuffle(ctx.scheduler.random);
    if (others.isEmpty) throw StateError('No unambiguous category distractor');
    return RoundSpec(
      target: target,
      choices: [target, ...others.take(ctx.choiceCount - 1)]
        ..shuffle(ctx.scheduler.random),
      promptTr: 'Bu hangi grupta?',
      promptEn: 'Which group does this belong to?',
      promptKey: GamePromptKey.groupMembership,
      stimulus: stimulus,
    );
  }
}

class SequenceMissingTemplate extends GameTemplate {
  const SequenceMissingTemplate();
  @override
  String get id => "sequence_missing";
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final pool = ctx.content.items
        .where(
          (x) =>
              x.theme == 'numbers' &&
              int.parse(x.slug) >= 1 &&
              int.parse(x.slug) <=
                  (ctx.difficulty == Difficulty.easy
                      ? 5
                      : ctx.difficulty == Difficulty.hard
                      ? 20
                      : 10),
        )
        .toList();
    final target = ctx.scheduler.next(
      pool
          .where(
            (x) =>
                int.parse(x.slug) >= 3 &&
                (ctx.difficulty != Difficulty.hard || int.parse(x.slug) < 20),
          )
          .toList(),
      ctx.struggle,
    );
    final n = int.parse(target.slug);
    final choices = List<ContentItem>.from(pool)..shuffle(ctx.scheduler.random);
    choices.removeWhere((x) => x.id == target.id);
    final selected = [target, ...choices.take(ctx.choiceCount - 1)]
      ..shuffle(ctx.scheduler.random);
    return RoundSpec(
      target: target,
      choices: selected,
      promptTr: ctx.difficulty == Difficulty.hard
          ? 'Eksik sayı hangisi?'
          : 'Sıradaki sayı hangisi?',
      promptEn: ctx.difficulty == Difficulty.hard
          ? 'Which number is missing?'
          : 'Which number comes next?',
      promptKey: ctx.difficulty == Difficulty.hard
          ? GamePromptKey.sequenceMissing
          : GamePromptKey.sequenceNext,
      sequence: ctx.difficulty == Difficulty.hard
          ? ['${n - 1}', '?', '${n + 1}']
          : ['${n - 2}', '${n - 1}', '?'],
    );
  }
}

class FlashcardsTemplate extends GameTemplate {
  const FlashcardsTemplate();
  @override
  String get id => 'flashcards';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final target = ctx.scheduler.next(
      ctx.content.pool(ctx.themeId, ctx.difficulty),
      ctx.struggle,
    );
    return RoundSpec(
      target: target,
      choices: [target],
      promptTr: target.name('tr'),
      promptEn: target.name('en'),
    );
  }
}

class CauseEffectTemplate extends FlashcardsTemplate {
  const CauseEffectTemplate();
  @override
  String get id => 'cause_effect';
}

abstract final class TemplateRegistry {
  static GameTemplate resolve(String gameId) => switch (gameId) {
    'G33' => const CountTemplate(),
    'G36' => const CompareTemplate(),
    'G04' => const GroupTemplate(),
    'G35' => const SequenceMissingTemplate(),
    'G02' => const FlashcardsTemplate(),
    'G55' => const CauseEffectTemplate(),
    'G01' || 'G10' || 'G14' || 'G34' => const IdentifyTemplate(),
    _ => throw StateError('Unsupported game: $gameId'),
  };
}
