"""Makes the short weather sounds of "Hava Nasıl?" with ElevenLabs.

    python -I tools/home_sections/make_sfx.py

Writes assets/sfx/nature/*.mp3 (quiet, 3-4 s, mono) and records the prompt of
each in assets/sfx/nature/SOURCES.json. The API key comes from
ELEVENLABS_API_KEY and is never printed.
"""
import json
import os
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/sfx/nature'
SOUNDS = {
    'rain': 'gentle steady rain falling on a window, calm, no thunder',
    'snow': 'soft footsteps crunching slowly in fresh snow, calm',
    'sun': 'a few birds chirping softly on a calm sunny morning',
    'wind': 'a soft wind blowing gently, calm',
    'thunder': 'one soft distant rumble of thunder, not scary',
}


def main():
    key = os.environ.get('ELEVENLABS_API_KEY')
    if not key:
        sys.exit('ELEVENLABS_API_KEY is not set')
    OUT.mkdir(parents=True, exist_ok=True)
    record = {}
    for name, prompt in SOUNDS.items():
        out = OUT / f'{name}.mp3'
        record[name] = {'generator': 'ElevenLabs sound generation', 'prompt': prompt}
        if out.exists():
            continue
        body = json.dumps({'text': prompt, 'duration_seconds': 4, 'prompt_influence': 0.5}).encode('utf-8')
        request = urllib.request.Request('https://api.elevenlabs.io/v1/sound-generation', data=body, method='POST',
                                         headers={'xi-api-key': key, 'Content-Type': 'application/json'})
        with urllib.request.urlopen(request, timeout=120) as response:
            raw = response.read()
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / 'raw.mp3'
            src.write_bytes(raw)
            subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(src), '-af',
                            'loudnorm=I=-22:TP=-3:LRA=7,afade=t=out:st=3.4:d=0.6', '-ar', '44100', '-ac', '1', '-b:a', '64k', str(out)],
                           check=True)
        print(name, out.stat().st_size)
    (OUT / 'SOURCES.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
