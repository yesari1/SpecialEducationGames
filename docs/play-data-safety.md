# Play Console: Veri güvenliği formu ve beyanlar (Özel Eğitim Oyunları)

Bu cevaplar R33/R34 kodunun gerçekte yaptığına göre hazırlandı (20 Ekim 2026).

- Uygulama hesap olmadan çalışır. Reklam, analitik, çökme raporu ve konum yoktur.
- Google ile giriş isteğe bağlıdır ve yalnız ebeveyn alanındadır.
- Buluta yalnızca şunlar gider: Firebase hesabı (e-posta `families/{uid}` içinde de saklanır), deneme başlangıç zamanı ve giriş yapılmışken otomatik gönderilen günlük öğrenme özetleri (Aile alanından kapatılabilir; 21 Ekim 2026 kararı).
- Yesa Studio yöneticisi bu verileri yönetici sayfasından (yesastudio.com/ozel-egitim-oyunlari/admin/, Firestore kurallarıyla yalnız `admins/{uid}` hesapları) görebilir ve silebilir. Bu bir üçüncü tarafa paylaşım değildir.

Kod değişirse bu formu da güncelleyin.

**Bağlantılar (yayında):**

- Gizlilik politikası: https://yesastudio.com/ozel-egitim-oyunlari/privacy/
- Kullanım koşulları: https://yesastudio.com/ozel-egitim-oyunlari/terms/
- Hesap silme (web): https://yesastudio.com/ozel-egitim-oyunlari/delete-account/

---

## 1. Uygulama içeriği → Gizlilik politikası

- URL: `https://yesastudio.com/ozel-egitim-oyunlari/privacy/`

## 2. Uygulama içeriği → Veri güvenliği

### 2.1 Veri toplama ve güvenlik (ilk sayfa)

| Soru | Cevap |
|---|---|
| Uygulamanız gerekli kullanıcı verisi türlerinden herhangi birini topluyor veya paylaşıyor mu? | **Evet** |
| Uygulamanızın topladığı tüm kullanıcı verileri aktarım sırasında şifreleniyor mu? | **Evet** |
| Hangi hesap oluşturma yöntemlerini destekliyorsunuz? | **OAuth (Google ile giriş)** |
| Kullanıcıların verilerinin silinmesini istemelerinin bir yolunu sunuyor musunuz? | **Evet** |
| Hesap silme URL'si | `https://yesastudio.com/ozel-egitim-oyunlari/delete-account/` |
| Uygulamanız bağımsız bir güvenlik incelemesinden geçti mi? (isteğe bağlı) | **Hayır** (işaretlemeyin) |
| Families politikasına uyum taahhüdü | **Evet** (Families politikasına uyduğunu onaylayın) |

### 2.2 Veri türleri: işaretlenecekler

Yalnızca aşağıdaki veri türlerini işaretleyin (22 Ekim 2026 güncellemesi: plan bilgisi, son açılış ve hesapsız kurulum istatistiği eklendi). Diğerlerinin hepsi **toplanmıyor**: konum, telefon numarası, adres, sağlık, mesajlar, fotoğraf/video, ses, dosyalar, takvim, kişiler, web geçmişi, uygulama bilgisi ve performans.

**Kişisel bilgiler**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Ad | Evet | Hayır | Hayır | **İsteğe bağlı** (kullanıcı giriş yapmayı seçebilir) | **Hesap yönetimi** |
| E-posta adresi | Evet | Hayır | Hayır | **İsteğe bağlı** | **Hesap yönetimi** |
| Kullanıcı kimlikleri | Evet | Hayır | Hayır | **İsteğe bağlı** | **Uygulama işlevselliği**, **Hesap yönetimi**, **Sahtekârlığı önleme, güvenlik ve uygunluk** (deneme süresinin hesap başına bir kez verilmesi) |

**Uygulama etkinliği**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Uygulama etkileşimleri | Evet | Hayır | Hayır | **Zorunlu** (kurulum istatistiği her kurulumda gider; günlük oyun özetleri yalnız girişte ve kapatılabilir) | **Uygulama işlevselliği**, **Analizler** (yönetici sayfası: günlük oyun ve süre, funnel) |

**Finansal bilgiler**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Satın alma geçmişi | Evet | Hayır | Hayır | **İsteğe bağlı** (yalnız giriş yapılmışsa; hesabın planı) | **Uygulama işlevselliği**, **Hesap yönetimi**, **Analizler** |

**Cihaz veya diğer kimlikler**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Cihaz veya diğer kimlikler | Evet | Hayır | Hayır | **Zorunlu** | **Analizler** |

Notlar:

