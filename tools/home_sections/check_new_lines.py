"""Speech-to-text check of the clips recorded on a given day.

    python -I tools/home_sections/check_new_lines.py 2026-11-12 [--lang tr]

Lists every clip of tools/home_sections/voice_manifest.json requested on that
day (UTC) that is not heard as its text, so it can be recorded again with
record_lines.py --force --only <path>.
"""
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import check_voice_stt as stt  # noqa: E402


def main():
    day = sys.argv[1]
    only = sys.argv[sys.argv.index('--lang') + 1] if '--lang' in sys.argv else None
    key = os.environ['ELEVENLABS_API_KEY']
    manifest = json.loads((ROOT / 'tools/home_sections/voice_manifest.json').read_text(encoding='utf-8'))
    bad = checked = 0
    for path, clip in sorted(manifest.items()):
        if not clip['requested_at'].startswith(day) or (only and clip['language'] != only):
            continue
        checked += 1
        heard = stt.stt(ROOT / path, clip['language'], key)
        if not stt.matches(clip['text'], heard, clip['language']):
            bad += 1
            print(f'MISMATCH {path}\n   text : {clip["text"]}\n   heard: {heard}'.encode('ascii', 'backslashreplace').decode(), flush=True)
    print(f'{checked} checked, {bad} not heard as written')


if __name__ == '__main__':
    main()
