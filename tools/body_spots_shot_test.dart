// Run explicitly: flutter test tools/body_spots_shot_test.dart --update-goldens
// Draws the hint ring of every body part on Ali's and Ayşe's pictures
// (G47) into artifacts/claude/body-nov16/.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/content/child_cast.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/features/game/round_spec.dart';
import 'package:special_education_games/features/game/widgets/body_map_view.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

void main() {
  testWidgets('body spots', (tester) async {
    late ContentRepository content;
    await tester.runAsync(() async {
      content = await ContentRepository.load();
      final raw = jsonDecode(
        await rootBundle.loadString('assets/content/photo_bounds.json'),
      ) as Map<String, dynamic>;
      PhotoVisual.registerBounds({
        for (final e in raw.entries)
          e.key: Rect.fromLTRB(
            (e.value[0] as num).toDouble(),
            (e.value[1] as num).toDouble(),
            (e.value[2] as num).toDouble(),
            (e.value[3] as num).toDouble(),
          ),
      });
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(2400, 1100);
    final map = BodyMap.fromJson(content.bodyMap);
    for (final who in const ['boy', 'girl']) {
      ChildCast.who = who;
      for (final (n, picture) in map.pictures.indexed) {
        final shown = ChildCast.of(picture.asset);
        final spots = picture.spotsFor(shown);
        final parts = {for (final s in spots) s.item}.toList();
        await tester.pumpWidget(
          RepaintBoundary(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: ColoredBox(
                color: const Color(0xFFDDEBF7),
                child: Wrap(
                  children: [
                    for (final part in parts)
                      SizedBox(
                        width: n == 0 ? 470 : 300,
                        height: n == 0 ? 360 : 540,
                        child: BodyMapView(
                          spec: RoundSpec(
                            target: content.anyItem(part)!,
                            choices: [content.anyItem(part)!],
                            promptTr: part,
                            promptEn: part,
                            promptImagePath: picture.asset,
                          ),
                          callbacks: RoundCallbacks(onSelect: (_) {}),
                          hint: const HintViewState(
                            level: 1,
                            visibleChoices: 1,
                            wrongCount: 0,
                            generation: 0,
                            celebrating: false,
                            showLabels: false,
                            animate: false,
                            locale: 'tr',
                          ),
                          spots: spots,
                          aspect: picture.aspect,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('../artifacts/claude/body-nov16/$who-$n.png'),
        );
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
