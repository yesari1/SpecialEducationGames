import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

AppLocalizations parkL10n(BuildContext context, AppState s) =>
    scopedLocalizations(context, s.locale);

/// The frame of a Play Park game: its background, a back button, the name.
class ParkScaffold extends StatelessWidget {
  final String title;
  final String background;
  final VoidCallback onBack;
  final Widget child;

  /// Sits at the right of the top bar (the puzzle's level picker).
  final Widget? trailing;
  const ParkScaffold({
    super.key,
    required this.title,
    required this.background,
    required this.onBack,
    required this.child,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1EEFD),
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          background,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          excludeFromSemantics: true,
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(SegSpace.s2),
                child: Row(
                  children: [
                    PillButton(
                      key: const ValueKey('park-back'),
                      semanticsLabel: title,
                      onPressed: () {
                        UiSound.tap();
                        onBack();
                      },
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: SegSpace.s3),
                    Text(title, style: SegText.title),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    ),
  );
}
