"""Lists (or with --delete removes) pictures and clips of the scene games that
nothing refers to any more.

    python -I tools/home_sections/unused_assets.py [--delete]

Looks at assets/images/play, assets/images/wear, assets/images/outfit and
assets/audio/<lang>/scenes; a file is used when its path appears in a content
JSON, in the config or in the Dart code (paths built from a pattern in code
are listed in KEEP).
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FOLDERS = ['assets/images/play', 'assets/images/wear', 'assets/images/outfit',
           'assets/audio/tr/scenes', 'assets/audio/en/scenes']
# Built in code: 'assets/images/wear/${id}_face.webp', the music games' clips.
KEEP = ('_face.webp', 'g75_', 'g76_')


def main():
    text = ''
    for pattern in ('assets/content/**/*.json', 'assets/*.json', 'lib/**/*.dart'):
        for f in ROOT.glob(pattern):
            # photo_bounds.json lists every picture there is, used or not.
            if f.name != 'photo_bounds.json':
                text += f.read_text(encoding='utf-8-sig', errors='ignore')
    unused = []
    for folder in FOLDERS:
        for f in sorted((ROOT / folder).glob('*')):
            rel = f.relative_to(ROOT).as_posix()
            if rel not in text and not any(k in f.name for k in KEEP):
                unused.append(f)
    size = sum(f.stat().st_size for f in unused)
    for f in unused:
        print(f.relative_to(ROOT).as_posix())
    print(f'{len(unused)} unused files, {size // 1024} KB')
    if '--delete' in sys.argv:
        for f in unused:
            f.unlink()
        print('deleted')


if __name__ == '__main__':
    main()
