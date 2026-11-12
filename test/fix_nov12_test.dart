import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final scenes = _json('assets/content/scene_games.json');
  final pairs = _json('assets/content/pair_games.json');
  final extra = {
    for (final item
        in jsonDecode(
              File('assets/content/extra_items.json').readAsStringSync(),
            )
            as List)
      (item as Map<String, dynamic>)['id'] as String: item,
  };

  group('dress-up (G63)', () {
    final rounds = (scenes['G63'] as Map)['rounds'] as List;

    test('each child has five outfits at every level', () {
      for (final who in ['boy', 'girl']) {
        for (final tier in ['easy', 'medium', 'hard']) {
          final keys = {
            for (final r in rounds)
              if (r['who'] == who && r['tier'] == tier) r['key'],
          };
          expect(keys, hasLength(5), reason: '$who $tier');
        }
      }
    });

    test('every piece and every picture of an outfit is bundled', () {
      for (final r in rounds) {
        expect(File(r['stage'] as String).existsSync(), isTrue);
        for (final step in r['steps'] as List) {
          final piece = extra[step['piece']];
          expect(piece, isNotNull, reason: '${step['piece']}');
          final images = piece!['images'] as List;
          expect(images, isNotEmpty, reason: '${step['piece']}');
          expect(File(images.first as String).existsSync(), isTrue);
          expect(
            File(step['after'] as String).existsSync(),
            isTrue,
            reason: '${step['after']}',
          );
        }
      }
    });

    test('a wrong piece is never called the same as an asked one', () {
      // "Şapkasını takalım" with a hat and a beanie side by side was the
      // complaint: nothing in the tray may be confused by name or place.
      String name(String id) => (extra[id]!['name'] as Map)['tr'] as String;
      for (final r in rounds) {
        final asked = {
          for (final s in r['steps'] as List) name(s['piece'] as String),
        };
        for (final other in r['extras'] as List) {
          expect(
            asked,
            isNot(contains(name(other as String))),
            reason: r['key'],
          );
        }
        // The boy's tray never holds the girl's clothes, or the other way.
        for (final id in [
          ...(r['steps'] as List).map((s) => s['piece'] as String),
          ...(r['extras'] as List).cast<String>(),
        ]) {
          expect(id, startsWith('outfit.${r['who']}_'));
        }
      }
    });
  });

  test('the boy is never offered a dress, a skirt or a swimsuit (G64)', () {
    final rounds = (pairs['G64'] as Map)['rounds'] as List;
    const girls = ['clothes.dress', 'clothes.skirt', 'clothes.swimsuit'];
    final boy = rounds.where((r) => r['who'] == 'boy').toList();
    expect(boy, hasLength(8));
    expect(rounds.where((r) => r['who'] == 'girl'), hasLength(8));
    for (final r in boy) {
      expect(girls, isNot(contains(r['target'])));
      expect(r['avoid'], containsAll(girls));
      for (final also in r['alsoRight'] as List) {
        expect(girls, isNot(contains(also)));
      }
    }
  });

  test('no two tables of a level are set with the same pieces (G66)', () {
    final rounds = (scenes['G66'] as Map)['rounds'] as List;
    for (final tier in ['easy', 'medium', 'hard']) {
      final sets = [
        for (final r in rounds)
          if (r['tier'] == tier)
            ([
              for (final s in r['steps'] as List) s['piece'] as String,
            ]..sort()).join(','),
      ];
      expect(sets.toSet(), hasLength(sets.length), reason: tier);
      expect(sets, hasLength(5));
    }
  });

  test('English never says Ali', () {
    final found = <String>[];
    void walk(Object? node) {
      if (node is Map) {
        final en = node['en'];
        if (node.containsKey('tr') &&
            en is String &&
            RegExp(r'\bAli\b').hasMatch(en)) {
          found.add(en);
        }
        node.values.forEach(walk);
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    for (final file in [
      'scene_games.json',
      'pair_games.json',
      'stories.json',
      'games.json',
      'extra_items.json',
      'body_map.json',
    ]) {
      walk(jsonDecode(File('assets/content/$file').readAsStringSync()));
    }
    expect(found, isEmpty);
  });

  group('EdgePull', () {
    Future<List<String>> pump(WidgetTester tester, int cards) async {
      final calls = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdgePull(
              onNext: () => calls.add('next'),
              onPrevious: () => calls.add('previous'),
              child: ListView(
                key: const ValueKey('row'),
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                children: [
                  for (var i = 0; i < cards; i++)
                    SizedBox(width: 300, child: Text('card $i')),
                ],
              ),
            ),
          ),
        ),
      );
      return calls;
    }

    testWidgets('a pull past the right end opens the next section', (
      tester,
    ) async {
      final calls = await pump(tester, 2);
      // The row is shorter than the screen: it is at both of its ends.
      await tester.drag(
        find.byKey(const ValueKey('row')),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(calls, ['next']);
      await tester.drag(
        find.byKey(const ValueKey('row')),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();
      expect(calls, ['next', 'previous']);
    });

    testWidgets('scrolling a long row to its end does not change section', (
      tester,
    ) async {
      final calls = await pump(tester, 6);
      // One long drag from the start: reaches the end and pulls past it.
      await tester.drag(
        find.byKey(const ValueKey('row')),
        const Offset(-1500, 0),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      // Already at the end: one more pull changes the section.
      await tester.drag(
        find.byKey(const ValueKey('row')),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(calls, ['next']);
    });
  });
}
