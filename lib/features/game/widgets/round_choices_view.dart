import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/choice_card.dart';
import '../../../app/ui/components.dart';
import '../../../core/content/content_repository.dart';
import '../../../l10n/scoped_localizations.dart';
import '../round_spec.dart';

class RoundCallbacks {
  final void Function(ContentItem item) onSelect;

  /// Plays a choice's sound without answering (sound-choice games).
  final void Function(ContentItem item)? onListen;

  /// Speaks clips during a round (scene games talk between their steps).
  final void Function(List<String> clips)? onSay;
  const RoundCallbacks({required this.onSelect, this.onListen, this.onSay});
}

class HintViewState {
  final int level, visibleChoices, wrongCount, generation;
  final bool celebrating, showLabels, animate;
  final String locale;
  const HintViewState({
    required this.level,
    required this.visibleChoices,
    required this.wrongCount,
    required this.generation,
    required this.celebrating,
    required this.showLabels,
    required this.animate,
    required this.locale,
  });
}

class RoundChoicesView extends StatefulWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  const RoundChoicesView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
  });
  @override
  State<RoundChoicesView> createState() => _RoundChoicesViewState();
}

class _RoundChoicesViewState extends State<RoundChoicesView> {
  final PageController _pager = PageController();
  int _page = 0;
  String? _lastPicked, _shakeFor;
  int _shakeSerial = 0;

  bool _needsPager(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 500;
    return compact &&
        // Groups and baskets always stand in one row; there are at most three.
        widget.spec.groupMembers.isEmpty &&
        widget.spec.stimulus != null &&
        widget.spec.count == null &&
        widget.spec.quantities.isEmpty &&
        // Shadows are small flat shapes: they all fit in one row, and the
        // right one must never wait on a second page (Yunus, 8 Nov 2026).
        widget.spec.look != ChoiceLook.silhouette &&
        !widget.spec.oneRow &&
        // Colour and shape cards are small drawings that also fit in a row.
        !widget.spec.choices.every(
          (x) => x.theme == 'colors' || x.theme == 'shapes',
        ) &&
        widget.spec.choices.length > 2;
  }

  int get _pageCount => (widget.spec.choices.length + 1) ~/ 2;
  int get _currentPage =>
      _pager.hasClients ? (_pager.page?.round() ?? _page) : _page;

