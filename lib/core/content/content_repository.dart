import 'dart:convert';
import 'package:flutter/services.dart';
import 'pair_games.dart';
import 'story.dart';
export 'pair_games.dart';
export 'story.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyLabel on Difficulty {
  String label(String locale) => locale == 'tr'
      ? ['Kolay', 'Orta', 'Zor'][index]
      : ['Easy', 'Medium', 'Hard'][index];
  int get choices => index + 2;
  int get stages => index + 4;
}

class ContentItem {
  // Explicit inventory of EN mappings verified byte-identical to legacy TR
  // recordings while their labels differ; never hash assets at runtime.
  static const Set<String> _legacyTurkishEnglishAssetPaths = {
    'assets/audio/en/animals/bird.mp3',
    'assets/audio/en/animals/fish.mp3',
    'assets/audio/en/animals/cow.mp3',
    'assets/audio/en/animals/horse.mp3',
    'assets/audio/en/animals/sheep.mp3',
    'assets/audio/en/animals/chicken.mp3',
    'assets/audio/en/animals/duck.mp3',
    'assets/audio/en/animals/chick.mp3',
    'assets/audio/en/animals/lion.mp3',
    'assets/audio/en/animals/elephant.mp3',
    'assets/audio/en/animals/monkey.mp3',
    'assets/audio/en/animals/bear.mp3',
    'assets/audio/en/animals/butterfly.mp3',
    'assets/audio/en/animals/goat.mp3',
    'assets/audio/en/animals/donkey.mp3',
    'assets/audio/en/animals/rooster.mp3',
    'assets/audio/en/animals/turkey.mp3',
    'assets/audio/en/animals/bee.mp3',
    'assets/audio/en/animals/turtle.mp3',
    'assets/audio/en/animals/mouse.mp3',
    'assets/audio/en/animals/frog.mp3',
    'assets/audio/en/animals/giraffe.mp3',
    'assets/audio/en/animals/tiger.mp3',
    'assets/audio/en/animals/wolf.mp3',
    'assets/audio/en/animals/owl.mp3',
    'assets/audio/en/animals/deer.mp3',
    'assets/audio/en/animals/bull.mp3',
    'assets/audio/en/colors/blue.mp3',
    'assets/audio/en/colors/yellow.mp3',
    'assets/audio/en/colors/green.mp3',
    'assets/audio/en/colors/orange.mp3',
    'assets/audio/en/colors/purple.mp3',
    'assets/audio/en/colors/pink.mp3',
    'assets/audio/en/colors/brown.mp3',
    'assets/audio/en/colors/black.mp3',
    'assets/audio/en/colors/white.mp3',
    'assets/audio/en/colors/gray.mp3',
    'assets/audio/en/numbers/1.mp3',
    'assets/audio/en/numbers/2.mp3',
    'assets/audio/en/numbers/4.mp3',
    'assets/audio/en/numbers/5.mp3',
    'assets/audio/en/numbers/6.mp3',
    'assets/audio/en/numbers/7.mp3',
    'assets/audio/en/numbers/8.mp3',
    'assets/audio/en/numbers/9.mp3',
    'assets/audio/en/produce/orange.mp3',
    'assets/audio/en/produce/strawberry.mp3',
    'assets/audio/en/produce/grape.mp3',
    'assets/audio/en/produce/watermelon.mp3',
    'assets/audio/en/produce/pear.mp3',
    'assets/audio/en/produce/cherry.mp3',
    'assets/audio/en/produce/mandarin.mp3',
    'assets/audio/en/produce/tomato.mp3',
    'assets/audio/en/produce/carrot.mp3',
    'assets/audio/en/produce/potato.mp3',
    'assets/audio/en/produce/cucumber.mp3',
    'assets/audio/en/produce/peach.mp3',
    'assets/audio/en/produce/plum.mp3',
    'assets/audio/en/produce/pomegranate.mp3',
    'assets/audio/en/produce/pepper.mp3',
    'assets/audio/en/produce/eggplant.mp3',
    'assets/audio/en/produce/onion.mp3',
    'assets/audio/en/produce/cabbage.mp3',
    'assets/audio/en/produce/lettuce.mp3',
    'assets/audio/en/produce/zucchini.mp3',
    'assets/audio/en/produce/pea.mp3',
    'assets/audio/en/produce/quince.mp3',
    'assets/audio/en/produce/blackberry.mp3',
    'assets/audio/en/produce/chestnut.mp3',
    'assets/audio/en/produce/cauliflower.mp3',
    'assets/audio/en/produce/spinach.mp3',
    'assets/audio/en/produce/radish.mp3',
    'assets/audio/en/produce/mint.mp3',
  };
  final String id, theme, tier;
  final Map<String, dynamic> names, audio;

