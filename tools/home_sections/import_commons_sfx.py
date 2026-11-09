"""Imports freely licensed recordings from Wikimedia Commons.

    python -I tools/home_sections/import_commons_sfx.py

Downloads only the named files into artifacts/source_audio/, cuts a short calm
piece, writes it under assets/sfx/ and adds its credit to assets/sfx/sources.json
and SOURCES.md. Files that are already there are left alone.
"""
import hashlib
import json
import subprocess
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ORIGINALS = ROOT / 'artifacts/source_audio'
API = 'https://commons.wikimedia.org/w/api.php'
HEADERS = {'User-Agent': 'SpecialEducationGamesAssetImport/1.0 (local educational app development)'}
BY = 'https://creativecommons.org/licenses/by/3.0/'
SA4 = 'https://creativecommons.org/licenses/by-sa/4.0/'
CC0 = 'https://creativecommons.org/publicdomain/zero/1.0/'
PD = 'https://commons.wikimedia.org/wiki/Commons:Licensing#Material_in_the_public_domain'

# item id, output, Commons title, author, licence, licence URL, start, seconds
SOUNDS = [
    ('nature.rain', 'nature/rain.mp3', 'Rain.ogg', 'ジダネ', 'Public domain', PD, 1.0, 2.5),
    ('nature.snow', 'nature/snow.mp3', 'Crunchy Snow Walking Sound Effect - Human Sounds.opus', 'Free Sounds Library User Spanac', 'CC-BY-3.0', BY, 2.0, 2.5),
    ('nature.sun', 'nature/sun.mp3', 'Gentle breeze and birds singing.ogg', 'ezwa', 'Public domain', PD, 4.0, 2.5),
    ('nature.wind', 'nature/wind.mp3', 'Windy breath.ogg', 'stilgar', 'Public domain', PD, 3.0, 2.5),
    ('nature.lightning', 'nature/thunder.mp3', 'Thunder.ogg', 'Bidgee', 'CC-BY-3.0', 'https://creativecommons.org/licenses/by/3.0/', 1.0, 3.0),
    ('music.drum', 'music/drum.mp3', 'Timpani 64-c-p5.wav', 'spt3125', 'CC0-1.0', CC0, 0.0, 2.5),
    ('music.trumpet', 'music/trumpet.mp3', '05. D5-trumpet.ogg', 'ПростоУчастник', 'CC0-1.0', CC0, 0.0, 2.5),
    ('music.accordion', 'music/accordion.mp3', 'Accordion registers.ogg', 'Necz0r', 'Public domain', PD, 2.0, 3.0),
    ('music.piano', 'music/piano.mp3', 'E major piano.ogg', 'ROUX (Wikimedia Commons)', 'CC0-1.0', CC0, 0.0, 3.0),
    ('music.guitar', 'music/guitar.mp3', 'A-major.ogg', 'WBOSITG', 'Public domain', PD, 0.0, 3.0),
    ('music.bell', 'music/bell.mp3', 'Bell-ring.flac', 'qubodup', 'CC0-1.0', CC0, 0.0, 2.5),
    ('music.recorder', 'music/recorder.mp3', 'SopranoRecorder.ogg', 'Thparkth', 'Public domain', PD, 1.0, 3.0),
    ('music.tambourine', 'music/tambourine.mp3', 'Tambourine.ogg', 'Freddythehat', 'Public domain', PD, 2.0, 2.0),
    ('music.violin', 'music/violin.mp3', 'Street musician violin.ogg', 'natalie', 'Public domain', PD, 3.0, 3.0),
    ('music.darbuka', 'music/darbuka.mp3', 'Djembe.ogg', 'Freddythehat', 'Public domain', PD, 0.0, 2.5),
]


def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=90) as response:
        return response.read()


def original_url(title):
    query = urllib.parse.urlencode({'action': 'query', 'format': 'json', 'titles': f'File:{title}', 'prop': 'imageinfo', 'iiprop': 'url'})
    pages = json.loads(fetch(f'{API}?{query}').decode('utf-8'))['query']['pages']
    url = next(iter(pages.values()))['imageinfo'][0]['url']
    if not url.startswith('https://upload.wikimedia.org/'):
        raise RuntimeError('Unexpected media host')
    return url


def main():
    ORIGINALS.mkdir(parents=True, exist_ok=True)
    credits_path = ROOT / 'assets/sfx/sources.json'
    credits = json.loads(credits_path.read_text(encoding='utf-8'))
    known = {c['asset'] for c in credits}
    notes = []
    for item, rel, title, author, licence, licence_url, start, seconds in SOUNDS:
        asset = f'assets/sfx/{rel}'
        out = ROOT / asset
        src = ORIGINALS / title.replace(' ', '_')
        if not src.exists():
            src.write_bytes(fetch(original_url(title)))
            time.sleep(4)
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-ss', str(start), '-t', str(seconds), '-i', str(src),
                        '-af', f'loudnorm=I=-24:TP=-6:LRA=7,afade=t=in:d=0.01,afade=t=out:st={seconds * .85:.2f}:d={seconds * .15:.2f}',
                        '-ar', '44100', '-ac', '1', '-b:a', '96k', str(out)], check=True)
        if asset in known:
            continue
        page = 'https://commons.wikimedia.org/wiki/File:' + urllib.parse.quote(title.replace(' ', '_'))
        credits.append({'itemId': item, 'asset': asset, 'title': title, 'author': author, 'source': page, 'license': licence,
                        'licenseUrl': licence_url, 'changes': f'Cut to {seconds:g} seconds; mono MP3; normalized to -24 LUFS; short fades.',
                        'originalSha256': hashlib.sha256(src.read_bytes()).hexdigest(), 'sha256': hashlib.sha256(out.read_bytes()).hexdigest()})
        notes.append(f'\n## {title}\n\n- Author: {author}\n- Source: {page}\n- License: {licence} — {licence_url}\n- App asset: {asset}\n')
        print(asset, out.stat().st_size)
    credits_path.write_text(json.dumps(credits, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with open(ROOT / 'assets/sfx/SOURCES.md', 'a', encoding='utf-8') as f:
        f.writelines(notes)


if __name__ == '__main__':
    main()
