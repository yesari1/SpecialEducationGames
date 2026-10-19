# Uygulama geliştirme kontrol listesi

## Güncel durum — 19 Ekim, test APK R25

- [ ] Haftalık kalan%1 (<%2): yeni kod/model işi bekler;5saat%59 engel değil. Haftalık reset24Ekim23:40:37Europe/Istanbul; mevcut yarım saat kontrolleri aktif.

- [x] R25 normal main universal profile APK üretildi/telefona kuruldu; hash/üç ABI/signer korundu. Yatay tek sayfa welcome incelendi; COLD8836ms tek emülatör ölçümü, genel performans kabulü ayrı. TEST_NOTLARI_R25.md.
- [x] R25 genel analiz temiz ve seri host227/227 geçti. İki paralel koşu tutarsız başarısız kaldı; çözülmüş sayılmaz. Sonraki tam doğrulama serial/stdout-stderr ayrı tercihli. R24fotoğrafpipeline5/5 değişmeyen varlıklar için geçerli.
- [x] Aile native TR/EN%200 gerçek viewport/çentik/güvenli alanlarda tüm rapor/ayar/credits/lisans/geri/oyun/profil rotaları geçti; ağ restored:true. Onboarding öncekiTR/EN%200 Android kabulü korunur. Fiziksel/TalkBack kabulü ayrı.
- [x] Sistem yazısını%130'da kesen sınır kaldırıldı; haftalık kart23px taşması tam metin korunarak giderildi; aktif düzen dikey kaydırmasız/yatay sayfalı.
- [x] G04/G33/G36/G14/G10/G35 sabit yönergeleri toplam dokuz tipli ARB anahtarına taşındı; eski sözcükler/dinamik sorular korundu. Credits ses sekmesi Doğal sesler/Natural sounds oldu.
- [x] Kuş fotoğrafı:31öğede32lisanslıfotoğraf/10doğalefekt/42kaynak; önceki kayıtlar/varlıklar korundu. İnsan nihai görsel/dinleme onayı ayrı.
- [ ] API37tablet temiz kabulü yok: yeni başlangıçta uygulama bu oturumda başlatılmadan PixelLauncher/Googleinteractor ANR doğrulandı. Önceki SystemUI/letterbox kesin kök nedeni bilinmiyor. r24-tablet-blocker.md ve r25-tablet-baseline; ayar değişikliği yok/QA5556 kapalı, API36/fiziksel tablet açık.
- [ ] 8eksikfotoğraf/108eski görsel incelemesi, seçilmiş ses insan onayı ve canlı Google/Firestore/Play/AppCheck/silme işleri açık. Son fasulye kaynağının iki maske denemesi gölge/kesik kontur nedeniyle reddedildi; uygulamaya eklenmedi. Bozulan deneme raporu açıkça kayıtlı; özgünler/çıktılar korundu. Üçüncü otomatik aynı kaynak denemesi yok.

- [x] Tren doğal efekt kaydı eklendi;8lisanslıefekt/38kaynak. Primary focused5/5; araba+tren G10kolay hedefminimumunu sağlar, TR/EN/mute kapıları korunur. İnsan dinlemeonayı ayrı; R20APK bu yeni treni içermez, paketleme nativeQA sonrası.

- [x] R20 gerçek araba korna efekti/tekilCC0kaynak/bundle doğrulandı;7efekt/37kaynak. Primary G10dil/mute/asset4/4 ve credits-layout1/1; APKkuruldu/WARM9.252s/welcomePNGincelendi. İnsan sesonayı/performance ayrı; TEST_NOTLARI_R20.md.

- [x] R19 gerçek köpek fotoğrafı eklendi:29 öğe/30fotoğraf/36kaynak;8eksik/110inceleme. Primary fotoğraf5/5 ve gerçekmanifest credits-layout1/1 geçti. Universal profile APK kuruldu, başlangıçbeklemesi timeout sonrası welcome PNG incelendi; performans kabulü ayrı. TEST_NOTLARI_R19.md.

- [x] R18 universal profile normal main kuruldu/cold-start7.824s/welcome PNG incelendi; primary analyze temiz,206/206 host test. G02+G55 TR/EN2x Android native geçti. Güncel paket/eksikler TEST_NOTLARI_R18.md.
- [x] Gerçek F22 uçak fotoğrafı kaynak/lisans/provenance/4pxkontur ile eklendi;28 öğede29fotoğraf/35kaynak,8eksik/111inceleme. Primary fotoğraf5/5; insan nihai onayı bekler.
- [x] Hesap silme callable SDK adaptörü varsayılan kapalı, aynı UID/confirmDelete/katı yanıt/hata testleriyle hazır. Mevcut143bağımlılık sürümü aynı, yalnız cloud_functions+iki platform paketi eklendi.
- [ ] Hesap silme ebeveyn akışı/AppCheck ve canlı sunucu kabulü: işletmeci politikaları/deployment/Google-Firebase dış bağımlılıkları bekler. Adaptör tamamlanmış ürün özelliği değildir.

- [x] R16 universal profil APK mevcut signer ile kuruldu; iki normal cold-start sonrası yatay welcome görüntüsü doğrulandı (ilk splash/başlangıç yavaşlığı ayrıca kayıtlı). Landscape isteği nonblocking, manifest kilidi korunur. Fiziksel telefon/performance kabulü değildir; önceki debug siyah görüntünün kesin kök nedeni açık. TEST_NOTLARI_R16.md.
- [x] G55 dört/beş/altı öğelik oturum, tüm öğeleri açmadan bitirmeme, sayaç ve replay reset; G02/G55 fotoğraf/etiket yan yana. Primary197test/analiz ve G02+G55 TR/EN native akışları geçti; R15 normal başlangıç QA ayrı açık.
- [x] R13 normal APK kuruldu/açıldı: G14 zor seviyede aynı nesnenin iki farklı doğrulanmış fotoğrafı, içerik uygunluk koruması ve balık için iki gerçek fotoğraf. Primary genel analiz temiz; 190/190 host test, 5/5 fotoğraf pipeline testi, TR/EN iki native G14 akışı geçti. TEST_NOTLARI_R13.md kanıt ve sınırları içerir.
- [x] Balık birincil/alternatif fotoğraf metadata ve kaynak/lisans zinciri düzeltildi; 27 öğede 28 doğrulanmış fotoğraf, 176/184 görsel, 8 eksik, 112 eski görsel incelemede; 34 kaynak kaydı. Teknik kabul, insan nihai fotoğraf onayı değildir.
- [ ] G14 Hard diğer temalarda doğrulanmış farklı fotoğraf çifti bekler; şu an yalnız animals.fish uygun. Eksik içerik menü/günlük yol/başlatmada korunur.
- [x] G02 kolay5/zor15 kart oturumu; tüm kartları açmadan bitmez, sınırda gezinme durur, replay1'e döner, Hard manuel kalır. Medium10 ara değer; kısa havuz gerçek sayısını gösterir. G55 korundu. Primary195/195tamtest ve genelanaliz temiz; TR/EN800x360/2x gerçekfont hostkontrolü geçti. R14 normal APK kuruldu/açıldı (PID27739); yeni screenshot ADB beklemesi nedeniyle doğrulanmadı. R13 bu eklemeyi içermez.

- [x] R12 normal APK kuruldu/açıldı; Google mevcut UID üzerinde ebeveyn korumalı yeniden doğrulama altyapısı. İşlem atlanması/iptali/hatası veya yetki kaybı başarı döndürmez. Primary178test; son bool sözleşmesi sonrası auth6/6/scopedanaliz. Notlar artifacts/test-builds/2026-10-18/TEST_NOTLARI_R12.md.
- [ ] Yeniden doğrulamayı canlı Google hesabıyla kabul et ve hesap silme istemci/callable/AppCheck akışını tamamla; yeni altyapı bu dış entegrasyonları tamamlamaz.

