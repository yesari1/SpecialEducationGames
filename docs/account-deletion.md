# Hesap ve Veri Silme — İç Taslak / Yayına Hazır Değil

> **Durum:** Uygulamada ebeveyn için Google ile oturum açma bulunuyor; hesap silme istemci akışı ve çalışan sunucu uç noktası yok. Bu belge bir uygulama özelliği veya çalışan destek adresi sunmaz. `[GELİŞTİRİCİ/KURUM ADI]`, `[ÇALIŞAN DIŞ SİLME TALEBİ URL'Sİ]`, `[DESTEK E-POSTASI]`, saklama/yedek süreleri ve süreç sahibi doldurulup doğrulanmadan yayımlanamaz. Firebase sunucu taslağı varsayılan olarak kapalı ve deploy edilmemiştir.

## Şu anda sunulan yerel profil silme

Aile alanındaki profil silme akışı seçili çocuk profilini bu cihazdan kaldırır; o profile ait yerel oyun/aşama geçmişini, profil tercihlerini ve yerel içe aktarılmış özet kopyalarını temizler. Bu, Google/Firebase ebeveyn hesabını silmez ve Firestore'daki günlük özetleri silmez. Uygulama açıkça ebeveyn onayı ister. Yerel profil silme için menü yolu: Aile alanı → Profil ayarları → Profili sil.

## Firebase hesabı ve bulut verisi silme durumu

Hesap silme şu sürümde kullanıcı tarafından başlatılamaz. Hesap silme sunucu taslağı yerel olarak test edilmiştir; Firebase projesine bağlanmamış, deploy edilmemiş, App Check/kimlik doğrulama/recent-login akışı gerçek hizmette doğrulanmamıştır. Taslak; doğrulanmış hesap kimliği için aile Firestore alt ağacını temizlemeyi ve ardından Firebase Auth kimliğini silmeyi amaçlar. Tamamlanmış gerçek hesap/veri silme olarak sunulamaz.

Bulut silme isteği için şimdilik doğrulanmış bir talep sayfası veya e-posta yok: `[ÇALIŞAN DIŞ SİLME TALEBİ URL'Sİ — SAHİP SAĞLAMALI]`, `[DESTEK E-POSTASI — SAHİP SAĞLAMALI]`. Bu yer tutucular kullanıcıya yayımlanmamalı veya Play Console'a girilmemelidir.

## Tamamlanmış özellik için ürün ve operasyon gereksinimleri

Hesap oluşturma/oturum açma uygulamada sunulduğundan, Google Play'in güncel hesabı silme rehberi hem uygulama içinden silme yolu hem de uygulama dışından ulaşılabilen, çalışan bir web talep yolu istediğini belirtir. Harici yol, uygulama kaldırılmış olsa bile başvuruya izin vermeli; doğru uygulama/geliştirici adına atıf yapmalı ve gerekli ek adımları/abonelik iptalini açıkça anlatmalıdır. Hesap silme isteğinde hesaba bağlı veriler de kapsamda olmalıdır. [Google Play hesap silme gereksinimleri](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)

Gerçekleştirmeden önce sahip/uygulama ekibi şunları kararlaştırıp uygulamalı:

- Google hesabı yeniden doğrulama ve açık, ebeveyn-korumalı onay; App Check ve deploy edilmiş sunucu doğrulaması.
- Firebase Auth hesabından önce bağlı Firestore aile verisinin güvenli temizliği; başarısızlık/tekrar deneme durumları ve ikinci cihaz/yazma kilidi doğrulaması.
- Yerel profil/oyun verilerinin hesap silmeye dahil olup olmadığı ve cihazda kalacaksa kullanıcıya nasıl açıklanacağı.
- Google Play aboneliğinin ayrıca yönetileceği/iptal edileceği; hesap silmenin Play aboneliğini iptal etmediği.
- Sunucu/yedek/sağlayıcı saklama süreleri, istisnalar, işlem süresi ve kullanıcıya tamamlanma bildirimi.
- Uygulama içi akış ile dış web talep yolunun gerçek hizmette uçtan uca testi; `[SAHİP ADI]`, `[DESTEK E-POSTASI]`, `[SİLME URL'Sİ]`, `[SAKLAMA SÜRESİ]` tamamlanması.

Bu gereksinimler tamamlanıp onaylanana kadar hesap silmenin mevcut olduğu, anında tamamlandığı veya bütün kopyaların silindiği söylenmemelidir. Bu taslak hukuk görüşü değildir.

---

# Account and Data Deletion — Internal Draft / Not Ready to Publish

> **Status:** The app offers parent Google sign-in, but there is no client account-deletion flow or working server endpoint. This document does not create an app feature or a support contact. Do not publish until `[DEVELOPER/LEGAL ENTITY]`, `[WORKING EXTERNAL DELETION REQUEST URL]`, `[SUPPORT EMAIL]`, retention/backup periods, and an operational owner are supplied and verified. The Firebase server deletion draft is disabled by default and undeployed.

## Local profile deletion currently available

The family-area profile deletion flow removes the selected child profile from this device, including its local game/stage history, profile preferences, and imported local summary copies. It does not delete the Google/Firebase parent account or daily summaries stored in Firestore. The app asks for explicit parent confirmation. Current local path: Family area → Profile settings → Delete profile.

## Firebase account and cloud-data deletion status

Users cannot initiate account deletion in this version. The account-deletion server draft has local tests, but it is not connected to the Firebase project, has not been deployed, and its App Check, authentication, and recent-login behavior have not been verified against a live service. The draft is intended to clear the authenticated account's Firestore family subtree before deleting its Firebase Authentication identity. It must not be described as completed deletion of a real account or its data.

There is currently no verified external request page or email: `[WORKING EXTERNAL DELETION REQUEST URL — OWNER TO PROVIDE]`, `[SUPPORT EMAIL — OWNER TO PROVIDE]`. Do not publish these placeholders or enter them into Play Console.

## Product and operations requirements before this feature is complete

Because the app offers account sign-in, Google Play's current account-deletion guidance calls for an in-app deletion path and a working web request path available outside the app. The external path must allow a request even if the app has been uninstalled, reference the actual app/developer name, and explain any required steps, including subscription cancellation. Account-associated data is also in scope for deletion requests. [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)

Before implementation, the owner/app team must decide and deliver:

- Recent Google reauthentication and explicit parent-gated confirmation; deployed server validation and App Check.
- Safe deletion of associated Firestore family data before Firebase Auth identity deletion; failure/retry behavior and second-device/write-lock validation.
- Whether local profiles/game records are included in account deletion and, if retained on the device, how that is explained.
- Separate handling of Google Play subscriptions; deleting an app account does not cancel a Play subscription.
- Retention periods for server, backup, and service-provider copies; exceptions, completion timeframe, and user notification.
- End-to-end tests for the in-app flow and external web request route; completion of `[OWNER NAME]`, `[SUPPORT EMAIL]`, `[DELETION URL]`, and `[RETENTION PERIOD]`.

Until these requirements are implemented and approved, do not say account deletion is available, immediate, or complete across all copies. This draft is not legal advice.
