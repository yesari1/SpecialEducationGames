"""Build a local review page for the selected İrem/Laura takes."""
import html
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'artifacts' / 'voice_samples_selected'
manifest = json.loads((root / 'manifest.json').read_text(encoding='utf-8'))
config = manifest['configuration']
rows = []
for sample in manifest['samples']:
    path = root / sample['file']
    probe = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_entries', 'format=duration:stream=codec_name,sample_rate,channels',
        '-of', 'json', str(path)], text=True))
    duration = float(probe['format']['duration'])
    if not 0.15 < duration < 20:
        raise RuntimeError(f'Unexpected duration: {path.name}')
    sample['validation'] = dict(duration_seconds=duration, streams=probe['streams'])
    voice = config['voices'][sample['language']]['name']
    rows.append(f'<article><span>{sample["language"].upper()} · {html.escape(voice)}</span>'
                f'<h2>{html.escape(sample["text"])}</h2>'
                f'<audio controls preload="none" src="{sample["file"]}"></audio>'
                f'<small>{duration:.2f} s</small></article>')
(root / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
(root / 'index.html').write_text('''<!doctype html><html lang="tr"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>İrem / Laura · Ses örnekleri</title>
<style>body{font:18px system-ui;background:#fff;color:#173651;max-width:1100px;margin:32px auto;padding:24px}h1{font-size:34px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:20px}article{background:#f5fbff;border:2px solid #dceef7;border-radius:24px;padding:24px}span,small{font-size:14px;color:#466275}h2{font-size:23px}audio{width:100%}small{display:block;margin-top:10px}p{line-height:1.6}</style>
<h1>Türkçe İrem · English Laura</h1><p>Eleven Multilingual v2 · 10 Türkçe + 10 İngilizce örnek.<br>
Hız 1.0 · Stability 0.35 · Similarity 0.75 · Style 0.43.<br>Sürgü değerleri ekran görüntüsünden yaklaşık alınmıştır. Tek sözcükler noktayla biter.<br>Eski Lauren örnekleri korunur. Bu sayfa değerlendirme içindir; uygulamadaki ses dosyaları değiştirilmedi.</p><main>'''
    + ''.join(rows) + '</main></html>', encoding='utf-8')
for language in ('tr', 'en'):
    files = [s['file'] for s in manifest['samples'] if s['language'] == language]
    (root / f'playlist_{language}.txt').write_text(''.join(f"file '{name}'\n" for name in files), encoding='utf-8')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0',
                    '-i', f'playlist_{language}.txt', '-c:a', 'libmp3lame', '-b:a', '128k', f'{language}-selected-samples.mp3'],
                   cwd=root, check=True)
print(f'{len(rows)} valid MP3 files; gallery: {root / "index.html"}')
