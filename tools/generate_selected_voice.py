"""Generate missing speech with the owner's selected ElevenLabs voices.

Owner decision (19-20 October 2026): Turkish = İrem (uvU9jrgGLWNPeNA4NgNT),
English = Laura (GZ4PpFJV8ikEGUtBrjK7), eleven_multilingual_v2, settings from
tools/elevenlabs_voice_settings.json, single words end with a period.

Usage (project root):
    python -I tools/generate_selected_voice.py plan      # counts, no API call
    python -I tools/generate_selected_voice.py run       # generate missing clips
    python -I tools/generate_selected_voice.py apply     # wire into item JSON

Each clip is requested once: an existing output with the same recorded text is
skipped, and a failed request is logged and not retried automatically (no
double spending). The API key is read from ELEVENLABS_API_KEY and never
printed or written. Every generated clip is recorded in
assets/content/generated_voice_manifest.json (text, voice, model, settings,
sha256, bytes, characters, time).
"""
import concurrent.futures
import datetime
import hashlib
import json
import os
import sys
import threading
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SETTINGS = json.loads((ROOT / 'tools' / 'elevenlabs_voice_settings.json').read_text(encoding='utf-8'))
MANIFEST = ROOT / 'assets' / 'content' / 'generated_voice_manifest.json'
ACTIVE_THEMES = ['animals', 'produce', 'colors', 'numbers', 'vehicles', 'shapes']
# Themes prepared ahead of activation (their words are voiced before photos land).
UPCOMING_THEMES = ['body', 'clothes', 'emotions', 'food', 'home', 'jobs', 'music', 'nature', 'school']
VOICED_THEMES = ACTIVE_THEMES + UPCOMING_THEMES

# Spoken game instructions. Keys are file stems under assets/audio/<lang>/prompts/.
PROMPTS = {
    'count': ('Kaç tane var?', 'How many are there?'),
    'compare_magnitude': ('Hangisi daha çok?', 'Which has more?'),
    'compare_numbers': ('Bu sayıları karşılaştır.', 'Compare these numbers.'),
    'group_membership': ('Bu hangi grupta?', 'Which group does this belong to?'),
    'find_match': ('Aynısını bul.', 'Find the match.'),
    'listen_number': ('Dinle. Hangi sayı?', 'Listen. Which number?'),
    'listen_sound': ('Dinle. Ses kimden geliyor?', 'Listen. What makes this sound?'),
    'sequence_next': ('Sıradaki sayı hangisi?', 'Which number comes next?'),
    'sequence_missing': ('Eksik sayı hangisi?', 'Which number is missing?'),
    'odd_one_out': ('Farklı olanı bul.', 'Find the one that is different.'),
    'shadow_match': ('Gölgesini bul.', 'Find its shadow.'),
    'sort_basket': ('Doğru sepete koy.', 'Put it in the right basket.'),
    'number_quantity': ('Bu kadar olanı bul.', 'Find this many.'),
    'which_sound': ('Hangi ses onun?', 'Which sound does it make?'),
    'praise': ('Aferin!', 'Well done!'),
    'retry': ('Tekrar dene.', 'Try again.'),
}
FILL_WORDS = {
    1: ('bir', 'one'), 2: ('iki', 'two'), 3: ('üç', 'three'), 4: ('dört', 'four'),
    5: ('beş', 'five'), 6: ('altı', 'six'), 7: ('yedi', 'seven'),
}
for n, (tr, en) in FILL_WORDS.items():
    PROMPTS[f'fill_count_{n}'] = (f'Sepete {tr} tane koy.', f'Put {en} in the basket.')


PRAISE = [
    ('Aferin!', 'Well done!'), ('Harika iş çıkardın!', 'Great job!'), ('Çok güzel!', 'Very nice!'),
    ('Süpersin!', "You're super!"), ('Bravo!', 'You did it!'), ('Tebrikler!', 'Congratulations!'),
    ('Mükemmel!', 'Perfect!'), ('Çok iyi!', 'Very good!'), ('İşte bu!', "That's it!"),
    ('Harikasın!', "You're amazing!"),
]

