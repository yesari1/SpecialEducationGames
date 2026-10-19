"""Import four separately licensed recordings; never synthesizes narration.

Only fetches the named Commons originals. Existing originals are reused.
Requires ffmpeg on PATH. Attribution travels in the app's asset bundle.
"""
import hashlib
import html
import json
from pathlib import Path
import re
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
SOURCES = [
    ('cat', 'Meow.ogg', 'Dan Crosby (Dcrosby)', 'CC-BY-SA-3.0',
     'https://creativecommons.org/licenses/by-sa/3.0/', 0.8),
    ('dog', 'Ladrido_perro.ogg', 'Edo.pt2', 'CC0-1.0',
     'https://creativecommons.org/publicdomain/zero/1.0/', 3.0),
    ('cow', 'Mudchute_cow_1.ogg', 'Secretlondon', 'CC-BY-SA-3.0',
     'https://creativecommons.org/licenses/by-sa/3.0/', 2.2),
    ('horse', 'Wiehern.ogg', 'Hü; current revision adjusted by Jonnmann',
     'LicenseRef-Public-Domain',
     'https://commons.wikimedia.org/wiki/File:Wiehern.ogg#Licensing', 2.3),
]


def fetch(url):
    request = urllib.request.Request(url, headers={
        'User-Agent': 'SpecialEducationGamesAssetImport/1.0 (local educational app development)'
    })
    with urllib.request.urlopen(request, timeout=45) as response:
        return response.read()


def main():
    originals = ROOT / 'artifacts/source_audio'
    target = ROOT / 'assets/sfx/animals'
    originals.mkdir(parents=True, exist_ok=True)
    target.mkdir(parents=True, exist_ok=True)
    records = []
    for slug, filename, author, license_id, license_url, duration in SOURCES:
        page = 'https://commons.wikimedia.org/wiki/File:' + filename
        source = originals / filename
        if not source.exists():
            markup = fetch(page).decode('utf-8')
            match = re.search(r'class="fullMedia".*?href="([^"]+)"', markup, re.S)
            if not match:
                raise RuntimeError('Original link missing: ' + page)
            original_url = html.unescape(match[1])
            if not original_url.startswith('https://upload.wikimedia.org/'):
                raise RuntimeError('Unexpected media host')
            source.write_bytes(fetch(original_url))
        output = target / (slug + '.mp3')
        subprocess.run([
            'ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(source),
            '-t', str(duration), '-af',
            f'loudnorm=I=-24:TP=-6:LRA=7,afade=t=in:d=0.04,afade=t=out:st={duration - .08}:d=0.08',
            '-ar', '44100', '-ac', '1', '-b:a', '96k', str(output)
        ], check=True)
        records.append(dict(
            itemId='animals.' + slug, asset=output.relative_to(ROOT).as_posix(),
            title=filename, author=author, source=page,
            license=license_id, licenseUrl=license_url,
            changes='Converted to mono MP3; normalized to -24 LUFS / -6 dBTP; short fades; clipped to at most 3 seconds.',
            originalSha256=hashlib.sha256(source.read_bytes()).hexdigest(),
            sha256=hashlib.sha256(output.read_bytes()).hexdigest(),
        ))
    (ROOT / 'assets/sfx/sources.json').write_text(
        json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
    lines = ['# Animal sound credits', '',
             'The cat and cow MP3 adaptations are distributed under CC BY-SA 3.0.',
             'These licenses apply to the named recordings and their adaptations.',
             'Original recordings are retained in artifacts/source_audio for review.', '']
    for record in records:
        lines.extend([
            f"## {record['title']}", '', f"- Author: {record['author']}",
            f"- Source: {record['source']}",
            f"- License: {record['license']} — {record['licenseUrl']}",
            f"- App asset: {record['asset']}",
            f"- Changes: {record['changes']}", '',
        ])
    (ROOT / 'assets/sfx/SOURCES.md').write_text('\n'.join(lines), encoding='utf-8')
    print('Imported 4 animal recordings with attribution and checksums.')


if __name__ == '__main__':
    main()
