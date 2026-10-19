import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../l10n/scoped_localizations.dart';

class GoalRing extends StatelessWidget {
  final AppState state;
  final double minutes;
  const GoalRing({super.key, required this.state, required this.minutes});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    return SegCard(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: SegSpace.s5,
        runSpacing: SegSpace.s4,
        children: [
          Semantics(
            label: l10n.familyTodayGoalProgress(
              minutes,
              state.dailyGoalMinutes,
            ),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: (minutes / state.dailyGoalMinutes).clamp(0, 1),
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: SegColors.turquoise,
                      backgroundColor: const Color(0xFFE3F1F4),
                    ),
                  ),
                  Text(
                    '${minutes.toStringAsFixed(1)}\n/ ${state.dailyGoalMinutes}',
                    textAlign: TextAlign.center,
                    style: SegText.item,
                  ),
                ],
              ),
            ),
          ),
          Text(l10n.familyDailyMinuteGoal, style: SegText.heading),
        ],
      ),
    );
  }
}
