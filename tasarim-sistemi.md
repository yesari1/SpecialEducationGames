# Özel Eğitim Oyunları: Tasarım Sistemi ve Stil Rehberi

> 16 Ekim kullanıcı güncellemesi: uygulama yalnızca yataydır. Zemin beyaz/çok hafif krem; palet canlı turuncu, mavi/açık mavi ve turkuaz; butonlar yumuşak yuvarlak ve beyaz kenarlıklı, kart metinleri düzgün hizalı olmalıdır. Gerçek fotoğraf PNG'lerinde beyaz özne konturu kullanılır. Eski palet ve dikey ekran hedefleri bu kararlara göre güncellenir. Uygulama durumu: [TODO.md](TODO.md).

> Ana rapor: [ozel-egitim-oyunlari-flutter-raporu.md](ozel-egitim-oyunlari-flutter-raporu.md)
> Bu dosya uygulamanın **her ekranında** kullanılacak görsel dili tanımlar. Agent hiçbir ekranda bu dosyadaki tokenların dışında renk, yazı boyutu, köşe yarıçapı, gölge veya animasyon süresi kullanmamalıdır. Yeni bir bileşen gerekiyorsa önce buraya eklenir, sonra kodlanır.

---

## 1. Tasarım Kişiliği

**Üç kelime:** Sakin · Sıcak · Net

| Biz böyleyiz | Böyle değiliz |
|---|---|
| Yumuşak pastel zeminler, bol boşluk | Neon renkler, kalabalık ekran |
| Büyük, dokunması kolay, "basılabilir" görünen kartlar | Küçük ikonlar, ince çizgiler |
| Tek odak: ekranda bir görev | Aynı anda birden çok hareketli şey |
| Sıcak, sakin bir ses ve kısa övgü | Bağıran efektler, uzun konfeti yağmuru |
| Tutarlı: her ekranda aynı yerleşim | Her oyunda farklı düzen |
| Modern, düz (flat) ama dokunsal (yumuşak gölge + alt kenar) | Eski tip parlak/gradyanlı "oyun" arayüzü |

### 1.1 Otsimo ekran analizi (33 ekran görüntüsü)

Kaynak: ürün sahibinin Nisan 2026'da Otsimo Android uygulamasından aldığı 33 ekran görüntüsü (`D:\GameDesktop\ÖzelEğitimOyunları\OtsimoSS`): 2 Aile ekranı (dikey), 1 çocuk ana ekranı ve 30 kategori/oyun listesi ekranı (yatay). Oyun içi ekran görüntüsü yok.

**Gözlenen yapı**

| Ekran | Gözlem |
|---|---|
| Çocuk ana ekranı (yatay) | Açık mavi gökyüzü zemini, hafif bulutlar. Üst bar: solda gri hap şeklinde "👤 Aile" butonu; ortada iki parçalı geçiş (🎮 Oyunlar / 〰 Öğrenme yolu); sağda günlük ilerleme "0/6 😊". Altında **ekrana 3 tane sığan dev kategori kartı**: kalın renkli çerçeve (mavi, mor…), içinde beyaz yuvarlak pencere ve düz vektör illüstrasyon, altta beyaz kalın başlık ("Günlük Hayat") ve küçük sayaç ("13 Oyun", "10 Kitap"). Yatay kaydırma. |
| Kategori ekranı (yatay) | Her kategorinin kendi rengi ve **temalı zemini** var: Günlük Hayat = oda duvar kağıdı + pencere + saat (mavi/pembe), Yapbozlar = yapboz parçası deseni (yeşil/turuncu), Müzik = nota çizgileri (lila), Harfler = kâğıt ve kalemler (pembe), Sayılar = rakamlar (mor), Doğa/Hayvanlar = tepe ve bulut manzarası (turuncu). Sol üstte kategori renginde daire geri butonu (beyaz ok, beyaz kontur). **Ekranda 3 büyük oyun kartı**, yatay kaydırma. |
| Oyun kartı | Kategori renginde kalın çerçeve (~12 dp), beyaz iç pencere (~%70), içinde tek düz illüstrasyon ve arkasında pastel "blob" leke. Alt şeritte solda beyaz daire içinde **durum ikonu** (▶ oynat = açık, turuncu yüzlü asma kilit = kilitli), yanında beyaz kalın oyun adı (2 satıra kadar). |
| Oyun adlandırma | Tutarlı fiil kalıbı: **"… Öğren"** (tanıtım), **"… Göster"** (dinle-bul), **"… Eşleştir"** (eşleştirme), **"… Hafıza Kartları"**, **"… Yapbozu"**, "… Çal" (müzik). Aynı içerik bu fiillerle 3–4 oyuna çoğaltılmış (ör. Yatak Odası Eşyalarını Öğren / Eşleştir / Göster). |
| Hikayeler | Kitap kapağı kartları (illüstrasyon + başlık), altta turuncu "♥ Premium" şeridi. Sosyal hikaye başlıkları: sırayı beklemek, paylaşmak, el yıkama/diş fırçalama, yemekhanede sıra, konuşmak için el kaldırmak. |
| Aile ekranı (dikey) | Beyaz zemin, büyük siyah "Özet" başlığı, sağ üstte mavi hap "😊 Çocuk" (çocuk moduna geçiş). Haftalık gün şeridi (Cu…Pe), "🔥 0 gün üst üste" seri sayacı ve "Seriyi korumak için çocuğunuzun her gün oynaması gerektiğini unutmayın" metni. Gri yuvarlak rapor kartları ("Bugün, 0 puan toplandı"), mavi "Detaylı Görüntüle" butonu, "0/30 dakika oynandı" günlük hedef halkası ve "Hedef Seç". Alt sekme çubuğu: Özet · Oyunlar · Eğitim · Ayarlar. |
| Satın alma baskısı | Aile özetinde kırmızı-pembe tam genişlik bant: "Size özel teklifler. Bir indirim ile Premium alın! Kalan süre 28:01:53:41" (geri sayım). Ücretsiz kullanıcıda oyun kartlarının neredeyse tamamı kilitli. |

