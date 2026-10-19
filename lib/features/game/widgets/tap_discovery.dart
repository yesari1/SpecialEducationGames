import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class TapDiscovery extends StatefulWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;
  final bool reducedMotion;
  const TapDiscovery({
    super.key,
    required this.child,
    required this.label,
    required this.onTap,
    required this.reducedMotion,
  });
  @override
  State<TapDiscovery> createState() => _TapDiscoveryState();
}

class _TapDiscoveryState extends State<TapDiscovery>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SegRadius.lg),
        highlightColor: SegColors.hintGlow,
        onTap: () {
          if (!widget.reducedMotion &&
              !MediaQuery.disableAnimationsOf(context)) {
            motion.forward(from: 0);
          }
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: motion,
          child: widget.child,
          builder: (_, child) {
            final progress =
                widget.reducedMotion || MediaQuery.disableAnimationsOf(context)
                ? 0.0
                : motion.value;
            return Transform.rotate(
              angle: sin(progress * pi * 2) * .025,
              child: Transform.scale(
                scale: 1 + sin(progress * pi) * .06,
                child: child,
              ),
            );
          },
        ),
      ),
    ),
  );
}
