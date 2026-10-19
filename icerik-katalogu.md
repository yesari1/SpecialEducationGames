# Özel Eğitim Oyunları: İçerik Kataloğu

> Güncel tamamlanma takibi: [TODO.md](TODO.md). 16 Ekim kullanıcı kararıyla yeni AI görseli üretilmez; tek ve tam nesneli gerçek internet fotoğrafları, doğrulanmış tekil lisans/atıf, transparan PNG ve beyaz özne konturu kullanılır. Ses: Türkçe İrem, İngilizce Laura, Eleven Multilingual v2; tek kelimeler noktayla biter. Katalogda kayıt bulunması fotoğraf/sesin nihai hazır olduğu anlamına gelmez.

> Ana rapor: [ozel-egitim-oyunlari-flutter-raporu.md](ozel-egitim-oyunlari-flutter-raporu.md) · Stil: [tasarim-sistemi.md](tasarim-sistemi.md)
> Bu dosya her temanın öğe listesini **Kolay / Orta / Zor** katmanlarına bölünmüş halde verir. Agent bu listeleri `assets/content/items/{tema}.json` dosyalarına dönüştürür.

## Nasıl okunur

- Biçim: `Türkçe ad (slug)` — slug İngilizce, küçük harf, alt çizgili; dosya adı ve İngilizce ad için temel alınır. İngilizce görünen ad slug'dan üretilir ve gözden geçirilir.
- **Katman (tier)** öğenin **tanıdıklığına** göredir: Kolay = çocuğun günlük hayatında en sık gördüğü; Orta = bilinen ama daha az sık; Zor = nadir, benzer çeldiricisi çok olan veya soyut.
- **Gruplar** (köşeli parantez) `tags` alanına yazılır; gruplama (sepete koy), "yaşadığı yer", "hangi odada" gibi oyunlarda kullanılır.
- **★** ile işaretli öğeler Unity projesinde hâlihazırda görsel ve sesiyle mevcuttur (taşınacak).
- **🔊** gerçek ses efekti (sfx) gerektirir/önerilir ("Sesini Bul" oyunları için).
- Bölüm: her katman ~8'lik bölümlere ayrılır (Notion'daki "her tema 5 seviye" kararı: Kolay = Bölüm 1–2, Orta = 3–4, Zor = 5–6).
- Hedef toplam: somut temalarda **40–50 öğe**. Renk, şekil, sayı, duygu gibi soyut temalar doğası gereği daha az öğeye, ama öğe başına daha çok görsele sahiptir.

### Toplam içerik özeti

| Tema | Kolay | Orta | Zor | Toplam öğe | Not |
|---|---|---|---|---|---|
| Hayvanlar | 16 | 17 | 18 | **51** | 30 mevcut + 19 OLDAnimals'ta hazır |
| Meyve ve Sebzeler | 15 | 16 | 19 | **50** | 30 mevcut |
| Yiyecek ve İçecekler | 14 | 14 | 14 | **42** | |
| Taşıtlar | 15 | 15 | 16 | **46** | |
| Kıyafet ve Aksesuarlar | 12 | 15 | 15 | **42** | |
| Evimiz (eşyalar) | 16 | 17 | 17 | **50** | |
| Okul ve Oyuncaklar | 14 | 14 | 14 | **42** | |
| Meslekler (+ araçları) | 10 | 14 | 16 | **40** | + 40 araç/eşya |
| Doğa ve Mevsimler | 12 | 15 | 15 | **42** | |
| Müzik Aletleri | 8 | 10 | 12 | **30** | tamamı 🔊 |
| Vücudumuz | 10 | 12 | 12 | **34** | illüstrasyon |
| Renkler | 4 | 6 | 6 | **16** + 60 renkli nesne | |
| Şekiller | 4 | 6 | 8 | **18** + 40 şekilli nesne | |
| Sayılar | 1–5 | 1–10 | 0–20 | **21** | + miktar görselleri |
| Duygular | 2 | 5 | 7 | **14** × 4 yüz = 56 görsel | |
| Harfler (Faz 5) | — | — | — | **29** | |
| Para ve Zaman | 10 | 12 | 12 | **34** | Otsimo'dan |
| Hikayeler | — | — | — | **10+ kitap** | §18 |
| **Toplam** | | | | **~650 öğe** | |

---

## 1. Hayvanlar 🐶

Gruplar: `[evcil]` `[ciftlik]` `[vahsi]` `[deniz]` `[bocek]` `[kus]` · Yaşadığı yer: `[kara]` `[su]` `[hava]`
Ek ilişkiler: `baby` (yavru), `food` (ne yer), `home` (yuvası).

**Kolay (16)** — Bölüm 1–2
Kedi (cat) ★🔊 [evcil] · Köpek (dog) ★🔊 [evcil] · Kuş (bird) ★🔊 [evcil,kus] · Balık (fish) ★ [evcil,deniz] · Tavşan (rabbit) ★ [evcil] · İnek (cow) ★🔊 [ciftlik] · At (horse) ★🔊 [ciftlik] · Koyun (sheep) ★🔊 [ciftlik] · Tavuk (chicken) ★🔊 [ciftlik,kus] · Ördek (duck) ★🔊 [ciftlik,kus] · Civciv (chick) ★🔊 [ciftlik,kus] · Aslan (lion) ★🔊 [vahsi] · Fil (elephant) ★🔊 [vahsi] · Maymun (monkey) ★🔊 [vahsi] · Ayı (bear) ★🔊 [vahsi] · Kelebek (butterfly) ★ [bocek]