  /// "Kuş hangisi?" / "Which one is the bird?" for the Find game.
  final Map<String, dynamic> whichAudio;
  final List<String> images, tags;
  final Map<String, dynamic> imageProvenance;
  final String? sfx;
  ContentItem.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      theme = j['theme'],
      tier = j['tier'],
      names = Map<String, dynamic>.from(j['name']),
      audio = Map<String, dynamic>.from(j['audio'] ?? {}),
      whichAudio = Map<String, dynamic>.from(j['whichAudio'] ?? {}),
      images = List<String>.from(j['images'] ?? []),
      imageProvenance = Map<String, dynamic>.from(j['imageProvenance'] ?? {}),
      tags = List<String>.from(j['tags'] ?? []),
      sfx = j['sfx'];
  String name(String locale) => names[locale] ?? names['tr'];
  String? audioFor(String locale) {
    final selected = locale == 'en' ? 'en' : 'tr';
    final own = audio[selected];
    if (own is String && own.isNotEmpty) {
      if (selected == 'en' &&
          _legacyTurkishEnglishAssetPaths.contains(own) &&
          names['tr'] != names['en']) {
        return null;
      }
      return own;
    }
    final other = audio[selected == 'en' ? 'tr' : 'en'];
    return other is String && other.isNotEmpty && names['tr'] == names['en']
        ? other
        : null;
  }

  String? whichAudioFor(String locale) {
    final path = whichAudio[locale == 'en' ? 'en' : 'tr'];
    return path is String && path.isNotEmpty ? path : null;
  }

  String get slug => id.split('.').last;

  List<String> get verifiedPhotoPaths {
    final seenHashes = <String>{};
    return images
        .where((path) {
          final value = imageProvenance[path];
          if (value is! Map) return false;
          final provenance = Map<String, dynamic>.from(value);
          final hash = provenance['sha256'];
          if (provenance['licenseVerified'] != true ||
              provenance['path'] != path ||
              ![
                provenance['author'],
                provenance['source'],
                provenance['license'],
                provenance['licenseUrl'],
              ].every((field) => field is String && field.isNotEmpty) ||
              hash is! String ||
              !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) {
            return false;
          }
          return seenHashes.add(hash.toLowerCase());
        })
        .toList(growable: false);
  }
}

class ContentTheme {
  final String id, hero;
  final Map<String, dynamic> names;
  final List<String> games;
  final Color bg, accent, deep;
  ContentTheme.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      hero = j['hero'],
      names = j['name'],
      games = List<String>.from(j['games']),
      bg = _color(j['palette']['bg']),
      accent = _color(j['palette']['accent']),
      deep = _color(j['palette']['deep']);
  String name(String locale) => names[locale] ?? names['tr'];
  static Color _color(String hex) =>
      Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
}

class GameDef {
  final String id, template;
  final Map<String, dynamic> names;
  GameDef.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      template = j['template'],
      names = j['name'];
  String name(String locale) => names[locale] ?? names['tr'];
}

class ContentRepository {
  final List<ContentTheme> themes;
  final List<ContentItem> items;
  final List<GameDef> games;
  final Set<String> freeGames;
  final Map<String, dynamic> configDefaults;

  /// Social stories (assets/content/stories.json), in shelf order.
  final List<Story> stories;

  /// Pictures and sounds used only inside games (scenes, Elif's faces,
  /// gloves...), never offered as a theme's own cards.
  final List<ContentItem> extraItems;

