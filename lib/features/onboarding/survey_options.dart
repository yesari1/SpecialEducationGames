import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/scoped_localizations.dart';
import 'survey_questions.dart';

class SurveyOptions extends StatefulWidget {
  final SurveyQuestion question;
  final String locale;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool reducedMotion;

  const SurveyOptions({
    super.key,
    required this.question,
    required this.locale,
    required this.value,
    required this.onChanged,
    this.reducedMotion = false,
  });

  @override
  State<SurveyOptions> createState() => _SurveyOptionsState();
}

class _SurveyOptionsState extends State<SurveyOptions> {
  late final PageController _controller;
  int _index = 0;

  List<String> get _options => widget.locale == 'tr'
      ? widget.question.trOptions
      : widget.question.enOptions;

  Set<int> get _selected => Set<int>.from(
    widget.value is List
        ? widget.value as List
        : widget.value is int
        ? [widget.value as int]
        : <int>[],
  );

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _options.length) return;
    if (widget.reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(index);
      return;
    }
    _controller.animateToPage(
      index,
      duration: SegMotion.pageSlide,
      curve: Curves.easeOutCubic,
    );
  }

  void _select(int optionIndex) {
    if (!widget.question.multiple) {
      widget.onChanged(optionIndex);
      return;
    }
    final next = _selected;
    if (!next.add(optionIndex)) next.remove(optionIndex);
    widget.onChanged(next.toList()..sort());
  }

  Widget _option(int index, String label) {
    final selected = _selected.contains(index);
    if (!widget.question.multiple) {
      return Semantics(
        key: ValueKey('survey-option-$index'),
        label: label,
        button: true,
        selected: widget.value == index,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(SegRadius.md),
            onTap: () => _select(index),
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(
                horizontal: SegSpace.s4,
                vertical: SegSpace.s2,
              ),
              decoration: BoxDecoration(
                color: selected ? SegColors.primarySoft : SegColors.surface,
                borderRadius: BorderRadius.circular(SegRadius.md),
                border: Border.all(
                  color: selected ? SegColors.primary : SegColors.line,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  if (selected) ...[
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: SegColors.primary,
                    ),
                    const SizedBox(width: SegSpace.s2),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: SegText.item,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      key: ValueKey('survey-option-$index'),
      label: label,
      checked: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SegRadius.md),
          onTap: () => _select(index),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: SegSpace.s4,
              vertical: SegSpace.s2,
            ),
            decoration: BoxDecoration(
              color: selected ? SegColors.primarySoft : SegColors.surface,
              borderRadius: BorderRadius.circular(SegRadius.md),
              border: Border.all(
                color: selected ? SegColors.primary : SegColors.line,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: selected ? SegColors.primary : SegColors.inkSoft,
                  size: 32,
                ),
                const SizedBox(width: SegSpace.s3),
                Expanded(
                  child: Text(
                    label,
                    style: SegText.item,
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final l10n = scopedLocalizations(context, widget.locale);
    // Upright screens have room for every option at once: no arrows.
    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return ListView.separated(
        key: ValueKey('survey-options-${widget.question.key}'),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(height: SegSpace.s2),
        itemBuilder: (context, index) => _option(index, options[index]),
      );
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: ValueKey('survey-options-${widget.question.key}'),
            controller: _controller,
            itemCount: options.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  IconButton(
                    tooltip: l10n.surveyPreviousOption,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth > 960
                              ? 960
                              : double.infinity,
                          maxHeight: constraints.maxHeight,
                        ),
                        child: _option(index, options[index]),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.surveyNextOption,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _index == options.length - 1
                        ? null
                        : () => _goTo(_index + 1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          label: l10n.surveyOptionProgress(_index + 1, options.length),
          liveRegion: true,
          child: Text(
            l10n.surveyOptionCount(_index + 1, options.length),
            style: SegText.caption,
          ),
        ),
      ],
    );
  }
}
