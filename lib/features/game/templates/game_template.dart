import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/content/content_repository.dart';
import '../../../core/learning/policies.dart';
import '../round_spec.dart';
import '../widgets/fill_basket_view.dart';
import '../widgets/body_map_view.dart';
import '../widgets/paint_view.dart';
import '../widgets/scene_game_view.dart';
import '../widgets/music_views.dart';
import '../../../l10n/scoped_localizations.dart';
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

  /// The profile's age band (after the parent's shift); null keeps the
  /// tier tables.
  final AgeBand? band;

  /// The child the profile chose for games about a child: 'boy' (Ali) or
  /// 'girl' (Ayşe).
  final String who;
  const ModeContext({
    required this.content,
    required this.themeId,
    required this.gameId,
    this.locale = 'tr',
    required this.difficulty,
    required this.scheduler,
    required this.struggle,
    int? choiceCount,
    this.band,
    this.who = 'boy',
  }) : _choiceCount = choiceCount;

  /// Highest number for this round: the band's range, else [legacy] by tier.
  int numberMax(List<int> legacy) =>
      band?.maxNumber(difficulty) ?? legacy[difficulty.index];

  /// Like [numberMax] for games that draw the objects to count.
  int countableMax(List<int> legacy) =>
      band?.countableMax(difficulty) ?? legacy[difficulty.index];

  /// Theme items for this round. 8+ also gets less familiar items, and the
  /// numbers theme keeps to the band's number range.
  List<ContentItem> pool() {
    final band = this.band;
    final items = content.pool(
      themeId,
      band?.contentTier(difficulty) ?? difficulty,
    );
    if (band == null || themeId != 'numbers') return items;
    final limit = band.maxNumber(difficulty);
    final inRange = items
        .where((x) => (int.tryParse(x.slug) ?? 0) <= limit)
        .toList();
    return inRange.length >= choiceCount ? inRange : items;
  }
}

/// One of ten recorded praise phrases ("Aferin!", "Süpersin!", ...),
/// never the same one twice in a row.
String praiseCue(String locale, {Random? random}) {
  final pick = random ?? _praiseRandom;
  var n = 1 + pick.nextInt(praiseCount);
  if (n == _lastPraise) n = n % praiseCount + 1;
  _lastPraise = n;
  return 'assets/audio/$locale/praise/praise_$n.mp3';
}

const praiseCount = 10;

/// One of five short spoken sentences for a finished game ("Harika,
/// başardın!"), never the same one twice in a row (Yunus, 3 November 2026).
String successSentenceCue(String locale, {Random? random}) {
  final pick = random ?? _praiseRandom;
  var n = 1 + pick.nextInt(successSentenceCount);
  if (n == _lastSuccess) n = n % successSentenceCount + 1;
  _lastSuccess = n;
  return 'assets/audio/$locale/success/success_$n.mp3';
}

const successSentenceCount = 5;
int? _lastSuccess;
final _praiseRandom = Random();
int _lastPraise = 0;

abstract class GameTemplate {
  const GameTemplate();
  String get id;

  /// A game of exactly this many rounds, whatever the family's length is.
  int? get fixedRounds => null;
  RoundSpec buildRound(ModeContext ctx);
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) => RoundChoicesView(spec: spec, callbacks: callbacks, hint: hint);

  /// The spoken instruction for this round, recorded with the selected voices
  /// (see tools/generate_selected_voice.py), or null when the round has none.
  String? promptCue(RoundSpec spec, String locale) {
    final stem = switch (spec.promptKey) {
      GamePromptKey.counting => 'count',
      GamePromptKey.compareMagnitude => 'compare_magnitude',
      GamePromptKey.compareNumbers => 'compare_numbers',
      GamePromptKey.groupMembership => 'group_membership',
      GamePromptKey.findMatch => 'find_match',
      GamePromptKey.listenForNumber => 'listen_number',
      GamePromptKey.listenForSoundSource => 'listen_sound',
      GamePromptKey.sequenceNext => 'sequence_next',
      GamePromptKey.sequenceMissing => 'sequence_missing',
      GamePromptKey.oddOneOut => 'odd_one_out',
      GamePromptKey.shadowMatch => 'shadow_match',
      GamePromptKey.sortIntoBasket => 'sort_basket',
      GamePromptKey.numberQuantity => 'number_quantity',
      GamePromptKey.whichSound => 'which_sound',
      GamePromptKey.fillCount
          when (spec.fillCount ?? 0) >= 1 && (spec.fillCount ?? 0) <= 7 =>
        'fill_count_${spec.fillCount}',
      _ => null,
    };
    return stem == null
        ? null
        : 'assets/audio/$locale/prompts/${stem}_selected.mp3';
  }

  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) {
    final prompt = promptCue(spec, locale);
    if (ctx.gameId == 'G33') return [?prompt];
    if (ctx.gameId == 'G35') {
      // Say the shown numbers in order, then the question:
      // "Beş, altı... Sıradaki sayı hangisi?"
      return [
        for (final number in spec.sequence.where((x) => x != '?'))
          if (ctx.content.items
                  .where((x) => x.id == 'numbers.$number')
                  .firstOrNull
                  ?.audioFor(locale)
              case final String cue)
            cue,
        ?prompt,
      ];
    }
    if (ctx.gameId == 'G36') return [?prompt];
    // Group rounds name the object to sort after the question.
    if (spec.promptKey == GamePromptKey.groupMembership) {
      return [?prompt, ?spec.stimulus?.audioFor(locale)];
    }
    // Find: ask the whole question, "Kuş hangisi?", not just the name.
    if (ctx.gameId == 'G01') {
      if (spec.target.whichAudioFor(locale) case final String which) {
        return [which];
      }
    }
    final cue = ctx.gameId == 'G10' && ctx.themeId != 'numbers'
        ? spec.target.sfx
        : spec.target.audioFor(locale);
    return [?prompt, ?cue];
  }

  List<String> successCues(RoundSpec spec, String locale) => [
    praiseCue(locale),
    if (spec.target.audioFor(locale) case final String cue) cue,
  ];
}