**Otsimo'dan alıyoruz (doğrudan)**

| Otsimo deseni | Bizdeki karşılığı |
|---|---|
| Ekrana 3 tane sığan dev kartlar, yatay kaydırma | `ThemeCard` ve `GameCard` telefonda 3, tablette 4 kart görünür (bkz. 8.2). Izgara yerine **tek sıra yatay kaydırma**. |
| Kalın renkli çerçeve + beyaz iç pencere + illüstrasyon + alt şeritte ad | Aynı kart anatomisi, çerçeve tema `accent` renginde, alt kenarda `deep` tonlu basılma derinliği. |
| Kart altında durum dairesi (▶ / 🔒) | `GameCard` alt şeridinde 40 dp beyaz daire: ▶ (oynanabilir), 🔒 (Premium), ✓ (bugün oynandı). |
| Kategori sayacı ("13 Oyun") | `ThemeCard` altında "13 oyun" sayacı. |
| Fiil kalıbıyla oyun adları | Oyun adlarında aynı kalıp: "Hayvanları Öğren", "Hayvanları Bul", "Hayvanları Eşleştir", "Hayvan Yapbozu" (ana rapor Bölüm 6.5). |
| Ana ekran üst barı: Aile · Oyunlar/Yol geçişi · günlük ilerleme | `ChildTopBar`: sol "Aile" (basılı tut + kilit), orta 🎮/〰 geçişi, sağ günlük ilerleme (yıldız sayacı). |
| Kategori renginde daire geri butonu | `SegIconButton.back` tema `accent` dolgulu, beyaz ok, 4 dp beyaz kontur. |
| Aile Modu: alt sekme çubuğu, hedef halkası, gün şeridi, "Çocuk" geçiş hapı | `FamilyBottomNav` (Gelişim · Oyunlar · Profiller · Ayarlar), `GoalRing`, `WeekStrip`, sağ üstte "Çocuk Modu" hapı. |
| Sosyal hikaye kitap kartları | `StoryCard` (Faz 5). |

**Otsimo'dan farklılaşıyoruz (modernleştirme ve özel eğitime uygunluk)**

| Otsimo'da | Bizde | Neden |
|---|---|---|
| Çok doygun saf renkler (parlak camgöbeği, mor, yeşil) yan yana | Aynı canlılık hissi ama bir ton yumuşatılmış tema renkleri (2.2); bir ekranda yalnızca **bir** tema rengi | Aşırı uyaranı azaltmak, daha modern ve "premium" görünüm |
| Kategori ekranlarında desenli, dağınık zeminler (uçuşan kâğıtlar, yıldızlar, yapboz parçaları) | Tema zemini düz pastel; en fazla tek, büyük, %4 kontrastlı silik motif (ör. tek bir yaprak), **oyun ekranlarında hiç** | Dikkat dağıtmamak |
| Cartoon insan figürlü yoğun illüstrasyonlar | Kart illüstrasyonları tek nesne ağırlıklı, sade; oyun içinde gerçek fotoğraf (sticker kesim) | Odak ve gerçek hayata genelleme |
| Ücretsiz kullanıcıda kartların çoğu kilitli, turuncu kilit baskın | Ücretsiz içerik bölümler bazında gerçekten oynanabilir; kilit ikonu küçük ve nötr (`inkFaint`); ebeveyn "yalnızca açık olanları göster" diyebilir | Çocuğun hayal kırıklığı yaşamaması, inceleme eleştirisi |
| Geri sayımlı "Size özel teklif" bandı | **Yok.** Teklifler yalnızca Paywall ekranında, süre baskısı olmadan | Play Families "duygusal manipülasyon" kuralı ve güven |
| "Seriyi korumak için her gün oynaması gerektiğini unutmayın" | Seri (streak) kaybı yok; haftalık nazik hedef ("Bu hafta 4 gün oynadınız") | Aileye suçluluk yüklememek |
| Aile ekranında gri, yazı ağırlıklı kartlar | Grafikli `StatTile`/`ChartCard`, beceri alanı çubukları | Daha anlamlı rapor |
| Çocuk yatay, aile dikey (yön değişimi) | Aynı; ama iki mod da her iki yönü destekler, geçişte yön zorlanmaz | Tablet kullanımında rahatlık |

**Telif notu:** Otsimo'nun illüstrasyonları, simgeleri ve oyun adlarının birebir kopyası kullanılmaz. Alınan şey yerleşim ve etkileşim desenleridir. Genel ifadeler ("Renkleri Öğren") serbesttir.

