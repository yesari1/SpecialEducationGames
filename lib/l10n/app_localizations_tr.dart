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
  String get noAdsOffline => 'Reklam yok. İnternet şart değil.';

  @override
  String get parentGateSettings => 'Ayarlar ebeveyn kilidinin arkasında.';

  @override
  String get noAccountNeeded => 'Hesap açmanız gerekmez.';

  @override
  String get letsGetStarted => 'Birlikte başlayalım';

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
  String get themeUnlockWithFamily => 'Bunu ailenle açabilirsin.';

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
  String get onboardingSuggestedStart => 'Önerilen başlangıç';

  @override
  String get onboardingFamilyHint => 'Aile bölümünden değiştirebilirsiniz.';

  @override
  String get onboardingSaving => 'Kaydediliyor…';

  @override
  String get onboardingPlay => 'Oyunlara geç';

  @override
  String get onboardingContinue => 'Devam et';

  @override
  String get onboardingSkipQuestion => 'Bu soruyu atla';

  @override
  String get onboardingNickname => 'Takma ad';

  @override
  String get onboardingProfileQuestion => 'Minik kaşifimiz kim?';

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
  String get onboardingPreviousRecommendation => 'Önceki öneri';

  @override
  String get onboardingNextRecommendation => 'Sonraki öneri';

  @override
  String get accountTitle => 'Hesap';

  @override
  String get familyAccountTitle => 'Aile hesabı';

  @override
  String get familyAccountOptional =>
      'Google ile giriş isteğe bağlıdır. Giriş yapmadan tüm yerel özellikleri kullanabilirsiniz.';

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
  String get familyAccountNotNow =>
      'Şimdi değil: Bu ekranı kapatıp oynamaya devam edebilirsiniz.';

  @override
  String get familyAccountCancelled => 'Giriş iptal edildi.';

  @override
  String get familyAccountOffline =>
      'Bağlantı kurulamadı. Çevrimdışı devam edebilirsiniz.';

  @override
  String get familyAccountConfiguration =>
      'Google girişi henüz yapılandırılmadı. Yerel verileriniz güvende.';

  @override
  String get familyAccountTimeout =>
      'Giriş zaman aşımına uğradı. Çevrimdışı devam edebilirsiniz.';

  @override
  String get familyAccountUnavailable =>
      'Giriş şu anda kullanılamıyor. Yerel modda devam edebilirsiniz.';

  @override
  String get creditsTitle => 'Kaynaklar ve lisanslar';

  @override
  String get creditsLoadFailure => 'Kaynak bilgileri yüklenemedi.';

  @override
  String get creditsAnimalRecordings => 'Doğal sesler';

  @override
  String get creditsRealPhotographs => 'Gerçek fotoğraflar';

  @override
  String get creditsSoundChanges =>
      'Değişiklikler: mono MP3, azaltılmış ses düzeyi, kısa giriş/çıkış ve en fazla 3 saniye.';

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
  String get applicationName => 'Özel Eğitim Oyunları';

  @override
  String get creditsOpenSourceLicenses => 'Açık kaynak yazılım lisansları';

  @override
  String get summarySyncTitle => 'Günlük özetleri eşitle';

  @override
  String get summarySyncDescription =>
      'Yalnız günlük süre, tur ve bağımsız yanıt sayıları paylaşılır. Ham seçimler, çocuk adı ve anket yanıtları gönderilmez. Bu, tam profil yedeği değildir.';

  @override
  String get summarySyncRequirements =>
      'Eşitlemek için ebeveyn erişimi, bir profil ve Google girişi gerekir.';

  @override
  String get summarySyncConsent =>
      'Bu hesap ve profil için günlük özet paylaşımına izin veriyorum.';

  @override
  String get summarySyncManualNotice =>
      'Eşitleme yalnız aşağıdaki düğmeyle başlar. İzni kaldırmak cihazdaki indirilen özeti temizler; sunucudaki veriyi silmez.';

  @override
  String get summarySyncNow => 'Şimdi eşitle';

  @override
  String summarySyncSnapshot(int count, String savedAt) {
    return 'Cihazdaki eşitlenmiş özet: $count kayıt. Kaydedildi: $savedAt';
  }

  @override
  String get summarySyncCapacity =>
      'Özet sayısı desteklenen sınırı aşıyor. Yerel kayıtlar korunuyor.';

  @override
  String get summarySyncUnavailable =>
      'Eşitleme tamamlanamadı. Bağlantı veya sunucu kullanılamıyor olabilir. Yerel kayıtlar korunuyor.';

  @override
  String get subscriptionTitle => 'Premium';

  @override
  String get subscriptionShowPlans => 'Planları göster';

  @override
  String get subscriptionHeading => 'Birlikte daha çok keşif';

  @override
  String get subscriptionAllGames => 'Tüm oyunlar ve zorluklar';

  @override
  String get subscriptionProfiles => 'Beş çocuk profiline kadar';

  @override
  String get subscriptionAdFree => 'Reklamsız, çevrimdışı öğrenme';

  @override
  String get subscriptionActive => 'Premium erişiminiz açık.';

  @override
  String get subscriptionUnavailable =>
      'Google Play ürünleri şu anda alınamıyor. Ücretsiz oyunlarla devam edebilirsiniz.';

  @override
  String get subscriptionMonthly => 'Aylık';

  @override
  String get subscriptionYearly => 'Yıllık';

  @override
  String get subscriptionMonth => 'ay';

  @override
  String get subscriptionYear => 'yıl';

  @override
  String subscriptionPrice(String recurringPrice, String period) {
    return '$recurringPrice / $period';
  }

  @override
  String subscriptionTrial(String recurringPrice) {
    return '7 gün ücretsiz, sonra $recurringPrice. Deneme bitmeden Google Play’den iptal edebilirsiniz.';
  }

  @override
  String get subscriptionRenewal =>
      'Otomatik yenilenir. Google Play’den istediğiniz zaman iptal edebilirsiniz.';

  @override
  String get subscriptionWaiting => 'Google Play bekleniyor…';

  @override
  String get subscriptionStartTrial => '7 günlük denemeyi başlat';

  @override
  String get subscriptionContinue => 'Google Play ile devam et';

  @override
  String get subscriptionStoreError =>
      'Mağazaya bağlanılamadı. Lütfen daha sonra tekrar deneyin.';

  @override
  String get subscriptionRestore => 'Satın alımları geri yükle';

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
  String get familyPlayTimeMinutes => 'Oynama süresi · dakika';

  @override
  String get familyIndependentFirstAnswers =>
      'İpucusuz, ilk denemede doğru · %';

  @override
  String get familyProgressWillAppearHereAfterThe =>
      'İlk oyundan sonra gelişimi burada görebilirsiniz.';

  @override
  String get familyAttentionDailyAverageSeconds =>
      'Dikkat · günlük ortalama saniye';

  @override
  String get familyFirstResponse => 'İlk tepki';

  @override
  String get familyS => 'sn';

  @override
  String get familyIdleTime => 'Tepkisiz süre';

  @override
  String get familyTimeInTheBackgroundIsExcluded =>
      'Arka planda geçen süre dahil değildir.';

  @override
  String familySecondsRange(double maximum) {
    return '0–$maximum saniye.';
  }

  @override
  String get familyNumericView => 'Sayısal görünüm';

  @override
  String get familySkillAreas => 'Beceri alanları';

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
      'Bağımsız liste: son üç yanıt ipucusuz. Destek listesi: son üç aşamanın en az ikisinde belirgin destek.';

  @override
  String get familyIndependentlyAnswered => 'Bağımsız yanıtladıkları';

  @override
  String get familyItemsNeedingMoreSupport => 'Daha fazla destek verdiklerimiz';

  @override
  String get familyItemsAppearHereAfterAtLeast =>
      'En az üç aşamanın ardından burada öğeler görünür.';

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
  String get familyShowUnlockedGamesOnly => 'Yalnızca açık oyunları göster';

  @override
  String get familyHidesLockedCardsInChildMode =>
      'Çocuk ekranındaki kilitli kartları gizler.';

  @override
  String get familyEasyAndMediumUnlocked => 'Kolay ve Orta açık';

  @override
  String get familyPremium => 'Premium';

  @override
  String get familyDailyScreenTimeLimit => 'Günlük ekran süresi sınırı';

  @override
  String get familyCountsActivePlayTimeABreak =>
      'Aktif oyun süresini sayar. Süre dolunca mola ekranı açılır.';

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
  String get familyAutomaticThemeSelection => 'Otomatik / tema seçimi';

  @override
  String get familyEasy => 'Kolay';

  @override
  String get familyMedium => 'Orta';

  @override
  String get familyHard => 'Zor';

  @override
  String get familyAppliesToNewRoundsHardLevel =>
      'Yeni turlarda uygulanır. Zor seviye Premium kapsamındadır.';

  @override
  String get familyRoundLength => 'Tur uzunluğu';

  @override
  String get familySurveyDifficultySetting => 'Anket / zorluk ayarı';

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
      'Yeni turda uygulanır. Zamanlı ipucu kapalıyken de yanlış yanıta destek verilir.';

  @override
  String get familyDailyMinuteGoal => 'Günlük dakika hedefi';

  @override
  String familyTodayGoalProgress(double minutes, int goal) {
    return 'Bugünkü hedef: $minutes / $goal dakika';
  }

  @override
  String get familyAnOptionalReminderItDoesNot =>
      'İsteğe bağlı hatırlatma; oyun süresini sınırlamaz.';

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
      'Önce tek kartla göster, sonra seçeneklerle sor.';

  @override
  String get familyAdaptiveDifficulty => 'Otomatik zorluk önerisi';

  @override
  String get familyChangesApplyOnlyWhenANew =>
      'Değişiklikler yalnızca yeni turda uygulanır.';

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
  String get familySubscriptionPricesAndTrialEligibilityCome =>
      'Abonelik fiyatları ve deneme uygunluğu Google Play’den alınır.';

  @override
  String get familyPlansAndRestore => 'Planlar ve geri yükleme';

  @override
  String get familyPrivacy => 'Gizlilik';

  @override
  String get familyGoogleFamilyAccount => 'Google aile hesabı';

  @override
  String get familyCreditsAndLicenses => 'Kaynaklar ve lisanslar';

  @override
  String get familyProfilesAndRawGameRecordsStay =>
      'Profil ve ham oyun kayıtları bu cihazda tutulur. Hesap ekranında izin verip eşitlemeyi başlatırsanız yalnızca günlük özetler gönderilir. Reklam veya reklam kimliği kullanılmaz.';

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
  String get familyStoredOnThisDevice => 'Bu cihazda saklanır';

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
  String get familyTheFreeVersionIncludesOneChild =>
      'Ücretsiz sürümde bir çocuk profili bulunur.';

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
  String get gameTodaysPath => 'Bugünün Yolu';

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
  String get gameObject => 'Nesne';

  @override
  String gameCountedObjectSemantics(String object, int number) {
    return '$object, say $number';
  }

  @override
  String get dailyPathNoGamesAreAvailableToday => 'Bugün açık oyun bulunmuyor.';

  @override
  String get dailyPathYouEarnedTodaysSticker =>
      'Bugünün çıkartmasını kazandın!';

  @override
  String get dailyPathEachCompletedGameIsOneStep =>
      'Her tamamlanan oyun bir adım.';

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
  String gameSummaryPage(int current, int total) {
    return 'Özet · sayfa $current / $total';
  }

  @override
  String dailyPathStepTitle(int index, String game) {
    return '$index. $game';
  }

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
      'Kısa ve düzenli oturumlar en iyisidir. Çocuğunuz sakin bir ilerleme görür, geri sayım görmez.';

  @override
  String obGoalMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String get obRecommended => 'Önerilen';

  @override
  String get obLockTitle => 'Ayarlar sizde kalır';

  @override
  String get obLockBody =>
      'Aile bölümüne dönmek için ana ekrandaki “Aile” düğmesine dokunun. Kısa bir ebeveyn kontrolü (basit bir soru ya da PIN’iniz) çocukların girmesini önler.';

  @override
  String get obPinSwitch => 'Ayrıca 4 haneli PIN belirle';

  @override
  String get obPinField => 'PIN';

  @override
  String get obPinInvalid => 'Dört rakam girin.';

  @override
  String get obTrialTitle => 'Tüm oyunları keşfedin';

  @override
  String get obTrialBody =>
      'Ücretsiz oyunlar hep ücretsiz kalır. Premium tüm temaları ve oyunları, tüm zorluk seviyelerini ve beş çocuk profilini açar.';

  @override
  String get obTrialPoint1 => 'Tüm temalar ve oyunlar';

  @override
  String get obTrialPoint2 => 'Tüm zorluk seviyeleri';

  @override
  String get obTrialPoint3 => 'Beş çocuk profiline kadar';

  @override
  String get obTrialStart => '7 gün ücretsiz dene';

  @override
  String get obTrialNote =>
      'Deneme sonrası ödeme Google Play üzerinden alınır. Google Play\'den istediğiniz zaman iptal edebilirsiniz.';

  @override
  String get obContinueFree => 'Ücretsiz devam et';

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
  String paywallTrialTitle(int days) {
    return '$days gün ücretsiz dene';
  }

  @override
  String paywallTrialBody(int days) {
    return 'Tüm oyunlar ve zorluklar $days gün açık. Ödeme bilgisi istenmez; süre bitince ücretsiz oyunlarla devam edilir.';
  }

  @override
  String get paywallTrialSignIn => 'Google ile giriş yap ve başla';

  @override
  String get paywallTrialStart => 'Ücretsiz denemeyi başlat';

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
  String get paywallTrialNote =>
      'Deneme her Google hesabı için bir kez verilir.';

  @override
  String paywallFreeTier(int count) {
    return 'Ücretsiz sürümde $count oyun her zaman açık.';
  }

  @override
  String get paywallLifetime => 'Tek seferlik';

  @override
  String get paywallLifetimeNote =>
      'Bir kez öde, süresiz kullan. Abonelik yok.';

  @override
  String get paywallBuy => 'Satın al';

  @override
  String get paywallLifetimeOwned => 'Tek seferlik Premium sizde.';

  @override
  String get paywallPrivacy => 'Gizlilik politikası';

  @override
  String get paywallTerms => 'Kullanım koşulları';
}
