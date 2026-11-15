import 'package:flutter/material.dart';
import '../../../core/content/child_cast.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../../../core/content/content_repository.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// One tappable place on the whole-body picture, as fractions of the
/// picture (centre and radius of the width).
class BodySpot {
  final String item;
  final double x, y, r;
  const BodySpot(this.item, this.x, this.y, this.r);
  factory BodySpot.fromJson(Map<String, dynamic> j) => BodySpot(
    j['item'] as String,
    (j['x'] as num).toDouble(),
    (j['y'] as num).toDouble(),
    (j['r'] as num).toDouble(),
  );
}

/// G47 "Ali'de Göster": the child taps the asked body part on a picture of
/// the whole of Ali. A hint lights the right place; the right tap rings it.
class BodyMapView extends StatelessWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  final List<BodySpot> spots;
  final double aspect;
  const BodyMapView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
    required this.spots,
    this.aspect = 2 / 3,
  });

  @override
  Widget build(BuildContext context) {
    final asset = spec.promptImagePath;
    if (asset == null) return const SizedBox.shrink();
    final byId = {for (final c in spec.choices) c.id: c};
    // Every place answers; a place that is not one of this round's choices
    // counts as a wrong tap like any other wrong choice.
    final usable = spots;
    final wrong = spec.choices.where((c) => c.id != spec.target.id).firstOrNull;
    final target = usable.where((s) => s.item == spec.target.id).firstOrNull;
    return Center(
      child: AspectRatio(
        aspectRatio: aspect,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            Widget ring(BodySpot s, Color color, String key) => Positioned(
              key: ValueKey(key),
              left: s.x * w - s.r * w,
              top: s.y * h - s.r * w,
              width: s.r * w * 2,
              height: s.r * w * 2,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .35),
                    border: Border.all(color: color, width: 4),
                  ),
                ),
              ),
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final p = d.localPosition;
                BodySpot? best;
                var bestDist = double.infinity;
                for (final s in usable) {
                  final dx = p.dx - s.x * w, dy = p.dy - s.y * h;
                  final dist = dx * dx + dy * dy;
                  // Small places (the nose) still get a finger-sized target.
                  final reach = (s.r * w * 1.4).clamp(28.0, double.infinity);
                  if (dist <= reach * reach && dist < bestDist) {
                    best = s;
                    bestDist = dist;
                  }
                }
                if (best == null) return;
                final picked = byId[best.item] ?? wrong;
                if (picked != null) callbacks.onSelect(picked);
              },
              child: Stack(
                children: [
                  Positioned.fill(child: PhotoVisual(ChildCast.of(asset))),
                  if (target != null && hint.celebrating)
                    ring(target, SegColors.successGlow, 'body-right')
                  else if (target != null && hint.level > 0)
                    ring(target, SegColors.star, 'body-hint'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One picture of Ali (his face, or his whole body) and its places.
class BodyPicture {
  final String asset;
  final double aspect;
  final List<BodySpot> spots;
  const BodyPicture(this.asset, this.aspect, this.spots);
  factory BodyPicture.fromJson(Map<String, dynamic> j) =>
      BodyPicture(j['picture'] as String, (j['aspect'] as num).toDouble(), [
        for (final s in j['spots'] as List)
          BodySpot.fromJson(s as Map<String, dynamic>),
      ]);
}

/// The body-map data (assets/content/body_map.json): face parts are asked
/// on a big picture of Ali's face, the rest on the whole body.
class BodyMap {
  final List<BodyPicture> pictures;
  final Map<String, Map<String, String>> questions;
  const BodyMap(this.pictures, this.questions);

  factory BodyMap.fromJson(Map<String, dynamic> j) => BodyMap(
    [
      for (final p in j['pictures'] as List)
        BodyPicture.fromJson(p as Map<String, dynamic>),
    ],
    {
      for (final e in (j['questions'] as Map).entries)
        e.key as String: Map<String, String>.from(e.value as Map),
    },
  );

  BodyPicture? pictureFor(String item) =>
      pictures.where((p) => p.spots.any((s) => s.item == item)).firstOrNull;

  /// Each body part once (a part may have two places, like the eyes).
  List<ContentItem> items(ContentRepository content) => [
    for (final id in {
      for (final p in pictures)
        for (final s in p.spots) s.item,
    })
      ?content.anyItem(id),
  ];
}
