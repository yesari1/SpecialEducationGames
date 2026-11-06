# Gizlilik Politikası — ÖZEL TASLAK / YAYINLANAMAZ

> **Yayın öncesi zorunlu tamamlama:** Bu belge taslaktır; yayımlanmış politika değildir. `[GELİŞTİRİCİ/KURUMUN YASAL ADI]`, `[GİZLİLİK İLETİŞİM E-POSTASI]`, `[YAYINLANMIŞ POLİTİKA URL'Sİ]`, yürürlük tarihi, veri saklama/yedek süresi ve hesap/veri silme yolu henüz doğrulanmadı. Hukuki ve mağaza uyum incelemesi yapılmadı. Eksik alanları doldurmadan ve gerçek uygulama davranışını yeniden denetlemeden yayımlamayın.

**Son incelenen uygulama davranışı:** 17 Ekim 2026. **Sorumlu:** `[GELİŞTİRİCİ/KURUMUN YASAL ADI]`.

## Kapsam

Bu taslak, Android için Özel Eğitim Oyunları uygulamasının incelenen yerel kod davranışını açıklar. Yalnızca kaynak kodu ve yapılandırması incelenmiştir; canlı Firebase hizmeti, mağaza ayarları, sunucu günlükleri, yedekler ve gerçek satın almalar doğrulanmamıştır. Bu nedenle belge yayına hazır değildir.

## Çocuk profilleri ve cihazda tutulan bilgiler

Uygulama, oyun için ebeveynin girdiği bir çocuk takma adını, avatarı ve isteğe bağlı başlangıç anketi yanıtlarını cihazdaki yerel SQLite veritabanında saklar. Anket; yaş aralığı, iletişim biçimi, söylenen nesneyi gösterme, dokunma/sürükleme becerisi, sese hassasiyet, odaklanma süresi, bilinen/tercih edilen temalar ve sayma becerisi hakkında seçenekler içerir. Bu yanıtlar yerel profil ayarları ve oyun tercihleri için kullanılır.

Oyun geçmişi cihazda; tema/oyun/öğe kimlikleri, zorluk, yanlış yanıt ve ipucu sayıları, seçilen seçenek kimlikleri, yanıt gecikmesi, aktif/tepkisiz süre ve tur zamanları gibi alanlarla tutulur. Profil ayarları, uygulama dili, ses/erişilebilirlik tercihleri, ebeveyn kapısı PIN'inin tuzlanmış özeti ve yerel satın alma erişim önbelleği de cihaz verileridir. Takma ad, avatar, anket yanıtları ve ham seçim geçmişi özet eşitleme payload'ına dahil edilmez.

## İsteğe bağlı ebeveyn hesabı ve çevrimiçi istekler

Oyunları yerel olarak kullanmak için Google hesabı zorunlu değildir. Ebeveyn, aile alanında Google ile oturum açmayı seçebilir. İncelenen uygulama kodu Firebase Authentication kullanır ve uygulama hesabı modeline Firebase UID'si ile e-posta adresini alır; ebeveyn profil fotoğrafı veya görünen ad uygulamanın kendi hesap modelinde tutulmaz. Google/Firebase'in oturum açma sırasında işlediği bilgiler ve teknik servis günlükleri bu kaynak denetiminden tam olarak çıkarılamaz; yayımlamadan önce sağlayıcı yapılandırması ve ilgili açıklamalar doğrulanmalıdır.

Android uygulaması Firebase Firestore'dan genel `config/app` yapılandırmasını ve yalnızca ebeveynin seçtiği duyuru kimliğine ait duyuru metnini okumaya çalışır. Okumaların canlı projede çalıştığı doğrulanmış değildir. Hesapla giriş yapıldıktan sonra aile, belirli bir profil için günlük özet paylaşımına ayrı bir onay verip **Eşitle** eylemini başlatabilir. Onay/ebeveyn/hesap/profil kapsamı değişince işlem iptal edilir. Eşitleme alanları gün, tema, oyun modu, zorluk, toplam aktif süre, tur/aşama ve bağımsız yanıt sayıları ile güncelleme zamanıdır; ham seçimler ve anket yanıtları gönderilmez. Bu özellik tam profil yedeği değildir. Eşitleme için Firestore'a aile UID'si ve profil kimliği yol içinde de kullanılır. Canlı bulut aktarımı henüz doğrulanmadı.

## Hesapsız kurulum istatistiği