class IdentifyTemplate extends GameTemplate {
  const IdentifyTemplate();
  @override
  String get id => 'identify';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    var pool = ctx.pool();
    // Unavailable images must not become indistinguishable answer cards.
    // Numbers, colours and shapes are drawn, so they need no photo.
    if (ctx.themeId != 'numbers' &&
        ctx.themeId != 'colors' &&
        ctx.themeId != 'shapes' &&
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
    final maximum = ctx.countableMax([3, 5, 10]);
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
        .where((i) => i.images.isNotEmpty || i.theme == 'shapes')
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
    final maximum = ctx.difficulty == Difficulty.hard
        ? ctx.numberMax([3, 5, 20])
        : ctx.countableMax([3, 5, 20]);
    final a = ctx.scheduler.random.nextInt(maximum) + 1,
        b = ctx.scheduler.random.nextInt(maximum) + 1;
    if (ctx.difficulty != Difficulty.hard) {
      final amounts = List.generate(maximum, (i) => i + 1)
        ..shuffle(ctx.scheduler.random);
      final selected = amounts
          .take(
            ctx.band == null
                ? ctx.difficulty.choices
                : min(ctx.choiceCount, maximum),
          )
          .toSet();
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
        quantityItem: ctx.pool().where((x) => x.images.isNotEmpty).firstOrNull,
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

  /// Group names per theme; a tag only counts as a group in its own theme.
  static const labels = {
    'animals': {
      'evcil': ['Evcil hayvanlar', 'Pets'],
      'ciftlik': ['Çiftlik hayvanları', 'Farm animals'],
      'vahsi': ['Vahşi hayvanlar', 'Wild animals'],
      'deniz': ['Suda yaşayanlar', 'Water animals'],
      'bocek': ['Böcekler', 'Insects'],
      'kus': ['Kuşlar', 'Birds'],
    },
    'produce': {
      'meyve': ['Meyveler', 'Fruits'],
      'sebze': ['Sebzeler', 'Vegetables'],
    },
    'vehicles': {
      'kara': ['Kara taşıtları', 'Road vehicles'],
      'hava': ['Hava taşıtları', 'Aircraft'],
      'rayli': ['Raylı taşıtlar', 'Rail vehicles'],
      'is_makinesi': ['İş makineleri', 'Work machines'],
      'deniz': ['Deniz taşıtları', 'Water vehicles'],
    },
  };

  @override
  RoundSpec buildRound(ModeContext ctx) {
    final names = labels[ctx.themeId] ?? const {};
    final pool = ctx.pool().where((x) => x.images.isNotEmpty).toList();
    final groups = pool.expand((x) => x.tags).where(names.containsKey).toSet();
    // Only items that belong to a group and leave another group to choose.
    final candidates = pool
        .where(
          (x) =>
              x.tags.any(groups.contains) &&
              groups.any((tag) => !x.tags.contains(tag)),
        )
        .toList();
    if (candidates.isEmpty) throw StateError('No category for stimulus');
    final stimulus = ctx.scheduler.next(candidates, ctx.struggle);
    final validTargets = stimulus.tags.where(groups.contains).toList();
    final targetTag =
        validTargets[ctx.scheduler.random.nextInt(validTargets.length)];
    // Each group shows a few of its members, never the item being sorted.
    final members = <String, List<ContentItem>>{};
    // Members come from the whole theme so small tier pools never leave a
    // group without pictures.
    final everyone = ctx.content.items
        .where((x) => x.theme == ctx.themeId && x.images.isNotEmpty)
        .toList();
    ContentItem category(String tag) {
      final group =
          everyone
              .where((x) => x.tags.contains(tag) && x.id != stimulus.id)
              .toList()
            ..shuffle(ctx.scheduler.random);
      members['group.$tag'] = group.take(3).toList(growable: false);
      return ContentItem.fromJson({
        'id': 'group.$tag',
        'theme': ctx.themeId,
        'tier': 'easy',
        'name': {'tr': names[tag]![0], 'en': names[tag]![1]},
        'images': group.isEmpty ? stimulus.images : group.first.images,
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
    // At most three groups: more baskets do not fit side by side clearly.
    final choices = [target, ...others.take(min(ctx.choiceCount, 3) - 1)]
      ..shuffle(ctx.scheduler.random);
    return RoundSpec(
      target: target,
      choices: choices,
      promptTr: 'Bu hangi grupta?',
      promptEn: 'Which group does this belong to?',
      promptKey: GamePromptKey.groupMembership,
      stimulus: stimulus,
      groupMembers: {for (final c in choices) c.id: members[c.id]!},
    );
  }

  /// "Evet, inek bir çiftlik hayvanıdır." for the item and its group.
  static String? explanationCue(RoundSpec spec, String locale) {
    final item = spec.stimulus;
    if (item == null || !spec.target.id.startsWith('group.')) return null;
    final tag = spec.target.id.substring('group.'.length);
    return 'assets/audio/$locale/explain/${item.theme}_${item.slug}_$tag.mp3';
  }

  @override
  List<String> successCues(RoundSpec spec, String locale) => [
    explanationCue(spec, locale) ?? praiseCue(locale),
  ];
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
                  (ctx.band == null
                      ? [5, 10, 20][ctx.difficulty.index]
                      : max(5, ctx.numberMax(const [5, 10, 20]))),
        )
        .toList();
    final target = ctx.scheduler.next(
      pool
          .where(
            (x) =>
                int.parse(x.slug) >= 3 &&
                (ctx.difficulty != Difficulty.hard ||
                    int.parse(x.slug) < pool.length),
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
    final target = ctx.scheduler.next(ctx.pool(), ctx.struggle);
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

/// G17 "Farklı Olanı Bul": all but one choice share a group; tap the odd one.
/// Easy/medium take the odd one from another theme; hard keeps it in the same
/// theme but from a different tag group (e.g. a vegetable among fruits).
class OddOneOutTemplate extends GameTemplate {
  const OddOneOutTemplate();
  @override
  String get id => 'odd_one_out';
  static const _groupTags = {
    'evcil', 'ciftlik', 'vahsi', 'deniz', 'bocek', 'kus', //
    'meyve', 'sebze', 'kara', 'hava', 'rayli', 'is_makinesi',
  };
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final pool = ctx.pool().where((x) => x.images.isNotEmpty).toList();
    final random = ctx.scheduler.random;
    final size = ctx.choiceCount.clamp(3, 4);
    List<ContentItem> group;
    ContentItem odd;
    final tags =
        pool
            .expand((x) => x.tags)
            .where(_groupTags.contains)
            .toSet()
            .where(
              (tag) => pool.where((x) => x.tags.contains(tag)).length >= size,
            )
            .toList()
          ..shuffle(random);
    // Themes without group tags (e.g. food) use another theme's item even
    // when hard.
    if (ctx.difficulty == Difficulty.hard && tags.isNotEmpty) {
      final tag = tags.first;
      group = pool.where((x) => x.tags.contains(tag)).toList()..shuffle(random);
      final outsiders = pool
          .where(
            (x) => !x.tags.contains(tag) && x.tags.any(_groupTags.contains),
          )
          .toList();
      if (outsiders.isEmpty) throw StateError('No outsider for group');
      odd = ctx.scheduler.next(outsiders, ctx.struggle);
    } else {
      group = List.of(pool)..shuffle(random);
      final others = ctx.content.items
          .where(
            (x) =>
                x.theme != ctx.themeId &&
                x.images.isNotEmpty &&
                const {'animals', 'produce', 'vehicles'}.contains(x.theme),
          )
          .toList();
      if (others.isEmpty) throw StateError('No other theme for odd item');
      odd = ctx.scheduler.next(others, ctx.struggle);
    }
    if (group.length < size - 1) throw StateError('Not enough group items');
    final choices = [odd, ...group.take(size - 1)]..shuffle(random);
    return RoundSpec(
      target: odd,
      choices: choices,
      promptTr: 'Farklı olanı bul',
      promptEn: 'Find the one that is different',
      promptKey: GamePromptKey.oddOneOut,
    );
  }

  // Saying the odd item's name would give the answer away.
  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) => [
    ?promptCue(spec, locale),
  ];
}

/// G15 "Gölgesini Bul": the photo is shown; choices are silhouettes. Drag the
/// photo onto its shadow or tap the shadow.
class ShadowMatchTemplate extends GameTemplate {
  const ShadowMatchTemplate();
  @override
  String get id => 'drag_to_target';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    // Shapes are drawn in code and have a silhouette of their own.
    final pool = ctx
        .pool()
        .where((x) => x.images.isNotEmpty || x.theme == 'shapes')
        .toList();
    if (pool.length < 2) throw StateError('Not enough silhouettes');
    final target = ctx.scheduler.next(pool, ctx.struggle);
    final distractors = pool.where((x) => x.id != target.id).toList()
      ..shuffle(ctx.scheduler.random);
    return RoundSpec(
      target: target,
      choices: [target, ...distractors.take(ctx.choiceCount - 1)]
        ..shuffle(ctx.scheduler.random),
      promptTr: 'Gölgesini bul',
      promptEn: 'Find its shadow',
      promptKey: GamePromptKey.shadowMatch,
      stimulus: target,
      look: ChoiceLook.silhouette,
      dragStimulus: true,
    );
  }
}

/// G23 "Sepete Koy": the G04 grouping drawn as baskets; the object can be
/// dragged into a basket or the basket tapped.
class BasketSortTemplate extends GroupTemplate {
  const BasketSortTemplate();
  @override
  String get id => 'sort';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final grouped = super.buildRound(ctx);
    return RoundSpec(
      target: grouped.target,
      choices: grouped.choices,
      promptTr: 'Doğru sepete koy',
      promptEn: 'Put it in the right basket',
      promptKey: GamePromptKey.sortIntoBasket,
      stimulus: grouped.stimulus,
      look: ChoiceLook.basket,
      dragStimulus: true,
      groupMembers: grouped.groupMembers,
    );
  }

  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) => [
    ?promptCue(spec, locale),
    ?spec.stimulus?.audioFor(locale),
  ];

  // Success inherits the group explanation sentence.
}

/// G37 "Sayı ve Miktar": a numeral is shown; pick the card with that many.
class NumberQuantityTemplate extends GameTemplate {
  const NumberQuantityTemplate();
  @override
  String get id => 'match_pair';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final maximum = ctx.countableMax([3, 5, 10]);
    final numbers = ctx.content.items
        .where(
          (x) =>
              x.theme == 'numbers' &&
              (int.tryParse(x.slug) ?? 0) >= 1 &&
              int.parse(x.slug) <= maximum,
        )
        .toList();
    if (numbers.length < 2) throw StateError('Not enough numbers');
    final target = ctx.scheduler.next(numbers, ctx.struggle);
    final others = numbers.where((x) => x.id != target.id).toList()
      ..shuffle(ctx.scheduler.random);
    final choices = [target, ...others.take(ctx.choiceCount - 1)]
      ..shuffle(ctx.scheduler.random);
    final counted = ctx.content
        .pool('produce', Difficulty.easy)
        .where((x) => x.images.isNotEmpty)
        .toList();
    return RoundSpec(
      target: target,
      choices: choices,
      promptTr: 'Bu kadar olanı bul',
      promptEn: 'Find this many',
      promptKey: GamePromptKey.numberQuantity,
      stimulus: target,
      quantities: {for (final item in choices) item.id: int.parse(item.slug)},
      quantityItem: counted.isEmpty
          ? null
          : counted[ctx.scheduler.random.nextInt(counted.length)],
    );
  }
}

/// G38 "Sepeti Doldur": put the asked number of objects into the basket.
class FillCountTemplate extends GameTemplate {
  const FillCountTemplate();
  @override
  String get id => 'fill_count';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    // The spoken instruction exists for 1–7.
    final maximum = min(7, ctx.countableMax([3, 5, 7]));
    final numbers = ctx.content.items
        .where(
          (x) =>
              x.theme == 'numbers' &&
              (int.tryParse(x.slug) ?? 0) >= 1 &&
              int.parse(x.slug) <= maximum,
        )
        .toList();
    final target = ctx.scheduler.next(numbers, ctx.struggle);
    final objects = ctx.content
        .pool(
          ctx.themeId == 'numbers' ? 'produce' : ctx.themeId,
          Difficulty.easy,
        )
        .where((x) => x.images.isNotEmpty)
        .toList();
    if (objects.isEmpty) throw StateError('No objects to count');
    return RoundSpec(
      target: target,
      choices: [target],
      promptTr: 'Sepete ${target.slug} tane koy',
      promptEn: 'Put ${target.slug} in the basket',
      promptKey: GamePromptKey.fillCount,
      stimulus: objects[ctx.scheduler.random.nextInt(objects.length)],
      fillCount: int.parse(target.slug),
    );
  }

