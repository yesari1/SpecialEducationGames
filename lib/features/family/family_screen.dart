import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/initial_avatar.dart';
import '../../app/ui/family_nav_bar.dart';
import '../../core/entitlement/entitlement_service.dart'
    show PremiumSource, qaPremium;
import '../../core/db/app_database.dart';
import '../../core/learning/age_band.dart';
import '../../core/learning/parent_pin.dart';
import '../../core/learning/learning_report.dart';
import 'progress_charts.dart';
import 'item_insights.dart';
import 'goal_ring.dart';
import '../../core/auth/family_auth.dart';
import 'ask_cards.dart';
import 'account_header.dart';
import 'parent_announcement_card.dart';
import '../child_home/reminder_offer.dart';
import '../../core/reminder/play_reminder.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

class _VolumeControl extends StatefulWidget {
  final String label;
  final int value;
  final bool enabled;
  final Future<void> Function(int) onSaved;
  const _VolumeControl({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onSaved,
  });
  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  late double value = widget.value.toDouble();
  @override
  void didUpdateWidget(covariant _VolumeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) value = widget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SegSpace.s3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.label} · ${value.round()}%', style: SegText.label),
        Semantics(
          label: widget.label,
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${value.round()}%',
            semanticFormatterCallback: (v) => '${v.round()}%',
            onChanged: widget.enabled ? (v) => setState(() => value = v) : null,
            onChangeEnd: widget.enabled
                ? (v) => widget.onSaved(v.round())
                : null,
          ),
        ),
      ],
    ),
  );
}

class _ParentPinDialog extends StatefulWidget {
  final AppState state;
  const _ParentPinDialog({required this.state});

  @override
  State<_ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<_ParentPinDialog> {
  final first = TextEditingController();
  final second = TextEditingController();
  String message = '';
  bool saving = false;
  AppState get s => widget.state;
  AppLocalizations get l10n => scopedLocalizations(context, s.locale);

  @override
  void dispose() {
    first.dispose();
    second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      TextButton(
        style: _dialogButtonStyle,
        onPressed: saving ? null : () => Navigator.pop(context),
        child: Text(l10n.familyCancel),
      ),
      if (s.hasParentPin)
        TextButton(
          style: _dialogButtonStyle,
          onPressed: saving
              ? null
              : () async {
                  await s.clearParentPin();
                  if (context.mounted) Navigator.pop(context);
                },
          child: Text(l10n.familyUseMultiplication),
        ),
      TextButton(
        style: _dialogButtonStyle,
        onPressed: saving
            ? null
            : () async {
                if (!ParentPin.valid(first.text) || first.text != second.text) {
                  setState(
                    () => message = l10n.familyEnterTheSameFourDigitsTwice,
                  );
                  return;
                }
                setState(() => saving = true);
                await s.setParentPin(first.text);
                if (context.mounted) Navigator.pop(context);
              },
        child: Text(l10n.familySave),
      ),
    ];
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(SegSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.familyParentPin, style: SegText.heading),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: first,
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.family4DigitPin,
                      ),
                    ),
                  ),
                  const SizedBox(width: SegSpace.s3),
                  Expanded(
                    child: TextField(
                      controller: second,
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.familyRepeatPin,
                      ),
                    ),
                  ),
                ],
              ),
              if (message.isNotEmpty) Text(message),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: SegSpace.s2,
                runSpacing: SegSpace.s1,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle get _dialogButtonStyle => TextButton.styleFrom(
  minimumSize: const Size(48, 48),
  visualDensity: VisualDensity.standard,
  tapTargetSize: MaterialTapTargetSize.padded,
);

class FamilyScreen extends StatefulWidget {
  final AppState state;

  /// The parent's Google account (for the survey's uid/e-mail), if any.
  final FamilyAuth? auth;
  const FamilyScreen({super.key, required this.state, this.auth});
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  int tab = 0;
  int sectionPage = 0;
  final PageController _sectionController = PageController();
  AppState get s => widget.state;
  AppLocalizations get l10n => scopedLocalizations(context, s.locale);