- [x] R11 APK kuruldu/açıldı; kaplumbağa gerçek fotoğrafıyla26lisanslı fotoğraf/176görsel/8eksik/113inceleme/32kaynak kaydı. Primary fotoğraf3/3 ve kredi1/1 geçti. Güncel notlar artifacts/test-builds/2026-10-18/TEST_NOTLARI_R11.md.
- [x] G10 sesli seçim için TR/EN800x360/2x yeni host testi: ses gate/mock oynatım, dört tam etiket/48pxhedef/doğrucevap/dikeykaydırma yokluğu ve iki azaltılmış hareket bayrağı. Primary1/1/scopedanaliz temiz; native ses duyma/onay yerine geçmez.
- [x] G10 gerçek Android viewport/TR/EN2x native test1/1 uçak modunda geçti; ağ restoredtrue. AudioBackend mock olduğundan hoparlör kalite onayı değildir. Normal R11 APK testten sonra yeniden kuruldu/açıldı.

- [x] R10 normal APK kuruldu/açıldı: artifacts/test-builds/2026-10-18/ozel-egitim-test-r10.apk. Ahududu gerçek fotoğrafıyla25lisanslı fotoğraf/176görsel/8eksik/114inceleme;31kaynak kaydı. Primary fotoğraf3/3 ve kredi widget1/1 geçti; çekirdek175test/üç native oyun akışı R9 kanıtıdır, fotoğraf değişikliği için tekrarlanmadı.
- [x] Ayrı API37/sw800dp tablet kontrolü: dört fiziksel rotasyonda uygulama yatay yüzeyini korur; fiziksel dikeyde siyah boşluklar görülür. Bu API36 runtime doğrulaması değildir. Yalnız geçici headless tablet kapatıldı; önce rotation free geri yüklendi, telefon emülatörü R10 açık kaldı.

Bu bölüm güncel kabulü gösterir. Aşağıdaki tarihli kayıtlar geçmiş niteliğindedir; biten işler yeniden yapılmaz. Yerel test, canlı servis ve insan onayı ayrı değerlendirilir.

- [x] GPT-6 Luna uygulama çalışanı; Codex inceleme/doğrulama. DeepSeek, InferX ve Gemini kapalı tutulur.
- [x] Yarım saatlik otomasyon etkin; sabit 08:00 bitişi kaldırıldı. Yeni iş yalnız beş saatlik kalan en az %8 ve haftalık en az %2 ise başlar.
- [x] Onboarding, ebeveyn kapısı, ana aile/ayar/hesap/abonelik/kaynaklar, sonuç/album/günlük yol/mola için yatay düzen ve gerçek fontlu TR/EN boyut/yazı ölçeği testleri.
- [x] İlk dil cihazdan gelir. Onboarding için 48 ekran görüntüsü, azaltılmış hareket ve 48px dokunma hedefleri doğrulandı.
- [x] Yanlış dildeki eski konuşma kaydı eşlemeleri engellendi; G10/günlük yol aynı dil uygunluğunu kullanır. Eksik İngilizce kayıtlar tamamlanmadı.
- [x] Home/Theme, onboarding, ebeveyn kapısı, ana aile ekranı ve oyun/günlük yol için R2 kapsamında 165, R3 profil düzenleyiciyle toplam 181 yeni typed ARB kaynağı. R3 genel analiz temiz; 160 test geçti.
- [x] Açık kaynak paket/lisans metinleri yatay ve tam sunulur. Gerçek Android paket lisansı testi geçti; üretim SDK'sı değiştirilmedi.
- [x] Çilek, nar, greyfurt ve ayva gerçek fotoğrafları lisans/maske/PNG incelemesinden sonra eklendi. Bu R2 aşamasındaki envanter19fotoğraf/171görseldi; güncel R8 envanteri aşağıda23fotoğraf/174görsel olarak kaydedilir.
- [x] R2 normal APK derlendi, emülatörde açık: [APK](artifacts/test-builds/2026-10-17/ozel-egitim-test-r2.apk), [notlar](artifacts/test-builds/2026-10-17/TEST_NOTLARI_R2.md). Uçak modunda tüm integration dosyaları 5/5 geçti; ağ ayarları geri yüklendi.
- [x] TR/EN gizlilik/mağaza ve hesap silme belgeleri iç taslak olarak hazırlandı. Kurum/iletişim/URL/saklama ve canlı servis doğrulamaları tamamlanmadığından yayıma hazır değiller.
- [x] Ayrı profil düzenleyici yatay; 16 typed ARB kaynağı, büyük yazı/uzun ad/kayıt hatası testleri ve gerçek Android create/edit akışı geçti. R3 normal APK kabul edildi; R2 bu eklemeyi içermez.
- [x] Kaynak/lisans/hesap/abonelik/profil öneri geçişleri iki azaltılmış hareket bayrağına uyar; normal animasyon korunur. Primary genel analiz temiz, 160/160 test geçti.
- [x] R4 normal APK kuruldu/açıldı;166test/genelanaliz ve etkilenen Androidlisans1/1 geçti. Diğer5+1Androidkanıtı R3tarihli. Notlar artifacts/test-builds/2026-10-18/TEST_NOTLARI_R4.md; önceki paketler korunur.
- [x] Kalan rapor/mola/sayma semantiği/abonelik/kaynak/lisans sabit UI metinleri typed ARB: R4 primary166test/analiz ve Androidlisans1/1. Güncel sınırlı audit artifacts/reviews/localization-r4-2026-10-18.md.
- [x] Şeftali ve coconut fotoğrafları primary görsel/lisans ve 3/3 override kontrolünden geçti. Kaynakta21fotoğraf/172görsel/12eksik; credits27. İnsan onayı ayrıdır.
- [x] R6 normal APK: yeni fotoğraflar, kompakt yatay seçenek sayfaları, kurbağa grup etiketi ve içerik hata ekranı; primary 171/171 test, temiz analiz, gerçek main kurulum/açılış. Notlar artifacts/test-builds/2026-10-18/TEST_NOTLARI_R6.md.
- [x] Tam/Sade/Kapalı kutlama seçimi iki ayar düzeninde; 480ms noninteractive Tam efekti, iki azaltılmış hareket bayrağına uyum. Primary genel analiz ve174/174test geçti; R7 normal APK/emülatörde açık. TEST_NOTLARI_R7.md.
- [x] G04 native Android uçak modu TR2x/dört seçenek/pager/ipucu/doğru yanıt primary1/1; test viewport ve session cleanup düzeltildi, ağ geri yüklendi. artifacts/validation/r8-native-game/android-pass.log/json.
- [x] G04 native Android TR2x/pager/Tam kutlama gerçek PNG görüntüleri primary incelendi; helper host driver ve ağ settling kontrolü geçti. G04 soru görseli96px ve tam soru yan yana; genel174test/analiz temiz. R8 normal APK kuruldu/açık, TEST_NOTLARI_R8.md.
- [x] Ananas/kayısı teknik kaynak kabulü ve R8 APK entegrasyonu:23fotoğraf/174görsel/10eksik/114inceleme,29kredi; primary3/3fotoğraf kontrolü. İnsan nihai beğenisi ayrı.
- [x] Katalog tur üretimi için TR/EN, üç zorluk ve sekiz seed sınırlı audit; primary yeni test1/1 ve kapsam analizi temiz, R6 APK değişmedi.
- [ ] İçerik prompt/anket/skill metadata çeviri ve insan kalite denetimi; sabit UI tamamlanması tüm içerik onayı değildir.
- [x] Maksimum duyuru başlık/gövdesi yatay tam metin sayfaları; gerçek host TR/EN boyut/ölçek, Unicode/boş satır/uzun kelime/reflow testleri ve genel166test geçti. Canlı duyuru servisi kabulü ayrı.
- [x] Otomobil gerçek fotoğrafı CC0 kaydıyla kaynak kataloğa entegre edildi; fotoğraf testleri 3/3. Güncel 19 doğrulanmış fotoğraf; R2 bu eklemeyi içermez. Köpek adayları reddedildi.
- [x] ChoiceCard çift spoken-name düzeltmesi primary167test/temizanalizle doğrulandı ve R5normalAPK/emülatöre alındı. R4bu düzeltmeyi içermez; artifacts/test-builds/2026-10-18/TEST_NOTLARI_R5.md.
- [x] Gerçek GameScreen SemanticsAction.tap ile doğru cevabı seçme ve dismissed alternatiflerin aktif semantik ağaçtan çıkması TR/EN primary1/1. R5aynıAPK.
- [x] G01dörtseçenek/G33sayma/G35dizi kompakt800x360x2TR/EN temsilciUIkabulü primary1/1; üretimfreegatingdeğişmedi, tümoyun/performanskanıtıdeğil.
- [x] R9: enginar fotoğrafı ve kesirli ekranda doğru-yanıt işareti taşması düzeltildi. Primary175/175test/temizanaliz, üç native Android akışı (G04TR2x/G01EN1x/G33TR2x) geçti; ağ geri yüklendi. Normal APK/emülatörde açık, TEST_NOTLARI_R9.md.24fotoğraf/175görsel/9eksik/114inceleme.
- [ ] Kalan içerik ve erişilebilirlik/performance kabulü; canlı Google/Firestore/Play, hesap silme, telemetry ve yayın hakları ayrıca açık.
Güncelleme: 16 Ekim 2026. Bu dosya güncel iş listesidir; ayrıntılı geçmiş ve test sonuçları [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) içindedir. Kaynak kapsam: ürün raporu §15, tasarım sistemi ve içerik kataloğu. Kullanıcının son doğrudan talepleri eski belge kararlarının önündedir.

