import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class FamilyNavItem {
  final IconData icon, selectedIcon;
  final String label;
  const FamilyNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating pill navigation for the family area: white rounded surface with
/// a soft shadow, a tinted capsule that slides behind the selected tab, filled
/// icon when selected and outlined otherwise.
class FamilyNavBar extends StatelessWidget {
  final List<FamilyNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  const FamilyNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    // Short (landscape) viewports get a slimmer bar with icon and label inline.
    final short = MediaQuery.sizeOf(context).height < 500;
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        SegSpace.s4,
        short ? 0 : SegSpace.s1,
        SegSpace.s4,
        short ? SegSpace.s1 : SegSpace.s3,
      ),
      // heightFactor keeps the bottom slot from growing; wide screens centre it.
      child: Align(
        heightFactor: 1,
        child: Container(
          height: short ? 52 : 68,
          constraints: const BoxConstraints(maxWidth: 640),
          decoration: BoxDecoration(
            color: SegColors.surface,
            borderRadius: BorderRadius.circular(SegRadius.pill),
            boxShadow: [
              BoxShadow(
                color: SegColors.ink.withValues(alpha: .10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(short ? 2 : 6),
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: width * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: Container(
                      decoration: BoxDecoration(
                        color: SegColors.primarySoft,
                        borderRadius: BorderRadius.circular(SegRadius.pill),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(child: _tab(context, i, duration, short)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, Duration duration, bool short) {
    final item = items[index];
    final selected = index == selectedIndex;
    final color = selected ? SegColors.primaryDeep : SegColors.inkSoft;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        key: ValueKey('family-nav-$index'),
        onTap: onDestinationSelected == null
            ? null
            : () => onDestinationSelected!(index),
        radius: 36,
        highlightShape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(SegRadius.pill),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: short ? 48 : 56),
            child: Flex(
              direction: short ? Axis.horizontal : Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    key: ValueKey(selected),
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(width: short ? 6 : 0, height: short ? 0 : 2),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: SegText.caption.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