**Orta (17)** — Bölüm 3–4
Keçi (goat) ★🔊 [ciftlik] · Eşek (donkey) ★🔊 [ciftlik] · Horoz (rooster) ★🔊 [ciftlik,kus] · Hindi (turkey) ★🔊 [ciftlik,kus] · Arı (bee) ★🔊 [bocek] · Kaplumbağa (turtle) ★ [evcil] · Fare (mouse) ★🔊 [evcil] · Kurbağa (frog) 🔊 [su] · Zürafa (giraffe) ★ [vahsi] · Zebra (zebra) ★ [vahsi] · Kaplan (tiger) ★🔊 [vahsi] · Kurt (wolf) ★🔊 [vahsi] · Tilki (fox) [vahsi] · Sincap (squirrel) ★ [vahsi] · Baykuş (owl) ★🔊 [kus] · Penguen (penguin) ★ [kus,deniz] · Yunus (dolphin) ★🔊 [deniz]

**Zor (18)** — Bölüm 5–6
Geyik (deer) ★ [vahsi] · Boğa (bull) ★🔊 [ciftlik] · Kirpi (hedgehog) ★ [vahsi] · Karınca (ant) ★ [bocek] · Uğur böceği (ladybug) ★ [bocek] · Ahtapot (octopus) ★ [deniz] · Köpekbalığı (shark) ★ [deniz] · Balina (whale) ★🔊 [deniz] · Su aygırı (hippopotamus) ★ [vahsi] · Gergedan (rhinoceros) ★ [vahsi] · Timsah (crocodile) ★ [vahsi,su] · Deve (camel) ★🔊 [vahsi] · Kanguru (kangaroo) ★ [vahsi] · Goril (gorilla) ★ [vahsi] · Flamingo (flamingo) ★ [kus] · Devekuşu (ostrich) ★ [kus] · Yarasa (bat) ★ [hava] · Bukalemun (chameleon) ★ [vahsi]

**İlişki listeleri**
- Anne–yavru: İnek–buzağı (calf) · At–tay (foal) · Koyun–kuzu (lamb) · Keçi–oğlak (kid_goat) · Tavuk–civciv · Köpek–yavru köpek (puppy) · Kedi–yavru kedi (kitten) · Ördek–ördek yavrusu (duckling) · Aslan–yavru aslan (cub) · Kurbağa–iribaş (tadpole)
- Ne yer: Tavşan–havuç · Maymun–muz · İnek–ot · Kedi–süt · Köpek–kemik · Ayı–bal · Fare–peynir · Sincap–fındık · At–elma
- Yuvası: Kuş–yuva · Arı–kovan · Köpek–kulübe · Balık–akvaryum · İnek–ahır · At–ahır · Tavuk–kümes

---

## 2. Meyve ve Sebzeler 🍎

Gruplar: `[meyve]` `[sebze]` · Renk etiketi: `[kirmizi]` `[sari]` `[yesil]` `[turuncu]` `[mor]` (Renkler temasıyla çapraz kullanım)
Ek: `slice` (bütün–dilim görseli), `growsOn` (ağaçta/toprakta/dalda)

**Kolay (15)**
Elma (apple) ★ [meyve,kirmizi] · Muz (banana) ★ [meyve,sari] · Portakal (orange) ★ [meyve,turuncu] · Çilek (strawberry) ★ [meyve,kirmizi] · Üzüm (grape) ★ [meyve,mor] · Karpuz (watermelon) ★ [meyve,yesil] · Armut (pear) ★ [meyve,yesil] · Kiraz (cherry) ★ [meyve,kirmizi] · Mandalina (mandarin) ★ [meyve,turuncu] · Domates (tomato) ★ [sebze,kirmizi] · Havuç (carrot) ★ [sebze,turuncu] · Patates (potato) ★ [sebze] · Salatalık (cucumber) ★ [sebze,yesil] · Mısır (corn) [sebze,sari] · Limon (lemon) [meyve,sari]

**Orta (16)**
Şeftali (peach) ★ [meyve] · Erik (plum) ★ [meyve,mor] · Kavun (melon) [meyve,sari] · Nar (pomegranate) ★ [meyve,kirmizi] · Ananas (pineapple) [meyve,sari] · Kivi (kiwi) [meyve,yesil] · Biber (pepper) ★ [sebze,yesil] · Patlıcan (eggplant) ★ [sebze,mor] · Soğan (onion) ★ [sebze] · Lahana (cabbage) ★ [sebze,yesil] · Marul (lettuce) ★ [sebze,yesil] · Kabak (zucchini) ★ [sebze,yesil] · Bezelye (pea) ★ [sebze,yesil] · Fasulye (green_bean) [sebze,yesil] · Kayısı (apricot) [meyve,turuncu] · Vişne (sour_cherry) [meyve,kirmizi]

