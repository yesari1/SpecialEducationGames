import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/ui/components.dart';

void main() {
  testWidgets('the same notice is shown once, never queued', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      showNotice(ctx, 'Locked');
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Locked'), findsOneWidget);
    // Let the one notice time out: nothing queued behind it.
    for (var i = 0; i < 2; i++) {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    }
    // A different message replaces the current one immediately.
    showNotice(ctx, 'A');
    await tester.pump(const Duration(milliseconds: 100));
    showNotice(ctx, 'B');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });
}
