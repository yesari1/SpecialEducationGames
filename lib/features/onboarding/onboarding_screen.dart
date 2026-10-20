import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../app/ui/initial_avatar.dart';
import '../../core/entitlement/billing_repository.dart';
import '../../core/learning/parent_pin.dart';
import '../../core/learning/policies.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/scoped_localizations.dart';
import 'onboarding_parts.dart';
import 'survey_questions.dart';

/// Parent-facing first run, shown upright. One decision per screen; every
/// question can be skipped. Nothing is saved until the hand-off screen.
class OnboardingScreen extends StatefulWidget {
  final AppState state;
  const OnboardingScreen({super.key, required this.state});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Onboarding illustrations (docs/illustration-style.md).
const _illustrations = 'assets/illustrations/onboarding';

enum OnboardingStep { welcome, child, question, goal, lock, trial, handoff }

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// The short get-to-know set; the full survey stays in the profile editor.
  static const questionKeys = ['favorite', 'known', 'sound', 'focus'];
  static final questions = [
    for (final key in questionKeys)
      surveyQuestions.firstWhere((q) => q.key == key),
  ];

  OnboardingStep step = OnboardingStep.welcome;
  int question = 0;
  final name = TextEditingController();
  final pin = TextEditingController();
  final answers = <String, dynamic>{};
  int? ageYears;
  int dailyGoal = 15;
  bool usePin = false, saving = false;
  AppState get s => widget.state;
  AppLocalizations get l10n => scopedLocalizations(context, s.locale);

  @override
  void initState() {
    super.initState();
    s.billing.addListener(_billingChanged);
  }