---

## 2. Renk Sistemi

### 2.1 Temel tokenlar

| Token | HEX | Kullanım |
|---|---|---|
| `canvas` | `#F7F5F0` | Varsayılan zemin (krem) |
| `surface` | `#FFFFFF` | Kartlar, diyaloglar |
| `surfaceMuted` | `#F0EDE6` | Pasif alanlar, boş yuvalar (drop zone) |
| `line` | `#E4DFD6` | Ayırıcı, kart kenarı |
| `ink` | `#2F3A45` | Ana yazı ve ikon |
| `inkSoft` | `#5F6C78` | İkincil yazı |
| `inkFaint` | `#9AA4AE` | Pasif yazı, devre dışı |
| `primary` | `#4A9C8C` | Marka rengi (adaçayı-turkuaz): ana buton, seçili sekme |
| `primaryDeep` | `#33796B` | Ana butonun alt kenarı, basılı hali |
| `primarySoft` | `#DCEFEA` | Seçili arka plan, rozet |
| `accent` | `#F2A65A` | Sıcak vurgu (şeftali): "Bugünün Yolu", yeni rozet |
| `accentDeep` | `#D9853A` | Accent butonun alt kenarı |
| `star` | `#F5C451` | Yıldızlar, ödül |
| `starDeep` | `#D9A52E` | Yıldız gölgesi |
| `hintGlow` | `#FFE7A3` | İpucu vurgusu (doğru kartın etrafındaki yumuşak hale) |
| `successGlow` | `#BFE6D6` | Doğru cevap sonrası kartın hale rengi |
| `shadow` | `#2F3A45` @ %8–12 | Gölgeler |
| `scrim` | `#2F3A45` @ %40 | Diyalog arkası |

**Kurallar**
- **Kırmızı yok** (hata rengi kullanılmaz; hatasız öğretim). Uyarı gereken tek yer Aile Modu'dur ve orada da `accentDeep` kullanılır.
- Doğru/yanlış asla yalnızca renkle anlatılmaz (hareket + ses + ikon).
- Yazı her zaman `ink` veya `inkSoft`; renkli zemin üzerine renkli yazı yok.
- Kontrast: `ink` / `canvas` ≈ 11:1; `inkSoft` / `surface` ≥ 5:1. Yeni renk eklenirse WCAG AA (4.5:1) kontrolü zorunlu.

### 2.2 Tema renkleri

Her tema bir **zemin** (oyun ekranı arka planı, çok açık) ve bir **vurgu** (tema kartı, tema ekranı başlığı, ilerleme) rengine sahiptir. Vurgu renginin koyusu (`deep`) butonların alt kenarında kullanılır.

| Tema | `bg` | `accent` | `deep` |
|---|---|---|---|
| Hayvanlar | `#EAF4EC` | `#6BAA75` | `#4F8A59` |
| Meyve ve Sebzeler | `#FDEEE7` | `#E98A6B` | `#C96B4E` |
| Yiyecekler | `#FFF3E0` | `#E8A24D` | `#C88333` |
| Renkler | `#F3EEF8` | `#9C7BC0` | `#7D5EA3` |
| Şekiller | `#EAF1FA` | `#5B8FD1` | `#4071B3` |
| Sayılar | `#FFF8DC` | `#D9A92B` | `#B88A14` |
| Taşıtlar | `#E8F1F7` | `#4E89B5` | `#356D97` |
| Kıyafetler | `#FBEFF3` | `#D07A98` | `#B25C7B` |
| Evimiz | `#F4EFE8` | `#A9805B` | `#8B6441` |
| Okul ve Oyuncaklar | `#EAF6F6` | `#46A3A3` | `#2F8585` |
| Vücudumuz | `#FDF1EA` | `#DB8D6A` | `#BC6F4D` |
| Duygular | `#FFF6E0` | `#E3B23C` | `#C29322` |
| Meslekler | `#EEF0F8` | `#6A78C2` | `#4F5DA6` |
| Doğa ve Mevsimler | `#EDF6F0` | `#5FA27A` | `#45845F` |
| Müzik Aletleri | `#F6EDF6` | `#B572B0` | `#965593` |
| Harfler | `#F1F4F8` | `#5F7896` | `#465E7A` |
| Para ve Zaman | `#F1F6EA` | `#7FA45A` | `#62863F` |
| Hikayeler | `#FFF1E6` | `#EE9A5C` | `#CF7B3F` |

Tema renkleri **yalnızca** zemin, tema kartı, başlık şeridi ve ilerleme çubuğunda kullanılır. Seçenek kartları her temada beyazdır (`surface`), böylece içerik resmi her zaman aynı nötr çerçevede görünür.

### 2.3 Aile Modu paleti

