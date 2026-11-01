import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../l10n/scoped_localizations.dart';

/// Our own question before Android's permission dialog: shall we remind the
/// parent in the evening on days nothing was played? True for "Yes".
Future<bool> showReminderOffer(BuildContext context, AppState state) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReminderOffer(state: state),
    ) ??
    false;

class ReminderOffer extends StatelessWidget {
  final AppState state;
  const ReminderOffer({super.key, required this.state});

  static const art = 'assets/illustrations/onboarding/opt_focus_medium.png';

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.reminderOfferTitle,
          style: SegText.heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SegSpace.s2),
        Text(
          l10n.reminderOfferBody,
          style: SegText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SegSpace.s4),
        SegButton(
          key: const ValueKey('reminder-offer-yes'),
          label: l10n.reminderOfferYes,
          icon: Icons.notifications_active_rounded,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: SegSpace.s1),
        TextButton(
          key: const ValueKey('reminder-offer-no'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.reminderOfferNo,
            style: SegText.item.copyWith(color: SegColors.inkSoft),
          ),
        ),
      ],
    );
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SegRadius.xl),
      ),
      insetPadding: const EdgeInsets.all(SegSpace.s4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(SegSpace.s5),
          // Landscape: picture beside the text; upright: above it. Very
          // large text scales down to fit instead of scrolling.
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = MediaQuery.sizeOf(context).aspectRatio > 1;
              final picture = _Art(size: wide ? 150 : 120);
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: box.maxWidth,
                  child: wide
                      ? Row(
                          children: [
                            picture,
                            const SizedBox(width: SegSpace.s5),
                            Expanded(child: text),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            picture,
                            const SizedBox(height: SegSpace.s3),
                            text,
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The alarm clock in a soft sunny circle.
class _Art extends StatelessWidget {
  final double size;
  const _Art({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .12),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          SegColors.star.withValues(alpha: .35),
          SegColors.star.withValues(alpha: .08),
        ],
      ),
    ),
    child: Image.asset(ReminderOffer.art, excludeFromSemantics: true),
  );
}