  void _billingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    s.billing.removeListener(_billingChanged);
    name.dispose();
    pin.dispose();
    super.dispose();
  }

  BillingPlan? get _trialPlan =>
      s.billing.plans.where((p) => p.sevenDayTrial).firstOrNull;

  /// Steps that show progress dots (welcome and hand-off are framing screens).
  int get _progressIndex => switch (step) {
    OnboardingStep.child => 0,
    OnboardingStep.question => 1 + question,
    OnboardingStep.goal => 1 + questions.length,
    OnboardingStep.lock => 2 + questions.length,
    OnboardingStep.trial => 3 + questions.length,
    _ => -1,
  };
  int get _progressCount => 3 + questions.length + (_trialPlan == null ? 0 : 1);

  void _next() {
    FocusScope.of(context).unfocus();
    setState(() {
      switch (step) {
        case OnboardingStep.welcome:
          step = OnboardingStep.child;
        case OnboardingStep.child:
          step = OnboardingStep.question;
          question = 0;
        case OnboardingStep.question:
          if (question < questions.length - 1) {
            question++;
          } else {
            step = OnboardingStep.goal;
          }
        case OnboardingStep.goal:
          step = OnboardingStep.lock;
        case OnboardingStep.lock:
          step = _trialPlan == null
              ? OnboardingStep.handoff
              : OnboardingStep.trial;
        case OnboardingStep.trial:
          step = OnboardingStep.handoff;
        case OnboardingStep.handoff:
          break;
      }
    });
  }

  void _back() {
    FocusScope.of(context).unfocus();
    setState(() {
      switch (step) {
        case OnboardingStep.welcome:
          break;
        case OnboardingStep.child:
          step = OnboardingStep.welcome;
        case OnboardingStep.question:
          if (question > 0) {
            question--;
          } else {
            step = OnboardingStep.child;
          }
        case OnboardingStep.goal:
          step = OnboardingStep.question;
          question = questions.length - 1;
        case OnboardingStep.lock:
          step = OnboardingStep.goal;
        case OnboardingStep.trial:
          step = OnboardingStep.lock;
        case OnboardingStep.handoff:
          step = _trialPlan == null
              ? OnboardingStep.lock
              : OnboardingStep.trial;
      }
    });
  }

  String get _nickname {
    final typed = name.text.trim();
    if (typed.isNotEmpty) return typed;
    return l10n.obDefaultNickname;
  }

  Map<String, dynamic> get _survey => {
    ...answers,
    if (ageYears case final age?) ...{
      'ageYears': age,
      // Legacy bucket kept for older readers of the survey payload.
      'age': age <= 3
          ? 0
          : age <= 5
          ? 1
          : age <= 7
          ? 2
          : 3,
    },
  };

  Future<void> finish() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final survey = _survey;
      final result = SurveyMapper.map(survey);
      await s.completeOnboarding(
        name: _nickname,
        survey: survey,
        dailyGoalMinutes: dailyGoal,
        pin: usePin ? pin.text : null,
      );
      await s.setting('celebration', result.celebration);
      if (survey['sound'] == 0) await s.setting('sound', 'false');
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.onboardingSaveError)));
      }
    }
  }

  // ---------------------------------------------------------------- frame --

  Widget _frame({
    required List<Widget> children,
    required Widget primary,
    Widget? secondary,
    bool skippable = false,
  }) {
    final dots = _progressIndex >= 0
        ? OnboardingDots(
            index: _progressIndex,
            count: _progressCount,
            label: l10n.obStepSemantics(_progressIndex + 1, _progressCount),
          )
        : const SizedBox.shrink();
    return Scaffold(
      backgroundColor: SegColors.familyCanvas,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: SegSpace.s2),
                  if (step != OnboardingStep.welcome)
                    IconButton(
                      key: const ValueKey('onboarding-back'),
                      tooltip: l10n.obBack,
                      onPressed: saving ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(child: Center(child: dots)),
                  if (skippable)
                    TextButton(
                      key: const ValueKey('onboarding-skip'),
                      onPressed: _next,
                      child: Text(l10n.obSkip, style: SegText.label),
                    )
                  else
                    const SizedBox(width: 64),
                  const SizedBox(width: SegSpace.s2),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    key: ValueKey('onboarding-${step.name}-$question'),
                    padding: const EdgeInsets.fromLTRB(
                      SegSpace.s5,
                      SegSpace.s2,
                      SegSpace.s5,
                      SegSpace.s5,
                    ),
                    children: children,
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SegSpace.s5,
                    0,
                    SegSpace.s5,
                    SegSpace.s4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      primary,
                      if (secondary != null) ...[
                        const SizedBox(height: SegSpace.s2),
                        secondary,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text, {Key? key}) => Padding(
    padding: const EdgeInsets.only(bottom: SegSpace.s2),
    child: Text(
      text,
      key: key,
      style: SegText.title.copyWith(color: SegColors.ink),
    ),
  );

  Widget _body(String text) =>
      Text(text, style: SegText.body.copyWith(color: SegColors.inkSoft));

  Widget _continue({VoidCallback? onPressed, String? label, Key? key}) =>
      SegButton(
        key: key ?? const ValueKey('onboarding-continue'),
        label: label ?? l10n.onboardingContinue,
        onPressed: onPressed,
      );

  // ---------------------------------------------------------------- steps --

  Widget _welcome() => _frame(
    children: [
      // One illustrated scene in the app's illustration style
      // (docs/illustration-style.md) on a soft sky-to-cream card.
      Container(
        key: const ValueKey('welcome-hero'),
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SegRadius.xl),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDF2FD), Color(0xFFFFF6EA)],
          ),
        ),
        padding: const EdgeInsets.all(SegSpace.s2),
        child: Image.asset(
          '$_illustrations/hero_welcome.png',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(height: SegSpace.s5),
      Text(
        l10n.welcomeTitle,
        key: const ValueKey('welcome-title'),
        style: SegText.display.copyWith(fontSize: 32, color: SegColors.ink),
      ),
      const SizedBox(height: SegSpace.s2),
      Text(
        l10n.welcomeSubtitle,
        key: const ValueKey('welcome-subtitle'),
        style: SegText.body.copyWith(color: SegColors.inkSoft),
      ),
      const SizedBox(height: SegSpace.s5),
      FeatureLine(icon: Icons.spa_rounded, text: l10n.noAdsOffline),
      FeatureLine(
        icon: Icons.lock_outline_rounded,
        text: l10n.parentGateSettings,
      ),
      FeatureLine(
        icon: Icons.person_outline_rounded,
        text: l10n.noAccountNeeded,
      ),
    ],
    primary: _continue(
      key: const ValueKey('welcome-start'),
      label: l10n.obStart,
      onPressed: _next,
    ),
  );

  Widget _child() => _frame(
    children: [
      _title(l10n.obChildTitle, key: const ValueKey('child-title')),
      _body(l10n.obChildBody),
      const SizedBox(height: SegSpace.s5),
      Row(
        children: [
          ValueListenableBuilder(
            valueListenable: name,
            builder: (context, value, _) =>
                InitialAvatar(name: value.text, size: 56),
          ),
          const SizedBox(width: SegSpace.s3),
          Expanded(
            child: TextField(
              key: const ValueKey('nickname-field'),
              controller: name,
              maxLength: 24,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.obNicknameOptional,
                hintText: l10n.onboardingNicknameHint,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: SegSpace.s5),
      Text(l10n.obAgeTitle, style: SegText.heading),
      const SizedBox(height: SegSpace.s3),
      LayoutBuilder(
        builder: (context, box) {
          const gap = SegSpace.s3;
          final width = (box.maxWidth - gap * 2) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var age = 2; age <= 10; age++)
                SizedBox(
                  width: width,
                  child: AgeChoice(
                    key: ValueKey('age-$age'),
                    label: age == 10 ? l10n.obAgeTenPlus : '$age',
                    semanticsLabel: age == 10
                        ? l10n.obAgeTenPlus
                        : l10n.obAgeYears(age),
                    selected: ageYears == age,
                    onTap: () =>
                        setState(() => ageYears = ageYears == age ? null : age),
                  ),
                ),
            ],
          );
        },
      ),
    ],
    primary: _continue(onPressed: _next),
  );

  Widget _question() {
    final q = questions[question];
    final options = s.locale == 'tr' ? q.trOptions : q.enOptions;
    final value = answers[q.key];
    final selected = <int>{
      if (value is List) ...value.whereType<int>(),
      if (value is int) value,
    };
    return _frame(
      skippable: true,
      children: [
        _title(
          s.locale == 'tr' ? q.tr : q.en,
          key: ValueKey('question-${q.key}'),
        ),
        if (q.multiple) _body(l10n.obMultipleHint),
        const SizedBox(height: SegSpace.s4),
        LayoutBuilder(
          builder: (context, box) {
            const gap = SegSpace.s3;
            final columns = options.length <= 3 ? 1 : 2;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              key: ValueKey('survey-options-${q.key}'),
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < options.length; i++)
                  SizedBox(
                    width: width,
                    child: PictureOption(
                      key: ValueKey('survey-option-$i'),
                      label: options[i],
                      picture: _optionPicture(q.key, i),
                      wide: columns == 1,
                      selected: selected.contains(i),
                      multiple: q.multiple,
                      onTap: () => setState(() {
                        if (q.multiple) {
                          final next = {...selected};
                          if (!next.add(i)) next.remove(i);
                          answers[q.key] = next.toList()..sort();
                        } else {
                          answers[q.key] = i;
                        }
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
      primary: _continue(onPressed: _next),
    );
  }

  /// Every survey option uses an illustration from one set, never a photo.
  Widget _optionPicture(String key, int index) {
    final name = switch (key) {
      'favorite' => const [
        'animals',
        'vehicles',
        'colors',
        'numbers',
        'music',
        'food',
      ][index],
      'known' => const [
        'animals',
        'fruit',
        'colors',
        'numbers',
        'vehicles',
        'shapes',
        'clothes',
        'home',
        'body',
        'feelings',
      ][index],
      'sound' => const ['sound_yes', 'sound_little', 'sound_no'][index],
      _ => const ['focus_short', 'focus_medium', 'focus_long'][index],
    };
    return Image.asset(
      '$_illustrations/opt_$name.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }

  Widget _goal() => _frame(
    children: [
      _title(l10n.obGoalTitle, key: const ValueKey('goal-title')),
      _body(l10n.obGoalBody),
      const SizedBox(height: SegSpace.s5),
      for (final minutes in const [10, 15, 20]) ...[
        GoalOption(
          key: ValueKey('goal-$minutes'),
          label: l10n.obGoalMinutes(minutes),
          badge: minutes == 15 ? l10n.obRecommended : null,
          minutes: minutes,
          selected: dailyGoal == minutes,
          onTap: () => setState(() => dailyGoal = minutes),
        ),
        const SizedBox(height: SegSpace.s3),
      ],
      _body(l10n.onboardingFamilyHint),
    ],
    primary: _continue(onPressed: _next),
  );

  Widget _lock() {
    final pinValid = ParentPin.valid(pin.text);
    return _frame(
      children: [
        _title(l10n.obLockTitle, key: const ValueKey('lock-title')),
        const SizedBox(height: SegSpace.s3),
        FamilyAccessIllustration(label: l10n.homeFamily),
        const SizedBox(height: SegSpace.s4),
        _body(l10n.obLockBody),
        const SizedBox(height: SegSpace.s4),
        Material(
          color: SegColors.surface,
          borderRadius: BorderRadius.circular(SegRadius.md),
          child: SwitchListTile(
            key: const ValueKey('pin-switch'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SegRadius.md),
            ),
            title: Text(l10n.obPinSwitch, style: SegText.label),
            value: usePin,
            onChanged: (value) => setState(() => usePin = value),
          ),
        ),
        if (usePin) ...[
          const SizedBox(height: SegSpace.s3),
          TextField(
            key: const ValueKey('pin-field'),
            controller: pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.obPinField,
              counterText: '',
              errorText: pin.text.isEmpty || pinValid
                  ? null
                  : l10n.obPinInvalid,
            ),
          ),
        ],
      ],
      primary: _continue(onPressed: usePin && !pinValid ? null : _next),
    );
  }

  Widget _trial() {
    final plan = _trialPlan;
    return _frame(
      children: [
        _title(l10n.obTrialTitle, key: const ValueKey('trial-title')),
        _body(l10n.obTrialBody),
        const SizedBox(height: SegSpace.s4),
        FeatureLine(icon: Icons.check_rounded, text: l10n.obTrialPoint1),
        FeatureLine(icon: Icons.check_rounded, text: l10n.obTrialPoint2),
        FeatureLine(icon: Icons.check_rounded, text: l10n.obTrialPoint3),
        const SizedBox(height: SegSpace.s4),
        if (plan != null)
          Text(
            l10n.subscriptionTrial(plan.recurringPrice),
            style: SegText.caption.copyWith(color: SegColors.inkSoft),
          ),
        const SizedBox(height: SegSpace.s1),
        Text(
          l10n.obTrialNote,
          style: SegText.caption.copyWith(color: SegColors.inkSoft),
        ),
      ],
      primary: _continue(
        key: const ValueKey('trial-continue-free'),
        label: l10n.obContinueFree,
        onPressed: _next,
      ),
      secondary: plan == null
          ? null
          : SegButton(
              key: const ValueKey('trial-start'),
              secondary: true,
              label: s.billing.pending
                  ? l10n.subscriptionWaiting
                  : l10n.obTrialStart,
              onPressed: s.billing.pending ? null : () => s.billing.buy(plan),
            ),
    );
  }

  Widget _handoff() => _frame(
    children: [
      const SizedBox(height: SegSpace.s3),
      const SizedBox(height: 200, child: RotatePhoneIllustration()),
      const SizedBox(height: SegSpace.s5),
      Text(
        l10n.onboardingReadyTitle(_nickname),
        key: const ValueKey('final-ready-title'),
        textAlign: TextAlign.center,
        style: SegText.display.copyWith(fontSize: 32, color: SegColors.ink),
      ),
      const SizedBox(height: SegSpace.s3),
      Text(
        l10n.obHandoffBody,
        textAlign: TextAlign.center,
        style: SegText.heading.copyWith(color: SegColors.ink),
      ),
      const SizedBox(height: SegSpace.s2),
      Text(
        l10n.obHandoffNote,
        textAlign: TextAlign.center,
        style: SegText.body.copyWith(color: SegColors.inkSoft),
      ),
    ],
    primary: _continue(
      key: const ValueKey('final-play'),
      label: saving ? l10n.onboardingSaving : l10n.onboardingPlay,
      onPressed: saving ? null : finish,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final page = switch (step) {
      OnboardingStep.welcome => _welcome(),
      OnboardingStep.child => _child(),
      OnboardingStep.question => _question(),
      OnboardingStep.goal => _goal(),
      OnboardingStep.lock => _lock(),
      OnboardingStep.trial => _trial(),
      OnboardingStep.handoff => _handoff(),
    };
    final reduced = s.reducedMotion || MediaQuery.disableAnimationsOf(context);
    // System Back walks back through the steps; only the first step leaves.
    return PopScope(
      canPop: step == OnboardingStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !saving) _back();
      },
      child: AnimatedSwitcher(
        duration: reduced ? Duration.zero : SegMotion.appear,
        child: KeyedSubtree(
          key: ValueKey('${step.name}-$question'),
          child: page,
        ),
      ),
    );
  }
}
