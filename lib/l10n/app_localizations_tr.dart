// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get welcomeTitle => 'Her küçük adım,\nbüyük bir keşif.';

  @override
  String get welcomeSubtitle =>
      'Çocuğunuzun hızında, sakin ve eğlenceli öğrenme.';

  @override
  String get welcomeLearnPlaying => 'Çocuğunuz eğlenirken öğrenir';

  @override
  String get welcomeTopics => 'Hayvanlar, renkler, sayılar';

  @override
  String get welcomeOwnPace => 'Yaşa göre ayarlanır';

  @override
  String get noAdsOffline => 'Reklam yok.';

  @override
  String get homeFamily => 'Aile';

  @override
  String get homeGames => 'Oyunlar';

  @override
  String get homeDailyPath => 'Bugünün Yolu';

  @override
  String get homeFamilyHint => 'Aile bölümü (ebeveyn kontrolü açılır)';

  @override
  String greeting(String name) {
    return 'Merhaba, $name';
  }

  @override
  String get homePathSubtitle => 'Küçük adımlarla keşfedelim.';

  @override
  String get homeGamesSubtitle => 'Bugün ne keşfedelim?';

  @override
  String get homeNewBadge => 'Yeni';

  @override
  String homeThemeGameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyun',
      one: '$count oyun',
      zero: '0 oyun',
    );
    return '$_temp0';
  }

  @override
  String get storiesTitle => 'Hikâyeler';

  @override
  String storiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hikâye',
      one: '$count hikâye',
      zero: '0 hikâye',
    );
    return '$_temp0';
  }

  @override
  String get storyNext => 'Devam';

  @override
  String get themeBack => 'Geri';

  @override
  String get difficultyEasy => 'Kolay';

  @override
  String get difficultyMedium => 'Orta';

  @override
  String get difficultyHard => 'Zor';

  @override
  String get themeNoUnlockedGames =>
      'Bu zorlukta açık oyun yok. Kolay’ı seçebilirsin.';

  @override
  String get parentGateTitle => 'Aile bölümü';

  @override
  String get parentGateEnterPin => 'PIN girin';

  @override
  String get parentGateContinuePrompt => 'Devam etmek için';

  @override
  String get parentGateWrongPin => 'PIN’i tekrar deneyin.';

  @override
  String get parentGateWrongMath => 'Yeni soruyu deneyin.';

  @override
  String get parentGateForgotPin => 'PIN’i unuttum';

  @override
  String get parentGateCancel => 'Vazgeç';

  @override
  String get onboardingSaveError => 'Kaydedilemedi. Tekrar deneyin.';

  @override
  String onboardingReadyTitle(String name) {
    return 'Hazırız, $name!';
  }

  @override
  String get onboardingFamilyHint => 'Aile bölümünden değiştirebilirsiniz.';

  @override
  String get onboardingSaving => 'Kaydediliyor…';

  @override
  String get onboardingPlay => 'Oyunlara geç';

  @override
  String get onboardingContinue => 'Devam et';

  @override
  String get onboardingNicknameHint => 'Bir takma ad yeterli.';

  @override
  String onboardingStepCount(int current, int total) {
    return '$current / $total';
  }

  @override
  String get surveyPreviousOption => 'Önceki seçenek';

  @override
  String get surveyNextOption => 'Sonraki seçenek';

  @override
  String surveyOptionCount(int current, int total) {
    return '$current / $total';
  }

  @override
  String surveyOptionProgress(int current, int total) {
    return 'Seçenek $current / $total';
  }

  @override
  String get accountTitle => 'Hesap';

  @override
  String get familyAccountTitle => 'Aile hesabı';

  @override
  String get familyAccountSignedIn => 'Google hesabına giriş yapıldı.';

  @override
  String get familyAccountLocalProgress =>
      'Ayrıntılı ilerleme bu cihazda saklanır. Günlük özet paylaşımı aşağıda ayrı izin gerektirir.';

  @override
  String get familyAccountSignIn => 'Google ile giriş';

  @override
  String get familyAccountSignOut => 'Çıkış yap';

  @override
  String get familyAccountCancelled => 'Giriş iptal edildi.';

  @override
  String get familyAccountOffline =>
      'Bağlantı kurulamadı. İnterneti kontrol edip tekrar deneyin.';

  @override
  String get familyAccountConfiguration => 'Giriş şu anda kullanılamıyor.';

  @override
  String get familyAccountTimeout =>
      'Giriş zaman aşımına uğradı. Tekrar deneyin.';

  @override
  String get familyAccountUnavailable =>
      'Giriş şu anda kullanılamıyor. Biraz sonra tekrar deneyin.';

  @override
  String get creditsTitle => 'Kaynaklar ve lisanslar';

  @override
  String get creditsLoadFailure => 'Kaynak bilgileri yüklenemedi.';

  @override
  String get creditsAnimalRecordings => 'Doğal sesler';

  @override
  String get creditsRealPhotographs => 'Gerçek fotoğraflar';

  @override
  String get creditsAdaptationLicense => 'Uyarlama lisansı';

  @override
  String get creditsAuthor => 'Sanatçı';

  @override
  String get creditsLicense => 'Lisans';

  @override
  String get creditsPreviousImageCredit => 'Önceki görsel kredisi';

  @override
  String get creditsSource => 'Kaynak';

  @override
  String get creditsLicenseLink => 'Lisans bağlantısı';

  @override
  String get creditsChanges => 'Düzenleme';

  @override
  String get creditsImagePreparedForAppUse =>
      'Görsel uygulama için hazırlandı.';

  @override
  String get creditsAudioEditedForInAppPlayback =>
      'Ses uygulama içi çalma için düzenlendi.';

  @override
  String get creditsPreviousRecord => 'Önceki kayıt';

  @override
  String get creditsNextRecord => 'Sonraki kayıt';

  @override
  String creditsRecordDetailProgress(
    int record,
    int recordTotal,
    int detail,
    int detailTotal,
  ) {
    return 'Kayıt $record / $recordTotal, ayrıntı $detail / $detailTotal';
  }

  @override
  String get creditsLicensesLoadFailure => 'Lisans bilgileri yüklenemedi.';

  @override
  String get creditsLicensesEmpty => 'Kayıtlı lisans yok.';

  @override
  String get familyNewsHeading => 'Yenilikler';

  @override
  String get creditsOpenSourceLicenses => 'Açık kaynak yazılım lisansları';

  @override
  String get summarySyncTitle => 'Günlük özetleri eşitle';

  @override
  String get summarySyncDescription =>
      'Buluta yalnız günlük süre ve tur sayısı gider. Çocuğun cevapları gitmez.';

  @override
  String get summarySyncRequirements =>
      'Eşitlemek için ebeveyn erişimi, bir profil ve Google girişi gerekir.';

  @override
  String get summarySyncConsent =>
      'Bu hesap ve profil için günlük özet paylaşımına izin veriyorum.';

  @override
  String get summarySyncManualNotice =>
      'Eşitleme yalnız aşağıdaki düğmeyle başlar. İzni kaldırmak bu telefondaki özeti temizler; buluttaki veriyi silmez.';

  @override
  String get summarySyncNow => 'Şimdi eşitle';

  @override
  String summarySyncSnapshot(int count, String savedAt) {
    return 'Cihazdaki eşitlenmiş özet: $count kayıt. Kaydedildi: $savedAt';
  }

  @override
  String get summarySyncCapacity =>
      'Çok fazla kayıt var, bir kısmı gönderilemedi. Telefondaki kayıtlar duruyor.';

  @override
  String get summarySyncUnavailable =>
      'Eşitleme tamamlanamadı. Bağlantı veya sunucu kullanılamıyor olabilir. Yerel kayıtlar korunuyor.';

  @override
  String get subscriptionTitle => 'Premium';

  @override
  String get subscriptionAllGames => 'Tüm oyunlar ve zorluklar';

  @override
  String get subscriptionProfiles => 'Beş çocuk profiline kadar';

  @override
  String get subscriptionAdFree => 'Ayrıntılı ilerleme raporları';

  @override
  String get subscriptionActive => 'Premium erişiminiz açık.';

  @override
  String get subscriptionMonthly => 'Aylık';

  @override
  String get subscriptionYearly => 'Yıllık';

  @override
  String get subscriptionWaiting => 'Google Play bekleniyor…';

  @override
  String get subscriptionStoreError =>
      'Mağazaya bağlanılamadı. Lütfen daha sonra tekrar deneyin.';

  @override
  String get subscriptionManage => 'Aboneliği yönet / iptal et';

  @override
  String get playTimeBreakTitle => 'Bugünlük bu kadar, harikaydın!';

  @override
  String get playTimeBreakSubtitle => 'Şimdi küçük bir mola verelim.';

  @override
  String get playTimeHome => 'Ana sayfa';

  @override
  String get playTimeExtendHint =>
      '10 dakika eklemek için ebeveyn kilidini açın';

  @override
  String get playTimeExtend => 'Ebeveyn: 10 dakika ekle';

  @override
  String playTimeBreakPageCount(int current, int total) {
    return 'Mola · $current / $total';
  }

  @override
  String get familyCancel => 'Vazgeç';

  @override
  String get familyUseMultiplication => 'Çarpma sorusu kullan';

  @override
  String get familyEnterTheSameFourDigitsTwice =>
      'Aynı 4 rakamı iki kez yazın.';

  @override
  String get familySave => 'Kaydet';

  @override
  String get familyParentPin => 'Ebeveyn PIN’i';

  @override
  String get family4DigitPin => '4 haneli PIN';

  @override
  String get familyRepeatPin => 'PIN’i tekrar yazın';

  @override
  String get familyEveryStepMatters => 'Her adım değerli';

  @override
  String get familyYourChildIsExploringAtTheir =>
      'Çocuğunuz kendi hızında keşfediyor.';

  @override
  String get familyStarsToday => 'Bugünkü yıldızlar';

  @override
  String get familyRoundsCompletedToday => 'Bugün tamamlanan tur';

  @override
  String get familyMinutesToday => 'Bugünkü dakika';

  @override
  String get familyStagesThisWeek => 'Bu hafta tamamlanan aşama';

  @override
  String get familyIndependentAnswers => 'İpucusuz doğru';

  @override
  String get familyLast7Days => 'Son 7 gün';

  @override
  String get familyPlayTimeMinutes => 'Oynama süresi (dk)';

  @override
  String get familyIndependentFirstAnswers => 'Kendi başına doğru (%)';

  @override
  String get familyProgressWillAppearHereAfterThe =>
      'Grafikler ilk oyundan sonra dolar.';

  @override
  String get familyAttentionDailyAverageSeconds => 'Cevap süresi (sn)';

  @override
  String get familyFirstResponse => 'İlk cevap';

  @override
  String get familyS => 'sn';

  @override
  String get familyIdleTime => 'Cevapsız bekleme';

  @override
  String get familyTimeInTheBackgroundIsExcluded =>
      'Arka planda geçen süre dahil değildir.';

  @override
  String get familySkillAreas => 'Beceriler';

  @override
  String get familyIndependentFirstAnswersInTheLast =>
      'Son 7 günde ipucusuz, ilk denemede doğru';

  @override
  String get familyNoRecordsYet => 'Henüz kayıt yok';

  @override
  String familyCountStages(int count) {
    return '$count aşama';
  }

  @override
  String get familyPointsComparedWithThePreviousWeek =>
      'puan · önceki haftaya göre';

  @override
  String get familyItems => 'Öğeler';

  @override
  String get familyIndependentLastThreeAnswersWithoutHints =>
      'Kendi başına: son 3 cevap ipucusuz doğru. Destek: son 3 turun 2’sinde yardım aldı.';

  @override
  String get familyIndependentlyAnswered => 'Kendi başına biliyor';

  @override
  String get familyItemsNeedingMoreSupport => 'Daha çok destek istiyor';

  @override
  String get familyItemsAppearHereAfterAtLeast => 'Üç denemeden sonra görünür.';

  @override
  String familyCountStagesLatestStreakAnswersIndependent(
    int count,
    int streak,
  ) {
    return '$count aşama · son $streak yanıt bağımsız';
  }

  @override
  String get familyProgressByTheme => 'Tema gelişimi';

  @override
  String get familyDailyScreenTimeLimit => 'Günlük ekran süresi sınırı';

  @override
  String get familyCountsActivePlayTimeABreak =>
      'Süre dolunca mola ekranı açılır.';

  @override
  String get familyOff => 'Kapalı';

  @override
  String get familyMinutes => 'dakika';

  @override
  String familyRemainingTodayMinutesMinutes(int minutes) {
    return 'Bugün kalan: $minutes dakika';
  }

  @override
  String get familyAdd10MinutesForToday => 'Bugün için 10 dakika ekle';

  @override
  String get familyDefaultDifficulty => 'Genel zorluk';

  @override
  String get familyAutomaticThemeSelection => 'Temaya göre otomatik';

  @override
  String get familyEasy => 'Kolay';

  @override
  String get familyMedium => 'Orta';

  @override
  String get familyHard => 'Zor';

  @override
  String get familyAppliesToNewRoundsHardLevel => 'Zor seviye Premium\'da.';

  @override
  String get familyRoundLength => 'Tur uzunluğu';

  @override
  String get familySurveyDifficultySetting => 'Başlangıç anketine göre';

  @override
  String get familyStages => 'aşama';

  @override
  String get familyHintDelay => 'İpucu başlangıcı';

  @override
  String get familyAutomaticPerItem => 'Otomatik / öğeye göre';

  @override
  String get familyTimedHintsOff => 'Zamanlı ipucu kapalı';

  @override
  String get familySeconds => 'saniye';

  @override
  String get familyNextRoundBehavior => 'Yeni tur davranışı';

  @override
  String get familyFadeIncorrectChoicesAfter2Mistakes =>
      '2 yanlış sonrası seçenekleri soluklaştır';

  @override
  String get familyAppliesToTheNextRoundIncorrect =>
      'Sonraki turdan itibaren geçerli.';

  @override
  String get familyDailyMinuteGoal => 'Günlük dakika hedefi';

  @override
  String familyTodayGoalProgress(double minutes, int goal) {
    return 'Bugünkü hedef: $minutes / $goal dakika';
  }

  @override
  String get familyAnOptionalReminderItDoesNot =>
      'Sadece bir hedef; oyunu sınırlamaz.';

  @override
  String get familyMin => 'dk';

  @override
  String get familyUpdate => 'Güncelleme';

  @override
  String get familyANewVersionIsAvailableYou =>
      'Uygulamanın yeni sürümü var. Google Play üzerinden güncelleyebilirsiniz.';

  @override
  String get familyParentGate => 'Ebeveyn kilidi';

  @override
  String get familyMultiplicationQuestion => 'Çarpma sorusu';

  @override
  String get familyIntroduceNewItemsFirst => 'Yeni öğeleri önce tanıt';

  @override
  String get familyShowOneCardFirstThenOffer =>
      'Önce tek kart, sonra seçenekler.';

  @override
  String get familyAdaptiveDifficulty => 'Otomatik zorluk önerisi';

  @override
  String get familyChangesApplyOnlyWhenANew =>
      'Sonraki turdan itibaren geçerli.';

  @override
  String get familyAudio => 'Sesler';

  @override
  String get familySpeechVolume => 'Konuşma ses düzeyi';

  @override
  String get familySoundEffectVolume => 'Efekt ses düzeyi';

  @override
  String get familyShowItemLabels => 'Öğe adlarını göster';

  @override
  String get familyReduceMotion => 'Hareketleri azalt';

  @override
  String get familyLanguage => 'Dil';

  @override
  String get familyCelebration => 'Kutlama';

  @override
  String get familySimple => 'Sade';

  @override
  String get familyFull => 'Tam';

  @override
  String get familyPrivacy => 'Gizlilik';

  @override
  String get familyGoogleFamilyAccount => 'Google aile hesabı';

  @override
  String get familyCreditsAndLicenses => 'Kaynaklar ve lisanslar';

  @override
  String get familyProfilesAndRawGameRecordsStay =>
      'Çocuk profilleri hesabınıza kaydedilir; ayrıntılı oyun kayıtları bu cihazda kalır. Reklam yok.';

  @override
  String get familyDoesNotReplaceProfessionalSupport =>
      'Uzman desteğinin yerini tutmaz.';

  @override
  String get familySection => 'Bölüm';

  @override
  String get familyPreviousSection => 'Önceki bölüm';

  @override
  String get familyNextSection => 'Sonraki bölüm';

  @override
  String get familyChildMode => 'Çocuk Modu';

  @override
  String get familyProgress => 'Gelişim';

  @override
  String get familyGames => 'Oyunlar';

  @override
  String get familyProfiles => 'Profiller';

  @override
  String get familySettings => 'Ayarlar';

  @override
  String get familyDeleteProfile => 'Profili sil';

  @override
  String familyGameAndProgressRecordsForName(String name) {
    return '$name profilinin bu cihazdaki oyun ve gelişim kayıtları silinecek.';
  }

  @override
  String get familyDelete => 'Sil';

  @override
  String get familyEditAndQuestionnaire => 'Düzenle ve anket';

  @override
  String familyProfileAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Daha fazla profil',
      one: 'Yeni profil oluştur',
      zero: 'Yeni profil oluştur',
    );
    return '$_temp0';
  }

  @override
  String get gameBackToTheme => 'Temaya dön';

  @override
  String get gameThisGameNeedsSoundAParentCan =>
      'Bu oyun için ses gerekli. Ebeveyn ayarlarından sesi açabilirsiniz.';

  @override
  String get gameThereIsNotEnoughContentForThis =>
      'Bu oyun için yeterli içerik henüz hazır değil.';

  @override
  String get gameHoldToLeave => 'Oyundan çık';

  @override
  String get gameListenAgain => 'Tekrar dinle';

  @override
  String get gamePreviousPage => 'Önceki sayfa';

  @override
  String get gameNextPage => 'Sonraki sayfa';

  @override
  String get gameWellDone => 'Aferin!';

  @override
  String get gameYouEarnedTodaysSticker => 'Bugünün çıkartmasını kazandın!';

  @override
  String get gameWeExploredTogether => 'Birlikte keşfettik.';

  @override
  String get gameAgain => 'Tekrar';

  @override
  String get gameImagesForThisThemeAreNotReady =>
      'Bu temanın görselleri henüz hazır değil.';

  @override
  String get gamePrevious => 'Önceki';

  @override
  String get gameFinish => 'Tamamla';

  @override
  String get gameNext => 'Sonraki';

  @override
  String get gameNextGame => 'Sonraki oyun';

  @override
  String get reminderTitle => 'Oyun zamanı';

  @override
  String get reminderBody => 'Bugün birlikte birkaç dakika oynayalım mı?';

  @override
  String get reminderChannel => 'Günlük oyun hatırlatması';

  @override
  String get reminderOfferTitle => 'Günlük hatırlatma';

  @override
  String get reminderOfferBody =>
      'O gün oynanmadıysa akşam 18:00\'de kısa bir hatırlatma gönderelim mi?';

  @override
  String get reminderOfferYes => 'Evet, hatırlat';

  @override
  String get reminderOfferNo => 'Şimdi değil';

  @override
  String get gameObject => 'Nesne';

  @override
  String gameCountedObjectSemantics(String object, int number) {
    return '$object, say $number';
  }

  @override
  String get dailyPathNoGamesAreAvailableToday => 'Bugün açık oyun bulunmuyor.';

  @override
  String get dailyPathMyStickers => 'Çıkartmalarım';

  @override
  String get dailyPathCompleted => 'Tamamlandı';

  @override
  String get dailyPathPlay => 'Oyna';

  @override
  String get dailyPathCompleteTodaysPathToEarnYourFirst =>
      'Bugünün yolunu tamamlayıp ilk çıkartmanı kazanabilirsin.';

  @override
  String get dailyPathEarnedSticker => 'Kazanılan çıkartma';

  @override
  String get dailyPathPreviousPage => 'Önceki sayfa';

  @override
  String dailyPathPageCurrentOfTotal(int current, int total) {
    return 'Sayfa $current / $total';
  }

  @override
  String get dailyPathNextPage => 'Sonraki sayfa';

  @override
  String get dailyPathClose => 'Kapat';

  @override
  String get profileEditorNameRequired => 'Bir takma ad yazın.';

  @override
  String get profileEditorSaveFailed =>
      'Kaydedilemedi. Profil sınırını ve bağlantıyı kontrol edin.';

  @override
  String get profileEditorEditTitle => 'Profili düzenle';

  @override
  String get profileEditorNewTitle => 'Yeni profil';

  @override
  String get profileEditorIdentityHeading => 'Küçük kaşifin profili';

  @override
  String get profileEditorNicknameLabel => 'Takma ad';

  @override
  String get profileEditorStartSurvey => 'Başlangıç anketi';

  @override
  String get profileEditorSaving => 'Kaydediliyor…';

  @override
  String get profileEditorSave => 'Kaydet';

  @override
  String get profileEditorSkipQuestionnaireAndCreate =>
      'Anketi atla ve oluştur';

  @override
  String get profileEditorContinue => 'Devam et';

  @override
  String get profileEditorSkipQuestion => 'Bu soruyu atla';

  @override
  String get profileEditorSuggestedStart => 'Önerilen başlangıç';

  @override
  String get profileEditorSaveRecommendations => 'Önerileri kaydet';

  @override
  String profileEditorSurveyProgress(int current, int total) {
    return 'Soru $current / $total';
  }

  @override
  String profileEditorRecommendationProgress(int current, int total) {
    return 'Öneri sayfası $current / $total';
  }

  @override
  String get gamePromptCount => 'Kaç tane var?';

  @override
  String get gamePromptCompareMagnitude => 'Hangisi daha çok?';

  @override
  String get gamePromptCompareNumbers => 'Bu sayıları karşılaştır';

  @override
  String get gamePromptGroupMembership => 'Bu hangi grupta?';

  @override
  String get gamePromptFindMatch => 'Aynısını bul';

  @override
  String get gamePromptListenForNumber => 'Dinle. Hangi sayı?';

  @override
  String get gamePromptListenForSoundSource => 'Dinle. Ses kimden geliyor?';

  @override
  String get gamePromptSequenceNext => 'Sıradaki sayı hangisi?';

  @override
  String get gamePromptSequenceMissing => 'Eksik sayı hangisi?';

  @override
  String get obStart => 'Başlayalım';

  @override
  String get obBack => 'Geri';

  @override
  String get obHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String get obSignIn => 'Giriş yap';

  @override
  String get obNoAccountFound =>
      'Bu hesapla kayıt bulunamadı. Başlamak için Başlayalım\'a dokunun.';

  @override
  String get signInTitle => 'Giriş yap';

  @override
  String get signInOr => 'veya';

  @override
  String get signInEmail => 'E-posta';

  @override
  String get signInPassword => 'Şifre';

  @override
  String get signInContinue => 'E-posta ile devam et';

  @override
  String get signInWrongPassword => 'E-posta ya da şifre hatalı.';

  @override
  String signInLinkSent(String email) {
    return '$email adresine giriş bağlantısı gönderdik. Bu telefonda e-postadaki bağlantıya dokunun.';
  }

  @override
  String get familyAccountDetails => 'Detaylar';

  @override
  String get accountDeleteHelpTitle => 'Hesap nasıl silinir?';

  @override
  String get accountDeleteHelpBody =>
      'Yukarıdaki \"Hesabı ve bulut verilerini sil\"e dokunun ve Google hesabınızla onaylayın. Aile kaydı, çocuk profilleri ve günlük özetler buluttan silinir. Uygulamaya erişemiyorsanız: yesastudio.com/ozel-egitim-oyunlari/delete-account';

  @override
  String get accountPlanMonthly => 'Premium · aylık';

  @override
  String get accountPlanYearly => 'Premium · yıllık';

  @override
  String get accountTrialEnds => 'Deneme bitişi';

  @override
  String get accountPremiumUntil => 'Premium bitişi';

  @override
  String get accountPurchased => 'Satın alma';

  @override
  String get accountCreated => 'Hesap oluşturma';

  @override
  String get accountLastSignIn => 'Son giriş';

  @override
  String get accountNextPaymentNote =>
      'Sonraki ödeme tarihi ve iptal Google Play → Ödemeler ve abonelikler bölümündedir.';

  @override
  String get paywallLifetimeSubscribedTitle => 'Aboneliğin devam ediyor';

  @override
  String get paywallLifetimeSubscribedBody =>
      'Ömür boyu satın aldıktan sonra aboneliğiniz kendiliğinden durmaz. Ödemenin devam etmemesi için Google Play → Ödemeler ve abonelikler bölümünden aboneliği iptal edin.';

  @override
  String get paywallLifetimeSubscribedContinue => 'Satın almaya devam et';

  @override
  String get obSignedIn => 'Giriş yapıldı. Şimdi çocuğunuzu ekleyelim.';

  @override
  String get obSkip => 'Atla';

  @override
  String get obChildTitle => 'Çocuğunuzu tanıyalım';

  @override
  String get obChildBody =>
      'Bu bilgilerle yumuşak bir başlangıç seçiyoruz. Daha sonra Aile bölümünden değiştirebilirsiniz.';

  @override
  String get obNicknameOptional => 'Takma ad (isteğe bağlı)';

  @override
  String get obAgeTitle => 'Yaş';

  @override
  String get obAgeTenPlus => '10+';

  @override
  String obAgeYears(int age) {
    return '$age yaşında';
  }

  @override
  String get obDefaultNickname => 'Minik kaşif';

  @override
  String get obMultipleHint => 'Birden fazla seçebilirsiniz.';

  @override
  String obStepSemantics(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get obGoalTitle => 'Günlük oyun hedefi';

  @override
  String get obGoalBody =>
      'Kısa ve düzenli oturumlar en iyisidir. Çocuğunuz baskı yaratan bir sayaç görmez.';

  @override
  String obGoalMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String get obRecommended => 'Önerilen';

  @override
  String get obHandoffBody => 'Telefonu yan çevirip çocuğunuza verin.';

  @override
  String get obHandoffNote => 'Oyunlar yatay açılır. Aile bölümü dik açılır.';

  @override
  String get gamePromptOddOneOut => 'Farklı olanı bul';

  @override
  String get gamePromptShadowMatch => 'Gölgesini bul';

  @override
  String get gamePromptSortIntoBasket => 'Doğru sepete koy';

  @override
  String get gamePromptNumberQuantity => 'Bu kadar olanı bul';

  @override
  String gamePromptFillCount(int count) {
    return 'Sepete $count tane koy';
  }

  @override
  String gameFillBasketCount(int count, int goal) {
    return 'Sepette $count / $goal';
  }

  @override
  String get appTitle => 'Özel Eğitim Oyunları';

  @override
  String get gamePromptWhichSound => 'Hangi ses onun?';

  @override
  String get gameListenToSound => 'Dinle';

  @override
  String get famToday => 'Bugün';

  @override
  String famGoalShort(int done, int goal) {
    return '$done / $goal dk';
  }

  @override
  String get famGoalDone => 'Bugünkü hedef tamam. Harika!';

  @override
  String famGoalLeft(int minutes) {
    return 'Bugünkü hedefe $minutes dakika kaldı.';
  }

  @override
  String famPlayedToday(int minutes) {
    return 'Bugün oynanan: $minutes dk';
  }

  @override
  String get famMinutesThisWeek => 'Bu hafta dakika';

  @override
  String get famDaysPlayed => 'Bu hafta oynanan gün';

  @override
  String get famThisWeek => 'Bu hafta';

  @override
  String get famRecentlyPlayed => 'Son oynananlar';

  @override
  String get famRecentlyLearned => 'Son öğrenilenler';

  @override
  String get famNothingYet => 'Henüz yok. Birlikte bir tur oynayın!';

  @override
  String get familyAgeLevel => 'Yaş seviyesi';

  @override
  String get familyAgeLevelEasier => 'Daha kolay';

  @override
  String get familyAgeLevelByAge => 'Yaşına göre';

  @override
  String get familyAgeLevelHarder => 'Daha zor';

  @override
  String familyAgeLevelFromAge(String band) {
    return 'Yaşına göre: $band';
  }

  @override
  String get familyAgeLevelNoAge =>
      'Profilde yaş yok. Yaşı profil düzenleyiciden ekleyin.';

  @override
  String get familyAgeLevelNote =>
      'Yeni oyunlara uygulanır. Kolay/Orta/Zor ve otomatik zorluk aynen çalışır; Zor yine premium.';

  @override
  String get ageBandFirstSteps => 'İlk adımlar (2–3)';

  @override
  String get ageBandExplore => 'Keşif (4–5)';

  @override
  String get ageBandSchoolReady => 'Okula hazırlık (6–7)';

  @override
  String get ageBandPractice => 'Pekiştirme (8+)';

  @override
  String get ageBandFirstStepsInfo =>
      '2 seçenek, 1–3 arası sayılar, oyun başına 5 soru, hızlı ipucu; önce dokunma oyunları.';

  @override
  String get ageBandExploreInfo =>
      '3 seçenek, 1–5 arası sayılar, oyun başına 6 soru; dokunma ve basit sürükleme.';

  @override
  String get ageBandSchoolReadyInfo =>
      '4 seçenek, 1–10 arası sayılar, oyun başına 8 soru; sürükleme, gruplama, sıralama.';

  @override
  String get ageBandPracticeInfo =>
      '4 seçenek, 1–20 arası sayılar, oyun başına 10 soru, daha az bilinen nesneler, ipucu daha geç.';

  @override
  String paywallTrialActive(int days) {
    return 'Deneme sürüyor: $days gün kaldı';
  }

  @override
  String get paywallTrialUsed => 'Bu hesabın ücretsiz denemesi kullanıldı.';

  @override
  String get paywallTrialError =>
      'Deneme başlatılamadı. İnternet bağlantısını kontrol edip tekrar deneyin.';

  @override
  String get paywallLifetime => 'Tek seferlik';

  @override
  String get paywallLifetimeNote =>
      'Bir kez öde, süresiz kullan. Abonelik yok.';

  @override
  String get paywallLifetimeOwned => 'Tek seferlik Premium sizde.';

  @override
  String get paywallPrivacy => 'Gizlilik politikası';

  @override
  String get paywallTerms => 'Kullanım koşulları';

  @override
  String get familyAccountDelete => 'Hesabı ve bulut verilerini sil';

  @override
  String get familyAccountDeleteTitle => 'Hesap silinsin mi?';

  @override
  String get familyAccountDeleteBody =>
      'Google hesabınıza bağlı aile hesabı ve buluttaki öğrenme özetleri kalıcı olarak silinir. Önce Google ile yeniden doğrulama istenir. Bu cihazdaki profiller ve ilerleme silinmez; onları uygulamayı kaldırarak silebilirsiniz.';

  @override
  String get familyAccountDeleteConfirm => 'Kalıcı olarak sil';

  @override
  String get familyAccountDeleteCancel => 'Vazgeç';

  @override
  String get familyAccountDeleted => 'Hesap ve bulut verileri silindi.';

  @override
  String get familyAccountDeleteFailed =>
      'Hesap silinemedi. İnternet bağlantısını kontrol edip tekrar deneyin.';

  @override
  String get paywallHeadline => 'Tüm oyunları aç';

  @override
  String paywallSave(int percent) {
    return '%$percent tasarruf';
  }

  @override
  String get paywallContinue => 'Devam et';

  @override
  String get paywallContinueFree => 'Ücretsiz sürümle devam et';

  @override
  String get paywallRestoreShort => 'Geri yükle';

  @override
  String get paywallPlansFailed => 'Planlar yüklenemedi.';

  @override
  String get paywallRetry => 'Tekrar dene';

  @override
  String get paywallClose => 'Kapat';

  @override
  String get familyCloudSync => 'Günlük özetleri buluta gönder';

  @override
  String get familyCloudSyncNote =>
      'Günlük özet (oyun, süre, tur) Google hesabınıza kaydedilir. Çocuğun adı gönderilmez.';

  @override
  String welcomeFreeTrial(int days) {
    return 'Tüm oyunları $days gün ücretsiz deneyin';
  }

  @override
  String get paywallBestValue => 'En avantajlı';

  @override
  String paywallPerMonth(String price) {
    return '$price/ay';
  }

  @override
  String paywallStartTrial(int days) {
    return '$days gün ücretsiz dene';
  }

  @override
  String get paywallStartFreeTrial => 'Denemeyi başlat';

  @override
  String get paywallTrialOptionNote => 'Kart yok · Otomatik ücret yok';

  @override
  String get paywallFreePrice => 'Ücretsiz';

  @override
  String get signInCheckEmail => 'E-postanızı kontrol edin';

  @override
  String get signInUseOtherEmail => 'Başka bir e-posta kullanın';

  @override
  String paywallTrialOption(int days) {
    return '$days gün ücretsiz';
  }

  @override
  String paywallContinuePrice(String price) {
    return 'Devam et · $price';
  }

  @override
  String get paywallCancelAnytime =>
      'Google Play\'den istediğiniz zaman iptal edebilirsiniz.';

  @override
  String get welcomeFreeAfter =>
      'Sonrasında her temada Öğren ve iki oyun hep ücretsiz.';

  @override
  String get paywallEveryMonth => 'her ay';

  @override
  String get paywallOnePayment => 'tek ödeme';

  @override
  String get paywallCancelShort => 'İstediğiniz zaman iptal';

  @override
  String get paywallNoSubscription => 'Abonelik yok';

  @override
  String get lockedGameTitle => 'Bu oyun kilitli';

  @override
  String get lockedGameBody =>
      'Açmak için ailene sor. Şimdilik açık oyunlarla oynayabilirsin.';

  @override
  String get lockedGameOk => 'Tamam';

  @override
  String get familyPremiumStripBuy => 'Premium\'a geç';

  @override
  String get familyPremiumStripNote => 'Tüm oyunlar ve ayrıntılı ilerleme';

  @override
  String get familyLockedStatsTitle => 'Ayrıntılı ilerleme Premium ile açılır';

  @override
  String get familyLockedStatsBody =>
      'Haftalık grafikler, dikkat, beceriler ve öğe sonuçları.';

  @override
  String get familyLockedStatsButton => 'Premium ile aç';

  @override
  String get familyAccountPlan => 'Paket';

  @override
  String get familyAccountPayment => 'Ödeme';

  @override
  String get familyPlanFree => 'Ücretsiz sürüm';

  @override
  String familyPlanTrial(int days) {
    return 'Ücretsiz deneme · $days gün kaldı';
  }

  @override
  String familyPlanTrialEnds(String date) {
    return '$date tarihinde biter. Sonra ücretsiz sürüm devam eder.';
  }

  @override
  String get familyPlanSubscription => 'Premium abonelik';

  @override
  String get familyPlanLifetime => 'Premium · tek seferlik';

  @override
  String get askSurveyMoreGames => 'Daha fazla oyun eklenmeli';

  @override
  String get askSurveyMoreThemes => 'Daha fazla tema/kategori eklenmeli';

  @override
  String get askSurveyPrice => 'Fiyat daha uygun olmalı';

  @override
  String get askSurveySatisfaction => 'Uygulamadan ne kadar memnunsunuz?';

  @override
  String get askSurveyWho => 'Uygulamayı kim kullanıyor?';

  @override
  String get askSurveyUserParent => 'Ebeveyn';

  @override
  String get askSurveyUserTeacher => 'Öğretmen';

  @override
  String get askSurveyUserSpecialist => 'Özel eğitim uzmanı veya terapist';

  @override
  String get askSurveyUserOther => 'Diğer';

  @override
  String get askSurveyImprove => 'Neleri geliştirelim?';

  @override
  String get askSurveyVoices => 'Seslendirme daha iyi olmalı';

  @override
  String get askSurveyReports => 'İlerleme raporları daha detaylı olmalı';

  @override
  String get askSurveyNote => 'Eklemek istedikleriniz';

  @override
  String get feedbackTitle => 'Geri bildirim gönder';

  @override
  String get feedbackIntro =>
      'Hata, öneri ya da görmek istediğiniz oyunlarla ilgili bize yazabilirsiniz.';

  @override
  String get feedbackSend => 'Gönder';

  @override
  String get feedbackSent => 'Teşekkürler, geri bildiriminiz gönderildi';

  @override
  String get feedbackFailed => 'Gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get familyPlanGranted => 'Premium';

  @override
  String get familyPlanTest => 'Premium (test sürümü)';

  @override
  String get familyPaymentNone => 'Ödeme yok';

  @override
  String get familyPaymentTrial => 'Ödeme yok · Google hesabıyla deneme';

  @override
  String get familyPaymentPlay => 'Google Play';

  @override
  String get familyPlanCardTitle => 'Hesap';

  @override
  String get familyGamesPremiumTitle => 'Oyunları çocuğunuza göre seçin';

  @override
  String get familyGamesPremiumBody =>
      'Oyunları açıp kapatma Premium ve ücretsiz denemede var.';

  @override
  String familyGamesShownCount(int shown, int total) {
    return '$total oyundan $shown açık';
  }

  @override
  String get familyMoreProfilesPremium =>
      'Daha fazla çocuk profili Premium ile';

  @override
  String get obPlanBuildingTitle => 'Planı hazırlıyoruz';

  @override
  String obPlanAge(String range) {
    return '$range yaş seviyesi seçildi';
  }

  @override
  String get obPlanAgeDefault => 'Başlangıç seviyesi seçildi';

  @override
  String obPlanTopics(String topics) {
    return 'Sevdiği konular eklendi: $topics';
  }

  @override
  String get obPlanTopicsAll => 'Tüm konular eklendi';

  @override
  String obPlanReadyTitle(String name) {
    return '$name için 7 günlük plan hazır';
  }

  @override
  String obPlanDay(int day) {
    return 'Gün $day';
  }

  @override
  String get obPlanToday => 'Bugün';

  @override
  String get gameMascotHello => 'Merhaba! Hadi birlikte oynayalım.';

  @override
  String get weeklySummaryTitle => 'Haftanın özeti';

  @override
  String weeklySummaryBody(String name, int days, int minutes) {
    return '$name bu hafta $days gün, toplam $minutes dakika oynadı.';
  }

  @override
  String weeklySummaryNone(String name) {
    return '$name bu hafta henüz oynamadı. Birlikte birkaç dakika oynamaya ne dersiniz?';
  }

  @override
  String get familyReminder => 'Günlük hatırlatma';

  @override
  String get familyReminderNote =>
      'O gün oynanmadıysa seçtiğiniz saatte kısa bir bildirim gelir; pazar akşamı haftanın özeti gelir.';

  @override
  String get familyReminderTime => 'Saat';

  @override
  String get famDayStreak => 'Üst üste oynanan gün';
}
