import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/initial_avatar.dart';
import '../../app/ui/page_navigation.dart';
import '../../core/learning/policies.dart';
import '../../core/content/content_repository.dart';
import '../onboarding/survey_questions.dart';
import '../onboarding/onboarding_parts.dart';
import '../onboarding/survey_options.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';

class ProfileEditorScreen extends StatefulWidget {
  final AppState state;
  final String? profileId;
  const ProfileEditorScreen({super.key, required this.state, this.profileId});
  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final name = TextEditingController();
  final answers = <String, dynamic>{};
  String avatar = 'cat', error = '';
  int page = 0;
  int recommendationPage = 0;
  bool saving = false;
  final PageController _recommendations = PageController();
  AppState get s => widget.state;
  AppLocalizations get l10n => scopedLocalizations(context, s.locale);
  bool get editing => widget.profileId != null;
  @override
  void initState() {
    super.initState();
    final profile = s.profiles
        .where((p) => p.id == widget.profileId)
        .firstOrNull;
    if (profile != null) {
      name.text = profile.nickname;
      avatar = profile.avatar;
      answers.addAll(jsonDecode(profile.payload));
    }
  }

  @override
  void dispose() {
    name.dispose();
    _recommendations.dispose();
    super.dispose();
  }

  void _goToPage(int next) {
    FocusScope.of(context).unfocus();
    setState(() {
      page = next;
      error = '';
    });
  }