Uygulama, her kurulumda kendi ürettiği rastgele bir kurulum kimliğiyle Firestore'daki `funnel/{installId}` kaydına anonim kullanım istatistiği yazar. Bu kayıt Google hesabına, Android ID'ye veya reklam kimliğine bağlanmaz ve yalnız yönetici okur. İçeriği: kurulum ve kurulum adımlarının ilk zamanları, platform, uygulama sürümü, dil, telefon modeli, bildirim adresi (FCM token), toplam ve günlük oyun süresi, oynanan gün sayısı; 6 Kasım 2026'dan beri ayrıca uygulamanın açıldığı yerel tarihler (son 60), ilk turun bittiği zaman, kart başına (tema ve oyun) açılma ve bitirme sayıları, teklif ekranında dokunulan düğme (deneme, plan ve plan kimliği, geri) ve Android bildirim izninin sonucu. Çocuğun takma adı, anket yanıtları ve tek tek oyun yanıtları bu kayda yazılmaz.

## Satın almalar

Uygulama Android'de abonelik tekliflerini Google Play'den sorgular; görünen fiyat ve uygun teklif Play yanıtına bağlıdır. Satın alma ve geri yükleme işlemleri Google Play Faturalandırma üzerinden yürütülür; uygulama ödeme kartı bilgilerini istemez veya saklamaz. İncelenen kod, fiyatı, deneme uygunluğunu ve satın alma durumunu Play yanıtından alır. Gerçek ürünler, fiyatlar, satın alma, geri yükleme ve mağaza hesabı doğrulanmadı. Bir Google Play aboneliği, Firebase hesabının silinmesiyle otomatik iptal edilmiş sayılmaz; iptal işlemi Google Play'de ayrıca yapılır.

## Reklam ve tanılama

İncelenen sürümde Firebase Analytics, Firebase Crashlytics veya bilinen bir reklam SDK'sı bağımlılığı yoktur. Kaydedilen release manifest denetiminde Android reklam kimliği (AD_ID) ve AdServices izinleri bulunmamıştır; bu sonuç incelenen derleme için geçerlidir. Kaynak Android manifesti internet izni içerir. Bu bulgular, ileride eklenecek SDK'ların etkisini ya da Play Console beyanını kapsamaz. Analitik veya çökme raporu eklenirse bu politika, çocuk verisi kuralları, izinler ve birleşik release bağımlılık/manifest denetimleri yeniden değerlendirilmelidir.

## Saklama, silme ve başvuru

Yerel profil silme ekranı, seçilen profilin yerel profil kaydını, ham oyun/tur kayıtlarını, profil tercihlerini ve o profille ilişkili yerel özet kopyalarını temizler. Bu işlem, buluttaki hesap verisini silmez. Ebeveyn hesabıyla ilişkili Firestore verileri için hesap silme kullanıcı arayüzü ve çalışan sunucu akışı mevcut değildir. Sunucu hesabı silme kodu taslak ve varsayılan olarak kapalıdır; canlıya alınmamış ve gerçek hesapta doğrulanmamıştır. Dolayısıyla bu belge şu anda bulut hesabının silinebildiğini iddia edemez.

Yerel veriler için saklama süresi ve cihaz yedeklerinin davranışı: `[SAKLAMA/YEREL YEDEK POLİTİKASI — SAHİP ONAYI GEREKİR]`. Bulut verileri, yedekler ve hizmet sağlayıcı kopyaları için saklama/silme süresi: `[BULUT SAKLAMA VE SİLME SÜRESİ — SAHİP ONAYI GEREKİR]`. Veri silme başvurusu: `[HESAP/VERİ SİLME İÇİN ÇALIŞAN, KAMUYA AÇIK URL]`; destek/gizlilik irtibatı: `[GİZLİLİK İLETİŞİM E-POSTASI]`. Bu başvuru kanalları henüz sağlanmadı; yer tutucular çalışır iletişim yolu değildir.

## Çocuklar ve yayımlama incelemesi

Uygulama çocuklara yönelik bir ürün olarak tasarlanmıştır. Bu metin hukuki tavsiye, COPPA/GDPR/Families uyumluluk beyanı veya mağaza onayı değildir. Google Play, çocuklara yönelik uygulamalarda uygulamanın kullandığı API ve SDK'lar dahil kişisel/hassas veri uygulamalarının açıklanmasını ve hedef kitle/Veri Güvenliği beyanlarının doğru tutulmasını ister. Güncel hedef kitle, veri akışları, SDK şartları, mağaza beyanları ve yerel hukuk yetkin bir inceleyici tarafından değerlendirilmelidir. [Google Play Families politikası](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)

## Değişiklikler ve iletişim

Yürürlük tarihi: `[GG.AA.YYYY — SAHİP ONAYI]`. Politika URL'si: `[YAYINLANMIŞ HTTPS URL]`. Veri sorumlusu/işletmeci: `[YASAL AD VE ADRES — SAHİP ONAYI]`. Gizlilik başvuruları: `[E-POSTA]`. Bu alanlar tamamlanıp yayımlanmadan kullanıcıya yürürlükteki politika olarak sunulmamalıdır.