  // "Put three in the basket." already says the number.
  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) => [
    ?promptCue(spec, locale),
  ];

  @override
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) => FillBasketView(spec: spec, callbacks: callbacks, hint: hint);
}

/// G11 "Doğru Sesi Seç": the picture is shown; each answer is a sound the
/// child can listen to with its button, then choose by tapping the card.
class SoundChoiceTemplate extends GameTemplate {
  const SoundChoiceTemplate();
  @override
  String get id => 'audio_choice';
  @override
  RoundSpec buildRound(ModeContext ctx) {
    final pool = ctx
        .pool()
        .where((x) => x.sfx != null && x.images.isNotEmpty)
        .toList();
    if (pool.length < 2) throw StateError('Not enough sounds');
    final target = ctx.scheduler.next(pool, ctx.struggle);
    final distractors = pool.where((x) => x.id != target.id).toList()
      ..shuffle(ctx.scheduler.random);
    final size = ctx.difficulty == Difficulty.easy ? 2 : 3;
    return RoundSpec(
      target: target,
      choices: [target, ...distractors.take(size - 1)]
        ..shuffle(ctx.scheduler.random),
      promptTr: 'Hangi ses onun?',
      promptEn: 'Which sound does it make?',
      promptKey: GamePromptKey.whichSound,
      stimulus: target,
      look: ChoiceLook.sound,
    );
  }

