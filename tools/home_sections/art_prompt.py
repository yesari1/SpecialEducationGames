"""Writes a ChatGPT (Codex) image prompt for a list of item pictures.

    python -I tools/home_sections/art_prompt.py <theme|extra> [start end] > prompt.txt

Pictures go to artifacts/illustrations-home/items/<theme>/<slug>.png, the
folder build_themes.py installs from.
"""
import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

MASTER = """Create an illustration in the "SEG soft clay" style for a calm educational app for young children (2-8) including children with autism and special needs.
Style: soft 2.5D clay / vinyl-toy look, rounded chunky friendly shapes, gentle volume with soft ambient-occlusion shading, one soft light from the top left, no outlines, no black strokes, no texture noise, no glitter, no motion lines.
Palette: warm orange #FF8A32, sky blue #63C6F4, blue #1687D9, turquoise #10B7B0, sunny yellow #FFC546, soft pink #E76F8E, lavender #7C73DF, leaf green #6CC66B, cream #FFF6EA; clear but slightly soft, at most 3-4 main colours.
Calm, low-stimulation composition with lots of empty space, one clear subject, centred, fully inside the frame with ~10% margin, nothing cropped.
No text, no letters, no logos, no watermark. No people, no faces on objects. Transparent background."""

NOTES = {
    'tap': 'a single kitchen-style water tap (faucet) with a small handle',
    'tissue': 'a small box of tissues with one tissue sticking out',
    'dustpan': 'a dustpan with a short handle',
    'drying_rack': 'a folding clothes drying rack with two small clothes on it',
    'bath_sponge': 'a soft round puffy bath sponge',
    'shower': 'a wall shower head with a hose and a few soft water drops',
    'nail_clipper': 'a pair of small nail clippers',
    'rubber_gloves': 'a pair of yellow rubber cleaning gloves',
    'detergent': 'a blue bottle of laundry detergent, with no writing on it',
    'shampoo': 'a bottle of shampoo with no writing on it',
    'toothpaste': 'a tube of toothpaste with no writing on it',
    'cupboard': 'a small wooden kitchen cupboard with two closed doors',
    'cup': 'a small tea cup on a saucer',
    'teapot': 'a Turkish double teapot (caydanlik): a small teapot sitting on top of a larger kettle',
    'glass': 'a plain drinking glass',
    'whisk': 'a balloon whisk',
    'rolling_pin': 'a long thin wooden rolling pin (Turkish oklava)',
    'oven': 'a small kitchen oven with a glass door',
    'fridge': 'a small two-door fridge, closed',
    'dishwasher': 'a small dishwasher, closed',
    'tshirt': 'an orange short-sleeved T-shirt, laid flat',
    'trousers': 'a pair of blue pants, laid flat',
    'weather.rain': 'a rounded window frame seen from inside, soft grey clouds and gentle rain outside',
    'weather.snow': 'a rounded window frame seen from inside, soft snowflakes falling and snow on the sill outside',
    'weather.sun': 'a rounded window frame seen from inside, a bright friendly sun in a clear blue sky outside',
    'weather.sea': 'a rounded window frame seen from inside, a calm blue sea and a small sun outside',
    'weather.night': 'a rounded window frame seen from inside, a dark blue night sky with a soft moon and small stars outside',
    'milk': 'a carton of milk with no writing on it',
    'cheese': 'a wedge of white-yellow cheese',
    'eggs': 'two whole eggs side by side',
    'dirty_plate': 'a plate with a few food crumbs and a soft sauce smear',
    'clean_plate': 'a shiny clean white plate with one small sparkle',
    'clean_glass': 'a shiny clean drinking glass with one small sparkle',
    'dirty_fork': 'a fork with a little sauce on it',
    'peel': 'an empty yellow banana peel',
    'empty_box': 'an open empty cardboard box',
    'cake_dough': 'a round cake tin filled with raw cream-coloured cake batter',
    'yogurt': 'a small white pot of yogurt with no writing on it',
    'foam': 'a soft pile of white soap foam with a few bubbles',
    'water': 'one large soft blue water drop with two small drops',
    'stir.spoon': 'a single long wooden spoon',
    'need.cat_tree': 'a small round tree with a little worried cat sitting on a high branch',
    'need.fire': 'a small house with soft orange flames on its roof',
    'need.fever': 'Ali, a little boy with brown hair and an orange T-shirt, lying in bed looking unwell, with a soft red nose',
    'need.toothache': 'Ali, a little boy with brown hair and an orange T-shirt, holding his cheek with a sad face',
    'need.lost': 'Ali, a little boy with brown hair and an orange T-shirt, standing alone on a pavement, looking around worried',
    'need.sick_dog': 'a small sad puppy lying on a cushion, with a plaster on its paw',
    'need.broken_car': 'a small blue car with its bonnet open and a small puff of grey smoke',
    'need.long_hair': 'Ali, a little boy with very long brown hair covering his eyes and an orange T-shirt',
    'need.dry_garden': 'a small garden bed with three wilted drooping flowers',
    'need.torn_shirt': 'a blue shirt laid flat with a clear tear on its sleeve',
    'use.hose': 'a coiled red fire hose with a brass nozzle',
    'use.tractor': 'a small friendly green tractor',
    'use.letter': 'a closed white envelope with a stamp',
    'use.dental_mirror': 'a small round dental mirror on a thin handle',
    'use.bread_peel': 'a long wooden baker peel holding one loaf of bread',
    'use.thermometer': 'a simple digital fever thermometer with no numbers on it',
    'use.chalk': 'two sticks of white chalk',
    'place.school': 'a small friendly school building with a flag and no writing',
    'place.hospital': 'a small white hospital building with a red cross and no writing',
    'place.restaurant': 'a small restaurant building with a striped awning and no writing',
    'place.farm': 'a small red barn with a fence',
    'place.fire_station': 'a small red fire station with a big garage door and no writing',
    'place.bakery': 'a small bakery shop with a loaf of bread sign and no writing',
    'place.police_station': 'a small blue police station building with a light on top and no writing',
    'place.plane': 'a small friendly passenger airplane',
    'place.ship': 'a small friendly ship on a little wave',
    'place.pharmacy': 'a small pharmacy building with a green cross and no writing',
    'grow.seed': 'one big brown seed',
    'grow.can': 'a watering can',
    'grow.sun': 'a friendly round sun with short rounded rays',
    'grow.shoe': 'a single small shoe',
    'grow.spoon': 'a single spoon',
    'grow.ball': 'a single round ball',
    'season.snow': 'a soft white pile of snow with three snowflakes',
    'season.blossom': 'a small bunch of pink blossoms',
    'season.yellow_leaves': 'three yellow autumn leaves',
    'season.apples': 'three red apples',
    'nature.rain': 'a small soft cloud with gentle rain drops under it',
    'nature.snow': 'a few big soft snowflakes above a small pile of snow',
    'nature.sun': 'a friendly round sun with short rounded rays',
    'nature.moon': 'a soft crescent moon',
    'nature.star': 'a single soft rounded star',
    'nature.cloud': 'a single puffy white cloud',
    'nature.tree': 'a single round green tree on a small grass patch',
    'nature.flower': 'a single pink flower with a green stem and two leaves',
    'nature.sea': 'a small rounded patch of calm blue sea with two soft waves',
    'nature.mountain': 'one snow-capped mountain',
    'nature.rainbow': 'a soft rainbow arc with a small cloud at each end',
    'nature.snowman': 'a friendly snowman with a carrot nose and a scarf',
    'nature.wind': 'three soft curled swirls of pale blue wind',
    'nature.lightning': 'a soft grey cloud with one yellow lightning bolt',
    'nature.leaf': 'a single green leaf',
    'nature.grass': 'a small patch of green grass',
    'nature.river': 'a soft blue river winding through a green patch',
    'nature.lake': 'a small round blue lake with a small reed on its shore',
    'nature.forest': 'a small group of three round green trees',
    'nature.spring': 'a small tree full of pink blossoms on green grass',
    'nature.summer': 'a small full green tree under a bright sun',
    'nature.autumn': 'a small tree with orange and yellow leaves, a few leaves on the ground',
    'nature.winter': 'a small bare tree with snow on its branches',
    'nature.night': 'a rounded dark blue square tile with a soft moon and small stars',
    'nature.day': 'a rounded light blue square tile with a bright sun and a small cloud',
    'nature.seed': 'a single brown seed',
    'nature.sprout': 'a small green sprout with two leaves in a little soil',
    'nature.sand': 'a small pile of yellow sand with a toy shovel in it',
}


