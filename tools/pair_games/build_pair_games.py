"""Builds assets/content/pair_games.json from tools/pair_games/source.py and
records the spoken questions.

    python -I tools/pair_games/build_pair_games.py [--no-voice]

Clips: assets/audio/<lang>/pairs/<game>_<n>.mp3, or <game>_<clip>.mp3 when
rounds share one sentence ("clip"). Turkish: İrem on eleven_v4 +
language_code tr; English: Laura on eleven_multilingual_v2. Each clip is
loudness-normalized and STT-checked (up to 3 takes; disagreements listed).
Existing clips whose text did not change are kept (manifest
tools/pair_games/voice_manifest.json).
"""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
sys.path.insert(0, str(ROOT / 'tools/pair_games'))
import source  # noqa: E402

MANIFEST = ROOT / 'tools/pair_games/voice_manifest.json'


def main():
    voice = '--no-voice' not in sys.argv
    if voice:
        import theme_voice as tv  # noqa: E402  (reuses its TTS + STT helpers)
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8')) if MANIFEST.exists() else {}
    review = []
    out = {}
    for gid, game in source.all_games().items():
        rounds = []
        for n, r in enumerate(game['rounds'], start=1):
            stem = f"{gid}_{r.get('clip', n)}"
            audio = {}
            for lang in ('tr', 'en'):
                rel = f'assets/audio/{lang}/pairs/{stem}.mp3'
                audio[lang] = rel
                text = r['text'][lang]
                path = ROOT / rel
                if path.exists() and manifest.get(rel, {}).get('text') == text:
                    continue
                if not voice:
                    continue
                data = tv.record(text, lang, path, review)
                manifest[rel] = {'text': text, 'language': lang, 'model_id': tv.VOICES[lang]['model_id'],
                                 'voice_id': tv.VOICES[lang]['voice_id'], 'sha256': hashlib.sha256(data).hexdigest()}
                print(rel, text)
            entry = {'target': r['target'], 'text': r['text'], 'audio': audio}
            for key in ('stimulus', 'sound', 'alsoRight'):
                if key in r:
                    entry[key] = r[key]
            rounds.append(entry)
        game_out = {k: v for k, v in game.items() if k != 'rounds'}
        game_out['rounds'] = rounds
        out[gid] = game_out
    for stem, text in source.clips().items():
        for lang in ('tr', 'en'):
            rel = f'assets/audio/{lang}/pairs/{stem}.mp3'
            path = ROOT / rel
            if path.exists() and manifest.get(rel, {}).get('text') == text[lang]:
                continue
            if not voice:
                continue
            data = tv.record(text[lang], lang, path, review)
            manifest[rel] = {'text': text[lang], 'language': lang, 'model_id': tv.VOICES[lang]['model_id'],
                             'voice_id': tv.VOICES[lang]['voice_id'], 'sha256': hashlib.sha256(data).hexdigest()}
            print(rel, text[lang])
    (ROOT / 'assets/content/extra_items.json').write_text(
        json.dumps(source.source_more.extra_items(), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (ROOT / 'assets/content/body_map.json').write_text(
        json.dumps(source.source_more.body_map(), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (ROOT / 'assets/content/pair_games.json').write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print('games:', ', '.join(out), '| STT disagreements:', len(review))
    for line in review:
        print('  ' + line)


if __name__ == '__main__':
    main()
