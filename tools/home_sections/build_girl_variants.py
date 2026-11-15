"""Builds the girl's counterparts of everything that shows or names the boy.

    python -I tools/home_sections/build_girl_variants.py [--no-voice]

The content is written for Ali (in English Leo). For a girl profile the app
looks every picture, clip and sentence up in assets/content/girl_variants.json
(lib/core/content/child_cast.dart) and uses the counterpart it finds:

- pictures: artifacts/fix-nov12/girl/<name>.png (drawn by girl_runner.py as
  an edit of the boy's picture) are installed beside the boy's with "_girl"
  in the name;
- sentences: every line of the home-sections and pair games that names him,
  with Ali -> Ayşe (Turkish suffixes stay as they are: both names end in a
  front vowel) and Leo -> Mia, he/his/him -> she/her in English;
- clips: those sentences recorded with the same voices to "<clip>_girl.mp3".

Dress-up (G63) and the weather game (G64) have their own rounds for each
child and are left alone. Run after build_themes.py and build_pair_games.py.
"""
import datetime
import hashlib
import importlib.util
import json
import os
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'artifacts/fix-nov12/girl'
OUT = ROOT / 'assets/content/girl_variants.json'
MANIFEST = ROOT / 'tools/home_sections/girl_voice_manifest.json'

# English result lines that speak of him without naming him.
DEPENDENT = ('g69_done_4', 'g69_done_8', 'g64_')
SKIP = ('/g63_', '/g64_')


def girl_tr(text):
    return re.sub(r'\bAli\b', 'Ayşe', text)


def girl_en(text):
    text = re.sub(r'\bLeo\b', 'Mia', text)
    for a, b in (('he', 'she'), ('his', 'her'), ('him', 'her'), ('himself', 'herself')):
        text = re.sub(rf'\b{a}\b', b, text)
        text = re.sub(rf'\b{a.capitalize()}\b', b.capitalize(), text)
    return text


def suffixed(path):
    stem, ext = path.rsplit('.', 1)
    return f'{stem}_girl.{ext}'


def pictures():
    """Installs the drawn pictures; returns {boy asset: girl asset}."""
    out = {}
    for src in sorted(ART.glob('*.png')):
        name = src.stem
        if name.startswith('_'):
            continue
        if name.startswith('need_'):
            boy = f'assets/images/need/{name[5:]}.webp'
        elif name.startswith('scenes_'):
            boy = f'assets/images/scenes/{name[7:]}.jpg'
        elif name.startswith('wear_'):
            boy = f'assets/images/wear/{name[5:]}.webp'
        else:
            boy = f'assets/images/play/{name}.webp'
        if not (ROOT / boy).exists():
            print('no boy picture for', name)
            continue
        girl = suffixed(boy)
        target = ROOT / girl
        like = Image.open(ROOT / boy)
        if not target.exists() or src.stat().st_mtime > target.stat().st_mtime:
            im = Image.open(src)
            if boy.endswith('.jpg'):
                im.convert('RGB').resize(like.size, Image.LANCZOS).save(target, 'JPEG', quality=90)
            elif like.mode == 'RGB':
                im.convert('RGB').resize(like.size, Image.LANCZOS).save(target, 'WEBP', quality=90, method=4)
            else:
                im = im.convert('RGBA')
                im.putalpha(im.getchannel('A').point(lambda v: 0 if v < 20 else v))
                if name.startswith('need_'):
                    # An item picture: the subject centred on a square, like the others.
                    box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
                    sub = im.crop(box)
                    scale = 912 / max(sub.size)
                    sub = sub.resize((round(sub.width * scale), round(sub.height * scale)), Image.LANCZOS)
                    im = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
                    im.paste(sub, ((1024 - sub.width) // 2, (1024 - sub.height) // 2))
                elif name.startswith('wear_'):
                    # The body game's spots are measured on the boy's picture.
                    im = im.resize(like.size, Image.LANCZOS)
                else:
                    box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
                    pad = 24
                    im = im.crop((max(0, box[0] - pad), max(0, box[1] - pad), min(im.width, box[2] + pad), min(im.height, box[3] + pad)))
                    if im.width > 1200:
                        im = im.resize((1200, round(im.height * 1200 / im.width)), Image.LANCZOS)
                im.save(target, 'WEBP', quality=90, alpha_quality=100, method=4)
        out[boy] = girl
    # The dress-up child on the game's card.
    if (ROOT / 'assets/images/wear/girl.webp').exists():
        out['assets/images/wear/boy.webp'] = 'assets/images/wear/girl.webp'
    return out


def lines():
    """Every spoken line as (clip path with {lang}, {'tr': ..., 'en': ...})."""
    found = {}
    for source in sorted((ROOT / 'tools/home_sections/lines').glob('*.json')):
        found.update(json.loads(source.read_text(encoding='utf-8')))
    pairs = json.loads((ROOT / 'tools/pair_games/voice_manifest.json').read_text(encoding='utf-8'))
    for path, clip in pairs.items():
        pattern = path.replace(f'/{clip["language"]}/', '/{lang}/', 1)
        found.setdefault(pattern, {})[clip['language']] = clip['text']
    return found


def main():
    voice = '--no-voice' not in sys.argv
    variants = pictures()
    texts = {'Ali': 'Ayşe', 'Leo': 'Mia'}
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8')) if MANIFEST.exists() else {}
    story_voice = None
    key = os.environ.get('ELEVENLABS_API_KEY')
    if voice and key:
        spec = importlib.util.spec_from_file_location('story_voice', ROOT / 'tools/stories/story_voice.py')
        story_voice = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(story_voice)
    recorded = missing = 0
    for pattern, text in sorted(lines().items()):
        if any(s in pattern for s in SKIP) or 'tr' not in text or 'en' not in text:
            continue
        names_him = re.search(r'\bAli\b', text['tr']) or re.search(r'\bLeo\b', text['en'])
        dependent = any(f'/{d}' in pattern for d in DEPENDENT if not d.endswith('_'))
        if not names_him and not dependent:
            continue
        for lang in ('tr', 'en'):
            new = girl_tr(text[lang]) if lang == 'tr' else girl_en(text[lang])
            if new == text[lang]:
                continue
            texts[text[lang]] = new
            path = pattern.replace('{lang}', lang)
            if not (ROOT / path).exists():
                continue
            girl = suffixed(path)
            out = ROOT / girl
            if story_voice and (not out.exists() or manifest.get(girl, {}).get('text') != new):
                audio = story_voice.finish(story_voice.synthesize(new, lang, key), out)
                manifest[girl] = {'text': new, 'language': lang, 'voice_id': story_voice.VOICES[lang]['voice_id'],
                                  'model_id': story_voice.VOICES[lang]['model_id'],
                                  'sha256': hashlib.sha256(audio).hexdigest(), 'bytes': len(audio),
                                  'requested_at': datetime.datetime.now(datetime.timezone.utc).isoformat()}
                MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
                recorded += 1
                print(girl.encode('ascii', 'replace').decode(), flush=True)
            if out.exists():
                variants[path] = girl
            else:
                missing += 1
    variants.update(texts)
    OUT.write_text(json.dumps(variants, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(f'{len(variants)} counterparts ({len(texts)} sentences), {recorded} clips recorded, {missing} clips missing')


if __name__ == '__main__':
    main()