def load(path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    theme = sys.argv[1]
    rows = []
    for path in sorted(HERE.glob('source_step*.py')):
        src = load(path)
        if theme == 'extra':
            for iid, _, en in src.EXTRA:
                group, slug = iid.split('.', 1)
                rows.append((group, slug, en))
        elif theme == 'clothes' and hasattr(src, 'CLOTHES_OPEN'):
            names = src.CLOTHES_EN
            rows += [('clothes', s, names.get(s, s.replace('_', ' '))) for s in src.CLOTHES_OPEN]
        elif hasattr(src, theme.upper()):
            rows += [(theme, slug, en) for slug, _, _, en in getattr(src, theme.upper())]
    if len(sys.argv) > 3:
        rows = rows[int(sys.argv[2]):int(sys.argv[3])]
    print('Use your image generation tool to make the PNG illustrations below and save each one to the exact path given. '
          'Generate each picture separately (one image call per file). Square 1024x1024, TRUE transparent background (alpha), '
          'nothing cropped. Skip a file that already exists. Do not change any other file. If your image limit is reached, stop and say so plainly. '
          'When done, reply with the list of saved files.\n')
    print('Master style for EVERY picture:\n' + (MASTER.replace(' No people, no faces on objects.', '') if theme == 'jobs' else MASTER) + '\n')
    for i, (group, slug, en) in enumerate(rows, 1):
        out = ROOT / 'artifacts/illustrations-home/items' / group / f'{slug}.png'
        default = f'A friendly clay adult {en.lower()} in simple work clothes, whole body, dot eyes, small smile' if group == 'jobs' else f'A single {en.lower()}'
        print(f'{i}. {out}: {NOTES.get(f"{group}.{slug}", NOTES.get(slug, default))}.')


if __name__ == '__main__':
    main()