**Zor (19)**
Ayva (quince) ★ [meyve,sari] · İncir (fig) [meyve,mor] · Böğürtlen (blackberry) ★ [meyve,mor] · Ahududu (raspberry) [meyve,kirmizi] · Dut (mulberry) [meyve] · Avokado (avocado) [meyve,yesil] · Hindistan cevizi (coconut) [meyve] · Greyfurt (grapefruit) [meyve] · Kestane (chestnut) ★ [meyve] · Karnabahar (cauliflower) ★ [sebze] · Brokoli (broccoli) [sebze,yesil] · Ispanak (spinach) ★ [sebze,yesil] · Turp (radish) ★ [sebze,kirmizi] · Pancar (beetroot) [sebze,mor] · Sarımsak (garlic) [sebze] · Kereviz (celery) [sebze] · Pırasa (leek) [sebze,yesil] · Nane (mint) ★ [sebze,yesil] · Enginar (artichoke) [sebze,yesil]

---

## 3. Yiyecek ve İçecekler 🥪

Gruplar: `[kahvalti]` `[ogle_aksam]` `[tatli]` `[icecek]` `[atistirmalik]` · Sıcak/soğuk: `[sicak]` `[soguk]`

**Kolay (14)**
Ekmek (bread) [kahvalti] · Süt (milk) [icecek] · Su (water) [icecek] · Yumurta (egg) [kahvalti] · Peynir (cheese) [kahvalti] · Yoğurt (yogurt) · Meyve suyu (juice) [icecek] · Kek (cake) [tatli] · Dondurma (ice_cream) [tatli,soguk] · Makarna (pasta) [ogle_aksam] · Çorba (soup) [ogle_aksam,sicak] · Pilav (rice) [ogle_aksam] · Kurabiye (cookie) [tatli] · Simit (simit) [kahvalti]

**Orta (14)**
Bal (honey) [kahvalti] · Zeytin (olive) [kahvalti] · Reçel (jam) [kahvalti] · Tereyağı (butter) [kahvalti] · Sandviç (sandwich) · Pizza (pizza) · Köfte (meatball) [ogle_aksam] · Salata (salad) [ogle_aksam] · Patates kızartması (french_fries) · Çikolata (chocolate) [tatli] · Pasta (birthday_cake) [tatli] · Ayran (ayran) [icecek] · Krep (pancake) [kahvalti] · Mısır gevreği (cereal) [kahvalti]

**Zor (14)**
Börek (borek) · Mantı (manti) · Dolma (dolma) · Lahmacun (lahmacun) · Menemen (menemen) [kahvalti] · Kuru üzüm (raisin) [atistirmalik] · Fındık (hazelnut) [atistirmalik] · Ceviz (walnut) [atistirmalik] · Fıstık (peanut) [atistirmalik] · Patlamış mısır (popcorn) [atistirmalik] · Sucuk (sucuk) [kahvalti] · Mercimek (lentil) · Puding (pudding) [tatli] · Limonata (lemonade) [icecek,soguk]

---

## 4. Taşıtlar 🚗

Gruplar: `[kara]` `[hava]` `[deniz]` `[rayli]` `[gorev]` `[is_makinesi]` · Hepsi için 🔊 önerilir (motor, korna, siren, düdük).
Ek: `driver` (sürücüsü: pilot, kaptan, şoför, makinist)

**Kolay (15)**
Araba (car) 🔊 [kara] · Otobüs (bus) 🔊 [kara] · Kamyon (truck) 🔊 [kara] · Tren (train) 🔊 [rayli] · Uçak (airplane) 🔊 [hava] · Gemi (ship) 🔊 [deniz] · Bisiklet (bicycle) 🔊 [kara] · Motosiklet (motorcycle) 🔊 [kara] · Ambulans (ambulance) 🔊 [kara,gorev] · İtfaiye aracı (fire_truck) 🔊 [kara,gorev] · Polis arabası (police_car) 🔊 [kara,gorev] · Taksi (taxi) 🔊 [kara] · Helikopter (helicopter) 🔊 [hava] · Tekne (boat) 🔊 [deniz] · Traktör (tractor) 🔊 [kara,is_makinesi]

**Orta (15)**
Minibüs (minibus) [kara] · Kamyonet (pickup_truck) [kara] · Çöp kamyonu (garbage_truck) 🔊 [kara,gorev] · Okul servisi (school_bus) 🔊 [kara] · Metro (subway) 🔊 [rayli] · Tramvay (tram) 🔊 [rayli] · Scooter (scooter) [kara] · Kepçe (excavator) 🔊 [is_makinesi] · Vinç (crane) [is_makinesi] · Sıcak hava balonu (hot_air_balloon) [hava] · Yelkenli (sailboat) [deniz] · Sürat teknesi (speedboat) 🔊 [deniz] · Karavan (caravan) [kara] · At arabası (horse_cart) 🔊 [kara] · Çekici (tow_truck) [kara,gorev]

**Zor (16)**
Forklift (forklift) [is_makinesi] · Beton mikseri (cement_mixer) [is_makinesi] · Buldozer (bulldozer) [is_makinesi] · Yol silindiri (road_roller) [is_makinesi] · Yük gemisi (cargo_ship) 🔊 [deniz] · Denizaltı (submarine) [deniz] · Feribot (ferry) 🔊 [deniz] · Kano (canoe) [deniz] · Roket (rocket) 🔊 [hava] · Jet (jet) 🔊 [hava] · Zeplin (airship) [hava] · Planör (glider) [hava] · Teleferik (cable_car) [hava] · Kar motosikleti (snowmobile) [kara] · Hızlı tren (high_speed_train) 🔊 [rayli] · Kaykay (skateboard) [kara]

