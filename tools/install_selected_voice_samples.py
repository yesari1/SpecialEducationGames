"""Reuse existing selected-voice samples locally; never generate TTS or contact APIs.

Run before build_content.py. Unity recordings and historical samples are preserved.
"""
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPPINGS = {
    'cat': 'animals.cat', 'dog': 'animals.dog', 'rabbit': 'animals.rabbit',
    'apple': 'produce.apple', 'banana': 'produce.banana',
    'red': 'colors.red', 'three': 'numbers.3',
}
VOICES = {'tr': 'uvU9jrgGLWNPeNA4NgNT', 'en': 'GZ4PpFJV8ikEGUtBrjK7'}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def catalog_items(root):
    return {item['id']: item for path in (root / 'assets/content/items').glob('*.json')
            for item in json.loads(path.read_text(encoding='utf-8'))}


def load_selected_audio(root=ROOT, items=None):
    """Validate installed overrides, returning (item ID, language) -> provenance."""
    manifest = root / 'assets/content/real_audio_manifest.json'
    if not manifest.exists():
        return {}
    items = catalog_items(root) if items is None else items
    data = json.loads(manifest.read_text(encoding='utf-8'))
    if data.get('schemaVersion') != 1:
        raise ValueError('Unsupported selected audio schema')
    result = {}
    for entry in data['assets']:
        identifier, language = entry['id'], entry['language']
        key = identifier, language
        if key in result or identifier not in items or language not in VOICES:
            raise ValueError(f'Invalid or duplicate audio identity: {key}')
        expected = items[identifier]['name'][language].strip() + '.'
        if entry['text'] != expected or entry['voiceId'] != VOICES[language]:
            raise ValueError(f'Spoken label or voice mismatch: {key}')
        if entry['modelId'] != 'eleven_multilingual_v2':
            raise ValueError(f'Model mismatch: {key}')
        theme, slug = identifier.split('.')
        expected_path = f'assets/audio/{language}/{theme}/{slug}_selected.mp3'
        if entry['path'] != expected_path:
            raise ValueError(f'Invalid selected audio path: {key}')
        path = (root / entry['path']).resolve()
        if not path.is_relative_to((root / 'assets/audio').resolve()) or not path.is_file():
            raise ValueError(f'Missing selected audio: {key}')
        if digest(path) != entry['sha256']:
            raise ValueError(f'Selected audio hash mismatch: {key}')
        for field in ('voiceSettings', 'configurationSha256', 'source', 'generationProvenance'):
            if not entry.get(field):
                raise ValueError(f'Missing {field}: {key}')
        result[key] = entry
    return result


def main(root=ROOT):
    directory = root / 'artifacts/voice_samples_selected'
    source_path = directory / 'manifest.json'
    source = json.loads(source_path.read_text(encoding='utf-8'))
    config = source['configuration']
    fingerprint = hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest()
    if fingerprint != source['configuration_sha256']:
        raise ValueError('Source configuration hash mismatch')
    items = catalog_items(root)
    validated = []
    seen = set()
    for sample in source['samples']:
        key = sample['key'], sample['language']
        if key in seen or sample['language'] not in VOICES:
            raise ValueError(f'Invalid or duplicate sample: {key}')
        seen.add(key)
        if sample['voice_id'] != VOICES[sample['language']]:
            raise ValueError(f'Unexpected voice: {key}')
        relative = Path(sample['file'])
        path = (directory / relative).resolve()
        if relative.is_absolute() or not path.is_relative_to(directory.resolve()):
            raise ValueError(f'Invalid source path: {key}')
        if digest(path) != sample['sha256'] or path.stat().st_size != sample['bytes']:
            raise ValueError(f'Source bytes/hash mismatch: {key}')
        probe = json.loads(subprocess.run([
            'ffprobe', '-v', 'error', '-show_entries',
            'format=duration:stream=codec_name,sample_rate,channels', '-of', 'json', str(path)
        ], check=True, capture_output=True, text=True).stdout)
        recorded = sample['validation']
        if (probe['streams'] != recorded['streams'] or
                abs(float(probe['format']['duration']) - recorded['duration_seconds']) > .001):
            raise ValueError(f'Audio properties mismatch: {key}')
        if sample['key'] not in MAPPINGS:
            continue  # Prompt semantics have no exact catalog text; keep gallery-only.
        identifier = MAPPINGS[sample['key']]
        if sample['text'] != items[identifier]['name'][sample['language']].strip() + '.':
            raise ValueError(f'Spoken meaning mismatch: {key}')
        validated.append((sample, identifier, path))
    if len(validated) != 14:
        raise ValueError('Expected exactly fourteen selected vocabulary recordings')
    entries = []
    for sample, identifier, path in validated:
        theme, slug = identifier.split('.')
        relative = f'assets/audio/{sample["language"]}/{theme}/{slug}_selected.mp3'
        destination = root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        entries.append(dict(
            id=identifier, language=sample['language'], path=relative, text=sample['text'],
            voiceId=sample['voice_id'], modelId=config['model_id'],
            voiceSettings=config['voice_settings'],
            settingsProvenance=config['settings_provenance'],
            configurationSha256=fingerprint, sha256=sample['sha256'],
            source=path.relative_to(root).as_posix(), validation=sample['validation'],
            generationProvenance=dict(
                sourceManifest='artifacts/voice_samples_selected/manifest.json',
                sourceManifestSha256=digest(source_path),
                generatedBetweenUtc=[source['account_before']['checked_at_utc'],
                                     source['account_after']['checked_at_utc']],
                provider='ElevenLabs', existingSampleReuse=True, newGeneration=False,
                scope='Selected voice demonstration; pronunciation not user-approved'),
        ))
    manifest = dict(schemaVersion=1, assets=sorted(entries, key=lambda e: (e['id'], e['language'])),
                    galleryOnlySamples=[s['file'] for s in source['samples'] if s['key'] not in MAPPINGS])
    (root / 'assets/content/real_audio_manifest.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    load_selected_audio(root)
    print(f'Validated {len(seen)} existing samples; installed {len(entries)} vocabulary overrides; 6 prompts remain gallery-only.')


if __name__ == '__main__':
    main()