  @override
  void initState() {
    super.initState();
    // When due on entering the family area: the survey pop-up, later
    // Google Play's own rating card.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (s.showSurvey) {
        showAskDialog(context, SurveyCard(state: s, auth: widget.auth));
      } else if (s.showRating) {
        requestPlayReview(s);
      } else {
        unawaited(_offerReminder());
      }
    });
  }

  /// Families set up before the reminder existed are asked once here.
  Future<void> _offerReminder() async {
    if (!await s.shouldOfferReminder() || !mounted) return;
    await s.answerReminderOffer(await showReminderOffer(context, s));
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _editPin() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ParentPinDialog(state: s),
    );
  }

  List<Widget> _sectionPages({required bool compact, bool portrait = false}) {
    final pages = switch (tab) {
      0 => compact ? _compactDashboardPages() : _dashboard(),
      1 => compact ? _compactGamePages() : _games(),
      2 => _profiles(),
      _ => compact ? _compactSettingsPages() : _settings(),
    }.where((widget) => widget is! SizedBox).toList();
    if (s.configuration.announcementId != null) {
      // The card paginates its text, so it needs a bounded height even when
      // the upright family area scrolls.
      pages.insert(
        0,
        portrait
            ? SizedBox(height: 420, child: ParentAnnouncementCard(state: s))
            : ParentAnnouncementCard(state: s),
      );
    }
    return pages;
  }

  Widget _familyCard(Widget child) =>
      SegCard(padding: const EdgeInsets.all(SegSpace.s2), child: child);

  String _bandName(AgeBand band) => switch (band) {
    AgeBand.firstSteps => l10n.ageBandFirstSteps,
    AgeBand.explore => l10n.ageBandExplore,
    AgeBand.schoolReady => l10n.ageBandSchoolReady,
    AgeBand.practice => l10n.ageBandPractice,
  };

  String _bandInfo(AgeBand band) => switch (band) {
    AgeBand.firstSteps => l10n.ageBandFirstStepsInfo,
    AgeBand.explore => l10n.ageBandExploreInfo,
    AgeBand.schoolReady => l10n.ageBandSchoolReadyInfo,
    AgeBand.practice => l10n.ageBandPracticeInfo,
  };

  /// Age band of the active profile with the parent's one-step shift.
  List<Widget> _ageLevelControls() {
    final fromAge = s.ageBandFromAge, band = s.ageBand;
    if (fromAge == null || band == null) {
      return [
        Text(
          l10n.familyAgeLevelNoAge,
          key: const ValueKey('age-level-no-age'),
          style: SegText.caption,
        ),
      ];
    }
    final shift = s.ageLevelShift;
    return [
      Text(
        _bandName(band),
        key: const ValueKey('age-level-band'),
        style: SegText.item,
      ),
      Text(_bandInfo(band), style: SegText.caption),
      if (band != fromAge)
        Text(
          l10n.familyAgeLevelFromAge(_bandName(fromAge)),
          style: SegText.caption,
        ),
      const SizedBox(height: SegSpace.s2),
      SegmentedButton<int>(
        key: const ValueKey('age-level-shift'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: -1,
            enabled: fromAge != AgeBand.firstSteps,
            label: Text(l10n.familyAgeLevelEasier),
          ),
          ButtonSegment(value: 0, label: Text(l10n.familyAgeLevelByAge)),
          ButtonSegment(
            value: 1,
            enabled: fromAge != AgeBand.practice,
            label: Text(l10n.familyAgeLevelHarder),
          ),
        ],
        selected: {shift},
        onSelectionChanged: (value) => s.setAgeLevelShift(value.first),
      ),
      Text(l10n.familyAgeLevelNote, style: SegText.caption),
    ];
  }

  List<Widget> _compactDashboardPages() {
    final now = DateTime.now();
    final report = LearningReport(s.trials, s.sessions, now);
    final week = report.trials;
    final independent = week.where(ReportDay.independent).length;
    final pages = <Widget>[
      _familyCard(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.familyEveryStepMatters, style: SegText.label),
            Text(
              l10n.familyYourChildIsExploringAtTheir,
              style: SegText.caption,
            ),
          ],
        ),
      ),
      _familyCard(_compactStat('${s.dayStreak}', l10n.famDayStreak)),
      _familyCard(_compactStat('${s.todayStars}', l10n.familyStarsToday)),
      _familyCard(
        _compactStat(
          '${s.sessions.where((x) => DateUtilsHelper.sameDay(x.startedAt, now) && x.completed).length}',
          l10n.familyRoundsCompletedToday,
        ),
      ),
      _familyCard(
        _compactStat(
          (s.sessions
                      .where((x) => DateUtilsHelper.sameDay(x.startedAt, now))
                      .fold<int>(0, (sum, x) => sum + x.activeMs) /
                  60000)
              .toStringAsFixed(1),
          l10n.familyMinutesToday,
        ),
      ),
      _familyCard(_compactStat('${week.length}', l10n.familyStagesThisWeek)),
      _familyCard(
        _compactStat(
          week.isEmpty ? '—' : '${(100 * independent / week.length).round()}%',
          l10n.familyIndependentAnswers,
        ),
      ),
      if (s.dailyGoalMinutes > 0)
        GoalRing(state: s, minutes: report.days.last.minutes),
    ];
    if (!s.entitlement.isPremium) {
      // Short sideways pages: the card shrinks to its page instead of
      // overflowing at large text.
      return [
        ...pages,
        FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(width: 380, child: _lockedStatsCard()),
        ),
      ];
    }

    for (final day in report.days) {
      pages.add(
        _familyCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l10n.familyLast7Days} · ${l10n.familyPlayTimeMinutes}',
                style: SegText.caption,
              ),
              Text(
                '${day.date.day}/${day.date.month} · ${day.minutes.toStringAsFixed(1)}',
                style: SegText.label,
              ),
              Text(l10n.familyIndependentFirstAnswers, style: SegText.caption),
              Text(
                day.independence == null
                    ? '—'
                    : '${(day.independence! * 100).round()}%',
                style: SegText.label,
              ),
              if (report.trials.isEmpty)
                Text(
                  l10n.familyProgressWillAppearHereAfterThe,
                  style: SegText.caption,
                ),
            ],
          ),
        ),
      );
      final latency = day.latencySeconds;
      final idle = day.idleSeconds;
      pages.add(
        _familyCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.familyAttentionDailyAverageSeconds,
                style: SegText.caption,
              ),
              Text('${day.date.day}/${day.date.month}', style: SegText.label),
              Text(
                '${l10n.familyFirstResponse}: ${latency?.toStringAsFixed(1) ?? '—'} ${l10n.familyS}',
                style: SegText.caption,
              ),
              Text(
                '${l10n.familyIdleTime}: ${idle?.toStringAsFixed(1) ?? '—'} ${l10n.familyS}',
                style: SegText.caption,
              ),
              Text(
                l10n.familyTimeInTheBackgroundIsExcluded,
                style: SegText.caption,
              ),
            ],
          ),
        ),
      );
    }

    pages.add(
      _familyCard(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.familySkillAreas, style: SegText.label),
            Text(
              l10n.familyIndependentFirstAnswersInTheLast,
              style: SegText.caption,
            ),
          ],
        ),
      ),
    );
    for (final entry in LearningReport.skillNames.entries) {
      final trials = report.forSkill(entry.key);
      final rate = trials.isEmpty
          ? null
          : trials.where(ReportDay.independent).length / trials.length;
      final trend = report.skillTrend(entry.key);
      final points = ((trend ?? 0) * 100).round();
      pages.add(
        _familyCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entry.value[s.locale == 'tr' ? 0 : 1],
                style: SegText.caption,
              ),
              Text(
                rate == null ? '—' : '${(rate * 100).round()}%',
                style: SegText.label,
              ),
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
        ),
      );
    }
    pages.add(
      _familyCard(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.familyItems, style: SegText.label),
            Text(
              l10n.familyIndependentLastThreeAnswersWithoutHints,
              style: SegText.caption,
            ),
          ],
        ),
      ),
    );
    final summaries = ItemLearningSummary.fromTrials(s.trials, now);
    final itemGroups = <(String, bool Function(ItemLearningSummary))>[
      (l10n.familyIndependentlyAnswered, (x) => x.independentlyAnswered),
      (l10n.familyItemsNeedingMoreSupport, (x) => x.needsSupport),
    ];
    for (final (heading, include) in itemGroups) {
      final selected = summaries
          .where(include)
          .where((x) => s.content.items.any((i) => i.id == x.itemId))
          .take(8)
          .toList();
      pages.add(
        _familyCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: SegText.caption),
              if (selected.isEmpty)
                Text(
                  l10n.familyItemsAppearHereAfterAtLeast,
                  style: SegText.caption,
                ),
              for (final summary in selected)
                Builder(
                  builder: (context) {
                    final item = s.content.items.firstWhere(
                      (x) => x.id == summary.itemId,
                    );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name(s.locale), style: SegText.caption),
                        Text(
                          l10n.familyCountStagesLatestStreakAnswersIndependent(
                            summary.observations.length,
                            summary.independentStreak,
                          ),
                          style: SegText.caption,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }
    for (final theme in s.content.themes) {
      final data = week.where((trial) => trial.themeId == theme.id).toList();
      final rate = data.isEmpty
          ? 0.0
          : data.where(ReportDay.independent).length / data.length;
      pages.add(
        _familyCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.familyProgressByTheme, style: SegText.caption),
              Text(
                '${theme.name(s.locale)} · ${data.length}',
                style: SegText.label,
              ),
              LinearProgressIndicator(
                value: rate,
                color: SegColors.primary,
                backgroundColor: SegColors.line,
                minHeight: 8,
              ),
            ],
          ),
        ),
      );
    }
    return pages;
  }

  /// Pinned above the bottom bar while Premium is not open.
  Widget _premiumStrip() {
    final e = s.entitlement;
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SegSpace.s3,
          SegSpace.s2,
          SegSpace.s3,
          SegSpace.s1,
        ),
        child: Material(
          key: const ValueKey('family-premium-strip'),
          borderRadius: BorderRadius.circular(SegRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9A3D), SegColors.accentStrong],
              ),
            ),
            child: InkWell(
              onTap: () => context.go('/family/subscription'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegSpace.s3,
                  vertical: SegSpace.s2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: SegSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.trialUsed
                                ? l10n.familyPremiumStripBuy
                                : l10n.paywallStartTrial(e.trialDays),
                            style: SegText.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l10n.familyPremiumStripNote,
                            style: SegText.caption.copyWith(
                              color: Colors.white.withValues(alpha: .92),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedStatsCard() => SegCard(
    key: const ValueKey('family-locked-stats'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(SegSpace.s3),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1E0),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: SegColors.accentDeep,
            size: 30,
          ),
        ),
        const SizedBox(height: SegSpace.s2),
        Text(
          l10n.familyLockedStatsTitle,
          textAlign: TextAlign.center,
          style: SegText.heading.copyWith(color: SegColors.ink),
        ),
        const SizedBox(height: SegSpace.s1),
        Text(
          l10n.familyLockedStatsBody,
          textAlign: TextAlign.center,
          style: SegText.caption.copyWith(color: SegColors.inkSoft),
        ),
        const SizedBox(height: SegSpace.s3),
        SegButton(
          key: const ValueKey('family-locked-stats-button'),
          label: l10n.familyLockedStatsButton,
          onPressed: () => context.go('/family/subscription'),
        ),
      ],
    ),
  );

  /// Detailed statistics for Premium; free users see a blurred preview of
  /// the top with an unlock card over it.
  Widget _premiumOnly(Widget child) {
    if (s.entitlement.isPremium) return child;
    // Not a SizedBox: the page list drops SizedBox spacers.
    return ConstrainedBox(
      key: const ValueKey('family-premium-only'),
      constraints: const BoxConstraints.tightFor(height: 460),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SegColors.familyCanvas.withValues(alpha: .2),
                    SegColors.familyCanvas,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -.2),
            child: Padding(
              padding: const EdgeInsets.all(SegSpace.s4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(width: 380, child: _lockedStatsCard()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The daily reminder on or off, its hour; the note says what comes when.
  Widget _reminderControls() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile(
        key: const ValueKey('reminder-switch'),
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.familyReminder),
        value: s.reminderOn,
        onChanged: (value) => s.setReminder(value),
      ),
      if (s.reminderOn)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyReminderTime),
          trailing: DropdownButton<int>(
            key: const ValueKey('reminder-hour'),
            value: s.reminderHour,
            items: [
              for (final hour in PlayReminder.hours)
                DropdownMenuItem(value: hour, child: Text('$hour:00')),
            ],
            onChanged: (value) {
              if (value != null) s.setReminderHour(value);
            },
          ),
        ),
      Text(
        l10n.familyReminderNote,
        style: SegText.caption.copyWith(color: SegColors.inkSoft),
      ),
    ],
  );

  Widget _compactStat(String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: SegText.label.copyWith(color: SegColors.primaryDeep)),
      Text(label, style: SegText.caption),
    ],
  );

  List<Widget> _compactGamePages() => [
    if (!_canChooseGames) _gamesPremiumCard(),
    for (final theme in s.content.themes)
      for (final id in s.allGamesForTheme(theme.id))
        _familyCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(theme.name(s.locale), style: SegText.caption),
              _gameSwitch(theme.id, id),
            ],
          ),
        ),
  ];

  List<Widget> _compactSettingsPages() {
    Widget page(
      String title,
      List<Widget> children, {
      bool showHeading = true,
    }) => _familyCard(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeading) Text(title, style: SegText.label),
          ...children,
        ],
      ),
    );
    DropdownButton<T> dropdown<T>(
      T value,
      List<DropdownMenuItem<T>> items,
      ValueChanged<T?> onChanged,
    ) => DropdownButton<T>(
      isExpanded: true,
      value: value,
      items: items,
      onChanged: onChanged,
    );
    return [
      page(l10n.familyDailyScreenTimeLimit, [
        Text(l10n.familyCountsActivePlayTimeABreak, style: SegText.caption),
        dropdown(
          s.screenLimitMinutes,
          [
            for (final value in [0, 10, 15, 20, 30])
              DropdownMenuItem(
                value: value,
                child: Text(
                  value == 0 ? l10n.familyOff : '$value ${l10n.familyMinutes}',
                ),
              ),
          ],
          (value) {
            if (value != null) s.setting('screenLimitMinutes', '$value');
          },
        ),
        if (s.screenLimitMinutes > 0) ...[
          Text(
            l10n.familyRemainingTodayMinutesMinutes(
              (s.playTimeRemainingMs / 60000).ceil(),
            ),
            style: SegText.caption,
          ),
          TextButton(
            onPressed: s.extendPlayTime,
            child: Text(l10n.familyAdd10MinutesForToday),
          ),
        ],
      ]),
      page(l10n.familyAgeLevel, _ageLevelControls()),
      page(l10n.familyDefaultDifficulty, [
        dropdown(
          s.difficultyOverride == 'hard' && !s.entitlement.isPremium
              ? 'auto'
              : s.difficultyOverride,
          [
            DropdownMenuItem(
              value: 'auto',
              child: Text(l10n.familyAutomaticThemeSelection),
            ),
            DropdownMenuItem(value: 'easy', child: Text(l10n.familyEasy)),
            DropdownMenuItem(value: 'medium', child: Text(l10n.familyMedium)),
            if (s.entitlement.isPremium)
              DropdownMenuItem(value: 'hard', child: Text(l10n.familyHard)),
          ],
          (value) {
            if (value != null) s.setting('difficultyOverride', value);
          },
        ),
        Text(l10n.familyAppliesToNewRoundsHardLevel, style: SegText.caption),
      ]),
      page(l10n.familyRoundLength, [
        dropdown(
          s.roundLength,
          [
            for (final value in [0, 3, 5, 8, 10])
              DropdownMenuItem(
                value: value,
                child: Text(
                  value == 0
                      ? l10n.familySurveyDifficultySetting
                      : '$value ${l10n.familyStages}',
                ),
              ),
          ],
          (value) {
            if (value != null) s.setting('roundLength', '$value');
          },
        ),
      ]),
      page(l10n.familyHintDelay, [
        dropdown(
          s.hintSeconds,
          [
            for (final value in [-1, 0, 4, 6, 10])
              DropdownMenuItem(
                value: value,
                child: Text(
                  value == -1
                      ? l10n.familyAutomaticPerItem
                      : value == 0
                      ? l10n.familyTimedHintsOff
                      : '$value ${l10n.familySeconds}',
                ),
              ),
          ],
          (value) {
            if (value != null) s.setting('hintSeconds', '$value');
          },
        ),
      ]),
      page(l10n.familyNextRoundBehavior, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyFadeIncorrectChoicesAfter2Mistakes),
          onChanged: (value) => s.setting('fadeWrongChoices', '$value'),
          value: s.fadeWrongChoices,
        ),
        Text(l10n.familyAppliesToTheNextRoundIncorrect, style: SegText.caption),
      ]),
      page(l10n.familyCloudSync, showHeading: false, [
        SwitchListTile(
          key: const ValueKey('cloud-sync-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyCloudSync),
          value: s.cloudSync,
          onChanged: (value) => s.setting('cloudSync', '$value'),
        ),
        Text(l10n.familyCloudSyncNote, style: SegText.caption),
      ]),
      page(l10n.familyDailyMinuteGoal, [
        Text(l10n.familyAnOptionalReminderItDoesNot, style: SegText.caption),
        dropdown(
          s.dailyGoalMinutes,
          [
            for (final value in [0, 10, 15, 20, 30])
              DropdownMenuItem(
                value: value,
                child: Text(
                  value == 0 ? l10n.familyOff : '$value ${l10n.familyMin}',
                ),
              ),
          ],
          (value) {
            if (value != null) s.setting('dailyGoalMinutes', '$value');
          },
        ),
      ]),
      if (PlayReminder.supported)
        page(l10n.familyReminder, [_reminderControls()], showHeading: false),
      if (s.configuration.minSupportedVersion > 14)
        page(l10n.familyUpdate, [
          Text(l10n.familyANewVersionIsAvailableYou, style: SegText.caption),
        ]),
      page(l10n.familyParentGate, [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline_rounded),
          title: Text(
            s.hasParentPin
                ? l10n.family4DigitPin
                : l10n.familyMultiplicationQuestion,
          ),
          onTap: _editPin,
        ),
      ]),
      page(l10n.familyIntroduceNewItemsFirst, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyIntroduceNewItemsFirst),
          subtitle: Text(
            l10n.familyShowOneCardFirstThenOffer,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
          value: s.introduction,
          onChanged: (value) => s.setting('introduction', '$value'),
        ),
      ], showHeading: false),
      page(l10n.familyAdaptiveDifficulty, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyAdaptiveDifficulty),
          subtitle: Text(
            l10n.familyChangesApplyOnlyWhenANew,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
          value: s.automaticDifficulty,
          onChanged: (value) => s.setting('automaticDifficulty', '$value'),
        ),
      ], showHeading: false),
      page(l10n.familyAudio, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyAudio),
          value: s.sound,
          onChanged: (value) => s.setting('sound', '$value'),
        ),
        _VolumeControl(
          key: const ValueKey('speech-volume'),
          label: l10n.familySpeechVolume,
          value: s.speechVolume,
          enabled: s.sound,
          onSaved: (value) => s.setting('speechVolume', '$value'),
        ),
      ], showHeading: false),
      page(l10n.familySoundEffectVolume, [
        _VolumeControl(
          key: const ValueKey('effect-volume'),
          label: l10n.familySoundEffectVolume,
          value: s.effectVolume,
          enabled: s.sound,
          onSaved: (value) => s.setting('effectVolume', '$value'),
        ),
      ]),
      page(l10n.familyShowItemLabels, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyShowItemLabels),
          value: s.showLabels,
          onChanged: (value) => s.setting('showLabels', '$value'),
        ),
      ], showHeading: false),
      page(l10n.familyReduceMotion, [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.familyReduceMotion),
          value: s.reducedMotion,
          onChanged: (value) => s.setting('reducedMotion', '$value'),
        ),
      ], showHeading: false),
      page(l10n.familyLanguage, [
        dropdown(
          s.locale,
          const [
            DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          (value) {
            if (value != null) s.setting('locale', value);
          },
        ),
      ]),
      page(l10n.familyCelebration, [
        dropdown(
          s.celebration,
          [
            DropdownMenuItem(value: 'full', child: Text(l10n.familyFull)),
            DropdownMenuItem(value: 'simple', child: Text(l10n.familySimple)),
            DropdownMenuItem(value: 'off', child: Text(l10n.familyOff)),
          ],
          (value) {
            if (value != null) s.setting('celebration', value);
          },
        ),
      ]),
      _feedbackCard(),
      page(l10n.familyPrivacy, [
        TextButton.icon(
          onPressed: () => context.go('/family/account'),
          icon: const Icon(Icons.account_circle_outlined),
          label: Text(l10n.familyGoogleFamilyAccount),
        ),
        TextButton(
          onPressed: () => context.go('/family/credits'),
          child: Text(l10n.familyCreditsAndLicenses),
        ),
      ]),
      page(l10n.familyPrivacy, [
        Text(l10n.familyProfilesAndRawGameRecordsStay, style: SegText.caption),
      ]),
      page(l10n.familyPrivacy, [
        Text(
          l10n.familyDoesNotReplaceProfessionalSupport,
          style: SegText.caption,
        ),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => s.touchFamily(),
    child: Scaffold(
      backgroundColor: SegColors.familyCanvas,
      body: SafeArea(
        // The bottom is the frosted bar's: lists scroll on beneath it.
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barSpace = MediaQuery.paddingOf(context).bottom;
            // Upright (the normal family orientation): one scrolling column.
            // Landscape keeps the paged sections built for short screens.
            final portrait = constraints.maxHeight > constraints.maxWidth;
            final compact =
                !portrait &&
                (constraints.maxHeight < 500 ||
                    MediaQuery.textScalerOf(context).scale(1) >= 1.6);
            final pages = _sectionPages(compact: compact, portrait: portrait);
            final gap = compact ? SegSpace.s1 : SegSpace.s5;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                gap,
                gap,
                gap,
                portrait ? 0 : gap + barSpace,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (s.profiles.length > 1)
                        Expanded(
                          child: DropdownButton<Profile>(
                            value: s.active,
                            items: s.profiles
                                .map(
                                  (profile) => DropdownMenuItem(
                                    value: profile,
                                    enabled: s.canSelectProfile(profile.id),
                                    child: Text(profile.nickname),
                                  ),
                                )
                                .toList(),
                            onChanged: (profile) {
                              if (profile != null) s.selectProfile(profile);
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            children: [
                              InitialAvatar(
                                name: s.active?.nickname ?? '',
                                size: 36,
                              ),
                              const SizedBox(width: SegSpace.s2),
                              Flexible(
                                child: Text(
                                  s.active?.nickname ?? '',
                                  style: SegText.label,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!portrait) ...[
                        Semantics(
                          liveRegion: true,
                          label: l10n.familySection,
                          child: Text(
                            '${sectionPage + 1} / ${pages.length}',
                            style: SegText.caption,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.familyPreviousSection,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: sectionPage <= 0
                              ? null
                              : () => _sectionController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                ),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          tooltip: l10n.familyNextSection,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: sectionPage >= pages.length - 1
                              ? null
                              : () => _sectionController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                ),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                      // A QA build must never look like a real subscription.
                      if (qaPremium)
                        Container(
                          key: const ValueKey('qa-premium-badge'),
                          margin: const EdgeInsets.only(right: SegSpace.s2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: SegSpace.s2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8B3),
                            borderRadius: BorderRadius.circular(SegRadius.pill),
                            border: Border.all(color: SegColors.starDeep),
                          ),
                          child: Text(
                            'TEST',
                            style: SegText.caption.copyWith(
                              color: SegColors.starDeep,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          visualDensity: VisualDensity.standard,
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        onPressed: () {
                          s.lockFamily();
                          context.go('/');
                        },
                        icon: const Icon(Icons.face_rounded),
                        label: Text(l10n.familyChildMode),
                      ),
                    ],
                  ),
                  if (portrait)
                    Expanded(
                      child: ListView.separated(
                        key: ValueKey('family-list-$tab'),
                        padding: EdgeInsets.only(
                          top: SegSpace.s3,
                          bottom: barSpace + SegSpace.s4,
                        ),
                        itemCount: pages.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: SegSpace.s4),
                        itemBuilder: (context, index) => Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: pages[index],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: PageView.builder(
                        key: ValueKey('family-tab-$tab'),
                        controller: _sectionController,
                        itemCount: pages.length,
                        onPageChanged: (index) =>
                            setState(() => sectionPage = index),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SegSpace.s1,
                            vertical: SegSpace.s1,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: pages[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      // The page runs on under the frosted bar.
      extendBody: true,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Short sideways screens keep their room; Settings › Premium is there.
          if (!s.entitlement.isPremium &&
              MediaQuery.sizeOf(context).height >= 600)
            _premiumStrip(),
          FamilyNavBar(
            selectedIndex: tab,
            onDestinationSelected: (i) {
              setState(() {
                tab = i;
                sectionPage = 0;
              });
              if (_sectionController.hasClients) {
                _sectionController.jumpToPage(0);
              }
            },
            items: [
              FamilyNavItem(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights_rounded,
                label: l10n.familyProgress,
              ),
              FamilyNavItem(
                icon: Icons.sports_esports_outlined,
                selectedIcon: Icons.sports_esports_rounded,
                label: l10n.familyGames,
              ),
              FamilyNavItem(
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded,
                label: l10n.familyProfiles,
              ),
              FamilyNavItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: l10n.familySettings,
              ),
            ],
          ),
        ],
      ),
    ),
  );
  List<Widget> _dashboard() {
    final now = DateTime.now();
    final report = LearningReport(s.trials, s.sessions, now);
    final week = report.trials;
    final independent = week.where(ReportDay.independent).length;
    _statIndex = 0;
    final weekMinutes = report.days.fold<double>(
      0,
      (sum, d) => sum + d.minutes,
    );
    final daysPlayed = report.days.where((d) => d.sessions.isNotEmpty).length;
    final todayRounds = s.sessions
        .where((x) => DateUtilsHelper.sameDay(x.startedAt, now) && x.completed)
        .length;
    return [
      GoalRing(state: s, minutes: report.days.last.minutes),
      LayoutBuilder(
        builder: (context, box) {
          final tile = (box.maxWidth - SegSpace.s3) / 2;
          return Wrap(
            spacing: SegSpace.s3,
            runSpacing: SegSpace.s3,
            children: [
              SizedBox(
                width: box.maxWidth,
                child: _stat('${s.dayStreak}', l10n.famDayStreak),
              ),
              for (final (value, label) in [
                ('${s.todayStars}', l10n.familyStarsToday),
                ('$todayRounds', l10n.familyRoundsCompletedToday),
                ('${weekMinutes.floor()}', l10n.famMinutesThisWeek),
                ('$daysPlayed / 7', l10n.famDaysPlayed),
                ('${week.length}', l10n.familyStagesThisWeek),
                (
                  week.isEmpty
                      ? '—'
                      : '${(100 * independent / week.length).round()}%',
                  l10n.familyIndependentAnswers,
                ),
              ])
                SizedBox(width: tile, child: _stat(value, label)),
            ],
          );
        },
      ),
      SegCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.famThisWeek, style: SegText.heading),
            const SizedBox(height: SegSpace.s3),
            _WeekStrip(report: report, locale: s.locale),
          ],
        ),
      ),
      _recentCard(),
      _premiumOnly(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WeeklyCharts(state: s, report: report),
            const SizedBox(height: SegSpace.s5),
            AttentionChart(state: s, report: report),
            const SizedBox(height: SegSpace.s5),
            SkillsCard(state: s, report: report),
            const SizedBox(height: SegSpace.s5),
            ItemInsights(state: s),
            const SizedBox(height: SegSpace.s5),
            _themeProgress(week),
          ],
        ),
      ),
    ];
  }

  Widget _themeProgress(List<Trial> week) => SegCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.familyProgressByTheme, style: SegText.heading),
        ...s.content.themes.map((theme) {
          final data = week.where((t) => t.themeId == theme.id).toList();
          final rate = data.isEmpty
              ? 0.0
              : data.where(ReportDay.independent).length / data.length;
          return Padding(
            padding: const EdgeInsets.only(top: SegSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${theme.name(s.locale)} · ${data.length}'),
                const SizedBox(height: SegSpace.s2),
                LinearProgressIndicator(
                  value: rate,
                  color: SegColors.primary,
                  backgroundColor: SegColors.line,
                  minHeight: 8,
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );

  static const _statTints = [
    (Color(0xFFFFF4D6), SegColors.starDeep, Icons.star_rounded),
    (Color(0xFFDDF6F3), SegColors.turquoiseDeep, Icons.check_circle_rounded),
    (Color(0xFFE5F4FF), SegColors.primaryDeep, Icons.schedule_rounded),
    (Color(0xFFEDEBFF), Color(0xFF5A50B8), Icons.stairs_rounded),
    (Color(0xFFFFEBDD), SegColors.accentDeep, Icons.emoji_events_rounded),
  ];
  int _statIndex = 0;

  /// A tinted tile: icon, big number, short label. Two per row on phones.
  Widget _stat(String value, String label) {
    final (fill, ink, icon) = _statTints[_statIndex++ % _statTints.length];
    return Container(
      padding: const EdgeInsets.all(SegSpace.s3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(SegRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ink, size: 22),
          const SizedBox(height: SegSpace.s1),
          Text(value, style: SegText.title.copyWith(color: ink)),
          Text(label, style: SegText.caption.copyWith(color: SegColors.ink)),
        ],
      ),
    );
  }

  /// Chips for the games played and the items answered on their own lately.
  Widget _recentCard() {
    final games = <String>[];
    for (final session in s.sessions.reversed) {
      final name =
          '${s.content.game(session.gameId).name(s.locale)} · '
          '${s.content.theme(session.themeId).name(s.locale)}';
      if (!games.contains(name)) games.add(name);
      if (games.length == 5) break;
    }
    final learned = <String>[];
    for (final trial in s.trials.reversed) {
      if (trial.wrongCount > 0 || trial.maxHint > 0) continue;
      final item = s.content.items.where((x) => x.id == trial.targetId);
      if (item.isEmpty) continue;
      final name = item.first.name(s.locale);
      if (!learned.contains(name)) learned.add(name);
      if (learned.length == 8) break;
    }
    Widget chips(List<String> values) => values.isEmpty
        ? Text(
            l10n.famNothingYet,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          )
        : Wrap(
            spacing: SegSpace.s2,
            runSpacing: SegSpace.s2,
            children: [
              for (final value in values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SegSpace.s3,
                    vertical: SegSpace.s1,
                  ),
                  decoration: BoxDecoration(
                    color: SegColors.familyCanvas,
                    borderRadius: BorderRadius.circular(SegRadius.pill),
                    border: Border.all(color: SegColors.line),
                  ),
                  child: Text(value, style: SegText.label),
                ),
            ],
          );
    return SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.famRecentlyPlayed, style: SegText.heading),
          const SizedBox(height: SegSpace.s3),
          chips(games),
          const SizedBox(height: SegSpace.s5),
          Text(l10n.famRecentlyLearned, style: SegText.heading),
          const SizedBox(height: SegSpace.s3),
          chips(learned),
        ],
      ),
    );
  }

  List<Widget> _games() => [
    if (!_canChooseGames) _gamesPremiumCard(),
    for (final theme in s.content.themes)
      if (s.allGamesForTheme(theme.id).isNotEmpty) _themeGames(theme.id),
  ];

  /// Choosing games is Premium (the free trial included).
  bool get _canChooseGames => s.entitlement.isPremium;

  Widget _gamesPremiumCard() => SegCard(
    key: const ValueKey('games-premium-card'),
    padding: const EdgeInsets.all(SegSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune_rounded, color: SegColors.accentDeep),
            const SizedBox(width: SegSpace.s2),
            Expanded(
              child: Text(
                l10n.familyGamesPremiumTitle,
                style: SegText.label.copyWith(color: SegColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: SegSpace.s1),
        Text(
          l10n.familyGamesPremiumBody,
          style: SegText.caption.copyWith(color: SegColors.inkSoft),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/family/subscription'),
            child: Text(l10n.familyPremiumStripBuy),
          ),
        ),
      ],
    ),
  );

  /// One theme: a header with a switch for all of its games; tap to open the
  /// single games.
  Widget _themeGames(String themeId) {
    final theme = s.content.theme(themeId);
    final games = s.allGamesForTheme(themeId);
    final shown = games
        .where((g) => !s.hiddenGames.contains('${themeId}_$g'))
        .length;
    final editable = _canChooseGames && s.familyUnlocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: SegSpace.s3),
      child: SegCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('games-$themeId'),
            tilePadding: const EdgeInsets.fromLTRB(
              SegSpace.s4,
              SegSpace.s1,
              SegSpace.s2,
              SegSpace.s1,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              SegSpace.s4,
              0,
              SegSpace.s2,
              SegSpace.s2,
            ),
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(theme.name(s.locale), style: SegText.heading),
            subtitle: Text(
              l10n.familyGamesShownCount(shown, games.length),
              style: SegText.caption.copyWith(color: SegColors.inkSoft),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  key: ValueKey('theme-switch-$themeId'),
                  value: shown > 0,
                  onChanged: editable
                      ? (value) => s.setThemeShown(themeId, value)
                      : null,
                ),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
            children: [for (final id in games) _gameSwitch(themeId, id)],
          ),
        ),
      ),
    );
  }

  /// One game of a theme: shown to the child or not (per profile).
  Widget _gameSwitch(String theme, String id) {
    final shown = !s.hiddenGames.contains('${theme}_$id');
    return SwitchListTile(
      key: ValueKey('game-switch-${theme}_$id'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        s.content.game(id).name(s.locale),
        style: SegText.body.copyWith(
          color: shown ? SegColors.ink : SegColors.inkSoft,
        ),
      ),
      value: shown,
      onChanged: _canChooseGames && s.familyUnlocked
          ? (value) => s.setGameShown(theme, id, value)
          : null,
    );
  }

  List<Widget> _profiles() => [
    _accountCard(),
    const SizedBox(height: SegSpace.s2),
    SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: SegSpace.s1, top: SegSpace.s2),
        child: Text(l10n.familyProfiles, style: SegText.heading),
      ),
    ),
    ...s.profiles.map(
      (profile) => SegCard(
        child: ListTile(
          title: Text(profile.nickname, style: SegText.heading),
          leading: InitialAvatar(name: profile.nickname, size: 44),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profile.id == s.active?.id)
                const Icon(
                  Icons.check_circle_rounded,
                  color: SegColors.primary,
                ),
              if (!s.canSelectProfile(profile.id))
                const Icon(Icons.lock_outline_rounded),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    context.go('/family/profile/${profile.id}');
                    return;
                  }
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                      child: SizedBox(
                        width: 520,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 720,
                            maxHeight:
                                MediaQuery.sizeOf(dialogContext).height - 24,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SegSpace.s2,
                              vertical: SegSpace.s1,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.familyDeleteProfile,
                                  style: SegText.heading,
                                ),
                                const SizedBox(height: SegSpace.s1),
                                Text(
                                  l10n.familyGameAndProgressRecordsForName(
                                    profile.nickname,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      style: _dialogButtonStyle,
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(l10n.familyCancel),
                                    ),
                                    TextButton(
                                      style: _dialogButtonStyle,
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(l10n.familyDelete),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  if (confirmed == true && s.familyUnlocked) {
                    await s.deleteProfile(profile.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l10n.familyEditAndQuestionnaire),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.familyDeleteProfile),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            if (s.canSelectProfile(profile.id)) {
              s.selectProfile(profile);
            } else {
              context.go('/family/subscription');
            }
          },
        ),
      ),
    ),
    const SizedBox(height: SegSpace.s2),
    if (s.profiles.length < s.profileLimit)
      SegButton(
        key: const ValueKey('profile-add'),
        label: l10n.familyProfileAction(0),
        icon: Icons.person_add_alt_rounded,
        secondary: true,
        onPressed: () => context.go('/family/profile/new'),
      )
    else if (s.profileLimit == 1)
      SegCard(
        key: const ValueKey('profile-add-premium'),
        padding: const EdgeInsets.all(SegSpace.s4),
        child: Row(
          children: [
            const Icon(Icons.group_add_rounded, color: SegColors.accentDeep),
            const SizedBox(width: SegSpace.s3),
            Expanded(
              child: Text(
                l10n.familyMoreProfilesPremium,
                style: SegText.label.copyWith(color: SegColors.ink),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/family/subscription'),
              child: Text(l10n.familyPremiumStripBuy),
            ),
          ],
        ),
      ),
  ];

  /// Settings › "Send feedback": opens the feedback page. Full width like
  /// the other settings cards.
  Widget _feedbackCard() => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: double.infinity),
    child: SegCard(
      child: InkWell(
        key: const ValueKey('settings-feedback'),
        borderRadius: BorderRadius.circular(SegRadius.lg),
        onTap: () {
          UiSound.tap();
          context.go('/family/feedback');
        },
        child: Row(
          children: [
            Expanded(child: Text(l10n.feedbackTitle, style: SegText.heading)),
            const Icon(Icons.chevron_right_rounded, color: SegColors.inkSoft),
          ],
        ),
      ),
    ),
  );

  /// What the family has: plan, how it was paid, trial days, and the way to
  /// manage or upgrade.
  Widget _accountCard() {
    final e = s.entitlement;
    final (plan, payment) = switch (e.source) {
      PremiumSource.subscription => (
        l10n.familyPlanSubscription,
        l10n.familyPaymentPlay,
      ),
      PremiumSource.lifetime => (
        l10n.familyPlanLifetime,
        l10n.familyPaymentPlay,
      ),
      PremiumSource.trial => (
        l10n.familyPlanTrial(e.trialDaysLeft),
        l10n.familyPaymentTrial,
      ),
      PremiumSource.qa => (l10n.familyPlanTest, l10n.familyPaymentNone),
      PremiumSource.granted => (l10n.familyPlanGranted, l10n.familyPaymentNone),
      PremiumSource.none => (l10n.familyPlanFree, l10n.familyPaymentNone),
    };
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: SegSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: SegText.caption.copyWith(color: SegColors.inkSoft),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: SegText.label.copyWith(color: SegColors.ink),
            ),
          ),
        ],
      ),
    );
    final ends = e.trialEndsAt;
    // On a short sideways page the card shrinks instead of overflowing.
    return LayoutBuilder(
      builder: (context, box) {
        final card = _planCard(plan, payment, ends, row);
        return box.hasBoundedHeight
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(width: box.maxWidth, child: card),
              )
            : card;
      },
    );
  }

  Widget _planCard(
    String plan,
    String payment,
    DateTime? ends,
    Widget Function(String, String) row,
  ) {
    final e = s.entitlement;
    return SegCard(
      key: const ValueKey('family-account-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.auth?.account case final account?)
            AccountHeader(account: account, premium: e.isPremium)
          else
            Row(
              children: [
                Icon(
                  e.isPremium
                      ? Icons.workspace_premium_rounded
                      : Icons.account_circle_outlined,
                  color: e.isPremium
                      ? SegColors.accentStrong
                      : SegColors.primaryDeep,
                ),
                const SizedBox(width: SegSpace.s2),
                Text(l10n.familyPlanCardTitle, style: SegText.heading),
              ],
            ),
          row(l10n.familyAccountPlan, plan),
          row(l10n.familyAccountPayment, payment),
          if (e.source == PremiumSource.trial && ends != null)
            Padding(
              padding: const EdgeInsets.only(top: SegSpace.s2),
              child: Text(
                l10n.familyPlanTrialEnds(
                  DateFormat.yMMMMd(s.locale).format(ends),
                ),
                style: SegText.caption.copyWith(color: SegColors.inkSoft),
              ),
            ),
          const SizedBox(height: SegSpace.s4),
          if (e.source == PremiumSource.subscription)
            SegButton(
              label: l10n.subscriptionManage,
              icon: Icons.settings_rounded,
              secondary: true,
              onPressed: () => context.go('/family/subscription'),
            )
          else if (e.source == PremiumSource.none ||
              e.source == PremiumSource.trial)
            SegButton(
              key: const ValueKey('family-account-premium'),
              label: e.trialUsed
                  ? l10n.familyPremiumStripBuy
                  : l10n.paywallStartTrial(e.trialDays),
              icon: Icons.workspace_premium_rounded,
              onPressed: () => context.go('/family/subscription'),
            ),
          const SizedBox(height: SegSpace.s2),
          SegButton(
            key: const ValueKey('family-account-details'),
            label: l10n.familyAccountDetails,
            icon: Icons.chevron_right_rounded,
            secondary: true,
            onPressed: () => context.go('/family/account'),
          ),
        ],
      ),
    );
  }

  List<Widget> _settings() => [
    SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.familyDailyScreenTimeLimit, style: SegText.item),
          Text(
            l10n.familyCountsActivePlayTimeABreak,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
          DropdownButton<int>(
            isExpanded: true,
            value: s.screenLimitMinutes,
            items: [
              for (final minutes in [0, 10, 15, 20, 30])
                DropdownMenuItem(
                  value: minutes,
                  child: Text(
                    minutes == 0
                        ? l10n.familyOff
                        : '$minutes ${l10n.familyMinutes}',
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) s.setting('screenLimitMinutes', '$value');
            },
          ),
          if (s.screenLimitMinutes > 0) ...[
            Text(
              l10n.familyRemainingTodayMinutesMinutes(
                (s.playTimeRemainingMs / 60000).ceil(),
              ),
            ),
            TextButton(
              onPressed: s.extendPlayTime,
              child: Text(l10n.familyAdd10MinutesForToday),
            ),
          ],
        ],
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.familyAgeLevel, style: SegText.label),
          ..._ageLevelControls(),
        ],
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.familyDefaultDifficulty, style: SegText.item),
          DropdownButton<String>(
            isExpanded: true,
            value: s.difficultyOverride == 'hard' && !s.entitlement.isPremium
                ? 'auto'
                : s.difficultyOverride,
            items: [
              DropdownMenuItem(
                value: 'auto',
                child: Text(l10n.familyAutomaticThemeSelection),
              ),
              DropdownMenuItem(value: 'easy', child: Text(l10n.familyEasy)),
              DropdownMenuItem(value: 'medium', child: Text(l10n.familyMedium)),
              if (s.entitlement.isPremium)
                DropdownMenuItem(value: 'hard', child: Text(l10n.familyHard)),
            ],
            onChanged: (value) {
              if (value != null) s.setting('difficultyOverride', value);
            },
          ),
          Text(
            l10n.familyAppliesToNewRoundsHardLevel,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
        ],
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.familyRoundLength, style: SegText.item),
          DropdownButton<int>(
            isExpanded: true,
            value: s.roundLength,
            items: [
              for (final value in [0, 3, 5, 8, 10])
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    value == 0
                        ? l10n.familySurveyDifficultySetting
                        : '$value ${l10n.familyStages}',
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) s.setting('roundLength', '$value');
            },
          ),
          const SizedBox(height: SegSpace.s5),
          Text(l10n.familyHintDelay, style: SegText.item),
          DropdownButton<int>(
            isExpanded: true,
            value: s.hintSeconds,
            items: [
              for (final value in [-1, 0, 4, 6, 10])
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    value == -1
                        ? l10n.familyAutomaticPerItem
                        : value == 0
                        ? l10n.familyTimedHintsOff
                        : '$value ${l10n.familySeconds}',
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) s.setting('hintSeconds', '$value');
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyFadeIncorrectChoicesAfter2Mistakes),
            value: s.fadeWrongChoices,
            onChanged: (value) => s.setting('fadeWrongChoices', '$value'),
          ),
          Text(
            l10n.familyAppliesToTheNextRoundIncorrect,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
        ],
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const ValueKey('cloud-sync-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyCloudSync, style: SegText.item),
            value: s.cloudSync,
            onChanged: (value) => s.setting('cloudSync', '$value'),
          ),
          Text(
            l10n.familyCloudSyncNote,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
        ],
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.familyDailyMinuteGoal),
        subtitle: Text(
          l10n.familyAnOptionalReminderItDoesNot,
          style: SegText.caption.copyWith(color: SegColors.inkSoft),
        ),
        trailing: DropdownButton<int>(
          value: s.dailyGoalMinutes,
          items: [
            for (final value in [0, 10, 15, 20, 30])
              DropdownMenuItem(
                value: value,
                child: Text(
                  value == 0 ? l10n.familyOff : '$value ${l10n.familyMin}',
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) s.setting('dailyGoalMinutes', '$value');
          },
        ),
      ),
    ),
    if (PlayReminder.supported) ...[
      const SizedBox(height: SegSpace.s5),
      SegCard(child: _reminderControls()),
    ],
    const SizedBox(height: SegSpace.s5),
    if (s.configuration.minSupportedVersion > 14) ...[
      SegCard(
        child: Text(l10n.familyANewVersionIsAvailableYou, style: SegText.item),
      ),
      const SizedBox(height: SegSpace.s5),
    ],
    SegCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_outline_rounded),
        title: Text(l10n.familyParentGate),
        subtitle: Text(
          s.hasParentPin
              ? l10n.family4DigitPin
              : l10n.familyMultiplicationQuestion,
        ),
        onTap: _editPin,
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyIntroduceNewItemsFirst),
            subtitle: Text(
              l10n.familyShowOneCardFirstThenOffer,
              style: SegText.caption.copyWith(color: SegColors.inkSoft),
            ),
            value: s.introduction,
            onChanged: (v) => s.setting('introduction', '$v'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyAdaptiveDifficulty),
            subtitle: Text(
              l10n.familyChangesApplyOnlyWhenANew,
              style: SegText.caption.copyWith(color: SegColors.inkSoft),
            ),
            value: s.automaticDifficulty,
            onChanged: (v) => s.setting('automaticDifficulty', '$v'),
          ),
        ],
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyAudio),
            value: s.sound,
            onChanged: (v) => s.setting('sound', '$v'),
          ),
          _VolumeControl(
            key: const ValueKey('speech-volume'),
            label: l10n.familySpeechVolume,
            value: s.speechVolume,
            enabled: s.sound,
            onSaved: (value) => s.setting('speechVolume', '$value'),
          ),
          _VolumeControl(
            key: const ValueKey('effect-volume'),
            label: l10n.familySoundEffectVolume,
            value: s.effectVolume,
            enabled: s.sound,
            onSaved: (value) => s.setting('effectVolume', '$value'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyShowItemLabels),
            value: s.showLabels,
            onChanged: (v) => s.setting('showLabels', '$v'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyReduceMotion),
            value: s.reducedMotion,
            onChanged: (v) => s.setting('reducedMotion', '$v'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyLanguage),
            trailing: DropdownButton<String>(
              value: s.locale,
              items: const [
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) s.setting('locale', v);
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.familyCelebration),
            trailing: DropdownButton<String>(
              value: s.celebration,
              items: [
                DropdownMenuItem(value: 'full', child: Text(l10n.familyFull)),
                DropdownMenuItem(
                  value: 'simple',
                  child: Text(l10n.familySimple),
                ),
                DropdownMenuItem(value: 'off', child: Text(l10n.familyOff)),
              ],
              onChanged: (v) {
                if (v != null) s.setting('celebration', v);
              },
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: SegSpace.s5),
    _feedbackCard(),
    const SizedBox(height: SegSpace.s5),
    SegCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.familyPrivacy, style: SegText.heading),
          TextButton.icon(
            onPressed: () => context.go('/family/account'),
            icon: const Icon(Icons.account_circle_outlined),
            label: Text(l10n.familyGoogleFamilyAccount),
          ),
          TextButton(
            onPressed: () => context.go('/family/credits'),
            child: Text(l10n.familyCreditsAndLicenses),
          ),
          const SizedBox(height: SegSpace.s4),
          Text(
            l10n.familyProfilesAndRawGameRecordsStay,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
          const SizedBox(height: SegSpace.s4),
          Text(
            l10n.familyDoesNotReplaceProfessionalSupport,
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
        ],
      ),
    ),
  ];
}

/// Seven day dots for the last week; filled where the child played.
class _WeekStrip extends StatelessWidget {
  final LearningReport report;
  final String locale;
  const _WeekStrip({required this.report, required this.locale});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final day in report.days)
        Expanded(
          child: Column(
            children: [
              Text(
                DateFormat.E(locale).format(day.date),
                textAlign: TextAlign.center,
                style: SegText.caption.copyWith(color: SegColors.inkSoft),
              ),
              const SizedBox(height: SegSpace.s1),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.sessions.isNotEmpty
                      ? SegColors.turquoise
                      : SegColors.familyCanvas,
                  border: Border.all(color: SegColors.line),
                ),
                child: day.sessions.isNotEmpty
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
    ],
  );
}