**İşaretleme:** `[x]` uygulanmış ve belirtilen düzeyde doğrulanmış; `[ ]` kalan iş. Kısmen yapılan büyük işler alt maddelere ayrılır. Kodun bulunması, canlı entegrasyonun çalıştığı anlamına gelmez. Her somut değişiklikten sonra ilgili madde ve doğrulama notu güncellenir.

## Şimdi yapılacaklar — son kullanıcı talepleri

- [x] Güncel iş bölümü: native GPT-6 Luna uygulama çalışanı; Codex kapsam/inceleme/doğrulama yöneticisi. InferX/DeepSeek/Gemini çağrılmaz; eski araç/anahtarlar korunur. Önceki InferX kararı son kullanıcı talimatıyla geçersizdir.
- [x] Önceki DeepSeek kuyruğu tarihsel kaynak olarak korundu; güncel işler bu TODO ve dar Luna görevleri üzerinden kaynak kanıtlarıyla yönetilir. Eski kuyruğu yeniden çalıştırma.
- [x] İlk uygulama birimi: DeepSeek karşılama ekranındaki dikey kaydırmayı kaldırdı. Beş bilgi yatay sayfalarda erişilebilir; önceki/sonraki düğmeleri ve >=64px başlangıç eylemi TR/EN 800×360, 1280×800, %100/%160/%200 yazıda doğrulandı. Codex incelemesi ve bağımsız testler geçti; genel 120 test ve analiz temiz. Bu yalnız karşılama ekranını kapsar.

- [x] Yatay arayüzde dikey kaydırmayı kaldır: aktif production scrollable'lar yatay; kısa yatay TR/EN/büyük yazıda onboarding, home/theme, oyun/sonuç, ebeveyn/aile/profil/credits/licenses ve mola focusedwidgetkontrolleri geçti. Primary216/216fullsuite+analiz temiz. Mevcut nativeG02/G55/G10/diğer seçili akış kanıtları kapsamı sınırlıdır.
- [ ] Aile ekranlarının nativeTR/EN2x route/inset doğrulamasını genişlet; tüm gerçekcihazların fiziksel/performance/TalkBack kabulü ayrı bekler. Yeni dar family nativefixture Luna'da, henüz primary doğrulanmadı.

- [x] Yapılanlar/kalanlar için bu tek kontrol listesini oluştur; durum günlüğünden bağlantı ver.
- [x] Mevcut yarım saat otomasyonu etkin; eski saat kesimi kaldırıldı. Yalnız5saat kalan<%8 veya hafta kalan<%2 ise yeni kod/model işi bekler; eşitlik çalışmaya izin verir.
- [x] Uygulama başlangıcına iki yatay yön kilidini ekle. Android telefon doğrulaması ve büyük ekran platform kısıtları ayrıca aşağıda izlenir.
- [x] İlk dili telefon dilinden seç (Türkçe → TR, diğer → EN); ilk açılış dil sorusunu kaldır; ebeveyn ayarından değiştirmeyi koru. Kalıcılık/profil tercihi dahil 4 yeni test geçti; anket 9 sorudur.
- [x] Beyaz zemin, canlı turuncu/mavi/turkuaz palet ve modern yumuşak geçişli/beyaz kenarlıklı butonları uygula.
- [x] Tema/oyun kartlarını yeniden düzenle; başlıkları ortala ve yatay kısa ekranda taşmayı gider. TR/EN 800×360 ve 1280×800 ana/tema/günlük yol QA geçti; başlık merkez sapması <1 px.
- [x] Yeni arayüzü Pixel_9a emülatöründe aç ve normal main screenshot'ını incele; TR/EN yatay telefon/tablet boyutlarında UI render QA geçti. Gerçek tablet donanımı kontrolü ayrıca bekliyor.
- [x] Karşılama ekranını yatay iki sütuna düzenle; başlama butonu TR/EN 800×360 ve1280×800 ekranlarında kaydırmadan görünür ve dokunulabilir. Normal Android screenshot ile doğrulandı.
- [x] Türkçe İrem / İngilizce Laura seslerinin kesin ElevenLabs kimliklerini hesaptaki seslerle doğrula (İrem `uvU9jrgGLWNPeNA4NgNT`, Laura `GZ4PpFJV8ikEGUtBrjK7`; farklı premade Laura seçilmedi).
- [x] Multilingual v2, tek kelime sonunda nokta ve ekran görüntüsündeki yaklaşık ayarlarla üretim aracını güncelle. Stability .35 / similarity .75 / style .43 / speed 1.0; kesin sayılar kullanıcı görselinde bulunmuyor. Ayarlar `tools/elevenlabs_voice_settings.json` içinde.
- [x] Yeni seçilen seslerle 20 örnek üret ve teknik doğrula (20/20 MP3). Galeri `artifacts/voice_samples_selected/index.html`; önceki Lauren dosyaları korundu. Telaffuz/beğeni onayı olarak sayılmaz.
- [ ] Eksik katalog seslerini yeni seçilen seslerle tamamla ve uygulamaya bağla (örneklerin üretilmesi tüm kataloğun seslendirildiği anlamına gelmez).
  - [ ] Öncelikli içerik düzeltmesi: 74 eski öğede TR/EN ses dosyası byte olarak aynı; 73’ünde kelimeler farklı. İngilizce konuşma tamamlandı sayılmaz. Kaynak/dil incelemesi yap, yanlış dilde geri dönüşü engelle; G10 için dile özgü ses uygunluğunu birlikte doğrula. Toplu ElevenLabs üretimi, kullanıcı onayı olmadan başlatılmadı.
  - [x] Mevcut örneklerden 7 kelime için toplam 14 TR/EN kaydı doğru öğe ve dile bağla. Noktalı metin, model, ses, ayarlar ve hash manifestte kayıtlıdır. Kesin anlam eşleşmesi olmayan 6 yönerge galeride kaldı; yeni TTS üretilmedi.
