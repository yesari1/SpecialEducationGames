"""Installs the new theme covers and Play Park tiles.

    python -I tools/home_sections/install_covers.py

Reads artifacts/illustrations-home/originals/, crops each picture to its
subject, centres it on a 512 transparent square and records it in the folder's
MANIFEST.json (same framing as the older covers).
"""
import hashlib
import json
from datetime import date
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ORIGINALS = ROOT / 'artifacts/illustrations-home/originals'
TARGET_SIDE = 448


def fit(src, out):
    im = Image.open(src).convert('RGBA')
    box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
    sub = im.crop(box)
    scale = TARGET_SIDE / max(sub.size)
    sub = sub.resize((round(sub.width * scale), round(sub.height * scale)), Image.LANCZOS)
    canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    canvas.paste(sub, ((512 - sub.width) // 2, (512 - sub.height) // 2))
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, optimize=True)


def main():
    records = {}
    for src in sorted(ORIGINALS.glob('*.png')):
        folder = 'themes' if src.stem.startswith('cover_') else 'park'
        rel = f'assets/illustrations/{folder}/{src.name}'
        fit(src, ROOT / rel)
        records.setdefault(folder, []).append({
            'name': src.stem, 'path': rel, 'size': [512, 512],
            'original': src.relative_to(ROOT).as_posix(),
            'originalSha256': hashlib.sha256(src.read_bytes()).hexdigest(),
            'sha256': hashlib.sha256((ROOT / rel).read_bytes()).hexdigest(),
            'generator': 'ChatGPT image generation via Codex CLI (gpt-6.1-sol), owner-approved for illustrations',
            'generatedOn': date.today().isoformat(), 'masterPrompt': 'docs/illustration-style.md',
        })
    for folder, assets in records.items():
        path = ROOT / f'assets/illustrations/{folder}/MANIFEST.json'
        manifest = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {'style': 'SEG soft clay', 'assets': []}
        names = {a['name'] for a in assets}
        manifest['assets'] = [a for a in manifest['assets'] if a['name'] not in names] + assets
        path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print({k: len(v) for k, v in records.items()})


if __name__ == '__main__':
    main()
