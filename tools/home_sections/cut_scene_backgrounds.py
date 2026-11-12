"""Removes the plain pastel background of the older result scenes.

    python tools/home_sections/cut_scene_backgrounds.py [name ...]

(Without -I: rembg lives in the user site-packages.) Reads the originals
(<home clone>/artifacts/illustrations-home/scenes/<name>.png, default every
do_* and out_*), cuts the figures out with rembg (U2Net), hardens the alpha
edge and writes artifacts/fix-nov12/cut/<name>.png for review. Install the
approved ones with --install, which writes assets/images/play/<name>.webp.
"""
import sys
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
ORIGINALS = ROOT.parent / 'SpecialEducationGames-home/artifacts/illustrations-home/scenes'
CUT = ROOT / 'artifacts/fix-nov12/cut'
PLAY = ROOT / 'assets/images/play'


def cut(names):
    from rembg import new_session, remove
    session = new_session('u2net')
    CUT.mkdir(parents=True, exist_ok=True)
    for name in names:
        im = Image.open(ORIGINALS / f'{name}.png').convert('RGB')
        out = remove(im, session=session, post_process_mask=True)
        alpha = out.getchannel('A').point(lambda v: 255 if v > 140 else 0)
        alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.8))
        rgba = im.convert('RGBA')
        rgba.putalpha(alpha)
        rgba.save(CUT / f'{name}.png')
        print('cut', name)


def install(names):
    for name in names:
        im = Image.open(CUT / f'{name}.png').convert('RGBA')
        box = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
        pad = 24
        im = im.crop((max(0, box[0] - pad), max(0, box[1] - pad), min(im.width, box[2] + pad), min(im.height, box[3] + pad)))
        if im.width > 1200:
            im = im.resize((1200, round(im.height * 1200 / im.width)), Image.LANCZOS)
        im.save(PLAY / f'{name}.webp', 'WEBP', quality=90, alpha_quality=100, method=4)
        print('installed', name)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    names = args or sorted(p.stem for p in ORIGINALS.glob('*.png') if p.stem.startswith(('do_', 'out_')))
    (install if '--install' in sys.argv else cut)(names)


if __name__ == '__main__':
    main()
