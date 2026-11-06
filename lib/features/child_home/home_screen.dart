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
import 'daily_path_view.dart';
import '../stories/story_screens.dart';
import '../../l10n/scoped_localizations.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool path = false;
  bool _pathInitialized = false;
  Timer? _dayTick;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pathInitialized) {
      _pathInitialized = true;
      path =
          GoRouter.maybeOf(
            context,
          )?.routerDelegate.currentConfiguration.uri.queryParameters['path'] ==
          'true';
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
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final stories = s.content.stories.isNotEmpty;
    Widget backdrop({required Widget child}) => path
        // Today's Path: the map is the whole screen, behind the top bar too.
        ? Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  DailyPathView.mapAsset,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              child,
            ],
          )
        : SceneBackdrop(clouds: false, child: child);
    return Scaffold(
      body: backdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegSpace.s5,
                  vertical: SegSpace.s3,
                ),
                child: Wrap(
                  spacing: SegSpace.s5,
                  runSpacing: SegSpace.s3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    PillButton(
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
                    PillToggle<bool>(
                      values: const [false, true],
                      selected: path,
                      label: (v) => v ? l10n.homeDailyPath : l10n.homeGames,
                      icon: (v) => v
                          ? Icons.route_rounded
                          : Icons.sports_esports_rounded,
                      onChanged: (v) => setState(() => path = v),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SegSpace.s4,
                        vertical: SegSpace.s2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(SegRadius.pill),
                        border: Border.all(color: SegColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: SegColors.star),
                          const SizedBox(width: SegSpace.s2),
                          Text(
                            '${s.dailyPath.count}/${s.dailyPath.steps.length}',
                            style: SegText.heading.copyWith(
                              color: SegColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!path)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SegSpace.s5),
                  child: Text(
                    l10n.greeting(s.active?.nickname ?? ''),
                    style: MediaQuery.sizeOf(context).height < 500
                        ? SegText.heading
                        : SegText.title,
                  ),
                ),
              if (!path && MediaQuery.sizeOf(context).height >= 500)
                const SizedBox(height: SegSpace.s2),
              if (!path && MediaQuery.sizeOf(context).height >= 500)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SegSpace.s5),
                  child: Text(
                    path ? l10n.homePathSubtitle : l10n.homeGamesSubtitle,
                    style: SegText.label.copyWith(color: SegColors.inkSoft),
                  ),
                ),
              Expanded(
                child: path
                    ? DailyPathView(state: s, background: false)
                    : HorizontalCards(
                        count: s.orderedThemes.length + (stories ? 1 : 0),
                        builder: (i) {
                          if (stories && i == 0) return StoriesCard(state: s);
                          final t = s.orderedThemes[i - (stories ? 1 : 0)];
                          final hero = s.content.items.firstWhere(
                            (x) => x.id == t.hero,
                          );
                          return ThemeGameCard(
                            theme: t,
                            title: t.name(s.locale),
                            badgeText: s.configuration.newBadge.contains(t.id)
                                ? l10n.homeNewBadge
                                : null,
                            subtitle: l10n.homeThemeGameCount(
                              s.gamesForTheme(t.id).length,
                            ),
                            visual: themeCover(t.id, hero),
                            normalizedVisual: themeCovers.contains(t.id),
                            onTap: () => context.go('/theme/${t.id}'),
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
