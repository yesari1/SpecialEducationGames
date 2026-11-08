"""Turns the colouring-book drawings into app assets.

    python -I tools/home_sections/install_coloring.py

From artifacts/illustrations-home/coloring/<name>.png writes
assets/coloring/<name>_line.png (black lines on transparent) and
<name>_regions.png (a grey picture: each closed area has its own value, the
lines are 0). The app paints a whole area when it is tapped.
"""
import json
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SIZE = 512
MIN_AREA = 50


def main():
    out = ROOT / 'assets/coloring'
    out.mkdir(parents=True, exist_ok=True)
    names = []
    for src in sorted((ROOT / 'artifacts/illustrations-home/coloring').glob('*.png')):
        grey = Image.open(src).convert('L')
        line = grey.resize((768, 768), Image.LANCZOS)
        alpha = line.point(lambda v: min(255, max(0, round((215 - v) * 1.6))))
        rgba = Image.new('RGBA', line.size, (30, 30, 30, 0))
        rgba.putalpha(alpha)
        rgba.save(out / f'{src.stem}_line.png', optimize=True)

        small = grey.resize((SIZE, SIZE), Image.LANCZOS)
        pixels = small.load()
        labels = [[0] * SIZE for _ in range(SIZE)]
        next_id, areas = 1, []
        for y in range(SIZE):
            for x in range(SIZE):
                if labels[y][x] or pixels[x, y] < 150:
                    continue
                queue = deque([(x, y)])
                labels[y][x] = next_id
                cells = 0
                while queue:
                    cx, cy = queue.popleft()
                    cells += 1
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < SIZE and 0 <= ny < SIZE and not labels[ny][nx] and pixels[nx, ny] >= 150:
                            labels[ny][nx] = next_id
                            queue.append((nx, ny))
                areas.append(cells)
                next_id += 1
        # Specks and hairline slivers are not areas to paint.
        keep = {i + 1: new for new, i in enumerate(i for i, area in enumerate(areas) if area >= MIN_AREA)}
        result = Image.new('L', (SIZE, SIZE))
        out_pixels = result.load()
        for y in range(SIZE):
            for x in range(SIZE):
                value = keep.get(labels[y][x], -1) + 1
                out_pixels[x, y] = value
        result.save(out / f'{src.stem}_regions.png', optimize=True)
        names.append(src.stem)
        print(src.stem, 'areas:', len(keep))
    (ROOT / 'assets/content/coloring.json').write_text(json.dumps(names) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
