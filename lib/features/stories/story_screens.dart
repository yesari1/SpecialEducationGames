import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/scene_backdrop.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/content/content_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

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
  asset,
  fit: fit,
  excludeFromSemantics: true,
  errorBuilder: (_, _, _) => const ColoredBox(color: SegColors.surfaceMuted),
);

/// The Stories card at the front of the home screen's theme cards.
class StoriesCard extends StatelessWidget {
  final AppState state;
  const StoriesCard({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final stories = state.content.stories;
    return ThemeGameCard(
      key: const ValueKey('stories-card'),
      theme: storiesTheme,
      title: l10n.storiesTitle,
      subtitle: l10n.storiesCount(stories.length),
      visual: storyPicture(stories.first.cover),
      normalizedVisual: true,
      onTap: () => context.go('/stories'),
    );
  }
}

/// The shelf of stories; Premium ones show a lock and lead to the same
/// parent notice as a locked game card.
class StoryShelfScreen extends StatelessWidget {
  final AppState state;
  const StoryShelfScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final stories = state.content.stories;
    return Scaffold(
      backgroundColor: SegColors.canvas,
      body: SceneBackdrop(
        tint: storiesTheme.accent,
        clouds: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegSpace.s5,
                  vertical: SegSpace.s3,
                ),
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
                        l10n.storiesTitle,
                        style: SegText.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: HorizontalCards(
                  count: stories.length,
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
                ),
              ),
            ],
          ),
        ),
      ),
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
  const StoryPlayerScreen({
    super.key,
    required this.state,
    required this.story,
    this.resultPause = const Duration(milliseconds: 1500),
    this.rightPause = const Duration(milliseconds: 900),
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
  Timer? _timer;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _say(page.line));
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    _step++;
    setState(() {
      index = next;
      phase = _Phase.page;
      tried.clear();
      answered = false;
      shownResult = null;
    });
    _say(page.line);
  }

  void _next() {
    if (phase != _Phase.page || answered) return;
    UiSound.tap();
    if (index + 1 < story.pages.length) {
      _show(index + 1);
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
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
        index + 1 < story.pages.length ? _show(index + 1) : _finish();
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
    final started = DateTime.now();
    _say(choice.result).whenComplete(() {
      if (!mounted || step != _step) return;
      // Without sound, give the child time to look at the result.
      final spoken = DateTime.now().difference(started);
      final rest = spoken < const Duration(seconds: 2)
          ? const Duration(seconds: 3) - spoken
          : widget.resultPause;
      _timer = Timer(rest, () {
        if (!mounted || step != _step) return;
        setState(() {
          phase = _Phase.page;
          shownResult = null;
        });
        _say(page.retry ?? page.line);
      });
    });
  }

  void _leave() {
    _timer?.cancel();
    s.audio.stop();
    context.go('/stories');
  }

  void _again() {
    UiSound.tap();
    _show(0);
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

  Widget _narration(AppLocalizations l10n, bool compact) => Padding(
    padding: EdgeInsets.fromLTRB(
      SegSpace.s5,
      0,
      SegSpace.s5,
      compact ? SegSpace.s2 : SegSpace.s4,
    ),
    child: Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _next,
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
          _sentence(text, key: const ValueKey('story-question'), compact: compact),
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
          child: AnimatedContainer(
            duration: reduced ? Duration.zero : SegMotion.focus,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SegRadius.lg),
              border: Border.all(color: glow ?? Colors.white, width: 6),
              boxShadow: [
                BoxShadow(
                  color: (glow ?? SegColors.ink).withValues(
                    alpha: glow == null ? .10 : .9,
                  ),
                  blurRadius: glow == null ? 16 : 22,
                  spreadRadius: glow == null ? 0 : 4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SegRadius.lg - 6),
              child: storyPicture(choice.image),
            ),
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
                child: _framedPicture(
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

  Widget _end(AppLocalizations l10n, bool compact) {
    final celebrate = !reduced && s.celebration != 'off';
    final praise = story.praise?.textFor(s.locale) ?? l10n.gameWellDone;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(SegSpace.s4),
          child: Column(
            key: const ValueKey('story-end'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: celebrate ? 0 : 1, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: compact ? 110 : 140,
                      height: compact ? 110 : 140,
                      decoration: BoxDecoration(
                        color: SegColors.star,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 8),
                        boxShadow: [
                          BoxShadow(
                            color: SegColors.starDeep.withValues(alpha: .3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: compact ? 70 : 90,
                      ),
                    ),
                  ),
                  const SizedBox(width: SegSpace.s6),
                  Image.asset(
                    'assets/illustrations/onboarding/mascot_cloud.png',
                    height: compact ? 110 : 150,
                    excludeFromSemantics: true,
                  ),
                ],
              ),
              SizedBox(height: compact ? SegSpace.s3 : SegSpace.s5),
              _sentence(praise, key: const ValueKey('story-praise')),
              SizedBox(height: compact ? SegSpace.s3 : SegSpace.s5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roundButton(
                    key: const ValueKey('story-again'),
                    icon: Icons.replay_rounded,
                    label: l10n.gameAgain,
                    onPressed: _again,
                  ),
                  const SizedBox(width: SegSpace.s4),
                  _roundButton(
                    key: const ValueKey('story-shelf'),
                    icon: Icons.menu_book_rounded,
                    label: l10n.storiesTitle,
                    onPressed: _leave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
