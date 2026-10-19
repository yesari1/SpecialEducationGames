# Resmî DeepSeek çalışanı

Aktif sağlayıcı resmî DeepSeek API: https://api.deepseek.com/chat/completions
Model: deepseek-flash (resmî belgede DeepSeek-V4.1-Flash).
Belgeler: https://api-docs.deepseek.com/ ve https://api-docs.deepseek.com/quick_start/pricing/

Anahtarı gizli girişle kaydet:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\_MobileProjects\SpecialEducationGames\tools\set_deepseek_key.ps1"
```

Anahtar proje dışında .codex/secrets/deepseek.credential.xml içinde Windows DPAPI ile kullanıcının hesabına bağlı şifrelenir. InferX anahtarı ayrı kalır; DeepSeek'e gönderilmez. Yeni anahtar sohbete veya Flutter uygulamasına yazılmaz.

Görev çağrısı:

```powershell
./tools/run_deepseek_agent.ps1 -TaskFile artifacts/inferx/task.txt -WriteScope lib/features/example/example.dart -AllowChecks
```

Örnek yolları gerçek göreve göre değiştirin. Yazma kapsamı verilmezse salt okuma. Önceki dosya/hash/yedek ve komut sınırları korunur; aynı araç motoru kullanılır. Varsayılan thinking disabled ve JSON mode açık; bunlar çalışma başına değiştirilebilir. API hatasında otomatik retry veya InferX'e geçiş yok. Kayıtlar artifacts/deepseek_agent altında tutulur. OS sandbox değildir; Flutter testleri mevcut kullanıcı yetkileriyle çalışır. Canlı erişim kullanıcı anahtarı girdikten sonra doğrulanacak.

## Güncel aktarım
run_deepseek_agent.ps1 artık her tur yeni curl süreci açmak yerine görev boyunca tek standart SDK istemcisi kullanır. Araç Python ortamı .codex/tools/deepseek-venv içindedir; paketler tools/requirements-deepseek-agent.txt ile sabittir. Sertifika doğrulaması açık, max_retries=0, redirect kapalıdır. Anahtar kaydı değişmedi. Tanı ve karşılaştırma artifacts/deepseek/connection_diagnostics/README.md içinde; eski curl/urllib yolları tarihsel/test amaçlı kalır, aktif wrapper bunları seçmez.