- [x] Ortak fotoğraf bileşenine alfa sınırını izleyen 4 mantıksal px beyaz kontur ekle. Orijinal RGB korunur, çerçeve kenarlığı değildir; önbellek/repaint boundary kullanır.
- [x] Kedi ve muz örneklerini tam kadrajı koruyarak büyüt ve 4 px beyaz konturla kontrol et: fotoğraf uzun kenarı 912 px, kontur dahil <=920 px; en az 52 px şeffaf boşluk, 1024×1024 RGBA.
- [ ] Doğal, tek ve tam nesneli lisanslı internet fotoğraflarıyla geçici AI görsellerini değiştir; tekil kaynak/yazar/lisans kaydını tut.
  - [x] Kedi ve muzu uygulamaya bağla; eski dosyaları koru. Doğrulanmış manifest önceliği, SHA256, yazar/lisans/uyarlama kaydı ve uygulama lisans ekranı eklendi. Python 2/2 ve yeniden üretim eşitliği geçti.
  - [x] Elmayı Evan-Amos Honeycrisp-Apple gerçek fotoğrafıyla değiştir (CC0 1.0); tam nesne/alpha/4px kontur/1024RGBA ve kaynak kaydı doğrulandı.
  - [x] Limon, biber ve kabak fotoğraflarını kaynak, lisans, alfa, 4 px kontur ve tekrarlanabilir işlem kaydıyla bağla. Limon eksik görseli tamamladı; kabaktaki ayrı gölge lekesi mekanik bileşen filtresiyle kaldırıldı.
  - [x] Domates ve portakalı Renee Comet/NCI kamu malı gerçek fotoğraflarıyla değiştir; Commons tekil kaynak/yazar/lisans,1024RGBA/tamnesne/4pxkontur ve2çalıştırmahash kanıtı kaydedildi. Eski6varlık korundu; final kullanıcı fotoğraf onayı bekler.
  - [x] Eksik kivi/avokado/kavuna3lisanslı gerçekfotoğraf bağla; batch3DPI96çalışmakopyası decodedRGBAhash eşitliğini doğrular,8eskiasset/kayıt korunur.1024RGBA/tamnesne/4pxkontur/2deterministikçalıştırma kanıtı var; finalkullanıcıonayı ayrı.
  - [x] Eksik pırasaya Amada44 / CC BY-SA 4.0 gerçek fotoğrafı bağla. Beyaz gövdeyi koruyan alfa maskesi, DPI/piksel eşitliği, iki deterministik çalışma ve 11 eski varlığın korunması kayıtlı; son kullanıcı onayı bekler.
  - [x] Yedi eski fotoğraftaki DPI kaynaklı gereksiz küçültmeyi gider. Açık piksel koordinatları, 72/96/240/320 DPI ve sekiz orijinal üzerinde doğrulandı; yedi çıktı iki çalıştırmada aynı hash verdi. Eski dosyalar yedeklendi, yazar/lisans korundu. Tarihsel kurulumun onarımı geri almaması testli.
  - [ ] Diğer öğeleri gerçek fotoğraflara geçir;134görselli öğenin12'si yeni doğrulanmış internet fotoğrafı sürecinden geçti.

## Faz 0 — hazırlık ve kaynaklar

- [x] Flutter 3.41.6 / Dart 3.11.4 ile proje ve sabitlenmiş bağımlılıkları hazırla.
- [x] Android applicationId `com.YeS.OzelEgitimOyunlari`, sürüm `2.0.0+14` koru.
- [x] Unity kaynağını değiştirmeden mevcut görsel/sesleri dışa aktar; boş referansları kaydet (63 görselli, 81 en az bir dilde sesli öğe).
- [x] Altı ücretsiz oyun kuralını rapor §13.1b'ye göre uygula.
- [x] Ücretsiz/ücretli görsel kaynaklarını ve lisans koşullarını araştır (`GORSEL_KAYNAKLARI.md`).
- [x] İki gerçek fotoğrafı kaynak ve lisans kaydıyla 1024×1024 RGBA örneğe hazırla; bunlar tüm katalogun bittiği anlamına gelmez.
- [ ] Eski Unity varlıklarının yayın haklarını doğrula.
- [ ] Play App Signing / mevcut imzalama anahtarını yetkili bilgilerle doğrula; anahtarı değiştirme.
- [ ] Kesin abonelik fiyatları ve Play ürün kurulumunu tamamla (ürün sahibi/Play Console dış bağımlılığı).

## Faz 1 — temel uygulama (henüz tamamlanmadı)

### Mimari ve içerik
- [x] Router, Drift SQLite, offline Nunito fontu ve ortak bileşen altyapısını kur.
- [x] CSV → JSON içerik üretim hattı; 538 öğelik katalog oluştur.
- [x] Tekrarlanabilir öğe/tema/zorluk içerik envanteri çıkar: [rapor](artifacts/content_coverage/README.md) ve JSON. Aktif 184 öğede 171 görsel/yerel çizim, 18 lisanslı fotoğraf, 6 efekt; 13 görsel eksik. Dosya varlığı ile dil/kalite onayını ayır.
- [x] Beş aktif tema ve 35 yapılandırılmış oyun kartını bağla.
- [ ] Beş temanın tüm Kolay/Orta/Zor içeriğini onaylı gerçek fotoğraf ve TR/EN seslerle eksiksiz yap. Mevcut 134 görselli öğe geçici AI içeriklerini de kapsar; nihai hazır sayısı değildir.
- [ ] Güncel envanterde kalan 8 eksik ve 108 hak/kalite incelemeli geçici görseli gerçek fotoğraflarla tamamla. R24:176/184 kullanılabilir görsel,31 öğede32 doğrulanmış fotoğraf; nihai insan onayı ayrı.
- [ ] Tüm TR/EN arayüz ve içerik metinlerini ARB ile yönetip editoryal kontrolü tamamla.
  - [x] ARB/gen-l10n altyapısı, eşleşen 13 TR/EN anahtarı ve `greeting(name)` karşılama/ana ekran başlıklarına bağlandı. Üretilen yerelleştirme delegeleri ve önizleme desteği eklendi; 4 yeni test geçti. intl 0.20.2 sürümü korundu.
  - [x] Aile hesabı başlığı/kartı ve giriş hata mesajlarını ARB'ye taşı:13yeniTR/ENanahtarı; önizleme, bağlantı hatası ve başarılı dönüş davranışı testli. Görünür metinler ve giriş davranışı korundu.
  - [x] Özet eşitleme kartındaki9TR/ENmetin ARB'ye taşındı; typedkayıtsayısı/tarih ve6widgettesti ile rıza/geçsonuç davranışı korundu.
  - [x] Premium ekranındaki 20 TR/EN metni ARB’ye taşı. Fiyat, dönem ve deneme metinleri tipli parametre kullanır; uzak başlık, Play fiyatları ve ebeveyn satın alma koşulları korunur. 9 hedefli test ve genel analiz geçti.
  - [x] Kaynak/lisans ekranındaki8sabit metin (başlık/hata/bölüm/değişiklik/açık kaynak düğmesi/uygulama adı) ARB'ye taşındı; kaynak/yazar/lisans kayıtları korunur. TR/ENanahtarparitesi dahil5yerelleştirmetesti geçti; diğer ekranlar ayrı kalır.
  - [x] Mola ekranının beş sabit metnini ARB’ye taşı. TR/EN görünüm, süre defteri ve yerelleştirme için 8 hedefli test geçti; genel analiz temiz. Süre sınırı ve ebeveyn uzatma davranışı korundu.
  - [ ] Diğer ekranları `state.tr` yerine ARB'ye taşı; içerik ve tüm metinlerin editoryal kontrolünü tamamla.

### Oyun ve pedagojik akış
- [x] GameTemplate / RoundSpec / RoundController / ChoiceCard / HintController ayrımını yap.
- [x] G01, G02, G04, G10, G14, G33, G34, G35, G36, G55 temel mekaniklerini bağla.
- [x] İki yanlış sonrası destek/soluklaştırma, zamanlı ipucu, öğe bazlı fading ve puansız tanıtım uygula.
- [x] Oturum değişiminde gecikmiş yanıtları iptal et; arka planda oyun ve sesi durdur.
- [x] Zorluk, aralıklı tekrar, anket odak süresi ve manuel ebeveyn zorluğunu bağla.
- [x] G33 tek tek dokunarak saymayı ve G55 puansız dokunma hareketini uygula.
- [x] Dört lisanslı gerçek hayvan efekti ve G10 sesli/sessiz korumasını uygula.
- [ ] Eksik hayvan/taşıt ses efektlerini tekil lisans ve gerçek ses kontrolüyle tamamla.
  - [x] Koyun (Eviatar Bach, CC0) ve ördek (Jonathon Jongsma, CC BY-SA 3.0) doğal kayıtlarını bağla. Kaynak, lisans, hash, tekrarlanabilir normalizasyon ve teknik ölçümler kayıtlı; önceki dört kayıt korundu. Doğal efekt sayısı 6 oldu. Tür eşleşmesi kaynak açıklamasına dayanır; insan tarafından dinleme/onay bekler.
