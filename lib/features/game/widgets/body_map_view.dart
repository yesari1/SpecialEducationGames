import 'package:flutter/material.dart';
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
    final usable = spots.where((s) => byId.containsKey(s.item)).toList();
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
                  final reach = (s.r * w) * 1.4;
                  if (dist <= reach * reach && dist < bestDist) {
                    best = s;
                    bestDist = dist;
                  }
                }
                if (best != null) callbacks.onSelect(byId[best.item]!);
              },
              child: Stack(
                children: [
                  Positioned.fill(child: PhotoVisual(asset)),
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

/// The body-map data (assets/content/body_map.json).
class BodyMap {
  final String picture;
  final double aspect;
  final List<BodySpot> spots;
  final Map<String, Map<String, String>> questions;
  const BodyMap(this.picture, this.aspect, this.spots, this.questions);

  factory BodyMap.fromJson(Map<String, dynamic> j) => BodyMap(
    j['picture'] as String,
    (j['aspect'] as num).toDouble(),
    [
      for (final s in j['spots'] as List)
        BodySpot.fromJson(s as Map<String, dynamic>),
    ],
    {
      for (final e in (j['questions'] as Map).entries)
        e.key as String: Map<String, String>.from(e.value as Map),
    },
  );

  List<ContentItem> items(ContentRepository content) => [
    for (final s in spots) ?content.anyItem(s.item),
  ];
}
