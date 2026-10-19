import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/learning/learning_report.dart';
import '../../l10n/scoped_localizations.dart';

class WeeklyCharts extends StatelessWidget {
  final AppState state;
  final LearningReport report;
  const WeeklyCharts({super.key, required this.state, required this.report});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final maximum = max(1.0, report.days.map((x) => x.minutes).reduce(max));
    return SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.familyLast7Days, style: SegText.heading),
          const SizedBox(height: SegSpace.s4),
          Text(l10n.familyPlayTimeMinutes, style: SegText.caption),
          const SizedBox(height: SegSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: report.days
                .map(
                  (day) => Expanded(
                    child: Semantics(
                      label:
                          '${day.date.day}/${day.date.month}: ${day.minutes.toStringAsFixed(1)} ${l10n.familyMinutes}',
                      child: Column(
                        children: [
                          Text(
                            day.minutes.toStringAsFixed(1),
                            style: SegText.caption,
                          ),
                          const SizedBox(height: SegSpace.s2),
                          Container(
                            height: day.minutes == 0
                                ? 1
                                : 120 * day.minutes / maximum,
                            width: 22,
                            decoration: BoxDecoration(
                              color: day.minutes == 0
                                  ? SegColors.line
                                  : SegColors.primary,
                              borderRadius: BorderRadius.circular(SegRadius.xs),
                            ),
                          ),
                          const SizedBox(height: SegSpace.s2),
                          Text(
                            '${day.date.day}/${day.date.month}',
                            style: SegText.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: SegSpace.s6),
          Text(l10n.familyIndependentFirstAnswers, style: SegText.caption),
          const SizedBox(height: SegSpace.s4),
          ReportLine(
            values: report.days
                .map(
                  (x) => x.independence == null ? null : x.independence! * 100,
                )
                .toList(),
            maximum: 100,
          ),
          const SizedBox(height: SegSpace.s3),
          Row(
            children: report.days
                .map(
                  (day) => Expanded(
                    child: Text(
                      day.independence == null
                          ? '—'
                          : '${(day.independence! * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: SegText.caption,
                    ),
                  ),
                )
                .toList(),
          ),
          if (report.trials.isEmpty) ...[
            const SizedBox(height: SegSpace.s4),
            Text(l10n.familyProgressWillAppearHereAfterThe),
          ],
        ],
      ),
    );
  }
}

class AttentionChart extends StatelessWidget {
  final AppState state;
  final LearningReport report;
  const AttentionChart({super.key, required this.state, required this.report});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final latency = report.days.map((x) => x.latencySeconds).toList();
    final idle = report.days.map((x) => x.idleSeconds).toList();
    final maximum = max(
      1.0,
      [...latency, ...idle].whereType<double>().fold<double>(0, max),
    );
    return SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.familyAttentionDailyAverageSeconds, style: SegText.heading),
          const SizedBox(height: SegSpace.s4),
          Text(l10n.familyFirstResponse, style: SegText.caption),
          ReportLine(values: latency, maximum: maximum),
          Text(l10n.familyIdleTime, style: SegText.caption),
          ReportLine(values: idle, maximum: maximum),
          const SizedBox(height: SegSpace.s3),
          Row(
            children: report.days
                .map(
                  (x) => Expanded(
                    child: Text(
                      '${x.date.day}/${x.date.month}',
                      textAlign: TextAlign.center,
                      style: SegText.caption,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: SegSpace.s4),
          Text(
            '${l10n.familySecondsRange(maximum)} ${l10n.familyTimeInTheBackgroundIsExcluded}',
            style: SegText.caption,
          ),
          ExpansionTile(
            title: Text(l10n.familyNumericView),
            children: [
              for (final day in report.days)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: SegSpace.s2),
                  child: Text(
                    '${day.date.day}/${day.date.month} · '
                    '${l10n.familyFirstResponse}: ${day.latencySeconds?.toStringAsFixed(1) ?? '—'} ${l10n.familyS} · '
                    '${l10n.familyIdleTime}: ${day.idleSeconds?.toStringAsFixed(1) ?? '—'} ${l10n.familyS}',
                    style: SegText.caption,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportLine extends StatelessWidget {
  final List<double?> values;
  final double maximum;
  const ReportLine({super.key, required this.values, required this.maximum});
  @override
  Widget build(BuildContext context) => Semantics(
    label: values.map((x) => x?.toStringAsFixed(1) ?? '—').join(', '),
    child: SizedBox(
      height: 90,
      width: double.infinity,
      child: CustomPaint(painter: _LinePainter(values, maximum)),
    ),
  );
}

class SkillsCard extends StatelessWidget {
  final AppState state;
  final LearningReport report;
  const SkillsCard({super.key, required this.state, required this.report});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    return SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.familySkillAreas, style: SegText.heading),
          Text(
            l10n.familyIndependentFirstAnswersInTheLast,
            style: SegText.caption,
          ),
          for (final entry in LearningReport.skillNames.entries)
            Builder(
              builder: (context) {
                final trials = report.forSkill(entry.key);
                final trend = report.skillTrend(entry.key);
                final points = ((trend ?? 0) * 100).round();
                final rate = trials.isEmpty
                    ? null
                    : trials.where(ReportDay.independent).length /
                          trials.length;
                return Padding(
                  padding: const EdgeInsets.only(top: SegSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.value[state.locale == 'tr' ? 0 : 1]} · ${rate == null ? '—' : '${(rate * 100).round()}%'}',
                      ),
                      const SizedBox(height: SegSpace.s2),
                      LinearProgressIndicator(
                        value: rate ?? 0,
                        color: SegColors.primary,
                        backgroundColor: SegColors.line,
                        minHeight: 8,
                      ),
                      Text(
                        trials.isEmpty
                            ? l10n.familyNoRecordsYet
                            : l10n.familyCountStages(trials.length),
                        style: SegText.caption,
                      ),
                      if (trend != null)
                        Text(
                          '${points > 0
                              ? '↑'
                              : points < 0
                              ? '↓'
                              : '→'} ${points.abs()} ${l10n.familyPointsComparedWithThePreviousWeek}',
                          style: SegText.caption,
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double?> values;
  final double maximum;
  _LinePainter(this.values, this.maximum);
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = SegColors.line
      ..strokeWidth = 1;
    final line = Paint()
      ..color = SegColors.primary
      ..strokeWidth = 3;
    for (final ratio in [0.0, .5, 1.0]) {
      final y = 6 + ratio * (size.height - 12);
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), grid);
    }
    Offset? previous;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        previous = null;
        continue;
      }
      final point = Offset(
        6 + i * (size.width - 12) / max(1, values.length - 1),
        size.height -
            6 -
            value.clamp(0, maximum) / maximum * (size.height - 12),
      );
      if (previous != null) canvas.drawLine(previous, point, line);
      canvas.drawCircle(point, 4, line);
      previous = point;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.maximum != maximum;
}
