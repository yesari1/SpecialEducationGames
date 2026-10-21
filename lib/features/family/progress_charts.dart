import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/learning/learning_report.dart';
import '../../l10n/scoped_localizations.dart';

/// "15–21 Oct": the week shown by the charts.
String _range(LearningReport report, String locale) {
  final first = report.days.first.date, last = report.days.last.date;
  final day = DateFormat.d(locale), month = DateFormat.MMM(locale);
  return first.month == last.month
      ? '${day.format(first)}–${day.format(last)} ${month.format(last)}'
      : '${DateFormat.MMMd(locale).format(first)} – '
            '${DateFormat.MMMd(locale).format(last)}';
}

/// Card title with the week on the right.
class _ChartTitle extends StatelessWidget {
  final String title, range;
  const _ChartTitle(this.title, this.range);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: SegText.heading)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: SegColors.primarySoft,
          borderRadius: BorderRadius.circular(SegRadius.pill),
        ),
        child: Text(
          range,
          style: SegText.caption.copyWith(color: SegColors.primaryDeep),
        ),
      ),
    ],
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: SegText.caption.copyWith(color: SegColors.ink),
        ),
      ),
    ],
  );
}

/// Short weekday under each column ("Wed").
class _DayLabels extends StatelessWidget {
  final LearningReport report;
  final String locale;
  const _DayLabels(this.report, this.locale);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final day in report.days)
        Expanded(
          child: Text(
            DateFormat.E(locale).format(day.date),
            textAlign: TextAlign.center,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
        ),
    ],
  );
}

class WeeklyCharts extends StatelessWidget {
  final AppState state;
  final LearningReport report;
  const WeeklyCharts({super.key, required this.state, required this.report});
  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    final maximum = max(1.0, report.days.map((x) => x.minutes).reduce(max));
    Color rateColor(double rate) => rate >= .7
        ? SegColors.turquoise
        : rate >= .4
        ? SegColors.star
        : SegColors.accent;
    return SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartTitle(l10n.familyLast7Days, _range(report, state.locale)),
          const SizedBox(height: SegSpace.s4),
          _Legend(SegColors.primary, l10n.familyPlayTimeMinutes),
          const SizedBox(height: SegSpace.s3),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in report.days)
                  Expanded(
                    child: Semantics(
                      label:
                          '${DateFormat.MMMd(state.locale).format(day.date)}: '
                          '${day.minutes.round()} ${l10n.familyMinutes}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (day.minutes > 0)
                            Text(
                              '${day.minutes.round()}',
                              style: SegText.caption.copyWith(
                                color: SegColors.primaryDeep,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: day.minutes == 0
                                ? 6
                                : max(10.0, 100 * day.minutes / maximum),
                            width: 22,
                            decoration: BoxDecoration(
                              gradient: day.minutes == 0
                                  ? null
                                  : const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        SegColors.sky,
                                        SegColors.primary,
                                      ],
                                    ),
                              color: day.minutes == 0 ? SegColors.line : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: SegSpace.s2),
          _DayLabels(report, state.locale),
          const SizedBox(height: SegSpace.s5),
          _Legend(SegColors.turquoise, l10n.familyIndependentFirstAnswers),
          const SizedBox(height: SegSpace.s3),
          Row(
            children: [
              for (final day in report.days)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: day.independence == null
                            ? SegColors.familyCanvas
                            : rateColor(
                                day.independence!,
                              ).withValues(alpha: .18),
                        border: Border.all(
                          color: day.independence == null
                              ? SegColors.line
                              : rateColor(day.independence!),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        day.independence == null
                            ? '–'
                            : '${(day.independence! * 100).round()}',
                        style: SegText.caption.copyWith(
                          color: SegColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (report.trials.isEmpty) ...[
            const SizedBox(height: SegSpace.s4),
            Text(
              l10n.familyProgressWillAppearHereAfterThe,
              style: SegText.caption.copyWith(color: SegColors.inkSoft),
            ),
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
          _ChartTitle(
            l10n.familyAttentionDailyAverageSeconds,
            _range(report, state.locale),
          ),
          const SizedBox(height: SegSpace.s3),
          Wrap(
            spacing: SegSpace.s4,
            runSpacing: SegSpace.s1,
            children: [
              _Legend(SegColors.primary, l10n.familyFirstResponse),
              _Legend(SegColors.accent, l10n.familyIdleTime),
            ],
          ),
          const SizedBox(height: SegSpace.s3),
          Semantics(
            label:
                '${l10n.familyFirstResponse}: '
                '${latency.map((x) => x?.toStringAsFixed(1) ?? '–').join(', ')}. '
                '${l10n.familyIdleTime}: '
                '${idle.map((x) => x?.toStringAsFixed(1) ?? '–').join(', ')}',
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _LinePainter([
                  (latency, SegColors.primary),
                  (idle, SegColors.accent),
                ], maximum),
              ),
            ),
          ),
          const SizedBox(height: SegSpace.s2),
          _DayLabels(report, state.locale),
        ],
      ),
    );
  }
}

