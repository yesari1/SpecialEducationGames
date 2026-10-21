import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Every little step,\na new discovery.'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calm, playful learning at your child’s own pace.'**
  String get welcomeSubtitle;

  /// No description provided for @noAdsOffline.
  ///
  /// In en, this message translates to:
  /// **'No ads. No internet required.'**
  String get noAdsOffline;

  /// No description provided for @parentGateSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings stay behind a parent gate.'**
  String get parentGateSettings;

  /// No description provided for @noAccountNeeded.
  ///
  /// In en, this message translates to:
  /// **'No account needed.'**
  String get noAccountNeeded;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let’s get started'**
  String get letsGetStarted;

  /// No description provided for @homeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get homeFamily;

  /// No description provided for @homeGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get homeGames;

  /// No description provided for @homeDailyPath.
  ///
  /// In en, this message translates to:
  /// **'Today’s Path'**
  String get homeDailyPath;

  /// No description provided for @homeFamilyHint.
  ///
  /// In en, this message translates to:
  /// **'Family area (opens a parent check)'**
  String get homeFamilyHint;

  /// Child home greeting with the local profile nickname.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// No description provided for @homePathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s explore, one step at a time.'**
  String get homePathSubtitle;

  /// No description provided for @homeGamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What shall we discover today?'**
  String get homeGamesSubtitle;

  /// No description provided for @homeNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get homeNewBadge;

  /// Count of available games shown on a theme card.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 games} one{{count} game} other{{count} games}}'**
  String homeThemeGameCount(int count);

  /// No description provided for @themeBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get themeBack;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @themeNoUnlockedGames.
  ///
  /// In en, this message translates to:
  /// **'No unlocked games at this level. Try Easy.'**
  String get themeNoUnlockedGames;

  /// No description provided for @themeUnlockWithFamily.
  ///
  /// In en, this message translates to:
  /// **'You can unlock this with your family.'**
  String get themeUnlockWithFamily;

  /// No description provided for @parentGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Family area'**
  String get parentGateTitle;

  /// No description provided for @parentGateEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get parentGateEnterPin;

  /// No description provided for @parentGateContinuePrompt.
  ///
  /// In en, this message translates to:
  /// **'To continue'**
  String get parentGateContinuePrompt;

  /// No description provided for @parentGateWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Try your PIN again.'**
  String get parentGateWrongPin;

  /// No description provided for @parentGateWrongMath.
  ///
  /// In en, this message translates to:
  /// **'Try the new question.'**
  String get parentGateWrongMath;

  /// No description provided for @parentGateForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN'**
  String get parentGateForgotPin;

  /// No description provided for @parentGateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get parentGateCancel;

  /// No description provided for @onboardingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get onboardingSaveError;

  /// Final onboarding heading with the child's chosen nickname.
  ///
  /// In en, this message translates to:
  /// **'Ready, {name}!'**
  String onboardingReadyTitle(String name);

  /// No description provided for @onboardingSuggestedStart.
  ///
  /// In en, this message translates to:
  /// **'Suggested starting point'**
  String get onboardingSuggestedStart;

  /// No description provided for @onboardingFamilyHint.
  ///
  /// In en, this message translates to:
  /// **'You can adjust these in the Family area.'**
  String get onboardingFamilyHint;

  /// No description provided for @onboardingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get onboardingSaving;

  /// No description provided for @onboardingPlay.
  ///
  /// In en, this message translates to:
  /// **'Let’s play'**
  String get onboardingPlay;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingSkipQuestion.
  ///
  /// In en, this message translates to:
  /// **'Skip this question'**
  String get onboardingSkipQuestion;

  /// No description provided for @onboardingNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get onboardingNickname;

  /// No description provided for @onboardingProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Who is our little explorer?'**
  String get onboardingProfileQuestion;

  /// No description provided for @onboardingNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'A nickname is all we need.'**
  String get onboardingNicknameHint;

  /// Current onboarding survey question and total question count.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String onboardingStepCount(int current, int total);

  /// No description provided for @surveyPreviousOption.
  ///
  /// In en, this message translates to:
  /// **'Previous option'**
  String get surveyPreviousOption;

  /// No description provided for @surveyNextOption.
  ///
  /// In en, this message translates to:
  /// **'Next option'**
  String get surveyNextOption;

  /// Visible position and total in the horizontal survey option pager.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String surveyOptionCount(int current, int total);

  /// Accessible position in the horizontal survey option pager.
  ///
  /// In en, this message translates to:
  /// **'Option {current} of {total}'**
  String surveyOptionProgress(int current, int total);

  /// No description provided for @onboardingPreviousRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Previous recommendation'**
  String get onboardingPreviousRecommendation;

  /// No description provided for @onboardingNextRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Next recommendation'**
  String get onboardingNextRecommendation;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @familyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Family account'**
  String get familyAccountTitle;

  /// No description provided for @familyAccountOptional.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is optional. All local features work without an account.'**
  String get familyAccountOptional;

  /// No description provided for @familyAccountSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google.'**
  String get familyAccountSignedIn;

  /// No description provided for @familyAccountLocalProgress.
  ///
  /// In en, this message translates to:
  /// **'Detailed progress stays on this device. Daily summary sharing requires separate permission below.'**
  String get familyAccountLocalProgress;

  /// No description provided for @familyAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get familyAccountSignIn;

  /// No description provided for @familyAccountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get familyAccountSignOut;

  /// No description provided for @familyAccountNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now: Close this screen and keep playing.'**
  String get familyAccountNotNow;

  /// No description provided for @familyAccountCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled.'**
  String get familyAccountCancelled;

  /// No description provided for @familyAccountOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. You can continue offline.'**
  String get familyAccountOffline;

  /// No description provided for @familyAccountConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in needs setup. Your local data is safe.'**
  String get familyAccountConfiguration;

  /// No description provided for @familyAccountTimeout.
  ///
  /// In en, this message translates to:
  /// **'Sign-in timed out. You can continue offline.'**
  String get familyAccountTimeout;

  /// No description provided for @familyAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is unavailable. You can continue locally.'**
  String get familyAccountUnavailable;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits and licenses'**
  String get creditsTitle;

  /// No description provided for @creditsLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not load credits.'**
  String get creditsLoadFailure;

  /// No description provided for @creditsAnimalRecordings.
  ///
  /// In en, this message translates to:
  /// **'Natural sounds'**
  String get creditsAnimalRecordings;

  /// No description provided for @creditsRealPhotographs.
  ///
  /// In en, this message translates to:
  /// **'Real photographs'**
  String get creditsRealPhotographs;

  /// No description provided for @creditsSoundChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes: mono MP3, reduced volume, short fades, at most 3 seconds.'**
  String get creditsSoundChanges;

  /// No description provided for @creditsAdaptationLicense.
  ///
  /// In en, this message translates to:
  /// **'Adaptation license'**
  String get creditsAdaptationLicense;

  /// No description provided for @creditsAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get creditsAuthor;

  /// No description provided for @creditsLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get creditsLicense;

  /// No description provided for @creditsPreviousImageCredit.
  ///
  /// In en, this message translates to:
  /// **'Previous image credit'**
  String get creditsPreviousImageCredit;

  /// No description provided for @creditsSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get creditsSource;

  /// No description provided for @creditsLicenseLink.
  ///
  /// In en, this message translates to:
  /// **'License link'**
  String get creditsLicenseLink;

  /// No description provided for @creditsChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get creditsChanges;

  /// No description provided for @creditsImagePreparedForAppUse.
  ///
  /// In en, this message translates to:
  /// **'Image prepared for app use.'**
  String get creditsImagePreparedForAppUse;

  /// No description provided for @creditsAudioEditedForInAppPlayback.
  ///
  /// In en, this message translates to:
  /// **'Audio edited for in-app playback.'**
  String get creditsAudioEditedForInAppPlayback;

  /// No description provided for @creditsPreviousRecord.
  ///
  /// In en, this message translates to:
  /// **'Previous record'**
  String get creditsPreviousRecord;

  /// No description provided for @creditsNextRecord.
  ///
  /// In en, this message translates to:
  /// **'Next record'**
  String get creditsNextRecord;

  /// Accessible position across credit records and the current record's detail pages.
  ///
  /// In en, this message translates to:
  /// **'Record {record} of {recordTotal}, detail {detail} of {detailTotal}'**
  String creditsRecordDetailProgress(
    int record,
    int recordTotal,
    int detail,
    int detailTotal,
  );

  /// No description provided for @creditsLicensesLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'License information could not be loaded.'**
  String get creditsLicensesLoadFailure;

  /// No description provided for @creditsLicensesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No registered licenses.'**
  String get creditsLicensesEmpty;

  /// No description provided for @familyNewsHeading.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get familyNewsHeading;

  /// No description provided for @applicationName.
  ///
  /// In en, this message translates to:
  /// **'Special Education Games'**
  String get applicationName;

  /// No description provided for @creditsOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source software licenses'**
  String get creditsOpenSourceLicenses;

  /// No description provided for @summarySyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync daily summaries'**
  String get summarySyncTitle;

  /// No description provided for @summarySyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Only daily time, round and independent response totals are shared. Raw choices, child name and survey answers are not sent. This is not a full profile backup.'**
  String get summarySyncDescription;

  /// No description provided for @summarySyncRequirements.
  ///
  /// In en, this message translates to:
  /// **'Parent access, a profile and Google sign-in are required to sync.'**
  String get summarySyncRequirements;

  /// No description provided for @summarySyncConsent.
  ///
  /// In en, this message translates to:
  /// **'I allow daily summary sharing for this account and profile.'**
  String get summarySyncConsent;

  /// No description provided for @summarySyncManualNotice.
  ///
  /// In en, this message translates to:
  /// **'Sync starts only with the button below. Revoking permission clears the downloaded snapshot on this device; it does not delete server data.'**
  String get summarySyncManualNotice;

  /// No description provided for @summarySyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get summarySyncNow;

  /// Separate imported daily aggregate snapshot; savedAt retains the existing local DateTime string.
  ///
  /// In en, this message translates to:
  /// **'Synced snapshot on device: {count} records. Saved: {savedAt}'**
  String summarySyncSnapshot(int count, String savedAt);

  /// No description provided for @summarySyncCapacity.
  ///
  /// In en, this message translates to:
  /// **'The summary count exceeds the supported limit. Local records are preserved.'**
  String get summarySyncCapacity;

  /// No description provided for @summarySyncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sync could not finish. The connection or server may be unavailable. Local records are preserved.'**
  String get summarySyncUnavailable;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionShowPlans.
  ///
  /// In en, this message translates to:
  /// **'Show plans'**
  String get subscriptionShowPlans;

  /// No description provided for @subscriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'More discoveries together'**
  String get subscriptionHeading;

  /// No description provided for @subscriptionAllGames.
  ///
  /// In en, this message translates to:
  /// **'All games and difficulty levels'**
  String get subscriptionAllGames;

  /// No description provided for @subscriptionProfiles.
  ///
  /// In en, this message translates to:
  /// **'Up to five child profiles'**
  String get subscriptionProfiles;

  /// No description provided for @subscriptionAdFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-free, offline learning'**
  String get subscriptionAdFree;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Your Premium access is active.'**
  String get subscriptionActive;

  /// No description provided for @subscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Play products are unavailable right now. You can continue with the free games.'**
  String get subscriptionUnavailable;

  /// No description provided for @subscriptionMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionMonthly;

  /// No description provided for @subscriptionYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionYearly;

  /// No description provided for @subscriptionMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get subscriptionMonth;

  /// No description provided for @subscriptionYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get subscriptionYear;

  /// Unmodified store formatted recurring price with localized period.
  ///
  /// In en, this message translates to:
  /// **'{recurringPrice} / {period}'**
  String subscriptionPrice(String recurringPrice, String period);

  /// Shown only when the store plan includes the supported seven-day trial.
  ///
  /// In en, this message translates to:
  /// **'7 days free, then {recurringPrice}. Cancel through Google Play before the trial ends.'**
  String subscriptionTrial(String recurringPrice);

  /// No description provided for @subscriptionRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically. You can cancel at any time through Google Play.'**
  String get subscriptionRenewal;

  /// No description provided for @subscriptionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Google Play…'**
  String get subscriptionWaiting;

  /// No description provided for @subscriptionStartTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 7-day trial'**
  String get subscriptionStartTrial;

  /// No description provided for @subscriptionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google Play'**
  String get subscriptionContinue;

  /// No description provided for @subscriptionStoreError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the store. Please try again later.'**
  String get subscriptionStoreError;

  /// No description provided for @subscriptionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subscriptionRestore;

  /// No description provided for @subscriptionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage / cancel subscription'**
  String get subscriptionManage;

  /// No description provided for @playTimeBreakTitle.
  ///
  /// In en, this message translates to:
  /// **'That’s enough for today. You did great!'**
  String get playTimeBreakTitle;

  /// No description provided for @playTimeBreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s take a little break now.'**
  String get playTimeBreakSubtitle;

  /// No description provided for @playTimeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get playTimeHome;

  /// No description provided for @playTimeExtendHint.
  ///
  /// In en, this message translates to:
  /// **'Unlock the parent gate to add 10 minutes'**
  String get playTimeExtendHint;

  /// No description provided for @playTimeExtend.
  ///
  /// In en, this message translates to:
  /// **'Parent: add 10 minutes'**
  String get playTimeExtend;

  /// Current page and total pages in the compact play-time break flow.
  ///
  /// In en, this message translates to:
  /// **'Break · {current} of {total}'**
  String playTimeBreakPageCount(int current, int total);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get familyCancel;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Use multiplication'**
  String get familyUseMultiplication;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Enter the same four digits twice.'**
  String get familyEnterTheSameFourDigitsTwice;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get familySave;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Parent PIN'**
  String get familyParentPin;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN'**
  String get family4DigitPin;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Repeat PIN'**
  String get familyRepeatPin;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Every step matters'**
  String get familyEveryStepMatters;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Your child is exploring at their own pace.'**
  String get familyYourChildIsExploringAtTheir;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Stars today'**
  String get familyStarsToday;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Rounds completed today'**
  String get familyRoundsCompletedToday;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Minutes today'**
  String get familyMinutesToday;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Stages this week'**
  String get familyStagesThisWeek;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Independent answers'**
  String get familyIndependentAnswers;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get familyLast7Days;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Play time · minutes'**
  String get familyPlayTimeMinutes;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Independent first answers · %'**
  String get familyIndependentFirstAnswers;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Progress will appear here after the first game.'**
  String get familyProgressWillAppearHereAfterThe;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Attention · daily average seconds'**
  String get familyAttentionDailyAverageSeconds;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'First response'**
  String get familyFirstResponse;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get familyS;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Idle time'**
  String get familyIdleTime;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Time in the background is excluded.'**
  String get familyTimeInTheBackgroundIsExcluded;

  /// Upper bound shown for average response and idle time.
  ///
  /// In en, this message translates to:
  /// **'0–{maximum} seconds.'**
  String familySecondsRange(double maximum);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Numeric view'**
  String get familyNumericView;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Skill areas'**
  String get familySkillAreas;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Independent first answers in the last 7 days'**
  String get familyIndependentFirstAnswersInTheLast;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get familyNoRecordsYet;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'{count} stages'**
  String familyCountStages(int count);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'points · compared with the previous week'**
  String get familyPointsComparedWithThePreviousWeek;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get familyItems;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Independent: last three answers without hints. Support: substantial help in at least two of the last three stages.'**
  String get familyIndependentLastThreeAnswersWithoutHints;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Independently answered'**
  String get familyIndependentlyAnswered;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Items needing more support'**
  String get familyItemsNeedingMoreSupport;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Items appear here after at least three observations.'**
  String get familyItemsAppearHereAfterAtLeast;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'{count} stages · latest {streak} answers independent'**
  String familyCountStagesLatestStreakAnswersIndependent(int count, int streak);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Progress by theme'**
  String get familyProgressByTheme;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Show unlocked games only'**
  String get familyShowUnlockedGamesOnly;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Hides locked cards in Child Mode.'**
  String get familyHidesLockedCardsInChildMode;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Easy and Medium unlocked'**
  String get familyEasyAndMediumUnlocked;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get familyPremium;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Daily screen time limit'**
  String get familyDailyScreenTimeLimit;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Counts active play time. A break screen opens when time runs out.'**
  String get familyCountsActivePlayTimeABreak;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get familyOff;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get familyMinutes;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Remaining today: {minutes} minutes'**
  String familyRemainingTodayMinutesMinutes(int minutes);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Add 10 minutes for today'**
  String get familyAdd10MinutesForToday;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Default difficulty'**
  String get familyDefaultDifficulty;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Automatic / theme selection'**
  String get familyAutomaticThemeSelection;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get familyEasy;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get familyMedium;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get familyHard;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Applies to new rounds. Hard level is included in Premium.'**
  String get familyAppliesToNewRoundsHardLevel;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Round length'**
  String get familyRoundLength;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Survey / difficulty setting'**
  String get familySurveyDifficultySetting;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'stages'**
  String get familyStages;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Hint delay'**
  String get familyHintDelay;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Automatic / per item'**
  String get familyAutomaticPerItem;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Timed hints off'**
  String get familyTimedHintsOff;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get familySeconds;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Next round behavior'**
  String get familyNextRoundBehavior;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Fade incorrect choices after 2 mistakes'**
  String get familyFadeIncorrectChoicesAfter2Mistakes;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Applies to the next round. Incorrect answers still receive support when timed hints are off.'**
  String get familyAppliesToTheNextRoundIncorrect;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Daily minute goal'**
  String get familyDailyMinuteGoal;

  /// Accessible summary of today's minutes and goal.
  ///
  /// In en, this message translates to:
  /// **'Today’s goal: {minutes} / {goal} minutes'**
  String familyTodayGoalProgress(double minutes, int goal);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'An optional reminder; it does not limit play time.'**
  String get familyAnOptionalReminderItDoesNot;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get familyMin;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get familyUpdate;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'A new version is available. You can update through Google Play.'**
  String get familyANewVersionIsAvailableYou;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Parent gate'**
  String get familyParentGate;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Multiplication question'**
  String get familyMultiplicationQuestion;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Introduce new items first'**
  String get familyIntroduceNewItemsFirst;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Show one card first, then offer choices.'**
  String get familyShowOneCardFirstThenOffer;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Adaptive difficulty'**
  String get familyAdaptiveDifficulty;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Changes apply only when a new round starts.'**
  String get familyChangesApplyOnlyWhenANew;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get familyAudio;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Speech volume'**
  String get familySpeechVolume;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Sound effect volume'**
  String get familySoundEffectVolume;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Show item labels'**
  String get familyShowItemLabels;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get familyReduceMotion;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get familyLanguage;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get familyCelebration;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get familySimple;

  /// Parent setting for a brief enhanced correct-answer celebration.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get familyFull;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Subscription prices and trial eligibility come from Google Play.'**
  String get familySubscriptionPricesAndTrialEligibilityCome;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Plans and restore'**
  String get familyPlansAndRestore;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get familyPrivacy;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Google family account'**
  String get familyGoogleFamilyAccount;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Credits and licenses'**
  String get familyCreditsAndLicenses;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Profiles and raw game records stay on this device. Only daily summaries are sent when you give permission and start sync in the account screen. No ads or advertising identifiers are used.'**
  String get familyProfilesAndRawGameRecordsStay;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Does not replace professional support.'**
  String get familyDoesNotReplaceProfessionalSupport;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get familySection;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Previous section'**
  String get familyPreviousSection;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Next section'**
  String get familyNextSection;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Child Mode'**
  String get familyChildMode;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get familyProgress;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get familyGames;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get familyProfiles;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get familySettings;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get familyStoredOnThisDevice;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get familyDeleteProfile;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Game and progress records for {name} will be deleted from this device.'**
  String familyGameAndProgressRecordsForName(String name);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get familyDelete;

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'Edit and questionnaire'**
  String get familyEditAndQuestionnaire;

  /// Profile action selected by the available profile allowance.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Create a profile} one{Create a profile} other{More profiles}}'**
  String familyProfileAction(int count);

  /// Family area interface copy.
  ///
  /// In en, this message translates to:
  /// **'The free version includes one child profile.'**
  String get familyTheFreeVersionIncludesOneChild;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Back to theme'**
  String get gameBackToTheme;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'This game needs sound. A parent can enable it in settings.'**
  String get gameThisGameNeedsSoundAParentCan;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'There is not enough content for this game yet.'**
  String get gameThereIsNotEnoughContentForThis;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Leave the game'**
  String get gameHoldToLeave;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get gameListenAgain;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get gamePreviousPage;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get gameNextPage;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get gameWellDone;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'You earned today’s sticker!'**
  String get gameYouEarnedTodaysSticker;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'We explored together.'**
  String get gameWeExploredTogether;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get gameAgain;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Today’s Path'**
  String get gameTodaysPath;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Images for this theme are not ready yet.'**
  String get gameImagesForThisThemeAreNotReady;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get gamePrevious;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get gameFinish;

  /// Game results and actions interface copy.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get gameNext;

  /// No description provided for @gameObject.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get gameObject;

  /// Accessible label for an object that can be counted during a game.
  ///
  /// In en, this message translates to:
  /// **'{object}, count {number}'**
  String gameCountedObjectSemantics(String object, int number);

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'No games are available today.'**
  String get dailyPathNoGamesAreAvailableToday;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'You earned today’s sticker!'**
  String get dailyPathYouEarnedTodaysSticker;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Each completed game is one step.'**
  String get dailyPathEachCompletedGameIsOneStep;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'My stickers'**
  String get dailyPathMyStickers;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dailyPathCompleted;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get dailyPathPlay;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Complete today’s path to earn your first sticker.'**
  String get dailyPathCompleteTodaysPathToEarnYourFirst;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Earned sticker'**
  String get dailyPathEarnedSticker;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get dailyPathPreviousPage;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String dailyPathPageCurrentOfTotal(int current, int total);

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get dailyPathNextPage;

  /// Daily path and sticker album interface copy.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dailyPathClose;

  /// Game completion summary pager position.
  ///
  /// In en, this message translates to:
  /// **'Summary · page {current} of {total}'**
  String gameSummaryPage(int current, int total);

  /// Numbered daily path game title.
  ///
  /// In en, this message translates to:
  /// **'{index}. {game}'**
  String dailyPathStepTitle(int index, String game);

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname.'**
  String get profileEditorNameRequired;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check the profile limit and try again.'**
  String get profileEditorSaveFailed;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditorEditTitle;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get profileEditorNewTitle;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Little explorer’s profile'**
  String get profileEditorIdentityHeading;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileEditorNicknameLabel;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Starting questionnaire'**
  String get profileEditorStartSurvey;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get profileEditorSaving;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileEditorSave;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Skip questionnaire and create'**
  String get profileEditorSkipQuestionnaireAndCreate;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileEditorContinue;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Skip this question'**
  String get profileEditorSkipQuestion;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Suggested starting point'**
  String get profileEditorSuggestedStart;

  /// Profile editor interface copy.
  ///
  /// In en, this message translates to:
  /// **'Save recommendations'**
  String get profileEditorSaveRecommendations;

  /// Profile editor horizontal pager progress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String profileEditorSurveyProgress(int current, int total);

  /// Profile editor horizontal pager progress.
  ///
  /// In en, this message translates to:
  /// **'Recommendation page {current} of {total}'**
  String profileEditorRecommendationProgress(int current, int total);

  /// Fixed instruction displayed in the G33 counting game.
  ///
  /// In en, this message translates to:
  /// **'How many are there?'**
  String get gamePromptCount;

  /// Fixed instruction displayed in the non-hard G36 comparison game.
  ///
  /// In en, this message translates to:
  /// **'Which has more?'**
  String get gamePromptCompareMagnitude;

  /// Fixed instruction displayed in the hard G36 comparison game.
  ///
  /// In en, this message translates to:
  /// **'Compare these numbers'**
  String get gamePromptCompareNumbers;

  /// Fixed instruction displayed in the G04 grouping game.
  ///
  /// In en, this message translates to:
  /// **'Which group does this belong to?'**
  String get gamePromptGroupMembership;

  /// Fixed instruction displayed in G14.
  ///
  /// In en, this message translates to:
  /// **'Find the match'**
  String get gamePromptFindMatch;

  /// Fixed instruction displayed in G10 for numbers.
  ///
  /// In en, this message translates to:
  /// **'Listen. Which number?'**
  String get gamePromptListenForNumber;

  /// Fixed instruction displayed in G10 for non-number themes.
  ///
  /// In en, this message translates to:
  /// **'Listen. What makes this sound?'**
  String get gamePromptListenForSoundSource;

  /// Fixed non-hard instruction displayed in G35.
  ///
  /// In en, this message translates to:
  /// **'Which number comes next?'**
  String get gamePromptSequenceNext;

  /// Fixed hard instruction displayed in G35.
  ///
  /// In en, this message translates to:
  /// **'Which number is missing?'**
  String get gamePromptSequenceMissing;

  /// No description provided for @obStart.
  ///
  /// In en, this message translates to:
  /// **'Let’s begin'**
  String get obStart;

  /// No description provided for @obBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get obBack;

  /// No description provided for @obSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get obSkip;

  /// No description provided for @obChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your child'**
  String get obChildTitle;

  /// No description provided for @obChildBody.
  ///
  /// In en, this message translates to:
  /// **'We use this to choose a gentle starting point. You can change it later in the family area.'**
  String get obChildBody;

  /// No description provided for @obNicknameOptional.
  ///
  /// In en, this message translates to:
  /// **'Nickname (optional)'**
  String get obNicknameOptional;

  /// No description provided for @obAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get obAgeTitle;

  /// No description provided for @obAgeTenPlus.
  ///
  /// In en, this message translates to:
  /// **'10+'**
  String get obAgeTenPlus;

  /// No description provided for @obAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String obAgeYears(int age);

  /// No description provided for @obDefaultNickname.
  ///
  /// In en, this message translates to:
  /// **'Little explorer'**
  String get obDefaultNickname;

  /// No description provided for @obMultipleHint.
  ///
  /// In en, this message translates to:
  /// **'You can choose more than one.'**
  String get obMultipleHint;

  /// No description provided for @obStepSemantics.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String obStepSemantics(int current, int total);

  /// No description provided for @obGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily play goal'**
  String get obGoalTitle;

  /// No description provided for @obGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Short, regular sessions work best. Your child sees calm progress, never a countdown.'**
  String get obGoalBody;

  /// No description provided for @obGoalMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String obGoalMinutes(int minutes);

  /// No description provided for @obRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get obRecommended;

  /// No description provided for @obLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings stay with you'**
  String get obLockTitle;

  /// No description provided for @obLockBody.
  ///
  /// In en, this message translates to:
  /// **'To return to the family area, tap “Family” on the home screen. A short parent check (a simple question, or your PIN) keeps children out.'**
  String get obLockBody;

  /// No description provided for @obPinSwitch.
  ///
  /// In en, this message translates to:
  /// **'Also set a 4-digit PIN'**
  String get obPinSwitch;

  /// No description provided for @obPinField.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get obPinField;

  /// No description provided for @obPinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter four digits.'**
  String get obPinInvalid;

  /// No description provided for @obTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore every game'**
  String get obTrialTitle;

  /// No description provided for @obTrialBody.
  ///
  /// In en, this message translates to:
  /// **'The free games stay free. Premium opens every theme and game, all difficulty levels and up to five child profiles.'**
  String get obTrialBody;

  /// No description provided for @obTrialPoint1.
  ///
  /// In en, this message translates to:
  /// **'All themes and games'**
  String get obTrialPoint1;

  /// No description provided for @obTrialPoint2.
  ///
  /// In en, this message translates to:
  /// **'Every difficulty level'**
  String get obTrialPoint2;

  /// No description provided for @obTrialPoint3.
  ///
  /// In en, this message translates to:
  /// **'Up to five child profiles'**
  String get obTrialPoint3;

  /// No description provided for @obTrialStart.
  ///
  /// In en, this message translates to:
  /// **'Try 7 days free'**
  String get obTrialStart;

  /// No description provided for @obTrialNote.
  ///
  /// In en, this message translates to:
  /// **'Billed by Google Play after the trial. You can cancel any time in Google Play.'**
  String get obTrialNote;

  /// No description provided for @obContinueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue for free'**
  String get obContinueFree;

  /// No description provided for @obHandoffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn the phone sideways and hand it to your child.'**
  String get obHandoffBody;

  /// No description provided for @obHandoffNote.
  ///
  /// In en, this message translates to:
  /// **'The games open in landscape. The family area opens upright.'**
  String get obHandoffNote;

  /// No description provided for @gamePromptOddOneOut.
  ///
  /// In en, this message translates to:
  /// **'Find the one that is different'**
  String get gamePromptOddOneOut;

  /// No description provided for @gamePromptShadowMatch.
  ///
  /// In en, this message translates to:
  /// **'Find its shadow'**
  String get gamePromptShadowMatch;

  /// No description provided for @gamePromptSortIntoBasket.
  ///
  /// In en, this message translates to:
  /// **'Put it in the right basket'**
  String get gamePromptSortIntoBasket;

  /// No description provided for @gamePromptNumberQuantity.
  ///
  /// In en, this message translates to:
  /// **'Find this many'**
  String get gamePromptNumberQuantity;

  /// No description provided for @gamePromptFillCount.
  ///
  /// In en, this message translates to:
  /// **'Put {count} in the basket'**
  String gamePromptFillCount(int count);

  /// No description provided for @gameFillBasketCount.
  ///
  /// In en, this message translates to:
  /// **'Basket: {count} of {goal}'**
  String gameFillBasketCount(int count, int goal);

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Special Education Games'**
  String get appTitle;

  /// No description provided for @gamePromptWhichSound.
  ///
  /// In en, this message translates to:
  /// **'Which sound does it make?'**
  String get gamePromptWhichSound;

  /// No description provided for @gameListenToSound.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get gameListenToSound;

  /// No description provided for @famToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get famToday;

  /// No description provided for @famGoalShort.
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} min'**
  String famGoalShort(int done, int goal);

  /// No description provided for @famGoalDone.
  ///
  /// In en, this message translates to:
  /// **'Today’s goal is reached. Well done!'**
  String get famGoalDone;

  /// No description provided for @famGoalLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} more minutes to today’s goal.'**
  String famGoalLeft(int minutes);

  /// No description provided for @famPlayedToday.
  ///
  /// In en, this message translates to:
  /// **'Played today: {minutes} min'**
  String famPlayedToday(int minutes);

  /// No description provided for @famMinutesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Minutes this week'**
  String get famMinutesThisWeek;

  /// No description provided for @famDaysPlayed.
  ///
  /// In en, this message translates to:
  /// **'Days played this week'**
  String get famDaysPlayed;

  /// No description provided for @famThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get famThisWeek;

  /// No description provided for @famRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get famRecentlyPlayed;

  /// No description provided for @famRecentlyLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned recently'**
  String get famRecentlyLearned;

  /// No description provided for @famNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Play a round together!'**
  String get famNothingYet;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'Age level'**
  String get familyAgeLevel;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'Easier'**
  String get familyAgeLevelEasier;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'By age'**
  String get familyAgeLevelByAge;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'Harder'**
  String get familyAgeLevelHarder;

  /// Family settings: the band the child's age gives.
  ///
  /// In en, this message translates to:
  /// **'By age: {band}'**
  String familyAgeLevelFromAge(String band);

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'No age in this profile. Add it in the profile editor.'**
  String get familyAgeLevelNoAge;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'Applies to new games. Easy/Medium/Hard and automatic difficulty still work; Hard stays premium.'**
  String get familyAgeLevelNote;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'First steps (2–3)'**
  String get ageBandFirstSteps;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'Explore (4–5)'**
  String get ageBandExplore;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'School ready (6–7)'**
  String get ageBandSchoolReady;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'Practice (8+)'**
  String get ageBandPractice;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'2 choices, numbers 1–3, 5 questions per game, quick hints; tap games first.'**
  String get ageBandFirstStepsInfo;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'3 choices, numbers 1–5, 6 questions per game; tap and simple drag.'**
  String get ageBandExploreInfo;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'4 choices, numbers 1–10, 8 questions per game; drag, group and sort.'**
  String get ageBandSchoolReadyInfo;

  /// Age band copy.
  ///
  /// In en, this message translates to:
  /// **'4 choices, numbers 1–20, 10 questions per game, less familiar items, later hints.'**
  String get ageBandPracticeInfo;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Try free for {days} days'**
  String paywallTrialTitle(int days);

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Every game and level is open for {days} days. No payment details needed; afterwards the free games stay open.'**
  String paywallTrialBody(int days);

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to start'**
  String get paywallTrialSignIn;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Start free trial'**
  String get paywallTrialStart;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Trial active: {days} days left'**
  String paywallTrialActive(int days);

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'This account\'s free trial has been used.'**
  String get paywallTrialUsed;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'The trial could not be started. Check the internet connection and try again.'**
  String get paywallTrialError;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'One free trial per Google account.'**
  String get paywallTrialNote;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'The free version always keeps {count} games open.'**
  String paywallFreeTier(int count);

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get paywallLifetime;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Pay once, keep it forever. No subscription.'**
  String get paywallLifetimeNote;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get paywallBuy;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'You own Premium for life.'**
  String get paywallLifetimeOwned;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get paywallPrivacy;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get paywallTerms;

  /// Account deletion copy.
  ///
  /// In en, this message translates to:
  /// **'Delete account and cloud data'**
  String get familyAccountDelete;

  /// Account deletion copy.
  ///
  /// In en, this message translates to:
  /// **'Delete the account?'**
  String get familyAccountDeleteTitle;

  /// Account deletion copy.
  ///
  /// In en, this message translates to:
  /// **'The family account linked to your Google account and the learning summaries in the cloud are deleted permanently. You will be asked to confirm with Google first. Profiles and progress on this device are not deleted; uninstall the app to remove them.'**
  String get familyAccountDeleteBody;

  /// Account deletion copy.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get familyAccountDeleteConfirm;

  /// Account deletion copy.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get familyAccountDeleteCancel;

  /// Account deletion copy.
  ///
  /// In en, this message translates to:
  /// **'The account and cloud data were deleted.'**
  String get familyAccountDeleted;

  /// Account deletion copy.
  ///
  /// In en, this message translates to:
  /// **'The account could not be deleted. Check the internet connection and try again.'**
  String get familyAccountDeleteFailed;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Unlock every game'**
  String get paywallHeadline;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'No payment details'**
  String get paywallNoPayment;

  /// Paywall badge.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSave(int percent);

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Continue with the free version'**
  String get paywallContinueFree;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get paywallRestoreShort;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Plans could not be loaded.'**
  String get paywallPlansFailed;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get paywallRetry;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get paywallClose;

  /// Paywall copy.
  ///
  /// In en, this message translates to:
  /// **'Pay once'**
  String get paywallOneTimeShort;

  /// Family settings: automatic cloud summary sync.
  ///
  /// In en, this message translates to:
  /// **'Send daily summaries to the cloud'**
  String get familyCloudSync;

  /// Family settings: automatic cloud summary sync.
  ///
  /// In en, this message translates to:
  /// **'While signed in with Google, a daily summary of the games played (game, minutes, rounds) is saved to your account automatically. The child\'s name is not sent.'**
  String get familyCloudSyncNote;

  /// Welcome page: trial banner above the start button.
  ///
  /// In en, this message translates to:
  /// **'Try every game free for {days} days'**
  String welcomeFreeTrial(int days);

  /// Paywall badge on the yearly plan.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get paywallBestValue;

  /// Paywall: per-month equivalent of a plan.
  ///
  /// In en, this message translates to:
  /// **'{price}/mo'**
  String paywallPerMonth(String price);

  /// Paywall: yearly price line.
  ///
  /// In en, this message translates to:
  /// **'{price}/year'**
  String paywallPerYear(String price);

  /// Paywall: monthly plan line.
  ///
  /// In en, this message translates to:
  /// **'Renews every month'**
  String get paywallRenewsMonthly;

  /// Paywall primary button while the trial is unused.
  ///
  /// In en, this message translates to:
  /// **'Try free for {days} days'**
  String paywallStartTrial(int days);

  /// Paywall line under the trial button.
  ///
  /// In en, this message translates to:
  /// **'No card needed. When the trial ends you go back to the free version, or continue with the plan you choose.'**
  String get paywallTrialFootnote;

  /// Paywall primary button for a purchase.
  ///
  /// In en, this message translates to:
  /// **'Continue · {price}'**
  String paywallContinuePrice(String price);

  /// Paywall line under the subscription button.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime in Google Play.'**
  String get paywallCancelAnytime;

  /// Welcome page: second line of the trial banner.
  ///
  /// In en, this message translates to:
  /// **'{count} games stay free afterwards.'**
  String welcomeFreeAfter(int count);

  /// Paywall: small line under the monthly price.
  ///
  /// In en, this message translates to:
  /// **'every month'**
  String get paywallEveryMonth;

  /// Paywall: small line under the one-time price.
  ///
  /// In en, this message translates to:
  /// **'one payment'**
  String get paywallOnePayment;

  /// Paywall: monthly plan line.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get paywallCancelShort;

  /// Paywall: one-time plan line.
  ///
  /// In en, this message translates to:
  /// **'No subscription'**
  String get paywallNoSubscription;

  /// Child mode: locked game dialog title.
  ///
  /// In en, this message translates to:
  /// **'This game is locked'**
  String get lockedGameTitle;

  /// Child mode: locked game dialog text.
  ///
  /// In en, this message translates to:
  /// **'Ask your family to unlock it. You can play the open games for now.'**
  String get lockedGameBody;

  /// Child mode: locked game dialog button.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get lockedGameOk;

  /// Family area: Premium strip title once the trial is used.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get familyPremiumStripBuy;

  /// Family area: Premium strip line.
  ///
  /// In en, this message translates to:
  /// **'Every game and detailed progress'**
  String get familyPremiumStripNote;

  /// Family progress: locked statistics title.
  ///
  /// In en, this message translates to:
  /// **'Detailed progress comes with Premium'**
  String get familyLockedStatsTitle;

  /// Family progress: locked statistics text.
  ///
  /// In en, this message translates to:
  /// **'Weekly charts, attention, skills and per-item results.'**
  String get familyLockedStatsBody;

  /// Family progress: locked statistics button.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Premium'**
  String get familyLockedStatsButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
