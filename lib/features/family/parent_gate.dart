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
    final MediaQueryData mq = MediaQuery.of(context);
    final l10n = scopedLocalizations(context, widget.state.locale);
    final bool wide = mq.size.width >= 900;
    final double inset = wide ? 16 : 8;
    final double gap = wide ? 12 : 8;
    final double gapSm = wide ? 8 : 6;
    final TextStyle instruction = SegText.body;
    final TextStyle math = SegText.title;
    final TextStyle err = SegText.body.copyWith(
      color: Theme.of(context).colorScheme.error,
    );
    final String promptText = usesPin
        ? l10n.parentGateEnterPin
        : l10n.parentGateContinuePrompt;
    final String displayText = usesPin
        ? List.generate(4, (int i) => i < answer.length ? '●' : '○').join(' ')
        : '$a × $b = ${answer.isEmpty ? '?' : answer}';
    final List<String> keys = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '⌫',
      '0',
      '✓',
    ];
    return Dialog(
      insetPadding: EdgeInsets.all(inset),
      backgroundColor: Colors.white,
      child: SafeArea(
        child: SizedBox(
          width: double.maxFinite,
          height: double.maxFinite,
          child: LayoutBuilder(
            builder: (BuildContext ctx, BoxConstraints c) {
              final double leftWidth = c.maxWidth * 0.45;
              final double rightWidth = c.maxWidth - leftWidth;
              final double rowGap = gapSm;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: leftWidth,
                    child: Padding(
                      padding: EdgeInsets.all(inset),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l10n.parentGateTitle, style: SegText.heading),
                          SizedBox(height: gap),
                          Text(promptText, style: instruction),
                          SizedBox(height: gapSm),
                          Text(displayText, style: math),
                          if (message.isNotEmpty) ...<Widget>[
                            SizedBox(height: gapSm),
                            Text(message, style: err),
                          ],
                          if (usesPin) ...<Widget>[
                            SizedBox(height: gapSm),
                            TextButton(
                              onPressed: () => setState(() {
                                forceMath = true;
                                message = '';
                                reset();
                              }),
                              child: Text(l10n.parentGateForgotPin),
                            ),
                          ],
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.parentGateCancel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: rightWidth,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: inset,
                        bottom: inset,
                        right: inset,
                        left: gapSm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          for (int r = 0; r < 3; r++) ...<Widget>[
                            if (r > 0) SizedBox(height: rowGap),
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  for (int col = 0; col < 4; col++) ...<Widget>[
                                    if (col > 0) SizedBox(width: gapSm),
                                    Expanded(
                                      child: FilledButton.tonal(
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                          padding: const EdgeInsets.all(8),
                                          visualDensity: VisualDensity.standard,
                                        ),
                                        onPressed: () =>
                                            input(keys[r * 4 + col]),
                                        child: Text(
                                          keys[r * 4 + col],
                                          style: SegText.heading,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