  // Saying the name is fine: the child compares the sounds.
  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) => [
    ?spec.target.audioFor(locale),
    ?promptCue(spec, locale),
  ];

  @override
  List<String> successCues(RoundSpec spec, String locale) => [
    praiseCue(locale),
    ?spec.target.sfx,
  ];
}

/// Data-driven pairing games (assets/content/pair_games.json): something
/// is shown or heard (a banana, a circle, a scene, a laugh) and the child
/// picks the matching card of the theme (yellow, the clock, "happy").
/// The question is spoken from the round's own clip.
class PairTemplate extends GameTemplate {
  const PairTemplate();
  @override
  String get id => 'pair';

  static String? _last;

  @override
  RoundSpec buildRound(ModeContext ctx) {
    final game = ctx.content.pairGames[ctx.gameId];
    if (game == null) throw StateError('No pair game ${ctx.gameId}');
    final pool = game.choicePool.isEmpty
        ? ctx.pool()
        : [for (final id in game.choicePool) ?ctx.content.anyItem(id)];
    final poolIds = {for (final x in pool) x.id};
    // Rounds whose answer is available at this level.
    final rounds = game.rounds
        .where(
          (r) =>
              poolIds.contains(r.target) &&
              (r.who == null || r.who == ctx.who) &&
              (r.stimulus == null || ctx.content.anyItem(r.stimulus!) != null),
        )
        .toList();
    if (rounds.isEmpty) throw StateError('No pair rounds for ${ctx.gameId}');
    final random = ctx.scheduler.random;
    // Medium and hard never ask the same thing twice in one game.
    String key(PairRound r) => r.stimulus ?? r.sound ?? r.textFor('tr');
    var options = ctx.scheduler.fresh(rounds, key);
    final notLast = options.where((r) => r.textFor('tr') != _last).toList();
    if (notLast.isNotEmpty && !ctx.scheduler.noRepeat) options = notLast;
    final round = options[random.nextInt(options.length)];
    _last = round.textFor('tr');
    ctx.scheduler.used.add(key(round));
    final target = pool.firstWhere((x) => x.id == round.target);
    final right = game.rightFor(round);
    final wrong =
        pool
            .where((x) => !right.contains(x.id) && !round.avoid.contains(x.id))
            .toList()
          ..shuffle(random);
    final dropOn = game.look == 'basket' || game.look == 'drop';
    final size = dropOn ? min(ctx.choiceCount, 3) : ctx.choiceCount;
    if (wrong.length < size - 1) throw StateError('Not enough choices');
    final choices = [target, ...wrong.take(size - 1)]..shuffle(random);
    final shown = round.stimulus == null
        ? null
        : ctx.content.anyItem(round.stimulus!);
    // A scene is drawn big above the choices instead of next to the question.
    final scene = game.look == 'scene';
    final stimulus = scene ? null : shown;
    String cue(String lang) => round.audio[lang] ?? '';
    return RoundSpec(
      target: target,
      choices: choices,
      promptTr: round.textFor('tr'),
      promptEn: round.textFor('en'),
      stimulus: stimulus,
      promptImagePath: scene ? shown?.images.firstOrNull : null,
      oneRow: true,
      look: dropOn ? ChoiceLook.basket : ChoiceLook.object,
      plainTargets: game.look == 'drop',
      dragStimulus: dropOn && stimulus != null,
      groupMembers: dropOn
          ? {
              for (final c in choices) c.id: [c],
            }
          : const {},
      promptCues: {
        for (final lang in const ['tr', 'en'])
          // A sound is heard, the question asked, the sound heard again.
          lang: [
            ?round.sound,
            if (cue(lang).isNotEmpty) cue(lang),
            ?round.sound,
          ],
      },
      successCueOverride: round.resultAudio.isNotEmpty
          ? {
              for (final e in round.resultAudio.entries)
                e.key: [e.value, praiseCue(e.key)],
            }
          : {
              for (final e in game.successAudio.entries) e.key: [e.value],
            },
      resultImagePath: round.result,
      rightHold: round.result == null
          ? const Duration(milliseconds: 1500)
          : const Duration(milliseconds: 2800),
    );
  }

  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) =>
      spec.promptCues[locale == 'en' ? 'en' : 'tr'] ?? const [];

  @override
  List<String> successCues(RoundSpec spec, String locale) =>
      spec.successCueOverride[locale == 'en' ? 'en' : 'tr'] ??
      super.successCues(spec, locale);

  @override
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) {
    final view = spec.promptImagePath == null
        ? super.buildView(context, spec, callbacks, hint)
        : PaintView(spec: spec, callbacks: callbacks, hint: hint, paint: false);
    // The right answer's result picture comes up over the whole game (see
    // [ResultScene] in the game screen).
    return view;
  }
}

