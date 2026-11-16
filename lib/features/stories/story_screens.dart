import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/scene_backdrop.dart';
import '../../core/content/child_cast.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/content/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';
import '../game/widgets/next_game_button.dart';

/// The colours of the Stories card and screens.
final storiesTheme = ContentTheme.fromJson({
  'id': 'stories',
  'hero': '',
  'name': {'tr': 'Hikâyeler', 'en': 'Stories'},
  'games': <String>[],
  'palette': {'bg': '#FFFEFC', 'accent': '#FF8A32', 'deep': '#BA4C08'},
});

/// A story's picture, or a quiet empty frame if the file is missing (a
/// broken picture must never stop the story).
Widget storyPicture(String asset, {BoxFit fit = BoxFit.contain}) => Image.asset(
  ChildCast.of(asset),
  fit: fit,
  excludeFromSemantics: true,
  errorBuilder: (_, _, _) => const ColoredBox(color: SegColors.surfaceMuted),
);

/// The Stories section of the home screen: the books side by side. Premium
/// ones are black and white with a lock and lead to the same parent notice
/// as a locked game card.
class StoryShelf extends StatelessWidget {
  final AppState state;

  /// Room kept clear under the cards (the home's floating bar).
  final double bottomInset;
  const StoryShelf({super.key, required this.state, this.bottomInset = 0});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final stories = state.content.stories;
    return HorizontalCards(
      count: stories.length,
      bottomInset: bottomInset,
      tight: bottomInset > 0,
      centered: bottomInset > 0,
      cardAspect: bottomInset > 0 ? .95 : null,
      builder: (i) {
        final story = stories[i];
        final locked = !state.canPlayStory(story);
        return ThemeGameCard(
          key: ValueKey('story-card-${story.id}'),
          theme: storiesTheme,
          title: story.titleFor(state.locale),
          subtitle: '',
          visual: storyPicture(story.cover),
          normalizedVisual: true,
          locked: locked,
          tapSound: false,
          onTap: () {
            UiSound.tap();
            if (locked) {
              showLockedGameNotice(
                context,
                title: l10n.lockedGameTitle,
                body: l10n.lockedGameBody,
                ok: l10n.lockedGameOk,
              );
            } else {
              context.go('/story/${story.id}');
            }
          },
        );
      },
    );
  }
}

enum _Phase { page, result, end }

class StoryPlayerScreen extends StatefulWidget {
  final AppState state;
  final Story story;

  /// How long a wrong choice's result stays after its sentence was said.
  final Duration resultPause;

  /// How long the right choice glows before the story goes on.
  final Duration rightPause;

  /// After a page has been read: when the hand hint shows, and when the
  /// story goes on by itself if nobody touched the screen.
  final Duration handDelay, autoAdvance;
  const StoryPlayerScreen({
    super.key,
    required this.state,
    required this.story,
    this.resultPause = const Duration(milliseconds: 1500),
    this.rightPause = const Duration(milliseconds: 900),
    this.handDelay = const Duration(seconds: 5),
    this.autoAdvance = const Duration(seconds: 15),
  });
  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  AppState get s => widget.state;
  Story get story => widget.story;
  int index = 0;
  _Phase phase = _Phase.page;

  /// Wrong choices tried on the current question (shown faded).
  final Set<int> tried = {};

  /// The right choice is glowing; taps wait for the story to go on.
  bool answered = false;
  StoryChoice? shownResult;
  Timer? _timer, _handTimer, _autoTimer;

  /// The hand showing where to tap, after a while with no touch.
  bool showHand = false;

  /// Bumped on every step so a late timer or clip end from an older page
  /// never moves the story.
  int _step = 0;

