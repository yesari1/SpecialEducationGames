import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/features/game/widgets/counted_objects.dart';

void main() {
  testWidgets(
    'Counting tracks distinct objects and resets for the next stage',
    (tester) async {
      final counts = <int>[];
      Widget screen(int stage, {bool enabled = true}) => MaterialApp(
        home: Scaffold(
          body: CountedObjects(
            key: ValueKey(stage),
            count: 3,
            locale: 'tr',
            enabled: enabled,
            onCount: counts.add,
          ),
        ),
      );
      await tester.pumpWidget(screen(1));
      expect(
        tester
            .widget<Semantics>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'Nesne, say 1',
              ),
            )
            .properties
            .label,
        'Nesne, say 1',
      );
      await tester.tap(find.byKey(const ValueKey('count-object-2')));
      await tester.tap(find.byKey(const ValueKey('count-object-2')));
      await tester.tap(find.byKey(const ValueKey('count-object-0')));
      expect(counts, [1, 2]);
      await tester.pumpWidget(screen(1, enabled: false));
      await tester.tap(find.byKey(const ValueKey('count-object-1')));
      expect(counts, [1, 2]);
      await tester.pumpWidget(screen(2));
      await tester.tap(find.byKey(const ValueKey('count-object-0')));
      expect(counts, [1, 2, 1]);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          home: Scaffold(
            body: CountedObjects(count: 1, locale: 'en', onCount: counts.add),
          ),
        ),
      );
      expect(
        tester
            .widget<Semantics>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'Object, count 1',
              ),
            )
            .properties
            .label,
        'Object, count 1',
      );
    },
  );
}