Aile Modu çocuk alanından görsel olarak ayrışmalı ama aynı aileden olmalı:
- Zemin `#F5F6F8` (soğuk açık gri), kartlar `surface`, başlık ve butonlar `primary`.
- Grafik serileri: `primary` (#4A9C8C) ve `accent` (#F2A65A). En fazla 2 seri. Eksen ve ızgara `line`.

---

## 3. Tipografi

**Yazı tipi:** **Nunito** (Google Fonts, açık lisans, Türkçe karakter desteği tam, yuvarlak uçlu, okunaklı). Rakamlar için de Nunito. Unity'de kullanılan Archivo, yalnızca logo/mağaza görsellerinde kalabilir.

| Token | Boyut / Satır | Ağırlık | Kullanım |
|---|---|---|---|
| `display` | 40 / 48 | 800 | Tur sonu "Aferin!", karşılama başlığı |
| `title` | 30 / 38 | 800 | Oyun yönergesi (yazı açıksa), ekran başlığı |
| `heading` | 24 / 32 | 700 | Tema ekranı başlığı, kart başlıkları |
| `itemLabel` | 22 / 28 | 800 | Seçenek kartı altındaki öğe adı |
| `body` | 18 / 26 | 600 | Aile Modu metinleri |
| `label` | 16 / 20 | 700 | Buton yazısı, sekme |
| `caption` | 14 / 20 | 600 | Yardımcı metin (yalnızca Aile Modu) |

**Kurallar**
- Çocuk Modu'nda yazı **20 sp'den küçük olamaz**.
- Tamamı büyük harf kullanılmaz (Türkçe "İ/ı" sorunları ve okunabilirlik). Cümle düzeni: "Kediyi bul".
- Sistem yazı ölçeği 1.3'e kadar taşmadan desteklenir; Çocuk Modu'nda üst sınır 1.3 ile kırpılır.

---

## 4. Boşluk, Izgara, Köşe ve Gölge

### 4.1 Boşluk (4'lük taban)
`s1 4` · `s2 8` · `s3 12` · `s4 16` · `s5 24` · `s6 32` · `s7 48` · `s8 64`

- Ekran kenar boşluğu: telefon `s5` (24), tablet `s7` (48).
- Kartlar arası: en az `s5` (24).

### 4.2 Yerleşim
- **Tasarım tabanı:** tablet yatay 1280×800 dp, telefon yatay 800×360 dp. Dikey de desteklenir.
- Oyun alanı dikeyde üç bölge: **Üst bar** (64 dp) · **Yönerge/Hedef alanı** (esnek, ~%35) · **Seçenek alanı** (esnek, ~%50).
- Seçenekler her zaman yatay sırada ve ortalı; 4 seçenek telefonda 2×2'ye geçebilir.

### 4.3 Köşe yarıçapları
`rXs 8` · `rSm 12` · `rMd 20` · `rLg 28` · `rXl 36` · `rPill 999`
- Seçenek kartı `rLg`, tema kartı `rXl`, buton `rPill`, diyalog `rLg`, ikon buton daire.

### 4.4 Gölge ve derinlik ("dokunsal düz" stil)
- `e1`: `0 2 6` `shadow@8%` (düz kartlar, Aile Modu)
- `e2`: `0 6 18` `shadow@10%` (seçenek ve tema kartları)
- **Alt kenar (press depth):** basılabilir öğelerde 6 dp'lik, rengin `deep` tonunda alt kenar. Basıldığında öğe 4 dp aşağı iner, alt kenar 2 dp'ye düşer (100 ms). Unity'deki `ButtonTop`/`ButtonBack` iki katmanlı butonun modern karşılığı.
- Seçenek kartlarının alt kenarı `line` renginde (beyaz kart, açık gri kenar).

---

## 5. Görsel Dil: Resimler, İkonlar, İllüstrasyon

### 5.1 İçerik resimleri (öğeler)
- **Varsayılan: gerçek fotoğraf, "sticker" kesimi.** Arka planı temizlenmiş nesne, etrafında 6–8 dp beyaz kontur ve çok hafif gölge. Bu, fotoğrafları modern ve tutarlı gösterir, mevcut "gerçek fotoğraf" vaadini korur.
- Tek nesne, ortalanmış, kartın %70–80'ini kaplar. Kırpılmış/kenara taşan nesne yok.
- Aynı temada aynı ışık ve açı (mümkünse yandan veya 3/4 önden).
- Soyut kavramlar (vücut bölgeleri, konum, duygu durumları, rutin adımları) için **sade düz illüstrasyon**: yuvarlak formlar, 2–3 ton gölge, kontur yok veya aynı rengin koyusunda 3 dp kontur.
- Dosya: WebP, kısa kenar 1024 px, şeffaf zemin.
- Ebeveyn ayarında "Fotoğraf / Çizim" seçeneği, içerik varsa geçerli.

### 5.2 Siluet ve yarım görseller
- Gölgeler öğe resminin alfa kanalından otomatik üretilir: renk `#5B6670`, opaklık %85, kenar yumuşatma 1 dp.
- Yarım görseller çalışma anında kırpılır; kesim çizgisinde 2 dp beyaz boşluk.

### 5.3 İkonlar
- Arayüz ikonları: yuvarlak uçlu, 2.5 dp çizgi kalınlığı, 28 dp tuval, `ink` rengi. Öneri: Material Symbols Rounded (ağırlık 600) veya Phosphor (Bold). Tek bir set seçilir, karıştırılmaz.
- Tema ikonları: düz illüstrasyon, tema `accent` renginde dolgulu daire içinde.
- Oyun modu ikonları: her mod için tek bir basit sembol (göz = Tanı, kulak = Sesini Bul, gölge = Gölgesini Bul, sepet = Grupla…). Bkz. ana rapor Bölüm 6.

---

## 6. Hareket (Motion) Tokenları

| Token | Süre | Eğri | Kullanım |
|---|---|---|---|
| `tap` | 100 ms | `easeOut` | Buton/kart basılma |
| `appear` | 320 ms | `easeOutBack` (overshoot 1.1) | Seçenek kartının belirmesi (0 → 1 ölçek) |
| `stagger` | 150 ms | — | Kartlar arası belirme gecikmesi |
| `dismiss` | 260 ms | `easeIn` | Yanlış seçeneklerin kaybolması |
| `fadeHint` | 600 ms | `easeInOut` | 2 yanlış sonrası yanlışların soluklaşması (opacity 1 → 0.25) |
| `breathe` | 1000 ms döngü | `easeInOut` | İpucu: doğru kart 1.00 ↔ 1.06, en fazla 3 döngü |
| `nudge` | 400 ms | `elasticOut` (hafif) | Yanlış seçimde doğru kartın zıplaması (punch scale 1.12) |
| `focus` | 500 ms | `easeOutCubic` | Doğru kartın ortaya gelip büyümesi (1.0 → 1.35) |
| `snap` | 220 ms | `easeOutCubic` | Sürüklenen öğenin hedefe oturması |
| `returnHome` | 350 ms | `easeOutCubic` | Yanlış yere bırakılan öğenin geri dönmesi |
| `pageSlide` | 300 ms | `easeOutCubic` | Aşama geçişi (öğe aşağı, yazı yukarı kayar) |
| `celebrate` | ≤ 1500 ms | — | Kutlama toplam süresi |

**Kurallar**
- Ekranda aynı anda **tek** sürekli animasyon (ör. yalnızca ipucu nefesi). Arka planda hareket eden öğe yok.
- "Sade" kutlama: doğru kartın `focus` hareketi + yumuşak `successGlow` halesi + 1 yıldızın dolması. Parçacık yok.
- "Tam" kutlama: yukarıdakine ek olarak ≤ 20 yıldız parçacığı (yavaş, aşağıdan yukarı süzülen) veya ≤ 5 balon.
- "Kapalı": yalnızca yıldız dolar ve öğenin adı söylenir.
- Sistem "animasyonları azalt" açıksa tüm süreler ×0.5, overshoot ve parçacık yok.

---

## 7. Ses Tasarımı Tokenları

| Token | Özellik |
|---|---|
| `voice` | Tek, sıcak, net bir ses (ElevenLabs'ta sabit ses ve ayar). Hız normalin ~%90'ı. −16 LUFS. |
| `praise` | 8–10 farklı kısa övgü cümlesi ("Aferin!", "Harika buldun!", "Çok güzel!"). Aynı övgü arka arkaya tekrar etmez. |
| `retry` | 3 farklı nötr cümle ("Hadi bir daha bakalım", "Tekrar deneyelim"). |
| `uiTap` | Çok kısa, yumuşak "tık" (≤ 80 ms, −24 LUFS). Varsayılan açık, kapatılabilir. |
| `successChime` | Yumuşak iki notalı çan (≤ 600 ms). |
| `starFill` | Hafif parıltı sesi (≤ 400 ms). |
| `roundEnd` | Kısa, sakin melodi (≤ 2 sn) + tebrik cümlesi. |
| `music` | Yumuşak, yavaş tempolu, akustik döngü. Varsayılan kapalı; açıkken konuşma sırasında %30'a kısılır. |

Yasak: siren benzeri, ani yüksek, metalik veya "hata" buzzer sesleri.

---

## 8. Bileşen Kütüphanesi

Her bileşen Flutter'da `lib/app/ui/` altında tek bir widget olarak yazılır ve tüm ekranlar bunları kullanır.

### 8.1 Temel

| Bileşen | Görünüm | Davranış |
|---|---|---|
| `SegButton` (birincil) | `rPill`, yükseklik 64 dp, `primary` dolgu, 6 dp `primaryDeep` alt kenar, beyaz `label` yazı + opsiyonel ikon | Basınca 4 dp iner (`tap`) |
| `SegButton.secondary` | Beyaz dolgu, `line` kenar, `ink` yazı | Aynı |
| `SegIconButton` | 64 dp daire, beyaz, `e2`, 28 dp ikon | Aynı; geri butonu için "basılı tut" varyantı: dairenin etrafında 1 sn dolan halka |
| `SegCard` | `surface`, `rLg`, `e2`, `line` alt kenar | — |
| `SegChip` | `rPill`, 40 dp, `primarySoft` dolgu | Seçili/seçili değil |
| `SegToggle` | 56×32 dp, açıkken `primary` | Aile Modu ayarları |
| `SegSlider` | 8 dp ray, 28 dp tutamak | Ses seviyeleri |

### 8.2 Çocuk Modu

| Bileşen | Görünüm | Davranış |
|---|---|---|
| `ThemeCard` (ana ekran) | Otsimo anatomisi: genişlik ekranın ~%30'u (telefonda 3, tablette 4 kart görünür), oran ~1:1; tema `accent` renginde 12 dp kalın çerçeve, `rXl`; içinde beyaz `rLg` pencere (%70) ve tek illüstrasyon (arkasında tema `bg` renginde yumuşak blob); alt şeritte beyaz `heading` ad + altında `caption` "13 oyun"; 6 dp `deep` alt kenar | Dokununca ad söylenir + tema açılır (ayarla "önce söyle, ikinci dokunuşta aç"). Tek sıra yatay kaydırma, kartlar arası 24 dp |
| `GameCard` (tema ekranı) | `ThemeCard` ile aynı anatomi (tema renginde çerçeve, beyaz pencere, oyun illüstrasyonu); alt şerit: solda 40 dp beyaz **durum dairesi** (▶ oynanabilir · 🔒 Premium · ✓ bugün oynandı), yanında 2 satıra kadar oyun adı; sağ üstte 1–3 küçük yıldız (en iyi tur) | Kilitliyse durum dairesinde `inkFaint` kilit, illüstrasyon %60 opak. Ekranda 3 kart, yatay kaydırma |
| `TierTabs` | Üç büyük sekme: 🟢 Kolay · 🟡 Orta · 🔵 Zor (renk + şekil: daire, kare, üçgen ikonları) | Seçili sekme `primarySoft` dolgu |
| `ChoiceCard` | Beyaz, `rLg`, `e2`; resim kartın %75'i; altta opsiyonel `itemLabel`; boyut: 2 seçenekte 260 dp, 3'te 220 dp, 4'te 180 dp (tablet) | Durumlar: `idle`, `pressed`, `hint` (`hintGlow` hale + `breathe`), `faded` (opacity 0.25, dokunulamaz), `correct` (`successGlow` hale + `focus`), `dismissed` |
| `DragItem` | `ChoiceCard` ile aynı görünüm, sürüklenirken 1.08 ölçek ve `e2` gölge büyür | Bırakılınca `snap` veya `returnHome` |
| `DropZone` | `surfaceMuted` dolgu, 3 dp kesikli `line` kenar, `rLg`; hedef siluet/etiket içinde | Üzerine gelince kenar `primary` ve hafif büyüme |
| `TopBar` | Sol: geri (basılı tut). Orta: `StarProgress`. Sağ: tekrar dinle | Sabit, tüm oyunlarda aynı |
| `StarProgress` | N adet 36 dp yıldız; boşken `line` dış hat, doluyken `star` dolgu + `starDeep` alt kenar | Dolunca hafif büyüme + `starFill` sesi |
| `PromptBubble` | Yönerge alanı: beyaz yuvarlak balon, içinde hedef resim/ses ikonu/yazı | Sesli yönerge çalarken ses ikonu yumuşakça nabız atar |
| `HintHand` | Sade, yuvarlak bir el ikonu (beyaz, `ink` kontur) | Doğru karta süzülür, iki kez "dokunur" |
| `RoundEndSheet` | Tam ekran `canvas`; ortada büyük 3–5 yıldız, `display` "Aferin!", altta iki büyük ikon buton: ↻ Tekrar, → Sonraki, ve küçük "Temaya dön" | Maskot (opsiyonel) yanında el sallar |
| `StickerAlbum` | Izgara; kazanılmamış sticker `surfaceMuted` siluet | Dokununca adı söylenir |
| `DailyPath` ("Bugünün Yolu") | `ChildTopBar`'daki 〰 geçişiyle açılır; kart alanında 4–6 büyük yuvarlak düğüm, aralarında yumuşak yol çizgisi; tamamlananlar `star` dolgulu | Düğüme dokununca o oyun açılır |
| `ChildTopBar` (ana ekran) | Solda yarı saydam gri hap "👤 Aile" (`ParentCorner`), ortada iki parçalı geçiş: 🎮 Oyunlar / 〰 Bugünün Yolu, sağda günlük ilerleme hapı "★ 2/6" | Aile hapı 2 sn basılı tutunca ebeveyn kilidi; geçiş ana ekran içeriğini değiştirir |
| `ParentCorner` | `ChildTopBar` içindeki "Aile" hapı; oyun ekranlarında görünmez | 2 sn basılı tutunca ebeveyn kilidi |

### 8.3 Aile Modu

| Bileşen | Görünüm |
|---|---|
| `FamilyHeader` | Solda büyük ekran başlığı ("Gelişim"), sağ üstte `primary` dolgulu hap "😊 Çocuk Modu" (Notion'daki Aile ↔ Çocuk geçişi; Otsimo'daki "Çocuk" butonu gibi); başlık altında profil avatarı + adı (açılır profil seçici) |
| `FamilyBottomNav` | 4 sekme: Gelişim · Oyunlar · Profiller · Ayarlar; seçili sekme `primary`, diğerleri `inkFaint` |
| `GoalRing` | Haftalık/günlük hedef halkası ("12 / 30 dakika"), halka `primary`, iz `line`; altında "Hedefi değiştir" |
| `WeekStrip` | 7 gün (Pt…Pz), oynanan günler `primarySoft` dolgulu daire + küçük yıldız; seri kaybı vurgusu yok |
| `StatTile` | Beyaz kart, `rMd`; büyük sayı (`title`), altında `caption` etiket, sağ altta küçük eğilim oku |
| `ChartCard` | Beyaz kart, `rMd`, başlık + `fl_chart` grafiği; en fazla 2 seri, ızgara `line` |
| `SkillBar` | Beceri alanı adı + yatay ilerleme (tema rengi yerine `primary`) + yüzde |
| `ItemChipList` | Öğrendikleri / Zorlandıkları: küçük sticker resimli çipler |
| `SettingsRow` | Sol ikon, başlık, açıklama, sağda `SegToggle`/seçici |
| `ParentGateDialog` | `rLg` diyalog; "Devam etmek için: 7 × 6 = ?" ; büyük sayı tuş takımı (72 dp tuşlar) |
| `PaywallSheet` | Üstte maskot/illüstrasyon, 3 madde fayda listesi, iki plan kartı (seçili olan `primary` kenar), deneme metni, tek `SegButton`, altta "Geri yükle" ve "İptal nasıl yapılır?" bağlantıları; kapat butonu her zaman görünür |
| `SurveyCard` | Tek soru; büyük resimli cevap kartları (2×2), "Atla" bağlantısı, üstte ilerleme noktaları |

---

## 9. Maskot (opsiyonel): "Minik"

- Yuvarlak, sakin bir **baykuş** (bilgelik çağrışımı, Türkçe'de sevimli). Renkleri `primary` ve `accent`.
- Pozlar: merhaba (el sallama), dinliyor, alkış, uyuyor (ekran süresi doldu), işaret ediyor (karşılama).
- **Nerede:** karşılama ekranları, ana ekran köşesi (statik), tur sonu, "Bugünlük bu kadar" ekranı, paywall.
- **Nerede değil:** soru/aşama sırasında, ipucu olarak (ipucu her zaman `HintHand`).
- Animasyonu en fazla 2 sn ve tek sefer; sürekli döngü yok.
- Maskot istenmezse aynı yerlerde tema illüstrasyonu kullanılır.

---

## 10. Ekran Şablonları

### 10.1 Çocuk ana ekranı (yatay)

```
┌───────────────────────────────────────────────────────────────┐
│ (👤 Aile)         [ 🎮 Oyunlar | 〰 Bugünün Yolu ]    (★ 2/6) │  ChildTopBar
│                                                               │
│  ┏━━━━━━━━━━━━━━┓  ┏━━━━━━━━━━━━━━┓  ┏━━━━━━━━━━━━━━┓  ┏━━   │
│  ┃ ┌──────────┐ ┃  ┃ ┌──────────┐ ┃  ┃ ┌──────────┐ ┃  ┃     │  ThemeCard: kalın tema çerçevesi,
│  ┃ │   🐶     │ ┃  ┃ │   🍎     │ ┃  ┃ │   🚗     │ ┃  ┃     │  beyaz pencere, illüstrasyon
│  ┃ └──────────┘ ┃  ┃ └──────────┘ ┃  ┃ └──────────┘ ┃  ┃     │
│  ┃  Hayvanlar   ┃  ┃ Meyve-Sebze  ┃  ┃  Taşıtlar    ┃  ┃  →  │  tek sıra yatay kaydırma
│  ┃   14 oyun    ┃  ┃   12 oyun    ┃  ┃   11 oyun    ┃  ┃     │
│  ┗━━━━━━━━━━━━━━┛  ┗━━━━━━━━━━━━━━┛  ┗━━━━━━━━━━━━━━┛  ┗━━   │
└───────────────────────────────────────────────────────────────┘
```
- Zemin `canvas` (Otsimo'daki gökyüzü yerine düz krem; isteğe bağlı tek, çok silik bulut motifi).
- "Bugünün Yolu" seçiliyken aynı alanda 4–6 düğümlük yatay yol (`DailyPath`) görünür.
- Ebeveyn "görünen temalar"ı kısıtlayabilir.

### 10.2 Tema ekranı

```
┌───────────────────────────────────────────────────────────────┐
│ (←)  Hayvanlar                         [ ● Kolay | ■ Orta | ▲ Zor ] │  zemin: tema bg
│                                                               │
│  ┏━━━━━━━━━━━━━━┓  ┏━━━━━━━━━━━━━━┓  ┏━━━━━━━━━━━━━━┓  ┏━━   │
│  ┃ ┌──────────┐ ┃  ┃ ┌──────────┐ ┃  ┃ ┌──────────┐ ┃  ┃     │  GameCard
│  ┃ │ 🐱 🐶    │ ┃  ┃ │  👂 🐄   │ ┃  ┃ │  ◐ 🐘    │ ┃  ┃  →  │
│  ┃ └──────────┘ ┃  ┃ └──────────┘ ┃  ┃ └──────────┘ ┃  ┃     │
│  ┃ (▶) Hayvan-  ┃  ┃ (▶) Sesini   ┃  ┃ (🔒) Gölgesi-┃  ┃     │  durum dairesi + ad
│  ┃  ları Öğren  ┃  ┃      Bul     ┃  ┃      ni Bul  ┃  ┃     │
│  ┗━━━━━━━━━━━━━━┛  ┗━━━━━━━━━━━━━━┛  ┗━━━━━━━━━━━━━━┛  ┗━━   │
└───────────────────────────────────────────────────────────────┘
```
- Seçili zorluk sekmesi, açılacak oyunun içerik katmanını ve sunum zorluğunu belirler (ana rapor Bölüm 8).
- Kartlar **çocuğa en uygun sırayla** dizilir (ana rapor Bölüm 6.4); ebeveyn sabitleyebilir.

### 10.3 Oyun ekranı

```
┌───────────────────────────────────────────────────────────────┐
│ (←)                 ★ ★ ☆ ☆ ☆                         (🔊)   │  TopBar
│                                                               │
│                 ╭──────────────────╮                          │
│                 │   🔊  Kedi hangisi? │                        │  PromptBubble (yazı ayarla gizlenebilir)
│                 ╰──────────────────╯                          │
│                                                               │
│        ┌─────────┐     ┌─────────┐     ┌─────────┐            │
│        │  🐱     │     │  🐶     │     │  🐰     │            │  ChoiceCard ×3
│        │  Kedi   │     │  Köpek  │     │ Tavşan  │            │
│        └─────────┘     └─────────┘     └─────────┘            │
└───────────────────────────────────────────────────────────────┘
```
- Zemin: tema `bg`. Başka hiçbir dekor yok.

### 10.4 Sürükle-bırak oyun ekranı (Gölgesini Bul, Grupla)

```
│        ┌ ─ ─ ─ ─ ┐          ┌ ─ ─ ─ ─ ┐                      │
│          (siluet)              🧺 Meyve                       │  DropZone(lar)
│        └ ─ ─ ─ ─ ┘          └ ─ ─ ─ ─ ┘                      │
│                                                               │
│        ┌───────┐  ┌───────┐  ┌───────┐                        │  DragItem(lar)
```

### 10.5 Tur sonu
Zemin `canvas`, ortada yıldızlar ve "Aferin!", altında ↻ ve → büyük ikon butonları. 4 sn işlem yoksa otomatik tema ekranına döner (Unity'deki davranışla uyumlu).

### 10.6 Aile Modu
Zemin `#F5F6F8`, dikey ve yatay desteklenir. Üstte `FamilyHeader`, altta `FamilyBottomNav` (**Gelişim · Oyunlar · Profiller · Ayarlar**; Abonelik ve Hakkında Ayarlar içinde). Gelişim sekmesi: `WeekStrip`, `GoalRing`, 3 `StatTile` (bugün süre, bu hafta tur, ipucusuz doğruluk), `ChartCard` (haftalık), `SkillBar` listesi, `ItemChipList`. "Oyunlar" sekmesi: ebeveynin oyunları görmesi, gizlemesi, sabitlemesi ve zorluğunu ayarlaması.

---

## 11. Flutter Uygulaması

### 11.1 Token sınıfları

```dart
// lib/app/theme/colors.dart
abstract final class SegColors {
  static const canvas = Color(0xFFF7F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0EDE6);
  static const line = Color(0xFFE4DFD6);
  static const ink = Color(0xFF2F3A45);
  static const inkSoft = Color(0xFF5F6C78);
  static const inkFaint = Color(0xFF9AA4AE);
  static const primary = Color(0xFF4A9C8C);
  static const primaryDeep = Color(0xFF33796B);
  static const primarySoft = Color(0xFFDCEFEA);
  static const accent = Color(0xFFF2A65A);
  static const accentDeep = Color(0xFFD9853A);
  static const star = Color(0xFFF5C451);
  static const starDeep = Color(0xFFD9A52E);
  static const hintGlow = Color(0xFFFFE7A3);
  static const successGlow = Color(0xFFBFE6D6);
  static const familyCanvas = Color(0xFFF5F6F8);
}

@immutable
class ThemePalette { // içerik temaları için
  final Color bg, accent, deep;
  const ThemePalette(this.bg, this.accent, this.deep);
}
```

```dart
// lib/app/theme/motion.dart
abstract final class SegMotion {
  static const tap = Duration(milliseconds: 100);
  static const appear = Duration(milliseconds: 320);
  static const stagger = Duration(milliseconds: 150);
  static const dismiss = Duration(milliseconds: 260);
  static const fadeHint = Duration(milliseconds: 600);
  static const breathe = Duration(milliseconds: 1000);
  static const nudge = Duration(milliseconds: 400);
  static const focus = Duration(milliseconds: 500);
  static const snap = Duration(milliseconds: 220);
  static const returnHome = Duration(milliseconds: 350);
  static const pageSlide = Duration(milliseconds: 300);
}
```

- `ThemeData` → `ThemeExtension<SegTokens>` ile radius, gölge, boşluk tokenları; `ThemePalette` aktif içerik temasına göre `InheritedWidget`/Riverpod ile sağlanır.
- `google_fonts` yerine Nunito dosyaları `assets/fonts/` altında paketlenir (çevrimdışı).
- Tüm bileşenler için golden testler: her durum (idle, hint, faded, correct) telefon ve tablette.

### 11.2 Kontrol listesi (her yeni ekran için)

- [ ] Yalnızca token renkleri/yazıları/süreleri kullanıldı
- [ ] Çocuk Modu'nda yazı ≥ 20 sp, dokunma alanı ≥ 96 dp
- [ ] Ekranda tek odak, en fazla 4 seçenek, dekor yok
- [ ] Aynı anda tek sürekli animasyon
- [ ] Kırmızı/hata rengi yok; geri bildirim renk + hareket + ses
- [ ] Sistem yazı ölçeği 1.3 ve "animasyonları azalt" ile test edildi
- [ ] Çocuk Modu'nda satın alma/dış bağlantı yok