- [x] Günlük yolu profil/yerel gün/birbirinden farklı tamamlanan oturumlarla ilerlet; yarım, tekrar ve gelecekteki oturumları dışla. Yol tamamlanınca günde bir kalıcı çıkartma ve albüm; gizli/devre dışı oyunlar dışlanır. 6 yeni test geçti.
- [x] G02 5/10/15 ve G55 4/5/6 farklı öğelik keşif oturumunu tüm kartlar açılınca açık Tamamla eylemiyle bitir; kısa havuz gerçek sayısını gösterir. Puanlı deneme üretmez; replay kartı/aktif süreyi sıfırlar. Host ve TR/EN2x Android kanıtı R18 notlarında.

### Profil, ebeveyn ve raporlar
- [x] Takma ad/avatar, atlanabilir anket ve bilinen/favori temalarda çoklu seçim.
- [x] Ücretsiz 1 / Premium 5 profil; oluştur/düzenle/sil, profil bazlı ayar izolasyonu.
- [x] Basılı tutma + matematik kapısı, PIN, unutulan PIN ve aile route koruması.
- [x] Yerel deneme/oturum/aktif/idle kayıtları ve veri kaybetmeyen şema geçişi.
- [x] Bugün/haftalık gerçek dakika, bağımsız yanıt, dikkat, beceri ve öğe raporları.
- [x] Günlük hedef dakika, tur uzunluğu, ipucu gecikmesi, soluklaştırma, azaltılmış hareket ayarları.
- [x] Günlük ekran süresi sınırı, profil/gün bazlı kalıcılık ve ebeveyn kilidiyle 10 dk uzatma. Birim/widget ve Android limit/PIN akışı geçti.
- [ ] Diğer rapor §11.2 ayarlarını mevcut uygulamayla tek tek karşılaştır; eksik ses seviyesi vb. ayarları tamamla.
  - [x] Konuşma/efekt için ayrı 0–100 profil ayarları, varsayılan100/60, ebeveyn koruması ve erişilebilir kaydırıcılar. Native oynatım öncesi kanal düzeyi, %0 sessizliği ve eski isteği iptal etme testli; G10 gerekli kanal sessizse açılmaz ve günlük yola eklenmez.
  - [ ] Müzik altyapısı (şu an müzik yok), Tam kutlama, sürükleme alternatifi/tema bazlı diğer ayarların uygulanabilir kapsamı.

### Dış entegrasyonlar
- [x] Silme koordinatörü yerel altyapısı: default-disabled, ebeveyn onayı/aynı UID/reauth ve çift çağrı koruması. Primary backend+coordinator18/18 ve scopedanalyze geçti; UI/üretim wiring/localcleanup/AppCheck/canlı silme ayrıca bekler. R19 kullanıcı APK davranışı değişmez.
- [x] Play ürün sorgusu, gerçek uygun 7 günlük teklif, geri yükleme ve iptal yolu istemcisini yaz.
- [x] Premium çevrimdışı önbelleğini 7 gün ve saat geri alma korumasıyla sınırla.
- [ ] Gerçek Play lisans hesabında satın alma/yenileme/iptal/geri yükleme testleri. Mevcut emülatör Play Billing desteklemiyor; gerçek satın alma yapma.
- [x] Firebase Android yapılandırması ve Core/Firestore SDK bağlantısını ekle.
- [x] config/app varsayılan/SQLite önbellek/validasyon, zaman sınırı, deneme aralığı ve aktif oyunda erteleme.
- [ ] Canlı Firestore erişimini doğrula: API disabled / 403; CLI yetkili oturum yok. Canlı senkron çalışıyor sayılmaz.
- [x] Opsiyonel Google aile girişi/çıkışı istemcisini ebeveyn korumalı hesap ekranına bağla. FirebaseAuth5.7.0/GoogleSignIn6.3.0; iptal/timeout/hata ve geç sonuç koruması, ortak Firebase başlatma. 3 servis + 1 route/ebeveyn/picker devamı testi geçti; yerel profiller giriş/çıkışta korunur.
- [ ] Canlı Google hesabıyla giriş/çıkışı doğrula; provider/OAuth SHA yapılandırması yetkili konsol erişimine bağlı. Fake testler canlı doğrulama değildir. Bulut yedekleme ve hesap silme tamamlanmadı.
- [ ] Veri minimizasyonlu özet senkronu, çakışma çözümü ve hesap/veri silme akışını tamamla.
  - [x] Yerel günlük özet hazırlama ve belge bazlı last-write-wins modeli: profil/kimlik tekrarı, geçersiz/gelecek kayıtlar ve tarih doğrulaması; eşit zamanlı belgelerde sıra bağımsız seçim. 4 test ve dar analyze geçti. Ham seçim/hedef/kimlik/abonelik alanları dışa aktarılmaz.
  - [x] Gelecekteki adaptör için özet payload okuyucu: fazla/eksik alan, yanlış tür, bozuk/gelecek gün, string timestamp ve yol içeren kimlik reddedilir. 5/5 özet testi geçti; dar analyze temiz. SDK timestamp→DateTime dönüşümü adaptörün sorumluluğudur.
  - [x] Açık rıza/ebeveyn/UID/profil korumalı adaptör ve Firestore transaction deposu; 200 belge sınırı, sunucu okuması, Timestamp dönüşümü, zaman aşımı/geç sonuç iptali. 6 adaptör testi +5 özet testi geçti; aşağıdaki ebeveyn UI bağlantısı eklendi; canlıya veri gönderilmedi.
  - [x] Varsayılan kapalı açık rıza ve elle eşitleme UI bağlantısı; ayrı hesap/profil bazlı, sınırlı ve doğrulanan indirilmiş özet önbelleği. İzin kaldırma, kilit, profil/hesap değişimi ve geç sonuç koruması: 6 widget +7 önbellek testi geçti. Ham kayıtları değiştirmez; tam yedek değildir.
  - [x] Profil silmede tüm hesaplara ait o profil önbelleğini temizle; uygulama sahipli hesap değişimi/çıkışında eski hesap önbelleklerini temizle. Yerel öğrenme verileri çıkışta korunur; 2 entegrasyon regresyon testi geçti; diğer hesap/profil ve ham kayıtlar korunur.
  - [x] Hesap silme sunucu taslağı: doğrulanmış UID, yakın tarihli giriş, açık onay ve App Check; kalıcı silme kilidi → recursive aile temizliği → Auth silme → kilidi tamamla. 12 yerel fake testi; callable varsayılan kapalı, deploy edilmedi.
  - [x] Sorgu kapasitesi incelemesi: 201 sonuç okunur; 200 belge sözleşmesi aşıldığında kapasite hatası verilir, sessiz kırpma yok. Mevcut sözleşmede cursor sayfalaması gereksiz; karar artifacts/reviews/summary-pagination-gap.md.
  - [x] Demo Auth/Firestore emülatörlerinde üretim silme handler backend testi: nested cleanup, ilgisiz aile, tombstone/Auth silme/tekrar; primary exit0. Sentetik .run bağlamı callable middleware/AppCheck kabulü değildir.
  - [ ] Canlı transaction/App Check ve gerçek hesap silme UI/yeniden kimlik doğrulama/doğrulama. İki cihaz etkinliği belge bazlı LWW ile seçilir; toplam birleştirme yok.
