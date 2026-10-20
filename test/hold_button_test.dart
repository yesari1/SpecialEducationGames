import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/ui/components.dart';

void main() {
  testWidgets('Two fingers cannot leave a stale parent hold timer', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: HoldButton(
            semanticsLabel: 'Family',
            onHeld: () => opened++,
            child: const Text('Family'),
          ),
        ),
      ),
    );
    final point = tester.getCenter(find.text('Family'));
    final first = await tester.startGesture(point, pointer: 1);
    await tester.pump(const Duration(milliseconds: 100));
    final second = await tester.startGesture(point, pointer: 2);
    await tester.pump(const Duration(milliseconds: 100));
    await first.up();
    await second.up();
    await tester.pump(const Duration(seconds: 3));
    expect(opened, 0);
    final held = await tester.startGesture(point, pointer: 3);
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 1);
    await held.up();
  });

  for (final (label, hint, duration) in const [
    ('Leave', 'Hold to leave', Duration(seconds: 1)),
    ('Family', 'Hold for the family area', Duration(seconds: 2)),
  ]) {
    testWidgets('$label: a short tap shows the hint and a hold fires', (
      tester,
    ) async {
      var fired = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: HoldButton(
              semanticsLabel: label,
              hint: hint,
              duration: duration,
              onHeld: () => fired++,
              child: Text(label),
            ),
          ),
        ),
      );
      expect(find.text(hint), findsNothing);
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 50));
      expect(fired, 0, reason: 'a tap must not trigger');
      expect(find.text(hint), findsOneWidget, reason: 'a tap explains itself');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final hold = await tester.startGesture(
        tester.getCenter(find.text(label)),
      );
      await tester.pump(duration ~/ 2);
      expect(fired, 0);
      await tester.pump(duration);
      expect(fired, 1, reason: 'holding long enough triggers once');
      await hold.up();
      await tester.pumpAndSettle();
      expect(fired, 1);
    });
  }
}
