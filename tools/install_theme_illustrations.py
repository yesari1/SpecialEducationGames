"""Installs the drawn item pictures of the Emotions and Our Body themes.

    python -I tools/install_theme_illustrations.py emotions body

Yunus (6 Nov 2026) chose drawings over photos for these two themes. The
pictures were made with ChatGPT image generation (Codex) in the SEG soft
clay style, all showing the story character Ali. Originals are kept under
artifacts/theme-illustrations/<theme>/. Each picture is cropped to its
subject, centred on a 1024x1024 transparent square (largest side 912 px)
and recorded on its item ("images", "imageProvenance" with kind
"illustration"). They are not licensed photos, so they are not listed in
real_photo_manifest.json. Run tools/build_photo_bounds.py afterwards.
"""
import hashlib
import json
import shutil
import sys
from datetime import date
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def fit(path):
    im = Image.open(path).convert('RGBA')
    box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
    sub = im.crop(box)
    scale = 912 / max(sub.size)
    sub = sub.resize((max(1, round(sub.width * scale)), max(1, round(sub.height * scale))), Image.LANCZOS)
    out = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    out.paste(sub, ((1024 - sub.width) // 2, (1024 - sub.height) // 2))
    out.save(path, optimize=True)


def main():
    for theme in sys.argv[1:]:
        catalog = ROOT / f'assets/content/items/{theme}.json'
        items = json.loads(catalog.read_text(encoding='utf-8-sig'))
        keep = ROOT / 'artifacts/theme-illustrations' / theme
        keep.mkdir(parents=True, exist_ok=True)
        done, missing = 0, []
        for item in items:
            slug = item['id'].split('.', 1)[1]
            rel = f'assets/images/{theme}/{slug}.png'
            path = ROOT / rel
            if not path.exists():
                missing.append(item['id'])
                continue
            if not (keep / path.name).exists():
                shutil.copy2(path, keep / path.name)
                fit(path)
            item['images'] = [rel]
            item['imageProvenance'] = {rel: {
                'id': item['id'], 'path': rel, 'kind': 'illustration',
                'author': 'Yes Studio', 'source': 'ChatGPT image generation (Codex), SEG soft clay style',
                'license': 'Created for this app', 'licenseVerified': False,
                'createdOn': date.today().isoformat(),
                'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}}
            done += 1
        catalog.write_text(json.dumps(items, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
        print(theme, 'installed', done, 'missing', missing)


if __name__ == '__main__':
    main()