---

## 5. Kıyafet ve Aksesuarlar 👕

Gruplar: `[yaz]` `[kis]` `[yagmur]` · Vücut bölgesi: `[bas]` `[govde]` `[bacak]` `[ayak]` `[el]` `[boyun]` `[aksesuar]`
Ek: `dressOrder` (giyinme sırası: iç → dış)

**Kolay (12)**
Tişört (tshirt) [yaz,govde] · Pantolon (trousers) [bacak] · Ayakkabı (shoes) [ayak] · Çorap (socks) [ayak] · Şapka (hat) [yaz,bas] · Mont (coat) [kis,govde] · Elbise (dress) [yaz,govde] · Etek (skirt) [bacak] · Şort (shorts) [yaz,bacak] · Pijama (pajamas) [govde] · Kazak (sweater) [kis,govde] · Terlik (slippers) [ayak]

**Orta (15)**
Gömlek (shirt) [govde] · Eldiven (gloves) [kis,el] · Atkı (scarf) [kis,boyun] · Bere (beanie) [kis,bas] · Çizme (boots) [kis,yagmur,ayak] · Sandalet (sandals) [yaz,ayak] · Mayo (swimsuit) [yaz] · Yağmurluk (raincoat) [yagmur,govde] · Hırka (cardigan) [govde] · Eşofman (tracksuit) [govde] · Spor ayakkabı (sneakers) [ayak] · Gözlük (glasses) [aksesuar] · Güneş gözlüğü (sunglasses) [yaz,aksesuar] · Şemsiye (umbrella) [yagmur,aksesuar] · Çanta (bag) [aksesuar]

**Zor (15)**
Yelek (vest) [govde] · Ceket (jacket) [govde] · Kravat (tie) [boyun] · Papyon (bow_tie) [boyun] · Önlük (apron) [govde] · Kemer (belt) [aksesuar] · Bot (ankle_boots) [kis,ayak] · Kasket (cap) [bas] · Kulaklık (earmuffs) [kis,bas] · Saat (wristwatch) [aksesuar,el] · Bilezik (bracelet) [aksesuar] · Kolye (necklace) [aksesuar,boyun] · Sırt çantası (backpack) [aksesuar] · Pelerin (cape) [govde] · Tulum (overalls) [govde]

---

## 6. Evimiz 🏠

Gruplar (oda): `[salon]` `[mutfak]` `[yatak_odasi]` `[banyo]` · İşlev: `[uyumak]` `[yemek]` `[temizlik]` `[oturmak]` `[isik]` `[giymek]`

**Kolay (16)**
Yatak (bed) [yatak_odasi,uyumak] · Yastık (pillow) [yatak_odasi,uyumak] · Masa (table) [salon,mutfak] · Sandalye (chair) [mutfak,oturmak] · Koltuk (sofa) [salon,oturmak] · Televizyon (television) [salon] · Kapı (door) · Pencere (window) · Lamba (lamp) [isik] · Buzdolabı (fridge) [mutfak] · Tabak (plate) [mutfak,yemek] · Bardak (glass) [mutfak,yemek] · Kaşık (spoon) [mutfak,yemek] · Diş fırçası (toothbrush) [banyo,temizlik] · Sabun (soap) [banyo,temizlik] · Havlu (towel) [banyo,temizlik]

**Orta (17)**
Fırın (oven) [mutfak] · Ocak (stove) [mutfak] · Tencere (pot) [mutfak] · Tava (pan) [mutfak] · Çatal (fork) [mutfak,yemek] · Çaydanlık (teapot) [mutfak] · Çamaşır makinesi (washing_machine) [banyo,temizlik] · Lavabo (sink) [banyo] · Küvet (bathtub) [banyo,temizlik] · Tuvalet (toilet) [banyo] · Ayna (mirror) [banyo] · Tarak (comb) [banyo] · Gardırop (wardrobe) [yatak_odasi,giymek] · Halı (carpet) [salon] · Perde (curtain) [salon] · Battaniye (blanket) [yatak_odasi,uyumak] · Saat (clock) [salon]

**Zor (17)**
Bulaşık makinesi (dishwasher) [mutfak,temizlik] · Süpürge (vacuum_cleaner) [temizlik] · Ütü (iron) [giymek] · Mikrodalga (microwave) [mutfak] · Su ısıtıcısı (kettle) [mutfak] · Mikser (mixer) [mutfak] · Saksı (flower_pot) [salon] · Kitaplık (bookshelf) [salon] · Komodin (nightstand) [yatak_odasi] · Şampuan (shampoo) [banyo,temizlik] · Diş macunu (toothpaste) [banyo,temizlik] · Saç kurutma makinesi (hair_dryer) [banyo] · Çöp kutusu (trash_can) [temizlik] · Anahtar (key) · Telefon (telephone) [salon] · Kumanda (remote_control) [salon] · Askı (hanger) [giymek]

**İşlev soruları (örnek):** Uyumak için hangisi? (yatak) · Suyu ne ile içeriz? (bardak) · Çorbayı ne ile içeriz? (kaşık) · Ellerimizi ne ile yıkarız? (sabun) · Ne ile kurulanırız? (havlu) · Yemekleri nerede saklarız? (buzdolabı) · Saçımızı ne ile tararız? (tarak) · Odayı ne aydınlatır? (lamba)

---

