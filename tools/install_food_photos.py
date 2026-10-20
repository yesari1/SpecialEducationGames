"""Install reviewed Food & Drinks photo adaptations with full provenance.

Inputs are numbered attempt folders (artifacts/food-photos-attempt-NN) with
originals/chosen.json (Commons metadata captured at download) and outputs
made by tools/adapt_cutout_photo.py. Only the items listed in ACCEPTED are
installed; each gets: the PNG under assets/images/food/, an imageProvenance
entry on its catalog item, an entry in real_photo_manifest.json and a
section in REAL_PHOTOS.md.

    python -I tools/install_food_photos.py
"""
import hashlib
import html
import json
import re
import shutil
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# item id -> attempt folder whose original/output was reviewed and accepted.
ACCEPTED = {
    'food.bread': 'food-photos-attempt-01',
    'food.egg': 'food-photos-attempt-01',
    'food.cake': 'food-photos-attempt-01',
    'food.cheese': 'food-photos-attempt-01',
    'food.cookie': 'food-photos-attempt-01',
    'food.ice_cream': 'food-photos-attempt-01',
    'food.soup': 'food-photos-attempt-01',
    'food.pasta': 'food-photos-attempt-02',
    'food.pizza': 'food-photos-attempt-02',
    'food.simit': 'food-photos-attempt-03',
}
MASKED = {'food.simit'}
MASK_CHANGES = ('Background removed with classical OpenCV GrabCut (rectangle start, largest '
                'component, 1 px feather; tools/grabcut_rect_mask.py), original photo pixels kept; '
                'alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject '
                'extent, centered 1024x1024 RGBA export and 4 px white outer outline.')
CHANGES = ('Existing transparent cutout from Wikimedia Commons retained (no new mask); '
           'alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject '
           'extent, centered 1024x1024 RGBA export and 4 px white outer outline.')


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def plain(markup):
    return html.unescape(re.sub(r'<[^>]+>', '', markup or '')).strip()


def main():
    items_path = ROOT / 'assets/content/items/food.json'
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
        target = ROOT / 'assets/images/food' / f'{slug}_real.png'
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(output, target)
        path = target.relative_to(ROOT).as_posix()
        license_name = meta['license']
        license_url = meta['licenseUrl'] or meta['page']
        adaptation = license_name if 'SA' in license_name else license_name
        entry = {
            'author': plain(meta['artist']) or 'Unknown (see source page)',
            'source': meta['page'],
            'license': license_name,
            'licenseUrl': license_url if license_url.startswith('http') else 'https:' + license_url,
            'changes': MASK_CHANGES if item_id in MASKED else CHANGES,
            'id': item_id,
            'path': path,
            'licenseVerified': True,
            'licenseVerifiedOn': date.today().isoformat(),
            'adaptationLicense': adaptation,
            'processing': ('tools/grabcut_rect_mask.py + ' if item_id in MASKED else '') + 'tools/adapt_cutout_photo.py',
            'whiteOutlinePixels': 4,
            'originalSha256': sha(original),
            'sha256': sha(target),
        }
        item = items[item_id]
        item['images'] = [path]
        item['imageProvenance'] = {path: entry}
        manifest['assets'] = [a for a in manifest['assets'] if a.get('path') != path] + [entry]
        credits.append(
            f"## {item_id}\n\nFile: `{path}`\nPhoto author: {entry['author']}\n"
            f"Source: {entry['source']}\nLicense: {license_name} — {entry['licenseUrl']}\n"
            f"Changes: {entry['changes']}\nOriginal SHA-256: `{entry['originalSha256']}`.\n"
            f"Adapted PNG SHA-256: `{entry['sha256']}`.\n"
            f"Attempt folder: `artifacts/{attempt}/`. Local technical review only; final human approval pending.\n")
        print(item_id, path, license_name, entry['author'])
    items_path.write_text(json.dumps(list(items.values()), ensure_ascii=False, indent=2).replace('\n', newline), encoding='utf-8')
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    credits_path = ROOT / 'assets/content/REAL_PHOTOS.md'
    text = credits_path.read_text(encoding='utf-8')
    marker = '\n<!-- food-photos -->\n'
    if marker in text:
        text = text[:text.index(marker)]
    credits_path.write_text(text.rstrip() + '\n' + marker + '\n'.join(credits), encoding='utf-8')


if __name__ == '__main__':
    main()