/// G42 "Boya": a white picture and paint choices; "Kırmızıya boya!" The
/// right colour paints the picture.
class PaintTemplate extends GameTemplate {
  const PaintTemplate();
  @override
  String get id => 'paint';

  /// Colours that read well on every picture (no white, black or grey).
  static const paints = [
    'red', 'blue', 'yellow', 'green', 'orange', 'purple', 'pink', 'brown', //
  ];

  @override
  RoundSpec buildRound(ModeContext ctx) {
    final random = ctx.scheduler.random;
    final pictures = ctx.content.extraItems
        .where((x) => x.id.startsWith('paint.') && x.images.isNotEmpty)
        .toList();
    final colours = [
      for (final slug in paints) ?ctx.content.anyItem('colors.$slug'),
    ];
    if (pictures.isEmpty || colours.length < 2) {
      throw StateError('No paint pictures');
    }
    final target = ctx.scheduler.next(colours, ctx.struggle);
    final others = colours.where((x) => x.id != target.id).toList()
      ..shuffle(random);
    final choices = [target, ...others.take(min(ctx.choiceCount, 4) - 1)]
      ..shuffle(random);
    final unused = ctx.scheduler.fresh(pictures, (x) => x.id);
    final picture = unused[random.nextInt(unused.length)];
    ctx.scheduler.used.add(picture.id);
    final tr = target.name('tr');
    return RoundSpec(
      target: target,
      choices: choices,
      promptTr:
          'Hadi, ${(paintSuffix[target.slug] ?? '$tr ile').toLowerCase()} '
          'boyayalım',
      promptEn: "Let's paint it ${target.name('en').toLowerCase()}",
      promptImagePath: picture.images.first,
      oneRow: true,
      // Time for the brush to finish and the painted picture to be seen.
      rightHold: const Duration(milliseconds: 3000),
      promptCues: {
        for (final lang in const ['tr', 'en'])
          lang: ['assets/audio/$lang/pairs/G42_${target.slug}.mp3'],
      },
    );
  }