## 7. Okul ve Oyuncaklar 🎒

Gruplar: `[okul]` `[oyuncak]` `[park]` `[sanat]`

**Kolay (14)**
Top (ball) [oyuncak] · Oyuncak bebek (doll) [oyuncak] · Oyuncak ayı (teddy_bear) [oyuncak] · Oyuncak araba (toy_car) [oyuncak] · Küpler (blocks) [oyuncak] · Balon (balloon) [oyuncak] · Kalem (pencil) [okul] · Boya kalemi (crayon) [sanat] · Kitap (book) [okul] · Okul çantası (school_bag) [okul] · Kaydırak (slide) [park] · Salıncak (swing) [park] · Yapboz (puzzle) [oyuncak] · Uçurtma (kite) [oyuncak]

**Orta (14)**
Silgi (eraser) [okul] · Kalemtıraş (sharpener) [okul] · Defter (notebook) [okul] · Makas (scissors) [okul,sanat] · Yapıştırıcı (glue) [sanat] · Cetvel (ruler) [okul] · Tahta (board) [okul] · Atlama ipi (jump_rope) [oyuncak] · Tahterevalli (seesaw) [park] · Kum havuzu (sandbox) [park] · Kova ve kürek (bucket_spade) [oyuncak] · Oyun hamuru (play_dough) [sanat] · Fırça (paintbrush) [sanat] · Düdük (whistle) [oyuncak]

**Zor (14)**
Suluboya (watercolor) [sanat] · Tebeşir (chalk) [okul] · Kalemlik (pencil_case) [okul] · Dünya küresi (globe) [okul] · Okul sırası (school_desk) [okul] · Zil (school_bell) [okul] · Bilgisayar (computer) [okul] · Tırmanma duvarı (climbing_frame) [park] · Topaç (spinning_top) [oyuncak] · Yoyo (yoyo) [oyuncak] · Misket (marbles) [oyuncak] · Robot (toy_robot) [oyuncak] · Domino (dominoes) [oyuncak] · Hula hop (hula_hoop) [oyuncak]

---

## 8. Meslekler 👩‍⚕️

Her meslek için **kişi görseli + 1–2 araç/eşya + çalıştığı yer** (eşleştirme ve "Kim?" soruları için). Kişi görsellerinde cinsiyet ve görünüm çeşitliliği gözetilir.

**Kolay (10)**
Doktor (doctor) – stetoskop (stethoscope), hastane · Hemşire (nurse) – termometre (thermometer), hastane · Öğretmen (teacher) – tahta (board), okul · Polis (police_officer) – düdük (whistle), polis arabası · İtfaiyeci (firefighter) – hortum (fire_hose), itfaiye aracı · Aşçı (cook) – tencere (pot), mutfak · Şoför (driver) – direksiyon (steering_wheel), otobüs · Çiftçi (farmer) – traktör (tractor), tarla · Fırıncı (baker) – ekmek (bread), fırın · Diş hekimi (dentist) – diş fırçası (toothbrush)

**Orta (14)**
Postacı (postman) – mektup (letter) · Berber/Kuaför (hairdresser) – makas (scissors) · Pilot (pilot) – uçak (airplane) · Veteriner (vet) – köpek (dog) · Garson (waiter) – tepsi (tray) · Temizlik görevlisi (cleaner) – süpürge (broom) · İnşaat işçisi (builder) – baret (hard_hat) · Kasiyer (cashier) – yazar kasa (cash_register) · Ressam (painter) – fırça ve palet (palette) · Müzisyen (musician) – gitar (guitar) · Bahçıvan (gardener) – sulama kabı (watering_can) · Balıkçı (fisher) – olta (fishing_rod) · Kaptan (captain) – gemi (ship) · Eczacı (pharmacist) – ilaç kutusu (medicine)

**Zor (16)**
Marangoz (carpenter) – çekiç (hammer) · Tamirci (mechanic) – İngiliz anahtarı (wrench) · Terzi (tailor) – dikiş makinesi (sewing_machine) · Fotoğrafçı (photographer) – fotoğraf makinesi (camera) · Kütüphaneci (librarian) – kitaplar (books) · Astronot (astronaut) – roket (rocket) · Elektrikçi (electrician) – ampul (light_bulb) · Boyacı (house_painter) – rulo (paint_roller) · Çoban (shepherd) – koyun (sheep) · Arıcı (beekeeper) – kovan (beehive) · Mühendis (engineer) – plan (blueprint) · Hakem (referee) – düdük (whistle) · Sporcu (athlete) – madalya (medal) · Bilim insanı (scientist) – mikroskop (microscope) · Makinist (train_driver) – tren (train) · Kurye (courier) – koli (parcel)

**Soru örnekleri:** Ateşi kim söndürür? · Hastaları kim iyileştirir? · Ekmeği kim yapar? · Saçımızı kim keser? · Mektupları kim getirir? · Uçağı kim uçurur? · Hayvanları kim tedavi eder?

---

## 9. Doğa ve Mevsimler 🌱

Gruplar: `[gokyuzu]` `[hava_durumu]` `[bitki]` `[yer]` · Mevsim: `[ilkbahar]` `[yaz]` `[sonbahar]` `[kis]` · 🔊 yağmur, rüzgar, dalga, kuş cıvıltısı (yumuşatılmış)

