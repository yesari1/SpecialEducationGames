> Codex inceleme durumu: Bu ilk DeepSeek taslağı henüz kabul edilmedi. Satır referansları ve tekrar iş maddeleri için düzeltme görevi gönderildi; InferX HTTP500/yanıt hataları yüzünden tamamlanmadı. Güncel yürütme durumu TODO.md ve DEVELOPMENT_STATUS.md içindedir. Hiçbir uygulama değişikliği bu görevlerden çıkmadı.
>
> Koordinatörün doğruladığı düzeltmeler: welcome_pane.dart:24/61, family_screen.dart:166 (gövde)/85 (dialog). Onboarding, ebeveyn kapısı, abonelik, hesap, lisans, oyun sonucu ve albüm de envantere dahil edilmeli. Aynı-dil-ses hash raporu, altı ücretsiz oyun ve önceki çevrimdışı kontroller zaten mevcut; bunlar yeniden sıfırdan uygulama işi değildir. Fotoğraf maskeleme .NET/PowerShell ile yapılır. Nihai insan onayı teknik hazırlığı durdurmaz. Aşağıdaki taslak bu inceleme notlarıyla okunmalıdır.
# DeepSeek Çalışma Kuyruğu (Denetim)

Bu belge yalnızca bir **denetim ve iş kuyruğu** önerisidir. Hiçbir uygulama işi
bu denetimle tamamlanmış veya doğrulanmış sayılmaz. Her başlık ayrı bir Codex
incelemesiyle kapatılmalıdır.

Kaynak: TODO.md (sha256 1325d0de…), Codex durum özeti ve `lib/` kaynak incelemesi.

## Kapsam kuralları
- Yatay yön; **dikey kaydırma yok**.
- Beyaz/turuncu/mavi/turkuaz palet ve cihaz diline göre ilk dil seçimi korunur.
- Yeni TTS/görsel üretimi, canlı servis dağıtımı, imza/satın alma/güç değişikliği yok.
- TR/EN aynı SHA256 sesleri ve G10’un dile özgü uygunluğu birlikte ele alınır.
- Her birim bağımsız incelenebilir büyüklükte tutulur.

---

## A. Önce: dikey kaydırmayı kaldır (kaynak kanıtlı)

Denetimde `lib/` altında bulunan gerçek dikey kaydırma widget’ları:

1. `lib/features/onboarding/welcome_pane.dart:24` — `SingleChildScrollView` (sol sütun).
2. `lib/features/onboarding/welcome_pane.dart:76` — `SingleChildScrollView` (sağ kart içi).
3. `lib/features/family/family_screen.dart:144` — üst düzey `ListView` (tüm gövde).
   Aynı dosyada `~:72` `AlertDialog(scrollable: true)`.

`lib/features/game/game_screen.dart` (683 satır) ve `lib/features/game/widgets/`
kaydırma taraması bu denetimde tamamlanamadı; arama çıktısı güvenilir biçimde
dönmedi. Önce aşağıdaki A1 ile bitirilmeli.

### A1. Kaydırma envanteri
- [ ] `lib/` ağacında `ListView`, `SingleChildScrollView`, `CustomScrollView`,
  `GridView`, `PageView`, `TabBarView`, `ReorderableListView` sembollerini
  dosya:satır referanslarıyla listele (game_screen ve widgets dahil).
- Kabul: welcome_pane ve family_screen referansları doğrulanır; her bulgu için
  dosya+satır ve sarmalanan içerik açıklanır.
- Kanıt: Satır numaralı kod alıntısı (test gerekmez).
- Blokaj: Yok.

### A2. `welcome_pane.dart` kaydırmasız düzen — İLK UYGULAMA GÖREVİ
- [ ] İki `SingleChildScrollView` kaldırılır; iki sütunlu `Row` içeriği
  `Flexible`/sabit yükseklik ile yerleşir; CTA (`welcome-start`) kaybolmaz.
- Kabul: 800×360 ve 1280×800, %100/%160/%200 yazı ölçeğinde dikey kaydırma yok;
  CTA ≥64px dokunma hedefiyle görünür; taşma/klip yok.
- Kanıt: Welcome QA/widget testi yeniden çalıştırılır; `flutter analyze` temiz;
  ekran görüntüsü notu.
- Blokaj: Yok. **İlk küçük görev budur** (tek dosya, sınırlı risk).

### A3. `family_screen.dart` gövde kaydırmasını kaldır
- [ ] Üst düzey `ListView` yerine yüksekliğe sığan sekmeli yerleşim; uzun liste
  içeriği (Gelişim/Oyunlar/Profiller/Ayarlar) açık sayfalama veya yatay gezinmeye taşınır.
- Kabul: Dört sekme 800×360’ta taşma/klips olmadan render edilir; Slider ve
  anahtarlar ≥48px dokunma hedefini korur.
- Kanıt: Family hedefli widget testleri; manuel render notu.
- Blokaj: Yok.

### A4. `game_screen.dart` ve oyun widget’larını kaydırmasız yap
- [ ] A1 envanterindeki tüm bulgular kaydırmasız düzenele alınır.
- Kabul: Tüm zorluk ve modlarda yatay taşma/klips yok; büyük yazı regresyonu yok.
- Kanıt: Oyun widget testleri; büyük yazı regresyonu.
- Blokaj: A1 envanteri.

