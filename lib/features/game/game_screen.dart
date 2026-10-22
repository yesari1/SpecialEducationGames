import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
import 'templates/game_template.dart' show praiseCue;
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
  bool _roundEndCelebrated = false;
  RoundController? controller;
  int card = 0;
  final Set<String> _explored = {};
  int? _autoSpokenCard;
  bool _exploreComplete = false;
  bool allowed = false;
  Timer? endTimer;

  /// Bumped per round-end celebration so a late "audio finished" from an
  /// earlier one never schedules the return.
  int _celebration = 0;
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
    final band = AgeBand.of(survey);
    controller = RoundController(
      content: s.content,
      themeId: widget.themeId,
      gameId: widget.gameId,
      locale: s.locale,
      difficulty: effectiveDifficulty,
      // Five rounds by default (Yunus, 22 October 2026); a short attention
      // span keeps three. The family can choose another length.
      total: s.roundLength > 0
          ? s.roundLength
          : survey['focus'] == 0
          ? 3
          : 5,
      band: band,
      hintSeconds: s.hintSeconds,
      fadeWrongChoices: s.fadeWrongChoices,
      fadeAfterErrors: s.configuration.fadeAfterErrors,
      choiceCount:
          band?.choices(effectiveDifficulty) ??
          s.configuration.choicesFor(effectiveDifficulty),
      struggle: s.struggle,
      performance: s.itemPerformance,
      introduced: s.introduced,
      introduceNewItems:
          s.introduction && SurveyMapper.map(survey).introduction,
      // After tapping a newly introduced item, say its name before moving on.
      onIntroduced: (id) async {
        final item = s.content.items.where((x) => x.id == id).firstOrNull;
        if (item?.audioFor(s.locale) case final String cue) {
          await s.audio.playSequence([cue]);
        }
        await s.markIntroduced(id);
      },
      playRetry: () => s.audio.playSequence([
        'assets/audio/${s.locale}/prompts/retry_selected.mp3',
      ]),
      playPrompt: playPrompt,
      replayPrompt: (spec) => playPrompt(spec, interrupt: false),
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

  /// [interrupt] false (replay button, idle hint) leaves narration that is
  /// still playing alone instead of starting it again.
  Future<void> playPrompt(RoundSpec spec, {bool interrupt = true}) async {
    final cues = spec.introduction
        ? [?spec.target.audioFor(s.locale)]
        : controller!.template.introCues(
            spec,
            controller!.modeContext,
            s.locale,
          );
    await (interrupt
        ? s.audio.playSequence(cues)
        : s.audio.playSequenceIfIdle(cues));
  }

  void changed() {
    if (!mounted || _limitReached) return;
    setState(() {});
    if (controller!.phase == RoundPhase.complete) {
      unawaited(_finishSession(true));
      // Fallback; with sound the return is rescheduled once the applause
      // and praise have finished (see [_completed]).
      endTimer ??= Timer(Duration(seconds: s.sound ? 15 : 7), () {
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
    if (exploratory) return _exploreComplete ? _completed(3) : _explore(theme);
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
                            onPressed: () => playPrompt(spec, interrupt: false),
                            icon: const Icon(Icons.volume_up_rounded),
                            tooltip: l10n.gameListenAgain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    // Group and basket games give the baskets more room.
                    flex: spec.groupMembers.isNotEmpty && !compact
                        ? 3
                        : sideBySidePrompt && compact
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
                                        SequenceRow(
                                          sequence: spec.sequence,
                                          answer: spec.target.slug,
                                          revealed:
                                              c.phase == RoundPhase.celebrating,
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
                    flex: spec.groupMembers.isNotEmpty && !compact
                        ? 8
                        : sideBySidePrompt && compact
                        ? 7
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

  /// Round end: one calm, happy page. Stars pop in, a few stars drift down
  /// (fewer for "simple", none for "off" or reduced motion), a soft applause
  /// and a varied spoken praise play once.
  Widget _completed(int stars) {
    if (!_roundEndCelebrated) {
      _roundEndCelebrated = true;
      final token = ++_celebration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !s.sound) return;
        s.audio
            .playSequence([
              if (s.celebration != 'off') 'assets/sfx/ui/applause.mp3',
              praiseCue(s.locale),
            ])
            .whenComplete(() {
              // Stay a few seconds after the praise before going back.
              if (!mounted || token != _celebration || endTimer == null) {
                return;
              }
              endTimer!.cancel();
              endTimer = Timer(_afterPraise, () {
                if (mounted) back();
              });
            });
      });
    }
    final theme = s.content.theme(widget.themeId);
    final reduced = s.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final particles = reduced || s.celebration == 'off'
        ? 0
        : s.celebration == 'full'
        ? 140
        : 70;
    final compact = MediaQuery.sizeOf(context).height < 500;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SceneBackdrop(
        tint: theme.accent,
        base: theme.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (particles > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(child: _Confetti(count: particles)),
                ),
              ),
            SafeArea(
              child: Center(
                // Everything on one page; very large text scales down to
                // fit instead of scrolling.
                child: FittedBox(
                  key: const ValueKey('completion-summary'),
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(SegSpace.s4),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.max(
                          320,
                          math.min(900, MediaQuery.sizeOf(context).width - 32),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (stars > 0)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              children: List.generate(
                                stars,
                                (i) => _PoppingStar(
                                  delay: Duration(milliseconds: 160 * i),
                                  animate: !reduced,
                                  size: compact ? 56 : 72,
                                ),
                              ),
                            ),
                          SizedBox(height: compact ? SegSpace.s2 : SegSpace.s4),
                          Text(
                            l10n.gameWellDone,
                            textAlign: TextAlign.center,
                            style: SegText.display.copyWith(
                              color: SegColors.ink,
                              fontSize: compact ? 36 : 44,
                            ),
                          ),
                          const SizedBox(height: SegSpace.s2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (s.hasTodaySticker) ...[
                                DaySticker(
                                  day: DateTime.now()
                                      .toIso8601String()
                                      .substring(0, 10),
                                  size: 44,
                                ),
                                const SizedBox(width: SegSpace.s2),
                              ],
                              Flexible(
                                child: Text(
                                  s.hasTodaySticker
                                      ? l10n.gameYouEarnedTodaysSticker
                                      : l10n.gameWeExploredTogether,
                                  textAlign: TextAlign.center,
                                  style: SegText.body,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? SegSpace.s4 : SegSpace.s6),
                          _completionActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Back to the theme" is the main way on; playing again is optional.
  Widget _completionActions() => Wrap(
    alignment: WrapAlignment.center,
    spacing: SegSpace.s3,
    runSpacing: SegSpace.s3,
    children: [
      SegButton(
        key: const ValueKey('completion-theme'),
        label: l10n.gameBackToTheme,
        icon: Icons.arrow_forward_rounded,
        onPressed: back,
      ),
      SegButton(
        key: const ValueKey('completion-path'),
        label: l10n.gameTodaysPath,
        icon: Icons.route_rounded,
        secondary: true,
        onPressed: () => context.go('/?path=true'),
      ),
      SegButton(
        key: const ValueKey('completion-again'),
        label: l10n.gameAgain,
        icon: Icons.replay_rounded,
        secondary: true,
        onPressed: () {
          endTimer?.cancel();
          endTimer = null;
          _celebration++;
          _sessionId = null;
          _sessionFinished = false;
          _sessionClock.reset();
          _lastChargedMs = 0;
          _explored.clear();
          _exploreComplete = false;
          _autoSpokenCard = null;
          _roundEndCelebrated = false;
          if (widget.gameId == 'G02' || widget.gameId == 'G55') card = 0;
          _startSession();
          if (controller case final c?) {
            c.stage = 0;
            c.start();
          }
          setState(() {});
        },
      ),
    ],
  );

  /// The prompt object. In drag games it can be carried onto a choice; the
  /// choices still accept taps, so dragging is never required.
  Widget _stimulus(RoundSpec spec, RoundController c) {
    // Its place on screen is where a sorted item hops from.
    final visual = HopOriginMarker(
      child: StagedObject(
        child: ItemVisual(spec.stimulus!, alignment: Alignment.bottomCenter),
      ),
    );
    // Once sorted, the item lives in its group (it hops in there). Its
    // place stays reserved so nothing on the page shifts while it flies.
    if (spec.groupMembers.isNotEmpty && c.phase == RoundPhase.celebrating) {
      return IgnorePointer(child: Opacity(opacity: 0, child: visual));
    }
    if (!spec.dragStimulus || c.phase != RoundPhase.answering) return visual;
    return Draggable<ContentItem>(
      data: spec.stimulus,
      onDragStarted: () => c.noteInteraction(itemId: spec.stimulus!.id),
      // The object is centred under the finger, so where it looks dropped is
      // where the drop is tested.
      dragAnchorStrategy: pointerDragAnchorStrategy,
      // Dropped on a basket: the hop starts where the finger let go.
      // The feedback is centred under the finger (offset -66).
      onDragEnd: (details) => HopOrigin.dropped =
          (details.offset - const Offset(66, 66)) & const Size(132, 132),
      feedback: Transform.translate(
        offset: const Offset(-66, -66),
        child: SizedBox.square(
          dimension: 132,
          child: Material(
            type: MaterialType.transparency,
            child: ItemVisual(spec.stimulus!),
          ),
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

    // Each card says its name once when it appears; that counts as seen,
    // so reaching the last card means every card was presented.
    if (_autoSpokenCard != card) {
      _autoSpokenCard = card;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _autoSpokenCard == card && !_exploreComplete) speak();
      });
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
                    // On the last card "Next" turns into "Finish".
                    if ((isFlashcards || isTapDiscovery) &&
                        card >= sessionItems.length - 1)
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
                      )
                    else
                      SegButton(
                        key: const ValueKey('explore-next'),
                        label: l10n.gameNext,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
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
  final double size;
  const _PoppingStar({
    required this.delay,
    required this.animate,
    this.size = 52,
  });
  @override
  Widget build(BuildContext context) {
    final star = Icon(
      Icons.star_rounded,
      size: size,
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

/// How long the round-end page stays after the spoken praise.
const _afterPraise = Duration(milliseconds: 5500);

/// Paper confetti that keeps falling and fluttering for as long as the
/// round-end page is shown (each piece starts again from the top).
class _Confetti extends StatefulWidget {
  final int count;
  const _Confetti({required this.count});
  @override
  State<_Confetti> createState() => _ConfettiState();
}

typedef _Piece = ({
  double x,
  double delay,
  double width,
  double fall,
  double sway,
  double spin,
  Color color,
});

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _seconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _seconds = elapsed.inMicroseconds / 1e6);
      // The page is gone well before this; never animate forever.
      if (_seconds > 14) _ticker.stop();
    })..start();
  }

  late final List<_Piece> _pieces = () {
    final random = math.Random(42);
    return [
      for (var i = 0; i < widget.count; i++)
        (
          x: random.nextDouble(),
          delay: random.nextDouble() * .45,
          width: 9 + random.nextDouble() * 7,
          fall: .75 + random.nextDouble() * .5,
          sway: random.nextDouble() * 2 * math.pi,
          spin: (random.nextBool() ? 1 : -1) * (2 + random.nextDouble() * 4),
          color: const [
            SegColors.star,
            SegColors.turquoise,
            SegColors.accent,
            SegColors.primary,
            Color(0xFFE76F8E),
            Color(0xFF7C73DF),
          ][i % 6],
        ),
    ];
  }();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ConfettiPainter(_seconds, _pieces));
}

class _ConfettiPainter extends CustomPainter {
  /// Seconds since the page opened.
  final double t;
  final List<_Piece> pieces;
  const _ConfettiPainter(this.t, this.pieces);

  /// One fall from the top to the bottom takes about this long.
  static const _fall = 3.4;
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final start = p.delay * _fall * 2;
      if (t < start) continue;
      final local = ((t - start) / (_fall / p.fall)) % 1.0;
      final y = -24 + local * p.fall * (size.height + 48);
      final x = p.x * size.width + math.sin(local * 7 + p.sway) * 26;
      final fade = local < .9 ? 1.0 : (1 - local) / .1;
      // A paper rectangle that turns while it falls: the width follows a
      // cosine so it flips like a real piece of paper.
      final flip = math.cos(local * 9 + p.sway).abs().clamp(.15, 1.0);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(local * p.spin + p.sway);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.width * flip,
        height: p.width * .55,
      );
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
          Paint()..color = p.color.withValues(alpha: .9 * fade),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// "5  6  7  ?": the numbers are big, the gap is a small dashed box; on a
/// right answer the chosen number grows into the gap so the whole row reads.
class SequenceRow extends StatelessWidget {
  final List<String> sequence;
  final String answer;
  final bool revealed;
  const SequenceRow({
    super.key,
    required this.sequence,
    required this.answer,
    required this.revealed,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final size = SegText.display.fontSize ?? 40;
    Widget gap() => Container(
      key: const ValueKey('sequence-gap'),
      width: size * 1.1,
      height: size * 1.1,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(SegRadius.md),
        border: Border.all(
          color: SegColors.primary.withValues(alpha: .45),
          width: 2,
        ),
      ),
      child: Text(
        '?',
        style: SegText.heading.copyWith(color: SegColors.primary),
      ),
    );
    Widget filled() => TweenAnimationBuilder<double>(
      key: const ValueKey('sequence-answer'),
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: .4 + .8 * t - .2 * t * t, child: child),
      child: Text(
        answer,
        style: SegText.display.copyWith(
          color: SegColors.accentDeep,
          fontSize: size * 1.25,
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < sequence.length; i++) ...[
          if (i > 0) SizedBox(width: size * .45),
          if (sequence[i] == '?')
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: revealed ? filled() : gap(),
            )
          else
            Text(sequence[i], style: SegText.display),
        ],
      ],
    );
  }
}
