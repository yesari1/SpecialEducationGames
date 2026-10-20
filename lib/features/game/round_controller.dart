import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/content/content_repository.dart';
import '../../core/learning/policies.dart';
import '../../core/learning/item_performance.dart';
import 'hint_controller.dart';
import 'round_spec.dart';
import 'templates/game_template.dart';
export 'round_spec.dart';

enum RoundPhase { preparing, answering, celebrating, complete }

class RoundController extends ChangeNotifier {
  final ContentRepository content;
  final String themeId, gameId;
  final String locale;
  final Difficulty difficulty;
  final ItemScheduler scheduler;
  final Map<String, int> struggle;
  final Map<String, ItemPerformance> performance;
  final Future<void> Function(RoundController) saveTrial;
  final Future<void> Function(RoundSpec) playPrompt;
  final Future<void> Function(String itemId)? onIntroduced;
  final Future<void> Function()? playRetry;
  final bool introduceNewItems;
  final int hintSeconds;

  /// Captured at round creation; remote refreshes never mutate active support.
  final int fadeAfterErrors;
  final int choiceCount;
  final bool fadeWrongChoices;
  final Set<String> introduced;
  final int total;
  RoundSpec? spec, _answerSpec;
  RoundPhase phase = RoundPhase.preparing;
  int stage = 0,
      wrongCount = 0,
      generation = 0,
      visibleChoices = 0,
      firstLatency = 0,
      idleMs = 0;
  final selected = <String>[];
  DateTime? startedAt;
  final Stopwatch _responseClock;
  int _lastInteractionMs = 0;
  final List<Timer> _pending = [];
  final List<VoidCallback> _deferred = [];
  bool _disposed = false, paused = false;
  bool _hasInteraction = false;
  String? error;
  late final HintController hints = HintController(
    onChanged: (level) {
      if (_disposed) return;
      if (level == 1 && spec != null) unawaited(playPrompt(spec!));
      notifyListeners();
    },
  );
  int get hint => hints.level;
  int get maxHint => hints.maximum;
  int get activeMs => _responseClock.elapsedMilliseconds;
  RoundController({
    required this.content,
    required this.themeId,
    required this.gameId,
    this.locale = 'tr',
    required this.difficulty,
    required this.struggle,
    required this.saveTrial,
    required this.playPrompt,
    Map<String, ItemPerformance>? performance,
    this.onIntroduced,
    this.playRetry,
    this.introduceNewItems = false,
    this.hintSeconds = -1,
    this.fadeWrongChoices = true,
    this.fadeAfterErrors = 2,
    int? choiceCount,
    Set<String>? introduced,
    int? total,
    ItemScheduler? scheduler,
    Stopwatch? responseClock,
  }) : choiceCount = (choiceCount ?? difficulty.choices).clamp(2, 4),
       introduced = {...?introduced},
       performance = Map.of(performance ?? {}),
       _responseClock = responseClock ?? Stopwatch(),
       total = total ?? difficulty.stages,
       scheduler = scheduler ?? ItemScheduler();
  GameTemplate get template => TemplateRegistry.resolve(gameId);
  ModeContext get modeContext => ModeContext(
    content: content,
    themeId: themeId,
    gameId: gameId,
    locale: locale,
    difficulty: difficulty,
    choiceCount: choiceCount,
    scheduler: scheduler,
    struggle: struggle,
  );
  void later(Duration delay, VoidCallback action) {
    final session = generation;
    _pending.add(
      Timer(delay, () {
        if (!_disposed && session == generation) {
          if (paused) {
            _deferred.add(() {
              if (!_disposed && session == generation) action();
            });
          } else {
            action();
          }
        }
      }),
    );
  }

  void _cancel() {
    generation++;
    hints.stop();
    _responseClock.stop();
    for (final timer in _pending) {
      timer.cancel();
    }
    _pending.clear();
    _deferred.clear();
  }

