"""Scene pictures of the new games: prompts for ChatGPT (Codex) and installing.

    python -I tools/home_sections/art_scenes.py prompt <group> > prompt.txt
    python -I tools/home_sections/art_scenes.py install

Pass artifacts/illustrations-home/characters_v1.png as the reference picture
(codex exec -i). Originals go to artifacts/illustrations-home/scenes/; install
writes assets/images/play/<name>.webp (the games' pictures).
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SCENES = ROOT / 'artifacts/illustrations-home/scenes'

STYLE = """Style for EVERY picture: "SEG soft clay" illustration for a calm educational app for young children including children with autism: soft 2.5D clay / vinyl-toy look, rounded chunky friendly shapes, gentle volume with soft shading, one soft light from the top left, no outlines, no black strokes, no texture noise, no glitter, no motion lines. Palette: warm orange #FF8A32, sky blue #63C6F4, blue #1687D9, turquoise #10B7B0, sunny yellow #FFC546, soft pink #E76F8E, lavender #7C73DF, leaf green #6CC66B, cream #FFF6EA. Calm, tidy, one clear idea, lots of empty space, nothing cropped. No text, no letters, no logos, no watermark.
The boy in the reference sheet is Ali (brown hair, dot eyes, small smile, orange T-shirt, blue shorts, white shoes). Mom is the woman on the sheet. Keep them exactly as on the sheet whenever they appear."""

SCENE = 'Landscape 1536x1024, soft plain pastel background (cream to pale sky blue), no busy room detail. '
ALI_TALL = 'Tall portrait 1024x1536, TRUE transparent background, Ali standing front-on with arms slightly away from his body, whole body inside the frame, same pose and proportions in every picture of this group. '

GROUPS = {
    'cleaning': {
        'teeth_dirty': SCENE + "Big close-up of Ali's friendly face filling the picture, mouth wide open in a big smile showing two neat rows of white teeth; the teeth area is large and centred in the lower middle of the picture.",
        'teeth_clean': SCENE + "Same big close-up of Ali's face as teeth_dirty, same size and position, eyes happily curved, big proud closed-lip-free smile showing shining white teeth, one small soft sparkle.",
        'wash_dirty': SCENE + 'Two small child hands with soft brown smudges, held above a white sink with a closed tap. Only hands and sink, no face.',
        'wash_water': SCENE + 'Same sink and hands, the tap is open and a gentle stream of water runs over the smudged hands.',
        'wash_soap': SCENE + 'Same sink and hands, tap open, hands holding a rounded bar of soap with a little foam.',
        'wash_foam': SCENE + 'Same sink and hands covered in lots of soft white foam, a few round bubbles.',
        'wash_rinse': SCENE + 'Same sink, water rinsing the foam off, the hands are clean.',
        'wash_dry': SCENE + 'The same two clean hands drying on a soft blue towel, a small soft sparkle.',
        'do_comb': SCENE + 'Ali in a calm bathroom-free plain scene combing his hair with a comb, smiling.',
        'do_brush': SCENE + 'Ali brushing his teeth with a toothbrush, a little foam on his mouth, smiling eyes.',
        'do_soap': SCENE + 'Ali at a sink soaping his hands with a bar of soap, smiling.',
        'do_towel': SCENE + 'Ali drying his face with a soft blue towel, smiling eyes above the towel.',
        'do_shampoo': SCENE + 'Ali washing his hair, white shampoo foam on his head, eyes closed and smiling.',
        'do_tissue': SCENE + 'Ali gently wiping his nose with a white tissue.',
        'do_bin': SCENE + 'Ali dropping a small paper ball into a round trash can, smiling.',
        'do_broom': SCENE + 'Ali sweeping a small pile of dust on the floor with a broom, smiling.',
        'do_sponge': SCENE + 'Ali at a kitchen sink washing a plate with a yellow sponge and foam, smiling.',
        'do_mop': SCENE + 'Ali mopping a shiny floor with a mop and a bucket beside him, smiling.',
        'do_dryer': SCENE + 'Ali drying his hair with a hair dryer, hair softly lifted, smiling.',
        'do_nails': SCENE + "Mom gently cutting Ali's fingernails with small nail clippers, both calm and smiling.",
        'do_vacuum': SCENE + 'Ali cleaning a round carpet with a vacuum cleaner, smiling.',
        'do_pin': SCENE + 'Ali pinning a small T-shirt on a clothes line with a clothespin, smiling.',
        'do_basket': SCENE + 'Ali putting a dirty sock into a laundry basket, smiling.',
        'do_detergent': SCENE + 'Ali pouring a little blue detergent into the front of a washing machine, smiling.',
    },
    'wear': {
        **{f'wear_{slug}': ALI_TALL + text for slug, text in {
            'tshirt': 'Ali wearing a turquoise T-shirt with his blue shorts.',
            'trousers': 'Ali wearing long blue pants and his orange T-shirt.',
            'socks': 'Ali in his orange T-shirt and blue shorts, wearing yellow socks and no shoes.',
            'shoes': 'Ali in his orange T-shirt and blue shorts, wearing bright orange sneakers.',
            'hat': 'Ali in his usual clothes, wearing a sunny yellow hat.',
            'coat': 'Ali wearing a puffy blue winter coat over long pants.',
            'scarf': 'Ali in his usual clothes with a warm pink scarf around his neck.',
            'gloves': 'Ali in his usual clothes wearing warm turquoise gloves.',
            'beanie': 'Ali in his usual clothes wearing a warm blue knitted beanie.',
            'pajamas': 'Ali wearing soft lavender pajamas with small stars.',
            'raincoat': 'Ali wearing a bright yellow raincoat with a hood.',
            'sweater': 'Ali wearing a soft green sweater and long pants.',
            'boots': 'Ali in his usual clothes wearing tall green rain boots.',
            'vest': 'Ali wearing an orange vest over a white shirt and blue pants.',
            'tracksuit': 'Ali wearing a turquoise tracksuit, top and bottom.',
        }.items()},
    },
    'jobs': {
        **{f'job_{slug}': SCENE + text for slug, text in {
            'doctor': 'A friendly doctor listening to a seated child with a stethoscope.',
            'firefighter': 'A friendly firefighter spraying water with a red hose on small soft flames.',
            'cook': 'A friendly cook in a white hat ladling soup from a big pot.',
            'teacher': 'A friendly teacher writing with chalk on a green board with simple drawn shapes and no letters.',
            'police_officer': 'A friendly police officer blowing a whistle and directing two small cars.',
            'farmer': 'A friendly farmer driving a small green tractor on a field.',
            'postman': 'A friendly mail carrier handing a letter at a small garden gate.',
            'hairdresser': "A friendly hairdresser cutting a seated child's hair with scissors.",
            'dentist': "A friendly dentist looking into a seated child's open mouth with a small mirror.",
            'baker': 'A friendly baker sliding a loaf of bread into a brick oven with a long wooden peel.',
            'carpenter': 'A friendly carpenter hammering a nail into a small wooden stool.',
            'nurse': "A friendly nurse checking a seated child's temperature with a thermometer.",
        }.items()},
        **{f'help_{slug}': SCENE + text for slug, text in {
            'cat_tree': 'A friendly firefighter on a small ladder gently holding a cat that was stuck in a tree.',
            'fire': 'A friendly firefighter putting out the last small flames on a small house with a hose.',
            'fever': 'A friendly doctor gently checking Ali, who is sitting up in bed and smiling.',
            'toothache': 'A friendly dentist checking Ali, who is sitting in a dentist chair and smiling.',
            'lost': "A friendly police officer holding Ali's hand and walking him to Mom, everyone smiling.",
            'sick_dog': 'A friendly vet holding a happy puppy with a small bandage on its paw.',
            'broken_car': 'A friendly mechanic closing the bonnet of a small blue car, thumbs up.',
            'long_hair': 'A friendly hairdresser finishing a neat haircut on Ali, who is smiling at a mirror.',
            'dry_garden': 'A friendly gardener watering a small garden bed with fresh upright flowers.',
            'torn_shirt': 'A friendly tailor sewing a blue shirt with a needle and thread.',
        }.items()},
    },
    'nature': {
        'grow_0': SCENE + 'One round terracotta flower pot full of soft brown soil, centred, large.',
        'grow_1': SCENE + 'The same pot, same size and position, one seed lying in a small hollow in the soil.',
        'grow_2': SCENE + 'The same pot, same size and position, the soil is wet and a small green sprout with two leaves stands in it.',
        'grow_pink': SCENE + 'The same pot, same size and position, a tall green stem with one big pink flower.',
        'grow_yellow': SCENE + 'The same pot, same size and position, a tall green stem with one big yellow flower.',
        'grow_tulip': SCENE + 'The same pot, same size and position, a red tulip.',
        'grow_sunflower': SCENE + 'The same pot, same size and position, one big sunflower.',
        'grow_daisy': SCENE + 'The same pot, same size and position, one big white daisy.',
        'tree_bare': SCENE + 'One large tree with a brown trunk and bare branches on a soft patch of ground, centred, filling most of the picture.',
        'tree_winter': SCENE + 'The same tree, same size and position, with soft white snow on every branch and snow on the ground.',
        'tree_spring': SCENE + 'The same tree, same size and position, covered with pink blossoms.',
        'tree_autumn': SCENE + 'The same tree, same size and position, covered with yellow and orange leaves, a few fallen on the ground.',
        'tree_summer': SCENE + 'The same tree, same size and position, full of green leaves and red apples.',
    },
    'outside': {
        'out_rain': SCENE + 'Ali in a yellow raincoat walking happily outside in gentle rain, small puddle.',
        'out_umbrella': SCENE + 'Ali holding a big blue umbrella in gentle rain, staying dry, smiling.',
        'out_snow': SCENE + 'Ali in a puffy blue coat playing in soft snow next to a small snowman.',
        'out_gloves': SCENE + 'Ali in a coat and warm gloves holding a snowball, smiling.',
        'out_sun': SCENE + 'Ali in shorts and a T-shirt walking in a sunny park with one round tree.',
        'out_shades': SCENE + 'Ali wearing sunglasses on a sunny day, big smile.',
        'out_sea': SCENE + 'Ali in a swimsuit standing at the edge of calm blue sea on a beach, smiling.',
        'out_bed': SCENE + 'Ali in lavender pajamas tucked into a cosy bed, eyes closing, a soft moon through a window.',
        'bowl_empty': SCENE + 'One big empty cream-coloured bowl, seen slightly from above so its inside is clearly visible, centred on a soft table. The bowl fills most of the picture.',
        'bowl_mixed': SCENE + 'The same big bowl, same size and position, now full of a colourful mixed fruit salad with a spoon resting in it.',
        'table': SCENE + 'A simple round-cornered dining table seen from straight above, soft cream tablecloth, nothing on it, filling most of the picture.',
    },
}


def prompt(group):
    print('Use your image generation tool to make the pictures below, one image call per file, and save each as PNG at the exact path. '
          'Use the attached character sheet as the reference for Ali and Mom. Skip a file that already exists. Do not change any other file. '
          'If your image limit is reached, stop and say so plainly. When done, reply with the saved files.\n')
    print(STYLE + '\n')
    for i, (name, text) in enumerate(GROUPS[group].items(), 1):
        print(f'{i}. {SCENES / (name + ".png")}: {text}\n')


def install():
    out = ROOT / 'assets/images/play'
    out.mkdir(parents=True, exist_ok=True)
    count = 0
    for group in GROUPS.values():
        for name in group:
            src = SCENES / f'{name}.png'
            if not src.exists():
                continue
            im = Image.open(src).convert('RGBA')
            scale = 1200 / max(im.size)
            if scale < 1:
                im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
            im.save(out / f'{name}.webp', 'WEBP', quality=90, alpha_quality=100, method=6)
            count += 1
    print(count, 'pictures installed')


if __name__ == '__main__':
    if sys.argv[1] == 'prompt':
        prompt(sys.argv[2])
    else:
        install()
