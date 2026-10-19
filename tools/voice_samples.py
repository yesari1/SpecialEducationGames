"""Generate 20 selected bilingual takes, preserving the older Lauren evaluation set."""
import argparse
import hashlib
import json
import os
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = Path(__file__).with_name('elevenlabs_voice_settings.json')
OUTPUT = ROOT / 'artifacts' / 'voice_samples_selected'
SAMPLES = [
    ('cat', 'Kedi', 'Cat'), ('dog', 'Köpek', 'Dog'),
    ('rabbit', 'Tavşan', 'Rabbit'), ('apple', 'Elma', 'Apple'),
    ('banana', 'Muz', 'Banana'), ('red', 'Kırmızı', 'Red'),
    ('three', 'Üç', 'Three'),
    ('find_cat', 'Kedi hangisi?', 'Find the cat.'),
    ('praise', 'Aferin! Çok güzel buldun.', 'Well done! You found it.'),
    ('retry', 'Hadi bir daha bakalım.', 'Let’s try again.'),
]


def api(path, data=None):
    key = os.environ.get('ELEVENLABS_API_KEY')
    if not key:
        raise RuntimeError('ELEVENLABS_API_KEY is not configured')
    request = urllib.request.Request(
        'https://api.elevenlabs.io/v1/' + path,
        data=json.dumps(data).encode() if data is not None else None,
        headers={'xi-api-key': key, 'Content-Type': 'application/json'},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def spoken_text(text):
    """Vocabulary labels end with a period; phrases keep their punctuation."""
    text = text.strip()
    if not text:
        raise ValueError('Empty speech text')
    return text if text.endswith(('.', '!', '?')) else text + '.'


def verify_account(config):
    voices = {v['voice_id']: v for v in json.loads(api('voices'))['voices']}
    verified = {}
    for language, selected in config['voices'].items():
        actual = voices.get(selected['voice_id'])
        if actual is None or actual['name'] != selected['name']:
            raise RuntimeError(f'Selected {language} voice ID/name no longer matches; stopping')
        verified[language] = {k: actual.get(k) for k in ('voice_id', 'name', 'category', 'labels')}
    quota = json.loads(api('user/subscription'))
    return {
        'checked_at_utc': datetime.now(timezone.utc).isoformat(),
        'voices': verified,
        'subscription': {k: quota.get(k) for k in (
            'tier', 'character_count', 'character_limit', 'next_character_count_reset_unix')},
    }


def generate(config, account):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest_path = OUTPUT / 'manifest.json'
    fingerprint = hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest()
    if manifest_path.exists():
        previous = json.loads(manifest_path.read_text(encoding='utf-8'))
        if previous.get('configuration_sha256') != fingerprint:
            raise RuntimeError('Existing selected takes use different settings; preserve them in a new directory')
    rows = [dict(language=lang, key=sample[0], text=spoken_text(sample[index]),
                 file=f'{lang}_{sample[0]}.mp3', voice_id=config['voices'][lang]['voice_id'])
            for lang, index in [('tr', 1), ('en', 2)] for sample in SAMPLES]
    pending = [r for r in rows if not (OUTPUT / r['file']).exists()]
    quota = account['subscription']
    conservative_cost = sum(len(r['text']) for r in pending) * 3
    remaining = (quota.get('character_limit') or 0) - (quota.get('character_count') or 0)
    if remaining < conservative_cost:
        raise RuntimeError('Insufficient conservative quota budget; no samples generated')
    manifest = dict(configuration_sha256=fingerprint, configuration=config,
                    account_before=account, samples=[])
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    for row in rows:
        target = OUTPUT / row['file']
        if not target.exists():
            # Multilingual v2 ignores language_code; use the native voice and text.
            payload = dict(text=row['text'], model_id=config['model_id'],
                           voice_settings=config['voice_settings'])
            audio = api('text-to-speech/' + row['voice_id'] + '?output_format=mp3_44100_128', payload)
            if len(audio) < 1024:
                raise RuntimeError('Unexpectedly short audio response; stopped')
            temporary = target.with_suffix('.tmp')
            temporary.write_bytes(audio)
            temporary.replace(target)
        row['bytes'] = target.stat().st_size
        row['sha256'] = hashlib.sha256(target.read_bytes()).hexdigest()
        manifest['samples'].append(row)
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
        print(row['file'], flush=True)
    manifest['account_after'] = verify_account(config)
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--generate', action='store_true')
    args = parser.parse_args()
    config = json.loads(CONFIG.read_text(encoding='utf-8'))
    if not (args.check or args.generate):
        parser.error('Choose --check or --generate')
    account = verify_account(config)
    print(json.dumps(account, ensure_ascii=False), flush=True)
    if args.generate:
        generate(config, account)
