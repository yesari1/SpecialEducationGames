# Play Console: Veri güvenliği formu ve beyanlar (Özel Eğitim Oyunları)

Bu cevaplar 2.0.25 (39) kodunun gerçekte gönderdiklerine göre kontrol edildi (23 Ekim 2026).

- Ebeveynin girişi zorunludur (23 Ekim 2026 kararı): Google ile ya da şifresiz e-posta bağlantısıyla (2.0.26); giriş yalnız ebeveyn ekranlarında. Reklam, üçüncü taraf analitik, çökme raporu ve konum yoktur.
- Çocuk profili (ad, yaş, avatar, profil ayarları) ebeveynin hesabıyla `families/{uid}/children/{id}` altında saklanır; fotoğraf yok.
- Buluta yalnızca şunlar gider: Firebase hesabı; aile kaydı `families/{uid}` (e-posta, dil, plan, son açılış, uygulama sürümü); çocuk profilleri; deneme başlangıç zamanı `trials/{uid}`; otomatik gönderilen günlük öğrenme özetleri (Aile alanından kapatılabilir); hesapsız kurulum istatistiği `funnel/{installId}`; isteğe bağlı geri bildirim ve anket `feedback/{id}`. Yöneticinin yazdığı `grants/{uid}` (tanımlı paket, denemeyi bitirme) uygulama tarafından yalnız okunur.
- Yesa Studio yöneticisi bu verileri yönetici sayfasından (seg.yesastudio.com, Firestore kurallarıyla yalnız `admins/{uid}` hesapları) görebilir ve silebilir. Bu bir üçüncü tarafa paylaşım değildir.

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
| Hangi hesap oluşturma yöntemlerini destekliyorsunuz? | **OAuth** (Google ile giriş) ve **Kullanıcı adı ve diğer kimlik doğrulama** / şifresiz e-posta bağlantısı (2.0.26'dan beri; Firebase e-posta bağlantısı). İnceleme hesabı `test@yesastudio.com` şifreyle girer. |
| Hesap silme URL'si (OAuth işaretli olduğu için zorunlu) | `https://yesastudio.com/ozel-egitim-oyunlari/delete-account/` |
| Kullanıcıların hesabı silmeden verilerinin bir kısmını/tamamını silmesini istemelerinin bir yolunu sunuyor musunuz? | **Evet** (23 Ekim 2026, Yunus). Veri silme URL'si: aynı sayfa; sayfada "Hesabı silmeden veri silme" bölümü **olmalı** (çocuk profilini silme, günlük özetleri kapatma, e-postayla talep). |
| Uygulamanız bağımsız bir güvenlik incelemesinden geçti mi? (isteğe bağlı) | **Hayır** (işaretlemeyin) |
| Families politikasına uyum taahhüdü | **Evet** (Families politikasına uyduğunu onaylayın) |

### 2.2 Veri türleri: işaretlenecekler

Yalnızca aşağıdaki veri türlerini işaretleyin (22 Ekim 2026: plan bilgisi, son açılış ve hesapsız kurulum istatistiği; 23 Ekim 2026: zorunlu giriş, çocuk profilleri hesapta, anket). Diğerlerinin hepsi **toplanmıyor**: konum, telefon numarası, adres, sağlık, mesajlar, fotoğraf/video, ses, dosyalar, takvim, kişiler, web geçmişi, uygulama bilgisi ve performans.

**Kişisel bilgiler**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Ad | Evet | Hayır | Hayır | **Zorunlu** | **Uygulama işlevselliği** (çocuk profili), **Hesap yönetimi** |
| E-posta adresi | Evet | Hayır | Hayır | **Zorunlu** | **Hesap yönetimi** |
| Diğer bilgiler | Evet | Hayır | Hayır | **Zorunlu** | **Uygulama işlevselliği** (çocuk profili: yaş / yaş bandı, avatar, profil ayarları) |
| Kullanıcı kimlikleri | Evet | Hayır | Hayır | **Zorunlu** | **Uygulama işlevselliği**, **Hesap yönetimi**, **Sahtekârlığı önleme, güvenlik ve uygunluk** (deneme süresinin hesap başına bir kez verilmesi) |

**Uygulama etkinliği**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Uygulama etkileşimleri | Evet | Hayır | Hayır | **Zorunlu** (kurulum istatistiği her kurulumda gider; günlük oyun özetleri yalnız girişte ve kapatılabilir) | **Uygulama işlevselliği**, **Analizler** (yönetici sayfası: günlük oyun ve süre, funnel) |
| Kullanıcı tarafından oluşturulan diğer içerikler | Evet | Hayır | Hayır | **İsteğe bağlı** (yalnız ebeveyn geri bildirim ya da anket gönderirse) | **Uygulama işlevselliği** (destek ve iyileştirme), **Analizler** (anket) |

**Finansal bilgiler**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Satın alma geçmişi | Evet | Hayır | Hayır | **Zorunlu** (giriş zorunlu; hesabın planı) | **Uygulama işlevselliği**, **Hesap yönetimi**, **Analizler** |

**Cihaz veya diğer kimlikler**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Geçici mi | Zorunlu / isteğe bağlı | Amaç |
|---|---|---|---|---|---|
| Cihaz veya diğer kimlikler | Evet | Hayır | Hayır | **Zorunlu** | **Analizler** |

Notlar:

- "Ad": ebeveynin Google adı (Firebase Authentication) ve ebeveynin girdiği çocuk adı/takma adı (çocuk profili).
- "Diğer bilgiler": çocuğun yaşı / yaş bandı, avatar ve profil ayarları (`families/{uid}/children/{id}`).
- "E-posta": Google ile ya da e-posta bağlantısıyla girişte Firebase Authentication alır; ayrıca `families/{uid}.email`. E-postayla giren kullanıcıda ad ve fotoğraf yoktur.
- "Kullanıcı kimlikleri": Firebase UID. Deneme kaydı (`trials/{uid}`, yalnız başlangıç zamanı) ve özetler bu kimlikle saklanır.
- "Uygulama etkileşimleri": günlük özetler (tarih, tema, oyun türü, zorluk, aktif süre, tur ve aşama sayısı, kendi başına doğru sayısı; özetlerde çocuğun adı ya da tek tek yanıtları yok), son açılış ve kurulum adımları; kurulum istatistiğinde açılış günleri, kart başına açılma/bitirme sayıları, teklif ekranı seçimi ve bildirim izni sonucu (6 Kasım 2026).
- "Paylaşılıyor" = **Hayır**. Google (Firebase, Play) bizim adımıza veri işleyen hizmet sağlayıcıdır; Play'in tanımına göre bu paylaşım sayılmaz.
- Satın almalar: ödemeyi Google Play işler; ödeme bilgisi bize gelmez. Giriş yapılmışsa hesabın planı (ücretsiz/deneme/aylık/yıllık/ömür boyu/tanımlı) `families/{uid}.plan` olarak gider, bu yüzden "Satın alma geçmişi" **işaretlenir**.
- "Cihaz veya diğer kimlikler": uygulamanın ürettiği rastgele kurulum kimliği (`funnel/{installId}`); yalnız kurulum adımlarının ilk zamanları, platform, sürüm ve dil; 6 Kasım 2026'dan (2.0.47) beri ayrıca uygulamanın açıldığı yerel tarihler (son 60), ilk turun bittiği zaman, kart başına açılma/bitirme sayıları (tema ve oyun kimliği), teklif ekranında dokunulan düğme (deneme, plan ve plan kimliği, geri) ve Android bildirim izninin sonucu (izin verildi/verilmedi). Çocuğun adı, yanıtları ya da hesap bilgisi bu kayda yazılmaz. Android ID, AAID, IMEI gibi kimlikler **kullanılmaz**; Google hesabına bağlanmaz.
- "Kullanıcı tarafından oluşturulan diğer içerikler": ayarlardaki geri bildirim mesajı ve kısa anket (`feedback/{id}`; mesaj, anket için memnuniyet 1-5, kim kullanıyor, geliştirme seçimleri; zaman, sürüm, dil, platform, kurulum kimliği, UID ve e-posta). Yalnız yönetici okur. (23 Ekim 2026)
- Son açılış ve uygulama sürümü (`families/{uid}.lastSeenAt`, `appVersion`) "Uygulama etkileşimleri" kapsamındadır.
- Çocuk profili hesapta saklanır: ad (≤40 karakter), yaş ya da yaş bandı, avatar kimliği ve profil ayarları (`families/{uid}/children/{id}`; 23 Ekim 2026). Onboarding anket cevapları ve tek tek oyun yanıtları yalnız cihazda kalır. Fotoğraf yok.
- Google Play değerlendirme penceresi (In-App Review) Play'in kendi arayüzüdür; uygulama puanı ya da yorumu görmez.

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
| **Uygulama erişimi** (inceleme ekibi için) | **İşlevlerin tamamı veya bir kısmı kısıtlı** (23 Ekim 2026'dan beri giriş zorunlu). Talimat: "Uygulama herhangi bir Google hesabıyla açılır (özel hesap gerekmez). Kurulumun sonunda 'Google ile giriş' yapın ve '7 gün ücretsiz dene'ye dokunun; ödeme istenmez. Ebeveyn kapısı ekranda yazan çarpma sorusudur." Kullanıcı adı/şifre alanlarını boş bırakın, gerekiyorsa bir test Google hesabı ekleyin. |
| **Hedef kitle ve içerik** | Hedef yaş grupları: **5 yaş ve altı**, **6–8 yaş** (isteğe bağlı **9–12**). Çocuklara hitap ediyor mu: **Evet**. Families politikası kapsamına girer. |
| **İçerik derecelendirmesi** anketi | Kategori: **Eğitim** / Referans. Şiddet, cinsellik, küfür, kumar, kullanıcı etkileşimi, konum paylaşımı, dijital ürün satın alma (**Evet**: uygulama içi satın alma var). Beklenen sonuç: **Herkes / 3+ (PEGI 3, IARC 3+)**. |
| **Haber uygulaması** | Hayır |
| **COVID-19 izleme** | Hayır |
| **Sağlık uygulaması** beyanı | Sağlık/tıbbi işlev **yok**. Eğitim uygulamasıdır, tanı veya tedavi sunmaz. |
| **Finansal özellikler** | Yok |
| **Devlet uygulaması** | Hayır |
| **Hesap silme** | Uygulama içinde: Aile → Hesap → "Hesabı ve bulut verilerini sil" (Firebase hesabı, aile kaydı, çocuk profilleri, günlük özetler silinir). Web: yukarıdaki URL. |
| **Hesabı silmeden veri silme** | Aile → Profiller'de bir çocuk profilini silmek onun hesaptaki kaydını da siler; günlük özet gönderimi Aile alanından kapatılır; diğer talepler e-postayla. |

## 4. Families programı notları

- Çocuk modunda reklam, satın alma istemi, dış bağlantı ve giriş yok. Bunların hepsi ebeveyn kapısının arkasında, dikey ebeveyn ekranlarında.
- Reklam kimliği (AAID) ve kalıcı cihaz kimlikleri toplanmaz; kurulum istatistiği yalnız uygulamanın ürettiği rastgele kimliği kullanır.
  - Android 13+ için `com.google.android.gms.permission.AD_ID` izni manifestte **olmamalı**. Release AAB'de kontrol edin (`tools/audit_android_apk.py`).
  - Bağımlılıklar reklam SDK'sı içermiyor.
- Firebase SDK'ları: Auth, Firestore, Core (Families sertifikalı SDK listesinde). Firebase Analytics ve Crashlytics **yok**.
- Uygulama içi satın almalar Google Play Billing ile yapılıyor; Families için uygun.
- İsteğe bağlı: Play Console → "Teacher Approved" (Öğretmen Onaylı) programına başvuru; Kids sekmesinde görünürlük sağlar.
