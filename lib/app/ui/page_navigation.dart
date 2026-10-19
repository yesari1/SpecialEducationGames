import 'package:flutter/material.dart';

Future<void> navigatePage({
  required BuildContext context,
  required PageController controller,
  required int page,
  required bool reducedMotion,
  required Duration duration,
  required Curve curve,
}) {
  if (reducedMotion || MediaQuery.disableAnimationsOf(context)) {
    controller.jumpToPage(page);
    return Future<void>.value();
  }
  return controller.animateToPage(page, duration: duration, curve: curve);
}
