import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../l10n/scoped_localizations.dart';

Future<bool> showParentGate(BuildContext context, AppState state) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _Gate(state: state),
    ) ??
    false;

class _Gate extends StatefulWidget {
  final AppState state;
  const _Gate({required this.state});
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  final random = Random();
  late int a, b;
  String answer = '', message = '';
  bool forceMath = false;
  bool get usesPin => widget.state.hasParentPin && !forceMath;
  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    a = random.nextInt(6) + 4;
    b = random.nextInt(6) + 4;
    answer = '';
  }

  void input(String key) {
    if (key == '⌫') {
      setState(
        () => answer = answer.isEmpty
            ? ''
            : answer.substring(0, answer.length - 1),
      );
      return;
    }
    if (key == '✓') {
      if (usesPin
          ? widget.state.verifyParentPin(answer)
          : int.tryParse(answer) == a * b) {
        widget.state.unlockFamily();
        Navigator.pop(context, true);
      } else {
        setState(() {
          reset();
          final l10n = scopedLocalizations(context, widget.state.locale);
          message = usesPin
              ? l10n.parentGateWrongPin
              : l10n.parentGateWrongMath;
        });
      }
      return;
    }
    if (answer.length < (usesPin ? 4 : 3)) setState(() => answer += key);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.state.locale);
    final error = Theme.of(context).colorScheme.error;
    final displayText = usesPin
        ? List.generate(4, (int i) => i < answer.length ? '●' : '○').join(' ')
        : '$a × $b = ${answer.isEmpty ? '?' : answer}';
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', '✓'];

    // Lock, title, the question and what was typed, centred as one block.
    Widget info() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: SegColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: SegColors.primaryDeep,
            size: 28,
          ),
        ),
        const SizedBox(height: SegSpace.s3),
        Text(
          l10n.parentGateTitle,
          style: SegText.heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SegSpace.s2),
        Text(
          usesPin ? l10n.parentGateEnterPin : l10n.parentGateContinuePrompt,
          style: SegText.body.copyWith(color: SegColors.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SegSpace.s3),
        Container(
          constraints: const BoxConstraints(minWidth: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: SegSpace.s5,
            vertical: SegSpace.s3,
          ),
          decoration: BoxDecoration(
            color: SegColors.familyCanvas,
            borderRadius: BorderRadius.circular(SegRadius.lg),
            border: Border.all(color: SegColors.line),
          ),
          child: Text(
            displayText,
            style: SegText.title,
            textAlign: TextAlign.center,
          ),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: SegSpace.s2),
          Text(
            message,
            style: SegText.body.copyWith(color: error),
            textAlign: TextAlign.center,
          ),
        ],
        if (usesPin)
          TextButton(
            onPressed: () => setState(() {
              forceMath = true;
              message = '';
              reset();
            }),
            child: Text(l10n.parentGateForgotPin),
          ),
      ],
    );

    // A phone-style 3 × 4 keypad with square keys of one size.
    Widget keypad(double key) {
      const gap = SegSpace.s2;
      Widget button(String k) {
        final confirm = k == '✓';
        return SizedBox.square(
          dimension: key,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              backgroundColor: confirm
                  ? SegColors.primary
                  : SegColors.familyCanvas,
              foregroundColor: confirm ? Colors.white : SegColors.ink,
              side: BorderSide(
                color: confirm ? SegColors.primary : SegColors.line,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SegRadius.md),
              ),
            ),
            onPressed: () => input(k),
            child: FittedBox(
              child: Text(
                k,
                style: SegText.heading.copyWith(
                  color: confirm ? Colors.white : SegColors.ink,
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < 4; r++) ...[
            if (r > 0) const SizedBox(height: gap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  button(keys[r * 3 + c]),
                ],
              ],
            ),
          ],
        ],
      );
    }

    final cancel = TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text(l10n.parentGateCancel),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(SegSpace.s3),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SegRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
        child: LayoutBuilder(
          builder: (context, c) {
            const pad = SegSpace.s4, gap = SegSpace.s2;
            final landscape = c.maxWidth > c.maxHeight;
            if (landscape) {
              // Info on the left, keypad on the right, both centred.
              final key = ((c.maxHeight - pad * 2 - gap * 3) / 4).clamp(
                48.0,
                76.0,
              );
              return Padding(
                padding: const EdgeInsets.all(pad),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: (c.maxWidth - pad * 3) / 2 - key,
                                  child: info(),
                                ),
                              ),
                            ),
                          ),
                          cancel,
                        ],
                      ),
                    ),
                    const SizedBox(width: pad),
                    Expanded(child: Center(child: keypad(key))),
                  ],
                ),
              );
            }
            final key = ((c.maxWidth - pad * 2 - gap * 2) / 3).clamp(
              48.0,
              80.0,
            );
            return Padding(
              padding: const EdgeInsets.all(pad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: c.maxWidth - pad * 2,
                        child: info(),
                      ),
                    ),
                  ),
                  const SizedBox(height: SegSpace.s4),
                  keypad(key),
                  const SizedBox(height: SegSpace.s2),
                  cancel,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
