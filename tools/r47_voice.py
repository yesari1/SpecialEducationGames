"""R47 voice work (ElevenLabs, same voices as the rest of the app).

    python -I tools/r47_voice.py praise   # re-record TR Aferin/Süpersin/Bravo, prompt, "Üç."
    python -I tools/r47_voice.py which    # "Kuş hangisi?" / "Which one is the bird?" clips

Praise: up to four takes per clip with calmer settings (Turkish words came
out with an English lilt at the expressive defaults); speech-to-text must
hear the exact text. Every take is kept under artifacts/voice-r47/ for review.
Which: one clip per Find item and language, recorded in the item JSON
(`whichAudio`) and the voice manifest.
"""
import concurrent.futures
import datetime
import json
import os
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_voice_stt as stt  # noqa: E402
import generate_selected_voice as gen  # noqa: E402

ROOT = gen.ROOT
OUT = ROOT / 'artifacts/voice-r47'
KEY = os.environ['ELEVENLABS_API_KEY']
# Steadier, less theatrical delivery first; the original settings last.
TR_SETTINGS = [
    {'stability': 0.6, 'similarity_boost': 0.8, 'style': 0.1, 'speed': 0.95, 'use_speaker_boost': True},
    {'stability': 0.75, 'similarity_boost': 0.85, 'style': 0.0, 'speed': 0.95, 'use_speaker_boost': True},
    {'stability': 0.5, 'similarity_boost': 0.8, 'style': 0.2, 'speed': 1.0, 'use_speaker_boost': True},
    gen.SETTINGS['voice_settings'],
]
PRAISE = {
    'praise.1:tr': 'Aferin!',
    'praise.4:tr': 'Süpersin!',
    'praise.5:tr': 'Bravo!',
    'prompt.praise:tr': 'Aferin!',
    'prompt.sequence_next:tr': 'Sıradaki sayı hangisi?',
}
WHICH_THEMES = ['animals', 'produce', 'food', 'vehicles', 'colors', 'shapes']


def tts(text, lang, settings):
    voice = gen.SETTINGS['voices'][lang]['voice_id']
    body = json.dumps({'text': text, 'model_id': gen.SETTINGS['model_id'],
                       'voice_settings': settings}).encode('utf-8')
    req = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128',
        data=body, method='POST',
        headers={'xi-api-key': KEY, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    with urllib.request.urlopen(req, timeout=90) as r:
        return r.read()


def praise():
    manifest = gen.load_manifest()
    clips = manifest['clips']
    # "Üç." lives in the item catalog; give it a manifest key if it has none.
    numbers = json.loads((ROOT / 'assets/content/items/numbers.json').read_text(encoding='utf-8'))
    three = next(i for i in numbers if i['id'] == 'numbers.3')['audio']['tr']
    targets = dict(PRAISE)
    targets['numbers.3:tr'] = 'Üç.'
    report = []
    for key, text in targets.items():
        path = clips[key]['path'] if key in clips else three
        chosen = None
        for n, settings in enumerate(TR_SETTINGS, 1):
            audio = tts(text, 'tr', settings)
            take = OUT / f"{key.replace(':', '_')}_take{n}.mp3"
            take.write_bytes(audio)
            heard = stt.stt(take, 'tr', KEY)
            ok = stt.matches(text, heard, 'tr')
            report.append({'key': key, 'take': n, 'settings': settings, 'heard': heard, 'match': ok,
                           'file': take.relative_to(ROOT).as_posix()})
            print(key, n, repr(heard), ok)
            if ok:
                chosen = take
                break
        chosen = chosen or (OUT / f"{key.replace(':', '_')}_take1.mp3")
        old = ROOT / path
        if old.exists():
            (OUT / 'old').mkdir(exist_ok=True)
            (OUT / 'old' / f"{key.replace(':', '_')}.mp3").write_bytes(old.read_bytes())
        old.write_bytes(chosen.read_bytes())
        entry = clips.setdefault(key, {'language': 'tr', 'text': text, 'path': path})
        entry.update(text=text, path=path, sha256=gen.sha256(old), bytes=old.stat().st_size,
                     requested_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                     note=f'R47 re-record with steadier Turkish settings ({chosen.name}).')
    gen.MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
    (OUT / 'praise_report.json').write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding='utf-8')


def which_text(item, lang, theme):
    name = item['name'][lang].strip().rstrip('.')
    if lang == 'tr':
        return f'{name[0].upper()}{name[1:]} hangisi?'
    low = name.lower()
    return f'Which one is {low}?' if theme == 'colors' else f'Which one is the {low}?'


def which():
    manifest = gen.load_manifest()
    jobs = []
    catalogs = {}
    for theme in WHICH_THEMES:
        p = ROOT / f'assets/content/items/{theme}.json'
        items = json.loads(p.read_text(encoding='utf-8'))
        catalogs[theme] = (p, items)
        for item in items:
            if not item.get('audio') or not (item.get('images') or theme in ('colors', 'shapes')):
                continue
            slug = item['id'].split('.', 1)[1]
            for lang in ('tr', 'en'):
                jobs.append({'item': item, 'theme': theme, 'lang': lang, 'text': which_text(item, lang, theme),
                             'out': f'assets/audio/{lang}/{theme}/{slug}_which.mp3',
                             'key': f"{item['id']}.which:{lang}"})
    print(len(jobs), 'clips', sum(len(j['text']) for j in jobs), 'characters')

    def work(job):
        settings = TR_SETTINGS[0] if job['lang'] == 'tr' else gen.SETTINGS['voice_settings']
        audio = tts(job['text'], job['lang'], settings)
        out = ROOT / job['out']
        out.write_bytes(audio)
        return job

    with concurrent.futures.ThreadPoolExecutor(4) as pool:
        for job in pool.map(work, jobs):
            out = ROOT / job['out']
            job['item'].setdefault('whichAudio', {})[job['lang']] = job['out']
            manifest['clips'][job['key']] = {
                'language': job['lang'], 'text': job['text'], 'path': job['out'],
                'sha256': gen.sha256(out), 'bytes': out.stat().st_size,
                'requested_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'note': 'R47 Find question clip.'}
    for p, items in catalogs.values():
        p.write_text(json.dumps(items, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    gen.MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    {'praise': praise, 'which': which}[sys.argv[1]]()
