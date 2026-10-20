# Hesap, deneme ve ödeme (R33)

## Uygulamada ne var

- **Ücretsiz sürüm:** hesap gerekmez. 6 ücretsiz oyun kartı (Kolay + Orta) her zaman açık; liste Firestore `config/app.freeGames` ile değiştirilebilir. Zor seviye ve diğer oyunlar Premium.
- **Ücretsiz deneme:** Google hesabı başına bir kez, ödeme bilgisi istenmeden, `config/app.trialDays` gün (varsayılan 7). Ebeveyn alanında Premium sayfasında: "Google ile giriş yap ve başla". Başlangıç zamanı sunucuda `trials/{uid}` belgesinde tutulur (yalnız `startedAt`, sunucu saati). Uygulama silinip kurulsa da ya da başka cihazda aynı hesapla tekrar başlatılamaz. Süre bitince profil otomatik olarak ücretsiz sürüme döner.
- **Satın alma (Google Play Billing):**
  - Abonelik `premium`, temel planlar `monthly` ve `yearly`.
  - Tek seferlik ürün `premium_lifetime` (tüketilmeyen).
  - Fiyatlar her zaman Play'den gelir (TL/EUR/USD yerelleştirilmiş); uygulamada fiyat yazılı değil.
  - "Satın alımları geri yükle" ve "Aboneliği yönet" (Play abonelik sayfası) var.
- **Doğrulama:** satın alma cihazda Play'in "sahip olunan ürünler" yanıtıyla doğrulanır. Sunucu tarafı doğrulama (Cloud Functions / Play Developer API) yok; bu bilinçli bir sınırlama. Abonelik, internetsiz 7 gün geçerli kalır; tek seferlik ürün Play iade bildirene kadar kalır.
- **Aile politikası:** giriş, deneme ve satın alma yalnız ebeveyn alanında, ebeveyn kapısının arkasında (dikey ekran). Çocuk modunda satın alma ya da giriş istemi yok.
- **Firestore'dan değiştirilebilenler (`config/app`):**
  - `freeGames` (tam 6 kart)
  - `trialDays` (1–30)
  - `paywallText` (`{tr, en}` başlık)
  - `privacyUrl` ve `termsUrl` (yalnız `https`; boşsa bağlantı gizlenir)
  - `disabledGames`, `hiddenThemes`, `newBadge`, `gameOrder`, `featuredTheme`, `announcementId`, `minSupportedVersion`, `difficultyDefaults`
- **Firestore'da tutulanlar:**
  - `trials/{uid}`: yalnız `startedAt`.
  - `families/{uid}/profiles/...`: ebeveyn onayıyla günlük özetler; mevcut özet senkronu, ham seçim ya da kimlik yok.
  - `announcements/{id}`: ebeveyn duyuruları.
  - Kurallar: `firebase/firestore.rules`. Emülatörde 11/11 kural testi geçiyor (`firebase/rules-tests`).

## Yunus'un yapması gerekenler

### 1. Firebase konsolu (proje `specialeducationgames`)

