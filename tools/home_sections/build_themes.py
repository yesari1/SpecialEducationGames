"""Builds the new themes' content from source_step*.py.

    python -I tools/home_sections/build_themes.py

Writes items, themes, games, scene and pair games, extra pictures, the free
list and the spoken lines (tools/home_sections/lines/themes.json). A picture
drawn for an item is taken from artifacts/illustrations-home/items/<theme>/
<slug>.png, centred on a 1024 transparent square and saved as WebP. A theme
goes active only when every one of its items has a picture.
"""
import hashlib
import importlib.util
import json
from datetime import date
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / 'assets/content'
ART = ROOT / 'artifacts/illustrations-home'
HERE = Path(__file__).resolve().parent


def load(name):
    spec = importlib.util.spec_from_file_location(name, HERE / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def install(src, out):
    """Crops to the subject, centres on a 1024 square, saves as WebP."""
    im = Image.open(src).convert('RGBA')
    box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
    sub = im.crop(box)
    scale = 912 / max(sub.size)
    sub = sub.resize((max(1, round(sub.width * scale)), max(1, round(sub.height * scale))), Image.LANCZOS)
    canvas = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    canvas.paste(sub, ((1024 - sub.width) // 2, (1024 - sub.height) // 2))
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, 'WEBP', quality=90, alpha_quality=100, method=6)


def picture(theme, slug, item_id):
    """Installs the drawn picture when there is one; returns (images, provenance)."""
    rel = f'assets/images/{theme}/{slug}.webp'
    src = ART / 'items' / theme / f'{slug}.png'
    out = ROOT / rel
    if src.exists() and (not out.exists() or src.stat().st_mtime > out.stat().st_mtime):
        install(src, out)
    if not out.exists():
        return [], {}
    return [rel], {rel: {
        'id': item_id, 'path': rel, 'kind': 'illustration', 'author': 'Yes Studio',
        'source': 'ChatGPT image generation (Codex), SEG soft clay style',
        'license': 'Created for this app', 'licenseVerified': False,
        'createdOn': date.today().isoformat(),
        'sha256': hashlib.sha256(out.read_bytes()).hexdigest(),
    }}


def main():
    sources = [load(p.stem) for p in sorted(HERE.glob('source_step*.py'))]
    lines = {}
    themes = read(CONTENT / 'themes.json')
    by_id = {t['id']: t for t in themes}
    games = {g['id']: g for g in read(CONTENT / 'games.json')}
    scene = {}
    pairs = read(CONTENT / 'pair_games.json')
    extra = {x['id']: x for x in read(CONTENT / 'extra_items.json')}
    config = read(ROOT / 'assets/config_defaults.json')

    item_sfx = {k: v for src in sources for k, v in getattr(src, 'ITEM_SFX', {}).items()}

    def build_items(theme, rows):
        items = []
        for slug, tier, tr, en in rows:
            item_id = f'{theme}.{slug}'
            images, provenance = picture(theme, slug, item_id)
            base = f'assets/audio/{{lang}}/{theme}/{slug}_selected.mp3'
            lines[base] = {'tr': f'{tr}.', 'en': f'{en}.'}
            item = {'id': item_id, 'theme': theme, 'tier': tier, 'chapter': 1, 'tags': [], 'name': {'tr': tr, 'en': en},
                    'images': images, 'audio': {l: base.replace('{lang}', l) for l in ('tr', 'en')}, 'sfx': item_sfx.get(item_id)}
            if provenance:
                item['imageProvenance'] = provenance
            items.append(item)
        write(CONTENT / f'items/{theme}.json', items)
        return all(i['images'] for i in items)

    for src in sources:
        for t in getattr(src, 'THEMES_NEW', []):
            if t['id'] not in by_id:
                entry = {**t, 'active': False, 'games': []}
                themes.append(entry)
                by_id[t['id']] = entry
        for gid, template, tr, en in src.GAMES:
            games[gid] = {'id': gid, 'template': template, 'name': {'tr': tr, 'en': en}}
        for name, value in vars(src).items():
            if name in ('CLEANING', 'KITCHEN', 'JOBS', 'NATURE', 'MUSIC'):
                ready = build_items(name.lower(), value)
                by_id[name.lower()]['active'] = ready
        if hasattr(src, 'CLOTHES_OPEN'):
            items = read(CONTENT / 'items/clothes.json')
            kept = []
            for item in items:
                slug = item['id'].split('.', 1)[1]
                if slug not in src.CLOTHES_OPEN:
                    continue
                images, provenance = picture('clothes', slug, item['id'])
                item['images'] = images
                if provenance:
                    item['imageProvenance'] = provenance
                if slug in src.CLOTHES_EN:
                    item['name']['en'] = src.CLOTHES_EN[slug]
                kept.append(item)
            write(CONTENT / 'items/clothes.json', kept)
            by_id['clothes'].update(src.CLOTHES_THEME)
            by_id['clothes']['active'] = all(i['images'] for i in kept)
        for theme, ids in getattr(src, 'THEME_GAMES', {}).items():
            by_id[theme]['games'] = ids
        for gid, make in src.SCENE_GAMES.items():
            scene[gid] = make()
        for gid, make in src.PAIR_GAMES.items():
            pairs[gid] = make()
        lines.update(src.LINES)  # The makers above fill it.
        for iid, tr, en in src.EXTRA:
            group, slug = iid.split('.', 1)
            images, provenance = picture(group, slug, iid)
            item = {'id': iid, 'theme': 'extra', 'tier': 'easy', 'name': {'tr': tr, 'en': en}, 'images': images, 'audio': {}, 'tags': []}
            if provenance:
                item['imageProvenance'] = provenance
            extra[iid] = item
        free = set(config['freeGames'])
        for key in getattr(src, 'FREE', []):
            free.add(key)
        config['freeGames'] = [k for k in config['freeGames'] if k in free] + sorted(free - set(config['freeGames']))

    # A theme that is not open yet has no free cards.
    config['freeGames'] = [k for k in config['freeGames'] if by_id[k.split('_')[0]]['active']]

    # "Neyi Nereye Giyeriz?" moved from Our Body to Clothes.
    if 'G49' in by_id['body']['games']:
        by_id['body']['games'].remove('G49')
    pairs['G49']['theme'] = 'clothes'

    write(CONTENT / 'themes.json', themes)
    write(CONTENT / 'games.json', list(games.values()))
    write(CONTENT / 'scene_games.json', scene)
    write(CONTENT / 'pair_games.json', pairs)
    write(CONTENT / 'extra_items.json', list(extra.values()))
    write(ROOT / 'assets/config_defaults.json', config)
    write(HERE / 'lines/themes.json', lines)
    print('active:', [t['id'] for t in themes if t['active']])
    print('lines:', len(lines))


if __name__ == '__main__':
    main()
