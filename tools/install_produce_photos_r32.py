"""Install the R32 single-object produce photos with full provenance.

Replaces confusing multi-object pictures (cucumber with slices, peeled
mandarin with segments, two onions with a half) by one whole real photo each.
Inputs are numbered attempt folders; originals/chosen.json in attempt r32-01
holds the Commons metadata captured at download. Legacy files stay on disk.

    python -I tools/install_produce_photos_r32.py
"""
import hashlib
import html
import json
import re
import shutil
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META = ROOT / 'artifacts/produce-photos-attempt-r32-01/originals/chosen.json'
# item id -> (attempt folder holding the accepted output, mask processing)
ACCEPTED = {
    'produce.cucumber': ('produce-photos-attempt-r32-01', None),
    'produce.mandarin': ('produce-photos-attempt-r32-01', 'tools/grabcut_rect_mask.py'),
    'produce.onion': ('produce-photos-attempt-r32-03',
                      'tools/grabcut_rect_mask.py + artifacts/produce-photos-attempt-r32-03/drop_outer_grey.py'),
}
CUTOUT = ('Existing transparent cutout from Wikimedia Commons retained (no new mask); '
          'alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject '
          'extent, centered 1024x1024 RGBA export and 4 px white outer outline.')
MASKED = ('Background removed with classical OpenCV GrabCut (rectangle start, largest '
          'component, 1 px feather), original photo pixels kept; alpha-bound crop, '
          'aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered '
          '1024x1024 RGBA export and 4 px white outer outline.')
SHADOW = (' Light grey floor shadow connected to the background cleared afterwards '
          '(HSV S < 0.24, V > 0.40), enclosed holes filled; a few shadow pixels by the '
          'root remain.')


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def plain(markup):
    return html.unescape(re.sub(r'<[^>]+>', '', markup or '')).strip()


def main():
    items_path = ROOT / 'assets/content/items/produce.json'
    raw = items_path.read_text(encoding='utf-8')
    newline = '\r\n' if '\r\n' in raw else '\n'
    items = {item['id']: item for item in json.loads(raw)}
    manifest_path = ROOT / 'assets/content/real_photo_manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    metadata = json.loads(META.read_text(encoding='utf-8'))
    credits = []
    for item_id, (attempt, masking) in ACCEPTED.items():
        slug = item_id.split('.', 1)[1]
        meta = metadata[item_id]
        original = next((ROOT / 'artifacts/produce-photos-attempt-r32-01/originals').glob(f'{slug}_original.*'))
        output = ROOT / 'artifacts' / attempt / 'outputs' / f'{slug}_real.png'
        target = ROOT / 'assets/images/produce' / f'{slug}_real.png'
        shutil.copyfile(output, target)
        path = target.relative_to(ROOT).as_posix()
        license_url = meta['licenseUrl'] or meta['page']
        changes = CUTOUT if masking is None else MASKED + (SHADOW if 'drop_outer_grey' in masking else '')
        entry = {
            'author': plain(meta['artist']) or 'Unknown (see source page)',
            'source': meta['page'],
            'license': meta['license'],
            'licenseUrl': license_url if license_url.startswith('http') else 'https:' + license_url,
            'changes': changes,
            'id': item_id,
            'path': path,
            'licenseVerified': True,
            'licenseVerifiedOn': date.today().isoformat(),
            'adaptationLicense': meta['license'],
            'processing': (masking + ' + ' if masking else '') + 'tools/adapt_cutout_photo.py',
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
            f"Source: {entry['source']}\nLicense: {entry['license']} — {entry['licenseUrl']}\n"
            f"Changes: {changes}\nOriginal SHA-256: `{entry['originalSha256']}`.\n"
            f"Adapted PNG SHA-256: `{entry['sha256']}`.\n"
            f"Attempt folder: `artifacts/{attempt}/`. Local technical review only; final human approval pending.\n")
        print(item_id, path, entry['license'], entry['author'])
    items_path.write_text(json.dumps(list(items.values()), ensure_ascii=False, indent=2).replace('\n', newline), encoding='utf-8')
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    credits_path = ROOT / 'assets/content/REAL_PHOTOS.md'
    text = credits_path.read_text(encoding='utf-8')
    marker = '\n<!-- produce-photos-r32 -->\n'
    if marker in text:
        text = text[:text.index(marker)]
    credits_path.write_text(text.rstrip() + '\n' + marker + '\n'.join(credits), encoding='utf-8')


if __name__ == '__main__':
    main()
