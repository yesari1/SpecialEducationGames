"""Data for the Shapes, Feelings and Our Body games (Nov 2026).

Turkish is written natively; English separately. See source.py for the
Colors games and build_pair_games.py for how this becomes app data.
"""

# ---- Extra pictures used only inside games: id -> (path, tr, en) ----
EXTRA = {
    'props.ball': ('assets/images/props/ball.webp', 'Top', 'Ball'),
    'props.gift': ('assets/images/props/gift.webp', 'Hediye kutusu', 'Gift box'),
    'props.dice': ('assets/images/props/dice.webp', 'Zar', 'Dice'),
    'props.pizza_slice': ('assets/images/props/pizza_slice.webp', 'Pizza dilimi', 'Pizza slice'),
    'props.tent': ('assets/images/props/tent.webp', 'Çadır', 'Tent'),
    'props.sign_triangle': ('assets/images/props/sign_triangle.webp', 'Uyarı levhası', 'Warning sign'),
    'props.book': ('assets/images/props/book.webp', 'Kitap', 'Book'),
    'props.starfish': ('assets/images/props/starfish.webp', 'Deniz yıldızı', 'Starfish'),
    'props.heart_balloon': ('assets/images/props/heart_balloon.webp', 'Kalp balon', 'Heart balloon'),
    'props.egg': ('assets/images/props/egg.webp', 'Yumurta', 'Egg'),
    'paint.balloon': ('assets/images/paint/balloon.webp', 'Balon', 'Balloon'),
    'paint.flower': ('assets/images/paint/flower.webp', 'Çiçek', 'Flower'),
    'paint.car': ('assets/images/paint/car.webp', 'Araba', 'Car'),
    'paint.ball': ('assets/images/paint/ball.webp', 'Top', 'Ball'),
    'paint.apple': ('assets/images/paint/apple.webp', 'Elma', 'Apple'),
    'paint.fish': ('assets/images/paint/fish.webp', 'Balık', 'Fish'),
    'paint.butterfly': ('assets/images/paint/butterfly.webp', 'Kelebek', 'Butterfly'),
    'paint.house': ('assets/images/paint/house.webp', 'Ev', 'House'),
    'wear.gloves': ('assets/images/wear/gloves.webp', 'Eldiven', 'Gloves'),
    'wear.socks': ('assets/images/wear/socks.webp', 'Çorap', 'Socks'),
    'wear.shoes': ('assets/images/wear/shoes.webp', 'Ayakkabı', 'Shoes'),
    'wear.hat': ('assets/images/wear/hat.webp', 'Şapka', 'Hat'),
    'wear.glasses': ('assets/images/wear/glasses.webp', 'Gözlük', 'Glasses'),
    'wear.scarf': ('assets/images/wear/scarf.webp', 'Atkı', 'Scarf'),
    'wear.ring': ('assets/images/wear/ring.webp', 'Yüzük', 'Ring'),
    'wear.earmuffs': ('assets/images/wear/earmuffs.webp', 'Kulaklık', 'Earmuffs'),
    'scene.icecream_dropped': ('assets/images/scenes/icecream_dropped.jpg', 'Dondurma düştü', 'Dropped ice cream'),
    'scene.gift': ('assets/images/scenes/gift.jpg', 'Hediye', 'A present'),
    'scene.big_dog': ('assets/images/scenes/big_dog.jpg', 'Havlayan köpek', 'Barking dog'),
    'scene.surprise_box': ('assets/images/scenes/surprise_box.jpg', 'Sürpriz kutusu', 'Jack-in-the-box'),
    'scene.tower_knocked': ('assets/images/scenes/tower_knocked.jpg', 'Yıkılan kule', 'Knocked-down tower'),
    'scene.bedtime': ('assets/images/scenes/bedtime.jpg', 'Uyku vakti', 'Bedtime'),
    'scene.drawing_done': ('assets/images/scenes/drawing_done.jpg', 'Resim bitti', 'Finished drawing'),
    'scene.tickle': ('assets/images/scenes/tickle.jpg', 'Gıdıklama', 'Tickling'),
    'body.ali_full': ('assets/images/wear/ali_full.webp', 'Ali', 'Ali'),
}
FACE_EMOTIONS = ['happy', 'sad', 'angry', 'scared', 'surprised', 'sleepy']
FACE_NAMES = {'happy': ('Mutlu', 'Happy'), 'sad': ('Üzgün', 'Sad'), 'angry': ('Kızgın', 'Angry'),
              'scared': ('Korkmuş', 'Scared'), 'surprised': ('Şaşkın', 'Surprised'), 'sleepy': ('Uykulu', 'Sleepy')}
for _who in ('elif', 'mom'):
    for _e in FACE_EMOTIONS:
        EXTRA[f'faces.{_who}_{_e}'] = (f'assets/images/faces/{_who}_{_e}.webp', *FACE_NAMES[_e])

CORE = ['happy', 'sad', 'angry', 'scared', 'surprised', 'sleepy']