---

## B. Yanlış dilde ses ve G10 dile özgü uygunluk

Bağlam: 74 eski öğede TR/EN ses dosyası aynı SHA256’ya sahip; 73’ünde sözcük
farklı (örn. `animals.cow`). İngilizce bu öğeler için tamamlanmış sayılmaz.

### B1. duplicateLocaleAudio / differentLabelsSameAudio tespiti
- [ ] 74 öğe, dosya+hash çiftiyle yeniden üretilebilir bir rapor/betik olarak sabitlenir.
- Kabul: Liste çift hash ile yeniden üretilir; yeni TTS üretilmez.
- Kanıt: Betik/rapor çıktısı ve özet JSON.
- Blokaj: Yok.

### B2. Yanlış dile sessiz geri dönüşü engelle
- [ ] İstenen dilden ses yoksa başka dile **sessizce fallback yok**; durum açık raporlanır.
- Kabul: Eksik/yanlış kayıt net sonuç verir; sessiz fallback yok.
- Kanıt: Hedefli birim/widget testi (mevcut kanal testleri ile).
- Blokaj: B1 sınıflandırması.

### B3. G10 dile özgü uygunluk
- [ ] G10 ses/sessiz koşulları TR ve EN için ayrı doğrulanır.
- Kabul: Eksik dile özgü ses varsa oyun açılmaz ve günlük yola eklenmez.
- Kanıt: G10 hedefli testler (mevcut mute/kanal testleri ile).
- Blokaj: B1, B2.

---

## C. Kalan içerik ve yerelleştirme

### C1. Eksik görseller (14 produce + diğer geçici)
- [ ] Eksik listeyi sabit kaynak al; yalnız lisanslı gerçek fotoğraf akışıyla doldur;
  her varlık için kaynak/yazar/lisans kaydı tut.
- Kabul: 1024×1024 RGBA, 4px beyaz kontur, tek nesne, tam kadraj.
- Kanıt: Python pipeline 2 deterministik çalışma + hash eşitliği.
- Blokaj: Dış kaynak bulma (internet) + kullanıcı onayı.

### C2. Kalan ekranları ARB’ye taşı (`state.tr` → ARB)
- [ ] Kalan `state.tr` çağrıları ekran bazlı küçük birimlerle ARB’ye taşınır.
- Kabul: TR/EN anahtar paritesi; görünür metinler değişmez.
- Kanıt: Birim başına yerelleştirme testi + analyze.
- Blokaj: Yok.

---

## D. Entegrasyonlar (yerel vs canlı ayrımı)

- D1. Firestore canlı erişim: yerel taslak kurallar/özet adaptörü yeşil; canlı API 403/disabled — **canlı doğrulanmadı** (dış bağımlılık).
- D2. Google OAuth canlı giriş/çıkış: yerel fake testler yeşil; provider/OAuth SHA — **canlı doğrulanmadı**.
- D3. Play Billing gerçek ürün testleri: istemci yazılı; emülatör desteklemiyor — **canlı doğrulanmadı**.
- D4. Hesap silme / App Check / kurallar canlı: callable varsayılan kapalı, deploy yok — **canlı doğrulanmadı**.

> D maddeleri dış konsol/API/Play erişimi gerektirir; bu denetimle tamamlanmış sayılmaz.

---

## E. Kabul ve yayın (yerel vs dış)

- [ ] Uçak modu, erişilebilirlik, performans ve tüm oyun durum kabulü.
- [ ] Diğer ekranlarda büyük yazı/TalkBack/dokunma hedefi kabulü.
- [ ] Altı ücretsiz oyun kuralı (§13.1b) yerel uyumu.
- Dış: gizlilik/mağaza/Families beyanları, gerçek cihaz, öğretmen/aile testi.

---

## Codex için özet

- **Denetim bulgusu (kaynak):** `welcome_pane.dart:24` ve `:76`
  `SingleChildScrollView`; `family_screen.dart:144` üst düzey `ListView`;
  ayrıca `family_screen.dart ~:72` `AlertDialog(scrollable:true)`.
  `game_screen.dart` ve `widgets/` taraması doğrulanamadı → A1’de bitir.
- **Önerilen ilk küçük görev (A2):** `welcome_pane.dart` iki
  `SingleChildScrollView` kaldırılıp yüksekliğe sığan iki sütun; 800×360’ta
  CTA kaydırmasız görünür. Tek dosya, sınırlı risk.
- **Öncelik:** (A) kaydırmasız UI → (B) yanlış dil sesi + G10 →
  (C) kalan içerik/yerelleştirme → (D) entegrasyonlar → (E) kabul.
- **Bağımlılıklar:** A2/A3 bağımsız; A4→A1; B3→B1,B2; C1→dış kaynak+onay;
  D*→dış erişim.
- **Yerel vs canlı:** A/B/C yerelde doğrulanabilir; D* yerel istemci yeşil olsa
  da canlı doğrulanmamış kalır.
- **Tamamlanmış madde yok.** TODO.md’de hiçbir checkbox `[x]` yapılmadı.