  void start({RoundSpec? repeat}) {
    _cancel();
    error = null;
    wrongCount = 0;
    firstLatency = 0;
    idleMs = 0;
    _lastInteractionMs = 0;
    _hasInteraction = false;
    _responseClock.reset();
    hints.reset();
    selected.clear();
    visibleChoices = 0;
    phase = RoundPhase.preparing;
    try {
      final built = repeat ?? template.buildRound(modeContext);
      final state = performance[built.target.id] ?? const ItemPerformance();
      // Odd-one-out is meaningless with fewer than three objects.
      final minimum = template is OddOneOutTemplate ? 3 : 1;
      final count = repeat == null
          ? state
                .fieldSize(built.choices.length)
                .clamp(minimum, built.choices.length)
          : built.choices.length;
      final others = built.choices
          .where((x) => x.id != built.target.id)
          .take(count - 1)
          .toList();
      final choices = [built.target, ...others]..shuffle(scheduler.random);
      _answerSpec = built.withChoices(choices);
      spec =
          introduceNewItems &&
              ['G01', 'G34'].contains(gameId) &&
              !introduced.contains(built.target.id)
          ? _answerSpec!.asIntroduction()
          : _answerSpec;
    } catch (_) {
      error = 'content_missing';
      notifyListeners();
      return;
    }
    notifyListeners();
    final session = generation;
    unawaited(
      playPrompt(spec!).whenComplete(() {
        if (!_disposed && session == generation) _showChoices();
      }),
    );
  }

  void _showChoices() {
    phase = RoundPhase.answering;
    startedAt = DateTime.now();
    if (!paused) _responseClock.start();
    for (var i = 0; i < spec!.choices.length; i++) {
      later(Duration(milliseconds: i * 150), () {
        visibleChoices = i + 1;
        notifyListeners();
      });
    }
    final state = performance[spec!.target.id] ?? const ItemPerformance();
    hints.start(
      initialDelay: hintSeconds == 0
          ? null
          : hintSeconds > 0
          ? Duration(seconds: hintSeconds)
          : state.hintDelay(difficulty),
      elapsedMs: () => activeMs - _lastInteractionMs,
      paused: () => paused || phase != RoundPhase.answering,
    );
    notifyListeners();
  }

  void pause() {
    paused = true;
    _responseClock.stop();
  }

  void resume() {
    paused = false;
    if (phase == RoundPhase.answering) _responseClock.start();
    final actions = List<VoidCallback>.of(_deferred);
    _deferred.clear();
    for (final action in actions) {
      action();
    }
  }

  void noteInteraction({String? itemId}) {
    if (paused || phase != RoundPhase.answering) return;
    final elapsed = activeMs;
    idleMs += max(0, elapsed - _lastInteractionMs - 3000);
    _lastInteractionMs = elapsed;
    if (!_hasInteraction) firstLatency = elapsed;
    _hasInteraction = true;
    if (itemId != null) selected.add(itemId);
  }

  Future<void> choose(ContentItem item) async {
    if (paused ||
        phase != RoundPhase.answering ||
        spec == null ||
        !spec!.choices.any((x) => x.id == item.id)) {
      return;
    }
    if (hint == 4 && item.id != spec!.target.id) return;
    noteInteraction(itemId: item.id);
    if (item.id != spec!.target.id) {
      wrongCount++;
      hints.wrong(
        wrongCount,
        fadeWrongChoices: fadeWrongChoices,
        fadeAfterErrors: fadeAfterErrors,
      );
      if (playRetry != null) unawaited(playRetry!());
      return;
    }
    hints.stop();
    _responseClock.stop();
    final answeredSession = generation;
    phase = RoundPhase.celebrating;
    notifyListeners();
    if (spec!.introduction) {
      introduced.add(spec!.target.id);
      await onIntroduced?.call(spec!.target.id);
      if (_disposed || answeredSession != generation) return;
      final answer = _answerSpec!;
      // Never advance faster than the name audio plus a calm pause.
      later(const Duration(milliseconds: 1500), () => start(repeat: answer));
      return;
    }
    await saveTrial(this);
    if (_disposed || answeredSession != generation) return;
    final previous = performance[spec!.target.id] ?? const ItemPerformance();
    performance[spec!.target.id] = ItemPerformance(
      independentStreak: maxHint == 0 && wrongCount == 0
          ? previous.independentStreak + 1
          : 0,
      fullSupportStreak: maxHint == 4 ? previous.fullSupportStreak + 1 : 0,
    );
    later(const Duration(milliseconds: 1500), () {
      stage++;
      if (stage >= total) {
        phase = RoundPhase.complete;
        notifyListeners();
      } else {
        start();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel();
    hints.dispose();
    super.dispose();
  }
}