SHAPE_OBJECTS = {
    'circle': (['props.ball', 'home.clock', 'home.plate'], 'daireye', 'a circle'),
    'square': (['props.gift', 'props.dice'], 'kareye', 'a square'),
    'triangle': (['props.pizza_slice', 'props.tent', 'props.sign_triangle'], 'üçgene', 'a triangle'),
    'rectangle': (['props.book', 'home.door'], 'dikdörtgene', 'a rectangle'),
    'star': (['props.starfish'], 'yıldıza', 'a star'),
    'heart': (['props.heart_balloon'], 'kalbe', 'a heart'),
    'oval': (['props.egg'], 'ovale', 'an oval'),
}

SCENES = [
    ('scene.icecream_dropped', 'sad', "Ali'nin dondurması yere düştü. Ali ne hissediyor?", 'Ali dropped his ice cream. How does Ali feel?'),
    ('scene.gift', 'happy', 'Ali bir hediye aldı. Ali ne hissediyor?', 'Ali got a present. How does Ali feel?'),
    ('scene.big_dog', 'scared', 'Büyük bir köpek havladı. Ali ne hissediyor?', 'A big dog barked. How does Ali feel?'),
    ('scene.surprise_box', 'surprised', 'Kutudan birden bir oyuncak fırladı. Ali ne hissediyor?', 'A toy popped out of the box. How does Ali feel?'),
    ('scene.tower_knocked', 'angry', "Elif, Ali'nin kulesini yıktı. Ali ne hissediyor?", "Elif knocked down Ali's tower. How does Ali feel?"),
    ('scene.bedtime', 'sleepy', 'Akşam oldu, Ali esniyor. Ali ne hissediyor?', 'It is evening and Ali is yawning. How does Ali feel?'),
    ('scene.drawing_done', 'happy', 'Ali resmini bitirdi, annesi alkışlıyor. Ali ne hissediyor?', 'Ali finished his drawing and Mom claps. How does Ali feel?'),
    ('scene.tickle', 'happy', "Annesi Ali'yi gıdıklıyor. Ali ne hissediyor?", 'Mom is tickling Ali. How does Ali feel?'),
]

# sound file -> feeling
SOUNDS = {'laughing': 'happy', 'sad': 'sad', 'sleepy': 'sleepy', 'surprised': 'surprised',
          'scared': 'scared', 'angry': 'angry'}

FUNCTIONS = [
    ('body.eye', 'Neyle görürüz?', 'What do we see with?', []),
    ('body.ear', 'Neyle duyarız?', 'What do we hear with?', []),
    ('body.nose', 'Neyle koklarız?', 'What do we smell with?', []),
    ('body.mouth', 'Neyle konuşuruz?', 'What do we talk with?', ['body.tongue', 'body.teeth']),
    ('body.hand', 'Neyle tutarız?', 'What do we hold things with?', ['body.finger']),
    ('body.foot', 'Neyle yürürüz?', 'What do we walk with?', ['body.leg']),
    ('body.teeth', 'Neyle ısırırız?', 'What do we bite with?', ['body.mouth']),
    ('body.tongue', 'Neyle tat alırız?', 'What do we taste with?', ['body.mouth']),
]
FUNCTION_POOL = ['body.eye', 'body.ear', 'body.nose', 'body.mouth', 'body.hand', 'body.foot',
                 'body.teeth', 'body.tongue', 'body.leg', 'body.finger', 'body.hair', 'body.knee']

WEAR = [
    ('wear.gloves', 'body.hand', 'Eldiveni nereye giyeriz?', 'Where do we wear gloves?', ['body.finger']),
    ('wear.socks', 'body.foot', 'Çorabı nereye giyeriz?', 'Where do we wear socks?', []),
    ('wear.shoes', 'body.foot', 'Ayakkabıyı nereye giyeriz?', 'Where do we wear shoes?', []),
    ('wear.hat', 'body.head', 'Şapkayı nereye takarız?', 'Where do we wear a hat?', ['body.hair']),
    ('wear.glasses', 'body.eye', 'Gözlüğü nereye takarız?', 'Where do we wear glasses?', ['body.nose']),
    ('wear.scarf', 'body.neck', 'Atkıyı nereye takarız?', 'Where do we wear a scarf?', []),
    ('wear.ring', 'body.finger', 'Yüzüğü nereye takarız?', 'Where do we wear a ring?', ['body.hand']),
    ('wear.earmuffs', 'body.ear', 'Kulaklığı nereye takarız?', 'Where do we wear earmuffs?', []),
]
WEAR_POOL = ['body.hand', 'body.foot', 'body.head', 'body.eye', 'body.neck', 'body.finger', 'body.ear',
             'body.nose', 'body.mouth', 'body.tummy', 'body.knee', 'body.hair']