- [x] Firestore taslak kurallarını demo emülatörde test et:10/10 geçti; duyuru exactget/adminwrite/listdenial şeması da testli; kalıcı sunucu silme kilidi tüm aile yazımlarını engeller; owner/anonim/config/admin/rawtrial/Premium ve9alanlı özet doğrulaması. Kanıt `firebase/rules-tests/last-result.json`; emülatör kapatıldı, deploy yapılmadı. Profil survey/settings iç şeması hâlâ taslaktır.
- [x] config/app istemci alanlarını tamamla; canlı API/konsol doğrulaması yukarıda ayrı açık.
  - [x] `newBadge` tema kimlikleri ve yerelleştirilmiş `paywallText` başlığını doğrulama/önbellek/UI ile bağla. 4 config ve 4 görünüm/route/oturum-erteleme testi geçti. Gizli tema görünmez; fiyat/deneme koşulları Play kaynaklı kalır.
  - [x] `difficultyDefaults.fadeAfterErrors` tam sayı1–3 doğrulaması, kalıcı önbellek ve oyun başlangıcında sabitleme. Varsayılan2; ebeveyn soluklaştırma kapalı tercihi üstün. 7 yeni oyun testi ve aktif oyun config erteleme regresyonu geçti; seçenek sayıları ayrı kalan iştir.
  - [x] `announcementId` ile yalnız ebeveyn duyurularını bağla: seçiliID/ebeveynkoruması, doğrulanmışdileözgüdüzmetin, ayrıSQLitecache,6saatdenemearalığı ve10snokuma sınırı.5UI+5repository/model+6configtesti geçti; canlı erişimAPIengeline bağlı, üretimduyurusu/deployyok.
  - [x] `difficultyDefaults.choiceCounts` üçzorluk için tam sayı2–4/azalmayan sıra doğrulaması; hatalıpedagojikmap alanlarını birlikte reddet, eksikalanı koru, boşmap varsayılan2/3/4+eşik2ye döner. Controllerbaşlangıçta sabitler; hedef/tekillik/poolcap/destekazaltma korundu.4oyun+9config ve oturumertelemetestleri geçti.
- [ ] Çocuk ayarlarına uygun Analytics ve Crashlytics entegrasyonlarını tamamla/doğrula.

### Faz 1 kabul ve yayın hazırlığı
- [x] Son birim/widget doğrulaması: R3 160/160 geçti, genel analiz temiz. Fotoğraf override 3/3; önceki ses ve Firestore güvenlik kanıtları kendi tarihli kayıtlarında korunur.
- [x] Son Android kabulü: R3 kaynaklarıyla 5 genel akış, ardından düzeltilen profil hedefi 1/1 genuine offline geçti; ağ restored=true. Kanıt r3-profile-accessibility, tek 6/6 koşumu denmez.
- [x] Yeni UI sonrası normal main'i emülatörde yeniden aç ve screenshot ile doğrula (`artifacts/screenshots/latest-main.png`).
- [ ] Uçak modu, erişilebilirlik, performans ve tüm oyun durumları kabul kontrolünü tamamla.
  - [x] KarşılamaTR/EN800×360/1280×800ve%100/%160/%200yazıda başlamaCTA görünür/dokunulabilir/enaz64px. Büyük yazıda CTA kaybolması giderildi; yalnızbilgisatırları kayar. GerçekNunito/MaterialIconsfontlarıyla regresyon+welcomeQA geçti.
  - [x] Pixel_9a uçakmodu/ağyok durumunda3yerelAndroidakışı geçti (limit/PIN, native ses/mute, onboarding/oyun/aile/profil/English). Emülatörradyoları sonunda aynı0/1/1değerlerine döndü; kanıt `artifacts/compliance/android-offline-qa.json`. Canlıağservisleri/gerçekcihazların tümü test edildi denmez.
  - [ ] Diğer ekranlarda büyük yazı/TalkBack/dokunmahedefleri ve performans kabulü.
- [x] Release birleşik manifestini üret ve izinleri denetle: applicationId korundu, versionCode14, game/sensorLandscape; AD_ID ve AdServices izinleri yok. Kanıt `artifacts/compliance/release_manifest_audit.json`; Gradle processReleaseMainManifest başarılı, imzalama/yayın yapılmadı.
- [x] Release çalışma bağımlılık ağacını çıkar: `artifacts/compliance/release-runtime-dependencies.txt`; bilinen reklam SDK adları ve firebase-analytics eşleşmedi. Bu, AAB/Dex sınıf denetiminin yerine geçmez.
- [ ] Nihai release AAB/Dex ve üretim imzası denetimini tamamla; manifest kontrolü tek başına bu kabul değildir.
  - [x] Mevcut debug APK içindeki16DEX/21035tanımlı sınıfı bilinen reklam SDK önekleriyle denetle:eşleşme yok. Tekrarlanabilir araç ve APK/DEXSHA256 kanıtı `artifacts/compliance/debug-apk-dex-audit.json`. Bu, nihai AAB/obfuscation/native/Dart taraması veya üretim imzası doğrulaması değildir.
- [x] TR/EN gizlilik, mağaza açıklaması ve hesap silme iç taslaklarını hazırla; docs/ ve artifacts/reviews/privacy-draft-evidence.md.
- [ ] İşletmeci/iletişim/URL/saklama bilgileri, hukuk kontrolü, mağaza görselleri ve Families/Data safety beyanlarını tamamla. Taslaklar yayımlanmadı.
- [ ] Öğretmen/aile kapalı kullanıcı testi (dış katılımcı gerektirir).
- [ ] Faz 1 kabul kriterlerinin tamamını doğrula. Mağaza yayını bu çalışmanın kapsamında değildir.

## Sonraki fazlar — Faz 1 sonrası sırayla

- [ ] Faz 2: içerik paketleri; sürükle-bırak ve dokun-dokun alternatifi; drag_to_target/sort/match_pair/odd_one_out/audio_choice/fill_count; rapordaki +14 oyun; Şekiller ve Yiyecek-İçecekler. Beceri/öğe raporlarının mevcut kısmını yeniden yazma, yeni oyunlara genişlet.
- [ ] Faz 3: web yönetim paneli; partial_reveal/missing_item/shape_sorter/build_face hazırlığı; +15 oyun; Kıyafetler/Evimiz/Okul/Vücudumuz/Duygular/Meslekler; Sakin Köşe ve Play Asset Delivery.
- [ ] Faz 4: puzzle/order/memory/simon/trace/coloring; rapordaki oyunlar; Doğa-Mevsimler/Müzik Aletleri; PDF rapor ve opsiyonel lifetime değerlendirmesi.
- [ ] Faz 5: rakam yazma, noktalar, sosyal hikâye, güvenlik, harfler, AAC, öğretmen/sınıf modu, ek diller ve iOS.

## Güncelleme kaydı

- 16 Ekim: Kontrol listesi üç şartname ve gerçek geliştirme günlüğüyle eşleştirildi. Geçmişteki AI üretimi, eski Lauren ses tercihi, 08:00 bitişi ve dikey ekran hedefi güncel talimat sayılmaz. Yeni UI ve otomatik dil işleri alt ajanlara sınırları belirlenerek verildi; tamamlandıkları doğrulanmadan işaretlenmeyecek.
- 16 Ekim devamı: Yatay/otomatik dil, modern UI, kontur ve iki ses örnek seti tamamlandı. 41 birim/widget testi ve analyze temiz; UI QA geçti. Android tekrarı sürüyor; önceki tekrarın tek hatası yeni otomatik İngilizce fixture karşısında eski Türkçe test beklentisiydi, fixture açık TR olarak düzeltildi. Üretim Firestore/Google/Play eksikleri hâlâ açık.
- Son doğrulama: Android 3/3 geçti; kontur/UI sonrası 41/41 birim/widget ve UI QA tekrarı geçti. Normal main emülatörde açıldı, gerçek ekran screenshot ile doğrulandı ve uygulama açık bırakıldı. Canlı Firestore disabled403 ve Billing desteklemeyen cihaz sınırları değişmedi.
- 16 Ekim 07:02 devamı: İki lisanslı fotoğraf uygulamaya alındı; gerçek günlük yol/sticker, Google hesap istemcisi ve yatay karşılama ekranı tamamlandı. Son 51 birim/widget, 2 fotoğraf pipeline, 6 günlük yol testinin dahil olduğu süit, Android3/3 ve ayrı welcome/home/path/tema QA geçti. Native SDK'larla tam derleme yapıldı, normal app screenshot incelendi. Canlı Google giriş/Firestore senkron ve tüm fotoğraf/ses kataloğu hâlâ eksik.
- 16 Ekim 11:27: Altı doğrulanmış gerçek fotoğraf ve 14 seçilmiş TR/EN kelime kaydı kataloğa bağlandı; ses kanalı ayarları, ARB temeli ve senkron adaptörü eklendi. 71 birim/widget, 4 Python ve 8 yerel Firestore güvenlik testi geçti; Android 3/3 ve normal main screenshot doğrulandı. Canlı bulut bağlantısı, rıza ekranı, silme ve tüm içerik henüz tamamlanmadı.


