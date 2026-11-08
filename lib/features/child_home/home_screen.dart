import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/scene_backdrop.dart';
import '../../core/content/content_repository.dart';
import '../../core/learning/policies.dart';
import '../family/parent_gate.dart';
import '../stories/story_screens.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

/// The rows of the Learn section, in order. A theme that is not open yet
/// has no card, and a row with no cards has no title.
List<(String, List<String>)> homeRows(AppLocalizations l10n) => [
  (l10n.homeRowAnimalsFood, const ['animals', 'produce', 'food']),
  (l10n.homeRowDaily, const ['cleaning', 'clothes', 'kitchen']),
  (l10n.homeRowHomeOutside, const ['home', 'vehicles', 'jobs', 'nature']),
  (l10n.homeRowBasics, const ['colors', 'shapes', 'numbers']),
  (l10n.homeRowBodyFeelings, const ['body', 'emotions']),
];

class HomeScreen extends StatefulWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _queryRead = false;
  Timer? _dayTick;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_queryRead) {
      _queryRead = true;
      // The child's first arrival after setup: Learn, at the top.
      if (GoRouter.maybeOf(
            context,
          )?.routerDelegate.currentConfiguration.uri.queryParameters['path'] ==
          'true') {
        s.homeTab = HomeTab.learn;
        s.homeLearnOffset = 0;
      }
      // Ready before the first switch, so a tab never shows a blank frame.
      for (final tab in HomeTab.values) {
        unawaited(precacheImage(AssetImage(_background(tab)), context));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _dayTick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dayTick?.cancel();
    super.dispose();
  }

  AppState get s => widget.state;

  static String _background(HomeTab tab) =>
      'assets/illustrations/home/bg_${tab.name}.jpg';

  void _open(HomeTab tab) {
    setState(() => s.homeTab = tab);
    unawaited(
      s.audio.playSequence([
        'assets/audio/${s.locale}/sections/tab_${tab.name}.mp3',
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final tab = s.homeTab;
    final look = _SectionLook.of(tab);
    return Scaffold(
      backgroundColor: look.base,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _background(tab),
            key: ValueKey('home-backdrop-${tab.name}'),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SegSpace.s5,
                  SegSpace.s2,
                  SegSpace.s5,
                  SegSpace.s2,
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/illustrations/onboarding/mascot_cloud.png',
                      key: const ValueKey('home-mascot'),
                      height: 48,
                      excludeFromSemantics: true,
                    ),
                    const Spacer(),
                    PillButton(
                      key: const ValueKey('home-stickers'),
                      semanticsLabel: l10n.dailyPathMyStickers,
                      onPressed: () => context.go('/stickers'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded),
                          const SizedBox(width: SegSpace.s2),
                          Text(l10n.dailyPathMyStickers, style: SegText.label),
                        ],
                      ),
                    ),
                    const SizedBox(width: SegSpace.s3),
                    PillButton(
                      key: const ValueKey('home-family'),
                      semanticsLabel: l10n.homeFamilyHint,
                      onPressed: () async {
                        if (await showParentGate(context, s) &&
                            context.mounted) {
                          context.go('/family');
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded),
                          const SizedBox(width: SegSpace.s2),
                          Text(l10n.homeFamily, style: SegText.label),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (tab) {
                  HomeTab.learn => _LearnSection(state: s),
                  HomeTab.stories => StoryShelf(state: s),
                  HomeTab.park => _ParkSection(state: s),
                },
              ),
              _SectionBar(
                  selected: tab,
                  onSelected: _open,
                  tabs: [
                    (
                      HomeTab.learn,
                      Icons.school_outlined,
                      Icons.school_rounded,
                      l10n.homeTabLearn,
                    ),
                    (
                      HomeTab.stories,
                      Icons.menu_book_outlined,
                      Icons.menu_book_rounded,
                      l10n.homeTabStories,
                    ),
                    (
                      HomeTab.park,
                      Icons.toys_outlined,
                      Icons.toys_rounded,
                      l10n.homeTabPark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The colours of one section of the home.
class _SectionLook {
  final Color base, deep, soft;
  const _SectionLook(this.base, this.deep, this.soft);
  static _SectionLook of(HomeTab tab) => switch (tab) {
    HomeTab.learn => const _SectionLook(
      Color(0xFFEAF8F5),
      Color(0xFF087B80),
      Color(0xFFD3F1EC),
    ),
    HomeTab.stories => const _SectionLook(
      Color(0xFFFFF3E6),
      Color(0xFFBA4C08),
      Color(0xFFFFE3CB),
    ),
    HomeTab.park => const _SectionLook(
      Color(0xFFF1EEFD),
      Color(0xFF544BB5),
      Color(0xFFE2DDFA),
    ),
  };
}

/// The bottom tabs: the open section is wide with its icon and name, the
/// others show only their icon.
class _SectionBar extends StatelessWidget {
  final HomeTab selected;
  final ValueChanged<HomeTab> onSelected;
  final List<(HomeTab, IconData, IconData, String)> tabs;
  const _SectionBar({
    required this.selected,
    required this.onSelected,
    required this.tabs,
  });
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final look = _SectionLook.of(selected);
    final duration = reduced ? Duration.zero : const Duration(milliseconds: 280);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: SegSpace.s1),
      child: Center(
        heightFactor: 1,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: SegColors.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(SegRadius.pill),
            boxShadow: [
              BoxShadow(
                color: SegColors.ink.withValues(alpha: .10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (tab, icon, selectedIcon, label) in tabs)
                  Semantics(
                    button: true,
                    selected: tab == selected,
                    label: label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('home-tab-${tab.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        UiSound.tap();
                        onSelected(tab);
                      },
                      child: AnimatedContainer(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        width: tab == selected ? 178 : 76,
                        height: 50,
                        decoration: BoxDecoration(
                          color: tab == selected
                              ? look.soft
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(SegRadius.pill),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tab == selected ? selectedIcon : icon,
                              size: 26,
                              color: tab == selected
                                  ? look.deep
                                  : SegColors.inkSoft,
                            ),
                            if (tab == selected) ...[
                              const SizedBox(width: SegSpace.s2),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                  style: SegText.label.copyWith(
                                    color: look.deep,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The theme rows; scrolls up and down.
class _LearnSection extends StatefulWidget {
  final AppState state;
  const _LearnSection({required this.state});
  @override
  State<_LearnSection> createState() => _LearnSectionState();
}

class _LearnSectionState extends State<_LearnSection> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.state.homeLearnOffset,
  )..addListener(() => widget.state.homeLearnOffset = _scroll.offset);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    final open = {for (final t in s.orderedThemes) t.id: t};
    return LayoutBuilder(
      builder: (context, box) {
        final deep = _SectionLook.of(HomeTab.learn).deep;
        final rowHeight = (box.maxHeight * .86).clamp(200.0, 340.0);
        return ListView(
          key: const ValueKey('home-learn-list'),
          controller: _scroll,
          padding: const EdgeInsets.only(bottom: SegSpace.s3),
          children: [
            for (final (title, ids) in homeRows(l10n))
              if (ids.where(open.containsKey).toList() case final themes
                  when themes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SegSpace.s5,
                    SegSpace.s3,
                    SegSpace.s5,
                    0,
                  ),
                  child: Text(
                    title,
                    style: SegText.heading.copyWith(color: deep),
                  ),
                ),
                SizedBox(
                  height: rowHeight,
                  child: HorizontalCards(
                    key: ValueKey('home-row-${ids.first}'),
                    count: themes.length,
                    builder: (i) => _themeCard(context, open[themes[i]]!),
                  ),
                ),
              ],
          ],
        );
      },
    );
  }

  Widget _themeCard(BuildContext context, ContentTheme t) {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    return ThemeGameCard(
      key: ValueKey('home-theme-${t.id}'),
      theme: t,
      title: t.name(s.locale),
      badgeText: s.configuration.newBadge.contains(t.id)
          ? l10n.homeNewBadge
          : null,
      subtitle: '',
      visual: themeCover(
        t.id,
        s.content.items.firstWhere((x) => x.id == t.hero),
      ),
      normalizedVisual: themeCovers.contains(t.id),
      onTap: () => context.go('/theme/${t.id}'),
    );
  }
}

/// The four big tiles of the Play Park.
class _ParkSection extends StatelessWidget {
  final AppState state;
  const _ParkSection({required this.state});
  static final _theme = ContentTheme.fromJson({
    'id': 'park',
    'hero': '',
    'name': {'tr': 'Oyun Parkı', 'en': 'Play Park'},
    'games': <String>[],
    'palette': {'bg': '#F6F4FE', 'accent': '#7C73DF', 'deep': '#544BB5'},
  });
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final tiles = [
      // A game that is not ready yet has no tile.
      if (state.content.coloringPages.isNotEmpty)
        ('coloring', l10n.parkColoring, '/park/coloring'),
      if (state.orderedThemes.any((t) => t.id == 'music'))
        ('music', l10n.parkMusic, '/theme/music'),
      ('puzzle', l10n.parkPuzzle, '/park/puzzle'),
      ('bubbles', l10n.parkBubbles, '/park/bubbles'),
    ];
    return HorizontalCards(
      count: tiles.length,
      builder: (i) {
        final (id, title, route) = tiles[i];
        return ThemeGameCard(
          key: ValueKey('park-tile-$id'),
          theme: _theme,
          title: title,
          subtitle: '',
          visual: Image.asset(
            'assets/illustrations/park/tile_$id.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            excludeFromSemantics: true,
          ),
          normalizedVisual: true,
          onTap: () => context.go(route),
        );
      },
    );
  }
}

class ThemeScreen extends StatefulWidget {
  final AppState state;
  final String themeId;
  const ThemeScreen({super.key, required this.state, required this.themeId});
  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  Difficulty difficulty = Difficulty.easy;
  AppState get s => widget.state;
  @override
  void initState() {
    super.initState();
    final survey =
        jsonDecode(s.active?.payload ?? '{}') as Map<String, dynamic>;
    difficulty = SurveyMapper.initialForTheme(survey, widget.themeId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final t = s.content.theme(widget.themeId);
    final tier = s.difficultyOverride == 'auto'
        ? difficulty
        : Difficulty.values.byName(s.difficultyOverride);
    final hero = s.content.items.firstWhere((x) => x.id == t.hero);
    // Each game card shows a different object from the theme for variety.
    final faces = [
      hero,
      ...s.content.items.where(
        (x) =>
            x.theme == t.id &&
            x.id != hero.id &&
            (x.images.isNotEmpty ||
                const {'numbers', 'colors', 'shapes'}.contains(t.id)) &&
            x.slug != '0',
      ),
    ];
    final games = s.gamesForTheme(t.id).toList()
      ..sort((a, b) {
        final open = (s.canPlay(t.id, b, tier) ? 1 : 0).compareTo(
          s.canPlay(t.id, a, tier) ? 1 : 0,
        );
        if (open != 0 || !(s.ageBand?.prefersTap ?? false)) return open;
        // 2–3: tap games first, drag games after them.
        return (AgeBand.dragGames.contains(a) ? 1 : 0).compareTo(
          AgeBand.dragGames.contains(b) ? 1 : 0,
        );
      });
    return Scaffold(
      backgroundColor: SegColors.canvas,
      body: SceneBackdrop(
        tint: t.accent,
        clouds: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegSpace.s5,
                  vertical: SegSpace.s3,
                ),
                // Back and title stay on the left, the levels on the right,
                // whatever the length of the theme name.
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        UiSound.tap();
                        context.go('/');
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: l10n.themeBack,
                    ),
                    const SizedBox(width: SegSpace.s3),
                    Expanded(
                      child: Text(
                        t.name(s.locale),
                        style: SegText.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: SegSpace.s3),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .55,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: PillToggle<Difficulty>(
                          values: Difficulty.values,
                          selected: tier,
                          label: (d) => switch (d) {
                            Difficulty.easy => l10n.difficultyEasy,
                            Difficulty.medium => l10n.difficultyMedium,
                            Difficulty.hard => l10n.difficultyHard,
                          },
                          icon: (d) => [
                            Icons.circle,
                            Icons.square_rounded,
                            Icons.change_history_rounded,
                          ][d.index],
                          onChanged: s.difficultyOverride == 'auto'
                              ? (v) => setState(() => difficulty = v)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: games.isEmpty
                    ? Center(
                        child: Text(
                          l10n.themeNoUnlockedGames,
                          style: SegText.heading,
                        ),
                      )
                    : HorizontalCards(
                        count: games.length,
                        builder: (i) {
                          final g = s.content.game(games[i]);
                          final locked = !s.canPlay(t.id, g.id, tier);
                          final effectiveTier = s.recommendedDifficulty(
                            t.id,
                            g.id,
                            tier,
                          );
                          final contentUnavailable =
                              g.id == 'G14' &&
                              effectiveTier == Difficulty.hard &&
                              !s.content.isGameContentAvailable(
                                t.id,
                                g.id,
                                effectiveTier,
                              );
                          return ThemeGameCard(
                            theme: t,
                            title: g.name(s.locale),
                            subtitle: '',
                            visual: ItemVisual(
                              faces[i % faces.length],
                              alignment: Alignment.bottomCenter,
                            ),
                            modeIcon: g.id == 'G01' ? null : gameIcon(g.id),
                            locked: locked || contentUnavailable,
                            tapSound: false,
                            onTap: () {
                              if (contentUnavailable) {
                                showNotice(
                                  context,
                                  l10n.gameThereIsNotEnoughContentForThis,
                                  icon: Icons.photo_library_rounded,
                                  color: SegColors.accent,
                                );
                                return;
                              }
                              if (locked) {
                                UiSound.tap();
                                showLockedGameNotice(
                                  context,
                                  title: l10n.lockedGameTitle,
                                  body: l10n.lockedGameBody,
                                  ok: l10n.lockedGameOk,
                                );
                              } else {
                                UiSound.gameOpen();
                                context.go(
                                  '/game/${t.id}/${g.id}/${tier.name}',
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData gameIcon(String id) => switch (id) {
  'G02' => Icons.style_rounded,
  'G10' => Icons.volume_up_rounded,
  'G14' => Icons.copy_rounded,
  'G33' => Icons.numbers_rounded,
  'G35' => Icons.arrow_forward_rounded,
  'G36' => Icons.balance_rounded,
  'G55' => Icons.touch_app_rounded,
  'G04' => Icons.category_rounded,
  'G15' => Icons.dark_mode_rounded,
  'G17' => Icons.highlight_alt_rounded,
  'G23' => Icons.shopping_basket_rounded,
  'G37' => Icons.looks_3_rounded,
  'G38' => Icons.add_shopping_cart_rounded,
  'G11' => Icons.hearing_rounded,
  'G40' => Icons.palette_rounded,
  'G41' => Icons.shopping_basket_rounded,
  'G42' => Icons.format_paint_rounded,
  'G43' => Icons.category_rounded,
  'G44' => Icons.photo_rounded,
  'G45' => Icons.people_rounded,
  'G46' => Icons.hearing_rounded,
  'G47' => Icons.accessibility_new_rounded,
  'G48' => Icons.lightbulb_rounded,
  'G49' => Icons.checkroom_rounded,
  'G60' => Icons.brush_rounded,
  'G61' => Icons.wash_rounded,
  'G62' => Icons.help_rounded,
  'G63' => Icons.checkroom_rounded,
  'G64' => Icons.wb_sunny_rounded,
  'G65' => Icons.restaurant_rounded,
  'G66' => Icons.dinner_dining_rounded,
  'G67' => Icons.kitchen_rounded,
  'G68' => Icons.handyman_rounded,
  'G69' => Icons.volunteer_activism_rounded,
  'G70' => Icons.location_on_rounded,
  'G71' => Icons.local_florist_rounded,
  'G72' => Icons.park_rounded,
  'G73' => Icons.cloud_rounded,
  'G74' => Icons.hearing_rounded,
  'G75' => Icons.touch_app_rounded,
  'G76' => Icons.music_note_rounded,
  _ => Icons.search_rounded,
};

/// Themes with an illustrated cover (assets/illustrations/themes, one style,
/// same framing). Others fall back to their hero photo.
const themeCovers = {
  'animals',
  'produce',
  'food',
  'vehicles',
  'colors',
  'shapes',
  'numbers',
  'emotions',
  'body',
  'home',
  'cleaning',
  'clothes',
  'kitchen',
  'jobs',
  'nature',
  'music',
};

Widget themeCover(String themeId, ContentItem hero) =>
    themeCovers.contains(themeId)
    ? Image.asset(
        'assets/illustrations/themes/cover_$themeId.png',
        key: ValueKey('theme-cover-$themeId'),
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        excludeFromSemantics: true,
      )
    : ItemVisual(hero, alignment: Alignment.bottomCenter);
