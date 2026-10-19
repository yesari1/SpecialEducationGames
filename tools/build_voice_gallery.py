import html,json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'voice_samples'
manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
rows=''.join(f'<article><h2>{s["language"].upper()} · {html.escape(s["text"])}</h2><audio controls preload="none" src="{s["file"]}"></audio><a href="{s["file"]}" download>İndir / Download</a></article>' for s in manifest['samples'])
(root/'index.html').write_text('''<!doctype html><html lang="tr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Kadın sesi örnekleri · Voice samples</title><style>body{font:18px system-ui;background:#F7F5F0;color:#2F3A45;max-width:1000px;margin:40px auto;padding:24px}h1{font-size:36px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:24px}article{background:white;border:1px solid #E4DFD6;border-radius:28px;padding:24px}h2{font-size:22px}audio{width:100%}a{display:block;margin-top:16px;color:#33796B}p{line-height:1.6}</style><h1>Yumuşak kadın sesi · Soft female voice</h1><p>ElevenLabs · Lauren – Friendly, Comforting and Soft<br>10 Türkçe + 10 İngilizce örnek. Hız: 0.9. Bunlar değerlendirme içindir; uygulamanın mevcut sesleri değiştirilmedi.</p><main>'''+rows+'</main></html>',encoding='utf-8')
print(root/'index.html')
for language in ('tr','en'):
    lines=[]
    for sample in manifest['samples']:
        if sample['language']==language:
            lines.append("file '"+(root/sample['file']).resolve().as_posix()+"'\n")
    (root/f'playlist_{language}.txt').write_text(''.join(lines),encoding='utf-8')
