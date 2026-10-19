// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Every little step,\na new discovery.';

  @override
  String get welcomeSubtitle =>
      'Calm, playful learning at your child’s own pace.';

  @override
  String get noAdsOffline => 'No ads. No internet required.';

  @override
  String get parentGateSettings => 'Settings stay behind a parent gate.';

  @override
  String get noAccountNeeded => 'No account needed.';

  @override
  String get letsGetStarted => 'Let’s get started';

  @override
  String get homeFamily => 'Family';

  @override
  String get homeGames => 'Games';

  @override
  String get homeDailyPath => 'Today’s Path';

  @override
  String get homeFamilyHint => 'Hold for two seconds to open the family area';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homePathSubtitle => 'Let’s explore, one step at a time.';

  @override
  String get homeGamesSubtitle => 'What shall we discover today?';

  @override
  String get homeNewBadge => 'New';

  @override
  String homeThemeGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '$count game',
      zero: '0 games',
    );
    return '$_temp0';
  }

  @override
  String get themeBack => 'Back';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get themeNoUnlockedGames =>
      'No unlocked games at this level. Try Easy.';

  @override
  String get themeUnlockWithFamily => 'You can unlock this with your family.';

  @override
  String get parentGateTitle => 'Family area';

  @override
  String get parentGateEnterPin => 'Enter PIN';

  @override
  String get parentGateContinuePrompt => 'To continue';

  @override
  String get parentGateWrongPin => 'Try your PIN again.';

  @override
  String get parentGateWrongMath => 'Try the new question.';

  @override
  String get parentGateForgotPin => 'Forgot PIN';

  @override
  String get parentGateCancel => 'Cancel';

  @override
  String get onboardingSaveError => 'Could not save. Please try again.';

  @override
  String onboardingReadyTitle(String name) {
    return 'Ready, $name!';
  }

  @override
  String get onboardingSuggestedStart => 'Suggested starting point';

  @override
  String get onboardingFamilyHint => 'You can adjust these in the Family area.';

  @override
  String get onboardingSaving => 'Saving…';

  @override
  String get onboardingPlay => 'Let’s play';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingSkipQuestion => 'Skip this question';

  @override
  String get onboardingNickname => 'Nickname';

  @override
  String get onboardingProfileQuestion => 'Who is our little explorer?';

  @override
  String get onboardingNicknameHint => 'A nickname is all we need.';

  @override
  String onboardingStepCount(int current, int total) {
    return '$current / $total';
  }

  @override
  String get surveyPreviousOption => 'Previous option';

  @override
  String get surveyNextOption => 'Next option';

  @override
  String surveyOptionCount(int current, int total) {
    return '$current / $total';
  }

  @override
  String surveyOptionProgress(int current, int total) {
    return 'Option $current of $total';
  }

  @override
  String get onboardingPreviousRecommendation => 'Previous recommendation';

  @override
  String get onboardingNextRecommendation => 'Next recommendation';

  @override
  String get accountTitle => 'Account';

  @override
  String get familyAccountTitle => 'Family account';

  @override
  String get familyAccountOptional =>
      'Google sign-in is optional. All local features work without an account.';

  @override
  String get familyAccountSignedIn => 'Signed in with Google.';

  @override
  String get familyAccountLocalProgress =>
      'Detailed progress stays on this device. Daily summary sharing requires separate permission below.';

  @override
  String get familyAccountSignIn => 'Sign in with Google';

  @override
  String get familyAccountSignOut => 'Sign out';

  @override
  String get familyAccountNotNow =>
      'Not now: Close this screen and keep playing.';

  @override
  String get familyAccountCancelled => 'Sign-in cancelled.';

  @override
  String get familyAccountOffline =>
      'Could not connect. You can continue offline.';

  @override
  String get familyAccountConfiguration =>
      'Google sign-in needs setup. Your local data is safe.';

  @override
  String get familyAccountTimeout =>
      'Sign-in timed out. You can continue offline.';

  @override
  String get familyAccountUnavailable =>
      'Sign-in is unavailable. You can continue locally.';

  @override
  String get creditsTitle => 'Credits and licenses';

  @override
  String get creditsLoadFailure => 'Could not load credits.';

  @override
  String get creditsAnimalRecordings => 'Natural sounds';

  @override
  String get creditsRealPhotographs => 'Real photographs';

  @override
  String get creditsSoundChanges =>
      'Changes: mono MP3, reduced volume, short fades, at most 3 seconds.';

  @override
  String get creditsAdaptationLicense => 'Adaptation license';

  @override
  String get creditsAuthor => 'Author';

  @override
  String get creditsLicense => 'License';

  @override
  String get creditsPreviousImageCredit => 'Previous image credit';

  @override
  String get creditsSource => 'Source';

  @override
  String get creditsLicenseLink => 'License link';

  @override
  String get creditsChanges => 'Changes';

  @override
  String get creditsImagePreparedForAppUse => 'Image prepared for app use.';

  @override
  String get creditsAudioEditedForInAppPlayback =>
      'Audio edited for in-app playback.';

  @override
  String get creditsPreviousRecord => 'Previous record';

  @override
  String get creditsNextRecord => 'Next record';

  @override
  String creditsRecordDetailProgress(
    int record,
    int recordTotal,
    int detail,
    int detailTotal,
  ) {
    return 'Record $record of $recordTotal, detail $detail of $detailTotal';
  }

  @override
  String get creditsLicensesLoadFailure =>
      'License information could not be loaded.';

  @override
  String get creditsLicensesEmpty => 'No registered licenses.';

  @override
  String get familyNewsHeading => 'News';

  @override
  String get applicationName => 'Special Education Games';

  @override
  String get creditsOpenSourceLicenses => 'Open source software licenses';

  @override
  String get summarySyncTitle => 'Sync daily summaries';

  @override
  String get summarySyncDescription =>
      'Only daily time, round and independent response totals are shared. Raw choices, child name and survey answers are not sent. This is not a full profile backup.';

  @override
  String get summarySyncRequirements =>
      'Parent access, a profile and Google sign-in are required to sync.';

  @override
  String get summarySyncConsent =>
      'I allow daily summary sharing for this account and profile.';

  @override
  String get summarySyncManualNotice =>
      'Sync starts only with the button below. Revoking permission clears the downloaded snapshot on this device; it does not delete server data.';

  @override
  String get summarySyncNow => 'Sync now';

  @override
  String summarySyncSnapshot(int count, String savedAt) {
    return 'Synced snapshot on device: $count records. Saved: $savedAt';
  }

  @override
  String get summarySyncCapacity =>
      'The summary count exceeds the supported limit. Local records are preserved.';

  @override
  String get summarySyncUnavailable =>
      'Sync could not finish. The connection or server may be unavailable. Local records are preserved.';

  @override
  String get subscriptionTitle => 'Premium';

  @override
  String get subscriptionShowPlans => 'Show plans';

  @override
  String get subscriptionHeading => 'More discoveries together';

  @override
  String get subscriptionAllGames => 'All games and difficulty levels';

  @override
  String get subscriptionProfiles => 'Up to five child profiles';

  @override
  String get subscriptionAdFree => 'Ad-free, offline learning';

  @override
  String get subscriptionActive => 'Your Premium access is active.';

  @override
  String get subscriptionUnavailable =>
      'Google Play products are unavailable right now. You can continue with the free games.';

  @override
  String get subscriptionMonthly => 'Monthly';

  @override
  String get subscriptionYearly => 'Yearly';

  @override
  String get subscriptionMonth => 'month';

  @override
  String get subscriptionYear => 'year';

  @override
  String subscriptionPrice(String recurringPrice, String period) {
    return '$recurringPrice / $period';
  }

  @override
  String subscriptionTrial(String recurringPrice) {
    return '7 days free, then $recurringPrice. Cancel through Google Play before the trial ends.';
  }

  @override
  String get subscriptionRenewal =>
      'Renews automatically. You can cancel at any time through Google Play.';

  @override
  String get subscriptionWaiting => 'Waiting for Google Play…';

  @override
  String get subscriptionStartTrial => 'Start 7-day trial';

  @override
  String get subscriptionContinue => 'Continue with Google Play';

  @override
  String get subscriptionStoreError =>
      'Could not connect to the store. Please try again later.';

  @override
  String get subscriptionRestore => 'Restore purchases';

  @override
  String get subscriptionManage => 'Manage / cancel subscription';

  @override
  String get playTimeBreakTitle => 'That’s enough for today. You did great!';

  @override
  String get playTimeBreakSubtitle => 'Let’s take a little break now.';

  @override
  String get playTimeHome => 'Home';

  @override
  String get playTimeExtendHint => 'Unlock the parent gate to add 10 minutes';

  @override
  String get playTimeExtend => 'Parent: add 10 minutes';

  @override
  String playTimeBreakPageCount(int current, int total) {
    return 'Break · $current of $total';
  }

  @override
  String get familyCancel => 'Cancel';

  @override
  String get familyUseMultiplication => 'Use multiplication';

  @override
  String get familyEnterTheSameFourDigitsTwice =>
      'Enter the same four digits twice.';

  @override
  String get familySave => 'Save';

  @override
  String get familyParentPin => 'Parent PIN';

  @override
  String get family4DigitPin => '4-digit PIN';

  @override
  String get familyRepeatPin => 'Repeat PIN';

  @override
  String get familyEveryStepMatters => 'Every step matters';

  @override
  String get familyYourChildIsExploringAtTheir =>
      'Your child is exploring at their own pace.';

  @override
  String get familyStarsToday => 'Stars today';

  @override
  String get familyRoundsCompletedToday => 'Rounds completed today';

  @override
  String get familyMinutesToday => 'Minutes today';

  @override
  String get familyStagesThisWeek => 'Stages this week';

  @override
  String get familyIndependentAnswers => 'Independent answers';

  @override
  String get familyLast7Days => 'Last 7 days';

  @override
  String get familyPlayTimeMinutes => 'Play time · minutes';

  @override
  String get familyIndependentFirstAnswers => 'Independent first answers · %';

  @override
  String get familyProgressWillAppearHereAfterThe =>
      'Progress will appear here after the first game.';

  @override
  String get familyAttentionDailyAverageSeconds =>
      'Attention · daily average seconds';

  @override
  String get familyFirstResponse => 'First response';

  @override
  String get familyS => 's';

  @override
  String get familyIdleTime => 'Idle time';

  @override
  String get familyTimeInTheBackgroundIsExcluded =>
      'Time in the background is excluded.';

  @override
  String familySecondsRange(double maximum) {
    return '0–$maximum seconds.';
  }

  @override
  String get familyNumericView => 'Numeric view';

  @override
  String get familySkillAreas => 'Skill areas';

  @override
  String get familyIndependentFirstAnswersInTheLast =>
      'Independent first answers in the last 7 days';

  @override
  String get familyNoRecordsYet => 'No records yet';

  @override
  String familyCountStages(int count) {
    return '$count stages';
  }

  @override
  String get familyPointsComparedWithThePreviousWeek =>
      'points · compared with the previous week';

  @override
  String get familyItems => 'Items';

  @override
  String get familyIndependentLastThreeAnswersWithoutHints =>
      'Independent: last three answers without hints. Support: substantial help in at least two of the last three stages.';

  @override
  String get familyIndependentlyAnswered => 'Independently answered';

  @override
  String get familyItemsNeedingMoreSupport => 'Items needing more support';

  @override
  String get familyItemsAppearHereAfterAtLeast =>
      'Items appear here after at least three observations.';

  @override
  String familyCountStagesLatestStreakAnswersIndependent(
    int count,
    int streak,
  ) {
    return '$count stages · latest $streak answers independent';
  }

  @override
  String get familyProgressByTheme => 'Progress by theme';

  @override
  String get familyShowUnlockedGamesOnly => 'Show unlocked games only';

  @override
  String get familyHidesLockedCardsInChildMode =>
      'Hides locked cards in Child Mode.';

  @override
  String get familyEasyAndMediumUnlocked => 'Easy and Medium unlocked';

  @override
  String get familyPremium => 'Premium';

  @override
  String get familyDailyScreenTimeLimit => 'Daily screen time limit';

  @override
  String get familyCountsActivePlayTimeABreak =>
      'Counts active play time. A break screen opens when time runs out.';

  @override
  String get familyOff => 'Off';

  @override
  String get familyMinutes => 'minutes';

  @override
  String familyRemainingTodayMinutesMinutes(int minutes) {
    return 'Remaining today: $minutes minutes';
  }

  @override
  String get familyAdd10MinutesForToday => 'Add 10 minutes for today';

  @override
  String get familyDefaultDifficulty => 'Default difficulty';

  @override
  String get familyAutomaticThemeSelection => 'Automatic / theme selection';

  @override
  String get familyEasy => 'Easy';

  @override
  String get familyMedium => 'Medium';

  @override
  String get familyHard => 'Hard';

  @override
  String get familyAppliesToNewRoundsHardLevel =>
      'Applies to new rounds. Hard level is included in Premium.';

  @override
  String get familyRoundLength => 'Round length';

  @override
  String get familySurveyDifficultySetting => 'Survey / difficulty setting';

  @override
  String get familyStages => 'stages';

  @override
  String get familyHintDelay => 'Hint delay';

  @override
  String get familyAutomaticPerItem => 'Automatic / per item';

  @override
  String get familyTimedHintsOff => 'Timed hints off';

  @override
  String get familySeconds => 'seconds';

  @override
  String get familyNextRoundBehavior => 'Next round behavior';

  @override
  String get familyFadeIncorrectChoicesAfter2Mistakes =>
      'Fade incorrect choices after 2 mistakes';

  @override
  String get familyAppliesToTheNextRoundIncorrect =>
      'Applies to the next round. Incorrect answers still receive support when timed hints are off.';

  @override
  String get familyDailyMinuteGoal => 'Daily minute goal';

  @override
  String familyTodayGoalProgress(double minutes, int goal) {
    return 'Today’s goal: $minutes / $goal minutes';
  }

  @override
  String get familyAnOptionalReminderItDoesNot =>
      'An optional reminder; it does not limit play time.';

  @override
  String get familyMin => 'min';

  @override
  String get familyUpdate => 'Update';

  @override
  String get familyANewVersionIsAvailableYou =>
      'A new version is available. You can update through Google Play.';

  @override
  String get familyParentGate => 'Parent gate';

  @override
  String get familyMultiplicationQuestion => 'Multiplication question';

  @override
  String get familyIntroduceNewItemsFirst => 'Introduce new items first';

  @override
  String get familyShowOneCardFirstThenOffer =>
      'Show one card first, then offer choices.';

  @override
  String get familyAdaptiveDifficulty => 'Adaptive difficulty';

  @override
  String get familyChangesApplyOnlyWhenANew =>
      'Changes apply only when a new round starts.';

  @override
  String get familyAudio => 'Audio';

  @override
  String get familySpeechVolume => 'Speech volume';

  @override
  String get familySoundEffectVolume => 'Sound effect volume';

  @override
  String get familyShowItemLabels => 'Show item labels';

  @override
  String get familyReduceMotion => 'Reduce motion';

  @override
  String get familyLanguage => 'Language';

  @override
  String get familyCelebration => 'Celebration';

  @override
  String get familySimple => 'Simple';

  @override
  String get familyFull => 'Full';

  @override
  String get familySubscriptionPricesAndTrialEligibilityCome =>
      'Subscription prices and trial eligibility come from Google Play.';

  @override
  String get familyPlansAndRestore => 'Plans and restore';

  @override
  String get familyPrivacy => 'Privacy';

  @override
  String get familyGoogleFamilyAccount => 'Google family account';

  @override
  String get familyCreditsAndLicenses => 'Credits and licenses';

  @override
  String get familyProfilesAndRawGameRecordsStay =>
      'Profiles and raw game records stay on this device. Only daily summaries are sent when you give permission and start sync in the account screen. No ads or advertising identifiers are used.';

  @override
  String get familyDoesNotReplaceProfessionalSupport =>
      'Does not replace professional support.';

  @override
  String get familySection => 'Section';

  @override
  String get familyPreviousSection => 'Previous section';

  @override
  String get familyNextSection => 'Next section';

  @override
  String get familyChildMode => 'Child Mode';

  @override
  String get familyProgress => 'Progress';

  @override
  String get familyGames => 'Games';

  @override
  String get familyProfiles => 'Profiles';

  @override
  String get familySettings => 'Settings';

  @override
  String get familyStoredOnThisDevice => 'Stored on this device';

  @override
  String get familyDeleteProfile => 'Delete profile';

  @override
  String familyGameAndProgressRecordsForName(String name) {
    return 'Game and progress records for $name will be deleted from this device.';
  }

  @override
  String get familyDelete => 'Delete';

  @override
  String get familyEditAndQuestionnaire => 'Edit and questionnaire';

  @override
  String familyProfileAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'More profiles',
      one: 'Create a profile',
      zero: 'Create a profile',
    );
    return '$_temp0';
  }

  @override
  String get familyTheFreeVersionIncludesOneChild =>
      'The free version includes one child profile.';

  @override
  String get gameBackToTheme => 'Back to theme';

  @override
  String get gameThisGameNeedsSoundAParentCan =>
      'This game needs sound. A parent can enable it in settings.';

  @override
  String get gameThereIsNotEnoughContentForThis =>
      'There is not enough content for this game yet.';

  @override
  String get gameHoldToLeave => 'Hold to leave';

  @override
  String get gameListenAgain => 'Listen again';

  @override
  String get gamePreviousPage => 'Previous page';

  @override
  String get gameNextPage => 'Next page';

  @override
  String get gameWellDone => 'Well done!';

  @override
  String get gameYouEarnedTodaysSticker => 'You earned today’s sticker!';

  @override
  String get gameWeExploredTogether => 'We explored together.';

  @override
  String get gameAgain => 'Again';

  @override
  String get gameTodaysPath => 'Today’s Path';

  @override
  String get gameImagesForThisThemeAreNotReady =>
      'Images for this theme are not ready yet.';

  @override
  String get gamePrevious => 'Previous';

  @override
  String get gameFinish => 'Finish';

  @override
  String get gameNext => 'Next';

  @override
  String get gameObject => 'Object';

  @override
  String gameCountedObjectSemantics(String object, int number) {
    return '$object, count $number';
  }

  @override
  String get dailyPathNoGamesAreAvailableToday =>
      'No games are available today.';

  @override
  String get dailyPathYouEarnedTodaysSticker => 'You earned today’s sticker!';

  @override
  String get dailyPathEachCompletedGameIsOneStep =>
      'Each completed game is one step.';

  @override
  String get dailyPathMyStickers => 'My stickers';

  @override
  String get dailyPathCompleted => 'Completed';

  @override
  String get dailyPathPlay => 'Play';

  @override
  String get dailyPathCompleteTodaysPathToEarnYourFirst =>
      'Complete today’s path to earn your first sticker.';

  @override
  String get dailyPathEarnedSticker => 'Earned sticker';

  @override
  String get dailyPathPreviousPage => 'Previous page';

  @override
  String dailyPathPageCurrentOfTotal(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get dailyPathNextPage => 'Next page';

  @override
  String get dailyPathClose => 'Close';

  @override
  String gameSummaryPage(int current, int total) {
    return 'Summary · page $current of $total';
  }

  @override
  String dailyPathStepTitle(int index, String game) {
    return '$index. $game';
  }

  @override
  String get profileEditorNameRequired => 'Enter a nickname.';

  @override
  String get profileEditorSaveFailed =>
      'Could not save. Check the profile limit and try again.';

  @override
  String get profileEditorEditTitle => 'Edit profile';

  @override
  String get profileEditorNewTitle => 'New profile';

  @override
  String get profileEditorIdentityHeading => 'Little explorer’s profile';

  @override
  String get profileEditorNicknameLabel => 'Nickname';

  @override
  String get profileEditorStartSurvey => 'Starting questionnaire';

  @override
  String get profileEditorSaving => 'Saving…';

  @override
  String get profileEditorSave => 'Save';

  @override
  String get profileEditorSkipQuestionnaireAndCreate =>
      'Skip questionnaire and create';

  @override
  String get profileEditorContinue => 'Continue';

  @override
  String get profileEditorSkipQuestion => 'Skip this question';

  @override
  String get profileEditorSuggestedStart => 'Suggested starting point';

  @override
  String get profileEditorSaveRecommendations => 'Save recommendations';

  @override
  String profileEditorSurveyProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String profileEditorRecommendationProgress(int current, int total) {
    return 'Recommendation page $current of $total';
  }

  @override
  String get gamePromptCount => 'How many are there?';

  @override
  String get gamePromptCompareMagnitude => 'Which has more?';

  @override
  String get gamePromptCompareNumbers => 'Compare these numbers';

  @override
  String get gamePromptGroupMembership => 'Which group does this belong to?';

  @override
  String get gamePromptFindMatch => 'Find the match';

  @override
  String get gamePromptListenForNumber => 'Listen. Which number?';

  @override
  String get gamePromptListenForSoundSource => 'Listen. What makes this sound?';

  @override
  String get gamePromptSequenceNext => 'Which number comes next?';

  @override
  String get gamePromptSequenceMissing => 'Which number is missing?';

  @override
  String get obStart => 'Let’s begin';

  @override
  String get obBack => 'Back';

  @override
  String get obSkip => 'Skip';

  @override
  String get obChildTitle => 'Tell us about your child';

  @override
  String get obChildBody =>
      'We use this to choose a gentle starting point. You can change it later in the family area.';

  @override
  String get obNicknameOptional => 'Nickname (optional)';

  @override
  String get obAgeTitle => 'Age';

  @override
  String get obAgeTenPlus => '10+';

  @override
  String obAgeYears(int age) {
    return '$age years old';
  }

  @override
  String get obDefaultNickname => 'Little explorer';

  @override
  String get obMultipleHint => 'You can choose more than one.';

  @override
  String obStepSemantics(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get obGoalTitle => 'Daily play goal';

  @override
  String get obGoalBody =>
      'Short, regular sessions work best. Your child sees calm progress, never a countdown.';

  @override
  String obGoalMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get obRecommended => 'Recommended';

  @override
  String get obLockTitle => 'Settings stay with you';

  @override
  String get obLockBody =>
      'To return to the family area, press and hold “Family” on the home screen for two seconds, then answer a simple question.';

  @override
  String get obPinSwitch => 'Also set a 4-digit PIN';

  @override
  String get obPinField => 'PIN';

  @override
  String get obPinInvalid => 'Enter four digits.';

  @override
  String get obTrialTitle => 'Explore every game';

  @override
  String get obTrialBody =>
      'The free games stay free. Premium opens every theme and game, all difficulty levels and up to five child profiles.';

  @override
  String get obTrialPoint1 => 'All themes and games';

  @override
  String get obTrialPoint2 => 'Every difficulty level';

  @override
  String get obTrialPoint3 => 'Up to five child profiles';

  @override
  String get obTrialStart => 'Try 7 days free';

  @override
  String get obTrialNote =>
      'Billed by Google Play after the trial. You can cancel any time in Google Play.';

  @override
  String get obContinueFree => 'Continue for free';

  @override
  String get obHandoffBody =>
      'Turn the phone sideways and hand it to your child.';

  @override
  String get obHandoffNote =>
      'The games open in landscape. The family area opens upright.';

  @override
  String get gamePromptOddOneOut => 'Find the one that is different';

  @override
  String get gamePromptShadowMatch => 'Find its shadow';

  @override
  String get gamePromptSortIntoBasket => 'Put it in the right basket';

  @override
  String get gamePromptNumberQuantity => 'Find this many';

  @override
  String gamePromptFillCount(int count) {
    return 'Put $count in the basket';
  }

  @override
  String gameFillBasketCount(int count, int goal) {
    return 'Basket: $count of $goal';
  }

  @override
  String get appTitle => 'Special Education Games';

  @override
  String get gamePromptWhichSound => 'Which sound does it make?';

  @override
  String get gameListenToSound => 'Listen';
}