  Future<void> save() async {
    if (!s.familyUnlocked || saving) return;
    if (name.text.trim().isEmpty) {
      setState(() => error = l10n.profileEditorNameRequired);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      error = '';
    });
    try {
      if (editing) {
        await s.updateProfile(widget.profileId!, name.text, avatar, answers);
      } else {
        await s.createProfile(name.text, avatar, answers);
      }
      if (mounted) context.go('/family');
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = l10n.profileEditorSaveFailed;
        });
      }
    }
  }

  String get _title => page == 0
      ? editing
            ? l10n.profileEditorEditTitle
            : l10n.profileEditorNewTitle
      : page <= surveyQuestions.length
      ? l10n.profileEditorStartSurvey
      : l10n.profileEditorSuggestedStart;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => s.touchFamily(),
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: SegColors.familyCanvas,
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          onPressed: () {
            UiSound.tap();
            context.go('/family');
          },
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.all(SegSpace.s2),
              child: Column(
                children: [
                  Expanded(child: _pageBody()),
                  const SizedBox(height: SegSpace.s2),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _pageBody() {
    if (page == 0) return _profilePage();
    if (page <= surveyQuestions.length) return _questionPage();
    return _recommendationPage();
  }

  Widget _profilePage() => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final avatarSize = _portrait
          ? 96.0
          : constraints.maxHeight < 240 || textScale >= 1.6
          ? 64.0
          : 84.0;
      final heading = Padding(
        padding: const EdgeInsets.symmetric(horizontal: SegSpace.s2),
        child: Text(
          l10n.profileEditorIdentityHeading,
          style: constraints.maxHeight < 250 && textScale >= 1.6
              ? SegText.item
              : SegText.title,
          textAlign: TextAlign.center,
        ),
      );
      final field = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('profile-editor-nickname'),
            controller: name,
            maxLength: 24,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              labelText: l10n.profileEditorNicknameLabel,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: SegSpace.s2,
                vertical: SegSpace.s1,
              ),
            ),
          ),
          if (error.isNotEmpty) _errorText(),
        ],
      );
      // Profiles are marked by the nickname's initial, not a picked animal.
      final avatars = Center(
        child: ValueListenableBuilder(
          valueListenable: name,
          builder: (context, value, _) => InitialAvatar(
            key: const ValueKey('profile-initial'),
            name: value.text,
            size: avatarSize,
          ),
        ),
      );

      if (_portrait) {
        return ListView(
          padding: const EdgeInsets.all(SegSpace.s3),
          children: [
            heading,
            const SizedBox(height: SegSpace.s5),
            SizedBox(height: avatarSize + 24, child: avatars),
            const SizedBox(height: SegSpace.s5),
            field,
          ],
        );
      }

      if (textScale >= 2 && constraints.maxHeight < 400) {
        return Column(
          children: [
            heading,
            const SizedBox(height: SegSpace.s1),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: avatars),
                  const SizedBox(width: SegSpace.s1),
                  Expanded(child: field),
                ],
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          heading,
          const SizedBox(height: SegSpace.s1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SegSpace.s2,
                    ),
                    child: field,
                  ),
                ),
                Expanded(flex: 6, child: avatars),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _questionPage() {
    final question = surveyQuestions[page - 1];
    final progress = l10n.profileEditorSurveyProgress(
      page,
      surveyQuestions.length,
    );
    final prompt = Text(
      s.locale == 'tr' ? question.tr : question.en,
      key: const ValueKey('profile-editor-question'),
      style: SegText.title,
      textAlign: TextAlign.center,
    );
    // Upright: exact age 2–10+ as one grid, like onboarding. The legacy
    // range answer is kept in sync for older readers of the survey.
    final options = _portrait && question.key == 'age'
        ? _ageGrid()
        : SurveyOptions(
            question: question,
            locale: s.locale,
            value: answers[question.key],
            onChanged: (value) {
              FocusScope.of(context).unfocus();
              setState(() {
                answers[question.key] = value;
                if (!question.multiple) page++;
              });
            },
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 400 &&
            MediaQuery.textScalerOf(context).scale(1) >= 1.6;
        if (_portrait) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: page / surveyQuestions.length,
                color: SegColors.primary,
                backgroundColor: SegColors.line,
                borderRadius: BorderRadius.circular(SegRadius.pill),
              ),
              const SizedBox(height: SegSpace.s2),
              Text(
                progress,
                style: SegText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SegSpace.s3),
              prompt,
              if (error.isNotEmpty) _errorText(),
              const SizedBox(height: SegSpace.s3),
              Expanded(child: options),
            ],
          );
        }
        if (compact) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SegSpace.s2),
                child: Text(
                  progress,
                  style: SegText.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SegSpace.s2),
                child: Text(
                  s.locale == 'tr' ? question.tr : question.en,
                  key: const ValueKey('profile-editor-question'),
                  style: SegText.item,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(child: options),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(SegSpace.s2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: page / surveyQuestions.length,
                      color: SegColors.primary,
                      backgroundColor: SegColors.line,
                    ),
                    const SizedBox(height: SegSpace.s2),
                    Text(
                      progress,
                      style: SegText.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: SegSpace.s2),
                    prompt,
                    if (error.isNotEmpty) _errorText(),
                  ],
                ),
              ),
            ),
            Expanded(flex: 6, child: options),
          ],
        );
      },
    );
  }

  bool get _singleRecommendationPerPage {
    final size = MediaQuery.sizeOf(context);
    return size.width <= 900 &&
        size.height <= 400 &&
        MediaQuery.textScalerOf(context).scale(1) >= 1.6;
  }

  int get _recommendationsPerPage => _singleRecommendationPerPage ? 1 : 2;

  int get _recommendationPageCount =>
      (s.content.themes.length + _recommendationsPerPage - 1) ~/
      _recommendationsPerPage;

  Widget _recommendationPage() => _portrait
      ? ListView(
          key: const ValueKey('profile-recommendation-list'),
          children: [
            if (error.isNotEmpty) _errorText(compact: true),
            for (final theme in s.content.themes) _recommendationCard(theme),
          ],
        )
      : Column(
          children: [
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegSpace.s2,
                  vertical: SegSpace.s1,
                ),
                child: _errorText(compact: true),
              ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('profile-recommendation-pages'),
                controller: _recommendations,
                itemCount: _recommendationPageCount,
                onPageChanged: (value) =>
                    setState(() => recommendationPage = value),
                itemBuilder: (context, index) {
                  final first = index * _recommendationsPerPage;
                  final themes = s.content.themes
                      .skip(first)
                      .take(_recommendationsPerPage)
                      .toList();
                  return Row(
                    children: [
                      for (final theme in themes)
                        Expanded(child: _recommendationCard(theme)),
                    ],
                  );
                },
              ),
            ),
          ],
        );

  Widget _recommendationCard(ContentTheme theme) {
    final level = SurveyMapper.initialForTheme(answers, theme.id);
    return Semantics(
      label: '${theme.name(s.locale)}, ${level.label(s.locale)}',
      child: Container(
        margin: const EdgeInsets.all(SegSpace.s2),
        padding: const EdgeInsets.all(SegSpace.s2),
        decoration: BoxDecoration(
          color: SegColors.surface,
          borderRadius: BorderRadius.circular(SegRadius.lg),
          border: Border.all(color: SegColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              theme.name(s.locale),
              style: SegText.item,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SegSpace.s2),
            Text(
              level.label(s.locale),
              style: SegText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool get _portrait =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  Widget _ageGrid() => LayoutBuilder(
    builder: (context, box) {
      const gap = SegSpace.s3;
      final width = (box.maxWidth - gap * 2) / 3;
      final selected = answers['ageYears'];
      return SingleChildScrollView(
        child: Wrap(
          key: const ValueKey('profile-age-grid'),
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var age = 2; age <= 10; age++)
              SizedBox(
                width: width,
                child: AgeChoice(
                  key: ValueKey('profile-age-$age'),
                  label: age == 10 ? l10n.obAgeTenPlus : '$age',
                  semanticsLabel: age == 10
                      ? l10n.obAgeTenPlus
                      : l10n.obAgeYears(age),
                  selected: selected == age,
                  onTap: () => setState(() {
                    answers['ageYears'] = age;
                    answers['age'] = age <= 3
                        ? 0
                        : age <= 5
                        ? 1
                        : age <= 7
                        ? 2
                        : 3;
                    page++;
                  }),
                ),
              ),
          ],
        ),
      );
    },
  );

  /// Upright screens stack the footer actions as full-width buttons.
  Widget _footer() {
    final footer = _footerRow();
    if (!_portrait || footer is! Row) return footer;
    final children = footer.children.whereType<Expanded>().toList();
    if (children.length < 2) return footer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: SegSpace.s2),
          children[i].child,
        ],
      ],
    );
  }

  Widget _footerRow() {
    if (page == 0) {
      final media = MediaQuery.sizeOf(context);
      final compact =
          media.width <= 900 &&
          media.height <= 400 &&
          MediaQuery.textScalerOf(context).scale(1) >= 1.6;
      if (compact) {
        return Row(
          children: [
            Expanded(
              child: _compactAction(
                key: const ValueKey('profile-editor-continue'),
                label: l10n.profileEditorStartSurvey,
                onPressed: saving ? null : () => _goToPage(1),
              ),
            ),
            const SizedBox(width: SegSpace.s1),
            Expanded(
              flex: 2,
              child: _compactAction(
                key: const ValueKey('profile-editor-save-or-skip'),
                label: saving
                    ? l10n.profileEditorSaving
                    : editing
                    ? l10n.profileEditorSave
                    : l10n.profileEditorSkipQuestionnaireAndCreate,
                onPressed: saving ? null : save,
                secondary: true,
              ),
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(
            child: SegButton(
              key: const ValueKey('profile-editor-continue'),
              label: l10n.profileEditorStartSurvey,
              icon: Icons.tune_rounded,
              onPressed: saving ? null : () => _goToPage(1),
            ),
          ),
          const SizedBox(width: SegSpace.s2),
          Expanded(
            child: SegButton(
              key: const ValueKey('profile-editor-save-or-skip'),
              label: saving
                  ? l10n.profileEditorSaving
                  : editing
                  ? l10n.profileEditorSave
                  : l10n.profileEditorSkipQuestionnaireAndCreate,
              secondary: true,
              onPressed: saving ? null : save,
            ),
          ),
        ],
      );
    }
    if (page <= surveyQuestions.length) {
      final question = surveyQuestions[page - 1];
      return Row(
        children: [
          Expanded(
            child: SegButton(
              key: const ValueKey('profile-editor-skip-question'),
              label: l10n.profileEditorSkipQuestion,
              secondary: true,
              onPressed: () => _goToPage(page + 1),
            ),
          ),
          if (question.multiple) ...[
            const SizedBox(width: SegSpace.s2),
            Expanded(
              child: SegButton(
                key: const ValueKey('profile-editor-survey-continue'),
                label: l10n.profileEditorContinue,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    answers.putIfAbsent(question.key, () => <int>[]);
                    page++;
                  });
                },
              ),
            ),
          ],
        ],
      );
    }
    return Row(
      children: [
        IconButton(
          key: const ValueKey('profile-recommendation-previous'),
          tooltip: MaterialLocalizations.of(context).previousPageTooltip,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: recommendationPage == 0
              ? null
              : () => navigatePage(
                  context: context,
                  controller: _recommendations,
                  page: recommendationPage - 1,
                  reducedMotion: s.reducedMotion,
                  duration: SegMotion.pageSlide,
                  curve: Curves.easeOutCubic,
                ),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            l10n.profileEditorRecommendationProgress(
              recommendationPage + 1,
              _recommendationPageCount,
            ),
            key: const ValueKey('profile-recommendation-progress'),
            textAlign: TextAlign.center,
            style: SegText.caption,
          ),
        ),
        IconButton(
          key: const ValueKey('profile-recommendation-next'),
          tooltip: MaterialLocalizations.of(context).nextPageTooltip,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: recommendationPage >= _recommendationPageCount - 1
              ? null
              : () => navigatePage(
                  context: context,
                  controller: _recommendations,
                  page: recommendationPage + 1,
                  reducedMotion: s.reducedMotion,
                  duration: SegMotion.pageSlide,
                  curve: Curves.easeOutCubic,
                ),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: SegSpace.s2),
        Expanded(
          flex: 2,
          child: SegButton(
            key: const ValueKey('profile-editor-save-recommendations'),
            label: saving
                ? l10n.profileEditorSaving
                : l10n.profileEditorSaveRecommendations,
            onPressed: saving ? null : save,
          ),
        ),
      ],
    );
  }

  Widget _compactAction({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    bool secondary = false,
  }) => ElevatedButton(
    key: key,
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      foregroundColor: secondary ? SegColors.primaryDeep : Colors.white,
      backgroundColor: secondary ? SegColors.surface : SegColors.accentStrong,
      side: BorderSide(
        color: secondary ? SegColors.line : Colors.white,
        width: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SegRadius.md),
      ),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: SegText.item.copyWith(
        color: secondary ? SegColors.primaryDeep : Colors.white,
      ),
    ),
  );

  Widget _errorText({bool compact = false}) => Text(
    error,
    key: const ValueKey('profile-editor-error'),
    style: (compact ? SegText.caption : SegText.body).copyWith(
      color: SegColors.accentDeep,
    ),
  );
}
