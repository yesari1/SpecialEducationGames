import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../../../app/ui/game_object.dart';
import '../../../l10n/scoped_localizations.dart';
import '../round_spec.dart';
import 'round_choices_view.dart';

/// "Sepeti Doldur": objects wait on the ground; each tap (or drag) puts one in
/// the basket and the count is shown. Tapping the basket takes one back out.
/// When the basket holds exactly the requested number the round succeeds.
class FillBasketView extends StatefulWidget {
  final RoundSpec spec;
  final RoundCallbacks callbacks;
  final HintViewState hint;
  final ValueChanged<int>? onCount;
  const FillBasketView({
    super.key,
    required this.spec,
    required this.callbacks,
    required this.hint,
    this.onCount,
  });
  @override
  State<FillBasketView> createState() => _FillBasketViewState();
}

class _FillBasketViewState extends State<FillBasketView> {
  final Set<int> _inBasket = {};

  int get _goal => widget.spec.fillCount ?? 1;
  int get _available => _goal + 2;

  @override
  void didUpdateWidget(FillBasketView old) {
    super.didUpdateWidget(old);
    if (old.hint.generation != widget.hint.generation) _inBasket.clear();
  }

  void _put(int index) {
    if (widget.hint.celebrating || _inBasket.contains(index)) return;
    setState(() => _inBasket.add(index));
    widget.onCount?.call(_inBasket.length);
    if (_inBasket.length == _goal) {
      widget.callbacks.onSelect(widget.spec.target);
    }
  }

  void _takeBack() {
    if (widget.hint.celebrating || _inBasket.isEmpty) return;
    setState(() => _inBasket.remove(_inBasket.last));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.hint.locale);
    final item = widget.spec.stimulus!;
    final reduced =
        !widget.hint.animate || MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final objectSize = (box.maxHeight * .5).clamp(48.0, 96.0);
        Widget object(int index) => Semantics(
          button: true,
          label: item.name(widget.hint.locale),
          child: Draggable<int>(
            data: index,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Transform.translate(
              offset: Offset(-objectSize / 2, -objectSize / 2),
              child: SizedBox.square(
                dimension: objectSize,
                child: ItemVisual(item),
              ),
            ),
            childWhenDragging: SizedBox.square(dimension: objectSize),
            child: PressableObject(
              key: ValueKey('fill-object-$index'),
              reducedMotion: reduced,
              onTap: () => _put(index),
              child: SizedBox.square(
                dimension: objectSize,
                child: StagedObject(
                  child: ItemVisual(item, alignment: Alignment.bottomCenter),
                ),
              ),
            ),
          ),
        );

        final basket = DragTarget<int>(
          onAcceptWithDetails: (details) => _put(details.data),
          builder: (context, candidates, _) => Semantics(
            button: true,
            label: l10n.gameFillBasketCount(_inBasket.length, _goal),
            child: GestureDetector(
              key: const ValueKey('fill-basket'),
              behavior: HitTestBehavior.opaque,
              onTap: _takeBack,
              child: AnimatedScale(
                duration: SegMotion.tap,
                scale: candidates.isEmpty ? 1 : 1.06,
                child: SizedBox(
                  width: box.maxHeight * 1.35,
                  height: box.maxHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: BasketFrame(
                          tint: SegColors.accent,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.end,
                            children: [
                              for (var i = 0; i < _inBasket.length; i++)
                                SizedBox.square(
                                  dimension: objectSize * .7,
                                  // The newest one hops in with an arc.
                                  child: i == _inBasket.length - 1
                                      ? HopIn(
                                          key: ValueKey('hop-$i'),
                                          animate: !reduced,
                                          child: ItemVisual(item),
                                        )
                                      : ItemVisual(item),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          key: const ValueKey('fill-basket-count'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: SegSpace.s3,
                            vertical: SegSpace.s1,
                          ),
                          decoration: BoxDecoration(
                            color: SegColors.primary,
                            borderRadius: BorderRadius.circular(SegRadius.pill),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '${_inBasket.length}',
                            style: SegText.heading.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        return Row(
          children: [
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: SegSpace.s2,
                  runSpacing: SegSpace.s2,
                  // Slots stay put so the next object is where it was.
                  children: [
                    for (var i = 0; i < _available; i++)
                      _inBasket.contains(i)
                          ? SizedBox.square(dimension: objectSize)
                          : object(i),
                  ],
                ),
              ),
            ),
            const SizedBox(width: SegSpace.s4),
            basket,
          ],
        );
      },
    );
  }
}
