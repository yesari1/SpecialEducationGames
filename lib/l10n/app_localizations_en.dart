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
  String get welcomeLearnPlaying => 'Your child learns while playing';

  @override
  String get welcomeTopics => 'Animals, colors, numbers';

  @override
  String get welcomeOwnPace => 'Adjusts to your child\'s age';

  @override
  String get noAdsOffline => 'No ads.';

  @override
  String get homeFamily => 'Family';

  @override
  String get homeGames => 'Games';

  @override
  String get homeFamilyHint => 'Family area (opens a parent check)';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

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
  String get storiesTitle => 'Stories';

  @override
  String storiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stories',
      one: '$count story',
      zero: '0 stories',
    );
    return '$_temp0';
  }

  @override
  String get storyNext => 'Next';

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
  String get onboardingFamilyHint => 'You can adjust these in the Family area.';

  @override
  String get onboardingSaving => 'Saving…';

  @override
  String get onboardingPlay => 'Let’s play';

  @override
  String get onboardingContinue => 'Continue';

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
  String get accountTitle => 'Account';

  @override
  String get familyAccountTitle => 'Family account';

  @override
  String get familyAccountSignedIn => 'Signed in with Google.';

  @override
  String get familyAccountLocalProgress =>
      'Detailed progress stays on this device. Daily summary sharing requires separate permission below.';

  @override
  String get familyAccountSignIn => 'Sign in with Google';

  @override
  String get appleSignIn => 'Sign in with Apple';

  @override
  String get familyAccountSignOut => 'Sign out';

  @override
  String get familyAccountCancelled => 'Sign-in cancelled.';

  @override
  String get familyAccountOffline =>
      'Could not connect. Check the internet connection and try again.';

  @override
  String get familyAccountConfiguration =>
      'Sign-in is not available right now.';

  @override
  String get familyAccountTimeout => 'Sign-in timed out. Please try again.';

  @override
  String get familyAccountUnavailable =>
      'Sign-in is unavailable right now. Please try again later.';

  @override
  String get creditsTitle => 'Credits and licenses';

  @override
  String get creditsLoadFailure => 'Could not load credits.';

  @override
  String get creditsAnimalRecordings => 'Natural sounds';

  @override
  String get creditsRealPhotographs => 'Real photographs';

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
  String get creditsOpenSourceLicenses => 'Open source software licenses';

  @override
  String get summarySyncTitle => 'Sync daily summaries';

  @override
  String get summarySyncDescription =>
      'Only daily time and the number of rounds go to the cloud. Your child\'s answers are not sent.';

  @override
  String get summarySyncRequirements =>
      'Parent access, a profile and Google sign-in are required to sync.';

  @override
  String get summarySyncConsent =>
      'I allow daily summary sharing for this account and profile.';

  @override
  String get summarySyncManualNotice =>
      'Sync starts only with the button below. Turning permission off clears the summary on this phone; it does not delete cloud data.';

  @override
  String get summarySyncNow => 'Sync now';

  @override
  String summarySyncSnapshot(int count, String savedAt) {
    return 'Synced snapshot on device: $count records. Saved: $savedAt';
  }

  @override
  String get summarySyncCapacity =>
      'There are too many records; some could not be sent. The records on this phone are kept.';

  @override
  String get summarySyncUnavailable =>
      'Sync could not finish. The connection or server may be unavailable. Local records are preserved.';

  @override
  String get subscriptionTitle => 'Premium';

  @override
  String get subscriptionAllGames => 'All games and difficulty levels';

  @override
  String get subscriptionProfiles => 'Up to five child profiles';

  @override
  String get subscriptionAdFree => 'Detailed progress reports';

  @override
  String get subscriptionActive => 'Your Premium access is active.';

  @override
  String get subscriptionMonthly => 'Monthly';

  @override
  String get subscriptionYearly => 'Yearly';

  @override
  String get subscriptionWaiting => 'Waiting for Google Play…';

  @override
  String get subscriptionStoreError =>
      'Could not connect to the store. Please try again later.';

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
  String get familyPlayTimeMinutes => 'Play time (min)';

  @override
  String get familyIndependentFirstAnswers => 'Correct on their own (%)';

  @override
  String get familyProgressWillAppearHereAfterThe =>
      'Charts fill in after the first game.';

  @override
  String get familyAttentionDailyAverageSeconds => 'Answer time (sec)';

  @override
  String get familyFirstResponse => 'First answer';

  @override
  String get familyS => 's';

  @override
  String get familyIdleTime => 'Waiting without an answer';

  @override
  String get familyTimeInTheBackgroundIsExcluded =>
      'Time in the background is excluded.';

  @override
  String get familySkillAreas => 'Skills';

  @override
  String get familyIndependentFirstAnswersInTheLast =>
      'Independent first answers in the last 7 days';

  @override
  String get familyNoRecordsYet => 'No records yet';

  @override
  String familyCountStages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stages',
      one: '1 stage',
    );
    return '$_temp0';
  }

  @override
  String get familyPointsComparedWithThePreviousWeek =>
      'points · compared with the previous week';

  @override
  String get familyItems => 'Items';

  @override
  String get familyIndependentLastThreeAnswersWithoutHints =>
      'On their own: last 3 answers right without hints. Support: needed help in 2 of the last 3 rounds.';

  @override
  String get familyIndependentlyAnswered => 'Knows on their own';

  @override
  String get familyItemsNeedingMoreSupport => 'Needs more help';

  @override
  String get familyItemsAppearHereAfterAtLeast => 'Shown after three tries.';

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
  String get familyDailyScreenTimeLimit => 'Daily screen time limit';

  @override
  String get familyCountsActivePlayTimeABreak =>
      'A break screen opens when time is up.';

  @override
  String get familyOff => 'Off';

  @override
  String get familyMinutes => 'minutes';

  @override
  String familyRemainingTodayMinutesMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Remaining today: $_temp0';
  }

  @override
  String get familyAdd10MinutesForToday => 'Add 10 minutes for today';

  @override
  String get familyDefaultDifficulty => 'Default difficulty';

  @override
  String get familyAutomaticThemeSelection => 'Automatic by theme';

  @override
  String get familyEasy => 'Easy';

  @override
  String get familyMedium => 'Medium';

  @override
  String get familyHard => 'Hard';

  @override
  String get familyAppliesToNewRoundsHardLevel => 'Hard level is Premium.';

  @override
  String get familyRoundLength => 'Round length';

  @override
  String get familySurveyDifficultySetting => 'Based on the starting survey';

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
      'Applies from the next round.';

  @override
  String get familyDailyMinuteGoal => 'Daily minute goal';

  @override
  String familyTodayGoalProgress(double minutes, int goal) {
    return 'Today’s goal: $minutes / $goal minutes';
  }

  @override
  String get familyAnOptionalReminderItDoesNot =>
      'A goal only; play is not limited.';

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
  String get familyShowOneCardFirstThenOffer => 'One card first, then choices.';

  @override
  String get familyAdaptiveDifficulty => 'Automatic difficulty suggestion';

  @override
  String get familyChangesApplyOnlyWhenANew => 'Applies from the next round.';

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
  String get familyPrivacy => 'Privacy';

  @override
  String get familyGoogleFamilyAccount => 'Google family account';

  @override
  String get familyCreditsAndLicenses => 'Credits and licenses';

  @override
  String get familyProfilesAndRawGameRecordsStay =>
      'Child profiles are saved to your account; detailed game records stay on this device. No ads.';

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
  String get gameBackToTheme => 'Back to theme';

  @override
  String get gameThisGameNeedsSoundAParentCan =>
      'This game needs sound. A parent can enable it in settings.';

  @override
  String get gameThereIsNotEnoughContentForThis =>
      'There is not enough content for this game yet.';

  @override
  String get gameHoldToLeave => 'Leave the game';

  @override
  String get gameListenAgain => 'Listen again';

  @override
  String get gamePreviousPage => 'Previous page';

  @override
  String get gameNextPage => 'Next page';

  @override
  String get gameWellDone => 'Well done!';

  @override
  String get gameWeExploredTogether => 'We explored together.';

  @override
  String get gameAgain => 'Again';

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
  String get gameNextGame => 'Next game';

  @override
  String get reminderTitle => 'Time to play';

  @override
  String get reminderBody => 'Shall we play together for a few minutes today?';

  @override
  String get reminderChannel => 'Daily play reminder';

  @override
  String get reminderOfferTitle => 'Daily reminder';

  @override
  String get reminderOfferBody =>
      'If you haven\'t played that day, shall we send a short reminder at 6 pm?';

  @override
  String get reminderOfferYes => 'Yes, remind me';

  @override
  String get reminderOfferNo => 'Not now';

  @override
  String get gameObject => 'Object';

  @override
  String gameCountedObjectSemantics(String object, int number) {
    return '$object, count $number';
  }

  @override
  String get dailyPathMyStickers => 'My stickers';

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
  String get obHaveAccount => 'Already have an account?';

  @override
  String get obSignIn => 'Sign in';

  @override
  String get obNoAccountFound =>
      'No account found for this Google account. Tap Let\'s begin to start.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInOr => 'or';

  @override
  String get signInEmail => 'E-mail';

  @override
  String get signInPassword => 'Password';

  @override
  String get signInContinue => 'Continue with e-mail';

  @override
  String get signInWrongPassword => 'Wrong e-mail or password.';

  @override
  String signInLinkSent(String email) {
    return 'We sent a sign-in link to $email. Tap the link in the e-mail on this phone.';
  }

  @override
  String get familyAccountDetails => 'Details';

  @override
  String get accountDeleteHelpTitle => 'How to delete the account';

  @override
  String get accountDeleteHelpBody =>
      'Tap \"Delete account and cloud data\" above and confirm with your Google account. The family record, child profiles and daily summaries are deleted from the cloud. If you cannot open the app: yesastudio.com/ozel-egitim-oyunlari/delete-account';

  @override
  String get accountPlanMonthly => 'Premium · monthly';

  @override
  String get accountPlanYearly => 'Premium · yearly';

  @override
  String get accountTrialEnds => 'Trial ends';

  @override
  String get accountPremiumUntil => 'Premium until';

  @override
  String get accountPurchased => 'Purchased';

  @override
  String get accountCreated => 'Account created';

  @override
  String get accountLastSignIn => 'Last sign-in';

  @override
  String get accountNextPaymentNote =>
      'The next payment date and cancelling are in Google Play → Payments & subscriptions.';

  @override
  String get paywallLifetimeSubscribedTitle => 'Your subscription continues';

  @override
  String get paywallLifetimeSubscribedBody =>
      'After the one-time purchase your subscription does not stop by itself. To stop its payments, cancel it in Google Play → Payments & subscriptions.';

  @override
  String get paywallLifetimeSubscribedContinue => 'Continue to purchase';

  @override
  String get obSignedIn => 'Signed in. Now let’s add your child.';

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
  String get obGenderGirl => 'Girl';

  @override
  String get obGenderBoy => 'Boy';

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
      'Short, regular sessions work best. Your child never sees a pressuring countdown.';

  @override
  String obGoalMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get obRecommended => 'Recommended';

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

  @override
  String get famToday => 'Today';

  @override
  String famGoalShort(int done, int goal) {
    return '$done / $goal min';
  }

  @override
  String get famGoalDone => 'Today’s goal is reached. Well done!';

  @override
  String famGoalLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes more minutes',
      one: '1 more minute',
    );
    return '$_temp0 to today’s goal.';
  }

  @override
  String famPlayedToday(int minutes) {
    return 'Played today: $minutes min';
  }

  @override
  String get famMinutesThisWeek => 'Minutes this week';

  @override
  String get famDaysPlayed => 'Days played this week';

  @override
  String get famThisWeek => 'This week';

  @override
  String get famRecentlyPlayed => 'Recently played';

  @override
  String get famRecentlyLearned => 'Learned recently';

  @override
  String get famNothingYet => 'Nothing yet. Play a round together!';

  @override
  String get familyAgeLevel => 'Age level';

  @override
  String get familyAgeLevelEasier => 'Easier';

  @override
  String get familyAgeLevelByAge => 'By age';

  @override
  String get familyAgeLevelHarder => 'Harder';

  @override
  String familyAgeLevelFromAge(String band) {
    return 'By age: $band';
  }

  @override
  String get familyAgeLevelNoAge =>
      'No age in this profile. Add it in the profile editor.';

  @override
  String get familyAgeLevelNote =>
      'Applies to new games. Easy/Medium/Hard and automatic difficulty still work; Hard stays premium.';

  @override
  String get ageBandFirstSteps => 'First steps (2–3)';

  @override
  String get ageBandExplore => 'Explore (4–5)';

  @override
  String get ageBandSchoolReady => 'School ready (6–7)';

  @override
  String get ageBandPractice => 'Practice (8+)';

  @override
  String get ageBandFirstStepsInfo =>
      '2 choices, numbers 1–3, 5 questions per game, quick hints; tap games first.';

  @override
  String get ageBandExploreInfo =>
      '3 choices, numbers 1–5, 6 questions per game; tap and simple drag.';

  @override
  String get ageBandSchoolReadyInfo =>
      '4 choices, numbers 1–10, 8 questions per game; drag, group and sort.';

  @override
  String get ageBandPracticeInfo =>
      '4 choices, numbers 1–20, 10 questions per game, less familiar items, later hints.';

  @override
  String paywallTrialActive(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return 'Trial active: $_temp0';
  }

  @override
  String get paywallTrialUsed => 'This account\'s free trial has been used.';

  @override
  String get paywallTrialError =>
      'The trial could not be started. Check the internet connection and try again.';

  @override
  String get paywallLifetime => 'One-time';

  @override
  String get paywallLifetimeNote =>
      'Pay once, keep it forever. No subscription.';

  @override
  String get paywallLifetimeOwned => 'You own Premium for life.';

  @override
  String get paywallPrivacy => 'Privacy policy';

  @override
  String get paywallTerms => 'Terms of use';

  @override
  String get familyAccountDelete => 'Delete account and cloud data';

  @override
  String get familyAccountDeleteTitle => 'Delete the account?';

  @override
  String get familyAccountDeleteBody =>
      'The family account linked to your Google account and the learning summaries in the cloud are deleted permanently. You will be asked to confirm with Google first. Profiles and progress on this device are not deleted; uninstall the app to remove them.';

  @override
  String get familyAccountDeleteConfirm => 'Delete permanently';

  @override
  String get familyAccountDeleteCancel => 'Cancel';

  @override
  String get familyAccountDeleted => 'The account and cloud data were deleted.';

  @override
  String get familyAccountDeleteFailed =>
      'The account could not be deleted. Check the internet connection and try again.';

  @override
  String get paywallHeadline => 'Unlock every game';

  @override
  String paywallSave(int percent) {
    return 'Save $percent%';
  }

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallContinueFree => 'Continue with the free version';

  @override
  String get paywallRestoreShort => 'Restore';

  @override
  String get paywallPlansFailed => 'Plans could not be loaded.';

  @override
  String get paywallRetry => 'Try again';

  @override
  String get paywallClose => 'Close';

  @override
  String get familyCloudSync => 'Send daily summaries to the cloud';

  @override
  String get familyCloudSyncNote =>
      'A daily summary (game, minutes, rounds) is saved to your Google account. No child name.';

  @override
  String welcomeFreeTrial(int days) {
    return 'Try every game free for $days days';
  }

  @override
  String get paywallBestValue => 'Best value';

  @override
  String paywallPerMonth(String price) {
    return '$price/mo';
  }

  @override
  String paywallStartTrial(int days) {
    return 'Try free for $days days';
  }

  @override
  String get paywallStartFreeTrial => 'Start trial';

  @override
  String get paywallTrialOptionNote => 'No card · No automatic charge';

  @override
  String get paywallFreePrice => 'Free';

  @override
  String get signInCheckEmail => 'Check your e-mail';

  @override
  String get signInUseOtherEmail => 'Use a different e-mail';

  @override
  String paywallTrialOption(int days) {
    return '$days days free';
  }

  @override
  String paywallContinuePrice(String price) {
    return 'Continue · $price';
  }

  @override
  String get paywallCancelAnytime => 'Cancel anytime in Google Play.';

  @override
  String get welcomeFreeAfter =>
      'Afterwards, Learn and two games in every theme stay free.';

  @override
  String get paywallEveryMonth => 'every month';

  @override
  String get paywallOnePayment => 'one payment';

  @override
  String get paywallCancelShort => 'Cancel anytime';

  @override
  String get paywallNoSubscription => 'No subscription';

  @override
  String get lockedGameTitle => 'This game is locked';

  @override
  String get lockedGameBody =>
      'Ask your family to unlock it. You can play the open games for now.';

  @override
  String get lockedGameOk => 'OK';

  @override
  String get familyPremiumStripBuy => 'Go Premium';

  @override
  String get familyPremiumStripNote => 'Every game and detailed progress';

  @override
  String get familyLockedStatsTitle => 'Detailed progress comes with Premium';

  @override
  String get familyLockedStatsBody =>
      'Weekly charts, attention, skills and per-item results.';

  @override
  String get familyLockedStatsButton => 'Unlock with Premium';

  @override
  String get familyAccountPlan => 'Plan';

  @override
  String get familyAccountPayment => 'Payment';

  @override
  String get familyPlanFree => 'Free version';

  @override
  String familyPlanTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return 'Free trial · $_temp0';
  }

  @override
  String familyPlanTrialEnds(String date) {
    return 'Ends on $date. Afterwards the free version continues.';
  }

  @override
  String get familyPlanSubscription => 'Premium subscription';

  @override
  String get familyPlanLifetime => 'Premium · one-time purchase';

  @override
  String get askSurveyMoreGames => 'Add more games';

  @override
  String get askSurveyMoreThemes => 'Add more themes and categories';

  @override
  String get askSurveyPrice => 'The price should be lower';

  @override
  String get askSurveySatisfaction => 'How satisfied are you with the app?';

  @override
  String get askSurveyWho => 'Who uses the app?';

  @override
  String get askSurveyUserParent => 'Parent';

  @override
  String get askSurveyUserTeacher => 'Teacher';

  @override
  String get askSurveyUserSpecialist =>
      'Special education specialist or therapist';

  @override
  String get askSurveyUserOther => 'Other';

  @override
  String get askSurveyImprove => 'What should we improve?';

  @override
  String get askSurveyVoices => 'The voices should be better';

  @override
  String get askSurveyReports => 'Progress reports should be more detailed';

  @override
  String get askSurveyNote => 'Anything you would like to add';

  @override
  String get feedbackTitle => 'Send feedback';

  @override
  String get feedbackIntro =>
      'Write to us about bugs, ideas or games you\'d like to see.';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackSent => 'Thank you, your feedback was sent';

  @override
  String get feedbackFailed => 'Could not send. Please try again.';

  @override
  String get familyPlanGranted => 'Premium';

  @override
  String get familyPlanTest => 'Premium (test build)';

  @override
  String get familyPaymentNone => 'No payment';

  @override
  String get familyPaymentTrial => 'No payment · trial with a Google account';

  @override
  String get familyPaymentPlay => 'Google Play';

  @override
  String get familyPlanCardTitle => 'Account';

  @override
  String get familyGamesPremiumTitle => 'Choose the games for your child';

  @override
  String get familyGamesPremiumBody =>
      'Turning games on and off comes with Premium and the free trial.';

  @override
  String familyGamesShownCount(int shown, int total) {
    return '$shown of $total games on';
  }

  @override
  String get familyMoreProfilesPremium => 'More child profiles with Premium';

  @override
  String get gameMascotHello => 'Hi! Let\'s play together.';

  @override
  String get weeklySummaryTitle => 'This week';

  @override
  String weeklySummaryBody(String name, int days, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$name played on $_temp0 this week, $_temp1 in total.';
  }

  @override
  String weeklySummaryNone(String name) {
    return '$name hasn\'t played this week yet. How about a few minutes together?';
  }

  @override
  String get familyReminder => 'Daily reminder';

  @override
  String get familyReminderNote =>
      'If there was no play that day, a short notification comes at the time you choose; on Sunday evening you get the week\'s summary.';

  @override
  String get familyReminderTime => 'Time';

  @override
  String get famDayStreak => 'Days in a row';

  @override
  String get homeTabLearn => 'Learn';

  @override
  String get homeTabStories => 'Stories';

  @override
  String get homeTabPark => 'Play Park';

  @override
  String get homeRowAnimalsFood => 'Animals and Food';

  @override
  String get homeRowDaily => 'Daily Routines';

  @override
  String get homeRowHomeOutside => 'Home and Outdoors';

  @override
  String get homeRowBasics => 'Colors, Shapes, Numbers';

  @override
  String get homeRowBodyFeelings => 'My Body and Feelings';

  @override
  String get parkColoring => 'Coloring';

  @override
  String get parkMusic => 'Musical Instruments';

  @override
  String get parkPuzzle => 'Puzzles';

  @override
  String get parkBubbles => 'Bubbles';

  @override
  String get gameNewSticker => 'You earned a new sticker!';
}