- "Ad" ve "E-posta": Google ile girişte Firebase Authentication bunları Google hesabından alır. Uygulama adı kullanmaz, ama Firebase sakladığı için "toplanıyor" sayılır.
- "Kullanıcı kimlikleri": Firebase UID. Deneme kaydı (`trials/{uid}`, yalnız başlangıç zamanı) ve özetler bu kimlikle saklanır.
- "Uygulama etkileşimleri": günlük özetler. İçerik: tarih, tema, oyun türü, zorluk, aktif süre, tur ve aşama sayısı, kendi başına doğru sayısı. Çocuğun adı, yaşı ya da tek tek yanıtları gönderilmez.
- "Paylaşılıyor" = **Hayır**. Google (Firebase, Play) bizim adımıza veri işleyen hizmet sağlayıcıdır; Play'in tanımına göre bu paylaşım sayılmaz.
- Satın almalar: ödemeyi Google Play işler; ödeme bilgisi bize gelmez. Giriş yapılmışsa hesabın planı (ücretsiz/deneme/aylık/yıllık/ömür boyu/tanımlı) `families/{uid}.plan` olarak gider, bu yüzden "Satın alma geçmişi" **işaretlenir**.
- "Cihaz veya diğer kimlikler": uygulamanın ürettiği rastgele kurulum kimliği (`funnel/{installId}`); yalnız kurulum adımlarının ilk zamanları, platform, sürüm ve dil. Android ID, AAID, IMEI gibi kimlikler **kullanılmaz**; Google hesabına bağlanmaz.
- Son açılış ve uygulama sürümü (`families/{uid}.lastSeenAt`, `appVersion`) "Uygulama etkileşimleri" kapsamındadır.
- Çocuk profili (takma ad, yaş, anket) ve tek tek oyun yanıtları yalnız cihazda kalır, gönderilmez. Buluta yalnız yukarıdaki günlük özetler (giriş yapılmışsa) ve hesapsız kurulum istatistiği gider.

### 2.3 Her veri türü için "Veriler nasıl kullanılıyor" sayfası

Formda her veri türü için aynı sorular gelir:

- "Bu veriler toplanıyor mu, paylaşılıyor mu, ikisi de mi?" → **Toplanıyor**
- "Bu veriler geçici olarak mı işleniyor?" → **Hayır**
- "Bu veri toplama işlemi zorunlu mu, yoksa kullanıcılar toplanıp toplanmayacağını seçebilir mi?" → Tablodaki "Zorunlu / isteğe bağlı" sütununa göre: İsteğe bağlı → **Kullanıcılar seçebilir**; Zorunlu → **Veri toplama zorunludur**
- "Toplama amaçları" → tablodaki amaçlar.

## 3. Uygulama içeriği → Diğer beyanlar

| Beyan | Cevap |
|---|---|
| **Reklamlar:** Uygulamanız reklam içeriyor mu? | **Hayır** |
| **Uygulama erişimi** (inceleme ekibi için) | **Tüm işlevler özel erişim gerektirmez.** Not: "Premium oyunlar için Aile alanı → Premium'da Google ile giriş yapıp 7 günlük ücretsiz deneme başlatılabilir. Ebeveyn kapısı çarpma sorusudur (ekranda yazar)." |
| **Hedef kitle ve içerik** | Hedef yaş grupları: **5 yaş ve altı**, **6–8 yaş** (isteğe bağlı **9–12**). Çocuklara hitap ediyor mu: **Evet**. Families politikası kapsamına girer. |
| **İçerik derecelendirmesi** anketi | Kategori: **Eğitim** / Referans. Şiddet, cinsellik, küfür, kumar, kullanıcı etkileşimi, konum paylaşımı, dijital ürün satın alma (**Evet**: uygulama içi satın alma var). Beklenen sonuç: **Herkes / 3+ (PEGI 3, IARC 3+)**. |
| **Haber uygulaması** | Hayır |
| **COVID-19 izleme** | Hayır |
| **Sağlık uygulaması** beyanı | Sağlık/tıbbi işlev **yok**. Eğitim uygulamasıdır, tanı veya tedavi sunmaz. |
| **Finansal özellikler** | Yok |
| **Devlet uygulaması** | Hayır |
| **Hesap silme** | Uygulama içinde: Aile → Hesap → "Hesabı ve bulut verilerini sil". Web: yukarıdaki URL. |

## 4. Families programı notları

- Çocuk modunda reklam, satın alma istemi, dış bağlantı ve giriş yok. Bunların hepsi ebeveyn kapısının arkasında, dikey ebeveyn ekranlarında.
- Reklam kimliği (AAID) ve kalıcı cihaz kimlikleri toplanmaz; kurulum istatistiği yalnız uygulamanın ürettiği rastgele kimliği kullanır.
  - Android 13+ için `com.google.android.gms.permission.AD_ID` izni manifestte **olmamalı**. Release AAB'de kontrol edin (`tools/audit_android_apk.py`).
  - Bağımlılıklar reklam SDK'sı içermiyor.
- Firebase SDK'ları: Auth, Firestore, Core (Families sertifikalı SDK listesinde). Firebase Analytics ve Crashlytics **yok**.
- Uygulama içi satın almalar Google Play Billing ile yapılıyor; Families için uygun.
- İsteğe bağlı: Play Console → "Teacher Approved" (Öğretmen Onaylı) programına başvuru; Kids sekmesinde görünürlük sağlar.