/// One line chart with one or more coloured series.
class ReportLine extends StatelessWidget {
  final List<double?> values;
  final double maximum;
  const ReportLine({super.key, required this.values, required this.maximum});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90,
    width: double.infinity,
    child: CustomPaint(
      painter: _LinePainter([(values, SegColors.primary)], maximum),
    ),
  );
}

class SkillsCard extends StatelessWidget {
  final AppState state;
  final LearningReport report;
  const SkillsCard({super.key, required this.state, required this.report});

  static const _colors = [
    SegColors.turquoise,
    SegColors.primary,
    SegColors.accent,
    Color(0xFF7C73DF),
    SegColors.star,
    Color(0xFFE86F9A),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, state.locale);
    var index = 0;
    return SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.familySkillAreas, style: SegText.heading),
          for (final entry in LearningReport.skillNames.entries)
            Builder(
              builder: (context) {
                final color = _colors[index++ % _colors.length];
                final trials = report.forSkill(entry.key);
                final trend = report.skillTrend(entry.key);
                final points = ((trend ?? 0) * 100).round();
                final rate = trials.isEmpty
                    ? null
                    : trials.where(ReportDay.independent).length /
                          trials.length;
                return Padding(
                  padding: const EdgeInsets.only(top: SegSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value[state.locale == 'tr' ? 0 : 1],
                              style: SegText.label.copyWith(
                                color: SegColors.ink,
                              ),
                            ),
                          ),
                          if (trend != null && points != 0)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: SegSpace.s2,
                              ),
                              child: Text(
                                '${points > 0 ? '↑' : '↓'} ${points.abs()}',
                                style: SegText.caption.copyWith(
                                  color: points > 0
                                      ? SegColors.turquoiseDeep
                                      : SegColors.accentDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          Text(
                            rate == null ? '–' : '${(rate * 100).round()}%',
                            style: SegText.label.copyWith(
                              color: SegColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(SegRadius.pill),
                        child: LinearProgressIndicator(
                          value: rate ?? 0,
                          color: color,
                          backgroundColor: color.withValues(alpha: .15),
                          minHeight: 10,
                        ),
                      ),
                      if (trials.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.familyCountStages(trials.length),
                            style: SegText.caption.copyWith(
                              color: SegColors.inkSoft,
                            ),
                          ),
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
  final List<(List<double?>, Color)> series;
  final double maximum;
  _LinePainter(this.series, this.maximum);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = SegColors.line
      ..strokeWidth = 1;
    for (final ratio in [0.0, .5, 1.0]) {
      final y = 8 + ratio * (size.height - 16);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final (values, color) in series) {
      final line = Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final dot = Paint()..color = color;
      // Columns line up with the day labels under the chart.
      final step = size.width / max(1, values.length);
      Offset? previous;
      for (var i = 0; i < values.length; i++) {
        final value = values[i];
        if (value == null) {
          previous = null;
          continue;
        }
        final point = Offset(
          step * (i + .5),
          size.height -
              8 -
              value.clamp(0, maximum) / maximum * (size.height - 16),
        );
        if (previous != null) canvas.drawLine(previous, point, line);
        canvas.drawCircle(point, 5, dot);
        canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
        previous = point;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.series != series || old.maximum != maximum;
}
