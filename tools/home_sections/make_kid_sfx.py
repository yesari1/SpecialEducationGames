"""Makes the child's cheer of "Duygu Sesi" and the puzzle's click.

    python -I tools/home_sections/make_kid_sfx.py

- assets/sfx/feelings/excited_boy.mp3 / excited_girl.mp3: "Yaşasın!" said by
  a young ElevenLabs voice (eleven_v4, Turkish) and raised in pitch so it
  sounds like a small child (the account has no child voice, and its key may
  not use sound generation). Three takes each are kept in
  artifacts/fix-nov12/sfx/; the first one speech-to-text hears as the word is
  installed.
- assets/sfx/ui/puzzle_snap.wav: a short wooden click, made here.
The API key comes from ELEVENLABS_API_KEY and is never printed.
"""
import json
import os
import subprocess
import sys
import urllib.request
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
TAKES = ROOT / 'artifacts/fix-nov12/sfx'
sys.path.insert(0, str(ROOT / 'tools'))
import check_voice_stt as stt  # noqa: E402

# (premade young voice, how much higher)
KIDS = {
    'boy': ('Will', 1.24),
    'girl': ('Jessica', 1.30),
}


def voices(key):
    request = urllib.request.Request('https://api.elevenlabs.io/v1/voices', headers={'xi-api-key': key})
    with urllib.request.urlopen(request, timeout=60) as response:
        return {v['name'].split(' ')[0]: v['voice_id'] for v in json.load(response)['voices'] if v.get('category') == 'premade'}


def say(key, voice_id, text):
    body = {'text': text, 'model_id': 'eleven_v4', 'language_code': 'tr',
            'voice_settings': {'stability': 0.3, 'similarity_boost': 0.8, 'style': 0.7, 'use_speaker_boost': True}}
    request = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128',
        data=json.dumps(body).encode('utf-8'), method='POST',
        headers={'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def snap():
    rate = 44100
    t = np.arange(int(rate * .16)) / rate
    rng = np.random.default_rng(3)
    click = rng.standard_normal(t.size) * np.exp(-t * 220) * .5
    knock = np.sin(2 * np.pi * 520 * t) * np.exp(-t * 60) * .7 + np.sin(2 * np.pi * 1180 * t) * np.exp(-t * 110) * .35
    out = (click + knock) * np.minimum(1, t / .002)
    out = out / np.max(np.abs(out)) * .8
    path = ROOT / 'assets/sfx/ui/puzzle_snap.wav'
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes((out * 32767).astype('<i2').tobytes())
    print('installed', path.relative_to(ROOT).as_posix())


def main():
    snap()
    key = os.environ['ELEVENLABS_API_KEY']
    ids = voices(key)
    TAKES.mkdir(parents=True, exist_ok=True)
    for who, (name, pitch) in KIDS.items():
        out = ROOT / f'assets/sfx/feelings/excited_{who}.mp3'
        best = None
        for take in range(3):
            raw = TAKES / f'excited_{who}_{take}.mp3'
            raw.write_bytes(say(key, ids[name], '[excited] Yaşasın!'))
            heard = stt.stt(raw, 'tr', key)
            print(f'{who} take {take}: {heard!r}'.encode('ascii', 'backslashreplace').decode(), flush=True)
            if best is None:
                best = raw
            if 'yaşasın' in stt.norm(heard):
                best = raw
                break
        # Higher and a touch quicker: a small child's voice.
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(best), '-af',
                        f'asetrate=44100*{pitch},aresample=44100,atempo={round(1 / pitch * 1.08, 3)},'
                        'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02,loudnorm=I=-16:TP=-1.5:LRA=11',
                        '-ar', '44100', '-ac', '1', '-b:a', '96k', str(out)], check=True)
        print('installed', out.relative_to(ROOT).as_posix(), 'from', best.name)


if __name__ == '__main__':
    main()
