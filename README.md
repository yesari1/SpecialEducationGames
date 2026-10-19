# Özel Eğitim Oyunları

Türkçe ve İngilizce Flutter yeniden yazımı. Android paket adı `com.YeS.OzelEgitimOyunlari`, sürüm `2.0.0+14`.

Geliştirme sürümüdür; yayın hazırlığı tamamlanmadı. Yapılanlar ve kalanlar: [TODO.md](TODO.md). Test kanıtları ve çalışma geçmişi: [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

## Çalıştırma

```powershell
flutter pub get
flutter emulators --launch Pixel_9a
flutter run -d emulator-5554
```

## Doğrulama

```powershell
flutter analyze
flutter test
flutter test integration_test/app_flow_test.dart -d emulator-5554
```

Entegrasyon testi geçici bellek veritabanı kullanır. Üretim profilleriyle karışmaz. Yatay telefon (800×360) ve tablet (1280×800) düzenlerini denetler. Son kullanıcı talebiyle uygulamanın hedefi yalnızca yatay kullanımdır.

## İçerik

```powershell
python tools/build_content.py
```

Katalogdan CSV ve JSON üretir; sahibinin eski Unity projesinden görsel/sesleri kopyalar. Kaynak proje değişmez. İçerik JSON'da olsa bile görsel/ses hazır olduğu anlamına gelmez; `assets/content/migration_report.json` eksikleri listeler. Mevcut varlıkların kaynakları `assets/LICENSES.md` içindedir.

## Ses denemeleri

`voice_samples/index.html`: Lauren kadın sesiyle 10 Türkçe + 10 İngilizce örnek. Birleştirilmiş dinleme dosyaları: `Turkce-ornekler.mp3`, `English-samples.mp3`. Üretim ayarları `manifest.json` içinde. Kullanıcı onaylayana kadar uygulamanın eski sesleri korunur. Anahtar yalnızca `ELEVENLABS_API_KEY` ortam değişkeninden okunur, uygulamaya dahil edilmez.

## Mağaza

Fiyatlar sabit yazılmaz. Play Billing, `premium` ürünü ve `monthly` / `yearly` planlarını sorgular. Yalnızca Play'in gerçekten döndürdüğü `trial-7d` teklifi için 7 günlük deneme gösterilir. Debug emülatörü, gerçek lisans testi veya yayın imzası doğrulamasının yerine geçmez.