  /// "Kırmızıya", "Maviye"...: the dative Turkish uses for "paint it red".
  static const paintSuffix = {
    'red': 'Kırmızıya',
    'blue': 'Maviye',
    'yellow': 'Sarıya',
    'green': 'Yeşile',
    'orange': 'Turuncuya',
    'purple': 'Mora',
    'pink': 'Pembeye',
    'brown': 'Kahverengiye',
  };

  @override
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) => PaintView(spec: spec, callbacks: callbacks, hint: hint);

  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) =>
      spec.promptCues[locale == 'en' ? 'en' : 'tr'] ?? const [];
}

/// G47 "Ali'de Göster": "Ali'nin burnu nerede?" The child taps the place on
/// a picture of the whole of Ali.
class BodyMapTemplate extends GameTemplate {
  const BodyMapTemplate();
  @override
  String get id => 'body_map';

  static BodyMap _map(ModeContext ctx) {
    if (ctx.content.bodyMap.isEmpty) throw StateError('No body map');
    return BodyMap.fromJson(ctx.content.bodyMap);
  }

  @override
  RoundSpec buildRound(ModeContext ctx) {
    final map = _map(ctx);
    _cached = map;
    // Easy and medium ask the well-known places; hard asks them all.
    final allowed = {for (final x in ctx.pool()) x.id};
    final items = map
        .items(ctx.content)
        .where((x) => allowed.contains(x.id))
        .toList();
    if (items.length < 2) throw StateError('Not enough body places');
    final target = ctx.scheduler.next(items, ctx.struggle);
    final q = map.questions[target.id] ?? const {};
    final picture = map.pictureFor(target.id)!;
    final here = {for (final s in picture.spots) s.item};
    // Wrong answers come from the same picture.
    final others =
        items.where((x) => x.id != target.id && here.contains(x.id)).toList()
          ..shuffle(ctx.scheduler.random);
    return RoundSpec(
      target: target,
      // Every place on the picture can be tapped (see BodyMapView); the
      // choices only carry the wrong-tap answer.
      choices: [target, ...others.take(ctx.choiceCount - 1)],
      promptTr: q['tr'] ?? '${target.name('tr')} nerede?',
      promptEn: q['en'] ?? 'Where is the ${target.name('en').toLowerCase()}?',
      promptImagePath: picture.asset,
      promptBeside: true,
      promptCues: {
        for (final lang in const ['tr', 'en'])
          lang: ['assets/audio/$lang/pairs/G47_${target.slug}.mp3'],
      },
    );
  }

