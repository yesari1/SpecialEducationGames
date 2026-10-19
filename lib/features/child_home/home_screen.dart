import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/content/content_repository.dart';
import '../../core/learning/policies.dart';
import '../family/parent_gate.dart';
import 'daily_path_view.dart';
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
    return Scaffold(
      body: SafeArea(
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
                  HoldButton(
                    semanticsLabel: l10n.homeFamilyHint,
                    onHeld: () async {
                      if (await showParentGate(context, s) && context.mounted) {
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
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.homeGames, style: SegText.label),
                        icon: const Icon(Icons.sports_esports_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.homeDailyPath, style: SegText.label),
                        icon: const Icon(Icons.route_rounded),
                      ),
                    ],
                    selected: {path},
                    onSelectionChanged: (v) => setState(() => path = v.first),
                  ),
                  Row(
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SegSpace.s5),
              child: Text(
                l10n.greeting(s.active?.nickname ?? ''),
                style: MediaQuery.sizeOf(context).height < 500
                    ? SegText.heading
                    : SegText.title,
              ),
            ),
            if (MediaQuery.sizeOf(context).height >= 500)
              const SizedBox(height: SegSpace.s2),
            if (MediaQuery.sizeOf(context).height >= 500)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SegSpace.s5),
                child: Text(
                  path ? l10n.homePathSubtitle : l10n.homeGamesSubtitle,
                  style: SegText.label.copyWith(color: SegColors.inkSoft),
                ),
              ),
            Expanded(
              child: path
                  ? DailyPathView(state: s)
                  : HorizontalCards(
                      count: s.orderedThemes.length,
                      builder: (i) {
                        final t = s.orderedThemes[i];
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
                          visual: ItemVisual(hero),
                          onTap: () => context.go('/theme/${t.id}'),
                        );
                      },
                    ),
            ),
          ],
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
    final games =
        s
            .gamesForTheme(t.id)
            .where((id) => !s.onlyFree || s.canPlay(t.id, id, tier))
            .toList()
          ..sort(
            (a, b) => (s.canPlay(t.id, b, tier) ? 1 : 0).compareTo(
              s.canPlay(t.id, a, tier) ? 1 : 0,
            ),
          );
    return Scaffold(
      backgroundColor: SegColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SegSpace.s5,
                vertical: SegSpace.s3,
              ),
              child: Wrap(
                spacing: SegSpace.s5,
                runSpacing: SegSpace.s4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: l10n.themeBack,
                  ),
                  Text(t.name(s.locale), style: SegText.title),
                  SegmentedButton<Difficulty>(
                    segments: Difficulty.values
                        .map(
                          (d) => ButtonSegment(
                            value: d,
                            label: Text(switch (d) {
                              Difficulty.easy => l10n.difficultyEasy,
                              Difficulty.medium => l10n.difficultyMedium,
                              Difficulty.hard => l10n.difficultyHard,
                            }, style: SegText.item),
                            icon: Icon(
                              [
                                Icons.circle,
                                Icons.square,
                                Icons.change_history_rounded,
                              ][d.index],
                            ),
                          ),
                        )
                        .toList(),
                    selected: {tier},
                    onSelectionChanged: s.difficultyOverride == 'auto'
                        ? (v) => setState(() => difficulty = v.first)
                        : null,
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
                          subtitle: g.id == 'G01' ? t.name(s.locale) : '',
                          visual: Stack(
                            alignment: Alignment.center,
                            children: [
                              ItemVisual(hero),
                              if (g.id != 'G01')
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Icon(
                                    gameIcon(g.id),
                                    size: 48,
                                    color: t.deep,
                                  ),
                                ),
                            ],
                          ),
                          locked: locked || contentUnavailable,
                          onTap: () {
                            if (contentUnavailable) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.gameThereIsNotEnoughContentForThis,
                                    style: SegText.item,
                                  ),
                                ),
                              );
                              return;
                            }
                            if (locked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.themeUnlockWithFamily,
                                    style: SegText.item,
                                  ),
                                ),
                              );
                            } else {
                              context.go('/game/${t.id}/${g.id}/${tier.name}');
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
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
  _ => Icons.search_rounded,
};
