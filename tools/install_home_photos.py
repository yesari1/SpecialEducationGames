"""Install reviewed Home (Evimiz / Our Home) photo adaptations with full provenance.

Inputs are numbered attempt folders (artifacts/home-photos-attempt-NN) with
originals/chosen.json (Pixabay metadata captured at download), the downloaded
original, the hardened rembg cutout (cutouts/) and the adapted output made by
tools/adapt_cutout_photo.py (outputs/). Only the items listed in ACCEPTED are
installed; each gets: the PNG under assets/images/home/, images and
imageProvenance on its catalog item, an entry in real_photo_manifest.json and a
section in REAL_PHOTOS.md.

    python -I tools/install_home_photos.py
"""
import hashlib
import json
import shutil
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# item id -> attempt folder whose original/output was reviewed and accepted.
ACCEPTED = {
    'home.pillow': 'home-photos-attempt-01',
    'home.table': 'home-photos-attempt-01',
    'home.chair': 'home-photos-attempt-01',
    'home.door': 'home-photos-attempt-01',
    'home.plate': 'home-photos-attempt-01',
    'home.glass': 'home-photos-attempt-01',
    'home.spoon': 'home-photos-attempt-01',
    'home.clock': 'home-photos-attempt-02',
    'home.vacuum_cleaner': 'home-photos-attempt-02',
    'home.kettle': 'home-photos-attempt-02',
    'home.towel': 'home-photos-attempt-02',
    'home.toothbrush': 'home-photos-attempt-02',
    'home.pot': 'home-photos-attempt-02',
    'home.pan': 'home-photos-attempt-02',
    'home.fork': 'home-photos-attempt-02',
    'home.teapot': 'home-photos-attempt-02',
    'home.fridge': 'home-photos-attempt-02',
    'home.mixer': 'home-photos-attempt-03',
    'home.flower_pot': 'home-photos-attempt-03',
    'home.shampoo': 'home-photos-attempt-03',
    'home.telephone': 'home-photos-attempt-03',
    'home.hanger': 'home-photos-attempt-03',
    'home.sofa': 'home-photos-attempt-04',
    'home.iron': 'home-photos-attempt-04',
    'home.lamp': 'home-photos-attempt-05',
    'home.curtain': 'home-photos-attempt-05',
    'home.comb': 'home-photos-attempt-05',
    'home.mirror': 'home-photos-attempt-05',
    'home.key': 'home-photos-attempt-05',
    'home.trash_can': 'home-photos-attempt-05',
    'home.remote_control': 'home-photos-attempt-05',
}
CHANGES = ('Foreground alpha with rembg U2Net, hardened (alpha threshold 140, 1 px erode, '
           '0.6 px blur, small stray regions dropped), original photo RGB retained; alpha-bound '
           'crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered '
           '1024x1024 RGBA export and 4 px white outer outline (tools/adapt_cutout_photo.py). '
           'No generative editing.')


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    items_path = ROOT / 'assets/content/items/home.json'
    raw = items_path.read_text(encoding='utf-8')
    newline = '\r\n' if '\r\n' in raw else '\n'
    items = {item['id']: item for item in json.loads(raw)}
    manifest_path = ROOT / 'assets/content/real_photo_manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    credits = []
    for item_id, attempt in ACCEPTED.items():
        slug = item_id.split('.', 1)[1]
        folder = ROOT / 'artifacts' / attempt
        meta = json.loads((folder / 'originals' / 'chosen.json').read_text(encoding='utf-8'))[item_id]
        original = next((folder / 'originals').glob(f'{slug}_original.*'))
        output = folder / 'outputs' / f'{slug}_real.png'
        target = ROOT / 'assets/images/home' / f'{slug}_real.png'
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(output, target)
        path = target.relative_to(ROOT).as_posix()
        entry = {
            'author': meta['author'],
            'source': meta['page'],
            'license': meta['license'],
            'licenseUrl': meta['licenseUrl'],
            'changes': CHANGES,
            'id': item_id,
            'path': path,
            'original': original.relative_to(ROOT).as_posix(),
            'originalSha256': sha(original),
            'downloadUrl': meta['downloadUrl'],
            'licenseVerified': True,
            'licenseVerifiedOn': date.today().isoformat(),
            'adaptationLicense': meta['license'],
            'processing': 'rembg U2Net + tools/adapt_cutout_photo.py',
            'whiteOutlinePixels': 4,
            'sha256': sha(target),
        }
        item = items[item_id]
        item['images'] = [path]
        item['imageProvenance'] = {path: entry}
        manifest['assets'] = [a for a in manifest['assets'] if a.get('path') != path] + [entry]
        credits.append(
            f"## {item_id}\n\nFile: `{path}`\nPhoto author: {entry['author']}\n"
            f"Source: {entry['source']}\n"
            f"Source and adaptation license: {entry['license']} - {entry['licenseUrl']}\n"
            f"Original: `{entry['original']}` (SHA-256 `{entry['originalSha256']}`).\n"
            f"Adapted PNG SHA-256: `{entry['sha256']}`.\n"
            f"Changes: {entry['changes']}\n")
        print(item_id, path, entry['license'], entry['author'])
    items_path.write_text(json.dumps(list(items.values()), ensure_ascii=False, indent=2).replace('\n', newline), encoding='utf-8')
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    credits_path = ROOT / 'assets/content/REAL_PHOTOS.md'
    text = credits_path.read_text(encoding='utf-8')
    marker = '\n<!-- home-photos -->\n'
    if marker in text:
        text = text[:text.index(marker)]
    credits_path.write_text(text.rstrip() + '\n' + marker + '\n' + '\n'.join(credits), encoding='utf-8')


if __name__ == '__main__':
    main()