## Planlanan çalışma sonu — 16 Ekim 20:02 İstanbul
- [x] 20:00 bitişinden sonraki ilk kontrolde geliştirme otomasyonunu PAUSED yap; tamamlanan işleri ve kalanları DEVELOPMENT_STATUS.md içine kaydet. Uygulamanın tüm kapsamı tamamlanmış değildir; dikey kaydırmasız yatay UI ilk sıradadır.

## InferX yardımcı model bağlantısı
- [x] Kullanıcının ekranındaki endpoint/model için açık çağrılı PowerShell istemcisi ve kullanıcıya bağlı Windows DPAPI token kaydı hazırlandı; iki betik sözdizimi kontrolünden geçti. Otomatik dosya okuma, kod yürütme veya API retry yok.
- [x] Token kaydından sonra tek küçük canlı istekte INFERX_CONNECTION_OK yanıtı birebir doğrulandı (max_tokens 64). Endpoint erişimi çalışıyor; kod üretim kalitesi ve araç kullanımı ayrıca değerlendirilir. Uygulama kodu gönderilmedi veya değiştirilmedi.


- [x] InferX ajan altyapısını kur: proje metni okuma/listeleme/arama, açık kapsamlı hash kontrollü yazma, ilk sürüm yedeği ve işlem kaydı; isteğe bağlı Flutter analiz/hedefli test. Keyfi shell ve proje dışı dosya erişimi aracı yok.
- [x] Yerel 8 test geçti; Windows symlink oluşturma yetkisi olmadığından 1 test atlandı. PowerShell parser kontrolü geçti. Canlı model geçici dosyayı okuyup değiştirdi, yedekledi ve Flutter analizini exit 0 ile çalıştırdı; sonuç ayrıca Codex tarafından incelendi. Test dosyası kanıt dizinine alınıp kaldırıldı. Kapsam denetimi OS sandbox değildir; kullanım tools/INFERX_AGENT.md içinde.



- [ ] InferX servis engeli: uygulama worker çağrısı yanıt hatası, sonraki dar belge çağrısı HTTP500, tek kompakt planlama çağrısı kullanılabilir yanıt vermedi. İlk kuyruk taslağı inceleme notlu/kabul edilmemiştir. Servis yeniden kullanılabilir olduğunda aynı modelle önce bu geri bildirimi, ardından karşılama UI görevini tamamla; sessiz model ikamesi yapma.

- [x] DeepSeek'e dikey kaydırmayı yakalayan karşılama regresyon testi yazdır; mevcut iki dikey alan nedeniyle beklenen RED sonuç doğrulandı. Bu madde UI düzeltildi demek değildir; testin yeşile dönmesi ilk UI işinin kabul koşuludur.


### Son yönetici incelemesi — DeepSeek ile karşılama
- [x] Gerçek ileri/geri gezinme, tüm bilgilerin görünür/dokunulabilir ekran sınırları, dikey kaydırma reddi ve başlangıç callback'i için 12 kombinasyonlu test matrisi geçti. Azaltılmış hareket tercihi kaynakta korunur; bu dal için ayrı yeni test yazılmadı.
- [x] APK derlendi, Pixel_9a yeniden açıldı; normal ana ekran screenshot ile incelendi. Resident run ayrıldıktan sonra uygulama PID3963 ile açık doğrulandı.
- [ ] Normal boyutta tüm bilgileri tek sayfada, yalnız büyük yazılı kısa ekranda yatay sayfalama ile gösteren görsel iyileştirmeyi tamamla. DeepSeek taslağı renk token'i hatası/test uyarlaması eksikleri taşıdı; düzeltme çağrıları HTTP500 verdi. Taslak artifacts/inferx/welcome-overview-unaccepted.dart.txt içinde korunup kaynak son doğrulanmış sürüme geri alındı. Genel kaydırmasız arayüz işi, diğer ekranlarda hâlâ bekliyor.
- [ ] InferX aralıklı HTTP500 sürüyor. Thinking disabled + JSON mode ile bazı yazma/inceleme döngüleri çalıştı; kalıcı servis iyileşmesi kanıtlanmadı. Yeni büyük iş başlamadan küçük, tek dosyalık görevler kullan; model seçimini sessizce değiştirme.

## Sağlayıcı değişikliği — resmî DeepSeek API
- [x] Kullanıcı isteğiyle aktif çalışanı resmî DeepSeek API / deepseek-flash / run_deepseek_agent.ps1 olarak değiştir; ayrı DPAPI anahtar girişi kur. InferX'e otomatik geri dönüş yok. Yerel12test geçti/1Windows symlink testi atlandı; iki PowerShell betiğinin parser kontrolü geçti.
- [x] Resmî DeepSeek anahtarıyla tek küçük canlı istek, tam DEEPSEEK_CONNECTION_OK yanıtı ve resmî endpoint kontrolü geçti. Uygulama kodu gönderilmedi/değiştirilmedi; çok adımlı dosya/araç görevi sonraki uygulama işinde ayrıca doğrulanacak.


- [x] Kullanıcının token tüketimi geri bildirimiyle orkestrasyonu kısaltma kurallarını AGENTS.md içine kaydet; büyük tekrar dökümleri ve uzayan tanı turlarını sınırla.
- [ ] Resmî DeepSeek aktarım engeli: anahtar ve bazı okuma/yazma istekleri çalıştı, fakat ConnectionResetError/IncompleteRead ve native curl exit35/HTTP000 görüldü. Son düzeltme işi tamamlanmadı; taslaklar korunup iki uygulama/test kaynağı önceki geçen sürüme geri alındı. Normal tek sayfa karşılama işi kabul edilmedi.

- [x] Son kesintisiz devam talimatıyla mevcut30dakikalık geliştirme otomasyonunu ACTIVE yap; eski20:00kesimini kaldır, resmî DeepSeek ve kısa orkestrasyon/tek görev/doğrulama sınırlarını koru. Bağlantı hatasında aynı turda döngü kurma; sonraki kontrolde değerlendir. UI öncelikleri henüz tamamlanmadı.

- [x] Çağrı altyapısını karşılaştırmalı incele: yeni bağlantılı curl9/10, tek bağlantılı SDK10/10; gerçek okuma/düzenleme/doğrulama ajan döngüsü geçti. Aktif resmî wrapper tek SDK istemcisine taşındı; otomatik retry/redirect kapalı, sertifika doğrulaması açık. Yerel15test geçti/1symlink atlandı. Rapor artifacts/deepseek/connection_diagnostics/README.md. Gelecekte hiç ağ hatası olmayacağı garanti edilmez; eski doğrudan curl/urllib engel notları tarihsel, yeni görevler SDK ile yürütülür.

- [x] 16 Ekim gece devamı: otomasyon 17 Ekim 08:00 İstanbul'a kadar ACTIVE; başarısız taslaklar korunup çalışan welcome kaynaklarına geri dönüldü, hedefli erişilebilirlik testi geçti.
- [ ] Normal tek sayfa welcome: son taslak çift CTA/sabit64footer/dynamic l10n nedeniyle kabul edilmedi. artifacts/deepseek/welcome-review-fix.txt geri bildirimi uygulanıp test/analiz/görsel QA ile doğrulanacak. Son resmi SDK isteği APITimeoutError; sonraki periyotta devam, sınırsız retry yok.

- [ ] 23:19 heartbeat: welcome düzeltmesi b98a15ce9c2a436fb4a7986528c25a10 boş model eylemiyle durdu; yeni UI kabul edilmedi. Çalışan iki dosyanın geri alma hashleri doğrulandı; aynı tur yeniden çağrı yok.

- [x] 23:51: Normal yatay karşılama tek sayfa, kısa+büyük yazıda yatay sayfalama uygulandı ve bağımsız analiz/hedefli12kombinasyon+4render QA geçti; TR800 screenshot incelendi. Önceki kabul edilmemiş welcome kayıtları bu kabul ile aşıldı.
- [ ] Yeni welcome Android APK/emülatör doğrulaması; diğer ekranlarda dikey kaydırmasız düzenleme devam ediyor.

