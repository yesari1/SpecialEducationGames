# Özel Eğitim Oyunları: Flutter'a Geçiş ve Ürün Raporu (v3)

> Güncel uygulama kontrol listesi: [TODO.md](TODO.md). Yapılanlar/kalanlar her değişiklikte orada işaretlenir; test geçmişi [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) içindedir. Son kullanıcı kararları: yalnızca yatay kullanım, beyaza yakın zemin ve canlı turuncu/mavi/turkuaz UI, telefon dilinden otomatik ilk dil, TR İrem / EN Laura (Multilingual v2), gerçek internet fotoğrafları ve beyaz özne konturu. Aşağıdaki eski kararlarla çelişirse bu son talepler uygulanır.

> **Amaç:** Google Play'deki "Özel Eğitim Oyunları" (`com.YeS.OzelEgitimOyunlari`) uygulamasını Flutter ile baştan yazmak, içeriği ve oyun türlerini büyük ölçüde genişletmek, reklamsız abonelik modeline geçmek ve aynı paket adıyla güncelleme olarak yayınlamak.
> **Okuyucu:** Uygulamayı yazacak geliştirici/agent. Her bölüm doğrudan uygulanabilir olacak şekilde yazıldı. Kurallar "zorunlu", öneriler "öneri" olarak işaretlendi.
> **Kaynaklar:** Unity projesi, ürün sahibinin Notion notları ("Yapılacaklar", "Roadmap", "v1.35"), Otsimo incelemesi, özel eğitim literatürü (hatasız öğretim, ipucu hiyerarşisi), Google Play Families politikası.
> **Sürüm:** v3.1, 15 Ekim 2026. v3'te: oyun sayısı 55'e çıkarıldı, temalar 16'ya ve somut temalarda 40–50 öğeye genişletildi (Kolay/Orta/Zor katmanlı), zorluk = içerik katmanı + sunum olarak yeniden tanımlandı, ayrı tasarım sistemi eklendi. v3.1'de: ürün sahibinin 33 Otsimo ekran görüntüsü incelendi; tasarım sistemi gerçek ekranlara göre güncellendi, Otsimo'dan 11 oyun fikri (G56–G66) ve 2 tema (Para ve Zaman, Hikayeler) eklendi.
> **Ek dosyalar:** [tasarim-sistemi.md](tasarim-sistemi.md) (stil rehberi, zorunlu) · [icerik-katalogu.md](icerik-katalogu.md) (tüm öğe listeleri)

---

## İçindekiler

0. Kısa Özet
1. Mevcut Durum: Unity Projesi ve Notion'daki İlerleme
2. Otsimo ve Benzer Uygulamalar
3. Pedagojik Temel: Hatasız Öğretim ve İpucu Sistemi
4. Tasarım Kuralları ve Stil (→ tasarim-sistemi.md)
5. **Kategori Yapısı: Beceri Alanı × Tema × Oyun**
6. **Oyun Kataloğu (66 oyun)** ve Tema × Oyun matrisi
7. İçerik (→ icerik-katalogu.md)
8. Zorluk Sistemi
9. Profil, Başlangıç Anketi ve Aile/Çocuk Modu
10. Raporlama ve Veri Toplama
11. Uygulama Ekranları
12. Flutter Mimarisi
13. Gelir Modeli: Reklamsız Abonelik + Ücretsiz Katman + Deneme
14. Google Play Uyumluluk Kontrol Listesi
15. Yol Haritası ve Öncelikler
16. Test Planı
17. Agent İçin Uygulama Talimatı
18. Açık Sorular

---

## 0. Kısa Özet

