import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/game_object.dart';
import '../../app/ui/scene_backdrop.dart';
import '../../app/ui/day_sticker.dart';
import '../../core/content/content_repository.dart';
import '../../core/db/app_database.dart';
import '../../core/learning/policies.dart';
import 'round_controller.dart';
import 'widgets/round_choices_view.dart';
import 'widgets/counted_objects.dart';
import 'widgets/tap_discovery.dart';
import 'play_time_break.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

class GameScreen extends StatefulWidget {
  final AppState state;
  final String themeId, gameId;
  final Difficulty difficulty;
  const GameScreen({
    super.key,
    required this.state,
    required this.themeId,
    required this.gameId,
    required this.difficulty,
  });
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final PageController _completionPager = PageController();
  int _completionPage = 0;
  RoundController? controller;
  int card = 0;
  final Set<String> _explored = {};
  bool _exploreComplete = false;
  bool allowed = false;
  Timer? endTimer;
  late Difficulty effectiveDifficulty;
  final Stopwatch _sessionClock = Stopwatch();
  Future<String>? _sessionId;
  bool _sessionFinished = false;
  bool _g14HardContentUnavailable = false;
  Timer? _checkpoint;
  Timer? _budgetTick;
  String? _sessionProfileId;
  int _lastChargedMs = 0;
  bool _limitReached = false;
  AppState get s => widget.state;
  AppLocalizations get l10n => scopedLocalizations(context, s.locale);
  String _promptText(RoundSpec spec) => switch (spec.promptKey) {
    GamePromptKey.counting => l10n.gamePromptCount,
    GamePromptKey.compareMagnitude => l10n.gamePromptCompareMagnitude,
    GamePromptKey.compareNumbers => l10n.gamePromptCompareNumbers,
    GamePromptKey.groupMembership => l10n.gamePromptGroupMembership,
    GamePromptKey.findMatch => l10n.gamePromptFindMatch,
    GamePromptKey.listenForNumber => l10n.gamePromptListenForNumber,
    GamePromptKey.listenForSoundSource => l10n.gamePromptListenForSoundSource,
    GamePromptKey.sequenceNext => l10n.gamePromptSequenceNext,
    GamePromptKey.sequenceMissing => l10n.gamePromptSequenceMissing,
    GamePromptKey.oddOneOut => l10n.gamePromptOddOneOut,
    GamePromptKey.shadowMatch => l10n.gamePromptShadowMatch,
    GamePromptKey.sortIntoBasket => l10n.gamePromptSortIntoBasket,
    GamePromptKey.numberQuantity => l10n.gamePromptNumberQuantity,
    GamePromptKey.fillCount => l10n.gamePromptFillCount(spec.fillCount ?? 0),
    GamePromptKey.whichSound => l10n.gamePromptWhichSound,
    null => s.locale == 'tr' ? spec.promptTr : spec.promptEn,
  };
  bool get exploratory => widget.gameId == 'G02' || widget.gameId == 'G55';
  @override
  void initState() {
    super.initState();
    s.enterGame();
    WidgetsBinding.instance.addObserver(this);
    effectiveDifficulty = s.recommendedDifficulty(
      widget.themeId,
      widget.gameId,
      widget.difficulty,
    );
    _g14HardContentUnavailable =
        widget.gameId == 'G14' &&
        effectiveDifficulty == Difficulty.hard &&
        !s.content.isGameContentAvailable(
          widget.themeId,
          widget.gameId,
          effectiveDifficulty,
        );
    allowed = s.canPlay(widget.themeId, widget.gameId, widget.difficulty);
    if (!allowed) return;
    _limitReached = s.playTimeExpired;
    if (_limitReached) return;
    if (!s.hasRequiredGameAudio(widget.themeId, widget.gameId)) return;
    if (_g14HardContentUnavailable) return;
    if (exploratory) {
      _startSession();
      return;
    }
    final survey =
        jsonDecode(s.active?.payload ?? '{}') as Map<String, dynamic>;
    controller = RoundController(
      content: s.content,
      themeId: widget.themeId,
      gameId: widget.gameId,
      locale: s.locale,
      difficulty: effectiveDifficulty,
      total: s.roundLength > 0
          ? s.roundLength
          : survey.containsKey('focus')
          ? SurveyMapper.map(survey).stages
          : null,
      hintSeconds: s.hintSeconds,
      fadeWrongChoices: s.fadeWrongChoices,
      fadeAfterErrors: s.configuration.fadeAfterErrors,
      choiceCount: s.configuration.choicesFor(effectiveDifficulty),
      struggle: s.struggle,
      performance: s.itemPerformance,
      introduced: s.introduced,
      introduceNewItems:
          s.introduction && SurveyMapper.map(survey).introduction,
      onIntroduced: s.markIntroduced,
      playRetry: () => s.audio.playSequence([
        'assets/audio/${s.locale}/prompts/retry_selected.mp3',
      ]),
      playPrompt: playPrompt,
      saveTrial: (c) async {
        await s.record(
          TrialsCompanion.insert(
            profileId: s.active!.id,
            themeId: widget.themeId,
            gameId: widget.gameId,
            targetId: c.spec!.target.id,
            difficulty: effectiveDifficulty.name,
            wrongCount: c.wrongCount,
            maxHint: c.maxHint,
            latencyMs: c.firstLatency,
            idleMs: Value(c.idleMs),
            activeMs: Value(c.activeMs),
            selectedIds: jsonEncode(c.selected),
            at: DateTime.now(),
          ),
        );
        await s.audio.playSequence(c.template.successCues(c.spec!, s.locale));
      },
    );
    controller!.addListener(changed);
    controller!.start();
    if (controller!.error == null) _startSession();
  }