  /// Data-driven pairing games (assets/content/pair_games.json) by game id.
  final Map<String, PairGame> pairGames;

  /// "Ali'de Göster": the whole-body picture and its tappable places
  /// (assets/content/body_map.json), kept as raw data for the game.
  final Map<String, dynamic> bodyMap;
  ContentRepository(
    this.themes,
    this.items,
    this.games,
    this.freeGames, [
    this.configDefaults = const {},
    this.stories = const [],
    this.extraItems = const [],
    this.pairGames = const {},
    this.bodyMap = const {},
  ]);
  static Future<ContentRepository> load() async {
    Future<dynamic> read(String p) async =>
        jsonDecode(await rootBundle.loadString('assets/$p'));
    final themeJson = await read('content/themes.json') as List;
    final themes = themeJson
        .where((j) => j['active'] == true)
        .map((j) => ContentTheme.fromJson(j))
        .toList();
    final items = <ContentItem>[];
    for (final theme in themes) {
      items.addAll(
        (await read('content/items/${theme.id}.json') as List).map(
          (j) => ContentItem.fromJson(j),
        ),
      );
    }
    final games = (await read('content/games.json') as List)
        .map((j) => GameDef.fromJson(j))
        .toList();
    final config = await read('config_defaults.json');
    final stories = [
      for (final j in await read('content/stories.json') as List)
        Story.fromJson(j as Map<String, dynamic>),
    ];
    final extraItems = [
      for (final j in await read('content/extra_items.json') as List)
        ContentItem.fromJson(j as Map<String, dynamic>),
    ];
    final pairGames = {
      for (final e
          in (await read('content/pair_games.json') as Map<String, dynamic>)
              .entries)
        e.key: PairGame.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    return ContentRepository(
      themes,
      items,
      games,
      Set<String>.from(config['freeGames']),
      Map<String, dynamic>.from(config),
      stories,
      extraItems,
      pairGames,
      Map<String, dynamic>.from(await read('content/body_map.json') as Map),
    );
  }

  /// A theme card or an extra picture by id.
  ContentItem? anyItem(String id) =>
      items.where((x) => x.id == id).firstOrNull ??
      extraItems.where((x) => x.id == id).firstOrNull;
  Story? story(String id) => stories.where((x) => x.id == id).firstOrNull;
  ContentTheme theme(String id) => themes.firstWhere((x) => x.id == id);
  GameDef game(String id) => games.firstWhere((x) => x.id == id);
  List<ContentItem> pool(
    String theme,
    Difficulty difficulty, {
    bool requireAudio = false,
    bool requireSfx = false,
  }) => items
      .where(
        (x) =>
            x.theme == theme &&
            Difficulty.values.byName(x.tier).index <= difficulty.index &&
            (!requireAudio || x.audio.isNotEmpty) &&
            (!requireSfx || x.sfx != null),
      )
      .toList();

  bool hasLocalizedG10Content(
    String theme,
    Difficulty difficulty,
    String locale,
  ) {
    final eligible = pool(theme, difficulty).where((item) {
      if (theme == 'animals' || theme == 'vehicles') return item.sfx != null;
      return item.audioFor(locale) != null;
    });
    return eligible.length >= 2;
  }

  List<ContentItem> g14HardTargetPool(String theme, Difficulty difficulty) =>
      pool(theme, difficulty)
          .where((item) => item.verifiedPhotoPaths.length >= 2)
          .toList(growable: false);

  bool hasG14HardVariants(String theme) {
    final visualIds = pool(
      theme,
      Difficulty.hard,
    ).where((item) => item.images.isNotEmpty).map((item) => item.id).toSet();
    return visualIds.length >= 2 &&
        g14HardTargetPool(
          theme,
          Difficulty.hard,
        ).any((item) => visualIds.contains(item.id));
  }

  bool isGameContentAvailable(
    String theme,
    String game,
    Difficulty difficulty,
  ) =>
      game != 'G14' ||
      difficulty != Difficulty.hard ||
      hasG14HardVariants(theme);
}