BODY_MAP_TR = {
    'hair': "Ali'nin saçı nerede?", 'eye': "Ali'nin gözü nerede?", 'ear': "Ali'nin kulağı nerede?",
    'nose': "Ali'nin burnu nerede?", 'mouth': "Ali'nin ağzı nerede?", 'neck': "Ali'nin boynu nerede?",
    'shoulder': "Ali'nin omzu nerede?", 'arm': "Ali'nin kolu nerede?", 'hand': "Ali'nin eli nerede?",
    'tummy': "Ali'nin karnı nerede?", 'leg': "Ali'nin bacağı nerede?", 'foot': "Ali'nin ayağı nerede?",
}
BODY_MAP_EN = {k: f"Where is Ali's {k}?" for k in BODY_MAP_TR}
# (part, x, y, r) as fractions of the picture (r of its width)
BODY_SPOTS = [
    ('hair', .50, .06, .12), ('eye', .40, .225, .06), ('eye', .66, .225, .06),
    ('ear', .18, .26, .07), ('ear', .81, .26, .07), ('nose', .53, .245, .045),
    ('mouth', .52, .285, .065), ('neck', .50, .36, .07), ('shoulder', .22, .42, .08),
    ('shoulder', .78, .42, .08), ('arm', .16, .53, .08), ('arm', .86, .53, .08),
    ('hand', .09, .65, .09), ('hand', .91, .65, .09), ('tummy', .50, .52, .12),
    ('leg', .35, .86, .08), ('leg', .65, .86, .08), ('foot', .32, .96, .1), ('foot', .68, .96, .1),
]


def games():
    out = {}
    out['G43'] = {
        'theme': 'shapes',
        'choicePool': sorted({o for objs, _, _ in SHAPE_OBJECTS.values() for o in objs}),
        'rounds': [
            {'stimulus': f'shapes.{shape}', 'target': obj, 'clip': shape,
             'text': {'tr': f'Hangisi {tr} benziyor?', 'en': f'Which one looks like {en}?'}}
            for shape, (objs, tr, en) in SHAPE_OBJECTS.items() for obj in objs
        ],
    }
    out['G44'] = {
        'theme': 'emotions',
        'look': 'scene',
        'choicePool': [f'emotions.{e}' for e in CORE],
        'rounds': [
            {'stimulus': s, 'target': f'emotions.{e}', 'text': {'tr': tr, 'en': en}}
            for s, e, tr, en in SCENES
        ],
    }
    out['G45'] = {
        'theme': 'emotions',
        'choicePool': [f'faces.{w}_{e}' for w in ('elif', 'mom') for e in FACE_EMOTIONS],
        'rounds': [
            {'stimulus': f'emotions.{e}', 'target': f'faces.{w}_{e}', 'clip': 'same',
             'text': {'tr': 'Kim de böyle hissediyor?', 'en': 'Who feels the same way?'}}
            for e in FACE_EMOTIONS for w in ('elif', 'mom')
        ],
    }
    out['G46'] = {
        'theme': 'emotions',
        'choicePool': [f'emotions.{e}' for e in CORE],
        'rounds': [
            {'sound': f'assets/sfx/feelings/{snd}.mp3', 'target': f'emotions.{e}', 'clip': 'listen',
             'text': {'tr': 'Dinle bakalım. Nasıl hissediyor?', 'en': 'Listen. How is this person feeling?'}}
            for snd, e in SOUNDS.items()
        ],
    }
    out['G48'] = {
        'theme': 'body',
        'choicePool': FUNCTION_POOL,
        'rounds': [
            {'target': t, 'alsoRight': also, 'text': {'tr': tr, 'en': en}}
            for t, tr, en, also in FUNCTIONS
        ],
    }
    out['G49'] = {
        'theme': 'body',
        'choicePool': WEAR_POOL,
        'rounds': [
            {'stimulus': s, 'target': t, 'alsoRight': also, 'text': {'tr': tr, 'en': en}}
            for s, t, tr, en, also in WEAR
        ],
    }
    return out


def clips():
    return {f'G47_{k}': {'tr': BODY_MAP_TR[k], 'en': BODY_MAP_EN[k]} for k in BODY_MAP_TR}


def extra_items():
    return [
        {'id': i, 'theme': 'extra', 'tier': 'easy', 'name': {'tr': tr, 'en': en},
         'images': [path], 'audio': {}, 'tags': []}
        for i, (path, tr, en) in EXTRA.items()
    ]


FACE_PARTS = {'hair', 'eye', 'ear', 'nose', 'mouth'}
FACE_CROP = 0.34  # assets/images/wear/ali_face.webp = top 34 % of ali_full.webp


def body_map():
    face = [{'item': f'body.{p}', 'x': x, 'y': y / FACE_CROP, 'r': r}
            for p, x, y, r in BODY_SPOTS if p in FACE_PARTS]
    body = [{'item': f'body.{p}', 'x': x, 'y': y, 'r': r}
            for p, x, y, r in BODY_SPOTS if p not in FACE_PARTS]
    return {
        'pictures': [
            {'picture': 'assets/images/wear/ali_face.webp', 'aspect': 656 / 476, 'spots': face},
            {'picture': EXTRA['body.ali_full'][0], 'aspect': 656 / 1400, 'spots': body},
        ],
        'questions': {f'body.{k}': {'tr': BODY_MAP_TR[k], 'en': BODY_MAP_EN[k]} for k in BODY_MAP_TR},
    }
