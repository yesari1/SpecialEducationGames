import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/ui/components.dart';

void main() {
  testWidgets('back and Family act on a single tap', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PillButton(
            semanticsLabel: 'Family',
            onPressed: () => pressed++,
            child: const Text('Family'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Family'));
    await tester.pump();
    expect(pressed, 1);
    final semantics = tester.getSemantics(find.byType(PillButton));
    expect(semantics.label, 'Family');
    expect(
      tester.getSize(find.byType(PillButton)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