  @override
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) {
    final picture = _cached?.pictures
        .where((p) => p.asset == spec.promptImagePath)
        .firstOrNull;
    return BodyMapView(
      spec: spec,
      callbacks: callbacks,
      hint: hint,
      spots: picture?.spots ?? const [],
      aspect: picture?.aspect ?? 2 / 3,
    );
  }

  /// The map of the last built round, for the view (rounds are always
  /// built before they are drawn).
  static BodyMap? _cached;

  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) =>
      spec.promptCues[locale == 'en' ? 'en' : 'tr'] ?? const [];
}

/// Games played on a picture (assets/content/scene_games.json): the child
/// brings the right thing to the scene and the scene changes.
class SceneTemplate extends GameTemplate {
  const SceneTemplate();
  @override
  String get id => 'scene';

  @override
  RoundSpec buildRound(ModeContext ctx) {
    final game = ctx.content.sceneGames[ctx.gameId];
    if (game == null) throw StateError('No scene game ${ctx.gameId}');
    final rounds = game.rounds
        .where(
          (r) =>
              r.tier == ctx.difficulty.name &&
              (r.who == null || r.who == ctx.who) &&
              ctx.content.anyItem(r.target) != null,
        )
        .toList();
    if (rounds.isEmpty) throw StateError('No scene rounds for ${ctx.gameId}');
    final options = ctx.scheduler.fresh(rounds, (r) => r.key);
    final round = options[ctx.scheduler.random.nextInt(options.length)];
    ctx.scheduler.used.add(round.key);
    final target = ctx.content.anyItem(round.target)!;
    // One wrong card carries the wrong answers into the family's reports.
    final wrong = [
      for (final step in round.steps)
        for (final id in step.others) ?ctx.content.anyItem(id),
    ];
    return RoundSpec(
      target: target,
      choices: [target, ...wrong.take(1)],
      promptTr: round.text['tr'] ?? '',
      promptEn: round.text['en'] ?? '',
      scene: round,
      scenePieces: {
        for (final step in round.steps)
          for (final id in [step.piece, ...step.others])
            id: ?ctx.content.anyItem(id),
        for (final id in round.extras) id: ?ctx.content.anyItem(id),
      },
      fullStage: true,
      rightHold: const Duration(milliseconds: 2500),
      promptCues: {
        for (final lang in const ['tr', 'en']) lang: [?round.audio[lang]],
      },
      successCueOverride: {
        for (final lang in const ['tr', 'en'])
          lang: [
            ?round.steps.last.doneAudio[lang],
            ?round.finishAudio[lang],
            praiseCue(lang),
          ],
      },
    );
  }

  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) =>
      spec.promptCues[locale == 'en' ? 'en' : 'tr'] ?? const [];

  @override
  List<String> successCues(RoundSpec spec, String locale) =>
      spec.successCueOverride[locale == 'en' ? 'en' : 'tr'] ?? const [];

  @override
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) => SceneGameView(spec: spec, callbacks: callbacks, hint: hint);
}

