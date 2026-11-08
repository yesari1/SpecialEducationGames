"""One-off retakes Yunus asked for on 8 Nov 2026: English "Foot" and a
livelier Turkish "Mükemmel!". Kept for the record of how they were made.

    python -I tools/rerecord_two.py
"""
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import check_voice_stt as stt  # noqa: E402

KEY = os.environ['ELEVENLABS_API_KEY']
MANIFEST = ROOT / 'assets/content/generated_voice_manifest.json'
JOBS = [
    {'key': 'body.foot:en', 'say': 'Foot.', 'lang': 'en', 'voice': 'GZ4PpFJV8ikEGUtBrjK7',
     'model': 'eleven_multilingual_v2', 'settings': {'stability': 0.7, 'similarity_boost': 0.8, 'style': 0.1, 'speed': 0.95, 'use_speaker_boost': True}},
    {'key': 'praise.7:tr', 'say': '[excited] Mükemmel!', 'heard': 'Mükemmel', 'lang': 'tr', 'voice': 'uvU9jrgGLWNPeNA4NgNT',
     'model': 'eleven_v4', 'code': 'tr', 'settings': {'stability': 0.3, 'similarity_boost': 0.8, 'style': 0.7, 'speed': 1.05, 'use_speaker_boost': True}},
]


def tts(job):
    body = {'text': job['say'], 'model_id': job['model'], 'voice_settings': job['settings']}
    if 'code' in job:
        body['language_code'] = job['code']
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{job['voice']}?output_format=mp3_44100_128",
        data=json.dumps(body).encode('utf-8'), method='POST',
        headers={'xi-api-key': KEY, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    with urllib.request.urlopen(req, timeout=90) as r:
        raw = r.read()
    with tempfile.TemporaryDirectory() as tmp:
        src, dst = Path(tmp) / 'r.mp3', Path(tmp) / 'o.mp3'
        src.write_bytes(raw)
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(src), '-af',
                        'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,loudnorm=I=-16:TP=-1.5:LRA=11',
                        '-ar', '44100', '-ac', '1', '-b:a', '64k', str(dst)], check=True)
        return dst.read_bytes()


def main():
    data = json.loads(MANIFEST.read_text(encoding='utf-8-sig'))
    for job in JOBS:
        clip = data['clips'][job['key']]
        path = ROOT / clip['path']
        old = hashlib.sha256(path.read_bytes()).hexdigest()
        for _ in range(4):
            audio = tts(job)
            path.write_bytes(audio)
            heard = stt.stt(path, job['lang'], KEY)
            if stt.matches(job.get('heard', job['say']), heard, job['lang']):
                break
        new = hashlib.sha256(audio).hexdigest()
        clip.update(sha256=new, bytes=len(audio), model_id=job['model'], voice_settings=job['settings'])
        print(clip['path'], 'heard', ascii(heard))
        for record in [*(ROOT / 'assets/content/items').glob('*.json'), ROOT / 'assets/content/real_audio_manifest.json']:
            text = record.read_text(encoding='utf-8-sig')
            if old in text:
                record.write_text(text.replace(old, new), encoding='utf-8', newline='\n')
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8', newline='\n')


if __name__ == '__main__':
    main()