  @override
  void didUpdateWidget(RoundChoicesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hint.generation != widget.hint.generation) {
      _lastPicked = null;
      _shakeFor = null;
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pager.hasClients) _pager.jumpToPage(0);
      });
    } else {
      if (widget.hint.wrongCount > oldWidget.hint.wrongCount &&
          _lastPicked != null) {
        _shakeFor = _lastPicked;
        _shakeSerial++;
      }
      if (oldWidget.hint.level < 3 && widget.hint.level >= 3) {
        final targetIndex = widget.spec.choices.indexWhere(
          (item) => item.id == widget.spec.target.id,
        );
        if (targetIndex >= 0) _schedulePage(targetIndex ~/ 2);
      }
    }
  }

  void _schedulePage(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pager.hasClients && page != _page) {
        _goToPage(page);
      }
    });
  }

  void _goToPage(int page) {
    final target = page.clamp(0, _pageCount - 1).toInt();
    if (!_pager.hasClients || target == _currentPage) return;
    if (MediaQuery.disableAnimationsOf(context) || !widget.hint.animate) {
      _pager.jumpToPage(target);
    } else {
      _pager.animateToPage(
        target,
        duration: SegMotion.pageSlide,
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _choiceCard(int index, double width, double height, bool compact) {
    final item = widget.spec.choices[index];
    final correct = item.id == widget.spec.target.id;
    final state = widget.hint.celebrating
        ? (correct ? ChoiceCardState.correct : ChoiceCardState.dismissed)
        : widget.hint.level == 4 && !correct
        ? ChoiceCardState.faded
        : widget.hint.level >= 2 && correct
        ? ChoiceCardState.hint
        : ChoiceCardState.idle;
    void pick() {
      _lastPicked = item.id;
      widget.callbacks.onSelect(item);
    }

    final look = widget.spec.look;
    final members = widget.spec.groupMembers[item.id] ?? const [];
    // The group's members; after a correct answer the sorted item hops in.
    Widget groupVisual() => Stack(
      fit: StackFit.expand,
      children: [
        GroupCluster(members),
        if (correct && widget.hint.celebrating && widget.spec.stimulus != null)
          HopIn(
            animate: widget.hint.animate,
            fromOrigin: true,
            child: FractionallySizedBox(
              alignment: Alignment.topCenter,
              widthFactor: .7,
              heightFactor: .7,
              child: ItemVisual(widget.spec.stimulus!),
            ),
          ),
      ],
    );
    final card = ChoiceCard(
      key: ValueKey('${widget.hint.generation}:${item.id}'),
      item: item,
      locale: widget.hint.locale,
      state: state,
      hintLevel: correct ? widget.hint.level : 0,
      nudgeSerial: correct ? widget.hint.wrongCount : 0,
      shakeSerial: _shakeFor == item.id ? _shakeSerial : 0,
      appearDelay: SegMotion.stagger * (index % 4),
      // Names under shadows would turn the game into a reading task.
      showLabel:
          widget.hint.showLabels &&
          widget.spec.quantities.isEmpty &&
          look != ChoiceLook.silhouette &&
          look != ChoiceLook.sound,
      visual: look == ChoiceLook.silhouette
          ? ItemVisual(
              item,
              alignment: Alignment.bottomCenter,
              silhouette: true,
            )
          : look == ChoiceLook.sound
          ? SoundChoiceVisual(
              index: index,
              onListen: widget.callbacks.onListen == null
                  ? null
                  : () => widget.callbacks.onListen!(item),
              listenLabel: scopedLocalizations(
                context,
                widget.hint.locale,
              ).gameListenToSound,
            )
          : look == ChoiceLook.basket && spec.plainTargets
          ? groupVisual()
          : look == ChoiceLook.basket
          ? BasketFrame(tint: SegColors.accent, child: groupVisual())
          : members.isNotEmpty
          ? groupVisual()
          : widget.spec.quantities.containsKey(item.id)
          ? QuantityVisual(
              count: widget.spec.quantities[item.id]!,
              item: widget.spec.quantityItem,
            )
          : item.id == widget.spec.target.id &&
                widget.spec.correctChoiceImagePath != null
          ? PhotoVisual(
              widget.spec.correctChoiceImagePath!,
              alignment: Alignment.bottomCenter,
            )
          : null,
      compact: compact,
      visible: index < widget.hint.visibleChoices,
      animate: widget.hint.animate,
      onTap: widget.hint.celebrating ? null : pick,
    );
    return SizedBox(
      width: width,
      height: height,
      child: !widget.spec.dragStimulus
          ? card
          // The prompt object can be dropped here; tapping still answers.
          : DragTarget<ContentItem>(
              onWillAcceptWithDetails: (_) => !widget.hint.celebrating,
              onAcceptWithDetails: (_) => pick(),
              builder: (context, candidates, _) => AnimatedScale(
                duration: SegMotion.tap,
                scale: candidates.isEmpty ? 1 : 1.06,
                child: card,
              ),
            ),
    );
  }

  Widget _pageButton({required bool previous, required bool enabled}) {
    final localizations = MaterialLocalizations.of(context);
    final label = previous
        ? localizations.previousPageTooltip
        : localizations.nextPageTooltip;
    final currentPage = _currentPage;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        key: ValueKey(previous ? 'choices-previous' : 'choices-next'),
        onPressed: enabled
            ? () => _goToPage(currentPage + (previous ? -1 : 1))
            : null,
        tooltip: label,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: Icon(
          previous ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          size: 32,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 500;
    final spec = widget.spec;
    return LayoutBuilder(
      builder: (context, size) {
        if (_needsPager(context)) {
          final spacing = SegSpace.s2;
          final allowPaging = !widget.hint.celebrating;
          return Row(
            children: [
              _pageButton(
                previous: true,
                enabled: allowPaging && _currentPage > 0,
              ),
              Expanded(
                child: PageView.builder(
                  key: ValueKey('choice-pages-${widget.hint.generation}'),
                  controller: _pager,
                  physics: allowPaging
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  itemCount: _pageCount,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, page) => LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - spacing) / 2;
                      final first = page * 2;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _choiceCard(first, width, size.maxHeight, compact),
                          SizedBox(width: spacing),
                          if (first + 1 < spec.choices.length)
                            _choiceCard(
                              first + 1,
                              width,
                              size.maxHeight,
                              compact,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              _pageButton(
                previous: false,
                enabled: allowPaging && _currentPage < _pageCount - 1,
              ),
            ],
          );
        }

        final cols =
            spec.choices.length > 2 &&
                size.maxWidth < 600 &&
                spec.groupMembers.isEmpty &&
                !spec.oneRow
            ? 2
            : spec.choices.length;
        final width = (size.maxWidth - SegSpace.s5 * (cols - 1)) / cols;
        final rows = (spec.choices.length / cols).ceil();
        final height = (size.maxHeight - SegSpace.s5 * (rows - 1)) / rows;
        return Wrap(
          spacing: SegSpace.s5,
          runSpacing: SegSpace.s5,
          alignment: WrapAlignment.center,
          children: [
            for (var index = 0; index < spec.choices.length; index++)
              _choiceCard(index, width, height, compact),
          ],
        );
      },
    );
  }
}

class QuantityVisual extends StatelessWidget {
  final int count;
  final ContentItem? item;
  const QuantityVisual({super.key, required this.count, this.item});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // As large as the card allows: the most square grid for the count.
      var best = 0.0, columns = 1;
      for (var c = 1; c <= count; c++) {
        final rows = (count / c).ceil();
        final side = math.min(box.maxWidth / c, box.maxHeight / rows);
        if (side > best) {
          best = side;
          columns = c;
        }
      }
      final side = best * .86;
      // Stand on the card's ground shadow, like single objects.
      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: side * columns + 1,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox.square(
                  dimension: side,
                  child: Padding(
                    padding: EdgeInsets.all(side * .04),
                    child: item == null
                        ? const CustomPaint(
                            painter: ColorBlobPainter(SegColors.accent),
                          )
                        : ItemVisual(item!),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// A sound answer: a coloured wave badge with its own listen button. Tapping
/// the listen button only plays; tapping the rest of the card answers.
class SoundChoiceVisual extends StatelessWidget {
  final int index;
  final VoidCallback? onListen;
  final String listenLabel;
  const SoundChoiceVisual({
    super.key,
    required this.index,
    required this.onListen,
    required this.listenLabel,
  });
  static const _tints = [
    SegColors.turquoise,
    SegColors.accent,
    SegColors.primary,
    Color(0xFF7C73DF),
  ];
  @override
  Widget build(BuildContext context) {
    final tint = _tints[index % _tints.length];
    return LayoutBuilder(
      builder: (context, box) {
        final side = (box.biggest.shortestSide * .9).clamp(48.0, 180.0);
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(Colors.white, tint, .18),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: tint,
                      size: side * .5,
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Material(
                    color: tint,
                    shape: const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 3),
                    ),
                    child: IconButton(
                      key: ValueKey('listen-$index'),
                      tooltip: listenLabel,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      color: Colors.white,
                      onPressed: onListen,
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