/// G75 "Sen de Çal": the instrument plays, the child plays it back.
class EchoTemplate extends GameTemplate {
  const EchoTemplate();
  @override
  String get id => 'echo';

  static Map<String, String> _clips(String key) => {
    for (final lang in const ['tr', 'en'])
      lang: 'assets/audio/$lang/scenes/$key.mp3',
  };

  @override
  RoundSpec buildRound(ModeContext ctx) {
    final pool = ctx.pool().where((x) => x.sfx != null).toList();
    if (pool.length < 2) throw StateError('No instruments');
    final target = ctx.scheduler.next(pool, ctx.struggle);
    final wrong = pool.firstWhere((x) => x.id != target.id);
    return RoundSpec(
      target: target,
      choices: [target, wrong],
      promptTr: 'Dinle, sonra sen de çal.',
      promptEn: 'Listen, then you play too.',
      fillCount: ctx.difficulty.index + 2,
      fullStage: true,
      promptCues: {
        for (final e in _clips('g75_listen').entries) e.key: [e.value],
      },
    );
  }

  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) =>
      spec.promptCues[locale == 'en' ? 'en' : 'tr'] ?? const [];

  @override
  List<String> successCues(RoundSpec spec, String locale) => [
    praiseCue(locale),
  ];

  @override
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) => EchoView(
    spec: spec,
    callbacks: callbacks,
    hint: hint,
    againAudio: _clips('g75_again'),
  );
}

/// G76 "Çal Bakalım": free play on every instrument.
class FreePlayTemplate extends GameTemplate {
  const FreePlayTemplate();
  @override
  String get id => 'free_play';

  @override
  int? get fixedRounds => 1;

  @override
  RoundSpec buildRound(ModeContext ctx) {
    final pool = ctx.content
        .pool(ctx.themeId, Difficulty.hard)
        .where((x) => x.sfx != null)
        .toList();
    if (pool.isEmpty) throw StateError('No instruments');
    return RoundSpec(
      target: pool.first,
      choices: pool,
      promptTr: 'Hangisini istersen çal.',
      promptEn: 'Play whichever you like.',
      fullStage: true,
      promptCues: {
        for (final lang in const ['tr', 'en'])
          lang: ['assets/audio/$lang/scenes/g76_play.mp3'],
      },
    );
  }

  @override
  List<String> introCues(RoundSpec spec, ModeContext ctx, String locale) =>
      spec.promptCues[locale == 'en' ? 'en' : 'tr'] ?? const [];

  @override
  List<String> successCues(RoundSpec spec, String locale) => [
    praiseCue(locale),
  ];

  @override
  Widget buildView(
    BuildContext context,
    RoundSpec spec,
    RoundCallbacks callbacks,
    HintViewState hint,
  ) => FreePlayView(
    spec: spec,
    callbacks: callbacks,
    hint: hint,
    doneLabel: scopedLocalizations(context, hint.locale).gameFinish,
  );
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
    'G15' => const ShadowMatchTemplate(),
    'G17' => const OddOneOutTemplate(),
    'G23' => const BasketSortTemplate(),
    'G37' => const NumberQuantityTemplate(),
    'G38' => const FillCountTemplate(),
    'G11' => const SoundChoiceTemplate(),
    'G42' => const PaintTemplate(),
    'G47' => const BodyMapTemplate(),
    'G40' ||
    'G41' ||
    'G43' ||
    'G44' ||
    'G45' ||
    'G46' ||
    'G48' ||
    'G49' => const PairTemplate(),
    'G75' => const EchoTemplate(),
    'G76' => const FreePlayTemplate(),
    'G62' ||
    'G64' ||
    'G67' ||
    'G68' ||
    'G69' ||
    'G70' ||
    'G73' ||
    'G74' => const PairTemplate(),
    'G60' ||
    'G61' ||
    'G63' ||
    'G65' ||
    'G66' ||
    'G71' ||
    'G72' => const SceneTemplate(),
    _ => throw StateError('Unsupported game: $gameId'),
  };
}
