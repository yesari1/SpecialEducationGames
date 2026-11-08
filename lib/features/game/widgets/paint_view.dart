import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// A big picture above the choices. G42 "Boya" ([paint]): the picture is
/// white and the right colour paints it (a soft fade). Scene games show
/// their scene as it is.
class PaintView extends StatelessWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  final bool paint;
  const PaintView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
    this.paint = true,
  });

  @override
  Widget build(BuildContext context) {
    final asset = spec.promptImagePath;
    final color = Color(ItemVisual.colors[spec.target.slug] ?? 0xFFFFFFFF);
    final picture = asset == null
        ? const SizedBox.shrink()
        : !paint
        ? ClipRRect(
            borderRadius: BorderRadius.circular(SegRadius.lg),
            child: Image.asset(asset, fit: BoxFit.contain),
          )
        : AnimatedSwitcher(
            duration: hint.animate
                ? const Duration(milliseconds: 600)
                : Duration.zero,
            child: hint.celebrating
                ? ColorFiltered(
                    key: const ValueKey('paint-done'),
                    colorFilter: ColorFilter.mode(color, BlendMode.modulate),
                    child: PhotoVisual(asset),
                  )
                : PhotoVisual(asset, key: const ValueKey('paint-white')),
          );
    final choices = RoundChoicesView(
      spec: spec,
      callbacks: callbacks,
      hint: hint,
    );
    // Landscape: the picture on the left, big choices on the right.
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth > box.maxHeight
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(SegSpace.s3),
                    child: picture,
                  ),
                ),
                Expanded(flex: 3, child: choices),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 3, child: picture),
                const SizedBox(height: SegSpace.s2),
                Expanded(flex: 2, child: choices),
              ],
            ),
    );
  }
}