# Group explanations said after a correct sort: (TR template, EN template).
GROUP_SENTENCES = {
    'animals': {
        'evcil': ('Evet, {x} bir evcil hayvandır.', 'Yes, the {x} is a pet.'),
        'ciftlik': ('Evet, {x} bir çiftlik hayvanıdır.', 'Yes, the {x} is a farm animal.'),
        'vahsi': ('Evet, {x} vahşi bir hayvandır.', 'Yes, the {x} is a wild animal.'),
        'deniz': ('Evet, {x} suda yaşar.', 'Yes, the {x} lives in the water.'),
        'bocek': ('Evet, {x} bir böcektir.', 'Yes, the {x} is an insect.'),
        'kus': ('Evet, {x} bir kuştur.', 'Yes, the {x} is a bird.'),
    },
    'produce': {
        'meyve': ('Evet, {x} bir meyvedir.', 'Yes, the {x} is a fruit.'),
        'sebze': ('Evet, {x} bir sebzedir.', 'Yes, the {x} is a vegetable.'),
    },
    'vehicles': {
        'kara': ('Evet, {x} yolda gider.', 'Yes, the {x} goes on the road.'),
        'hava': ('Evet, {x} havada uçar.', 'Yes, the {x} flies in the air.'),
        'rayli': ('Evet, {x} rayda gider.', 'Yes, the {x} runs on rails.'),
        'is_makinesi': ('Evet, {x} bir iş makinesidir.', 'Yes, the {x} is a work machine.'),
        'deniz': ('Evet, {x} suda gider.', 'Yes, the {x} goes on the water.'),
    },
}


def tr_lower(text):
    return text.replace('İ', 'i').replace('I', 'ı').lower()


def extra_jobs():
    jobs = []
    for n, pair in enumerate(PRAISE, 1):
        for lang, text in zip(('tr', 'en'), pair):
            jobs.append({'key': f'praise.{n}:{lang}', 'kind': 'praise', 'lang': lang, 'text': text,
                         'out': f'assets/audio/{lang}/praise/praise_{n}.mp3'})
    for theme, groups in GROUP_SENTENCES.items():
        items = json.loads((ROOT / 'assets' / 'content' / 'items' / f'{theme}.json').read_text(encoding='utf-8'))
        for item in items:
            if not item['images']:
                continue
            slug = item['id'].split('.', 1)[1]
            for tag in item['tags']:
                if tag not in groups:
                    continue
                tr_tpl, en_tpl = groups[tag]
                texts = {'tr': tr_tpl.format(x=tr_lower(item['name']['tr'])),
                         'en': en_tpl.format(x=item['name']['en'].lower())}
                if item['id'] == 'animals.bird' and tag == 'kus':
                    texts = {'tr': 'Evet, bu bir kuş.', 'en': 'Yes, this is a bird.'}
                for lang in ('tr', 'en'):
                    jobs.append({'key': f'explain.{item["id"]}.{tag}:{lang}', 'kind': 'explain',
                                 'item': item['id'], 'lang': lang, 'text': texts[lang],
                                 'out': f'assets/audio/{lang}/explain/{theme}_{slug}_{tag}.mp3'})
    return jobs


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_manifest() -> dict:
    if MANIFEST.exists():
        return json.loads(MANIFEST.read_text(encoding='utf-8'))
    return {'voices': SETTINGS['voices'], 'model_id': SETTINGS['model_id'],
            'voice_settings': SETTINGS['voice_settings'], 'clips': {}}


def item_jobs():
    jobs = []
    for theme in VOICED_THEMES:
        items = json.loads((ROOT / 'assets' / 'content' / 'items' / f'{theme}.json').read_text(encoding='utf-8'))
        for item in items:
            audio = item.get('audio') or {}
            tr, en = audio.get('tr'), audio.get('en')
            paths = [ROOT / p for p in (tr, en) if p]
            good = (len(paths) == 2 and all(p.exists() for p in paths)
                    and sha256(paths[0]) != sha256(paths[1])
                    and all(str(p).endswith('_selected.mp3') for p in paths))
            if good:
                continue
            slug = item['id'].split('.', 1)[1]
            for lang in ('tr', 'en'):
                name = item['name'][lang].strip()
                text = name if name.endswith(('.', '!', '?')) else name + '.'
                jobs.append({'key': f"{item['id']}:{lang}", 'kind': 'item', 'item': item['id'], 'lang': lang,
                             'text': text, 'out': f'assets/audio/{lang}/{theme}/{slug}_selected.mp3'})
    return jobs


