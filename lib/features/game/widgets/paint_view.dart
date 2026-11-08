import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// G42 "Boya": a big white picture above the paint choices. The right
/// colour paints the picture (a soft fade); a wrong one leaves it white.
class PaintView extends StatelessWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  const PaintView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final asset = spec.promptImagePath;
    final color = Color(ItemVisual.colors[spec.target.slug] ?? 0xFFFFFFFF);
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: asset == null
              ? const SizedBox.shrink()
              : AnimatedSwitcher(
                  duration: hint.animate
                      ? const Duration(milliseconds: 600)
                      : Duration.zero,
                  child: hint.celebrating
                      ? ColorFiltered(
                          key: const ValueKey('paint-done'),
                          colorFilter: ColorFilter.mode(
                            color,
                            BlendMode.modulate,
                          ),
                          child: PhotoVisual(asset),
                        )
                      : PhotoVisual(asset, key: const ValueKey('paint-white')),
                ),
        ),
        const SizedBox(height: SegSpace.s2),
        Expanded(
          flex: 2,
          child: RoundChoicesView(spec: spec, callbacks: callbacks, hint: hint),
        ),
      ],
    );
  }
}
