"""Records the home-sections and new-theme lines with ElevenLabs.

    python -I tools/home_sections/record_lines.py [--force] [--changed] [--only <text>] [--lang tr|en]

Reads every tools/home_sections/lines/*.json ({"<clip path with {lang}>":
{"tr": "...", "en": "..."}}). Turkish: İrem, eleven_v4 with language_code tr;
English: Laura, eleven_multilingual_v2. Clips that exist are skipped unless
--force is given; --changed also records again every clip whose text is no
longer the one in the manifest; --only limits to paths containing the text. Records text,
voice, model and sha256 in tools/home_sections/voice_manifest.json. The API key
comes from ELEVENLABS_API_KEY and is never printed.
"""
import datetime
import hashlib
import importlib.util
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'tools/home_sections/voice_manifest.json'
spec = importlib.util.spec_from_file_location('story_voice', ROOT / 'tools/stories/story_voice.py')
story_voice = importlib.util.module_from_spec(spec)
spec.loader.exec_module(story_voice)


def main():
    key = os.environ.get('ELEVENLABS_API_KEY')
    if not key:
        sys.exit('ELEVENLABS_API_KEY is not set')
    args = sys.argv[1:]
    force = '--force' in args
    changed = '--changed' in args
    only_lang = args[args.index('--lang') + 1] if '--lang' in args else None
    only = args[args.index('--only') + 1] if '--only' in args else None
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8')) if MANIFEST.exists() else {}
    done = 0
    for source in sorted((ROOT / 'tools/home_sections/lines').glob('*.json')):
        for pattern, texts in json.loads(source.read_text(encoding='utf-8')).items():
            for lang in ('tr', 'en'):
                path = pattern.replace('{lang}', lang)
                if only and only not in path:
                    continue
                if only_lang and lang != only_lang:
                    continue
                out = ROOT / path
                stale = changed and path in manifest and manifest[path].get('text') != texts[lang]
                if out.exists() and not force and not stale:
                    continue
                audio = story_voice.synthesize(texts[lang], lang, key)
                out.parent.mkdir(parents=True, exist_ok=True)
                audio = story_voice.finish(audio, out)
                voice = story_voice.VOICES[lang]
                manifest[path] = {
                    'text': texts[lang], 'language': lang, 'voice_id': voice['voice_id'],
                    'voice_name': voice['name'], 'model_id': voice['model_id'],
                    'language_code': voice.get('language_code'), 'post': story_voice.FILTER,
                    'voice_settings': story_voice.SETTINGS,
                    'sha256': hashlib.sha256(audio).hexdigest(), 'bytes': len(audio),
                    'requested_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                }
                done += 1
                print(f'{path}: {texts[lang]}')
                MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(f'{done} clips recorded')


if __name__ == '__main__':
    main()
