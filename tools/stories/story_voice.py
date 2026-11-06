"""Records the story narration with ElevenLabs (same voices as the app).

    python -I tools/stories/story_voice.py [story_id ...] [--force]

Turkish: İrem with eleven_v4 and language_code "tr" (Yunus, 6 Nov 2026: the
turbo v2.5 takes sounded muffled, distant or flat). English: Laura with
eleven_multilingual_v2. Reads every line from assets/content/stories.json,
skips clips that already exist (unless --force) and records text, voice,
model and sha256 of each clip in tools/stories/voice_manifest.json.
The API key comes from ELEVENLABS_API_KEY and is never printed.
"""
import datetime
import hashlib
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'tools/stories/voice_manifest.json'
VOICES = {
    'tr': {'voice_id': 'uvU9jrgGLWNPeNA4NgNT', 'name': 'İrem', 'model_id': 'eleven_v4', 'language_code': 'tr'},
    'en': {'voice_id': 'GZ4PpFJV8ikEGUtBrjK7', 'name': 'Laura', 'model_id': 'eleven_multilingual_v2'},
}
# Warm storytelling: some expression, a little slower than the game prompts.
SETTINGS = {'stability': 0.5, 'similarity_boost': 0.8, 'style': 0.35, 'speed': 0.95, 'use_speaker_boost': True}
# Every clip at one loudness, without leading silence, so no line sounds
# distant or starts late.
FILTER = ('silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,'
          'loudnorm=I=-16:TP=-1.5:LRA=11')


def finish(raw, out):
    import subprocess, tempfile
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / 'raw.mp3'
        src.write_bytes(raw)
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(src), '-af', FILTER,
                        '-ar', '44100', '-ac', '1', '-b:a', '128k', str(out)], check=True)
    return out.read_bytes()


def lines(story):
    def walk(node):
        if isinstance(node, dict):
            if 'text' in node and 'audio' in node:
                yield node
            for value in node.values():
                yield from walk(value)
        elif isinstance(node, list):
            for value in node:
                yield from walk(value)
    yield from walk(story)


def synthesize(text, lang, key):
    voice = VOICES[lang]
    body = {'text': text, 'model_id': voice['model_id'], 'voice_settings': SETTINGS}
    if 'language_code' in voice:
        body['language_code'] = voice['language_code']
    request = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice['voice_id']}?output_format=mp3_44100_128",
        data=json.dumps(body).encode('utf-8'), method='POST',
        headers={'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def main():
    key = os.environ.get('ELEVENLABS_API_KEY')
    if not key:
        sys.exit('ELEVENLABS_API_KEY is not set')
    force = '--force' in sys.argv
    wanted = {a for a in sys.argv[1:] if not a.startswith('--')}
    catalog = json.loads((ROOT / 'assets/content/stories.json').read_text(encoding='utf-8'))
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8')) if MANIFEST.exists() else {}
    done = 0
    for story in catalog:
        if wanted and story['id'] not in wanted:
            continue
        for line in lines(story):
            for lang, path in line['audio'].items():
                out = ROOT / path
                if out.exists() and not force:
                    continue
                audio = synthesize(line['text'][lang], lang, key)
                out.parent.mkdir(parents=True, exist_ok=True)
                audio = finish(audio, out)
                voice = VOICES[lang]
                manifest[path] = {
                    'text': line['text'][lang], 'language': lang, 'voice_id': voice['voice_id'],
                    'voice_name': voice['name'], 'model_id': voice['model_id'], 'post': FILTER,
                    'language_code': voice.get('language_code'), 'voice_settings': SETTINGS,
                    'sha256': hashlib.sha256(audio).hexdigest(), 'bytes': len(audio),
                    'requested_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                }
                done += 1
                print(f'{path}: {line["text"][lang]}')
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(f'{done} clips recorded')


if __name__ == '__main__':
    main()
