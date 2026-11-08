"""Records the voice clips a newly opened theme needs (Nov 2026).

    python -I tools/theme_voice.py emotions body home

For every item: the Turkish word again with İrem on eleven_v4 +
language_code tr (the old multilingual v2 takes could sound English), and
the Find question in both languages ("whichAudio"), written the way people
say it: emotions "Hangisi mutlu?" / "Which one is happy?", body
"Göz nerede?" / "Where is the eye?", other themes "Yatak hangisi?" /
"Which one is the bed?". English words keep their existing Laura takes.
Every new clip is loudness-normalized, STT-checked (up to 3 takes, the
take is kept even if STT disagrees and is listed for review), recorded in
generated_voice_manifest.json, and the item JSON gets "whichAudio".
"""
import datetime
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
VOICES = {
    'tr': {'voice_id': 'uvU9jrgGLWNPeNA4NgNT', 'voice_name': 'İrem', 'model_id': 'eleven_v4', 'language_code': 'tr'},
    'en': {'voice_id': 'GZ4PpFJV8ikEGUtBrjK7', 'voice_name': 'Laura - a top narration voice',
           'model_id': 'eleven_multilingual_v2'},
}
SETTINGS = {'stability': 0.5, 'similarity_boost': 0.8, 'style': 0.3, 'speed': 0.95, 'use_speaker_boost': True}
FILTER = ('silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,'
          'loudnorm=I=-16:TP=-1.5:LRA=11')


def which_text(theme, name, lang):
    name = name.strip().rstrip('.')
    low = name if lang == 'tr' else name.lower()
    if lang == 'tr':
        if theme == 'emotions':
            return f'Hangisi {low.lower()}?'
        if theme == 'body':
            return f'{name[0].upper()}{name[1:]} nerede?'
        return f'{name[0].upper()}{name[1:]} hangisi?'
    if theme == 'emotions':
        return f'Which one is {low}?'
    if theme == 'body':
        return f'Where is the {low}?' if not low.endswith('s') else f'Where are the {low}?'
    return f'Which one is the {low}?'


def tts(text, lang):
    voice = VOICES[lang]
    body = {'text': text, 'model_id': voice['model_id'], 'voice_settings': SETTINGS}
    if 'language_code' in voice:
        body['language_code'] = voice['language_code']
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice['voice_id']}?output_format=mp3_44100_128",
        data=json.dumps(body).encode('utf-8'), method='POST',
        headers={'xi-api-key': KEY, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    with urllib.request.urlopen(req, timeout=90) as r:
        raw = r.read()
    with tempfile.TemporaryDirectory() as tmp:
        src, dst = Path(tmp) / 'raw.mp3', Path(tmp) / 'out.mp3'
        src.write_bytes(raw)
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(src), '-af', FILTER,
                        '-ar', '44100', '-ac', '1', '-b:a', '64k', str(dst)], check=True)
        return dst.read_bytes()


def record(text, lang, out, review):
    for take in range(3):
        audio = tts(text, lang)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(audio)
        heard = stt.stt(out, lang, KEY)
        if stt.matches(text, heard, lang):
            return audio
    review.append(f'{out.relative_to(ROOT).as_posix()}: "{text}" heard "{heard}"')
    return audio


def main():
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8-sig'))
    review = []
    for theme in sys.argv[1:]:
        path = ROOT / f'assets/content/items/{theme}.json'
        items = json.loads(path.read_text(encoding='utf-8-sig'))
        for item in items:
            slug = item['id'].split('.', 1)[1]
            jobs = [('item', 'tr', item['name']['tr'].strip().rstrip('.') + '.', item['audio']['tr'])]
            for lang in ('tr', 'en'):
                jobs.append(('which', lang, which_text(theme, item['name'][lang], lang),
                             f'assets/audio/{lang}/{theme}/{slug}_which.mp3'))
            for kind, lang, text, rel in jobs:
                audio = record(text, lang, ROOT / rel, review)
                key = f"{item['id']}:{lang}" if kind == 'item' else f"{item['id']}.which:{lang}"
                voice = VOICES[lang]
                manifest['clips'][key] = {
                    'bytes': len(audio), 'characters': len(text), 'item': item['id'], 'kind': kind,
                    'language': lang, 'model_id': voice['model_id'], 'path': rel,
                    'requested_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    'sha256': hashlib.sha256(audio).hexdigest(), 'text': text,
                    'voice_id': voice['voice_id'], 'voice_name': voice['voice_name'],
                    'voice_settings': SETTINGS, 'note': 'Theme opening (Nov 2026), loudness-normalized.'}
                if kind == 'which':
                    item.setdefault('whichAudio', {})[lang] = rel
                print(rel, text)
        path.write_text(json.dumps(items, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
    print('STT disagreements to review:', len(review))
    for line in review:
        print('  ' + line)


if __name__ == '__main__':
    main()
