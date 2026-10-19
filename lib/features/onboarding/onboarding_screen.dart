import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/learning/policies.dart';
import '../../core/content/content_repository.dart';
import 'survey_questions.dart';
import 'survey_options.dart';
import 'welcome_pane.dart';
import '../../l10n/scoped_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final AppState state;
  const OnboardingScreen({super.key, required this.state});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int page = 0;
  String avatar = 'cat';
  final name = TextEditingController();
  final answers = <String, dynamic>{};
  bool saving = false;
  AppState get s => widget.state;
  final questions = surveyQuestions;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final result = SurveyMapper.map(answers);
      await s.createProfile(name.text.trim(), avatar, answers);
      await s.setting('celebration', result.celebration);
      if (answers['sound'] == 0) await s.setting('sound', 'false');
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        final l10n = scopedLocalizations(context, s.locale);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.onboardingSaveError)));
      }
    }
  }

  Widget _recommendationCard(String themeId, {required bool compact}) {
    final theme = s.content.theme(themeId);
    final level = SurveyMapper.initialForTheme(answers, themeId);
    return Container(
      key: ValueKey('final-recommendation-$themeId'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? SegSpace.s3 : SegSpace.s4,
        vertical: compact ? SegSpace.s1 : SegSpace.s2,
      ),
      decoration: BoxDecoration(
        color: SegColors.surface,
        borderRadius: BorderRadius.circular(SegRadius.lg),
        border: Border.all(color: SegColors.line, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            color: SegColors.primary,
            size: compact ? 24 : 32,
          ),
          SizedBox(width: compact ? SegSpace.s2 : SegSpace.s3),
          Expanded(
            child: Text(
              theme.name(s.locale),
              style: compact ? SegText.label : SegText.item,
            ),
          ),
          const SizedBox(width: SegSpace.s2),
          Text(
            level.label(s.locale),
            style: compact ? SegText.label : SegText.caption,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _recommendationPager() {
    const themeIds = ['animals', 'vehicles', 'colors'];
    return _RecommendationPager(
      locale: s.locale,
      themeIds: themeIds,
      recommendationCard: (id) => _recommendationCard(id, compact: true),
    );
  }

  Widget _buildFinalPage() {
    const themeIds = ['animals', 'vehicles', 'colors'];
    final l10n = scopedLocalizations(context, s.locale);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 500;
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final usePager = compact && textScale >= 1.4;
            final pad = compact ? SegSpace.s1 : SegSpace.s5;
            final gap = compact ? SegSpace.s1 : SegSpace.s4;
            final title = Text(
              l10n.onboardingReadyTitle(name.text),
              key: const ValueKey('final-ready-title'),
              style: compact ? SegText.heading : SegText.display,
            );
            final suggested = Text(
              l10n.onboardingSuggestedStart,
              key: const ValueKey('final-suggested-title'),
              style: compact ? SegText.body : SegText.heading,
            );
            final familyHint = Text(
              l10n.onboardingFamilyHint,
              key: const ValueKey('final-family-hint'),
              style: compact ? SegText.label : SegText.body,
            );
            final play = SegButton(
              key: const ValueKey('final-play'),
              label: saving ? l10n.onboardingSaving : l10n.onboardingPlay,
              onPressed: saving ? null : finish,
            );

            if (!compact && constraints.maxWidth >= 900) {
              return Padding(
                padding: EdgeInsets.all(pad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              title,
                              SizedBox(height: gap),
                              familyHint,
                              SizedBox(height: gap),
                              play,
                            ],
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              suggested,
                              const SizedBox(height: SegSpace.s3),
                              for (var i = 0; i < themeIds.length; i++) ...[
                                if (i > 0) const SizedBox(height: SegSpace.s2),
                                _recommendationCard(
                                  themeIds[i],
                                  compact: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      SizedBox(height: gap),
                      suggested,
                      SizedBox(height: gap),
                      if (usePager)
                        Expanded(child: _recommendationPager())
                      else
                        for (var i = 0; i < themeIds.length; i++) ...[
                          if (i > 0) const SizedBox(height: SegSpace.s1),
                          _recommendationCard(themeIds[i], compact: true),
                        ],
                      SizedBox(height: gap),
                      familyHint,
                      SizedBox(height: gap),
                      play,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSurveyPage(SurveyQuestion question) {
    final l10n = scopedLocalizations(context, s.locale);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 500;
            final pad = compact ? SegSpace.s1 : SegSpace.s5;
            final gap = compact ? SegSpace.s1 : SegSpace.s3;
            final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
            if (constraints.maxHeight < 480 && largeText) {
              return Padding(
                padding: EdgeInsets.all(pad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: (page - 1) / questions.length,
                                  color: SegColors.primary,
                                  backgroundColor: SegColors.line,
                                ),
                              ),
                              const SizedBox(width: SegSpace.s2),
                              Text(
                                l10n.onboardingStepCount(
                                  page - 1,
                                  questions.length,
                                ),
                                style: SegText.caption,
                              ),
                            ],
                          ),
                          SizedBox(height: gap),
                          Expanded(
                            child: Center(
                              child: Text(
                                s.locale == 'tr' ? question.tr : question.en,
                                style: SegText.title,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: SurveyOptions(
                              key: ValueKey(
                                'survey-${question.key}-${s.locale}',
                              ),
                              question: question,
                              locale: s.locale,
                              value: answers[question.key],
                              reducedMotion: s.reducedMotion,
                              onChanged: (value) {
                                setState(() => answers[question.key] = value);
                                if (!question.multiple && mounted) {
                                  setState(() => page++);
                                }
                              },
                            ),
                          ),
                          SizedBox(height: gap),
                          if (question.multiple)
                            Row(
                              children: [
                                Expanded(
                                  child: SegButton(
                                    label: l10n.onboardingContinue,
                                    onPressed: () => setState(() {
                                      answers.putIfAbsent(
                                        question.key,
                                        () => [],
                                      );
                                      page++;
                                    }),
                                  ),
                                ),
                                SizedBox(width: gap),
                                Expanded(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                      visualDensity: VisualDensity.standard,
                                      tapTargetSize:
                                          MaterialTapTargetSize.padded,
                                    ),
                                    onPressed: () => setState(() => page++),
                                    child: Text(l10n.onboardingSkipQuestion),
                                  ),
                                ),
                              ],
                            )
                          else
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  visualDensity: VisualDensity.standard,
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                ),
                                onPressed: () => setState(() => page++),
                                child: Text(l10n.onboardingSkipQuestion),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.all(pad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (page - 1) / questions.length,
                              color: SegColors.primary,
                              backgroundColor: SegColors.line,
                            ),
                          ),
                          const SizedBox(width: SegSpace.s2),
                          Text(
                            l10n.onboardingStepCount(
                              page - 1,
                              questions.length,
                            ),
                            style: SegText.caption,
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      Text(
                        s.locale == 'tr' ? question.tr : question.en,
                        style: SegText.title,
                      ),
                      SizedBox(height: gap),
                      Expanded(
                        child: SurveyOptions(
                          key: ValueKey('survey-${question.key}-${s.locale}'),
                          question: question,
                          locale: s.locale,
                          value: answers[question.key],
                          reducedMotion: s.reducedMotion,
                          onChanged: (value) {
                            setState(() => answers[question.key] = value);
                            if (!question.multiple && mounted) {
                              setState(() => page++);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: gap),
                      if (question.multiple)
                        Row(
                          children: [
                            Expanded(
                              child: SegButton(
                                label: l10n.onboardingContinue,
                                onPressed: () => setState(() {
                                  answers.putIfAbsent(question.key, () => []);
                                  page++;
                                }),
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  visualDensity: VisualDensity.standard,
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                ),
                                onPressed: () => setState(() => page++),
                                child: Text(l10n.onboardingSkipQuestion),
                              ),
                            ),
                          ],
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              visualDensity: VisualDensity.standard,
                              tapTargetSize: MaterialTapTargetSize.padded,
                            ),
                            onPressed: () => setState(() => page++),
                            child: Text(l10n.onboardingSkipQuestion),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    final l10n = scopedLocalizations(context, s.locale);
    final avatars = ['cat', 'dog', 'rabbit', 'bear'];
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewH = constraints.maxHeight;
            final viewW = constraints.maxWidth;
            final compact = viewH < 480;
            final tight = viewH < 560;
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final wide = viewW >= 1000 || (viewW >= 700 && textScale >= 2);
            final pad = compact ? SegSpace.s1 : SegSpace.s6;
            final gap = compact || (keyboardOpen && tight)
                ? SegSpace.s1
                : SegSpace.s2;
            final tile = viewH >= 640
                ? 88.0
                : viewH >= 520
                ? 72.0
                : viewH >= 440
                ? 64.0
                : 48.0;
            final showDecor = !keyboardOpen;
            final textField = TextField(
              controller: name,
              maxLength: 24,
              maxLines: 1,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.onboardingNickname),
              onChanged: (_) => setState(() {}),
            );
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDecor) ...[
                  Text(l10n.onboardingProfileQuestion, style: SegText.title),
                  const SizedBox(height: SegSpace.s3),
                  Text(l10n.onboardingNicknameHint),
                ],
                if (showDecor) const SizedBox(height: SegSpace.s3),
                textField,
              ],
            );
            final avatarRow = Wrap(
              spacing: SegSpace.s2,
              runSpacing: SegSpace.s2,
              alignment: WrapAlignment.start,
              children: [for (final a in avatars) _avatarTile(a, tile)],
            );
            final continueBtn = SegButton(
              label: l10n.onboardingContinue,
              onPressed: name.text.trim().isEmpty
                  ? null
                  : () => setState(() => page = 2),
            );

            if (textScale >= 2 && viewW < 1000) {
              return Padding(
                padding: EdgeInsets.all(pad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDecor) ...[
                          Text(
                            l10n.onboardingProfileQuestion,
                            style: SegText.title,
                          ),
                          const SizedBox(height: SegSpace.s1),
                          Text(l10n.onboardingNicknameHint),
                          SizedBox(height: gap),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: textField),
                            SizedBox(width: gap),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  avatarRow,
                                  SizedBox(height: gap),
                                  continueBtn,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (wide) {
              return Padding(
                padding: EdgeInsets.all(pad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              heading,
                              SizedBox(height: gap),
                              continueBtn,
                            ],
                          ),
                        ),
                        SizedBox(width: gap),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [avatarRow],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      heading,
                      SizedBox(height: gap),
                      avatarRow,
                      SizedBox(height: gap),
                      continueBtn,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _avatarTile(String a, [double size = 88]) {
    return Semantics(
      label: a,
      selected: avatar == a,
      button: true,
      child: InkWell(
        onTap: () => setState(() => avatar = a),
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size >= 72 ? SegSpace.s3 : SegSpace.s2),
          decoration: BoxDecoration(
            color: avatar == a ? SegColors.primarySoft : SegColors.surface,
            borderRadius: BorderRadius.circular(SegRadius.lg),
            border: Border.all(
              color: avatar == a ? SegColors.primary : SegColors.line,
              width: 2,
            ),
          ),
          child: ItemVisual(
            s.content.items.firstWhere((x) => x.id == 'animals.$a'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (page == 0) {
      return WelcomePane(state: s, onContinue: () => setState(() => page = 1));
    } else if (page == 1) {
      return _buildNamePage();
    } else if (page < questions.length + 2) {
      final q = questions[page - 2];
      return _buildSurveyPage(q);
    } else {
      return _buildFinalPage();
    }
  }
}

class _RecommendationPager extends StatefulWidget {
  final String locale;
  final List<String> themeIds;
  final Widget Function(String id) recommendationCard;

  const _RecommendationPager({
    required this.locale,
    required this.themeIds,
    required this.recommendationCard,
  });

  @override
  State<_RecommendationPager> createState() => _RecommendationPagerState();
}

class _RecommendationPagerState extends State<_RecommendationPager> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = scopedLocalizations(context, widget.locale);
    return PageView.builder(
      key: const ValueKey('final-recommendations-pager'),
      controller: _controller,
      itemCount: widget.themeIds.length,
      onPageChanged: (index) => setState(() => _index = index),
      itemBuilder: (context, index) => Row(
        children: [
          IconButton(
            tooltip: l10n.onboardingPreviousRecommendation,
            onPressed: _index == 0
                ? null
                : () => _controller.previousPage(
                    duration: SegMotion.pageSlide,
                    curve: Curves.easeOutCubic,
                  ),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: widget.recommendationCard(widget.themeIds[index]),
            ),
          ),
          IconButton(
            tooltip: l10n.onboardingNextRecommendation,
            onPressed: _index == widget.themeIds.length - 1
                ? null
                : () => _controller.nextPage(
                    duration: SegMotion.pageSlide,
                    curve: Curves.easeOutCubic,
                  ),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
