import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/ui/components.dart';
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
      child: InkWell(
        key: ValueKey('count-object-$index'),
        borderRadius: BorderRadius.circular(SegRadius.md),
        onTap: !widget.enabled
            ? null
            : () {
                if (counted.containsKey(index)) return;
                final number = counted.length + 1;
                setState(() => counted[index] = number);
                widget.onCount(number);
              },
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SegRadius.md),
            border: Border.all(
              color: counted.containsKey(index)
                  ? SegColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.item == null
                    ? const Icon(
                        Icons.circle,
                        color: SegColors.accent,
                        size: 36,
                      )
                    : ItemVisual(widget.item!),
              ),
              if (counted[index] case final int number)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: SegColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$number',
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
