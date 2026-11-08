"""Shrinks the app's item pictures and voice clips (Yunus, 8 Nov 2026).

    python -I tools/shrink_assets.py

Pictures: every PNG under assets/images (except app_logo.png) becomes a
WebP at the SAME pixel size, quality 90, lossless alpha. Voice: every MP3
under assets/audio is re-encoded to 64 kbps mono (speech). The originals
stay in git history.

All records follow: new paths and sha256 values are written into the
catalog, manifests and credits, and "bytes" in the voice manifest.
Run tools/build_photo_bounds.py afterwards.
"""
import concurrent.futures as cf
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RECORDS = [
    *sorted((ROOT / 'assets/content').rglob('*.json')),
    *sorted((ROOT / 'assets/content').glob('*.md')),
    ROOT / 'tools/pair_games/source_more.py',
    ROOT / 'tools/pair_games/voice_manifest.json',
    ROOT / 'tools/stories/voice_manifest.json',
]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def rel(path):
    return path.relative_to(ROOT).as_posix()


def picture(path):
    old = path.read_bytes()
    out = path.with_suffix('.webp')
    with Image.open(path) as im:
        im.convert('RGBA').save(out, 'WEBP', quality=90, alpha_quality=100, method=6)
    path.unlink()
    return rel(path), rel(out), sha(old), sha(out.read_bytes())


def clip(path):
    old = path.read_bytes()
    with tempfile.TemporaryDirectory() as tmp:
        dst = Path(tmp) / 'o.mp3'
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(path),
                        '-ac', '1', '-b:a', '64k', '-map_metadata', '-1', str(dst)], check=True)
        new = dst.read_bytes()
    # Never keep a re-encode that came out larger.
    if len(new) >= len(old):
        return rel(path), rel(path), sha(old), sha(old)
    path.write_bytes(new)
    return rel(path), rel(path), sha(old), sha(new)


def main():
    pictures = [p for p in (ROOT / 'assets/images').rglob('*.png') if p.name != 'app_logo.png']
    clips = list((ROOT / 'assets/audio').rglob('*.mp3'))
    with cf.ThreadPoolExecutor(8) as pool:
        done = list(pool.map(picture, pictures)) + list(pool.map(clip, clips))
    paths = {a: b for a, b, _, _ in done if a != b}
    hashes = {a: b for _, _, a, b in done if a != b}
    for record in RECORDS:
        if not record.exists():
            continue
        text = original = record.read_text(encoding='utf-8-sig')
        for a, b in paths.items():
            text = text.replace(a, b)
        for a, b in hashes.items():
            text = text.replace(a, b)
        if text != original:
            record.write_text(text, encoding='utf-8', newline='\n')
    # File sizes recorded for the voice clips.
    for name in ('generated_voice_manifest.json', 'real_audio_manifest.json'):
        p = ROOT / 'assets/content' / name
        data = json.loads(p.read_text(encoding='utf-8-sig'))
        entries = data['clips'].values() if 'clips' in data else data.get('assets', [])
        changed = False
        for e in entries:
            f = ROOT / e.get('path', '')
            if 'bytes' in e and f.is_file() and e['bytes'] != f.stat().st_size:
                e['bytes'] = f.stat().st_size
                changed = True
        if changed:
            p.write_text(json.dumps(data, ensure_ascii=False, indent=1, sort_keys='clips' in data), encoding='utf-8', newline='\n')
    print(len(pictures), 'pictures,', len(clips), 'clips;', len(paths), 'renamed,', len(hashes), 'hashes updated')


if __name__ == '__main__':
    main()
