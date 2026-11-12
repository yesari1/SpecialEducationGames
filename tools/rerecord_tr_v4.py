"""Records Turkish item clips again with İrem on eleven_v4 (language "tr").

    python -I tools/rerecord_tr_v4.py <clip path> [<clip path> ...]

For clips of assets/content/generated_voice_manifest.json that were recorded
with eleven_multilingual_v2 and sound wrong in Turkish (a single short word
read as English). Up to three takes; the first one speech-to-text hears as the
text is installed (same loudness and format as the other new clips), and the
manifests get the new sha256 and size. The API key comes from
ELEVENLABS_API_KEY and is never printed.
"""
import datetime
import hashlib
import importlib.util
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'assets/content/generated_voice_manifest.json'
REAL = ROOT / 'assets/content/real_audio_manifest.json'
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_voice_stt as stt  # noqa: E402

spec = importlib.util.spec_from_file_location('story_voice', ROOT / 'tools/stories/story_voice.py')
story_voice = importlib.util.module_from_spec(spec)
spec.loader.exec_module(story_voice)


def main():
    key = os.environ['ELEVENLABS_API_KEY']
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    by_path = {c['path']: c for c in (manifest['clips'].values() if isinstance(manifest['clips'], dict) else manifest['clips'])}
    real = json.loads(REAL.read_text(encoding='utf-8'))
    for path in sys.argv[1:]:
        clip = by_path[path]
        assert clip['language'] == 'tr', path
        out = ROOT / path
        heard = ''
        for take in range(3):
            audio = story_voice.finish(story_voice.synthesize(clip['text'], 'tr', key), out)
            heard = stt.stt(out, 'tr', key)
            if stt.matches(clip['text'], heard, 'tr'):
                break
        voice = story_voice.VOICES['tr']
        clip.update(sha256=hashlib.sha256(audio).hexdigest(), bytes=len(audio), model_id=voice['model_id'],
                    language_code='tr', voice_settings=story_voice.SETTINGS,
                    requested_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    note=f'Recorded again with eleven_v4 (12 Nov 2026); heard as {heard!r}.')

        def fix(node):
            if isinstance(node, dict):
                if node.get('path') == path:
                    if 'sha256' in node:
                        node['sha256'] = clip['sha256']
                    if 'bytes' in node:
                        node['bytes'] = clip['bytes']
                for value in node.values():
                    fix(value)
            elif isinstance(node, list):
                for value in node:
                    fix(value)
        fix(real)
        print(path, '->', heard)
    # Written the way the tools that own these files write them.
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
    REAL.write_text(json.dumps(real, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