  void _startSession() {
    if (_sessionId != null || !allowed) return;
    _sessionClock.start();
    _sessionProfileId = s.active!.id;
    _sessionId = s.beginSession(
      widget.themeId,
      widget.gameId,
      effectiveDifficulty,
    );
    _checkpoint?.cancel();
    _checkpoint = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _saveSessionTime(),
    );
    _budgetTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionClock.isRunning) unawaited(_chargeTime());
    });
  }

  Future<void> _chargeTime({bool checkLimit = true}) async {
    final profile = _sessionProfileId;
    if (profile == null) return;
    final elapsed = _sessionClock.elapsedMilliseconds;
    final delta = elapsed - _lastChargedMs;
    _lastChargedMs = elapsed;
    if (delta > 0) await s.chargePlayTime(profile, delta);
    if (checkLimit &&
        mounted &&
        !_sessionFinished &&
        !_limitReached &&
        s.playTimeExpired) {
      _limitReached = true;
      controller?.pause();
      s.audio.stop();
      endTimer?.cancel();
      unawaited(_finishSession(false));
      setState(() {});
    }
  }

  Future<void> _saveSessionTime() async {
    if (_sessionFinished || _sessionId == null) return;
    await _chargeTime();
    final elapsed = _sessionClock.elapsedMilliseconds;
    final id = await _sessionId!;
    await s.checkpointSession(id, elapsed);
  }

  Future<void> _finishSession(bool completed) async {
    if (_sessionFinished || _sessionId == null) return;
    _sessionFinished = true;
    _checkpoint?.cancel();
    _budgetTick?.cancel();
    _sessionClock.stop();
    await _chargeTime(checkLimit: false);
    final elapsed = _sessionClock.elapsedMilliseconds;
    final pendingId = _sessionId!;
    final id = await pendingId;
    await s.finishSession(id, elapsed, completed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_sessionFinished && !_limitReached && _sessionId != null) {
        _sessionClock.start();
        controller?.resume();
      }
    } else {
      _sessionClock.stop();
      controller?.pause();
      unawaited(_saveSessionTime());
    }
  }

  Future<void> playPrompt(RoundSpec spec) async {
    if (spec.introduction) {
      final cue = spec.target.audioFor(s.locale);
      await s.audio.playSequence([?cue]);
      return;
    }
    await s.audio.playSequence(
      controller!.template.introCues(spec, controller!.modeContext, s.locale),
    );
  }

  void changed() {
    if (!mounted || _limitReached) return;
    setState(() {});
    if (controller!.phase == RoundPhase.complete) {
      unawaited(_finishSession(true));
      endTimer ??= Timer(const Duration(seconds: 4), () {
        if (mounted) back();
      });
    }
  }

  void back() {
    s.audio.stop();
    context.go('/theme/${widget.themeId}');
  }

  @override
  void dispose() {
    s.leaveGame();
    _checkpoint?.cancel();
    _budgetTick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_finishSession(false));
    endTimer?.cancel();
    controller?.removeListener(changed);
    controller?.dispose();
    _completionPager.dispose();
    s.audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = s.content.theme(widget.themeId);
    if (_limitReached) return PlayTimeBreak(state: s);
    if (!allowed) {
      return Scaffold(
        body: Center(
          child: SegButton(label: l10n.gameBackToTheme, onPressed: back),
        ),
      );
    }
    if (!s.hasRequiredGameAudio(widget.themeId, widget.gameId)) {
      return Scaffold(
        backgroundColor: theme.bg,
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(SegSpace.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_off_rounded, size: 64),
                const SizedBox(height: SegSpace.s5),
                Text(
                  l10n.gameThisGameNeedsSoundAParentCan,
                  style: SegText.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SegSpace.s5),
                SegButton(label: l10n.gameBackToTheme, onPressed: back),
              ],
            ),
          ),
        ),
      );
    }
    if (_g14HardContentUnavailable) {
      final compact = MediaQuery.sizeOf(context).height < 500;
      return Scaffold(
        backgroundColor: theme.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(compact ? SegSpace.s3 : SegSpace.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: compact ? 40 : 56,
                  ),
                  SizedBox(height: compact ? SegSpace.s2 : SegSpace.s5),
                  Text(
                    l10n.gameThereIsNotEnoughContentForThis,
                    style: SegText.heading,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? SegSpace.s2 : SegSpace.s5),
                  SegButton(label: l10n.gameBackToTheme, onPressed: back),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (exploratory) return _exploreComplete ? _completed(0) : _explore(theme);
    final c = controller!;
    if (c.error != null) {
      final compact = MediaQuery.sizeOf(context).height < 500;
      return Scaffold(
        backgroundColor: theme.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(compact ? SegSpace.s3 : SegSpace.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_off_rounded,
                    size: compact ? 48 : 64,
                    color: SegColors.inkSoft,
                  ),
                  SizedBox(height: compact ? SegSpace.s3 : SegSpace.s5),
                  Text(
                    l10n.gameThereIsNotEnoughContentForThis,
                    style: SegText.heading,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? SegSpace.s3 : SegSpace.s5),
                  SegButton(label: l10n.gameBackToTheme, onPressed: back),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (c.phase == RoundPhase.complete) return _completed(c.total);
    final spec = c.spec!;
    final compact = MediaQuery.sizeOf(context).height < 500;
    // Games that show one object next to the instruction (group, shadow,
    // basket and number-quantity games).
    final groupPrompt = spec.stimulus != null && spec.count == null;
    final g14Prompt = widget.gameId == 'G14';
    final sideBySidePrompt = groupPrompt || g14Prompt;
    // An instruction alone needs little room; give the stage to the objects.
    final textOnlyPrompt =
        !sideBySidePrompt &&
        spec.stimulus == null &&
        spec.count == null &&
        spec.sequence.isEmpty;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SceneBackdrop(
        tint: theme.accent,
        base: theme.bg,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(
                      compact ? SegSpace.s2 : SegSpace.s4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PillButton(
                          semanticsLabel: l10n.gameHoldToLeave,
                          onPressed: back,
                          child: const Icon(Icons.arrow_back_rounded),
                        ),
                        Flexible(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              c.total,
                              (i) => Icon(
                                i < c.stage ||
                                        (i == c.stage &&
                                            !c.spec!.introduction &&
                                            c.phase == RoundPhase.celebrating)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: SegColors.star,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: SegColors.line),
                          ),
                          child: IconButton(
                            iconSize: 28,
                            constraints: const BoxConstraints(
                              minWidth: 64,
                              minHeight: 64,
                            ),
                            color: SegColors.primaryDeep,
                            onPressed: () => playPrompt(spec),
                            icon: const Icon(Icons.volume_up_rounded),
                            tooltip: l10n.gameListenAgain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: sideBySidePrompt && compact
                        ? 4
                        : textOnlyPrompt
                        ? 1
                        : spec.count == null
                        ? 2
                        : 3,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SegSpace.s5,
                        ),
                        // The prompt object stands on the scene next to a
                        // short instruction pill; no full-width banner.
                        child: sideBySidePrompt
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    key: ValueKey(
                                      '${groupPrompt ? 'group-stimulus' : 'g14-prompt'}-${c.generation}',
                                    ),
                                    width: compact ? 104 : 150,
                                    height: compact ? 104 : 150,
                                    child: groupPrompt
                                        ? _stimulus(spec, c)
                                        : StagedObject(
                                            child: spec.promptImagePath == null
                                                ? ItemVisual(
                                                    spec.target,
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                  )
                                                : PhotoVisual(
                                                    spec.promptImagePath!,
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                  ),
                                          ),
                                  ),
                                  if (s.showLabels || g14Prompt) ...[
                                    const SizedBox(width: SegSpace.s4),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: SegSpace.s5,
                                          vertical: SegSpace.s3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            SegRadius.xl,
                                          ),
                                          border: Border.all(
                                            color: SegColors.line,
                                          ),
                                        ),
                                        child: Text(
                                          _promptText(spec),
                                          style: compact
                                              ? SegText.heading
                                              : SegText.title,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : _fitPrompt(
                                context,
                                SegCard(
                                  padding: EdgeInsets.all(
                                    compact ? SegSpace.s3 : SegSpace.s5,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (spec.count != null)
                                        CountedObjects(
                                          key: ValueKey(
                                            'counted-${c.generation}',
                                          ),
                                          count: spec.count!,
                                          item: spec.stimulus,
                                          enabled:
                                              c.phase == RoundPhase.answering,
                                          locale: s.locale,
                                          onCount: (number) {
                                            c.noteInteraction(
                                              itemId:
                                                  spec.stimulus?.id ??
                                                  'count.dot',
                                            );
                                            final item = s.content.items
                                                .where(
                                                  (x) =>
                                                      x.id == 'numbers.$number',
                                                )
                                                .firstOrNull;
                                            final cue = item?.audioFor(
                                              s.locale,
                                            );
                                            if (cue != null) {
                                              s.audio.playSequence([cue]);
                                            }
                                          },
                                        ),
                                      if (spec.stimulus != null &&
                                          spec.count == null)
                                        SizedBox(
                                          width: compact ? 48 : 96,
                                          height: compact ? 48 : 96,
                                          child: ItemVisual(spec.stimulus!),
                                        ),
                                      if (spec.sequence.isNotEmpty)
                                        Text(
                                          spec.sequence.join('   '),
                                          style: SegText.display,
                                        ),
                                      if (widget.gameId == 'G14')
                                        SizedBox(
                                          height: compact ? 48 : 96,
                                          width: compact ? 48 : 96,
                                          child: spec.promptImagePath == null
                                              ? ItemVisual(spec.target)
                                              : PhotoVisual(
                                                  spec.promptImagePath!,
                                                ),
                                        ),
                                      if (s.showLabels)
                                        Text(
                                          _promptText(spec),
                                          style: compact
                                              ? SegText.heading
                                              : SegText.title,
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: sideBySidePrompt && compact
                        ? 5
                        : spec.count == null
                        ? 3
                        : 2,
                    child: Padding(
                      padding: EdgeInsets.all(
                        compact ? SegSpace.s3 : SegSpace.s5,
                      ),
                      child: c.template.buildView(
                        context,
                        spec,
                        RoundCallbacks(
                          onSelect: (item) => c.choose(item),
                          onListen: (item) {
                            c.noteInteraction(itemId: item.id);
                            if (item.sfx case final String sfx) {
                              s.audio.playSequence([sfx]);
                            }
                          },
                        ),
                        HintViewState(
                          level: c.hint,
                          visibleChoices: c.visibleChoices,
                          wrongCount: c.wrongCount,
                          generation: c.generation,
                          celebrating: c.phase == RoundPhase.celebrating,
                          showLabels: s.showLabels,
                          animate: !s.reducedMotion && s.celebration != 'off',
                          locale: s.locale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (s.celebration == 'full' &&
                  c.phase == RoundPhase.celebrating &&
                  !s.reducedMotion &&
                  !MediaQuery.disableAnimationsOf(context))
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: _FullCelebrationBurst(
                        key: ValueKey('full-celebration-${c.generation}'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _completed(int stars) => Scaffold(
    backgroundColor: s.content.theme(widget.themeId).bg,
    body: SceneBackdrop(
      tint: s.content.theme(widget.themeId).accent,
      base: s.content.theme(widget.themeId).bg,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    key: const ValueKey('completion-pages'),
                    controller: _completionPager,
                    onPageChanged: (page) =>
                        setState(() => _completionPage = page),
                    children: [
                      _completionSummary(stars),
                      _completionActions(constraints.maxWidth - 16),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const ValueKey('completion-previous'),
                      tooltip: l10n.gamePreviousPage,
                      onPressed: _completionPage == 0
                          ? null
                          : () => _completionPager.previousPage(
                              duration: SegMotion.pageSlide,
                              curve: Curves.easeOutCubic,
                            ),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      l10n.gameSummaryPage(_completionPage + 1, 2),
                      key: const ValueKey('completion-page-indicator'),
                      textAlign: TextAlign.center,
                      style: SegText.caption,
                    ),
                    IconButton(
                      key: const ValueKey('completion-next'),
                      tooltip: l10n.gameNextPage,
                      onPressed: _completionPage == 1
                          ? null
                          : () => _completionPager.nextPage(
                              duration: SegMotion.pageSlide,
                              curve: Curves.easeOutCubic,
                            ),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _completionSummary(int stars) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: List.generate(
                stars,
                (i) => _PoppingStar(
                  delay: Duration(milliseconds: 120 * i),
                  animate: !s.reducedMotion,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.gameWellDone,
                style: SegText.title.copyWith(color: SegColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (s.hasTodaySticker) ...[
                Row(
                  children: [
                    DaySticker(
                      day: DateTime.now().toIso8601String().substring(0, 10),
                      size: 52,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.gameYouEarnedTodaysSticker,
                        style: SegText.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  l10n.gameWeExploredTogether,
                  style: SegText.body,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _completionActions(double width) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: (width - 24) / 2,
            child: SegButton(
              label: l10n.gameAgain,
              icon: Icons.replay_rounded,
              onPressed: () {
                endTimer?.cancel();
                endTimer = null;
                _sessionId = null;
                _sessionFinished = false;
                _sessionClock.reset();
                _lastChargedMs = 0;
                _explored.clear();
                _exploreComplete = false;
                if (widget.gameId == 'G02' || widget.gameId == 'G55') {
                  card = 0;
                  _explored.clear();
                }
                _startSession();
                if (controller case final c?) {
                  c.stage = 0;
                  c.start();
                }
                setState(() {
                  _completionPage = 0;
                  _completionPager.jumpToPage(0);
                });
              },
            ),
          ),
          SizedBox(
            width: (width - 24) / 2,
            child: SegButton(
              label: l10n.gameTodaysPath,
              icon: Icons.route_rounded,
              onPressed: () => context.go('/?path=true'),
            ),
          ),
          SizedBox(
            width: (width - 24) / 2,
            child: SegButton(
              label: l10n.gameBackToTheme,
              icon: Icons.arrow_forward_rounded,
              onPressed: back,
            ),
          ),
        ],
      ),
    ),
  );

  /// The prompt object. In drag games it can be carried onto a choice; the
  /// choices still accept taps, so dragging is never required.
  Widget _stimulus(RoundSpec spec, RoundController c) {
    final visual = StagedObject(
      child: ItemVisual(spec.stimulus!, alignment: Alignment.bottomCenter),
    );
    if (!spec.dragStimulus || c.phase != RoundPhase.answering) return visual;
    return Draggable<ContentItem>(
      data: spec.stimulus,
      onDragStarted: () => c.noteInteraction(itemId: spec.stimulus!.id),
      feedback: SizedBox.square(
        dimension: 132,
        child: Material(
          type: MaterialType.transparency,
          child: ItemVisual(spec.stimulus!),
        ),
      ),
      childWhenDragging: Opacity(opacity: .25, child: visual),
      child: visual,
    );
  }

  Widget _fitPrompt(BuildContext context, Widget child) => FittedBox(
    fit: BoxFit.scaleDown,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 40,
      ),
      child: child,
    ),
  );

  Widget _explore(ContentTheme theme) {
    final compact = MediaQuery.sizeOf(context).height < 500;
    final items = s.content
        .pool(widget.themeId, effectiveDifficulty)
        .where(
          (x) =>
              x.images.isNotEmpty ||
              x.theme == 'colors' ||
              x.theme == 'numbers' ||
              x.theme == 'shapes',
        )
        .toList();
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.gameImagesForThisThemeAreNotReady)),
      );
    }
    final isFlashcards = widget.gameId == 'G02';
    final isTapDiscovery = widget.gameId == 'G55';
    final requestedCount = isTapDiscovery
        ? switch (effectiveDifficulty) {
            Difficulty.easy => 4,
            Difficulty.medium => 5,
            Difficulty.hard => 6,
          }
        : switch (effectiveDifficulty) {
            Difficulty.easy => 5,
            Difficulty.medium => 10,
            Difficulty.hard => 15,
          };
    // Keep the displayed session honest when a tier has a short content pool.
    final sessionItems = isFlashcards || isTapDiscovery
        ? items.take(requestedCount).toList(growable: false)
        : items;
    final item = sessionItems[card % sessionItems.length];
    final finishThreshold = isFlashcards || isTapDiscovery
        ? sessionItems.length
        : (items.length < 3 ? items.length : 3);
    void speak() {
      setState(() => _explored.add(item.id));
      final cue = item.audioFor(s.locale);
      if (cue != null) s.audio.playSequence([cue]);
    }

    final explored = _explored.contains(item.id);
    final picture = Padding(
      padding: EdgeInsets.all(compact ? SegSpace.s1 : SegSpace.s3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape =
              constraints.maxWidth >= 420 &&
              constraints.maxWidth > constraints.maxHeight * 1.25;
          final label = ObjectLabel(item.name(s.locale));
          final object = StagedObject(
            glow: explored ? SegColors.primarySoft : null,
            child: ItemVisual(item),
          );
          if (landscape) {
            return Row(
              children: [
                Expanded(flex: 3, child: object),
                if (s.showLabels)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(child: label),
                    ),
                  ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: object),
              if (s.showLabels) label,
            ],
          );
        },
      ),
    );
    return Scaffold(
      backgroundColor: theme.bg,
      body: SceneBackdrop(
        tint: theme.accent,
        base: theme.bg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(compact ? SegSpace.s3 : SegSpace.s5),
                child: Row(
                  children: [
                    PillButton(
                      semanticsLabel: l10n.gameHoldToLeave,
                      onPressed: back,
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: SegSpace.s5),
                    Expanded(
                      child: Text(
                        s.content.game(widget.gameId).name(s.locale),
                        style: SegText.title,
                      ),
                    ),
                    if (isFlashcards || isTapDiscovery)
                      Text(
                        '${card + 1} / ${sessionItems.length}',
                        key: const ValueKey('explore-card-counter'),
                        style: SegText.body,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(compact ? SegSpace.s3 : SegSpace.s5),
                  child: widget.gameId == 'G55'
                      ? TapDiscovery(
                          key: ValueKey(item.id),
                          label: item.name(s.locale),
                          onTap: speak,
                          reducedMotion: s.reducedMotion,
                          child: picture,
                        )
                      : Semantics(
                          button: true,
                          label: item.name(s.locale),
                          child: PressableObject(
                            onTap: speak,
                            reducedMotion: s.reducedMotion,
                            pivot: Alignment.center,
                            child: picture,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? SegSpace.s3 : SegSpace.s5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SegButton(
                      key: const ValueKey('explore-previous'),
                      label: l10n.gamePrevious,
                      secondary: true,
                      icon: Icons.arrow_back_rounded,
                      onPressed: (isFlashcards || isTapDiscovery) && card == 0
                          ? null
                          : () {
                              s.audio.stop();
                              setState(
                                () => card = isFlashcards || isTapDiscovery
                                    ? card - 1
                                    : (card - 1) % sessionItems.length,
                              );
                            },
                    ),
                    SegButton(
                      key: const ValueKey('explore-finish'),
                      label: l10n.gameFinish,
                      icon: Icons.check_rounded,
                      onPressed: _explored.length >= finishThreshold
                          ? () async {
                              s.audio.stop();
                              await _finishSession(true);
                              if (mounted) {
                                setState(() => _exploreComplete = true);
                              }
                            }
                          : null,
                    ),
                    SegButton(
                      key: const ValueKey('explore-next'),
                      label: l10n.gameNext,
                      icon: Icons.arrow_forward_rounded,
                      onPressed:
                          (isFlashcards || isTapDiscovery) &&
                              card >= sessionItems.length - 1
                          ? null
                          : () {
                              s.audio.stop();
                              setState(() => card++);
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A star that pops in once (no loop), as a sticker with a white rim.
class _PoppingStar extends StatelessWidget {
  final Duration delay;
  final bool animate;
  const _PoppingStar({required this.delay, required this.animate});
  @override
  Widget build(BuildContext context) {
    const star = Icon(
      Icons.star_rounded,
      size: 52,
      color: SegColors.star,
      shadows: [
        Shadow(color: Colors.white, blurRadius: 0, offset: Offset(0, -2)),
        Shadow(color: Colors.white, blurRadius: 0, offset: Offset(2, 0)),
        Shadow(color: Colors.white, blurRadius: 0, offset: Offset(-2, 0)),
        Shadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 2)),
        Shadow(color: Color(0x33AC6B00), blurRadius: 6, offset: Offset(0, 3)),
      ],
    );
    if (!animate || MediaQuery.disableAnimationsOf(context)) return star;
    final total = SegMotion.appear + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) => Transform.scale(
        scale: Curves.easeOutBack.transform(
          ((t - start) / (1 - start)).clamp(0.0, 1.0),
        ),
        child: child,
      ),
      child: star,
    );
  }
}

class _FullCelebrationBurst extends StatefulWidget {
  const _FullCelebrationBurst({super.key});

  @override
  State<_FullCelebrationBurst> createState() => _FullCelebrationBurstState();
}

class _FullCelebrationBurstState extends State<_FullCelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) =>
        CustomPaint(painter: _CelebrationBurstPainter(_controller.value)),
  );
}

class _CelebrationBurstPainter extends CustomPainter {
  final double progress;
  const _CelebrationBurstPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - progress).clamp(0.0, 1.0);
    final radius = 20 + progress * 82;
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [SegColors.primary, SegColors.turquoise, SegColors.star];
    for (var i = 0; i < 10; i++) {
      final angle = (i * 2 * math.pi / 10) - math.pi / 2;
      final point =
          center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade * .85);
      canvas.drawCircle(point, 4 + (i % 2) * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_CelebrationBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