  StoryPage get page => story.pages[index];
  bool get reduced =>
      s.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    s.enterGame();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPage());
  }

  /// Reads the page; a narration page then waits for the child, shows the
  /// hand after a while and finally goes on by itself.
  void _openPage() {
    final step = _step;
    _say(page.line).whenComplete(() {
      if (!mounted || step != _step || page.isQuestion) return;
      _armIdle(step);
    });
  }

  void _armIdle(int step) {
    _handTimer = Timer(widget.handDelay, () {
      if (mounted && step == _step) setState(() => showHand = true);
    });
    _autoTimer = Timer(widget.autoAdvance, () {
      if (!mounted || step != _step) return;
      // Never turn pages while the app is in the background.
      final life = WidgetsBinding.instance.lifecycleState;
      if (life != null && life != AppLifecycleState.resumed) {
        _armIdle(step);
        return;
      }
      _next(auto: true);
    });
  }

  void _clearIdle() {
    _handTimer?.cancel();
    _autoTimer?.cancel();
    showHand = false;
  }

  @override
  void dispose() {
    _endRing.dispose();
    _timer?.cancel();
    _clearIdle();
    s.leaveGame();
    if (!s.inGame) s.audio.stop();
    super.dispose();
  }

  Future<void> _say(StoryLine? line) async {
    final clip = line?.audioFor(s.locale);
    if (clip == null) return s.audio.stop();
    await s.audio.playSequence([clip]);
  }

  void _show(int next) {
    _timer?.cancel();
    _clearIdle();
    _step++;
    setState(() {
      index = next;
      phase = _Phase.page;
      tried.clear();
      answered = false;
      shownResult = null;
    });
    _openPage();
  }

  void _next({bool auto = false}) {
    if (phase != _Phase.page || answered || page.isQuestion) return;
    if (!auto) UiSound.tap();
    if (index + 1 < story.pages.length) {
      _show(index + 1);
    } else {
      _finish();
    }
  }

  void _goOn() => index + 1 < story.pages.length ? _show(index + 1) : _finish();

  void _finish() {
    _timer?.cancel();
    _clearIdle();
    _step++;
    setState(() => phase = _Phase.end);
    _say(story.praise);
  }

  void _choose(int i) {
    if (phase != _Phase.page || answered || tried.contains(i)) return;
    final choice = page.choices[i];
    final step = ++_step;
    if (choice.correct) {
      UiSound.tap();
      setState(() => answered = true);
      _timer = Timer(widget.rightPause, () {
        if (!mounted || step != _step) return;
        answered = false;
        if (choice.result == null) {
          _goOn();
          return;
        }
        // The chosen picture is shown big and what happens is said.
        setState(() {
          shownResult = choice;
          phase = _Phase.result;
        });
        _sayResult(choice, step, _goOn);
      });
      return;
    }
    // A wrong choice is never scolded: its result is shown calmly, then the
    // question comes back with that picture faded.
    setState(() {
      tried.add(i);
      shownResult = choice.result == null ? null : choice;
      phase = shownResult == null ? _Phase.page : _Phase.result;
    });
    if (shownResult == null) {
      _say(page.retry ?? page.line);
      return;
    }
    _sayResult(choice, step, () {
      setState(() {
        phase = _Phase.page;
        shownResult = null;
      });
      _say(page.retry ?? page.line);
    });
  }

  /// Says a result, leaves it on screen for a moment and then goes [then].
  void _sayResult(StoryChoice choice, int step, VoidCallback then) {
    final started = DateTime.now();
    _say(choice.result).whenComplete(() {
      if (!mounted || step != _step) return;
      // Without sound, give the child time to look at the result.
      final spoken = DateTime.now().difference(started);
      final rest = spoken < const Duration(seconds: 2)
          ? const Duration(seconds: 3) - spoken
          : widget.resultPause;
      _timer = Timer(rest, () {
        if (mounted && step == _step) then();
      });
    });
  }

  void _leave() {
    _timer?.cancel();
    _clearIdle();
    s.audio.stop();
    context.go('/stories');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, s.locale);
    final compact = MediaQuery.sizeOf(context).height < 500;
    final body = switch (phase) {
      _Phase.end => _end(l10n, compact),
      _Phase.result => _result(compact),
      _Phase.page when page.isQuestion => _question(compact),
      _Phase.page => _narration(l10n, compact),
    };
    return Scaffold(
      backgroundColor: SegColors.canvas,
      body: SceneBackdrop(
        tint: storiesTheme.accent,
        clouds: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(compact ? SegSpace.s2 : SegSpace.s4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PillButton(
                      semanticsLabel: l10n.themeBack,
                      onPressed: _leave,
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                    if (phase != _Phase.end) _dots(),
                    if (phase != _Phase.end)
                      _roundButton(
                        key: const ValueKey('story-listen'),
                        icon: Icons.volume_up_rounded,
                        label: l10n.gameListenAgain,
                        onPressed: () => s.audio.playSequenceIfIdle([
                          ?(phase == _Phase.result
                                  ? shownResult!.result
                                  : tried.isEmpty
                                  ? page.line
                                  : page.retry ?? page.line)
                              ?.audioFor(s.locale),
                        ]),
                      )
                    else
                      const SizedBox(width: 64),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduced ? Duration.zero : SegMotion.appear,
                  child: KeyedSubtree(
                    key: ValueKey('$index-${phase.name}'),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dots() => Row(
    key: const ValueKey('story-dots'),
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < story.pages.length; i++)
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i <= index ? SegColors.accent : SegColors.line,
          ),
        ),
    ],
  );

  Widget _sentence(String text, {Key? key, bool compact = false}) => Container(
    key: key,
    padding: EdgeInsets.symmetric(
      horizontal: SegSpace.s5,
      vertical: compact ? SegSpace.s2 : SegSpace.s3,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(SegRadius.md),
      boxShadow: [
        BoxShadow(
          color: SegColors.ink.withValues(alpha: .08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: SegText.heading.copyWith(fontSize: compact ? 20 : 24),
    ),
  );

  Widget _framedPicture(String asset, {Key? key}) => DecoratedBox(
    key: key,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(SegRadius.lg),
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: [
        BoxShadow(
          color: SegColors.ink.withValues(alpha: .10),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(SegRadius.lg - 4),
      child: storyPicture(asset, fit: BoxFit.cover),
    ),
  );

  /// Anywhere on the page goes on: a tap, or a swipe to the left.
  Widget _narration(AppLocalizations l10n, bool compact) => GestureDetector(
    key: const ValueKey('story-page-area'),
    behavior: HitTestBehavior.opaque,
    onTap: _next,
    onHorizontalDragEnd: (d) {
      if ((d.primaryVelocity ?? 0) < -100) _next();
    },
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        _narrationBody(l10n, compact),
        if (showHand)
          Positioned(
            right: SegSpace.s6,
            bottom: compact ? SegSpace.s4 : SegSpace.s5,
            child: IgnorePointer(
              child: _TapHand(
                key: const ValueKey('story-hand'),
                animate: !reduced,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _narrationBody(AppLocalizations l10n, bool compact) => Padding(
    padding: EdgeInsets.fromLTRB(
      SegSpace.s5,
      0,
      SegSpace.s5,
      compact ? SegSpace.s2 : SegSpace.s4,
    ),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: _framedPicture(
                page.image!,
                key: const ValueKey('story-picture'),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? SegSpace.s2 : SegSpace.s3),
        Row(
          children: [
            const SizedBox(width: 72),
            Expanded(
              child: _sentence(
                page.line.textFor(s.locale),
                key: const ValueKey('story-sentence'),
                compact: compact,
              ),
            ),
            const SizedBox(width: SegSpace.s3),
            Semantics(
              button: true,
              label: l10n.storyNext,
              child: GestureDetector(
                key: const ValueKey('story-next'),
                onTap: _next,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: SegColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: SegColors.accentDeep.withValues(alpha: .3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _question(bool compact) {
    final retrying = tried.isNotEmpty;
    final text = (retrying ? page.retry ?? page.line : page.line).textFor(
      s.locale,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SegSpace.s5,
        0,
        SegSpace.s5,
        compact ? SegSpace.s3 : SegSpace.s5,
      ),
      child: Column(
        children: [
          _sentence(
            text,
            key: const ValueKey('story-question'),
            compact: compact,
          ),
          SizedBox(height: compact ? SegSpace.s3 : SegSpace.s5),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (i, choice) in page.choices.indexed) ...[
                  if (i > 0) const SizedBox(width: SegSpace.s6),
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _choiceCard(i, choice, hint: retrying),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceCard(int i, StoryChoice choice, {required bool hint}) {
    final faded = tried.contains(i);
    final glow = answered && choice.correct
        ? SegColors.successGlow
        : hint && choice.correct
        ? SegColors.hintGlow
        : null;
    return Semantics(
      button: true,
      label: choice.labelFor(s.locale),
      child: GestureDetector(
        key: ValueKey('story-choice-$i'),
        onTap: () => _choose(i),
        child: AnimatedOpacity(
          duration: reduced ? Duration.zero : SegMotion.fadeHint,
          opacity: faded ? .35 : 1,
          // No box: the transparent picture stands on the scene like a game
          // choice; a soft round glow behind it marks the hint or the answer.
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: FractionallySizedBox(
                  widthFactor: .82,
                  heightFactor: .82,
                  child: AnimatedContainer(
                    duration: reduced ? Duration.zero : SegMotion.focus,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (glow ?? SegColors.hintGlow).withValues(
                        alpha: glow == null ? 0 : .35,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (glow ?? SegColors.hintGlow).withValues(
                            alpha: glow == null ? 0 : .9,
                          ),
                          blurRadius: 48,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SegSpace.s2),
                child: PhotoVisual(choice.image),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A wrong choice's calm result: its own picture, or the right answer's
  /// picture ("Look, Ali is smiling.").
  Widget _result(bool compact) {
    final choice = shownResult!;
    final image =
        choice.resultImage ?? page.choices.firstWhere((c) => c.correct).image;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SegSpace.s5,
        0,
        SegSpace.s5,
        compact ? SegSpace.s2 : SegSpace.s4,
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: choice.resultImage == null ? 1 : 3 / 2,
                // A scene keeps its frame; a choice picture has no box.
                child: choice.resultImage == null
                    ? PhotoVisual(
                        image,
                        key: const ValueKey('story-result-picture'),
                      )
                    : _framedPicture(
                        image,
                        key: const ValueKey('story-result-picture'),
                      ),
              ),
            ),
          ),
          SizedBox(height: compact ? SegSpace.s2 : SegSpace.s3),
          _sentence(
            choice.result!.textFor(s.locale),
            key: const ValueKey('story-result'),
            compact: compact,
          ),
        ],
      ),
    );
  }

  /// The story's end: its own last picture, the praise ("Ayşe'ye çok güzel
  /// yardım ettin!") and one button whose ring runs round and takes the
  /// child back to the stories (Yunus, 16 November 2026: no star, no logo,
  /// no "again", no round shelf button).
  Widget _end(AppLocalizations l10n, bool compact) {
    final praise = story.praise?.textFor(s.locale) ?? l10n.gameWellDone;
    final picture =
        story.pages.reversed
            .map((p) => p.image)
            .whereType<String>()
            .firstOrNull ??
        story.cover;
    return Padding(
      key: const ValueKey('story-end'),
      padding: EdgeInsets.fromLTRB(
        SegSpace.s5,
        0,
        SegSpace.s5,
        compact ? SegSpace.s2 : SegSpace.s4,
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: _framedPicture(
                  picture,
                  key: const ValueKey('story-end-picture'),
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? SegSpace.s2 : SegSpace.s3),
          _sentence(praise, key: const ValueKey('story-praise')),
          SizedBox(height: compact ? SegSpace.s2 : SegSpace.s3),
          NextGameButton(
            key: const ValueKey('story-shelf'),
            label: l10n.storiesTitle,
            running: _endRing,
            animate: !reduced,
            onNext: _leave,
          ),
        ],
      ),
    );
  }

  final _endRing = ValueNotifier(true);

  Widget _roundButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => DecoratedBox(
    key: key,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: SegColors.line, width: 2),
    ),
    child: IconButton(
      iconSize: 30,
      constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
      color: SegColors.primaryDeep,
      tooltip: label,
      icon: Icon(icon),
      onPressed: onPressed,
    ),
  );
}

/// A soft, see-through hand that taps over the next arrow.
class _TapHand extends StatefulWidget {
  final bool animate;
  const _TapHand({super.key, required this.animate});
  @override
  State<_TapHand> createState() => _TapHandState();
}

class _TapHandState extends State<_TapHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, 10 * _pulse.value),
      child: Transform.scale(scale: 1 - .08 * _pulse.value, child: child),
    ),
    child: Icon(
      Icons.touch_app_rounded,
      size: 72,
      color: SegColors.ink.withValues(alpha: .45),
      shadows: const [Shadow(color: Colors.white, blurRadius: 12)],
    ),
  );
}
