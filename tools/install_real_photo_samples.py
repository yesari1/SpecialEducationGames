"""Install the verified deterministic real-photo samples; no downloads or AI.

Rebuild samples first with prepare_photo_samples.ps1 when processing changes.
Run build_content.py afterwards. Originals and other catalog images are retained.
"""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main(root=ROOT):
    samples = root / 'artifacts/photo_samples'
    source = json.loads((samples / 'manifest.json').read_text(encoding='utf-8'))
    manifest_path = root / 'assets/content/real_photo_manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {
        'schemaVersion': 1, 'assets': []}
    entries = {entry['id']: entry for entry in manifest['assets']}
    retained = 0
    for sample in source['assets']:
        theme = {'cat': 'animals', 'banana': 'produce', 'apple': 'produce'}[sample['id']]
        identifier = f"{theme}.{sample['id']}"
        relative = f"assets/images/{theme}/{sample['id']}_real.png"
        destination = root / relative
        current = entries.get(identifier, {})
        if current.get('processing') == 'tools/rebuild_legacy_real_photos.ps1':
            # Historical gallery files predate the DPI repair. Never silently
            # reinstall their lower-resolution bytes over a verified repair.
            if (current.get('path') != relative or not destination.is_file() or
                    hashlib.sha256(destination.read_bytes()).hexdigest() != current.get('sha256')):
                raise ValueError(f'Invalid repaired asset: {identifier}')
            retained += 1
            continue
        shutil.copy2(samples / sample['output'], destination)
        entry = {field: sample[field] for field in (
            'author', 'source', 'license', 'licenseUrl', 'changes')}
        if 'existingBackgroundRemoval' in sample:
            entry['existingBackgroundRemoval'] = sample['existingBackgroundRemoval']
        entry.update(id=identifier, path=relative, licenseVerified=True,
                     licenseVerifiedOn='2026-10-16',
                     adaptationLicense=sample['license'],
                     processing='tools/prepare_photo_samples.ps1',
                     whiteOutlinePixels=4,
                     sha256=hashlib.sha256(destination.read_bytes()).hexdigest())
        if current.get('additionalVariants'):
            entry['additionalVariants'] = current['additionalVariants']
        entries[identifier] = entry
    manifest['assets'] = sorted(entries.values(), key=lambda entry: entry['id'])
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    credits = ['# Real photo credits', '',
               'These are adaptations of existing photographs, not generated images. '
               'Each adaptation retains its recorded source license or public-domain dedication. '
               'Original photo detail is preserved through deterministic masking/crop/resize. '
               'The application also draws a white outline at display time.', '']
    for entry in manifest['assets']:
        variants = [entry, *entry.get('additionalVariants', [])]
        for index, variant in enumerate(variants):
            variant_id = entry['id'] if index == 0 else f"{entry['id']}#{index + 1}"
            credits += [f"## {variant_id}", '', f"File: `{variant['path']}`",
                        f"Photo author: {variant['author']}"]
            if 'existingBackgroundRemoval' in variant:
                credits.append(f"Original background removal: {variant['existingBackgroundRemoval']}")
            credits += [f"Source: {variant['source']}",
                        f"Source and adaptation license: {variant['license']} — {variant['licenseUrl']}",
                        f"Changes: {variant['changes']}", '']
    (root / 'assets/content/REAL_PHOTOS.md').write_text('\n'.join(credits), encoding='utf-8')
    print(f"Installed {len(source['assets']) - retained} samples; retained {retained} repaired assets; "
          f"{len(entries)} verified overrides in manifest.")


if __name__ == '__main__':
    main()
