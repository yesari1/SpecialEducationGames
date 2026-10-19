# InferX yardımcı ajan

`deepseek-v4.1-flash`, kullanıcı tarafından sağlanan InferX endpoint'i üzerinden çalışır. Codex'in yerleşik alt ajan listesine eklenmez. Son inceleme, entegrasyon ve test değerlendirmesi Codex'tedir.

## Kullanım

Token bir kez `set_inferx_token.ps1` ile girilir. Windows DPAPI kaydı proje dışında tutulur. Görevi UTF-8 metin dosyasına yazın, sonra PowerShell'de:

```powershell
./tools/run_inferx_agent.ps1 -TaskFile artifacts/inferx/task.txt -WriteScope lib/features/example/example.dart -AllowChecks -MaxSteps 12
```

Örnekteki görev ve yazma yollarını gerçek görevle değiştirin. Yazma kapsamı tek dosya veya dizin olabilir; PowerShell'de birden fazla kapsam virgülle ayrılır. `WriteScope` verilmezse yalnız okur. `AllowChecks` verilmezse komut çalıştırmaz. Model yalnız `flutter analyze --no-pub` ve belirli bir `test/*_test.dart` için `flutter test --no-pub` çalıştırabilir. Bağımlılık yükleme, keyfi terminal komutu, silme, yayın veya imza değiştirme aracı bulunmaz.

## Erişim ve kayıt

- Okuma: `lib`, `test`, `integration_test`, `docs` altındaki izinli metin uzantıları ve kökteki belirli proje belgeleri. Gizli dosya, credential, Firebase options, native yapılandırma, araç altyapısının kendisi ve proje dışı yollar erişime kapalıdır. Sembolik bağlar ve Windows reparse point'leri reddedilir.
- Dosyalar yalnız model istediğinde okunup dış sağlayıcıya gönderilir; tüm proje otomatik yüklenmez. Görev dosyasına gizli bilgi koymayın. Bilinen ortam token'leri gönderilen metinden ve işlem kaydından temizlenir; bu, her olası gömülü sırrın bulunacağı garantisi değildir.
- Yazma, açık kapsam ve güncel SHA256 eşleşmesi ister. İlk dosya yedeği, yeni dosya işareti, işlem sonuçları, bitiş durumu ve model özeti `artifacts/inferx_agent/<run>/` içinde kalır. Başka birinin aradaki değişikliği eski hash ile ezilmez.
- En fazla 30 model çağrısı, çağrı başına varsayılan 4096, açık MaxOutputTokens seçimiyle en fazla 8192 çıktı token'i, 120 saniye ağ/check zaman aşımı; varsayılan 12 adım. Otomatik API retry yok. Her tur artan bağlam gönderir; bunlar maliyet tavanı garantisi değildir.
- `finished`, modelin işi bitirdiğini bildirdiği anlamına gelir; otomatik kabul veya test başarı garantisi değildir. `step_limit`, `context_limit`, `request_failed` sonrasında kısmi değişiklikler kalabilir. Yedek ve log ile inceleyin; otomatik geri alma başka değişiklikleri ezmemek için yapılmaz.

Bu yol denetimleri **işletim sistemi sandbox'ı değildir**. Flutter testleri bilgisayardaki mevcut kullanıcı yetkileriyle kod çalıştırır; yalnız güvenilir, koordinatörün incelediği görevlerde `AllowChecks` açılmalıdır. Güç, Gemini ve mevcut otomasyon ayarları değiştirilmez. Modelin dosya yazabilmesi ona sınırsız bilgisayar erişimi vermez.

## Proje yürütme politikası
Kullanıcının 16 Ekim talimatıyla tüm uygulama işleri bu DeepSeek çalışanına verilir. Codex görev kapsamını belirler, sonucu bağımsız inceler/test eder ve somut düzeltme görevlerini aynı modele geri gönderir. Güncel kalıcı politika AGENTS.md içindedir; çalışma kuyruğu docs/DEEPSEEK_WORK_QUEUE.md dosyasındadır. Ağ veya çıktı hatasında sessizce Codex uygulayıcısına geçilmez. Orkestrasyon yapılandırmasını ve kontrol belgelerini Codex tutabilir.


## Küçük yamalar
replace eylemi tekil exact old/new metnini güncel SHA256 ile değiştirir; yazma kapsamı ve ilk yedek aynı kalır. Satır sonları/BOM dahil diğer byte'lar korunur; birden fazla eşleşme veya eski hash reddedilir. Kısa yama görevleri büyük tam-dosya yanıtlarına alternatif olarak kullanılabilir; servis hatasının nedeni hakkında garanti vermez.

## InferX çıktı biçimi ve düşünme ayarı
Kısa dosya/yama görevlerinde -Thinking disabled -JsonMode seçenekleri canlı denendi. Resmî DeepSeek seçeneği thinking.type'dır (https://api-docs.deepseek.com/guides/thinking_mode/); InferX kabulü ayrıca request-metrics.jsonl içinde reasoning_chars0/stop ve yazılmış eylemlerle gözlendi. JsonMode response_format json_object ister. Varsayılanlar sağlayıcının düşünme seçimi ve serbest JSON istemidir; görevde bu seçenekleri açıkça verin. Metrikler reasoning içeriğini değil yalnız uzunluk/kullanım sayılarını kaydeder. HTTP500 hâlâ aralıklı görüldü; bu ayarlar tüm servis sorunlarını çözdü sayılmaz.

17 Ekim resmî DeepSeek güncellemesi: run_deepseek_agent.ps1 artık JsonMode varsayılan false kullanır. Model SYSTEM ile tek JSON eylemine yönlendirilir; parse_actions/hash/kapsam/tekmutasyon kontrolleri korunur. İstenirse -JsonMode açık test edilebilir; otomatik fallback/retry yok. Nedeni JSONOutput modunda belgelenmiş boşiçerik riski. nonwhite_content_chars metriği boşlukyalnız yanıtı ayrıca ayırır. SDK/host/model/SSL/redirect/retry/anahtar yönetimi değişmedi.
