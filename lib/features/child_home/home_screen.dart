import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
  Timer? _dayTick;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ready before the first switch, so a tab never shows a blank frame.
    for (final tab in HomeTab.values) {
      unawaited(precacheImage(AssetImage(_background(tab)), context));
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

  /// The next or the previous section, when a row is pulled past its end.
  void _step(int by) {
    final next = s.homeTab.index + by;
    if (next < 0 || next >= HomeTab.values.length) return;
    _open(HomeTab.values[next]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final tab = s.homeTab;
    final look = _SectionLook.of(tab);
    final reduced = MediaQuery.disableAnimationsOf(context);
    // The bar floats over the cards; this much stays clear under a single
    // row and at the end of the list.
    final barRoom =
        _SectionBar.height +
        SegSpace.s3 +
        math.max(MediaQuery.paddingOf(context).bottom, SegSpace.s2);
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
                    SegSpace.s1,
                    SegSpace.s5,
                    0,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/illustrations/onboarding/mascot_cloud.png',
                        key: const ValueKey('home-mascot'),
                        height: 34,
                        excludeFromSemantics: true,
                      ),
                      const Spacer(),
                      PillButton(
                        key: const ValueKey('home-stickers'),
                        compact: true,
                        semanticsLabel: l10n.dailyPathMyStickers,
                        onPressed: () => context.go('/stickers'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 20,
                              color: SegColors.starDeep,
                            ),
                            const SizedBox(width: SegSpace.s1),
                            Text(
                              l10n.dailyPathMyStickers,
                              style: SegText.caption.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SegColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: SegSpace.s2),
                      PillButton(
                        key: const ValueKey('home-family'),
                        compact: true,
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
                            const Icon(
                              Icons.people_outline_rounded,
                              size: 20,
                              color: SegColors.primaryDeep,
                            ),
                            const SizedBox(width: SegSpace.s1),
                            Text(
                              l10n.homeFamily,
                              style: SegText.caption.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SegColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  // No glow or stretch at a row's end: the pull changes the
                  // section instead.
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    child: EdgePull(
                      onNext: () => _step(1),
                      onPrevious: () => _step(-1),
                      child: AnimatedSwitcher(
                        duration: reduced
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        child: KeyedSubtree(
                          key: ValueKey('home-section-${tab.name}'),
                          child: switch (tab) {
                            HomeTab.learn => _LearnSection(
                              state: s,
                              barRoom: barRoom,
                            ),
                            HomeTab.stories => _SingleRow(
                              barRoom: barRoom,
                              builder: (inset) =>
                                  StoryShelf(state: s, bottomInset: inset),
                            ),
                            HomeTab.park => _SingleRow(
                              barRoom: barRoom,
                              builder: (inset) =>
                                  _ParkSection(state: s, bottomInset: inset),
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floats over the cards: nothing is cut off behind a band.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SectionBar(
              selected: tab,
              onSelected: _open,
              tabs: [
                (HomeTab.learn, Icons.school_rounded, l10n.homeTabLearn),
                (HomeTab.stories, Icons.menu_book_rounded, l10n.homeTabStories),
                (HomeTab.park, Icons.toys_rounded, l10n.homeTabPark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns a pull past the end of a sideways row into [onNext] (past the right
/// end) or [onPrevious] (past the left end). Only a pull that starts at that
/// end counts, so scrolling a row to its end never changes the section by
/// itself.
class EdgePull extends StatefulWidget {
  final Widget child;
  final VoidCallback onNext, onPrevious;
  const EdgePull({
    super.key,
    required this.child,
    required this.onNext,
    required this.onPrevious,
  });
  @override
  State<EdgePull> createState() => _EdgePullState();
}

class _EdgePullState extends State<EdgePull> {
  static const _needed = 56.0;
  double _pull = 0;
  bool _atStart = false, _atEnd = false, _fired = false;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.horizontal) return false;
    if (n is ScrollStartNotification) {
      _pull = 0;
      _fired = false;
      _atStart = n.metrics.pixels <= n.metrics.minScrollExtent + 1;
      _atEnd = n.metrics.pixels >= n.metrics.maxScrollExtent - 1;
    } else if (n is OverscrollNotification && n.dragDetails != null) {
      _pull += n.overscroll;
      if (_fired) return false;
      if (_pull > _needed && _atEnd) {
        _fired = true;
        widget.onNext();
      } else if (_pull < -_needed && _atStart) {
        _fired = true;
        widget.onPrevious();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      );
}

/// The colours of one section of the home.
class _SectionLook {
  final Color base, deep, soft, strong;
  const _SectionLook(this.base, this.deep, this.soft, this.strong);
  static _SectionLook of(HomeTab tab) => switch (tab) {
    HomeTab.learn => const _SectionLook(
      Color(0xFFEAF8F5),
      Color(0xFF087B80),
      Color(0xFFD3F1EC),
      Color(0xFF10B7B0),
    ),
    HomeTab.stories => const _SectionLook(
      Color(0xFFFFF3E6),
      Color(0xFFBA4C08),
      Color(0xFFFFE3CB),
      Color(0xFFFF8A32),
    ),
    HomeTab.park => const _SectionLook(
      Color(0xFFF1EEFD),
      Color(0xFF544BB5),
      Color(0xFFE2DDFA),
      Color(0xFF7C73DF),
    ),
  };
}

/// The bottom tabs with their names: the open one is filled with its
/// section's colour, the others are plain grey.
class _SectionBar extends StatelessWidget {
  static const height = 52.0;
  final HomeTab selected;
  final ValueChanged<HomeTab> onSelected;
  final List<(HomeTab, IconData, String)> tabs;
  const _SectionBar({
    required this.selected,
    required this.onSelected,
    required this.tabs,
  });
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: SegSpace.s2),
      child: Center(
        heightFactor: 1,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: SegColors.surface,
            borderRadius: BorderRadius.circular(SegRadius.pill),
            boxShadow: [
              BoxShadow(
                color: SegColors.ink.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (tab, icon, label) in tabs)
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
                      // Only the open section is coloured; the others are
                      // quiet grey, so where the child is reads at a glance.
                      child: AnimatedContainer(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        height: height - 8,
                        padding: EdgeInsets.symmetric(
                          horizontal: tab == selected
                              ? SegSpace.s5
                              : SegSpace.s4,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: tab == selected
                                ? [
                                    _SectionLook.of(tab).strong,
                                    _SectionLook.of(tab).deep,
                                  ]
                                : const [
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(SegRadius.pill),
                          boxShadow: [
                            if (tab == selected)
                              BoxShadow(
                                color: _SectionLook.of(
                                  tab,
                                ).deep.withValues(alpha: .35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: tab == selected ? 26 : 22,
                              color: tab == selected
                                  ? Colors.white
                                  : SegColors.inkFaint,
                            ),
                            const SizedBox(width: SegSpace.s2),
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              style: SegText.label.copyWith(
                                fontSize: tab == selected ? 17 : 15,
                                color: tab == selected
                                    ? Colors.white
                                    : SegColors.inkSoft,
                                fontWeight: tab == selected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
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

/// One row of big cards (Stories, Play Park), kept clear of the bar.
class _SingleRow extends StatelessWidget {
  final double barRoom;
  final Widget Function(double bottomInset) builder;
  const _SingleRow({required this.barRoom, required this.builder});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // On a tall screen the cards stay card-sized and sit in the middle.
      final free = box.maxHeight - barRoom;
      final height = math.min(free, 300.0);
      return Padding(
        padding: EdgeInsets.only(top: (free - height) / 2),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(height: height + barRoom, child: builder(barRoom)),
        ),
      );
    },
  );
}

/// The theme rows; scrolls up and down, under the floating bar.
class _LearnSection extends StatefulWidget {
  final AppState state;
  final double barRoom;
  const _LearnSection({required this.state, required this.barRoom});
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
        // One whole row and the top of the next: there is always more to see
        // below, and nothing is cut by a band.
        final rowHeight = (box.maxHeight * .58).clamp(176.0, 250.0);
        // Rows scrolled up melt away under the top bar instead of being cut
        // by a hard line: a thin strip in the sky's own colour lies over the
        // top of the list. (Not a ShaderMask: that redraws the whole list
        // through an extra layer on every frame and made scrolling stutter.)
        const sky = Color(0xFFC8FAF9);
        return Stack(
          fit: StackFit.expand,
          children: [
            _list(l10n, open, rowHeight, deep),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 14,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [sky, sky.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _list(
    AppLocalizations l10n,
    Map<String, ContentTheme> open,
    double rowHeight,
    Color deep,
  ) {
    return ListView(
      key: const ValueKey('home-learn-list'),
      controller: _scroll,
      padding: EdgeInsets.only(top: 2, bottom: widget.barRoom),
      children: [
        for (final (title, ids) in homeRows(l10n))
          if (ids.where(open.containsKey).toList() case final themes
              when themes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SegSpace.s5,
                SegSpace.s2,
                SegSpace.s5,
                0,
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SegText.label.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: deep,
                ),
              ),
            ),
            SizedBox(
              height: rowHeight,
              child: HorizontalCards(
                key: ValueKey('home-row-${ids.first}'),
                count: themes.length,
                cardAspect: .92,
                tight: true,
                builder: (i) => _themeCard(context, open[themes[i]]!),
              ),
            ),
          ],
      ],
    );
  }

  Widget _themeCard(BuildContext context, ContentTheme t) {
    final s = widget.state;
    final l10n = scopedLocalizations(context, s.locale);
    return ThemeGameCard(
      key: ValueKey('home-theme-${t.id}'),
      theme: t,
      dense: true,
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

/// The big tiles of the Play Park.
class _ParkSection extends StatelessWidget {
  final AppState state;
  final double bottomInset;
  const _ParkSection({required this.state, this.bottomInset = 0});
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
      bottomInset: bottomInset,
      tight: true,
      centered: true,
      cardAspect: .95,
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
    difficulty =
        s.pickedDifficulty ??
        SurveyMapper.initialForTheme(survey, widget.themeId);
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
                padding: const EdgeInsets.fromLTRB(
                  SegSpace.s5,
                  SegSpace.s2,
                  SegSpace.s5,
                  0,
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
                        style: SegText.heading.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Color.lerp(t.deep, SegColors.ink, .45),
                        ),
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
                              ? (v) {
                                  setState(() => difficulty = v);
                                  unawaited(s.pickDifficulty(v));
                                }
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
                        cardAspect: .8,
                        tight: true,
                        centered: true,
                        bottomInset: SegSpace.s1,
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
                              gameFace(s.content, t.id, g.id) ??
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

/// The picture on a game's card when the game has a subject of its own (a
/// toothbrush for brushing teeth, the child for the games about the body);
/// other games show an object of the theme. Pictures of the child follow the
/// profile (Ali or Ayşe) like everywhere else.
ContentItem? gameFace(
  ContentRepository content,
  String themeId,
  String gameId,
) {
  const child = 'assets/images/wear/boy.webp';
  const face = 'assets/images/wear/ali_face.webp';
  const body = 'assets/images/wear/ali_full.webp';
  final picture = switch ((themeId, gameId)) {
    ('body', 'G02') => face,
    ('body', 'G01') => body,
    ('body', 'G14') => face,
    ('body', 'G47') => body,
    ('body', 'G48') => child,
    ('emotions', 'G44') => 'assets/images/need/toothache.webp',
    ('emotions', 'G45') => 'assets/images/faces/elif_happy.webp',
    _ => null,
  };
  if (picture != null) {
    return ContentItem.fromJson({
      'id': 'card.$themeId.$gameId',
      'theme': 'extra',
      'tier': 'easy',
      'name': {'tr': '', 'en': ''},
      'images': [picture],
    });
  }
  final id = const {
    'G60': 'cleaning.toothbrush',
    'G61': 'cleaning.tap',
    'G62': 'cleaning.towel',
    'G63': 'wear.boy',
    'G64': 'weather.sun',
    'G49': 'wear.socks',
    'G65': 'fruit.strawberry',
    'G66': 'kitchen.plate',
    'G67': 'kitchen.fridge',
    'G68': 'use.stethoscope',
    'G69': 'need.cat_tree',
    'G70': 'place.hospital',
    'G71': 'grow.can',
    'G72': 'season.blossom',
    'G73': 'nature.rainbow',
  }[gameId];
  return id == null ? null : content.anyItem(id);
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