1. **Mevcut uygulama:** 10 sahne, 5 oyun (Meyve-Sebze ×3, Hayvanlar ×3, Renkler, Sonraki Sayı, Sayıları Karşılaştır). Tek mekanik: "Sesli yönerge → 3 görselden doğruyu seç", 5 aşama, yıldız + kutlama. Unity'de ayrıca Google/Firebase girişi, Hayvanlar 4–5 verisi, ElevenLabs ses üretimi, GameAnalytics hazır.
2. **Notion'daki yön çok doğru:** önce altyapı (ebeveyn kilidi, çoklu çocuk profili, bulut, raporlama), sonra aynı temaları farklı oyun modlarıyla çeşitlendirme, sonra yeni temalar, en son yapboz ve sıralama. Bu rapor bu sırayı korur ve Flutter'a uyarlar.
3. **Kategori yapısı:** Çocuk **18 temadan** birini seçer (Hayvanlar, Taşıtlar, Kıyafetler…). Temanın içinde **66 oyundan** o temaya uygun olanlar vardır (Tanı, Sesini Bul, Gölgesini Bul, Anne ve Yavrusu, Odalara Yerleştir, Yapboz…). Her oyun **Kolay / Orta / Zor** oynanır; zorluk hem içeriği (kolay hayvanlar → zor hayvanlar) hem sunumu (2 → 4 seçenek) değiştirir. Somut temalarda 40–50 öğe var (toplam ~600). Sonuç: lansman sonrası hedefte ~950 farklı oynanabilir set (~317 tıklanabilir oyun kartı). Ebeveyn gelişimi 9 **Beceri Alanı** üzerinden görür.
3b. **Stil:** Otsimo'nun sakin ve sıcak yaklaşımı modernleştirilerek ayrı bir tasarım sistemine dönüştürüldü (pastel tema renkleri, beyaz "sticker" kartlar, dokunsal butonlar, Nunito, hareket ve ses tokenları).
4. **Pedagoji:** hatasız öğretim (Notion'daki "2 yanlıştan sonra yanlış seçenekler soluklaşsın" kuralı dahil), seçenek sayısının 1–2'den başlayıp artması, ipucu hiyerarşisi, ceza yok, süre sınırı yok.
5. **Para modeli:** Reklam yok. Ücretsiz katman (her temanın ilk seviyesi + temel modlar) + Premium (aylık/yıllık) + 7 gün deneme. Satın alma ve ayarlar yalnızca ebeveyn kilidinin arkasında.
6. **Acil:** Play sayfası şu an "Reklam içerir" gösteriyor ve açıklamada yer tutucular (`[email address]`) var. Yeni sürümde Play Console beyanları düzeltilmeli. Güncelleme için **aynı paket adı ve aynı imzalama anahtarı** şart, versionCode ≥ 14.

---

## 1. Mevcut Durum: Unity Projesi ve Notion'daki İlerleme

### 1.1 Teknik künye

| Alan | Değer |
|---|---|
| Unity | 2022.3.62f3, URP 2D, Zenject, DOTween, MEC, Unity Localization + Addressables |
| Paket adı | `com.YeS.OzelEgitimOyunlari` (**aynen korunmalı**) |
| Sürüm | `bundleVersion 1.3`, `versionCode 13` → Flutter sürümü **≥ 14**, `versionName 2.0.0` önerilir |
| minSdk / targetSdk | 23 / 34 (Flutter'da targetSdk Play'in güncel zorunluluğu, 35+) |
| Diller | Türkçe, İngilizce |
| Font | Archivo (variable) |
| Servisler | Firebase Auth (Google Sign-In), Realtime Database (test), Firebase Analytics, GameAnalytics (içinde AdMob/IronSource gelir entegrasyon dosyaları var) |
| Mağaza | 1K+ indirme, 3+, "Öğretmen Onaylı", son güncelleme 2 Nisan 2026 |

### 1.2 Mevcut oyunlar ve içerik (taşınacak)

| Oyun | Mekanik | İçerik |
|---|---|---|
| Meyve ve Sebzeleri Öğren 1–3 | Dinle → 3 resimden seç | 30 öğe |
| Hayvanları Öğren 1–3 | Aynı | 30 öğe |
| Renkleri Öğren | Aynı | 11 renk |
| Sonraki Sayıyı Bul | Üstte dizi, gizli olanı alttaki 3 seçenekten bul | 1–10 |
| Sayıları Karşılaştır | İki sayı → büyük/eşit/küçük; ses: "9 ve 4, bu sayıları karşılaştır bakalım" | 1–10 |

**Öğe listeleri:**
- Meyve-Sebze 1: Muz, Lahana, Kiraz, Patlıcan, Üzüm, Portakal, Armut, Patates, Çilek, Domates
- Meyve-Sebze 2: Elma, Havuç, Kabak, Salatalık, Mandalina, Nane, Şeftali, Biber, Erik, Karpuz
- Meyve-Sebze 3: Böğürtlen, Karnabahar, Kestane, Marul, Soğan, Bezelye, Nar, Ayva, Turp, Ispanak
- Hayvanlar 1 (Ev ve Yakın): Kuş, Kelebek, Kedi, Civciv, Köpek, Ördek, Balık, Fare, Tavşan, Kaplumbağa
- Hayvanlar 2 (Çiftlik): Arı, Boğa, Tavuk, İnek, Eşek, Keçi, At, Horoz, Koyun, Hindi
- Hayvanlar 3 (Vahşi): Ayı, Geyik, Fil, Zürafa, Aslan, Maymun, Baykuş, Kaplan, Kurt, Zebra
- **Hazır ama yayında değil** (`Scriptables/ItemDatas/OLDAnimals`): Hayvanlar 4 (Deniz, Orman, Küçük Dostlar): Karınca, Yunus, Kirpi, Su Aygırı, Uğur Böceği, Ahtapot, Köpekbalığı, Sincap, Balina · Hayvanlar 5 (Egzotik): Yarasa, Deve, Bukalemun, Timsah, Flamingo, Goril, Kanguru, Devekuşu, Penguen, Gergedan
- Renkler: Siyah, Mavi, Kahverengi, Gri, Yeşil, Turuncu, Pembe, Mor, Kırmızı, Beyaz, Sarı
- Sesler (TR/EN): tüm öğe adları, "Hangisi sonraki sayı?", "ve", "büyük/eşit/küçük", 5 başarı, 3 tebrik, 2 seviye sonu, "bir daha dene", menü müziği. ElevenLabs ile üretilmiş.

### 1.3 Korunacak oyun hissi (Unity'de iyi çalışanlar)

Notion'da tek tek yapılmış ve oturmuş detaylar; Flutter'da aynen karşılığı olmalı:
- Başlangıçta yönerge metni görünür ve seslendirilir, ardından seçenekler **sırayla** (stagger) büyüyerek gelir.
- **Doğru seçimde:** diğer seçenekler animasyonla kaybolur, seçilen öğe **öne/ortaya gelir ve büyür**, halka (circles) parçacık efekti, ardından yıldız parçacığı; başarı sesi + öğenin adı tekrar söylenir; üstteki yıldız dolar.
- Aşama geçişi: öğe aşağı kayar, yazı yukarı kayar, yeni aşama başlar.
- **Yanlış seçimde:** ceza yok; doğru seçenek kendini hafifçe zıplatarak gösterir (punch scale) ve "bir daha dene" sesi çalar.
- Sesler sıralı bir kuyrukta çalar (ör. "dokuz" + "ve" + "dört" + "bu sayıları karşılaştır bakalım").
- Bağımsız yönerge sesleri enum/anahtar ile çağrılır, sahneler arasında ortaktır.
- Tur bitince tebrik, birkaç saniye sonra menüye dönüş.
- Arka plan: hafif fayans dokusu (Flutter'da çok düşük kontrastlı ya da hiç; bkz. Bölüm 4).
- Bilinen hata (çözülmüş): hızlı sahne geçişlerinde `OnInfoTextShowed` iki kez çağrılıp seçenekleri erken gösteriyordu. Flutter'da her tur bir **iptal edilebilir oturum kimliği** taşımalı; eski turun gecikmeli işleri yeni turu etkilememeli.

### 1.4 Notion'daki açık işler (Flutter'da karşılanacak)

| Notion maddesi | Bu rapordaki karşılığı |
|---|---|
| Profil yoksa "Profil oluştur" ekranı açılsın | Bölüm 9.2 |
| Tek tek sorular: yaş, konuşabiliyor mu, araçları biliyor mu, eşyaları biliyor mu… | Bölüm 9.3 (anket ve sonuçların zorluğa etkisi) |
| Veriyi Firebase'e gönder, JSON'a kaydet | Bölüm 9.5 ve 12 (önce cihaz, sonra bulut senkronu) |
| Sol üstte Aile ↔ Çocuk geçişi | Bölüm 9.4 |
| Renkler için 5 seviye, Meyve-Sebze için 5 seviye | Bölüm 7 ve icerik-katalogu.md (her temada Kolay/Orta/Zor × 2 bölüm = 6 bölüm) |
| Her tema için farklı tarzda oyunlar | Bölüm 5 ve 6 (18 tema × 66 oyun) |
| Kolay/Orta/Zor seviyeler, kullanıcıya sorulacak | Bölüm 8 |
| Günlük, haftalık analiz için veri toplama | Bölüm 10 |
| Roadmap Aşama 1–4 | Bölüm 15 |
| Altın kurallar (hatasız öğretim, net seslendirme, modüler içerik) | Bölüm 3, tasarim-sistemi.md §7, Bölüm 12.3–12.4 |

---

## 2. Otsimo ve Benzer Uygulamalar

### 2.1 Otsimo | Special Education

Otsimo Bilişim A.Ş. (Ankara). Play: 100K+ indirme, ~2.6★, 3+, Öğretmen Onaylı, reklamsız.

| Konu | Otsimo | Hedefimiz |
|---|---|---|
| İçerik | 100+ oyun; sosyal hikayeler, sayılar-harfler, kelimeler, duygular, renkler, müzik, hayvanlar-çevre, taşıtlar | 18 tema × 66 oyun × 3 zorluk (~317 oyun kartı, ~950 set), ~650 öğe; her ay yeni içerik |
| Mekanikler | Eşleştirme, çizme, seçme, sıralama | 24 şablon: tanı, ses, gölge, yarım, saklanan, grupla, eşleştir, sırala, yapboz, şekil kutusu, say, hafıza, simon, boya, iz sür, giydir, yüz yap… |
| Zorluk | Makine öğrenmesiyle uyarlanabilir + manuel | Kural tabanlı uyarlanabilir + Kolay/Orta/Zor + anketle başlangıç |
| Rapor | Günlük karne ücretsiz; haftalık/aylık ve öğe bazlı Premium | Aynı mantık, grafiklerle |
| Profiller | Çoklu (Premium) | Çoklu (Premium), bulut senkronu |
| Çevrimdışı | Premium | **Herkes için** |
| Fiyat | 1 ay $20.99, yıllık ~$13.75/ay, ömür boyu $229.99; 14 gün deneme (2019) | Türkiye'ye uygun fiyat, şeffaf deneme |
| Şikayetler | İptal zorluğu, iade sorunları, takılma, pahalı | Kolay iptal yolu, hafif uygulama, adil fiyat |

### 2.1b Otsimo'nun ekranlarından gözlenenler

Ürün sahibinin 33 ekran görüntüsünden (ayrıntılı analiz: [tasarim-sistemi.md §1.1](tasarim-sistemi.md)):
- **Ana ekran:** az sayıda büyük kategori (ör. Günlük Hayat · 13 oyun, Hikayeler · 10 kitap, Sayılar · 7 oyun), ekrana 3 kart sığar, yatay kaydırma; üst barda Aile butonu, Oyunlar/Öğrenme Yolu geçişi ve günlük ilerleme (0/6).
- **İçerik çoğaltma:** aynı içerik 3–4 fiil kalıbıyla ayrı oyunlara bölünmüş ("Mutfak Eşyalarını Öğren / Eşleştir", "Oturma Odası Eşyalarını Göster", "Meyve Yapbozu", "Şekiller Hafıza Kartları"). Bizim Tema × Oyun yapımız bunun sistemli hali.
- **Gözlenen oyun alanları:** ev odaları (oturma odası, mutfak, yatak odası, bahçe), kıyafet, meyve-sebze, meslek ve araçları, para (bozuk/kağıt), saat kurma, hava durumu, şekiller (2B, 3B, şekil çizimi), harfler (harf çizimi, çizgi çizimi, harf eşleştirme, sözcük oluşturma), sayılar (sayma, sıradaki sayı, karşılaştırma, birlikte sayalım), duygular ve emojiler, duyular, yapbozlar (şehir, oyuncak, hayvan, doğa, meyve, taşıt, ev eşyası, enstrüman, kendi yapbozunu yap), yer-yön, sıfat oyunu, müzik (ksilofon, gitar, piyano), sosyal hikayeler.
- **Kaçındığımız desenler:** kilitli kartların büyük, dikkat çeken kilit veya fiyat etiketiyle gösterilmesi (bizde küçük köşe kilidi), Aile ekranında **geri sayımlı indirim bandı**, "seriyi korumak için her gün oynamalı" suçluluk mesajı.

### 2.2 Diğer örnekler ve çıkarımlar

- **Autism iHelp serisi:** aynı/farklı, gölge eşleştirme, farklı olanı bul, kategoriye ayırma kutuları, ses-resim eşleştirme, zıtlar. Çıkarım: **tek bir mekanik = tek bir küçük oyun**, sade, gerçek fotoğraf.
- **Photo Touch (Farm Animals vb.):** gerçek fotoğraf, ses, yanlış cevap oyunu kesmez. Mevcut uygulamamıza en yakın örnek.
- **Learn with Rufus:** duygular (belirginden inceye), gruplar ve kategoriler. Çıkarım: duyguları **kademeli zorlukla** sunmak.
- **First Then Visual Schedule:** görsel rutin. Çıkarım: "Günlük Rutin" teması ve ileride ebeveyn için "Önce-Sonra" panosu.
- **AAC uygulamaları (Avaz, Proloquo2Go):** ayrı ve pahalı kategori. İleride basit "İhtiyaç Kartları" modülü bir fark yaratır.

---

## 3. Pedagojik Temel: Hatasız Öğretim ve İpucu Sistemi

Özel eğitimde yaygın yaklaşım: görev, çocuk ilk denemede doğru yapacak şekilde kurulur; yardım sonra azaltılır. Yanlış cevap tekrarlandıkça "öğrenilir", bu yüzden yanlıştan önce ipucu verilir. Bu bölüm **zorunlu** davranıştır.

### 3.1 Seçenek alanı büyüklüğü (field size)

| Kademe | Seçenek | Kullanım |
|---|---|---|
| 1 | 1 (yalnızca doğru) | Yeni kavram tanıtımı ("Bu kedi. Kediye dokun.") |
| 2 | 2 | Kolay |
| 3 | 3 | Orta (mevcut uygulama) |
| 4 | 4 | Zor |

Yeni bir temaya ilk girişte her öğe bir kez "tanıtım" aşamasıyla (kademe 1) gösterilebilir (ayarla kapatılabilir).

### 3.2 İpucu hiyerarşisi (uygulamada karşılığı)

En az yardımdan en çoğa:
1. **Sözel tekrar:** yönerge sesi tekrar çalar ("Kediyi bul").
2. **Vurgu:** doğru kart yavaşça "nefes alır" (1.0 → 1.06 ölçek, 1 sn döngü, en fazla 3 kez).
3. **Jest/model:** el ikonu doğru kartın üzerine gidip dokunma animasyonu yapar.
4. **Alanı daraltma (Notion kuralı):** yanlış seçenekler yavaşça soluklaşır (opacity 1.0 → 0.25, 600 ms) ve dokunulamaz olur; yalnızca doğru cevap belirgin kalır.

**Tetikleme kuralları (varsayılan, ayarlanabilir):**
- Yanıtsızlık: 6 sn → İpucu 1; +4 sn → İpucu 2; +4 sn → İpucu 3.
- 1. yanlış: doğru kart kendini gösterir (punch) + "bir daha dene" (mevcut davranış) → İpucu 2.
- **2. yanlış: üçüncü denemede İpucu 4** (yanlışlar soluklaşır, yalnızca doğru kalır). Böylece aşama her zaman başarıyla biter.
- İpucuyla gelen doğru cevap da **tam kutlanır**, ama raporda "ipucuyla doğru" olarak kaydedilir.

### 3.3 İpucu azaltma (fading)

- Bir öğede art arda 3 kez ipucusuz doğru → o öğe için ipucu başlangıç gecikmesi uzar (6 → 8 → 10 sn).
- Bir öğede art arda 2 kez İpucu 4'e ihtiyaç → o öğe bir sonraki turda daha az seçenekle (kademe −1) sorulur.

### 3.4 Genelleme

- Her öğe için mümkünse **2–3 farklı görsel** (farklı kedi fotoğrafları, fotoğraf + çizim). Kolay modda hep ilk görsel, Zor modda rastgele.
- Aynı öğe farklı oyun modlarında tekrar karşısına çıkar (tanı → sesini bul → gölgesini bul → grupla). Bölüm 5'teki yapının temel nedeni budur.

### 3.5 Pekiştirme

- Her doğru cevapta kısa sosyal övgü (6–10 farklı cümle: "Aferin!", "Harika!", "Çok güzel buldun!"), ardından öğenin adı.
- Tur sonu: yıldızlar + kısa tebrik; belirli sayıda tur sonra sticker.
- Para, rastgele ödül kutusu, kaybetme ekranı **yok**.

---

## 4. Tasarım Kuralları ve Stil

Uygulamanın tüm görsel dili ayrı bir dosyada, **zorunlu** tasarım sistemi olarak tanımlandı: **[tasarim-sistemi.md](tasarim-sistemi.md)**. İçeriği: tasarım kişiliği, Otsimo'dan alınan ve modernleştirilen yönler, renk tokenları (temel + 18 tema rengi + Aile Modu), tipografi (Nunito), boşluk/köşe/gölge, "dokunsal düz" buton stili, sticker kesimli fotoğraf dili, hareket ve ses tokenları, tüm bileşenler (ThemeCard, GameCard, ChoiceCard durumları, DragItem, DropZone, TopBar, StarProgress, ParentGateDialog, PaywallSheet…), opsiyonel maskot, ekran şablonları ve Flutter token sınıfları.

Özet kurallar (ayrıntı tasarım sisteminde):
- Pastel tek renk zemin, beyaz kartlar, ekranda tek odak, en fazla 4 seçenek, dekor yok.
- Dokunma alanı ≥ 96 dp, Çocuk Modu'nda yazı ≥ 20 sp.
- Kırmızı/hata rengi yok; geri bildirim hareket + ses + ikon ile.
- Animasyon 100–600 ms, aynı anda tek sürekli animasyon, kutlama Tam/Sade/Kapalı (varsayılan Sade).
- Tek, sıcak, net seslendirme; müzik varsayılan kapalı.
- Çocuk Modu'nda satın alma, ayar, dış bağlantı yok.

---

## 5. Kategori Yapısı: Beceri Alanı × Tema × Oyun

### 5.1 Üç katman ve "kaç oyun var?" sorusu

| Katman | Kim görür | Sayı | Örnek |
|---|---|---|---|
| **Tema** (içerik dünyası) | Çocuk, ana ekran | **18** | Hayvanlar, Taşıtlar, Kıyafetler |
| **Oyun** (adı olan, ayrı bir oyun) | Çocuk, tema ekranı | **66** (Bölüm 6) | Sesini Bul, Gölgesini Bul, Anne ve Yavrusu, Odalara Yerleştir |
| **Zorluk katmanı** | Çocuk/ebeveyn, tema ekranı sekmesi | **3** | Kolay / Orta / Zor (Bölüm 8) |
| **Beceri Alanı** | Ebeveyn, raporlar | **9** | Alıcı Dil, İşitsel Dikkat |

- Her **oyun**, birden çok temada oynanır. Örneğin "Sesini Bul" Hayvanlar, Taşıtlar, Müzik Aletleri, Doğa ve Evimiz temalarında ayrı ayrı vardır.
- **Oynanabilir oyun seti** = tema × oyun × zorluk. Bölüm 6.3'teki matrise göre lansman sonrası hedefte **~317 tema-oyun eşleşmesi (ekranda tıklanıp açılan oyun kartı) × 3 zorluk ≈ 950 farklı oynanabilir set** oluşur. Her sette her tur farklı öğelerle gelir (tema başına 40–50 öğe).
- Kodda oyunlar **~24 şablon** üzerine kurulur (Bölüm 6.1). Yeni oyun çoğu zaman yeni kod değil, mevcut şablona yeni bir yapılandırma ve içerik ilişkisidir (ör. "Anne ve Yavrusu" ve "Meslek ve Aracı" aynı `match_pair` şablonu).

### 5.2 Beceri alanları

| Kod | Beceri Alanı | Örnek kazanım |
|---|---|---|
| `receptive_language` | **Alıcı Dil ve Kelime** | Söyleneni resimde gösterir |
| `visual_perception` | **Görsel Algı** | Aynı/gölge/yarım/parça resmi eşleştirir, farklı olanı bulur |
| `auditory` | **İşitsel Dikkat** | Sesi kaynağıyla eşleştirir, ses sırasını hatırlar |
| `categorization` | **Kavram ve Sınıflama** | Gruplar, işlev ve ilişki kurar, zıt kavramları ayırt eder |
| `math_readiness` | **Sayılar ve Matematik Öncesi** | Sayar, karşılaştırır, sıralar, örüntü tamamlar |
| `fine_motor` | **İnce Motor** | Sürükler, yerleştirir, iz sürer, boyar |
| `memory_sequence` | **Dikkat, Hafıza ve Sıralama** | Olay sırasını kurar, kaybolanı hatırlar |
| `social_emotional` | **Sosyal-Duygusal** | Duyguları tanır, sosyal durumları anlar |
| `daily_living` | **Günlük Yaşam ve Öz Bakım** | Giyinme, rutinler, eşyaların işlevi, güvenlik |

### 5.3 Temalar

Öğe listeleri ve Kolay/Orta/Zor ayrımı: **[icerik-katalogu.md](icerik-katalogu.md)** (toplam ~650 öğe).

| # | Tema | Öğe | Faz |
|---|---|---|---|
| 1 | 🐶 Hayvanlar | 51 | 1 |
| 2 | 🍎 Meyve ve Sebzeler | 50 | 1 |
| 3 | 🎨 Renkler | 16 + 60 renkli nesne | 1 |
| 4 | 🔢 Sayılar | 0–20 | 1 |
| 5 | 🚗 Taşıtlar | 46 | 1 |
| 6 | 🔷 Şekiller | 18 + 40 nesne | 2 |
| 7 | 🥪 Yiyecek ve İçecekler | 42 | 2 |
| 8 | 👕 Kıyafet ve Aksesuarlar | 42 | 3 |
| 9 | 🏠 Evimiz | 50 | 3 |
| 10 | 🎒 Okul ve Oyuncaklar | 42 | 3 |
| 11 | 🧍 Vücudumuz | 34 | 3 |
| 12 | 😊 Duygular | 14 (×4 yüz) | 3 |
| 13 | 👩‍⚕️ Meslekler | 40 (+40 araç) | 3 |
| 14 | 🌱 Doğa ve Mevsimler | 42 | 4 |
| 15 | 🎵 Müzik Aletleri | 30 | 4 |
| 16 | 🔤 Harfler | 29 | 5 |
| 17 | 💰 Para ve Zaman | 34 | 4 |
| 18 | 📖 Hikayeler (sosyal hikaye kitapları) | 10+ kitap | 5 |

Ana ekranda Otsimo'daki gibi **tek sıra büyük tema kartları** yatay kaydırılır (telefonda 3, tablette 4 kart görünür); kartta tema adı ve "N oyun" sayacı bulunur. Ebeveyn hangi temaların görüneceğini seçebilir.

---

## 6. Oyun Kataloğu (66 oyun)

### 6.1 Şablonlar (kod)

| Şablon | Açıklama |
|---|---|
| `identify` | Hedef söylenir/gösterilir → N karttan doğruya dokun |
| `flashcards` | Kartları kaydırarak gez, dokununca adı/sesi |
| `audio_choice` | Resim gösterilir → 2–3 ses butonundan doğru sesi seç |
| `drag_to_target` | Bir öğeyi hedef alana sürükle (gölge, yarım, giydirme, yerleştirme) |
| `sort` | Öğeleri 2–3 alana grupla |
| `match_pair` | İki küme arasında ilişkili çiftleri eşleştir |
| `odd_one_out` | Gruba uymayanı bul |
| `partial_reveal` | Kısmen görünen / yakınlaştırılmış resmi tanı |
| `missing_item` | Gösterilen öğelerden kaybolanı bul |
| `puzzle` | 2–4 parçalı yapboz |
| `shape_sorter` | Şekli doğru deliğe yerleştir |
| `count` | Nesneleri say, sayıyı seç |
| `fill_count` | İstenen sayıda öğeyi sepete koy |
| `compare` | Miktar/sayı/boyut karşılaştır |
| `sequence_missing` | Dizide eksik olanı bul (sayı/örüntü) |
| `order` | Kartları doğru sıraya diz |
| `memory` | Hafıza kartları |
| `simon` | Sırayla yanan öğeleri aynı sırayla dokun |
| `trace` | Çizgi/şekil/rakam/harf izi sür |
| `coloring` | İstenen rengi seçip bölgeye dokunarak boya |
| `connect_dots` | Noktaları sırayla birleştir |
| `cause_effect` | Dokun, ses/hareket; doğru/yanlış yok |
| `build_face` | Yüze ağız/kaş parçası koyarak duygu oluştur |
| `story` | Resimli sesli hikaye + soru |

### 6.2 Oyunlar

**Faz** sütunu Bölüm 15'teki yol haritasına göredir. Kolay/Orta/Zor ayrımı tüm oyunlarda iki şeyle yapılır: (1) içerik katmanı (Kolay öğeler / Orta / Zor), (2) sunum zorluğu (Bölüm 8.2 parametreleri). Aşağıda yalnızca oyuna özel farklar yazılmıştır.

#### A. Dil ve Kelime (Alıcı Dil)

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G01 | **Tanı** (Bul bakalım) | identify | "Kedi hangisi?" → doğru resme dokun. Mevcut ana mekanik | — | 1 |
| G02 | **Kartlarla Öğren** | flashcards | Büyük kartlar sırayla gelir, dokununca adı (ve varsa sesi) çalar. Yeni öğeleri tanıtma | Kolay: 5 kart; Zor: 15 kart, otomatik geçiş kapalı | 1 |
| G03 | **Özelliğine Göre Bul** | identify | "Kırmızı olanı bul", "Büyük olanı bul", "Uçan hangisi?" | Kolay: tek özellik çok belirgin; Zor: iki özellik ("küçük kırmızı top") | 2 |
| G04 | **Bu Hangi Grupta?** | identify | Bir öğe gösterilir: "Bu bir hayvan mı, meyve mi?" 2–3 kategori ikonu | Kolay: 2 kategori; Zor: 3 ve yakın kategoriler (meyve/sebze) | 2 |
| G05 | **Ne İşe Yarar?** | identify | "Uyumak için hangisi?", "Ne ile görürüz?" | Kolay: tek doğru, uzak çeldirici; Zor: işlevi yakın çeldirici (kaşık/çatal) | 3 |
| G06 | **Kim Yapar?** | identify | "Ateşi kim söndürür?" (meslekler), "Süt veren hangisi?" (hayvanlar) | Aynı | 3 |
| G07 | **Ne Yapıyor?** | identify | Fiil resimleri: yiyor, uyuyor, koşuyor, yıkanıyor | Kolay: 6 temel fiil; Zor: 20 fiil | 4 |
| G08 | **Zıtları Bul** | match_pair | Büyük–küçük, dolu–boş, açık–kapalı, sıcak–soğuk | Kolay: 1 çift; Zor: 3 çift aynı anda | 4 |
| G09 | **Nerede?** (konum) | identify | "Kedi kutunun içinde olan hangisi?" içinde/üstünde/altında/yanında | Kolay: içinde/dışında; Zor: 4 konum | 4 |

#### B. İşitsel Dikkat

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G10 | **Sesini Bul** | identify | Yalnızca ses çalar (miyav, korna) → doğru resim | Kolay: sesleri çok farklı; Zor: benzer sesler (inek/boğa, ambulans/polis) | 1 |
| G11 | **Doğru Sesi Seç** | audio_choice | Resim gösterilir, 2–3 hoparlör butonu; dinle ve doğru sesi seç | Kolay: 2 ses; Zor: 3 ses | 2 |
| G12 | **Sesleri Sırala** | simon | 2–3 öğe sırayla ses çıkarır, çocuk aynı sırayla dokunur | Kolay: 2 öğe; Orta: 3; Zor: 4 | 4 |
| G13 | **Müzik Aleti Çal** | cause_effect | Aletlere dokunarak serbestçe çal; doğru/yanlış yok | — | 4 |

#### C. Görsel Algı

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G14 | **Aynısını Bul** | identify | Üstte resim, altta seçenekler; aynısına dokun | Kolay: birebir aynı fotoğraf; Zor: aynı nesnenin farklı fotoğrafı | 1 |
| G15 | **Gölgesini Bul** | drag_to_target | Öğeyi siluetinin üzerine sürükle | Kolay: 1 siluet; Zor: 3 siluet aynı anda | 2 |
| G16 | **Yarısını Tamamla** | drag_to_target | Yarım resmin eksik yarısını sürükle | Kolay: dikey kesim, 2 seçenek; Zor: yatay kesim, benzer renkler | 2 |
| G17 | **Farklı Olanı Bul** | odd_one_out | 3–4 öğeden gruba uymayanı bul | Kolay: 3 aynı + 1 çok farklı; Zor: aynı kategoride ince fark | 2 |
| G18 | **Saklanan Ne?** | partial_reveal | Öğenin bir kısmı çalının/perdenin arkasında; hangisi? | Kolay: %60 görünür; Zor: %25 görünür | 3 |
| G19 | **Yakından Bak** | partial_reveal | Çok yakından bir desen (zebra çizgisi, ananas kabuğu) → hangi öğe? Sonra yavaşça uzaklaşır | Kolay: 2 seçenek, hızlı uzaklaşma; Zor: 4 seçenek | 4 |
| G20 | **Yapboz** | puzzle | 2–4 parça; yanlış bırakılınca parça geri döner | Kolay 2, Orta 3, Zor 4 parça | 4 |
| G21 | **Şekil Kutusu** | shape_sorter | Şekli doğru deliğe sürükle | Kolay: 2 delik; Zor: 4 delik, döndürülmüş | 3 |
| G22 | **Parçası Nerede?** (bütün–parça) | match_pair | Tekerlek → araba, kanat → kuş, yaprak → ağaç | Kolay: 1 çift; Zor: 3 çift | 3 |

#### D. Kavram ve Sınıflama

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G23 | **Sepete Koy** | sort | Meyve sepeti / sebze sepeti, hayvan / taşıt vb. | Kolay: 2 alan, örnek resimli etiket, 4 öğe; Zor: 3 alan, 8 öğe | 2 |
| G24 | **Nerede Yaşar?** | sort | Kara / su / hava; çiftlik / orman | Aynı | 2 |
| G25 | **Kara, Hava, Deniz** | sort | Taşıtları doğru arka plana sürükle | Aynı | 2 |
| G26 | **Odalara Yerleştir** | sort | Mutfak / yatak odası / banyo | Aynı | 3 |
| G27 | **Renge Göre Grupla** | sort | Nesneleri renk kutularına | Kolay: 2 renk; Zor: 4 renk | 2 |
| G28 | **Anne ve Yavrusu** | match_pair | İnek–buzağı, tavuk–civciv | Kolay: 1 anne 2 yavru; Zor: 3–3 | 2 |
| G29 | **Ne Yer?** | match_pair | Tavşan–havuç, maymun–muz | Aynı | 3 |
| G30 | **Yuvası Hangisi?** | match_pair | Arı–kovan, kuş–yuva, köpek–kulübe | Aynı | 3 |
| G31 | **Meslek ve Aracı** | match_pair | Doktor–stetoskop, aşçı–tencere | Aynı | 3 |
| G32 | **Hangi Mevsim?** | sort | Kıyafet/nesne → yaz / kış (sonra 4 mevsim) | Kolay: 2 mevsim; Zor: 4 | 4 |

#### E. Sayılar ve Matematik Öncesi

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G33 | **Say ve Seç** | count | Nesnelere dokunarak say, "Kaç tane?" | Kolay 1–3, Orta 1–5, Zor 1–10 | 1 |
| G34 | **Rakamı Bul** | identify | "Üç hangisi?" | Kolay 1–5, Zor 0–20 | 1 |
| G35 | **Sonraki Sayı** | sequence_missing | Mevcut oyun | Kolay: son eleman eksik; Zor: ortadan eksik, 1–20 | 1 |
| G36 | **Karşılaştır** | compare | Mevcut oyun | Kolay: "Hangisi daha çok?" (nesneyle); Zor: büyük/eşit/küçük rakamla | 1 |
| G37 | **Sayı ve Miktar** | match_pair | "3" ile 3 elmalı kartı eşleştir | Kolay: 1–3; Zor: 1–10 | 2 |
| G38 | **Sepeti Doldur** | fill_count | "Sepete 3 elma koy" | Kolay 1–3; Zor 1–10 | 2 |
| G39 | **Örüntüyü Tamamla** | sequence_missing | Kırmızı–mavi–kırmızı–? ; şekil ve hayvan örüntüleri | Kolay AB; Orta AAB; Zor ABC | 3 |
| G40 | **Büyükten Küçüğe** | order | 3–4 boyutta aynı öğeyi sırala | Kolay 2; Zor 4 | 3 |

#### F. Dikkat, Hafıza ve Sıralama

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G41 | **Hafıza Kartları** | memory | Eşleri bul | Kolay 2 çift (önce açık gösterilir); Zor 6 çift | 4 |
| G42 | **Kaybolan Ne?** | missing_item | 3 öğe gösterilir, perde iner, biri kaybolur; hangisi? | Kolay 2 öğe; Zor 4 öğe | 3 |
| G43 | **Olay Sırası** | order | Tohum → yağmur → çiçek | Kolay 2–3 adım, ilk kart hazır; Zor 4 adım | 4 |
| G44 | **Günlük Rutin** | order | El yıkama, diş fırçalama, sabah rutini | Aynı | 4 |

#### G. İnce Motor

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G45 | **İz Sür** | trace | Düz çizgi → eğri → daire | Kolay: kalın yol, geniş tolerans | 4 |
| G46 | **Rakam Yaz** | trace | Rakamların üzerinden geç (ok yönleriyle) | Kolay 1–3; Zor 0–9 | 5 |
| G47 | **Boya** | coloring | "Elmayı kırmızıya boya": rengi seç, bölgeye dokun (tek dokunuşla dolar) | Kolay: 1 bölge; Zor: 3 bölge | 4 |
| G48 | **Noktaları Birleştir** | connect_dots | 3–8 nokta, sonunda resim ortaya çıkar ve adı söylenir | Kolay 3; Zor 8 | 5 |

#### H. Sosyal-Duygusal

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G49 | **Duyguyu Bul** | identify | "Mutlu olan hangisi?" | Kolay: mutlu/üzgün abartılı; Zor: 7 duygu, ince ifade | 3 |
| G50 | **Nasıl Hisseder?** | identify | Durum resmi → duygu yüzü | Kolay 2 duygu; Zor 4 | 3 |
| G51 | **Yüz Yap** | build_face | Boş yüze ağız ve kaş sürükleyerek istenen duyguyu yap | Kolay: yalnızca ağız; Zor: ağız + kaş | 4 |
| G52 | **Sosyal Hikayeler** | story | Doktora gidiyorum, sırada beklerim… | — | 5 |

#### I. Günlük Yaşam

| # | Oyun | Şablon | Nasıl oynanır | Oyuna özel zorluk | Faz |
|---|---|---|---|---|---|
| G53 | **Giydir** | drag_to_target | Silüete kıyafet giydir; "Kar yağıyor, ne giyelim?" | Kolay: 1 parça; Zor: mevsime göre 3 parça | 3 |
| G54 | **Güvenli mi?** | sort | Güvenli / dikkat (sıcak ocak, makas, priz) iki alan | Kolay: 2 öğe; Zor: 6 | 5 |

#### J. Keşif ve Rahatlama

| # | Oyun | Şablon | Nasıl oynanır | Faz |
|---|---|---|---|---|
| G55 | **Dokun-Keşfet** | cause_effect | Her temada 4–6 öğe; dokununca adı/sesi, hafif hareket. Doğru/yanlış, yıldız yok. İlk oturum ve en küçükler için | 1 |
| (özellik) | **Sakin Köşe** | — | Tek büyük yuvarlak "nefes" balonu yavaşça büyür/küçülür, yumuşak ses. Oyun değil, her ekrandan değil, tema ekranından ve Aile Modu'ndan açılır | 3 |

#### K. Otsimo ekranlarından eklenenler (v3.1)

| # | Oyun | Şablon | Nasıl oynanır | Temalar | Faz |
|---|---|---|---|---|---|
| G56 | **Bozuk Paraları Tanı** | identify / match_pair | 5, 10, 25, 50 kuruş ve 1 TL; "1 lira hangisi?" ve aynı parayı eşleştir | Para ve Zaman | 4 |
| G57 | **Kağıt Paraları Tanı** | identify / match_pair | 5–200 TL banknotlar; Zor: "Hangisi daha çok?" | Para ve Zaman | 4 |
| G58 | **Saati Kur** | `clock_set` (yeni) | Akrebi/yelkovanı sürükleyerek tam saati kur; Kolay: yalnızca akrep, tam saatler; Zor: buçuklar | Para ve Zaman | 4 |
| G59 | **Hava Durumu** | identify + match_pair | Hava durumunu tanı; hava → kıyafet/eşya eşleştir (yağmur → şemsiye) | Doğa, Kıyafetler | 4 |
| G60 | **Duyuları Eşleştir** | match_pair | Göz → görmek (resim), kulak → duymak (zil sesi), burun → koklamak (çiçek) | Vücudumuz | 3 |
| G61 | **Nasıl Bir?** (sıfatlar) | identify | "Islak olan hangisi?", "Uzun olan hangisi?", "Sıcak olan?" | Hayvanlar, Yiyecekler, Kıyafetler, Evimiz | 4 |
| G62 | **Yer ve Yön** | identify | Sağ/sol, yukarı/aşağı, ön/arka; "Ağacın solundaki hangisi?" | Evimiz, Okul, Hayvanlar | 4 |
| G63 | **Kendi Yapbozunu Yap** | puzzle | Ebeveyn bir aile fotoğrafı seçer (Aile Modu'nda, yalnızca cihazda kalır, buluta gitmez), 2–4 parçalı yapboz olur | Tüm temalar dışı, "Ailem" özel kartı | 4 |
| G64 | **Birlikte Sayalım** | count (şarkılı) | Yavaş tempolu sayma tekerlemesi eşliğinde nesneler tek tek belirir, çocuk dokundukça sayılır; doğru/yanlış yok | Sayılar | 2 |
| G65 | **Emojileri Eşleştir** | match_pair | Gerçek yüz fotoğrafını aynı duygudaki sade emoji/simgeyle eşleştir | Duygular | 3 |
| G66 | **Kelime Kur** | drag_to_target | Resmi verilen 3–4 harfli kelimenin harflerini sıraya diz (top, kedi) | Harfler | 5 |

### 6.5 Oyun adlandırma kuralı

Otsimo'daki gibi tutarlı fiil kalıpları kullanılır; çocuk ve ebeveyn oyunun ne yaptığını addan anlar. Ekranda görünen ad = `{İçerik} + {fiil}`:

| Şablon/oyun | Ad kalıbı | Örnek |
|---|---|---|
| G02 Kartlarla Öğren | **"{X} Öğren"** | Hayvanları Öğren, Taşıtları Öğren |
| G01 Tanı | **"{X} Bul"** | Hayvanları Bul, Renkleri Bul |
| G14 Aynısını Bul / match_pair | **"{X} Eşleştir"** | Hayvanları Eşleştir, Meslek ve Aracını Eşleştir |
| G10 Sesini Bul | **"{X} Seslerini Bul"** | Hayvan Seslerini Bul |
| G15 Gölgesini Bul | **"{X} Gölgeleri"** | Taşıt Gölgeleri |
| G20 Yapboz | **"{X} Yapbozu"** | Meyve Yapbozu |
| G41 Hafıza | **"{X} Hafıza Kartları"** | Şekiller Hafıza Kartları |
| G23 Sepete Koy | **"{X} Grupla"** | Meyve mi Sebze mi? (özel adlar serbest) |
| G13 Müzik | **"{Alet} Çal"** | Ksilofon Çal |

Oyun kartı illüstrasyonu da kalıba uyar: "Öğren" kartlarında tek büyük öğe, "Eşleştir" kartlarında iki öğe ve aralarında ok, "Bul" kartlarında öğe + soru işareti.

### 6.3 Tema × Oyun matrisi

✅ = o temada var. Hangi fazda geleceği, oyunun fazı ile temanın fazından büyük olanıdır. G56–G66 ve Para ve Zaman / Hikayeler temaları için tema listesi yukarıdaki K tablosundadır.

| Oyun | Hay | Mey | Yiy | Ren | Şek | Say | Taş | Kıy | Ev | Okul | Vüc | Duy | Mes | Doğ | Müz | Har |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| G01 Tanı | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | ✅ | ✅ |
| G02 Kartlarla Öğren | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| G03 Özelliğine Göre | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | | ✅ | | | | ✅ | | |
| G04 Hangi Grupta | ✅ | ✅ | ✅ | | | | ✅ | ✅ | ✅ | ✅ | | | | | ✅ | |
| G05 Ne İşe Yarar | | | ✅ | | | | ✅ | ✅ | ✅ | ✅ | ✅ | | | ✅ | | |
| G06 Kim Yapar | ✅ | | | | | | ✅ | | | | | | ✅ | | | |
| G07 Ne Yapıyor | ✅ | | | | | | | | | | ✅ | | ✅ | | | |
| G08 Zıtları Bul | ✅ | | ✅ | | ✅ | | | | ✅ | ✅ | | | | ✅ | | |
| G09 Nerede | ✅ | | | | | | | | ✅ | ✅ | | | | | | |
| G10 Sesini Bul | ✅ | | | | | ✅ | ✅ | | ✅ | ✅ | | ✅ | | ✅ | ✅ | ✅ |
| G11 Doğru Sesi Seç | ✅ | | | | | | ✅ | | ✅ | | | ✅ | | ✅ | ✅ | |
| G12 Sesleri Sırala | ✅ | | | | | | ✅ | | | | | | | | ✅ | |
| G13 Müzik Aleti Çal | | | | | | | | | | | | | | | ✅ | |
| G14 Aynısını Bul | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | | ✅ | ✅ | ✅ |
| G15 Gölgesini Bul | ✅ | ✅ | ✅ | | ✅ | | ✅ | ✅ | ✅ | ✅ | | | | ✅ | ✅ | |
| G16 Yarısını Tamamla | ✅ | ✅ | ✅ | | ✅ | | ✅ | ✅ | ✅ | ✅ | | | | | ✅ | |
| G17 Farklı Olanı Bul | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | | ✅ | ✅ | ✅ |
| G18 Saklanan Ne | ✅ | ✅ | ✅ | | | | ✅ | ✅ | ✅ | ✅ | | | | | ✅ | |
| G19 Yakından Bak | ✅ | ✅ | ✅ | | | | ✅ | | ✅ | | | | | ✅ | | |
| G20 Yapboz | ✅ | ✅ | ✅ | | | | ✅ | ✅ | ✅ | ✅ | | | ✅ | ✅ | ✅ | |
| G21 Şekil Kutusu | | | | | ✅ | | | | | | | | | | | |
| G22 Parçası Nerede | ✅ | ✅ | | | | | ✅ | | ✅ | | ✅ | | | ✅ | | |
| G23 Sepete Koy | ✅ | ✅ | ✅ | | ✅ | | ✅ | ✅ | ✅ | ✅ | | | | ✅ | ✅ | |
| G24 Nerede Yaşar | ✅ | | | | | | | | | | | | | | | |
| G25 Kara-Hava-Deniz | | | | | | | ✅ | | | | | | | | | |
| G26 Odalara Yerleştir | | | | | | | | | ✅ | | | | | | | |
| G27 Renge Göre Grupla | | ✅ | | ✅ | | | ✅ | ✅ | | ✅ | | | | | | |
| G28 Anne ve Yavrusu | ✅ | | | | | | | | | | | | | | | |
| G29 Ne Yer | ✅ | | | | | | | | | | | | | | | |
| G30 Yuvası Hangisi | ✅ | | | | | | | | | | | | | | | |
| G31 Meslek ve Aracı | | | | | | | | | | | | | ✅ | | | |
| G32 Hangi Mevsim | | ✅ | | | | | | ✅ | | | | | | ✅ | | |
| G33 Say ve Seç | ✅ | ✅ | ✅ | | ✅ | ✅ | ✅ | | | ✅ | | | | | | |
| G34 Rakamı Bul | | | | | | ✅ | | | | | | | | | | |
| G35 Sonraki Sayı | | | | | | ✅ | | | | | | | | | | |
| G36 Karşılaştır | ✅ | ✅ | | | ✅ | ✅ | ✅ | | | | | | | | | |
| G37 Sayı ve Miktar | | | | | | ✅ | | | | | | | | | | |
| G38 Sepeti Doldur | | ✅ | ✅ | | | ✅ | | | | ✅ | | | | | | |
| G39 Örüntü | ✅ | ✅ | | ✅ | ✅ | ✅ | ✅ | | | | | | | | | |
| G40 Büyükten Küçüğe | ✅ | ✅ | | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | | | | | |
| G41 Hafıza Kartları | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅ |
| G42 Kaybolan Ne | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | ✅ | ✅ | | | | ✅ | ✅ | |
| G43 Olay Sırası | ✅ | ✅ | ✅ | | | | | | | | | | | ✅ | | |
| G44 Günlük Rutin | | | | | | | | ✅ | ✅ | | ✅ | | | | | |
| G45 İz Sür | | | | | ✅ | | | | | | | | | | | |
| G46 Rakam Yaz | | | | | | ✅ | | | | | | | | | | ✅ |
| G47 Boya | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | | ✅ | | | | ✅ | | |
| G48 Noktaları Birleştir | ✅ | ✅ | | | ✅ | ✅ | ✅ | | | | | | | ✅ | | |
| G49 Duyguyu Bul | | | | | | | | | | | | ✅ | | | | |
| G50 Nasıl Hisseder | | | | | | | | | | | | ✅ | | | | |
| G51 Yüz Yap | | | | | | | | | | | | ✅ | | | | |
| G52 Sosyal Hikayeler | | | | | | | | | | | | ✅ | | | | |
| G53 Giydir | | | | | | | | ✅ | | | ✅ | | | ✅ | | |
| G54 Güvenli mi | | | | | | | | | ✅ | ✅ | | | | | | |
| G55 Dokun-Keşfet | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### 6.4 Oyun kartının tema ekranındaki sırası

Tema ekranında oyunlar şu mantıkla sıralanır (ebeveyn sabitleyebilir):
1. **Kartlarla Öğren** ve **Dokun-Keşfet** (tanıtım) her zaman ilk iki kart.
2. Sonra **Tanı**, **Aynısını Bul**, **Sesini Bul** (temel tanıma).
3. Sonra öneri motorunun (Bölüm 8.3) çocuğa uygun gördüğü oyunlar.
4. Kilitli (Premium) oyunlar en sonda.

Bir tema ekranında aynı anda en fazla 12 oyun kartı görünür; daha fazlası "Daha fazla oyun" sayfasına taşınır (az uyaranlı ekran kuralı).

---

## 7. İçerik

Tüm öğe listeleri, gruplar, ilişki listeleri (anne–yavru, meslek–araç, işlev soruları), olay sıraları ve sosyal hikaye başlıkları: **[icerik-katalogu.md](icerik-katalogu.md)**.

Önemli kurallar:
- Somut temalarda **40–50 öğe**, üç katmana bölünmüş (Kolay ≈ 15, Orta ≈ 15, Zor ≈ 15–20).
- Katman = öğenin **tanıdıklığı** (kedi Kolay, zürafa Orta, bukalemun Zor).
- Her katman ~8'lik **bölümlere** ayrılır: Kolay = Bölüm 1–2, Orta = Bölüm 3–4, Zor = Bölüm 5–6. (Notion'daki "her tema için 5 seviye" kararını karşılar ve aşar.)
- Kolay ve Orta öğelerde öğe başına 2–3 görsel (genelleme).
- Unity'deki 30 hayvan + 19 hazır hayvan, 30 meyve-sebze, 11 renk ve sayı içerikleri olduğu gibi taşınır ve katmanlara dağıtılır.
- Seslendirmede öğe adı ve soru kalıbı ayrı dosyalardır ("Kedi" + "… hangisi?"), böylece 600 öğe için 600 ad dosyası + birkaç düzine kalıp yeterlidir.

---

## 8. Zorluk Sistemi

### 8.1 Zorluk iki şeyi birlikte değiştirir

| | Kolay | Orta | Zor |
|---|---|---|---|
| **İçerik katmanı** (hangi öğeler) | Kolay öğeler (kedi, elma, araba) | Kolay + Orta öğeler | Tüm öğeler, Zor ağırlıklı |
| **Sunum** (nasıl soruluyor) | Bölüm 8.2 Kolay sütunu | Orta | Zor |

- Varsayılan olarak ikisi birlikte hareket eder (çocuk "Zor" sekmesine geçince hem zor hayvanlar gelir hem seçenek sayısı artar).
- Ebeveyn ayarında ayrılabilir: "İçerik: Zor, Sunum: Kolay" (ör. çok hayvan bilen ama motor güçlüğü olan çocuk).
- Orta ve Zor'da, çocuğun hâlâ hata yaptığı Kolay öğeler aralıklı tekrar ile arada sorulmaya devam eder.

### 8.2 Sunum parametreleri

| Parametre | Kolay | Orta | Zor |
|---|---|---|---|
| Seçenek sayısı | 2 | 3 | 4 |
| Çeldirici | Farklı temadan / çok farklı | Aynı temadan, farklı grup | Aynı grup, benzer |
| İpucu 1 gecikmesi | 4 sn | 6 sn | 8 sn |
| Görsel | Ana görsel | Ana görsel | Rastgele varyasyon |
| Sürükleme mıknatıs yarıçapı | Hedefin %60'ı | %45 | %30 |
| Tur uzunluğu | 4 aşama | 5 aşama | 6 aşama |
| Yazı | Görünür | Görünür | Ayara bağlı |

Oyuna özel farklar Bölüm 6.2'de.

### 8.3 Zorluk nasıl belirlenir? (Notion: "kullanıcıya sorulacak")

1. **Başlangıç:** profil anketinden (Bölüm 9.3) tema ve beceri alanı bazında başlangıç zorluğu.
2. **Çocuk/ebeveyn seçimi:** tema ekranındaki **Kolay / Orta / Zor** sekmeleri. Ebeveyn bu sekmeleri Çocuk Modu'nda gizleyebilir ("Zorluğu ben seçerim" veya "Otomatik").
3. **Otomatik öneri (varsayılan açık):** profil × oyun × tema için son 10 aşama:
   - İpucusuz doğruluk ≥ %80 ve İpucu 3–4 ≤ %10 → bir üst zorluk önerilir (sekmede küçük yıldız), "Otomatik" moddaysa bir sonraki turda geçilir.
   - İpucusuz doğruluk < %50 veya İpucu 4 > %30 → bir alt zorluk.
   - Değişiklik yalnızca tur aralarında.
4. **Bölüm ilerlemesi:** bir katmanın bölümleri sırayla açılır gibi görünür ama kilitli değildir (Premium'da). Bölümdeki öğelerin %80'i "öğrenildi" (son 3 karşılaşmada ipucusuz doğru) olunca sonraki bölüm önerilir.

### 8.4 Aralıklı tekrar

Profil × öğe başarı skoru tutulur. Sık hata yapılan öğeler daha sık hedef olur; aynı turda art arda aynı hedef olmaz; öğrenilmiş öğeler arada bir tekrar sorulur. Aynı öğe farklı oyunlarda karşısına çıktığında skor ortak tutulur (kediyi "Tanı"da biliyor ama "Sesini Bul"da bilmiyorsa ikisi ayrı beceri skoru, tek öğe skoru).

---

## 9. Profil, Başlangıç Anketi ve Aile/Çocuk Modu

### 9.1 Kavramlar (Notion: `Users` → `ChildProfiles`)

- **Aile (ebeveyn) hesabı:** opsiyonel. Giriş yapılmadan da uygulama tam çalışır (yerel mod). Giriş yalnızca **Aile Modu** içinde, Google ile (mevcut Firebase projesi kullanılabilir). Amaç: cihaz değişince verinin kaybolmaması ve aboneliğin birden fazla cihazda görünmesi.
- **Çocuk profili:** takma ad, avatar (hazır hayvan ikonlarından), yaş aralığı, anket cevapları, ayarlar, ilerleme.
- Ücretsiz: 1 profil. Premium: 5 profil.

### 9.2 İlk açılış akışı (Notion: "Profil hiç yoksa Profil Oluştur açılsın")

```
Açılış
 └─ Profil yok mu?
     ├─ Evet → Aile karşılama (3 kısa sayfa: uygulama ne yapar, reklam yok, ebeveyn kilidi nedir)
     │        → [opsiyonel] Google ile giriş ("Şimdi değil" belirgin)
     │        → Çocuk profili oluştur (takma ad + avatar)
     │        → Başlangıç anketi (9.3, atlanabilir)
     │        → Önerilen temalar ekranı
     │        → [Ücretsiz deneme teklifi, atlanabilir]
     │        → Çocuk Modu
     └─ Hayır → Son kullanılan profil ile Çocuk Modu (birden çok profil varsa avatar seçim ekranı)
```

### 9.3 Başlangıç anketi (Notion: "Yaş, konuşabiliyor mu, araçları biliyor mu…")

Kurallar: tek ekranda tek soru, büyük butonlar, her soru atlanabilir, ilerleme çubuğu, toplam ≤ 10 soru, sonradan Aile Modu'ndan değiştirilebilir. Tanı sorusu **sorulmaz** (hassas sağlık verisi; Families ve KVKK açısından risk).

| # | Soru | Cevaplar | Etkisi |
|---|---|---|---|
| 1 | Çocuğunuzun yaşı? | 2–3 / 4–5 / 6–7 / 8+ | Varsayılan zorluk, tema sırası |
| 2 | Konuşma durumu? | Henüz konuşmuyor / Tek kelimeler / Kısa cümleler / Akıcı | Yazı varsayılanı; "Dokun-Keşfet" ve Kolay ile başlama |
| 3 | Söylenen bir nesneyi resimde gösterebiliyor mu? | Henüz değil / Bazen / Evet | `receptive_language` başlangıç zorluğu; "Henüz değil" → tanıtım aşamaları açık + Kolay |
| 4 | Ekrana dokunup sürükleyebiliyor mu? | Zorlanıyor / Biraz / Rahat | Sürükleme modlarında "Dokunarak seç" alternatifi açık/kapalı, mıknatıs yarıçapı |
| 5 | Seslere karşı hassas mı? | Evet / Biraz / Hayır | Kutlama yoğunluğu (Kapalı/Sade/Tam), efekt seviyesi, müzik |
| 6 | Bir oyuna ne kadar odaklanabiliyor? | 1–2 dk / 3–5 dk / 5+ dk | Tur uzunluğu (3/5/8) |
| 7 | Hangilerini tanıyor? (çoklu seçim) | Hayvanlar, Meyveler, Renkler, Sayılar, Taşıtlar, Şekiller, Kıyafetler, Ev eşyaları, Vücut, Duygular | Seçilen temalar Orta'dan, seçilmeyenler Kolay'dan başlar; seçilmeyenler "önerilen" listesine |
| 8 | Saymayı biliyor mu? | Henüz değil / 1–5 / 1–10 / 10+ | Sayılar teması başlangıç seviyesi |
| 9 | En çok neyi seviyor? (çoklu) | Hayvanlar, Taşıtlar, Müzik, Yemekler… | Ana ekranda bu temalar başa |
| 10 | Hangi dilde? | Türkçe / English | Ses ve yazı dili |

Sonuç ekranı: "Önerilen başlangıç: Hayvanlar (Kolay), Taşıtlar (Kolay), Renkler (Orta)…" ve "Değiştir" butonu.

### 9.4 Aile Modu ↔ Çocuk Modu (Notion: "Sol üstte Switch to Family / Switch to Child")

- **Çocuk Modu'ndan Aile Modu'na:** sol üstte küçük, sade bir "ebeveyn" ikonu. **2 sn basılı tutma** + ebeveyn kilidi (rastgele çarpma sorusu, ör. "7 × 6 = ?" sayı tuş takımıyla, ya da ebeveynin belirlediği 4 haneli PIN). Yanlışta tekrar sorar, kilitlenme yok.
- **Aile Modu'ndan Çocuk Modu'na:** sol üstte belirgin "Çocuk Moduna Geç" butonu, kilit gerekmez. Birden fazla profil varsa avatar seçimi.
- Aile Modu'nda 5 dakika işlem yoksa otomatik Çocuk Modu'na döner.
- Kilit korur: ayarlar, satın alma, profil yönetimi, raporlar, dış bağlantılar, veri silme, oturum açma/kapama.

### 9.5 Veri saklama (Notion: "JSON'a kaydet, Firebase'e gönder")

- **Önce cihaz:** tüm profil, anket ve ilerleme verisi yerel veritabanında (drift/SQLite). Uygulama çevrimdışı tam çalışır.
- **Sonra bulut (yalnızca aile girişi yapılmışsa):** Cloud Firestore'a senkron.

```
families/{uid}
  createdAt, locale
  profiles/{profileId}
    nickname, avatarId, ageRange, survey{...}, settings{...}, createdAt, updatedAt
    progress/{modeId_themeId_level}   // özet: zorluk, son skorlar
    itemStats/{itemId}                 // öğe bazlı doğru/yanlış/ipucu sayaçları
    sessions/{sessionId}               // günlük özet; ham aşama logları değil
```
- Senkron: son yazan kazanır, belge bazında `updatedAt`. Ham aşama kayıtları (Bölüm 10.1) cihazda tutulur; buluta yalnızca **günlük özetler** gider (veri minimizasyonu).
- Firestore güvenlik kuralları: kullanıcı yalnızca `families/{kendi uid}` altını okuyup yazabilir. Abonelik durumu burada tutulmaz; her cihaz Google Play'den okur (Bölüm 13.3).
- Hesap silme: Aile Modu'nda "Hesabımı ve verilerimi sil" + web üzerinden silme talebi sayfası (Play zorunluluğu).
- Mevcut Unity'deki Realtime Database test kodu ve `testData` yapısı taşınmaz.

---

## 10. Raporlama ve Veri Toplama

### 10.1 Aşama kaydı (cihazda)

```dart
class TrialLog {
  final String profileId;
  final String themeId, modeId;
  final int level;
  final Difficulty difficulty;
  final String targetItemId;
  final List<String> selectedItemIds; // sırayla tüm dokunuşlar
  final bool correctFirstTry;
  final int wrongCount;
  final int maxHintLevel;     // 0..4
  final int latencyMs;        // yönerge bitişinden ilk dokunuşa
  final int idleMs;           // aşama içindeki toplam tepkisiz süre (Notion: "ekrana ne kadar tepkisiz kaldı")
  final DateTime at;
}
```
- `idleMs`: son dokunuştan veya yönergenin bitişinden itibaren 3 sn'yi aşan sessizliklerin toplamı.
- Ayrıca oturum kaydı: başlangıç-bitiş, oynanan modlar, yarıda bırakılan turlar.

### 10.2 Ebeveyn raporu ekranları (Notion: "bar veya çizgi grafikler")

| Görünüm | İçerik | Grafik |
|---|---|---|
| Bugün | Oynama süresi, tamamlanan tur, kazanılan yıldız | Kartlar |
| Haftalık | Gün gün oynama süresi; gün gün ipucusuz doğruluk | Çubuk + çizgi |
| Beceri alanları | 9 alan için ipucusuz doğruluk ve eğilim (↑↓) | Yatay çubuk |
| Temalar | Tema bazında ilerleme (seviye, zorluk) | Liste + ilerleme çubuğu |
| Öğeler | "Öğrendikleri" ve "Zorlandıkları" listesi (öğe bazlı başarı) | Resimli liste |
| Dikkat | Ortalama tepki süresi ve tepkisiz süre trendi | Çizgi |

- Ücretsiz: son 7 gün, Bugün + Haftalık. Premium: tüm geçmiş, tüm görünümler, PDF dışa aktarma (öğretmen/terapistle paylaşmak için, yalnızca Aile Modu'nda).
- Haftalık özet yerel bildirim (varsayılan kapalı, ebeveyn açar).
- Grafik kütüphanesi: `fl_chart`. Sakin renkler, en fazla 2 seri.

### 10.3 Ürün analitiği (geliştirici için)

- Notion'da GameAnalytics kurulmuştu; **Flutter'da üçüncü taraf analitik/reklam SDK'sı kullanılmaz** (Families riski). İhtiyaç olursa:
  - Firebase Crashlytics (çökme raporları, kişisel veri yok).
  - Ürün metrikleri: yalnızca aile hesabı olanların anonim günlük özetlerinden, Firestore üzerinden toplu sorgu.
  - Firebase Analytics çocuk ayarlarıyla (reklam kimliği ve kişiselleştirme kapalı, sabit ve anonim olay listesi, ebeveyn kapatabilir). Ayrıntı ve olay listesi: Bölüm 12.8.

---

## 11. Uygulama Ekranları

```
Çocuk Modu
 ├─ Profil seçimi (birden fazla profil varsa; avatarlar)
 ├─ Ana ekran: tema kartları (2×3 / 3×4 ızgara; tablette daha fazla)
 │    ├─ "Bugün ne oynasak?" kartı (öğrenme yolundan 1 öneri) [opsiyonel]
 │    └─ [Sol üst: ebeveyn ikonu, basılı tut]
 ├─ Tema ekranı: Kolay/Orta/Zor sekmeleri + oyun kartları (ikon + ad, seslendirilir, en iyi tur yıldızı)
 │    └─ Oyun ekranı → Tur sonu (yıldız, tebrik) → Tekrar / Sonraki / Temaya dön
 └─ Sticker albümü
Aile Modu
 ├─ [Sol üst: Çocuk Moduna Geç]
 ├─ Raporlar (Bölüm 10.2)
 ├─ Profiller (ekle, düzenle, anketi yeniden yap, sil)
 ├─ Oyun ayarları (profil bazlı; Bölüm 11.2)
 ├─ Görünen temalar ve modlar
 ├─ Abonelik (Premium, deneme, yönet/iptal, geri yükle)
 ├─ Hesap (Google ile giriş/çıkış, senkron durumu, hesabı sil)
 ├─ Dil, ses, erişilebilirlik
 └─ Hakkında: gizlilik politikası, koşullar, destek e-postası, "Uzman desteğinin yerini tutmaz" notu
```

### 11.1 Oyun ekranı

```
┌──────────────────────────────────────────────┐
│ [←]           ★ ★ ☆ ☆ ☆               [🔊]  │
│                                              │
│        Yönerge görseli / hedef alanı         │
│                                              │
│     ┌──────┐    ┌──────┐    ┌──────┐         │
│     │      │    │      │    │      │         │
│     └──────┘    └──────┘    └──────┘         │
└──────────────────────────────────────────────┘
```
- Yatay ve dikey; tablet öncelikli. Geri: 1 sn basılı tut.
- Uygulama arka plana geçerse ses durur; dönüşte aynı aşamanın yönergesi tekrar çalar.

### 11.2 Ebeveyn ayarları (profil bazlı)

| Ayar | Seçenekler | Varsayılan |
|---|---|---|
| Zorluk | Otomatik / Kolay / Orta / Zor (genel veya tema bazlı) | Otomatik (anketten başlar) |
| Tur uzunluğu | 3 / 5 / 8 / 10 | Anket / 5 |
| İpucu başlangıcı | 4 / 6 / 10 sn / Kapalı | Zorluğa göre |
| "2 yanlıştan sonra yanlışları soluklaştır" | Açık / Kapalı | Açık |
| Tanıtım aşamaları (tek seçenek) | Açık / Kapalı | Anket |
| Kutlama | Tam / Sade / Kapalı | Sade |
| Yazıyı göster | Açık / Kapalı | Açık |
| Sürükleme yerine dokunarak seç | Açık / Kapalı | Anket |
| Konuşma / Efekt / Müzik | 0–100 | 100 / 60 / 0 |
| Görsel stili | Fotoğraf / Çizim (içerik varsa) | Fotoğraf |
| Ekran süresi sınırı | Kapalı / 10 / 15 / 20 / 30 dk | Kapalı |

Süre dolunca: yumuşak "Bugünlük bu kadar, harikaydın!" ekranı; uzatma ebeveyn kilidiyle.

---

## 12. Flutter Mimarisi

### 12.1 Teknoloji seçimi

| Konu | Öneri | Not |
|---|---|---|
| Flutter / Dart | Stable güncel, Dart 3 | |
| Durum yönetimi | `flutter_riverpod` + `riverpod_generator` | |
| Yönlendirme | `go_router` | Aile Modu redirect'i ile kilit kontrolü |
| Oyun ekranları | Düz Flutter widget'ları | Flame gerekmez. Sürükle-bırak: `Draggable`/`DragTarget` veya özel `GestureDetector`; yapboz ve iz sürme için `CustomPainter` |
| Animasyon | `flutter_animate` | Süreler merkezi `MotionTokens`'tan |
| Parçacık | Basit özel `CustomPainter` (≤ 20 parçacık) | Ağır paket yok |
| Ses | `just_audio` (konuşma kuyruğu) + `soundpool`/`audioplayers` (kısa efektler) | |
| Yerel veri | `drift` (SQLite) | Profiller, loglar, ilerleme |
| Bulut | `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`, `firebase_crashlytics`, `firebase_analytics`, `firebase_storage`, `firebase_app_check` | Ayar ve içerik paketleri herkes için; aile senkronu yalnızca giriş sonrası. Bölüm 12.8 |
| Satın alma | `in_app_purchase` | Bölüm 13 |
| Grafik | `fl_chart` | |
| Yerelleştirme | `flutter_localizations` + `gen-l10n` (ARB) | İçerik adları JSON'da |
| Modeller | `freezed`, `json_serializable` | |
| PDF rapor | `pdf` + `printing` | Faz 2 |
| Test | `flutter_test`, golden testler, `integration_test` | |

### 12.2 Klasör yapısı

```
lib/
  main.dart
  app/
    app.dart, router.dart
    ui/                               # tasarim-sistemi.md bileşenleri (SegButton, ThemeCard, ChoiceCard…)
    theme/ colors.dart typography.dart motion.dart spacing.dart
  core/
    audio/audio_service.dart          # sıralı kuyruk, iptal, ducking, ön yükleme
    content/
      models/                         # Theme, Item, ModeSpec, LevelSpec, Pair, Question
      content_repository.dart         # assets/content/*.json
    db/app_database.dart              # drift
    sync/firestore_sync.dart
    auth/family_auth.dart
    entitlement/entitlement_service.dart, billing_repository.dart
    learning/
      difficulty_engine.dart          # 8.3
      item_scheduler.dart             # 8.4
      hint_policy.dart                # 3.2–3.3
      survey_mapper.dart              # 9.3 → başlangıç ayarları
  features/
    onboarding/ (welcome, survey, recommendations)
    profiles/
    child_home/ theme_home/
    game/
      game_shell.dart                 # üst bar, yıldızlar, tekrar dinle, tur akışı
      round_controller.dart           # ortak tur mantığı, iptal edilebilir oturum kimliği
      hint_controller.dart
      widgets/ choice_card.dart star_progress.dart celebration.dart drag_item.dart drop_zone.dart
      templates/                      # Bölüm 6.1'deki 24 şablon
        identify/ flashcards/ audio_choice/ drag_to_target/ sort/ match_pair/
        odd_one_out/ partial_reveal/ missing_item/ puzzle/ shape_sorter/
        count/ fill_count/ compare/ sequence_missing/ order/ memory/ simon/
        trace/ coloring/ connect_dots/ cause_effect/ build_face/ story/
      games/games.json                # 66 oyunun tanımı: id, ad, şablon, parametreler, beceri alanları, faz
    reward/ sticker_album/
    family/
      gate/ dashboard/ reports/ settings/ subscription/ account/ about/
  l10n/ app_tr.arb app_en.arb
assets/
  content/
    themes.json
    items/{theme}.json
    pairs/*.json  questions/*.json  sequences/*.json
  images/{theme}/...
  audio/{lang}/{theme}/...
  audio/{lang}/prompts/...
  sfx/{theme}/...
  LICENSES.md
```

### 12.3 İçerik şeması

```json
// assets/content/items/animals.json
{
  "id": "animals.giraffe",
  "theme": "animals",
  "tier": "medium",        // easy | medium | hard (icerik-katalogu.md)
  "chapter": 3,            // 1–2 easy, 3–4 medium, 5–6 hard
  "tags": ["vahsi", "kara"],
  "name": { "tr": "Zürafa", "en": "Giraffe" },
  "images": ["images/animals/giraffe_1.webp", "images/animals/giraffe_2.webp"],
  "audio": { "tr": "audio/tr/animals/giraffe.mp3", "en": "audio/en/animals/giraffe.mp3" },
  "sfx": null
}
```

```json
// assets/content/themes.json
{
  "id": "animals",
  "name": { "tr": "Hayvanlar", "en": "Animals" },
  "icon": "images/themes/animals.webp",
  "palette": { "bg": "#EAF4EC", "accent": "#6BAA75", "deep": "#4F8A59" },
  "games": [
    { "game": "G01", "free": { "tier": "easy", "chapters": [1] } },
    { "game": "G10", "requires": ["sfx"] },
    { "game": "G15" },
    { "game": "G24", "params": { "groups": [["kara","su","hava"], ["ciftlik","vahsi"]] } },
    { "game": "G28", "pairs": "pairs/animal_baby.json" },
    { "game": "G55", "free": true }
  ]
}
```

```json
// lib/features/game/games/games.json (bir oyun tanımı)
{
  "id": "G28",
  "name": { "tr": "Anne ve Yavrusu", "en": "Mom and Baby" },
  "template": "match_pair",
  "icon": "icons/games/mom_baby.svg",
  "skills": ["categorization"],
  "difficulty": {
    "easy":   { "owners": 1, "candidates": 2 },
    "medium": { "owners": 2, "candidates": 2 },
    "hard":   { "owners": 3, "candidates": 3 }
  },
  "prompts": { "intro": "prompt.find_baby" }
}
```
- Bir oyun, gereken verisi (ör. `sfx`, `pairs`) olmayan öğeleri otomatik dışarıda bırakır; o katmanda yeterli öğe yoksa oyun o temada gizlenir.
- Yeni oyun eklemek: `games.json`'a tanım + (gerekirse) yeni şablon + temaların `games` listesine ekleme.

### 12.4 Şablon sözleşmesi

```dart
abstract class GameTemplate {
  String get id;  // ör. "match_pair"; oyun tanımı (GameDef) parametreleri ModeContext içinde gelir

  /// Bir aşamanın verisini üretir (hedef, seçenekler, yerleşim).
  RoundSpec buildRound(ModeContext ctx); // GameDef, tema, zorluk katmanı, ItemScheduler, ayarlar

  /// Aşama ekranını çizer; sonucu controller'a bildirir.
  Widget buildView(BuildContext context, RoundSpec spec, RoundCallbacks cb, HintState hint);

  /// Aşama başında çalınacak ses kuyruğu.
  List<AudioCue> introCues(RoundSpec spec);

  /// Doğru cevap sonrası ses kuyruğu (ör. "9 büyüktür 4").
  List<AudioCue> successCues(RoundSpec spec);
}
```

`RoundController` akışı:
`yeni oturum kimliği → buildRound → introCues → seçenekler stagger 150 ms → cevap bekle (HintController zamanlayıcı) → yanlış: HintPolicy → doğru: kutlama + successCues + yıldız + TrialLog → 600–1500 ms → sonraki aşama → tur sonu`. Her gecikmeli iş oturum kimliğini kontrol eder (Unity'deki çift çağrı hatasının önlemi).

### 12.5 Ses servisi

- `playSequence([...])`, aralarda ayarlanabilir boşluk; yeni kuyruk eskisini iptal eder (sürüm sayacı).
- Ekrandan çıkınca tüm sesler durur. Mod açılırken o turun sesleri ön belleğe alınır.
- Dil değişince içerik sesleri yeniden çözülür.

### 12.6 Erişilebilirlik ve performans

- `Semantics` etiketleri, sistem yazı boyutu desteği, "animasyonları azalt" uyumu, sürükleme modlarında dokun-dokun alternatifi.
- Soğuk açılış < 2 sn, mod açılışı < 500 ms, 60 fps; düşük cihazda parçacık kapalı.
- İçerik büyüklüğü: ~600 öğe × 2–3 görsel (WebP ~60 KB) + sesler ≈ 120–180 MB. Faz 1 temaları (Hayvanlar, Meyve-Sebze, Renkler, Sayılar, Taşıtlar) AAB içinde; sonraki temalar **Play Asset Delivery** (fast-follow / on-demand) paketleri olarak. Paket indirilmemişse tema kartı sade bir "indiriliyor" durumu gösterir.
- minSdk 23 korunabilir (okullardaki eski tabletler).

### 12.7 Yayın ve taşıma

- `applicationId` = `com.YeS.OzelEgitimOyunlari`, aynı imzalama/yükleme anahtarı, `versionCode` ≥ 14.
- Mevcut Firebase projesi (`specialeducationgames`) yeniden kullanılabilir; Flutter için `flutterfire configure` ile Android uygulaması aynı paket adıyla bağlanır.
- Dahili test → Kapalı test (öğretmen/aile grubu) → Aşamalı yayın (%10 → %50 → %100).

### 12.8 Backend ve Uzaktan Yönetim (Firebase)

**Karar (ürün sahibi, 2026-10-15):** Mevcut Firebase projesi (`specialeducationgames`) kullanılır. Uzaktan ayar ve içerik için **Firestore + Storage** yeterli; **Remote Config ve Cloud Functions kullanılmaz** (abonelik tamamen Google Play üzerinden). Uygulama **önce cihazda çalışır**. Firebase'in amacı çocuğu izlemek değil; uygulamayı uzaktan ayarlamak, yeni içerik eklemek ve toplu, anonim istatistik görmek.

| Servis | Ne için |
|---|---|
| **Cloud Firestore** | (a) uzaktan ayar belgesi `config/app`, (b) içerik paketleri listesi, (c) ebeveyn duyuruları, (d) opsiyonel aile hesabı senkronu (Bölüm 9.5) |
| **Cloud Storage** | İçerik paketlerinin görsel ve ses dosyaları |
| **Analytics** (çocuk ayarlarıyla) | Toplu, anonim kullanım istatistiği |
| **Crashlytics** | Çökme raporları |
| **Auth** | Opsiyonel ebeveyn girişi ve yönetim paneli girişi |

Sunucu kodu yok; bu yüzden Firebase'in ücretsiz **Spark** planı bu ölçekte yeterlidir.

#### Uzaktan ayar belgesi: `config/app` (Firestore)

| Alan | Örnek | Neden |
|---|---|---|
| `freeGames` | Bölüm 13.1b'deki 6 oyunun listesi | Ücretsiz oyunları güncellemesiz değiştirmek |
| `disabledGames` | `["hayvanlar_G21"]` | Hatalı bir oyunu anında kapatmak |
| `gameOrder` | tema başına oyun sırası | Tema ekranındaki sıralamayı değiştirmek |
| `hiddenThemes` / `newBadge` | yeni tema hazır olana kadar gizli; "Yeni" rozeti | Kontrollü açılış |
| `featuredTheme` | "kis" | Mevsimlik öne çıkarma |
| `difficultyDefaults` | seçenek sayıları, soluklaştırma eşiği (2 yanlış) | Pedagojik ayarı sahadaki veriye göre düzeltmek |
| `paywallText` | Aile Modu metinleri | Fiyatın kendisi Play Console'da |
| `minSupportedVersion` | 20 | Aile Modu'nda sakin "Güncelleme var" kartı; çocuk ekranında asla |
| `announcementId` | `announcements/{id}` | Ebeveyne yeni oyun/tema haberi (yalnızca Aile Modu) |

- Uygulama aynı alanların **varsayılan halini** içinde taşır (`assets/config_defaults.json`). Belge açılışta okunur, yerelde önbelleğe alınır; internet yoksa son kopya, o da yoksa varsayılan geçerli. Değerler oturum başında uygulanır, oyun ortasında ekran değişmez.
- Firestore'un çevrimdışı önbelleği açık; okuma sayısı cihaz başına günde birkaç belgeyle sınırlı kalır.

#### İçerik paketleri (güncellemesiz yeni içerik)

Oyunlar veri odaklı olduğu için (Bölüm 12.3) **yeni öğe, yeni tema veya mevcut oyun türüyle yeni oyun** mağaza güncellemesi olmadan eklenebilir:

```
content_packs/{packId}            // Firestore
  version, minAppVersion, themeIds[], sizeBytes, storagePath, sha256, publishedAt
packs/{packId}.zip                // Storage: JSON + webp görseller + ses dosyaları
```
- Uygulama Aile Modu'nda veya Wi-Fi'da listeyi kontrol eder, indirir, `sha256` doğrular, drift'e işler. İndirme çocuğun oyununu bölmez.
- `minAppVersion`, paketin ihtiyaç duyduğu oyun türlerinin uygulamada olduğunu garanti eder. **Tamamen yeni bir oyun türü (yeni kod) yine mağaza güncellemesi ister.**
- 2.0 içeriği uygulamanın içinde gelir; paketler 2.1'den itibaren kullanılır.

#### İstatistik (toplu ve anonim)

- **Firebase Analytics** çocuk uygulaması ayarlarıyla: `google_analytics_adid_collection_enabled=false`, `google_analytics_default_allow_ad_personalization_signals=false`, kullanıcı özelliği yok, profil adı/yaş gibi alan gönderilmez. Ebeveyn ayarlarında "Anonim kullanım istatistiği gönder" anahtarı (varsayılan açık, kapatılabilir). Veri Güvenliği formunda beyan edilir.
- Sabit olay listesi: `game_start{gameId, themeId, tier}`, `game_complete{gameId, hintRateBucket}`, `game_quit{gameId, stage}`, `paywall_view`, `trial_start`, `purchase`, `survey_done{ageBucket}`.
- Görülebilecekler: en çok oynanan oyunlar ve temalar, çocukların hangi oyunu yarıda bıraktığı, hangi zorlukta ipucu oranının yüksek olduğu, deneme → abonelik dönüşümü (Play Console raporlarıyla birlikte), sürüm bazında çökmeler.
- **Görülmeyecek olan:** tek bir çocuğun ne oynadığı. Bireysel ilerleme yalnızca cihazda ve ebeveynin kendi hesabında kalır.
- Daha ileri analiz gerekirse Analytics → BigQuery dışa aktarımı ve Looker Studio panosu (sonradan, isteğe bağlı).

#### Yönetim paneli

- **Sürüm 2.0:** Firebase konsolu yeterli (`config/app` belgesini elle düzenleme, Analytics, Crashlytics).
- **Faz 3:** Firebase Hosting üzerinde küçük bir **Flutter Web yönetim paneli**. Giriş yalnızca izinli yönetici e-postasıyla (Firestore'da `admins/{uid}` belgesi). Sayfalar:
  - Ayarlar: `config/app` alanlarını form üzerinden düzenleme (ücretsiz oyunlar, kapalı oyunlar, sıra, öne çıkan tema).
  - İçerik: paket zip'ini Storage'a yükleme ve `content_packs` kaydını oluşturma (önce "test" kanalında kapalı test cihazlarına, sonra herkese).
  - Duyurular: ebeveynlere gösterilecek kısa duyuru yazma.
  - İstatistik: Analytics/Looker Studio panosuna bağlantı.

#### Güvenlik kuralları

- `config/*`, `content_packs/*`, `announcements/*`: herkes okur, yalnızca `admins/{uid}` belgesi olan hesap yazar. Storage `packs/` için aynı kural.
- `families/{uid}`: yalnızca sahibi okur/yazar. Abonelik durumu Firestore'da tutulmaz (aşağıda).
- App Check (Play Integrity) açık; kotaların kötüye kullanımını engeller.

---

## 13. Gelir Modeli: Reklamsız Abonelik + Ücretsiz Katman + Deneme

### 13.1 Katmanlar

| | Ücretsiz | Premium |
|---|---|---|
| Reklam | Yok | Yok |
| Oyunlar | **Sabit 6 oyun** (Bölüm 13.1b listesi), başka hiçbiri | Tüm oyunlar (~317 tıklanabilir oyun), her ay yeni içerik |
| Zorluk | 6 ücretsiz oyunda Kolay + Orta | Kolay/Orta/Zor + Otomatik |
| Profil | 1 | 5 |
| Bulut senkronu | Var (aile girişi yapılırsa) | Var |
| Raporlar | Son 7 gün, Bugün + Haftalık | Tüm geçmiş, beceri alanları, öğe bazlı, PDF |
| Çevrimdışı | Evet | Evet |

### 13.1b Ücretsiz sürümde tam olarak ne açık? (agent bu tabloyu uygular)

**Kural:** Ücretsiz kullanıcı **en fazla 6 oyun** açıp oynayabilir. "Oyun" burada ekranda dokunup açılan tek bir oyun kartıdır (ör. "Hayvanları Bul"); tema değil. Bu 6 oyunun dışındaki her oyun kartı kilitlidir.

| # | Ücretsiz oyun (kartın adı) | Tema | Oyun türü | Açık zorluk |
|---|---|---|---|---|
| 1 | Hayvanları Bul | Hayvanlar | G01 Tanı | Kolay + Orta |
| 2 | Meyve ve Sebzeleri Bul | Meyve-Sebze | G01 Tanı | Kolay + Orta |
| 3 | Renkleri Bul | Renkler | G01 Tanı | Kolay + Orta |
| 4 | Hayvanların Sesini Bul | Hayvanlar | G10 Sesini Bul | Kolay + Orta |
| 5 | Sonraki Sayı | Sayılar | G35 Sonraki Sayı | Kolay + Orta |
| 6 | Taşıtları Öğren | Taşıtlar | G02 Kartlarla Öğren | Kolay + Orta |

- Zor seviye ve diğer tüm oyunlar Premium.
- Seçim gerekçesi: ilk üçü ve Sonraki Sayı, eski uygulamada da olan oyunlar (mevcut kullanıcı tanıdığı şeyi bulur); Sesini Bul ve Kartlarla Öğren ise yeni oyun türlerini tattırır.
- Sayılarla: sürüm 2.0'da 35 oyunun **6'sı** ücretsiz, 29'u Premium. Plan bittiğinde ~317 oyunun yine **6'sı** ücretsiz kalır.
- Görünüm: 6 ücretsiz oyun tema ekranlarında en başta durur. Kilitli kartlar normal görünür, köşede küçük bir kilit vardır. Çocuk kilitli karta dokunursa nötr "Bunu ailenle açabilirsin" çıkar (13.4).
- Liste kodda sabit değildir: Firestore `config/app.freeGames` alanından okunur (Bölüm 12.8), böylece güncelleme yapmadan değiştirilebilir. Uygulamanın içindeki varsayılan değer bu tablodur.
- Eski sürüm kullanıcıları: eski uygulamadaki 10 oyunun 4'ü ücretsiz kalır, diğerleri Premium olur. Güncelleme notunda ve Aile Modu'nda bir kez sakin bir açıklama gösterilir.

### 13.2 Play Console ürünleri

- Abonelik `premium`:
  - Temel plan `monthly` (otomatik yenilenen, 1 ay)
  - Temel plan `yearly` (otomatik yenilenen, 1 yıl; aylığa göre ~%40–50 indirimli konum)
  - Teklif `trial-7d` (her iki planda; uygunluk: bu aboneliği hiç almamış kullanıcı)
- Opsiyonel (Faz 2): tek seferlik `lifetime`.
- **Fiyat önerisi (başlangıç noktası, doğrulanmalı):** Aylık ₺99–149, Yıllık ₺699–999; diğer ülkeler Play fiyat şablonuyla.
- Grace period ve account hold açık. Aile Kitaplığı (Family Library) açık.

### 13.3 Teknik

- `in_app_purchase` (Play Billing Library 7+).
- `EntitlementService`: açılışta ve satın alma akışında durumu günceller; son bilinen durumu yerelde saklar (`premiumUntil`, `lastVerifiedAt`); **çevrimdışında 7 gün** son bilinen durumu kabul eder; "Satın alımları geri yükle".
- Sunucu yok (ürün sahibi kararı): abonelik durumu her cihazda Play Billing'den okunur (`queryPurchases`). Aynı Google hesabıyla giriş yapılmış başka cihazda Premium kendiliğinden görünür; "Satın alımları geri yükle" de aynı sorguyu yapar. Satın alma 3 gün içinde `acknowledge` edilir (yoksa Google iade eder).
- Abonelik yönetimi bağlantısı (yalnızca Aile Modu'nda): `https://play.google.com/store/account/subscriptions?sku=premium&package=com.YeS.OzelEgitimOyunlari`

### 13.4 Paywall kuralları (yalnızca Aile Modu'nda)

- Açıkça: "7 gün ücretsiz, sonra ₺X/ay. Deneme bitmeden Google Play'den istediğiniz zaman iptal edebilirsiniz." Deneme bitiş tarihi gösterilir.
- Deneme bitmeden 2 gün önce yerel hatırlatma (ebeveyn izin verirse).
- Geri sayım, sahte indirim, gizli kapatma butonu, çocuğa yönelik baskı **yok**.
- Ayarlarda "Aboneliği nasıl iptal ederim?" tek dokunuşla (Otsimo'nun en büyük şikayeti).
- Çocuk Modu'nda kilitli içeriğe dokunulursa: kısa nötr animasyon + "Bunu ailenle açabilirsin" sesi; satın alma ekranı **açılmaz**.

---

## 14. Google Play Uyumluluk Kontrol Listesi

### 14.1 Families politikası

- [ ] Hedef kitle yalnızca gerçekten tasarlanan çocuk yaş grupları (ör. "5 ve altı", "6–8"); geniş seçim daha sıkı inceleme demek.
- [ ] **Reklam yok:** Play Console → Uygulama içeriği → Reklamlar → **Hayır** (şu anki "Reklam içerir" etiketi düzeltilmeli).
- [ ] Reklam/gelir SDK'sı yok: AdMob, IronSource, GameAnalytics ILRD vb.
- [ ] Reklam kimliği ve cihaz tanımlayıcıları gönderilmez; `com.google.android.gms.permission.AD_ID` izni manifestten kaldırılır (`tools:node="remove"`).
- [ ] Konum ve gereksiz izin yok.
- [ ] Kullanılan her SDK (Firebase Auth, Firestore, Crashlytics, Analytics, Storage, Google Sign-In) Veri Güvenliği formunda beyanlı; Analytics'te reklam kimliği toplama kapalı; Families için uygun olmayan SDK yok.
- [ ] Giriş ve veri toplama ebeveyn kaynaklı (Aile Modu, ebeveyn kilidi arkası); çocuktan kişisel veri istenmez (takma ad önerilir, doğum tarihi yerine yaş aralığı, tanı sorusu yok).
- [ ] Satın alma ekranları yanıltıcı değil, yanlışlıkla dokunmaya yol açmaz.
- [ ] "Yetişkin işlemi" (ebeveyn kilidi) satın alma ve dış bağlantılardan önce.

### 14.2 Gizlilik ve hesap

- [ ] Gizlilik politikası güncel: cihazda tutulan veri, aile hesabıyla Firestore'a giden özetler, satın almanın Google tarafından işlenmesi, saklama süresi, silme yolu, iletişim e-postası. Uygulamada ve mağazada bağlantı.
- [ ] Hesap silme: uygulama içinden ve web sayfasından (Play zorunluluğu).
- [ ] Veri Güvenliği formu: toplanan veriler (uygulama etkinliği, kullanıcı tarafından sağlanan içerik, e-posta: yalnızca giriş yapan ebeveyn), aktarımda şifreli, **silinebilir**.
- [ ] KVKK ve COPPA/GDPR-K: çocuktan doğrudan kişisel veri toplanmaz.

### 14.3 Mağaza sayfası

- [ ] Yer tutucular (`[email address]`, `[Audio instructions...]`) temizlenir.
- [ ] Abonelik modeli açıkça yazılır: "Ücretsiz oyunlar + isteğe bağlı Premium, reklam yok."
- [ ] Yeni ekran görüntüleri (telefon, 7", 10" tablet), sakin bir tanıtım videosu.
- [ ] "Uzman desteğinin yerini tutmaz" ibaresi korunur; tıbbi/terapi iddiası yok.
- [ ] "Öğretmen Onaylı" rozetini korumak için Families kalitesine dikkat.

---

## 15. Yol Haritası ve Öncelikler

Notion'daki 4 aşamalı plan korunmuştur; Flutter yeniden yazımı ve abonelik için başa bir "taşıma" fazı eklenmiştir.

### Faz 0: Hazırlık (ürün sahibi)
- [ ] İmzalama anahtarını ve Play App Signing durumunu doğrula.
- [ ] Unity'den tüm görsel ve sesleri dışa aktar, `icerik-katalogu.md` "Üretim notları" adlandırmasına getir (OLDAnimals dahil).
- [ ] Yeni öğeler için görsel ve ses üretim planı (Faz 1 için ~75 yeni öğe: 2 hayvan, 20 meyve-sebze, 5 renk, 46 taşıt).
- [ ] Fiyatlar ve ücretsiz kapsam kararı (Bölüm 18).
- [ ] Yeni temalar için görsel kaynağı ve ElevenLabs ses ayarlarını netleştir.

### Faz 1: Taşıma + Temel Altyapı (Notion Aşama 1) → **Sürüm 2.0**
1. Proje iskeleti, **tasarım sistemi** (`tasarim-sistemi.md` tokenları ve bileşenleri), router, l10n, drift.
2. İçerik sistemi (Bölüm 12.3), `content_source.csv` → JSON betiği, mevcut tüm içeriğin taşınması.
3. `GameShell`, `RoundController`, `AudioService`, `HintController` + hatasız öğretim (Bölüm 3).
4. Şablonlar: `identify`, `flashcards`, `count`, `compare`, `sequence_missing`, `cause_effect`.
5. Oyunlar (**10**): G01 Tanı, G02 Kartlarla Öğren, G10 Sesini Bul, G14 Aynısını Bul, G33 Say ve Seç, G34 Rakamı Bul, G35 Sonraki Sayı, G36 Karşılaştır, G55 Dokun-Keşfet, + G04 Hangi Grupta (identify ile ucuz).
6. Temalar (**5**): Hayvanlar (51), Meyve-Sebze (50), Renkler, Sayılar, Taşıtlar (46). Kolay/Orta/Zor katmanları tam.
7. Zorluk sistemi (Bölüm 8), aralıklı tekrar.
8. Profil oluşturma, başlangıç anketi, Aile/Çocuk Modu, ebeveyn kilidi.
9. Yerel kayıt + raporlar (Bugün, Haftalık).
10. Abonelik + 7 gün deneme + geri yükleme + iptal yolu.
11. Google ile opsiyonel aile girişi + Firestore senkronu; `config/app` uzaktan ayar belgesi (varsayılanlarla), Crashlytics, çocuk ayarlı Analytics (Bölüm 12.8).
12. Uyumluluk düzeltmeleri, gizlilik politikası, mağaza metni.

Sürüm 2.0'da: **35 tıklanabilir oyun kartı** (5 tema), her biri Kolay/Orta/Zor ≈ 105 oynanabilir set (mevcut uygulamanın 10 oyununa karşı).

**Kabul kriterleri:**
- Mevcut 10 oyunun içeriği eksiksiz oynanabilir; mevcut ses/animasyon hissi korunmuş (Bölüm 1.3).
- 2 yanlıştan sonra yanlış seçenekler soluklaşıyor; hiçbir aşama başarısız bitmiyor.
- Tüm ekranlar `tasarim-sistemi.md` kontrol listesinden geçiyor.
- Çocuk Modu'nda satın alma/dış bağlantı yok; Aile Modu kilitli.
- Uçak modunda tüm ücretsiz içerik ve (7 gün içinde doğrulanmış) Premium içerik çalışıyor.
- Deneme, iptal, yenileme, geri yükleme lisans test hesaplarıyla doğrulandı.
- Manifestte AD_ID yok; AAB'de reklam SDK'sı yok; Firebase Analytics yalnızca Bölüm 12.8'deki çocuk ayarlarıyla.

### Faz 2: Mekanikleri Çeşitlendirme (Notion Aşama 2) → Sürüm 2.1
- Altyapı: içerik paketleri (Bölüm 12.8) ile güncellemesiz yeni içerik.
- Sürükle-bırak altyapısı (`DragItem`, `DropZone`, mıknatıs, geri dönüş, dokun-dokun alternatifi).
- Şablonlar: `drag_to_target`, `sort`, `match_pair`, `odd_one_out`, `audio_choice`, `fill_count`.
- Oyunlar (**+14**): G03, G11, G15 Gölgesini Bul, G16 Yarısını Tamamla, G17 Farklı Olanı Bul, G23 Sepete Koy, G24 Nerede Yaşar, G25 Kara-Hava-Deniz, G27 Renge Göre Grupla, G28 Anne ve Yavrusu, G37 Sayı ve Miktar, G38 Sepeti Doldur + Faz 1 oyunlarının yeni temalara açılması.
- Temalar (**+2**): Şekiller, Yiyecek ve İçecekler.
- Beceri alanı raporu, öğe bazlı rapor.

### Faz 3: Yeni Temalar (Notion Aşama 3) → Sürüm 2.2–2.3
- Altyapı: Flutter Web yönetim paneli (Bölüm 12.8).
- Şablonlar: `partial_reveal`, `missing_item`, `shape_sorter`, `build_face` (hazırlık).
- Oyunlar (**+15**): G05 Ne İşe Yarar, G06 Kim Yapar, G18 Saklanan Ne, G21 Şekil Kutusu, G22 Parçası Nerede, G26 Odalara Yerleştir, G29 Ne Yer, G30 Yuvası Hangisi, G31 Meslek ve Aracı, G39 Örüntü, G40 Büyükten Küçüğe, G42 Kaybolan Ne, G49 Duyguyu Bul, G50 Nasıl Hisseder, G53 Giydir.
- Temalar (**+6**): Kıyafetler, Evimiz, Okul ve Oyuncaklar, Vücudumuz, Duygular, Meslekler.
- Sakin Köşe; Play Asset Delivery.

### Faz 4: Bilişsel ve İnce Motor (Notion Aşama 4) → Sürüm 2.4
- Şablonlar: `puzzle`, `order`, `memory`, `simon`, `trace`, `coloring`.
- Oyunlar (**+12**): G07, G08, G09, G12, G13, G19 Yakından Bak, G20 Yapboz, G32 Hangi Mevsim, G41 Hafıza, G43 Olay Sırası, G44 Günlük Rutin, G45 İz Sür, G47 Boya, G51 Yüz Yap.
- Temalar (**+2**): Doğa ve Mevsimler, Müzik Aletleri.
- PDF rapor, opsiyonel `lifetime`.

### Faz 5: Genişleme
- G46 Rakam Yaz, G48 Noktaları Birleştir, G52 Sosyal Hikayeler, G54 Güvenli mi; Harfler teması; basit İhtiyaç Kartları (AAC); öğretmen/sınıf modu; ek diller; iOS.

### Öncelik özeti

| Öncelik | İş |
|---|---|
| P0 | Aynı paket/anahtar, içerik taşıma, sakin tasarım, hatasız öğretim, ebeveyn kilidi, abonelik + deneme, reklam beyanı düzeltmesi |
| P1 | Profil + anket, Kolay/Orta/Zor katmanlı içerik, raporlar, Sesini Bul, Taşıtlar, bulut senkronu |
| P2 | Sürükle-bırak oyunları, sınıflama oyunları, yeni temalar, beceri alanı raporu |
| P3 | Yapboz, sıralama, hafıza, PDF, AAC, iOS |

---

## 16. Test Planı

- **Birim:** `DifficultyEngine`, `ItemScheduler`, `HintPolicy` (2 yanlış → soluklaştırma), `SurveyMapper`, `RoundController` (hedef her zaman seçeneklerde, seçenekler benzersiz, oturum kimliği iptali), `EntitlementService` (deneme, süresi dolmuş, çevrimdışı önbellek, iade), Firestore senkron çakışmaları.
- **Widget/golden:** her şablon ve `tasarim-sistemi.md` bileşeni için Kolay/Orta/Zor ve tüm durumlar, telefon ve tablet, dikey/yatay, büyük yazı.
- **Entegrasyon:** ilk açılış → anket → oyun → tur sonu → Aile Modu → rapor → paywall (test hesabı) → Çocuk Modu.
- **Uyumluluk:** manifest izin kontrolü; AAB içinde `com.google.android.gms.ads`, `ironsource`, `gameanalytics` aranır, bulunmamalı.
- **Kullanıcı testi:** en az 3 özel eğitim öğretmeni ve 5 aileyle kapalı test. Gözlem: yönerge anlaşıldı mı, yanlışlıkla çıkış oldu mu, kutlama rahatsız etti mi, sürükleme yapılabildi mi, ses seviyesi uygun mu, anket soruları anlaşılır mı.

---

## 17. Agent İçin Uygulama Talimatı

1. Flutter projesini `com.YeS.OzelEgitimOyunlari` paket adıyla oluştur; `versionCode` ≥ 14.
2. Bölüm 12.1 paketlerini ve 12.2 klasör yapısını kullan.
3. Önce **`tasarim-sistemi.md`**'deki tokenları ve bileşenleri (`lib/app/ui/`) kodla; hiçbir ekran token dışı renk/yazı/süre kullanmasın.
4. İçeriği **`icerik-katalogu.md`**'den `content_source.csv` → JSON betiğiyle üret (Bölüm 12.3 şeması); Faz sırasına göre temaları ekle.
5. `GameShell`, `RoundController`, `AudioService`, `HintController` ve `HintPolicy`'yi yaz; Bölüm 3 kuralları birim testleriyle doğrulansın.
6. Şablonları ve oyunları (Bölüm 6) Bölüm 15'teki faz sırasıyla ekle. Her şablon `GameTemplate` sözleşmesini uygular; oyunlar `games.json`'da tanımlanır ve Bölüm 6.3 matrisine göre temalara bağlanır.
7. Profil, anket (Bölüm 9.3), Aile/Çocuk Modu ve ebeveyn kilidini `go_router` redirect'iyle uygula.
8. Abonelik: `in_app_purchase`, ürün `premium`, planlar `monthly`/`yearly`, teklif `trial-7d`; erişim yalnızca `EntitlementService` üzerinden.
9. Reklam SDK'sı, AD_ID izni, konum izni, zorunlu giriş, üçüncü taraf analitik **ekleme**.
10. Her fazın sonunda Bölüm 16 testlerini ve Bölüm 15 kabul kriterlerini çalıştır.

---

## 18. Açık Sorular (ürün sahibine)

1. **Fiyat:** aylık ve yıllık tutar? Ömür boyu seçenek olacak mı?
2. **Deneme:** 7 gün mü, 14 gün mü (Otsimo 14 gün vermişti)?
3. **Ücretsiz kapsam:** karar verildi: en fazla 6 oyun (Bölüm 13.1b). Hangi 6 oyun olduğu değiştirilebilir.
4. **Hedef yaş grubu** (Play Console)?
5. **Görsel stil:** tamamen gerçek fotoğraf mı, Vücut/Duygular/Meslekler gibi temalarda sade çizim kabul mü? (Notion'da "gerçek mi ikonik mi" sorusu işaretlenmiş; nihai karar nedir?)
6. **Ses:** kullanılan ElevenLabs sesi ve ayarları nedir? Hayvan/taşıt efekt sesleri nereden temin edilecek?
7. **Aile hesabı:** yalnızca Google ile giriş mi, e-posta ile de mi?
8. **iOS** ilk sürümde hedefleniyor mu?
9. **Otsimo ekranları:** Otsimo'nun ekran görüntülerine bu oturumdan erişilemedi. 4–5 ekran görüntüsü paylaşırsan tasarım sistemi ona göre netleştirilir.
10. **Maskot:** "Minik" baykuş maskotu olsun mu (tasarim-sistemi.md §9)?
11. **Yeni içerik üretimi:** ~520 yeni öğe için görseller (fotoğraf kesimi mi, üretim mi) ve sesler kim/ne ile üretilecek? Faz 1 için ~75 öğe yeterli.

---

### Kaynaklar

- Unity projesi: `D:\GameDesktop\UnityProjects\SpecialEducationGames`
- Ürün sahibinin Notion notları: "Yapılacaklar", "Roadmap", "v1.35" (thread'de paylaşıldı)
- [Özel Eğitim Oyunları, Google Play](https://play.google.com/store/apps/details?id=com.YeS.OzelEgitimOyunlari)
- [Otsimo | Special Education, Google Play](https://play.google.com/store/apps/details?id=com.otsimo.app)
- [The Autism Dad: Otsimo incelemesi (2019)](https://theautismdad.com/2019/06/23/review-otsimo-is-a-fantastic-educational-app-for-kids-with-autism/)
- [Autism Parenting Magazine: Best autism apps](https://www.autismparentingmagazine.com/best-autism-apps/)
- [File Folder Heaven: Errorless learning in special education](https://www.filefolderheaven.com/guides/errorless-learning-special-education)
- [Multimedia guidelines for vocabulary apps for children with ASD (Univ. of Pretoria)](https://repository.up.ac.za/items/4f7aea7b-4369-4b07-8dc3-f7fea58a6016/full)
- [MEB: İletişim ve Sosyal Beceriler](https://Karatayram.Meb.K12.Tr/meb_iys_dosyalar/42/25/966350/dosyalar/2021_11/23091543_Iletisim-ve-Sosyal-Beceriler.pdf)
- [Google Play Families politikası](https://support.google.com/googleplay/android-developer/answer/9893335)
- [Google Play Families gereksinimleri](https://support.google.com/googleplay/android-developer/answer/10075896)
