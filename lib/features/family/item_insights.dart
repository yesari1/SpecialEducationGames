import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/learning/learning_report.dart';
import '../../l10n/scoped_localizations.dart';

class ItemInsights extends StatelessWidget {
  final AppState state;
  const ItemInsights({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final summaries = ItemLearningSummary.fromTrials(
      state.trials,
      DateTime.now(),
    );
    Widget section(String title, bool Function(ItemLearningSummary) include) {
      final selected = summaries
          .where(include)
          .where((x) => state.content.items.any((i) => i.id == x.itemId))
          .take(8)
          .toList();
      return ExpansionTile(
        title: Text(title, style: SegText.item),
        children: [
          if (selected.isEmpty)
            Padding(
              padding: const EdgeInsets.all(SegSpace.s4),
              child: Text(l10n.familyItemsAppearHereAfterAtLeast),
            ),
          for (final summary in selected)
            Builder(
              builder: (context) {
                final item = state.content.items.firstWhere(
                  (x) => x.id == summary.itemId,
                );
                return ListTile(
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: ItemVisual(item),
                  ),
                  title: Text(item.name(state.locale)),
                  subtitle: Text(
                    l10n.familyCountStagesLatestStreakAnswersIndependent(
                      summary.observations.length,
                      summary.independentStreak,
                    ),
                  ),
                );
              },
            ),
        ],
      );
    }

    return SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.familyItems, style: SegText.heading),
          section(
            l10n.familyIndependentlyAnswered,
            (x) => x.independentlyAnswered,
          ),
          section(l10n.familyItemsNeedingMoreSupport, (x) => x.needsSupport),
        ],
      ),
    );
  }
}
