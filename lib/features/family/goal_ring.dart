import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../l10n/scoped_localizations.dart';

/// Today's hero card: a calm ring with whole minutes ("4 / 15 dk") and one
/// status line. Without a daily goal it shows today's minutes only.
class GoalRing extends StatelessWidget {
  final AppState state;
  final double minutes;
  const GoalRing({super.key, required this.state, required this.minutes});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final goal = state.dailyGoalMinutes;
    final done = minutes.floor();
    final reached = goal > 0 && minutes >= goal;
    final status = goal <= 0
        ? l10n.famPlayedToday(done)
        : reached
        ? l10n.famGoalDone
        : l10n.famGoalLeft((goal - minutes).ceil());
    // The ring grows with the text size so its label always fits inside.
    final side = 92 + 28 * MediaQuery.textScalerOf(context).scale(1);
    final ring = Semantics(
      label: l10n.familyTodayGoalProgress(minutes, goal),
      excludeSemantics: true,
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CircularProgressIndicator(
                value: goal > 0 ? (minutes / goal).clamp(0, 1) : 0,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                color: reached ? SegColors.star : SegColors.turquoise,
                backgroundColor: const Color(0xFFE3F1F4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                goal > 0 ? l10n.famGoalShort(done, goal) : '$done',
                textAlign: TextAlign.center,
                style: SegText.label.copyWith(
                  color: SegColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return SegCard(
      child: Row(
        children: [
          ring,
          const SizedBox(width: SegSpace.s5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.famToday, style: SegText.title),
                const SizedBox(height: SegSpace.s1),
                Text(
                  l10n.familyDailyMinuteGoal,
                  style: SegText.label.copyWith(color: SegColors.inkSoft),
                ),
                const SizedBox(height: SegSpace.s2),
                Text(status, style: SegText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
