"""Transcribe generated clips with ElevenLabs speech-to-text and flag mismatches.

    python -I tools/check_voice_stt.py [kind ...]      # default: item

Writes artifacts/voice-check/stt_report.json: per clip key the expected text,
transcript, duration and whether they match after normalisation. One request
per clip that has no result for its current sha256 yet; nothing is retried.
"""
import concurrent.futures
import json
import os
import re
import subprocess
import sys
import threading
import unicodedata
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'assets/content/generated_voice_manifest.json'
REPORT = ROOT / 'artifacts/voice-check/stt_report.json'
LANG = {'tr': 'tur', 'en': 'eng'}


def norm(text):
    text = unicodedata.normalize('NFKC', text).replace('İ', 'i').replace('I', 'ı') if False else unicodedata.normalize('NFKC', text)
    text = text.replace('’', "'")
    text = re.sub(r"[^\w' ]+", ' ', text.lower())
    return ' '.join(text.split())


def duration(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(path)],
                         capture_output=True, text=True)
    try:
        return float(out.stdout.strip())
    except ValueError:
        return None


def stt(path, lang, key):
    boundary = uuid.uuid4().hex
    data = Path(path).read_bytes()
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="model_id"\r\n\r\nscribe_v1\r\n'
            f'--{boundary}\r\nContent-Disposition: form-data; name="language_code"\r\n\r\n{LANG[lang]}\r\n'
            f'--{boundary}\r\nContent-Disposition: form-data; name="tag_audio_events"\r\n\r\nfalse\r\n'
            f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="clip.mp3"\r\n'
            'Content-Type: audio/mpeg\r\n\r\n').encode() + data + f'\r\n--{boundary}--\r\n'.encode()
    request = urllib.request.Request('https://api.elevenlabs.io/v1/speech-to-text', data=body, method='POST',
                                     headers={'xi-api-key': key, 'Content-Type': f'multipart/form-data; boundary={boundary}'})
    with urllib.request.urlopen(request, timeout=120) as response:
        return json.load(response).get('text', '')


def matches(expected, heard, lang):
    e, h = norm(expected), norm(heard)
    if lang == 'tr':
        fold = str.maketrans('ıiğüşöç', 'iigusoc')
        e, h = e.translate(fold), h.translate(fold)
    return e == h


def main():
    kinds = set(sys.argv[1:]) or {'item'}
    key = os.environ['ELEVENLABS_API_KEY']
    clips = json.loads(MANIFEST.read_text(encoding='utf-8'))['clips']
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    report = json.loads(REPORT.read_text(encoding='utf-8')) if REPORT.exists() else {}
    todo = [(k, c) for k, c in clips.items()
            if c['kind'] in kinds and report.get(k, {}).get('sha256') != c['sha256']]
    print(f'{len(todo)} clips to transcribe', flush=True)
    lock = threading.Lock()

    def work(pair):
        name, clip = pair
        path = ROOT / clip['path']
        try:
            heard = stt(path, clip['language'], key)
        except Exception as error:
            heard = f'ERROR {type(error).__name__}'
        row = {'text': clip['text'], 'heard': heard, 'sha256': clip['sha256'], 'path': clip['path'],
               'duration': duration(path), 'match': matches(clip['text'], heard, clip['language'])}
        with lock:
            report[name] = row
            REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding='utf-8')

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        list(pool.map(work, todo))
    bad = {k: v for k, v in report.items() if not v['match']}
    print(f'done; {len(bad)} mismatches')
    for k, v in sorted(bad.items()):
        print(f'  {k}: expected {v["text"]!r} heard {v["heard"]!r}')


if __name__ == '__main__':
    main()