1. **Firestore'u açın:** Firestore Database → Create database (production mode, bölge `eur3` ya da `europe-west1`). Önceki denemelerde API kapalı olduğu için 403 dönüyordu.
2. **Google ile girişi açın:** Authentication → Sign-in method → Google → Enable; destek e-postanızı seçin.
3. **Parmak izlerini ekleyin:** Project settings → Your apps → Android uygulaması `com.YeS.OzelEgitimOyunlari` → Add fingerprint:
   - **Debug anahtarı** (bu bilgisayardaki test APK'ları; R33 dahil tüm test derlemeleri bununla imzalı):
     - SHA-1 `A6:C3:0F:E0:AB:92:AA:40:4F:8A:03:98:BB:16:F7:00:49:72:78:78`
     - SHA-256 `79:DC:98:FD:C3:A2:09:64:B2:FC:24:FF:E4:93:62:F5:FE:57:21:4F:8A:4E:15:6D:C7:72:5F:5F:24:EE:59:59`
   - **Play Console → Uygulama bütünlüğü → Uygulama imzalama:** "App signing key certificate" ve "Upload key certificate" altındaki SHA-1 ve SHA-256 değerleri. Play'den indirilen uygulamada Google ile giriş için bunlar şart.
   - Yükleme (upload) anahtarı bu depoda yok; dokunmadım.
4. **OAuth kontrolü:** Google Cloud Console → APIs & Services → Credentials. Web istemcisi `579874152426-e7a15kto2l2nhmfnhfdmoc3a5cnnpfk6` var olmalı (uygulama bunu `serverClientId` olarak kullanıyor). Parmak izleri eklenince Android istemcileri otomatik oluşur. OAuth consent ekranında uygulama adı, destek e-postası ve gizlilik politikası bağlantısı doldurulmalı.
5. **Kuralları yükleyin** (bu bilgisayarda; Firebase CLI kurulu ama oturum yok):

   ```
   firebase login
   cd D:\_MobileProjects\SpecialEducationGames\firebase
   firebase deploy --only firestore:rules --project specialeducationgames
   ```

6. **İsteğe bağlı:** Firestore'da `config/app` belgesini oluşturun. Örnek alanlar: `trialDays: 7`, `privacyUrl: "https://..."`, `termsUrl: "https://..."`, `freeGames: [...6 kart...]`. Konsoldan elle yazılabilir; yazma yalnız `admins/{uid}` belgesi olan hesaplara açık, konsol bu kurala takılmaz.

### 2. Play Console

1. **Abonelik:** Ürün kimliği `premium`.
   - Temel plan `monthly`: otomatik yenilenen, 1 ay. Önerilen 59,99 TL; ABD 7,99 USD, Euro bölgesi 7,99 €, Birleşik Krallık 6,99 £ (bkz. `docs/pazar-arastirmasi-2026-10.md`).
   - Temel plan `yearly`: 1 yıl. Önerilen 449,99 TL; 39,99–49,99 USD.
   - Play tarafında ücretsiz deneme teklifi **eklemeyin**. Deneme uygulama içinde, ödeme bilgisi istemeden veriliyor. İki deneme kafa karıştırır.
2. **Tek seferlik ürün:** Uygulama içi ürün kimliği `premium_lifetime` (tüketilmeyen). Önerilen 799,99 TL; 79,99–99,99 USD.
3. **Lisans test kullanıcıları:** Setup → License testing → kendi Gmail adresiniz. Test satın alımları ücretsiz olur.
4. **Dahili test kanalı:** Billing yalnız Play'den yüklenmiş ve Play'e yüklenmiş sürümle çalışır. Release AAB'yi kendi upload anahtarınızla imzalayıp dahili teste yükleyin (versionCode ≥ 15 olmalı). Benim test APK'larım debug imzalı; Billing'i gerçekten bu yolla test etmek gerekir.
5. **Politika:**
   - Gizlilik politikası: https://yesastudio.com/ozel-egitim-oyunlari/privacy/ (yayında; koşullar `/terms/`, hesap silme `/delete-account/`). Uygulama bu bağlantıları varsayılan olarak gösterir; `config/app.privacyUrl`/`termsUrl` ile değiştirilebilir.
   - Data safety ve diğer beyanlar: soru soru cevaplar `docs/play-data-safety.md` içinde.
   - Hesap silme: uygulama içinde Aile → Hesap → "Hesabı ve bulut verilerini sil" (sunucu fonksiyonu gerekmez); web için yukarıdaki sayfa.

### 3. Benden sonra (bu adımlar bitince)

- Gerçek cihazda: Premium sayfası → Google ile giriş → deneme başlar. Aynı hesapla tekrar denenince "deneme kullanıldı" yazmalı. 7 gün sonra (ya da `config/app.trialDays: 1` ile 1 gün sonra) ücretsiz sürüme dönmeli.
- Dahili test sürümünde lisans test hesabıyla aylık, yıllık ve tek seferlik satın alma, iptal ve geri yükleme.
