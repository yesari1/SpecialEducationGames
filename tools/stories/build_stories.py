"""Builds assets/content/stories.json from tools/stories/stories_source.json.

The source holds only the texts; this script adds the picture and narration
paths by one naming rule, so the app catalog never has hand-typed paths:
  pictures  assets/stories/<id>/cover.png, page<N>.jpg, choice_<key>.png,
            result_<key>.jpg (only where the source sets "resultImage")
  narration assets/audio/<lang>/stories/<id>/p<N>.mp3, p<N>_retry.mp3,
            p<N>_<key>.mp3 (a wrong choice's result), praise.mp3
Usage: python -I tools/stories/build_stories.py [--check]
--check also lists every referenced file that does not exist yet.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LANGS = ('tr', 'en')


def line(text, audio_name, story_id):
    return {
        'text': {lang: text[lang] for lang in LANGS},
        'audio': {lang: f'assets/audio/{lang}/stories/{story_id}/{audio_name}.mp3' for lang in LANGS},
    }


def build(source):
    out = []
    for story in source:
        sid = story['id']
        base = f'assets/stories/{sid}'
        pages = []
        for n, page in enumerate(story['pages'], start=1):
            built = {'line': line(page, f'p{n}', sid)}
            if 'choices' in page:
                if 'retry' in page:
                    built['retry'] = line(page['retry'], f'p{n}_retry', sid)
                choices = []
                for choice in page['choices']:
                    key = choice['key']
                    item = {'image': f'{base}/choice_{key}.png', 'correct': choice.get('correct', False)}
                    if 'result' in choice:
                        item['result'] = line(choice['result'], f'p{n}_{key}', sid)
                    if choice.get('resultImage'):
                        item['resultImage'] = f'{base}/result_{key}.jpg'
                    choices.append(item)
                built['choices'] = choices
            else:
                built['image'] = f'{base}/page{n}.jpg'
            pages.append(built)
        entry = {'id': sid, 'free': story.get('free', False), 'title': story['title'],
                 'cover': f'{base}/cover.png', 'pages': pages}
        if 'praise' in story:
            entry['praise'] = line(story['praise'], 'praise', sid)
        out.append(entry)
    return out


def referenced(catalog):
    def walk(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key in ('image', 'cover', 'resultImage') and isinstance(value, str):
                    yield value
                elif key == 'audio':
                    yield from value.values()
                else:
                    yield from walk(value)
        elif isinstance(node, list):
            for value in node:
                yield from walk(value)
    return sorted(set(walk(catalog)))


def main():
    source = json.loads((ROOT / 'tools/stories/stories_source.json').read_text(encoding='utf-8'))
    catalog = build(source)
    target = ROOT / 'assets/content/stories.json'
    target.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'wrote {target.relative_to(ROOT)}: {len(catalog)} stories')
    if '--check' in sys.argv:
        missing = [p for p in referenced(catalog) if not (ROOT / p).is_file()]
        print(f'missing files: {len(missing)}')
        for p in missing:
            print('  ' + p)


if __name__ == '__main__':
    main()
