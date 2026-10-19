import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
import '../../../app/ui/game_object.dart';
import '../../../core/content/content_repository.dart';
import '../../../l10n/scoped_localizations.dart';

class CountedObjects extends StatefulWidget {
  final int count;
  final ContentItem? item;
  final String locale;
  final ValueChanged<int> onCount;
  final bool enabled;
  const CountedObjects({
    super.key,
    required this.count,
    this.item,
    required this.locale,
    required this.onCount,
    this.enabled = true,
  });
  @override
  State<CountedObjects> createState() => _CountedObjectsState();
}

class _CountedObjectsState extends State<CountedObjects> {
  final Map<int, int> counted = {};
  @override
  void didUpdateWidget(CountedObjects old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count || old.item?.id != widget.item?.id) {
      counted.clear();
    }
  }

  Widget object(BuildContext context, int index) {
    final l10n = scopedLocalizations(context, widget.locale);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: l10n.gameCountedObjectSemantics(
        widget.item?.name(widget.locale) ?? l10n.gameObject,
        index + 1,
      ),
      value: counted[index] == null ? '' : '${counted[index]}',
      child: PressableObject(
        key: ValueKey('count-object-$index'),
        onTap: !widget.enabled
            ? null
            : () {
                if (counted.containsKey(index)) return;
                final number = counted.length + 1;
                setState(() => counted[index] = number);
                widget.onCount(number);
              },
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: SegMotion.focus,
                  opacity: counted.containsKey(index) ? 1 : 0,
                  child: const ObjectHalo(color: SegColors.primarySoft),
                ),
              ),
              const Positioned(
                left: 14,
                right: 14,
                bottom: 0,
                height: 8,
                child: GroundShadow(),
              ),
              Positioned.fill(
                child: AnimatedSlide(
                  duration: SegMotion.focus,
                  curve: Curves.easeOutBack,
                  offset: counted.containsKey(index)
                      ? const Offset(0, -.08)
                      : Offset.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 3, 5, 7),
                    child: widget.item == null
                        ? const CustomPaint(
                            painter: ColorBlobPainter(SegColors.accent),
                          )
                        : ItemVisual(widget.item!),
                  ),
                ),
              ),
              if (counted[index] case final int number)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 26),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: SegColors.primary,
                      borderRadius: BorderRadius.circular(SegRadius.pill),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$number',
                      textAlign: TextAlign.center,
                      style: SegText.label.copyWith(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.height < 500) {
      return SizedBox(
        width: size.width - 100,
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.count,
          separatorBuilder: (_, _) => const SizedBox(width: SegSpace.s3),
          itemBuilder: (context, i) => object(context, i),
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: SegSpace.s3,
      runSpacing: SegSpace.s3,
      children: List.generate(widget.count, (index) => object(context, index)),
    );
  }
}
