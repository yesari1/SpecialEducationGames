"""Builds the voice review page (all clips made in Nov 2026, TR and EN).

    python -I tools/voice_review/build_review.py <out_dir>

Writes <out_dir>/index.html (the page; marks are kept in the artifact's db
collection "marks", one doc per clip) and copies every clip under
<out_dir>/a/... ; <out_dir>/files.json lists them for publishing.
"""
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HEAD = (ROOT / 'tools/voice_review/page_head.html').read_text(encoding='utf-8')
TAIL = (ROOT / 'tools/voice_review/page_tail.html').read_text(encoding='utf-8')

GAME_NAMES = {
    'G40': 'Ne Renk?', 'G41': 'Renk Sepeti', 'G42': 'Boya', 'G43': 'Şekli Etrafında Bul',
    'G44': 'Ne Oldu, Ne Hissetti?', 'G45': 'Aynı Duygu', 'G46': 'Duygu Sesi', 'G47': "Ali'de Göster",
    'G48': 'Ne İşe Yarar?', 'G49': 'Neyi Nereye Giyeriz?',
}
STORY_NAMES = {'teeth': 'Dişlerimi fırçalıyorum', 'angry': 'Kızınca ne yaparım?',
               'turn': 'Sıramı bekliyorum', 'doctor': 'Doktora gidiyorum'}
THEME_NAMES = {'emotions': 'Duygular', 'body': 'Vücudumuz', 'home': 'Evimiz'}
FEELING_SOUNDS = {'laughing': 'Mutlu (gülme)', 'sad': 'Üzgün (ağlama)', 'sleepy': 'Uykulu (esneme)',
                  'surprised': 'Şaşkın', 'scared': 'Korkmuş', 'angry': 'Kızgın'}


def load(p):
    return json.loads((ROOT / p).read_text(encoding='utf-8-sig'))


def main():
    out = Path(sys.argv[1])
    if (out / 'a').exists():
        shutil.rmtree(out / 'a')
    groups = []  # (section, group title, [clip dicts])

    stories = load('tools/stories/voice_manifest.json')
    catalog = load('assets/content/stories.json')
    for story in catalog:
        sid = story['id']
        order = []

        def walk(node):
            if isinstance(node, dict):
                if 'audio' in node and 'text' in node:
                    order.extend(node['audio'].values())
                for v in node.values():
                    walk(v)
            elif isinstance(node, list):
                for v in node:
                    walk(v)
        walk(story)
        clips = [{'path': p, 'lang': stories[p]['language'], 'text': stories[p]['text']}
                 for p in dict.fromkeys(order) if p in stories]
        groups.append(('Hikâyeler', STORY_NAMES.get(sid, sid), clips))

    pairs = load('tools/pair_games/voice_manifest.json')
    by_game = {}
    for p, e in sorted(pairs.items()):
        game = Path(p).stem.split('_')[0]
        by_game.setdefault(game, []).append({'path': p, 'lang': e['language'], 'text': e['text']})
    for game in sorted(by_game):
        groups.append(('Oyun soruları', f'{GAME_NAMES.get(game, game)}', by_game[game]))

    gen = load('assets/content/generated_voice_manifest.json')['clips']
    for theme, title in THEME_NAMES.items():
        items = load(f'assets/content/items/{theme}.json')
        clips = []
        for item in items:
            for key in (f"{item['id']}:tr", f"{item['id']}.which:tr", f"{item['id']}:en", f"{item['id']}.which:en"):
                e = gen.get(key)
                if e and (ROOT / e['path']).exists():
                    clips.append({'path': e['path'], 'lang': e['language'], 'text': e['text']})
        groups.append(('Tema kelimeleri', title, clips))

    groups.append(('Duygu sesleri', 'Duygu Sesi oyunu', [
        {'path': f'assets/sfx/feelings/{k}.mp3', 'lang': 'ses', 'text': v} for k, v in FEELING_SOUNDS.items()]))

    # The clips travel as one JSON file per section (base64), so the page
    # publishes a handful of files instead of hundreds.
    import base64
    sections = list(dict.fromkeys(s for s, _, _ in groups))
    packs = {s: {} for s in sections}
    data = []
    for section, title, clips in groups:
        rows = []
        for c in clips:
            cid = c['path'].removeprefix('assets/').replace('/', '__').removesuffix('.mp3')
            packs[section][cid] = base64.b64encode((ROOT / c['path']).read_bytes()).decode()
            rows.append({'id': cid, 'pack': f'pack{sections.index(section)}.json',
                         'lang': c['lang'], 'text': c['text'], 'path': c['path']})
        data.append({'section': section, 'title': title, 'rows': rows})
    files = []
    for n, s in enumerate(sections):
        (out / f'pack{n}.json').write_text(json.dumps(packs[s]), encoding='utf-8')
        files.append(f'pack{n}.json')
    page = HEAD + '<script id="clips" type="application/json">' + json.dumps(data, ensure_ascii=False) + '</script>\n' + TAIL
    (out / 'index.html').write_text(page, encoding='utf-8')
    (out / 'files.json').write_text(json.dumps(files), encoding='utf-8')
    print(len(files), 'clips in', len(data), 'groups')


if __name__ == '__main__':
    main()