**Kolay (12)**
Güneş (sun) [gokyuzu,yaz] · Ay (moon) [gokyuzu] · Yıldız (star) [gokyuzu] · Bulut (cloud) [gokyuzu] · Yağmur (rain) 🔊 [hava_durumu] · Kar (snow) [hava_durumu,kis] · Ağaç (tree) [bitki] · Çiçek (flower) [bitki,ilkbahar] · Deniz (sea) 🔊 [yer] · Dağ (mountain) [yer] · Gökkuşağı (rainbow) [gokyuzu] · Kardan adam (snowman) [kis]

**Orta (15)**
Rüzgar (wind) 🔊 [hava_durumu] · Şimşek (lightning) [hava_durumu] · Yaprak (leaf) [bitki,sonbahar] · Çimen (grass) [bitki] · Nehir (river) 🔊 [yer] · Göl (lake) [yer] · Orman (forest) [yer] · Kum (sand) [yer,yaz] · Taş (stone) [yer] · İlkbahar (spring) · Yaz (summer) · Sonbahar (autumn) · Kış (winter) · Gece (night) · Gündüz (day)

**Zor (15)**
Şelale (waterfall) 🔊 [yer] · Ada (island) [yer] · Çöl (desert) [yer] · Mağara (cave) [yer] · Volkan (volcano) [yer] · Sis (fog) [hava_durumu] · Dolu (hail) [hava_durumu] · Buz (ice) [kis] · Tohum (seed) [bitki] · Filiz (sprout) [bitki,ilkbahar] · Kozalak (pine_cone) [bitki,sonbahar] · Mantar (mushroom) [bitki] · Kaktüs (cactus) [bitki] · Gün doğumu (sunrise) [gokyuzu] · Dalga (wave) 🔊 [yer]

**Olay sıraları:** Tohum → filiz → çiçek · Bulut → yağmur → gökkuşağı · Kar yağar → kardan adam → güneş açar → erir · Yaprak yeşil → sarı → düşer

---

## 10. Müzik Aletleri 🎵

