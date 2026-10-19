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
}
