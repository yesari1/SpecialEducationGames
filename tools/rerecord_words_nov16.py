"""Records Turkish single words again, three takes each (Yunus, 16 Nov 2026).

    python -I tools/rerecord_words_nov16.py

İrem, eleven_v4, language_code "tr". Each word gets three takes with a
calm, a default and a lively setting; all takes are kept under
artifacts/claude/voice-nov16/takes/ for the review page, and the first take
that speech-to-text hears as the word is installed over the asset (the
default take when none matches). Manifests that list the clip get the new
sha256 and size. The API key comes from ELEVENLABS_API_KEY and is never printed.
"""
import datetime
import hashlib
import importlib.util
import json
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TAKES = ROOT / 'artifacts/claude/voice-nov16/takes'
GEN = ROOT / 'assets/content/generated_voice_manifest.json'
REAL = ROOT / 'assets/content/real_audio_manifest.json'
HOME = ROOT / 'tools/home_sections/voice_manifest.json'
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_voice_stt as stt  # noqa: E402

spec = importlib.util.spec_from_file_location('story_voice', ROOT / 'tools/stories/story_voice.py')
sv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sv)

VARIANTS = [
    ('default', dict(sv.SETTINGS)),
    ('calm', {'stability': 0.75, 'similarity_boost': 0.8, 'style': 0.1, 'speed': 0.9, 'use_speaker_boost': True}),
    ('lively', {'stability': 0.35, 'similarity_boost': 0.8, 'style': 0.55, 'speed': 1.0, 'use_speaker_boost': True}),
]

MUSIC = ['accordion', 'baglama', 'bell', 'castanets', 'cello', 'clarinet', 'davul_zurna', 'double_bass', 'drum',
         'flute', 'guitar', 'harmonica', 'harp', 'kanun', 'keyboard', 'maracas', 'ney', 'oud', 'piano', 'recorder',
         'saxophone', 'tambourine', 'triangle', 'trombone', 'trumpet', 'ukulele', 'violin', 'xylophone', 'zurna']
WORDS = [
    'assets/audio/tr/praise/praise_1.mp3', 'assets/audio/tr/prompts/praise_selected.mp3',
    'assets/audio/tr/praise/praise_4.mp3', 'assets/audio/tr/praise/praise_5.mp3',
    'assets/audio/tr/body/arm_selected.mp3', 'assets/audio/tr/jobs/doctor_selected.mp3',
    'assets/audio/tr/nature/moon_selected.mp3', 'assets/audio/tr/nature/cloud_selected.mp3',
    'assets/audio/tr/sections/tab_learn.mp3',
] + [f'assets/audio/tr/music/{m}_selected.mp3' for m in MUSIC]


SPOKEN = {'Kol.': 'Kol!', 'Org.': 'Org!', 'Ud.': 'Ud!', 'Tef.': 'tef'}  # 'tef' (lower case, no stop) was the one Yunus picked


def synthesize(text, settings, key):
    import urllib.request
    voice = sv.VOICES['tr']
    body = {'text': text, 'model_id': voice['model_id'], 'voice_settings': settings, 'language_code': 'tr'}
    request = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice['voice_id']}?output_format=mp3_44100_128",
        data=json.dumps(body).encode('utf-8'), method='POST',
        headers={'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def walk_fix(node, path, sha, size):
    if isinstance(node, dict):
        if node.get('path') == path:
            if 'sha256' in node:
                node['sha256'] = sha
            if 'bytes' in node:
                node['bytes'] = size
        for value in node.values():
            walk_fix(value, path, sha, size)
    elif isinstance(node, list):
        for value in node:
            walk_fix(value, path, sha, size)


def main():
    key = os.environ['ELEVENLABS_API_KEY']
    only = [a for a in sys.argv[1:]]
    gen = json.loads(GEN.read_text(encoding='utf-8'))
    gen_clips = gen['clips'].values() if isinstance(gen['clips'], dict) else gen['clips']
    by_path = {c['path']: c for c in gen_clips}
    real = json.loads(REAL.read_text(encoding='utf-8'))
    home = json.loads(HOME.read_text(encoding='utf-8'))
    report_path = TAKES.parent / 'words.json'
    report = json.loads(report_path.read_text(encoding='utf-8')) if report_path.exists() else {}
    TAKES.mkdir(parents=True, exist_ok=True)
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    for path in WORDS:
        if only and not any(o in path for o in only):
            continue
        text = (by_path.get(path) or home.get(path))['text']
        # A short word with a full stop is read as an abbreviation ("Org." ->
        # "Organizasyon", "Tef." -> "Telefon"); these are spoken without it.
        spoken = SPOKEN.get(text, text)
        stem = path.replace('assets/audio/tr/', '').replace('/', '__').replace('.mp3', '')
        takes = []
        for name, settings in VARIANTS:
            out = TAKES / f'{stem}__{name}.mp3'
            sv.finish(synthesize(spoken, settings, key), out)
            heard = stt.stt(out, 'tr', key)
            takes.append({'variant': name, 'file': out.name, 'heard': heard, 'ok': stt.matches(text, heard, 'tr')})
        # The default take is what Yunus found poor before; prefer the calm one.
        chosen = next((t for t in sorted(takes, key=lambda t: t['variant'] != 'calm') if t['ok']), takes[1])
        target = ROOT / path
        shutil.copyfile(TAKES / chosen['file'], target)
        audio = target.read_bytes()
        sha, size = hashlib.sha256(audio).hexdigest(), len(audio)
        settings = dict(VARIANTS)[chosen['variant']]
        if path in by_path:
            by_path[path].update(sha256=sha, bytes=size, model_id='eleven_v4', language_code='tr',
                                 voice_settings=settings, requested_at=now,
                                 note=f"Recorded again (16 Nov 2026), take {chosen['variant']}; heard as {chosen['heard']!r}.")
        if path in home:
            home[path].update(sha256=sha, bytes=size, model_id='eleven_v4', language_code='tr',
                              voice_settings=settings, requested_at=now)
        walk_fix(real, path, sha, size)
        report[path] = {'text': text, 'chosen': chosen['variant'], 'takes': takes}
        print(path, text, '->', [(t['variant'], t['heard'], t['ok']) for t in takes], 'chosen', chosen['variant'])
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding='utf-8')
    GEN.write_text(json.dumps(gen, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
    REAL.write_text(json.dumps(real, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    HOME.write_text(json.dumps(home, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