def prompt_jobs():
    return [{'key': f'prompt.{stem}:{lang}', 'kind': 'prompt', 'lang': lang, 'text': text,
             'out': f'assets/audio/{lang}/prompts/{stem}_selected.mp3'}
            for stem, pair in PROMPTS.items() for lang, text in zip(('tr', 'en'), pair)]


def pending(jobs, manifest):
    result = []
    for job in jobs:
        recorded = manifest['clips'].get(job['key'])
        out = ROOT / job['out']
        if recorded and recorded['text'] == job['text'] and out.exists() and sha256(out) == recorded['sha256']:
            continue
        result.append(job)
    return result


def synthesize(job, key):
    voice = SETTINGS['voices'][job['lang']]['voice_id']
    body = json.dumps({'text': job['text'], 'model_id': SETTINGS['model_id'],
                       'voice_settings': SETTINGS['voice_settings']}).encode('utf-8')
    request = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128',
        data=body, method='POST',
        headers={'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def run():
    key = os.environ.get('ELEVENLABS_API_KEY')
    if not key:
        sys.exit('ELEVENLABS_API_KEY is not set')
    manifest = load_manifest()
    jobs = pending(prompt_jobs() + item_jobs() + extra_jobs(), manifest)
    print(f'{len(jobs)} clips, {sum(len(j["text"]) for j in jobs)} characters to generate')
    lock = threading.Lock()
    failures = []

    def work(job):
        started = datetime.datetime.now(datetime.timezone.utc).isoformat()
        try:
            audio = synthesize(job, key)
        except urllib.error.HTTPError as error:
            failures.append((job['key'], f'HTTP {error.code}'))
            return
        except Exception as error:  # network etc.; recorded, not retried
            failures.append((job['key'], type(error).__name__))
            return
        if len(audio) < 1000:
            failures.append((job['key'], 'short response'))
            return
        out = ROOT / job['out']
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(audio)
        with lock:
            manifest['clips'][job['key']] = {
                'kind': job['kind'], 'item': job.get('item'), 'language': job['lang'],
                'text': job['text'], 'path': job['out'],
                'voice_id': SETTINGS['voices'][job['lang']]['voice_id'],
                'voice_name': SETTINGS['voices'][job['lang']]['name'],
                'model_id': SETTINGS['model_id'], 'voice_settings': SETTINGS['voice_settings'],
                'sha256': sha256(out), 'bytes': len(audio), 'characters': len(job['text']),
                'requested_at': started,
            }
            MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
            done = len(manifest['clips'])
        print(f'ok {job["key"]} ({done} total)', flush=True)

    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(work, jobs))
    print(f'finished; failures: {len(failures)}')
    for key_name, reason in failures:
        print(f'  failed {key_name}: {reason}')


def apply():
    """Point item audio at generated clips (keeps the old files on disk)."""
    manifest = load_manifest()
    changed = 0
    for theme in VOICED_THEMES:
        path = ROOT / 'assets' / 'content' / 'items' / f'{theme}.json'
        raw = path.read_text(encoding='utf-8')
        items = json.loads(raw)
        for item in items:
            for lang in ('tr', 'en'):
                clip = manifest['clips'].get(f"{item['id']}:{lang}")
                if clip and (ROOT / clip['path']).exists():
                    item.setdefault('audio', {})
                    if item['audio'].get(lang) != clip['path']:
                        item['audio'][lang] = clip['path']
                        changed += 1
        newline = '\r\n' if '\r\n' in raw else '\n'
        path.write_text(json.dumps(items, ensure_ascii=False, indent=2).replace('\n', newline), encoding='utf-8')
    print(f'{changed} item audio references updated')


def plan():
    manifest = load_manifest()
    jobs = pending(prompt_jobs() + item_jobs() + extra_jobs(), manifest)
    kinds = {}
    for job in jobs:
        kinds[job['kind']] = kinds.get(job['kind'], 0) + 1
    print(f'{len(jobs)} clips pending {kinds}; {sum(len(j["text"]) for j in jobs)} characters')


if __name__ == '__main__':
    {'plan': plan, 'run': run, 'apply': apply}[sys.argv[1] if len(sys.argv) > 1 else 'plan']()
