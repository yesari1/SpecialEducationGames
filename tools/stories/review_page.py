"""Builds a review page (pictures + TR/EN text + play buttons) for Yunus.

    python -I tools/stories/review_page.py <out_dir>

Writes <out_dir>/hikaye-inceleme.html, the media it uses under <out_dir>/assets/
and <out_dir>/files.json (the list to publish next to the page).
"""
import json
import os
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
HEAD = (ROOT / 'tools/stories/review_head.html').read_text(encoding='utf-8')


def main():
    out_dir = Path(sys.argv[1])
    if (out_dir / 'assets').exists():
        shutil.rmtree(out_dir / 'assets')
    catalog = json.loads((ROOT / 'assets/content/stories.json').read_text(encoding='utf-8'))
    files = []

    def media(path):
        rel = path[:-4] + '.jpg' if path.endswith('.png') else path
        dst = out_dir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        if path.endswith('.png'):
            im = Image.open(ROOT / path).convert('RGBA')
            bg = Image.new('RGBA', im.size, (255, 255, 255, 255))
            bg.alpha_composite(im)
            bg.convert('RGB').resize((320, 320)).save(dst, quality=82)
        elif path.endswith('.jpg'):
            Image.open(ROOT / path).resize((600, 400)).save(dst, quality=82)
        else:
            shutil.copy(ROOT / path, dst)
        files.append(rel)
        return rel

    def audio(line):
        return ''.join(f'<button class="play" data-src="{media(line["audio"][l])}">▶ {l.upper()}</button>'
                       for l in ('tr', 'en'))

    def text(line):
        return f'<div class="tr">{line["text"]["tr"]}</div><div class="en">{line["text"]["en"]}</div>'

    out = []
    for s in catalog:
        badge = 'Ücretsiz' if s.get('free') else 'Premium'
        out.append(f'<section><h2>{s["title"]["tr"]} <span class="en">· {s["title"]["en"]} · {badge}</span></h2>')
        for n, p in enumerate(s['pages'], 1):
            out.append(f'<div class="page"><div class="num">{n}</div><div class="body">')
            if 'image' in p:
                out.append(f'<img class="scene" src="{media(p["image"])}" alt="">')
            out.append(f'<div class="line">{text(p["line"])}<div class="btns">{audio(p["line"])}</div></div>')
            if 'choices' in p:
                out.append('<div class="choices">')
                for c in p['choices']:
                    cls, cap = ('ok', '✓ doğru') if c['correct'] else ('no', 'yanlış')
                    out.append(f'<figure class="{cls}"><img src="{media(c["image"])}" alt=""><figcaption>{cap}</figcaption></figure>')
                out.append('</div>')
                for c in p['choices']:
                    if 'result' in c:
                        im = f'<img class="scene" src="{media(c["resultImage"])}" alt="">' if 'resultImage' in c else ''
                        out.append(f'<div class="result"><b>Yanlış seçilince:</b>{im}<div class="line">{text(c["result"])}'
                                   f'<div class="btns">{audio(c["result"])}</div></div></div>')
                if 'retry' in p:
                    out.append(f'<div class="result"><b>Sonra tekrar sorulur:</b><div class="line">{text(p["retry"])}'
                               f'<div class="btns">{audio(p["retry"])}</div></div></div>')
            out.append('</div></div>')
        if 'praise' in s:
            out.append(f'<div class="page"><div class="num">★</div><div class="body"><div class="line">{text(s["praise"])}'
                       f'<div class="btns">{audio(s["praise"])}</div></div></div></div>')
        out.append('</section>')
    page = HEAD + '\n'.join(out) + """
</main>
<script>
const a=new Audio();let cur=null;
document.addEventListener('click',e=>{const b=e.target.closest('.play');if(!b)return;
if(cur)cur.classList.remove('on');a.src=b.dataset.src;a.play().catch(()=>{});cur=b;b.classList.add('on');});
a.addEventListener('ended',()=>{if(cur)cur.classList.remove('on');});
</script>
"""
    (out_dir / 'hikaye-inceleme.html').write_text(page, encoding='utf-8')
    (out_dir / 'files.json').write_text(json.dumps([{'path': f} for f in sorted(set(files))]), encoding='utf-8')
    print(len(set(files)), 'files')


if __name__ == '__main__':
    main()
