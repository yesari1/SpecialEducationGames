import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/content/content_repository.dart';
import '../../../core/learning/policies.dart';
import '../round_spec.dart';
import '../widgets/fill_basket_view.dart';
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
final _praiseRandom = Random();
int _lastPraise = 0;

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
    final pool = ctx.pool().where((x) => x.images.isNotEmpty).toList();
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
    _ => throw StateError('Unsupported game: $gameId'),
  };
}