Hepsi 🔊 (her alet için 2–3 sn'lik yumuşak bir ezgi parçası). Gruplar: `[vurmali]` `[telli]` `[uflemeli]` `[tuslu]` `[geleneksel]`

**Kolay (8)**
Davul (drum) [vurmali] · Piyano (piano) [tuslu] · Gitar (guitar) [telli] · Flüt (recorder) [uflemeli] · Zil (bell) [vurmali] · Ksilofon (xylophone) [vurmali] · Marakas (maracas) [vurmali] · Tef (tambourine) [vurmali]

**Orta (10)**
Keman (violin) [telli] · Trompet (trumpet) [uflemeli] · Akordeon (accordion) [tuslu] · Mızıka (harmonica) [uflemeli] · Bağlama (baglama) [telli,geleneksel] · Darbuka (darbuka) [vurmali,geleneksel] · Ukulele (ukulele) [telli] · Üçgen (triangle) [vurmali] · Org (keyboard) [tuslu] · Kastanyet (castanets) [vurmali]

**Zor (12)**
Çello (cello) [telli] · Arp (harp) [telli] · Saksafon (saxophone) [uflemeli] · Klarnet (clarinet) [uflemeli] · Trombon (trombone) [uflemeli] · Yan flüt (flute) [uflemeli] · Ney (ney) [uflemeli,geleneksel] · Kanun (kanun) [telli,geleneksel] · Zurna (zurna) [uflemeli,geleneksel] · Ud (oud) [telli,geleneksel] · Kontrbas (double_bass) [telli] · Davul-zurna (davul_zurna) [geleneksel]

---

## 11. Vücudumuz 🧍

Görseller **sade illüstrasyon**: bir çocuk figürü üzerinde bölge vurgusu + tek başına bölge çizimi. Gruplar: `[yuz]` `[govde]` `[kol_el]` `[bacak_ayak]` · Duyu: `[gorme]` `[isitme]` `[koklama]` `[tatma]` `[dokunma]`

**Kolay (10)**
Göz (eye) [yuz,gorme] · Kulak (ear) [yuz,isitme] · Burun (nose) [yuz,koklama] · Ağız (mouth) [yuz,tatma] · El (hand) [kol_el,dokunma] · Ayak (foot) [bacak_ayak] · Saç (hair) [yuz] · Karın (tummy) [govde] · Baş (head) · Diş (teeth) [yuz]

**Orta (12)**
Kol (arm) [kol_el] · Bacak (leg) [bacak_ayak] · Parmak (finger) [kol_el] · Dil (tongue) [yuz,tatma] · Kaş (eyebrow) [yuz] · Diz (knee) [bacak_ayak] · Omuz (shoulder) [govde] · Boyun (neck) [govde] · Sırt (back) [govde] · Yanak (cheek) [yuz] · Dudak (lips) [yuz] · Çene (chin) [yuz]

**Zor (12)**
Dirsek (elbow) [kol_el] · Bilek (wrist) [kol_el] · Topuk (heel) [bacak_ayak] · Tırnak (nail) [kol_el] · Kirpik (eyelash) [yuz] · Alın (forehead) [yuz] · Bel (waist) [govde] · Ayak bileği (ankle) [bacak_ayak] · Avuç içi (palm) [kol_el] · Ayak parmağı (toe) [bacak_ayak] · Göbek (belly_button) [govde] · Kalça (hip) [govde]

**Soru örnekleri:** Ne ile görürüz? · Ne ile duyarız? · Ne ile koklarız? · Ne ile tadarız? · Eldiveni nereye giyeriz? · Şapkayı nereye takarız?

---

## 12. Renkler 🎨

Renk kartı: düz renk daire/boya lekesi (kenarları yumuşak). Her renk için ayrıca **4 renkli nesne** fotoğrafı ("Kırmızı olanı bul", "Renge göre grupla" için).

**Kolay (4):** Kırmızı (red) ★ · Mavi (blue) ★ · Sarı (yellow) ★ · Yeşil (green) ★
**Orta (6):** Turuncu (orange) ★ · Mor (purple) ★ · Pembe (pink) ★ · Kahverengi (brown) ★ · Siyah (black) ★ · Beyaz (white) ★
**Zor (6):** Gri (gray) ★ · Lacivert (navy) · Açık mavi (light_blue) · Turkuaz (turquoise) · Altın (gold) · Gümüş (silver)

**Renkli nesneler (örnek, renk başına 4):** Kırmızı: domates, çilek, itfaiye aracı, elma · Mavi: deniz, kot pantolon, mavi top, mavi kova · Sarı: muz, limon, civciv, güneş · Yeşil: yaprak, salatalık, kurbağa, çimen · Turuncu: portakal, havuç, balkabağı, turuncu top · Mor: üzüm, patlıcan, mor çiçek, erik · Pembe: flamingo, pembe balon, pamuk şeker, pembe çiçek · Kahverengi: ayı, çikolata, kütük, kestane · Siyah: siyah kedi, lastik, siyah ayakkabı, piyano tuşu · Beyaz: süt, kar, koyun, bulut · Gri: fil, fare, taş, bulutlu gök …

---

## 13. Şekiller 🔷

Şekil kartı: düz renkli, kalın, kenarı yumuşatılmış şekil. Her şekil için **3–4 gerçek nesne** ("Top hangi şekle benziyor?").

**Kolay (4):** Daire (circle) · Kare (square) · Üçgen (triangle) · Yıldız (star)
**Orta (6):** Dikdörtgen (rectangle) · Kalp (heart) · Oval (oval) · Hilal (crescent) · Artı (cross) · Ok (arrow)
**Zor (8):** Altıgen (hexagon) · Beşgen (pentagon) · Eşkenar dörtgen (rhombus) · Yamuk (trapezoid) · Küp (cube) · Küre (sphere) · Silindir (cylinder) · Koni (cone)

**Nesneler (örnek):** Daire: top, saat, pizza, tekerlek · Kare: pencere, kutu, kraker, sandviç · Üçgen: dilim pizza, çatı, trafik levhası, çadır · Dikdörtgen: kapı, kitap, telefon, tahta · Yıldız: deniz yıldızı, yılbaşı süsü · Kalp: kalp balon, kalp kurabiye · Oval: yumurta, ayna · Hilal: ay, kruvasan · Küre: top, dünya küresi · Silindir: bardak, konserve, mum · Koni: dondurma külahı, trafik konisi

---

## 14. Sayılar 🔢

- **Kolay:** 1–5 (rakam + 1–5 nesne). Bölüm 1: 1–3, Bölüm 2: 1–5.
- **Orta:** 1–10. Bölüm 3: 6–10, Bölüm 4: sonraki sayı ve karşılaştırma 1–10 (mevcut iki oyun).
- **Zor:** 0–20. Bölüm 5: 0 ve 11–20, Bölüm 6: ikişer sayma, az/çok/eşit, basit toplama görselli (2 elma + 1 elma).
- Mevcut sesler ★: Bir–On, "ve", "büyük/eşit/küçük", "Hangisi sonraki sayı?", "Bu sayıları karşılaştır bakalım". Eklenecek: Sıfır, On bir–Yirmi, "Kaç tane?", "Daha çok olan hangisi?", "Daha az olan hangisi?".
- Sayma nesneleri: diğer temaların Kolay öğeleri (elma, top, araba, kedi…) yeniden kullanılır.

---

## 15. Duygular 😊

Her duygu için **en az 4 farklı yüz** (çocuk/yetişkin, farklı cinsiyet ve ten rengi; fotoğraf veya sade illüstrasyon) + 2–3 **durum resmi**.

**Kolay (2):** Mutlu (happy) · Üzgün (sad)
**Orta (5):** Kızgın (angry) · Korkmuş (scared) · Şaşkın (surprised) · Uykulu (sleepy) · Gülen/Kahkaha (laughing)
**Zor (7):** Sakin (calm) · Utangaç (shy) · Gururlu (proud) · Sıkılmış (bored) · Endişeli (worried) · Heyecanlı (excited) · Tiksinmiş (disgusted)

**Durum örnekleri:** Doğum günü pastası → mutlu · Dondurması düştü → üzgün · Oyuncağı elinden alındı → kızgın · Karanlıkta gök gürültüsü → korkmuş · Sürpriz hediye → şaşkın · Resmini bitirdi → gururlu · Yeni sınıfa girdi → utangaç

---

## 16. Harfler 🔤 (Faz 5)

Türk alfabesinin 29 harfi (A, B, C, Ç, D, E, F, G, Ğ, H, I, İ, J, K, L, M, N, O, Ö, P, R, S, Ş, T, U, Ü, V, Y, Z). Her harf için: harf sesi, büyük/küçük harf görseli, harfle başlayan 2 kelime (diğer temalardan: A–arı, B–balık, C–ceket, Ç–çilek…). Kolay: sesli harfler; Orta: sık ünsüzler; Zor: Ğ, J, V, Z ve büyük-küçük eşleştirme.

---

## 17. Sıralama İçerikleri (olay örgüsü ve rutinler)

| Kod | Adımlar | Katman |
|---|---|---|
| `seq.plant` | Tohum ekilir → yağmur yağar → çiçek açar | Kolay (3) |
| `seq.handwash` | Musluğu aç → sabunla → durula → kurula | Orta (4) |
| `seq.toothbrush` | Macun sür → fırçala → ağzını çalkala | Kolay (3) |
| `seq.dress` | İç çamaşır → pantolon → çorap → ayakkabı | Orta (4) |
| `seq.morning` | Uyan → yüzünü yıka → kahvaltı yap → okula git | Orta (4) |
| `seq.bedtime` | Pijama giy → dişlerini fırçala → masal → uyu | Orta (4) |
| `seq.cake` | Malzeme → karıştır → fırına koy → ye | Zor (4) |
| `seq.snowman` | Kar yağar → kardan adam yap → güneş çıkar → erir | Zor (4) |
| `seq.chick` | Yumurta → çatlar → civciv çıkar | Kolay (3) |
| `seq.butterfly` | Yumurta → tırtıl → koza → kelebek | Zor (4) |
| `seq.apple` | Çiçek → küçük elma → büyük elma → toplanır | Zor (4) |
| `seq.size3` / `seq.size4` | Büyükten küçüğe (her temadan) | Kolay/Orta |

## 18. Sosyal Hikayeler (Faz 5)

Her hikaye 5–7 sayfa, sayfa başına bir resim ve 1 kısa cümle, sonunda 1–2 soru. İlk set: Doktora gidiyorum · Berbere gidiyorum · Okula gidiyorum · Sırada beklerim · Oyuncağımı paylaşırım · Ellerimi yıkarım · Markette sakin kalırım · Arabada kemerimi takarım · Yeni bir arkadaş · Kızgın olduğumda nefes alırım.

---

## 19. Para ve Zaman 💰⏰ (Otsimo ekranlarından, Faz 4)

Gruplar: `[bozuk_para]` `[kagit_para]` `[saat]` `[gun_bolumu]` `[gun]`
Para görselleri güncel Türk lirası; görseller TCMB görsel kullanım kurallarına uygun, "ÖRNEKTİR" filigranlı veya stilize illüstrasyon olarak hazırlanır.

**Kolay (10)**
1 Lira (one_lira) [bozuk_para] · 5 Lira bozuk (five_lira_coin) [bozuk_para] · 10 Lira (ten_lira_note) [kagit_para] · 20 Lira (twenty_lira_note) [kagit_para] · Saat (clock) [saat] · Sabah (morning) [gun_bolumu] · Öğle (noon) [gun_bolumu] · Akşam (evening) [gun_bolumu] · Gece (night) [gun_bolumu] · Cüzdan (wallet)
**Orta (12)**
50 Kuruş (fifty_kurus) [bozuk_para] · 25 Kuruş (twentyfive_kurus) [bozuk_para] · 5 Lira kağıt (five_lira_note) [kagit_para] · 50 Lira (fifty_lira_note) [kagit_para] · 100 Lira (hundred_lira_note) [kagit_para] · Saat 1–12 tam saatler (o_clock) [saat] · Pazartesi–Pazar (7 gün, tek öğe grubu: weekdays) [gun] · Kumbara (piggy_bank) · Kasa (cash_register) · Alışveriş sepeti (shopping_basket) · Kredi kartı (card) · Takvim (calendar)
**Zor (12)**
10 Kuruş (ten_kurus) · 5 Kuruş (five_kurus) · 200 Lira (two_hundred_lira_note) · Buçuklar (half_past) [saat] · Çeyrekler (quarter) [saat] · Dün/Bugün/Yarın (yesterday_today_tomorrow) · Aylar (months) · Mevsim takvimi (season_calendar) · Kum saati (hourglass) · Kol saati (wristwatch) · Çalar saat (alarm_clock) · Para üstü (change)

**Oyunlar:** G56 Bozuk Paraları Tanı, G57 Kağıt Paraları Tanı, G58 Saati Kur, G43 Olay Sırası (sabah → öğle → akşam → gece), G36 Karşılaştır (Zor: "Hangisi daha çok para?").

---

## Üretim notları

- Görsel ve ses dosya adı: `images/{tema}/{slug}_{n}.webp`, `audio/{dil}/{tema}/{slug}.mp3`, `sfx/{tema}/{slug}.mp3`.
- Her öğe için en az 1, Kolay/Orta katmanlarda tercihen **2–3 görsel** (genelleme).
- Seslendirme: öğe adı tek başına ("Kedi") ve soru kalıbı ayrı ("… hangisi?"). Böylece her öğe için tek ses dosyası yeter.
- Toplu üretim için `content_source.csv`: `theme, tier, slug, name_tr, name_en, tags, needs_sfx, image_status, audio_status`. Agent bu CSV'den JSON üreten bir betik yazmalı.
- Lisans: her görselin kaynağı `assets/LICENSES.md`'de.