- [ ] Ebeveyn kapısı kaydırmasız yatay düzen:00:22 görevi adım/çıktı sınırında tamamlanmadı; uygulama kaynağı değişmedi. Test taslağı korunmuş, fixture sorunları var; artifacts/deepseek/parent-gate-review.txt sonraki dar kaynak görevi.

- [ ] 00:51 ebeveyn kapısı taslağı: gerçek16px taşma nedeniyle kabul edilmedi, kaynak hash kontrollü geri alındı. Tuş alanı padding sonrası ölçülecek; test locale/platform fixture ayrıca onarılacak. Kanıt DEVELOPMENT_STATUS sonkaydı.

- [ ] 01:22 parentgate: keypad taşma taslağı onarıldı ancak testfixture locale/platform sorunları sürdüğü için kabul edilmedi; taslaklar korunup çalışan kaynak geri alındı. Sonraki görev somut fixturegeri bildirimiyle devam.

- [ ] 01:51 parentgate: taze locale/PIN testmatrisi taslakta; 32pxbuton ve testplatformcleanup sorunları nedeniyle kabul edilmedi. Sonraki küçük geri bildirim parent-gate-fixture-task.txt sonundadır.

- [ ] 02:22 parentgate:3x4keypad ve kısmi testcleanup taslakta; buttonvisualDensity40px ve kalan3testhelper kapsamı onarılacak. 1geçti/4başarısız, kabul/Android doğrulaması yok.

- [ ] 03:21 parentgate:24caseTR/ENmath/PINmatrisi>=48/noverticalscroll geçti; toplam4/5test, tekPINsuccesstimerfixturecleanup kaldı. parent-gate-last-timer.txt daronarımla sonraki tur; henüzkabul/Androidkanıtı yok.

- [x] 03:51 ebeveyn kapısı yatay kaydırmasız yerleşim uygulandı;24case/min48/authkaynakprefix doğrulandı. Bağımsızanaliz ve ilgili7test geçti.
- [ ] PINtestfixture başlangıcını kilitle; successöncesikilit/yanlışPINreddi ekle. ŞuankigeçenPINtesti başlangıçunlock nedeniyle tamkanıtdeğil. YeniAPK/emülatör/görselQA ve DBfixturetemizliği bekler.

- [x] 04:21 PINfixture kilitlibaşlangıç/yanlışPINreddi/doğruPINunlock ve fallbackkanıtı: bağımsız5/5test geçti; üretimauthdeğişmedi.
- [ ] Yeniwelcome/parentgateAPK-emülatör/görselQA; diğer yatay ekranların düzeni. DBfixturecasebitimi kapatma temizliği ayrıbekler.

- [x] 04:52 YeniAPK build/install/main açılışı ve parentgate normalAndroidmathgörünümü/cancel geri dönüşü doğrulandı; screenshotlar incelendi. App açık; id/version14 korundu.
- [ ] Welcome cihazda ilkakış ve parentgatePIN/büyükyazıAndroidQA ayrıbekler; sıradaki kaynak işi onboardingprofil dikeykaydırmasını kaldırma.

- [ ] 05:21 profilpage1: worker eşleşmeyenreplace/JSON/yolhataları nedeniyle kod/test değiştirmedi. Kaydırma sorunu açık; source-only küçük görevle devam edilecek.

- [ ] 05:51 profiltaslağı yeniSingleChildScrollView içerdiği için reddedildi; kaynak hashkontrollü geri alındı. SDKbağlantıhatasından sonra bu tur tekrar yok; sonraki dar görev noverticalscroll ve keyboardavatarfit.

- [ ] 06:21 profil boundedRow/Wrap taslakta fakat kısaekrandabaşlık/açıklamagizleme nedeniyle kabuldeğil; kaynak geri alındı. Sonraki testli görev profile-test-next.txt.

- [x] 06:30 Limit kuralı düzeltildi: yalnız5saatkalan<8% veya haftalıkkalan<2%; haftalık7%ileçalışmayaizin. AGENTS ve ACTIVEotomasyon güncel.
- [ ] Profil işi06:30 DeepSeekboşeylemi nedeniyle hâlâ açık; çalışan kaynakgeri alındı, sonraki kontrol eşikleri ayrıdeğerlendirir.

- [x] Kullanıcı istediği5kısaDeepSeekmesajı sınandı:5/5HTTP200,0.765–1.109s. JSONmodeboşeylem resmi belgede bilinenolay; uzunagentstabilitesi hâlâdoğrulanmışdeğil.

- [x] Profil gerçekfont/locale/boyut/yazı/klavye regresyontesttaslağı yazıldı; fixtureyalıtıldı, klavye120inset testi geçti.
- [ ] Profil normalTR800x360x1.6da7px taşma kaldı; diğer tümcasegeçmedenUIkabul edilmez. Günceltaslak/geribildirim profile-overflow-task.txt ile korunur.

- [x] DeepSeek JSONmodevarsayılanı kapatıldı, JSONistem/parserkorunur;6karşılaştırmalıistek+gerçekwrapperdryrun geçti. Uzunuygulamagörevistabilitesi ayrıizlenecek; kopmalar tamamençözüldüdenmez.

- [ ] JSONmodekapalı yenidenprofilgörevi67f26154 ilkistekteAPIConnectionErrorHTTPyok; yeniuygulamadeğişikliğiyok. Kaynakhashkontrollügerialındı,7pxprofiltaşmataslağıkorundu.

- [x] Kullanıcı tercihiyle nativeGPT-6Lunaaltajanına geçildi; DeepSeek/InferXaktifçağrıları devredışı, AGENTS/otomasyon güncel.
- [ ] Luna profilkaydırmasızUI/7pxtaşma düzeltmesi ve testleri sürüyor; doğrulanmadan tamamlandı sayılmaz.

- [x] Luna profilpage1 kaydırmasız UI ve7pxtaşma düzeltmesi kabul edildi; normal12case/keyboard6case, çalışananaliztemiz, bağımsızilgili8/8test geçti.
- [ ] ProfilAndroid/görselQA; onboarding survey/final ve diğer dikeykaydırmalıekranlar, yanlışdilses/G10 ve dışbağımlılıklar devameder.

- [ ] Luna onboardinganketsoru sayfalarını dikeykaydırmasız yapıyor; seçenekler büyük yazıda yatay gezinmeyle erişilebilir olacak. Sonuç/test gelmeden kabul edilmez; finalsayfa ayrıiş.

- [x] Luna anket: tüm soru/seçenekler yatayda kaydırmasızdikey erişilebilir; single/multi/skip/emptyContinue/progress doğrulandı. Bağımsızilgili10/10test ve çalışananaliztemiz.
- [ ] Finalönerionboarding sayfasını dikeykaydırmasız yap; yeniprofil/anketAndroidQA. SurveyOptions reduced-motion ve tümseçenektap48bounds için ekkanıt bekler.

- [ ] 07:33 Luna finalönerisayfası/test dar görevi sürüyor; eskiSingleChildScrollView kaldırılacak, tamamlanmahenüzdoğrulanmadı.

- [x] Luna son öneri ekranını dikey kaydırmasız tamamladı. Uzun24karakterad,TR/ENboyut/yazımatrisi, öneriseviyeleri ve çifttıklamada tekkayıt doğrulandı; bağımsız ilgili13/13test geçti, çalışananaliztemiz.
- [ ] Yeni onboarding tamamı Android/görsel QA; SurveyOptions azaltılmışhareket/tapbounds ve diğerUI/içerik/dışservis işleri açık.

- [x] 17 Ekim08:03:08:00İstanbul planlanan bitişi nedeniyle gece geliştirme otomasyonu PAUSED yapıldı; ilerleme/eksikler kaydedildi. Uygulamanın tüm kapsamı bitmedi.
- [ ] Sonraki çalışma: yeni onboarding Android/görsel QA, diğer kaydırmasız ekranlar, azaltılmış hareket/tapbounds, yanlışdilses/G10 ve içerik/canlıservis eksikleri.










































