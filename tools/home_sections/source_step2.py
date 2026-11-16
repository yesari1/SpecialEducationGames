"""Temizlik, Kıyafetler, Mutfak: items, games and every spoken line.

Turkish lines are written the way Turks talk to a child, not translated from
the English next to them. Used by build_themes.py.
"""

PLAY = 'assets/images/play'

# --- Items -------------------------------------------------------------------
# (slug, tier, Turkish name, English name)
CLEANING = [
    ('toothbrush', 'easy', 'Diş fırçası', 'Toothbrush'),
    ('toothpaste', 'easy', 'Diş macunu', 'Toothpaste'),
    ('soap', 'easy', 'Sabun', 'Soap'),
    ('towel', 'easy', 'Havlu', 'Towel'),
    ('comb', 'easy', 'Tarak', 'Comb'),
    ('shampoo', 'easy', 'Şampuan', 'Shampoo'),
    ('tissue', 'easy', 'Kâğıt mendil', 'Tissue'),
    ('trash_bin', 'easy', 'Çöp kovası', 'Trash can'),
    ('tap', 'easy', 'Musluk', 'Tap'),
    ('bathtub', 'easy', 'Küvet', 'Bathtub'),
    ('hairbrush', 'medium', 'Saç fırçası', 'Hairbrush'),
    ('sponge', 'medium', 'Sünger', 'Sponge'),
    ('broom', 'medium', 'Süpürge', 'Broom'),
    ('dustpan', 'medium', 'Faraş', 'Dustpan'),
    ('mop', 'medium', 'Paspas', 'Mop'),
    ('bucket', 'medium', 'Kova', 'Bucket'),
    ('toilet_paper', 'medium', 'Tuvalet kâğıdı', 'Toilet paper'),
    ('washing_machine', 'medium', 'Çamaşır makinesi', 'Washing machine'),
    ('hair_dryer', 'medium', 'Saç kurutma makinesi', 'Hair dryer'),
    ('nail_clipper', 'medium', 'Tırnak makası', 'Nail clippers'),
    ('vacuum', 'hard', 'Elektrikli süpürge', 'Vacuum cleaner'),
    ('laundry_basket', 'hard', 'Çamaşır sepeti', 'Laundry basket'),
    ('clothespin', 'hard', 'Mandal', 'Clothespin'),
    ('drying_rack', 'hard', 'Çamaşırlık', 'Drying rack'),
    ('detergent', 'hard', 'Deterjan', 'Laundry detergent'),
    ('rubber_gloves', 'hard', 'Lastik eldiven', 'Rubber gloves'),
    ('bath_sponge', 'hard', 'Banyo lifi', 'Bath sponge'),
    ('shower', 'hard', 'Duş', 'Shower'),
]

KITCHEN = [
    ('plate', 'easy', 'Tabak', 'Plate'),
    ('fork', 'easy', 'Çatal', 'Fork'),
    ('spoon', 'easy', 'Kaşık', 'Spoon'),
    ('knife', 'easy', 'Bıçak', 'Knife'),
    ('glass', 'easy', 'Bardak', 'Glass'),
    ('bowl', 'easy', 'Kâse', 'Bowl'),
    ('pot', 'easy', 'Tencere', 'Pot'),
    ('pan', 'easy', 'Tava', 'Frying pan'),
    ('fridge', 'easy', 'Buzdolabı', 'Fridge'),
    ('oven', 'easy', 'Fırın', 'Oven'),
    ('cup', 'medium', 'Fincan', 'Cup'),
    ('mug', 'medium', 'Kupa', 'Mug'),
    ('teapot', 'medium', 'Çaydanlık', 'Teapot'),
    ('tray', 'medium', 'Tepsi', 'Tray'),
    ('cutting_board', 'medium', 'Kesme tahtası', 'Cutting board'),
    ('ladle', 'medium', 'Kepçe', 'Ladle'),
    ('jug', 'medium', 'Sürahi', 'Jug'),
    ('cupboard', 'medium', 'Dolap', 'Cupboard'),
    ('dishwasher', 'medium', 'Bulaşık makinesi', 'Dishwasher'),
    ('napkin', 'medium', 'Peçete', 'Napkin'),
    ('grater', 'hard', 'Rende', 'Grater'),
    ('rolling_pin', 'hard', 'Oklava', 'Rolling pin'),
    ('strainer', 'hard', 'Süzgeç', 'Strainer'),
    ('whisk', 'hard', 'Çırpma teli', 'Whisk'),
    ('spatula', 'hard', 'Spatula', 'Spatula'),
    ('blender', 'hard', 'Blender', 'Blender'),
    ('toaster', 'hard', 'Tost makinesi', 'Toaster'),
    ('oven_mitt', 'hard', 'Fırın eldiveni', 'Oven mitt'),
    ('salt_shaker', 'hard', 'Tuzluk', 'Salt shaker'),
]

# The closed theme's items that get a picture and open up (28).
CLOTHES_OPEN = [
    'tshirt', 'trousers', 'shoes', 'socks', 'hat', 'coat', 'dress', 'skirt', 'shorts', 'pajamas',
    'sweater', 'slippers', 'shirt', 'gloves', 'scarf', 'beanie', 'boots', 'sandals', 'swimsuit', 'raincoat',
    'cardigan', 'tracksuit', 'sneakers', 'sunglasses', 'umbrella', 'bag', 'vest', 'jacket',
]
# English names that read badly in the old list.
CLOTHES_EN = {'tshirt': 'T-shirt', 'trousers': 'Pants', 'coat': 'Coat', 'bag': 'Bag', 'beanie': 'Beanie'}

# Extra pictures used only inside games (id, Turkish, English).
EXTRA = [
    ('fruit.apple', 'Elma', 'Apple'), ('fruit.banana', 'Muz', 'Banana'),
    ('fruit.strawberry', 'Çilek', 'Strawberry'), ('fruit.orange', 'Portakal', 'Orange'),
    ('fruit.grape', 'Üzüm', 'Grapes'), ('fruit.kiwi', 'Kivi', 'Kiwi'),
    ('fruit.peach', 'Şeftali', 'Peach'), ('fruit.pear', 'Armut', 'Pear'),
    ('put.milk', 'Süt', 'Milk'), ('put.cheese', 'Peynir', 'Cheese'), ('put.eggs', 'Yumurta', 'Eggs'),
    ('put.dirty_plate', 'Kirli tabak', 'Dirty plate'), ('put.clean_plate', 'Temiz tabak', 'Clean plate'),
    ('put.clean_glass', 'Temiz bardak', 'Clean glass'), ('put.dirty_fork', 'Kirli çatal', 'Dirty fork'),
    ('put.peel', 'Muz kabuğu', 'Banana peel'), ('put.empty_box', 'Boş kutu', 'Empty box'),
    ('put.cake_dough', 'Kek hamuru', 'Cake batter'), ('put.yogurt', 'Yoğurt', 'Yogurt'),
    ('wash.foam', 'Köpük', 'Foam'), ('wash.water', 'Su', 'Water'),
    ('stir.spoon', 'Kaşık', 'Spoon'),
]

# --- Games -------------------------------------------------------------------
GAMES = [
    ('G60', 'scene', 'Dişlerini Fırçala', 'Brush the Teeth'),
    ('G61', 'scene', 'Ellerini Yıka', 'Wash the Hands'),
    ('G62', 'pair', 'Ne Lazım?', 'What Do We Need?'),
    ('G63', 'scene', 'Giydirelim', "Let's Get Dressed"),
    ('G64', 'pair', 'Bugün Ne Giysek?', 'What Shall We Wear?'),
    ('G65', 'scene', 'Meyve Salatası Yapalım', 'Make a Fruit Salad'),
    ('G66', 'scene', 'Sofrayı Kuralım', 'Set the Table'),
    ('G67', 'pair', 'Nereye Koyalım?', 'Where Does It Go?'),
]
THEME_GAMES = {
    'cleaning': ['G02', 'G60', 'G61', 'G62'],
    'clothes': ['G02', 'G63', 'G64', 'G49'],
    'kitchen': ['G02', 'G65', 'G66', 'G67'],
}
FREE = ['cleaning_G02', 'cleaning_G60', 'cleaning_G61', 'clothes_G02', 'clothes_G63', 'clothes_G64',
        'kitchen_G02', 'kitchen_G65', 'kitchen_G66']
THEMES_NEW = [
    {'id': 'cleaning', 'name': {'tr': 'Temizlik', 'en': 'Keeping Clean'}, 'hero': 'cleaning.soap',
     'palette': {'bg': '#EFF8FB', 'accent': '#4FB6D6', 'deep': '#2B8BA9'}},
    {'id': 'kitchen', 'name': {'tr': 'Mutfak', 'en': 'Kitchen'}, 'hero': 'kitchen.pot',
     'palette': {'bg': '#FDF3E7', 'accent': '#E8934A', 'deep': '#BD6A25'}},
]
CLOTHES_THEME = {'name': {'tr': 'Kıyafetler', 'en': 'Clothes'}, 'hero': 'clothes.tshirt'}

LINES = {}


def line(key, tr, en):
    path = f'assets/audio/{{lang}}/scenes/{key}.mp3'
    LINES[path] = {'tr': tr, 'en': en}
    return {lang: path.replace('{lang}', lang) for lang in ('tr', 'en')}


def text(tr, en):
    return {'tr': tr, 'en': en}


# G60 Dişlerini Fırçala -------------------------------------------------------
import random  # noqa: E402

# The teeth of teeth_dirty.webp, measured on the picture (left, top, right,
# bottom in its 1200x800 pixels). A stain never leaves its tooth.
_TEETH_PX = [
    (529, 476, 565, 514), (566, 480, 606, 518), (607, 480, 646, 518), (647, 476, 682, 513),  # upper
    (535, 555, 567, 588), (569, 561, 606, 596), (607, 561, 643, 596), (645, 555, 676, 588),  # lower
]
TEETH = [[round(l / 1200, 4), round(t / 800, 4), round((r - l) / 1200, 4), round((b - t) / 800, 4)] for l, t, r, b in _TEETH_PX]
TEETH_ZONE = [.44, .59, .13, .16]


def teeth_spots(n, seed):
    return random.Random(seed).sample(TEETH, n)


def g60():
    ask = line('g60_ask', "Ali'nin dişleri kirlenmiş. Hadi fırçalayalım!", "Ali's teeth need a clean. Let's brush them!")
    done = line('g60_done', 'Dişlerin pırıl pırıl oldu, Ali!', 'Your teeth are sparkling, Ali!')
    rounds = []
    for tier, n in (('easy', 3), ('medium', 4), ('hard', 6)):
        for i in range(5):
            rounds.append({
                'key': f'{tier}{i}', 'tier': tier, 'target': 'cleaning.toothbrush',
                'stage': f'{PLAY}/teeth_dirty.webp', 'aspect': 1.5,
                'tints': TEETH, 'text': text("Ali'nin dişlerini fırçalayalım.", "Let's brush Ali's teeth."), 'audio': ask,
                'steps': [{'mode': 'rub', 'piece': 'cleaning.toothbrush', 'zone': TEETH_ZONE,
                           'spots': teeth_spots(n, f'{tier}{i}'), 'after': f'{PLAY}/teeth_clean.webp',
                           'doneAudio': done}],
            })
    return {'theme': 'cleaning', 'rounds': rounds}


# G61 Ellerini Yıka -----------------------------------------------------------
WASH = {
    'tap': ('cleaning.tap', 'wash_water.webp', 'Önce musluğu açalım.', "First let's turn on the tap.", 'Su akıyor!', 'The water is on!'),
    'soap': ('cleaning.soap', 'wash_soap.webp', 'Şimdi sabunlayalım.', "Now let's use the soap.", 'Ellerimiz sabunlandı.', 'Soapy hands!'),
    'foam': ('wash.foam', 'wash_foam.webp', 'Ellerimizi iyice ovalım.', "Let's rub our hands well.", 'Bak, ne çok köpük!', 'Look at all that foam!'),
    'rinse': ('wash.water', 'wash_rinse.webp', 'Şimdi durulayalım.', "Now let's rinse.", 'Köpükler gitti.', 'The foam is gone.'),
    'dry': ('cleaning.towel', 'wash_dry.webp', 'Havluyla kurulayalım.', "Let's dry with the towel.", 'Ellerimiz tertemiz oldu!', 'Our hands are all clean!'),
}
WASH_ZONE = [.3, .25, .4, .5]
WASH_OTHERS = ['cleaning.comb', 'cleaning.toothbrush', 'cleaning.hairbrush', 'cleaning.bucket', 'kitchen.spoon', 'cleaning.broom']


def g61():
    first = {k: line(f'g61_first_{k}', f"Ellerini yıkayalım. {v[2]}", f"Let's wash the hands. {v[3]}") for k, v in WASH.items()}
    def steps(names, seed):
        rnd = random.Random(seed)
        out = []
        count = {'easy': 1, 'medium': 2, 'hard': 3}[seed.split('_')[0]]
        for name in names:
            piece, after, ask_tr, ask_en, done_tr, done_en = WASH[name]
            out.append({
                'mode': 'place', 'piece': piece, 'others': rnd.sample(WASH_OTHERS, count), 'zone': WASH_ZONE,
                'after': f'{PLAY}/{after}',
                'askAudio': line(f'g61_ask_{name}', ask_tr, ask_en), 'askText': text(ask_tr, ask_en),
                'doneAudio': line(f'g61_done_{name}', done_tr, done_en),
            })
        return out
    plans = {
        'easy': (['rinse', 'dry'], 'wash_soap.webp'),
        'medium': (['tap', 'soap', 'rinse', 'dry'], 'wash_dirty.webp'),
        'hard': (['tap', 'soap', 'foam', 'rinse', 'dry'], 'wash_dirty.webp'),
    }
    rounds = []
    for tier, (names, stage) in plans.items():
        for i in range(3):
            v = WASH[names[0]]
            rounds.append({
                'key': f'{tier}{i}', 'tier': tier, 'target': 'cleaning.soap',
                'stage': f'{PLAY}/{stage}', 'aspect': 1.5,
                'text': text(f'Ellerini yıkayalım. {v[2]}', f"Let's wash the hands. {v[3]}"),
                'audio': first[names[0]], 'steps': steps(names, f'{tier}_{i}'),
            })
    return {'theme': 'cleaning', 'rounds': rounds}


# G62 Ne Lazım? ---------------------------------------------------------------
G62 = [
    ('cleaning.comb', 'Saçını taramak için ne lazım?', 'What do we need to comb our hair?', 'Ali saçını tarıyor.', 'Ali is combing his hair.', 'do_comb'),
    ('cleaning.toothbrush', 'Dişini fırçalamak için ne lazım?', 'What do we need to brush our teeth?', 'Ali dişini fırçalıyor.', 'Ali is brushing his teeth.', 'do_brush'),
    ('cleaning.soap', 'Ellerini yıkamak için ne lazım?', 'What do we need to wash our hands?', 'Ali ellerini sabunluyor.', 'Ali is soaping his hands.', 'do_soap'),
    ('cleaning.towel', 'Elini yüzünü kurulamak için ne lazım?', 'What do we need to dry our face?', 'Ali yüzünü kuruluyor.', 'Ali is drying his face.', 'do_towel'),
    ('cleaning.shampoo', 'Saçını yıkamak için ne lazım?', 'What do we need to wash our hair?', 'Ali saçını yıkıyor.', 'Ali is washing his hair.', 'do_shampoo'),
    ('cleaning.tissue', 'Burnunu silmek için ne lazım?', 'What do we need to wipe our nose?', 'Ali burnunu siliyor.', 'Ali is wiping his nose.', 'do_tissue'),
    ('cleaning.trash_bin', 'Çöpü nereye atarız?', 'Where do we throw the rubbish?', 'Ali çöpü attı.', 'Ali threw the rubbish away.', 'do_bin'),
    ('cleaning.broom', 'Yeri süpürmek için ne lazım?', 'What do we need to sweep the floor?', 'Ali yeri süpürüyor.', 'Ali is sweeping the floor.', 'do_broom'),
    ('cleaning.sponge', 'Bulaşık yıkamak için ne lazım?', 'What do we need to wash the dishes?', 'Ali bulaşık yıkıyor.', 'Ali is washing the dishes.', 'do_sponge'),
    ('cleaning.mop', 'Yeri silmek için ne lazım?', 'What do we need to mop the floor?', 'Ali yeri siliyor.', 'Ali is mopping the floor.', 'do_mop'),
    ('cleaning.hair_dryer', 'Saçını kurutmak için ne lazım?', 'What do we need to dry our hair?', 'Ali saçını kurutuyor.', 'Ali is drying his hair.', 'do_dryer'),
    ('cleaning.nail_clipper', 'Tırnaklarını kesmek için ne lazım?', 'What do we need to cut our nails?', 'Annesi Ali\'nin tırnaklarını kesiyor.', 'Mom is cutting Ali\'s nails.', 'do_nails'),
    ('cleaning.vacuum', 'Halıyı süpürmek için ne lazım?', 'What do we need to clean the carpet?', 'Ali halıyı süpürüyor.', 'Ali is vacuuming the carpet.', 'do_vacuum'),
    ('cleaning.clothespin', 'Çamaşırları asmak için ne lazım?', 'What do we need to hang up the washing?', 'Ali çamaşırları asıyor.', 'Ali is hanging up the washing.', 'do_pin'),
    ('cleaning.laundry_basket', 'Kirli çamaşırları nereye koyarız?', 'Where do we put dirty clothes?', 'Ali çamaşırları sepete koydu.', 'Ali put the clothes in the basket.', 'do_basket'),
    ('cleaning.detergent', 'Çamaşır yıkarken içine ne koyarız?', 'What do we add when we wash clothes?', 'Ali deterjanı koyuyor.', 'Ali is adding the detergent.', 'do_detergent'),
]


def g62():
    rounds = []
    also = {'cleaning.comb': ['cleaning.hairbrush'], 'cleaning.broom': ['cleaning.vacuum'], 'cleaning.vacuum': ['cleaning.broom'],
            'cleaning.tissue': ['cleaning.toilet_paper', 'cleaning.towel'], 'cleaning.towel': ['cleaning.tissue'],
            'cleaning.laundry_basket': ['cleaning.washing_machine'], 'cleaning.soap': ['cleaning.shampoo', 'cleaning.sponge'],
            'cleaning.mop': ['cleaning.sponge', 'cleaning.bucket'], 'cleaning.sponge': ['cleaning.rubber_gloves']}
    for i, (target, q_tr, q_en, r_tr, r_en, picture) in enumerate(G62, 1):
        rounds.append({
            'target': target, 'alsoRight': also.get(target, []), 'text': text(q_tr, q_en), 'audio': line(f'g62_{i}', q_tr, q_en),
            'result': f'{PLAY}/{picture}.webp', 'resultAudio': line(f'g62_done_{i}', r_tr, r_en),
        })
    return {'theme': 'cleaning', 'rounds': rounds}


# G63 Giydirelim --------------------------------------------------------------
# Two children, by the profile: Ali (a boy) and Ayşe (a girl); in English Leo
# and Mia. Each round is one outfit (kombin), put on piece by piece, and the
# piece in the tray is the very garment the child ends up wearing: both are
# drawn from the same picture (artifacts/fix-nov12/wear_runner.py).
WHO = {'boy': ('Ali', 'Leo'), 'girl': ('Ayşe', 'Mia')}

# slug: (kind, Turkish name, English name, "…giydirelim", "the …", place on the picture)
_HEAD, _TOP, _LEGS, _FEET = [.18, .0, .64, .2], [.2, .36, .6, .27], [.26, .6, .48, .3], [.2, .86, .6, .14]
GARMENTS = {
    'tshirt': ('top', 'Tişört', 'T-shirt', 'tişörtünü giydirelim', 'the T-shirt', _TOP),
    'shorts': ('legs', 'Şort', 'Shorts', 'şortunu giydirelim', 'the shorts', _LEGS),
    'socks': ('socks', 'Çorap', 'Socks', 'çoraplarını giydirelim', 'the socks', _FEET),
    'sneakers': ('feet', 'Spor ayakkabı', 'Sneakers', 'ayakkabılarını giydirelim', 'the sneakers', _FEET),
    'shoes': ('feet', 'Ayakkabı', 'Shoes', 'ayakkabılarını giydirelim', 'the shoes', _FEET),
    'trainers': ('feet', 'Spor ayakkabı', 'Trainers', 'spor ayakkabılarını giydirelim', 'the trainers', _FEET),
    'hat': ('head', 'Şapka', 'Hat', 'şapkasını takalım', 'the hat', _HEAD),
    'cap': ('head', 'Şapka', 'Cap', 'şapkasını takalım', 'the cap', _HEAD),
    'beanie': ('head', 'Bere', 'Beanie', 'beresini takalım', 'the beanie', _HEAD),
    'sweater': ('top', 'Kazak', 'Sweater', 'kazağını giydirelim', 'the sweater', _TOP),
    'trousers': ('legs', 'Pantolon', 'Pants', 'pantolonunu giydirelim', 'the pants', _LEGS),
    'coat': ('over', 'Mont', 'Coat', 'montunu giydirelim', 'the coat', _TOP),
    'boots': ('feet', 'Bot', 'Boots', 'botlarını giydirelim', 'the boots', _FEET),
    'raincoat': ('over', 'Yağmurluk', 'Raincoat', 'yağmurluğunu giydirelim', 'the raincoat', _TOP),
    'rainboots': ('feet', 'Çizme', 'Rain boots', 'çizmelerini giydirelim', 'the rain boots', _FEET),
    'pajamatop': ('top', 'Pijama üstü', 'Pajama top', 'pijamasının üstünü giydirelim', 'the pajama top', _TOP),
    'pajamabottoms': ('legs', 'Pijama altı', 'Pajama bottoms', 'pijamasının altını giydirelim', 'the pajama bottoms', _LEGS),
    'slippers': ('feet', 'Terlik', 'Slippers', 'terliklerini giydirelim', 'the slippers', _FEET),
    'tracktop': ('top', 'Eşofman üstü', 'Tracksuit top', 'eşofmanının üstünü giydirelim', 'the tracksuit top', _TOP),
    'trackbottoms': ('legs', 'Eşofman altı', 'Tracksuit bottoms', 'eşofmanının altını giydirelim', 'the tracksuit bottoms', _LEGS),
    'dress': ('top', 'Elbise', 'Dress', 'elbisesini giydirelim', 'the dress', [.2, .36, .6, .4]),
    'skirt': ('legs', 'Etek', 'Skirt', 'eteğini giydirelim', 'the skirt', _LEGS),
}
# outfit: (how the round starts, how it ends), {N} is the child's name.
OUTFIT_LINES = {
    'park': (('{N} parka gidiyor.', '{N} is going to the park.'), ('{N} hazır. Haydi parka!', '{N} is ready. Off to the park!')),
    'skirt': (('{N} arkadaşına gidiyor.', '{N} is going to see a friend.'), ('{N} çok şık oldu!', '{N} looks lovely!')),
    'winter': (('Dışarıda kar yağıyor. {N} üşümesin.', "It's snowing outside. Let's keep {N} warm."), ('{N} sıcacık oldu. Karda oynayabilir!', '{N} is nice and warm. Time to play in the snow!')),
    'rain': (('Yağmur yağıyor. {N} ıslanmasın.', "It's raining. Let's keep {N} dry."), ('{N} artık ıslanmaz!', '{N} will stay dry now!')),
    'sleep': (('Uyku vakti geldi.', "It's bedtime."), ('İyi uykular, {N}!', 'Sleep well, {N}!')),
    'sport': (('{N} spor yapacak.', '{N} is going to play sports.'), ('{N} spora hazır!', '{N} is ready for sports!')),
}
OUTFITS = {
    'boy': {
        'park': ['tshirt', 'shorts', 'socks', 'sneakers', 'hat'],
        'winter': ['sweater', 'trousers', 'coat', 'boots', 'beanie'],
        'rain': ['trousers', 'raincoat', 'rainboots'],
        'sleep': ['pajamatop', 'pajamabottoms', 'slippers'],
        'sport': ['tracktop', 'trackbottoms', 'trainers', 'cap'],
    },
    'girl': {
        'park': ['dress', 'socks', 'shoes', 'hat'],
        'skirt': ['tshirt', 'skirt', 'socks', 'sneakers'],
        'winter': ['sweater', 'trousers', 'coat', 'boots', 'beanie'],
        'rain': ['trousers', 'raincoat', 'rainboots'],
        'sleep': ['pajamatop', 'pajamabottoms', 'slippers'],
    },
}
G63_EXTRAS = {'easy': 0, 'medium': 2, 'hard': 3}


def outfit_piece(who, outfit, slug):
    return f'outfit.{who}_{outfit}_{slug}'


EXTRA += [(outfit_piece(who, outfit, slug), GARMENTS[slug][1], GARMENTS[slug][2])
          for who, outfits in OUTFITS.items() for outfit, slugs in outfits.items() for slug in slugs]
# The children themselves, for the game's card.
EXTRA += [('wear.boy', 'Ali', 'Leo'), ('wear.girl', 'Ayşe', 'Mia')]


def g63():
    rnd = random.Random(63)
    asks = {slug: line(f'g63_ask_{slug}', f'Şimdi {g[3]}.', f'Now {g[4]}.') for slug, g in GARMENTS.items()}
    rounds = []
    for who, outfits in OUTFITS.items():
        tr_name, en_name = WHO[who]
        for outfit, slugs in outfits.items():
            (start_tr, start_en), (end_tr, end_en) = OUTFIT_LINES[outfit]
            first = GARMENTS[slugs[0]]
            q_tr = f'{start_tr.replace("{N}", tr_name)} Önce {first[3]}.'
            q_en = f'{start_en.replace("{N}", en_name)} First, {first[4]}.'
            audio = line(f'g63_first_{who}_{outfit}', q_tr, q_en)
            done = line(f'g63_done_{who}_{outfit}', end_tr.replace('{N}', tr_name), end_en.replace('{N}', en_name))
            steps = []
            for n, slug in enumerate(slugs, 1):
                g = GARMENTS[slug]
                steps.append({'mode': 'place', 'piece': outfit_piece(who, outfit, slug), 'zone': g[5],
                              'after': f'assets/images/wear/{who}_{outfit}_{n}.webp', 'askAudio': asks[slug],
                              'askText': text(f'Şimdi {g[3]}.', f'Now {g[4]}.')})
            steps[-1]['doneAudio'] = done
            # Pieces of the child's other outfits that cannot be mixed up with
            # one of this outfit by name or by where they go.
            kinds = {GARMENTS[s][0] for s in slugs}
            names = {GARMENTS[s][1] for s in slugs}
            others = sorted({(o, s) for o, ss in outfits.items() if o != outfit for s in ss
                             if GARMENTS[s][1] not in names and not (GARMENTS[s][0] in ('head', 'feet', 'socks') and GARMENTS[s][0] in kinds)})
            for tier, count in G63_EXTRAS.items():
                extras = rnd.sample(others, min(count, len(others)))
                rounds.append({
                    'key': f'{who}_{outfit}', 'tier': tier, 'who': who, 'target': 'clothes.tshirt',
                    'stage': f'assets/images/wear/{who}_base.webp', 'aspect': 2 / 3, 'gentle': True,
                    'extras': [outfit_piece(who, o, s) for o, s in extras],
                    'text': text(q_tr, q_en), 'audio': audio, 'steps': steps,
                })
    return {'theme': 'clothes', 'rounds': rounds}


# G64 Bugün Ne Giysek? --------------------------------------------------------
# (weather picture, target, also right, question, answer sentence, result picture); {N} is the child's name.
G64 = {
    'boy': [
        ('rain', 'raincoat', ['umbrella', 'boots'], 'Dışarıda yağmur yağıyor. {N} ne giysin?', "It's raining outside. What should {N} wear?", 'Yağmurluğunu giydi, dışarı çıkıyor.', 'He put on his raincoat and off he goes.', 'out_rain'),
        ('rain', 'umbrella', ['raincoat', 'boots'], 'Yağmur başladı. {N} yanına ne alsın?', 'It started to rain. What should {N} take?', 'Şemsiyesini aldı, hiç ıslanmıyor.', 'He took his umbrella and stays dry.', 'out_umbrella'),
        ('snow', 'coat', ['beanie', 'gloves', 'scarf', 'boots', 'sweater'], 'Dışarıda kar yağıyor. {N} ne giysin?', "It's snowing outside. What should {N} wear?", 'Montunu giydi, karda oynuyor.', 'He put on his coat and plays in the snow.', 'out_snow'),
        ('snow', 'gloves', ['coat', 'beanie', 'scarf', 'boots', 'sweater'], '{N} kartopu oynayacak. Eline ne taksın?', '{N} wants to make snowballs. What goes on his hands?', 'Eldivenlerini taktı, kartopu yapıyor.', 'He put on his gloves and makes snowballs.', 'out_gloves'),
        ('sun', 'shorts', ['tshirt', 'sandals', 'hat', 'sunglasses'], 'Hava çok sıcak. {N} ne giysin?', "It's very hot. What should {N} wear?", 'Şortunu giydi, parka gidiyor.', 'He put on his shorts and goes to the park.', 'out_sun'),
        ('sun', 'sunglasses', ['hat', 'shorts', 'tshirt', 'sandals'], 'Güneş gözünü alıyor. {N} ne taksın?', 'The sun is in his eyes. What should {N} put on?', 'Güneş gözlüğünü taktı, çok havalı oldu.', 'He put on his sunglasses and looks so cool.', 'out_shades'),
        ('sea', 'shorts', ['hat', 'sunglasses', 'sandals'], '{N} denize gidiyor. Ne giysin?', '{N} is going to the sea. What should he wear?', 'Şortunu giydi, denize giriyor.', 'He put on his swim shorts and jumps in.', 'out_sea'),
        ('night', 'pajamas', ['slippers'], 'Hava karardı, uyku vakti. {N} ne giysin?', "It's dark, time for bed. What should {N} wear?", 'Pijamasını giydi, yatağına girdi.', 'He put on his pajamas and got into bed.', 'out_bed'),
    ],
    'girl': [
        ('rain', 'raincoat', ['umbrella', 'boots'], 'Dışarıda yağmur yağıyor. {N} ne giysin?', "It's raining outside. What should {N} wear?", 'Yağmurluğunu giydi, dışarı çıkıyor.', 'She put on her raincoat and off she goes.', 'out_rain_girl'),
        ('rain', 'umbrella', ['raincoat', 'boots'], 'Yağmur başladı. {N} yanına ne alsın?', 'It started to rain. What should {N} take?', 'Şemsiyesini aldı, hiç ıslanmıyor.', 'She took her umbrella and stays dry.', 'out_umbrella_girl'),
        ('snow', 'coat', ['beanie', 'gloves', 'scarf', 'boots', 'sweater'], 'Dışarıda kar yağıyor. {N} ne giysin?', "It's snowing outside. What should {N} wear?", 'Montunu giydi, karda oynuyor.', 'She put on her coat and plays in the snow.', 'out_snow_girl'),
        ('snow', 'gloves', ['coat', 'beanie', 'scarf', 'boots', 'sweater'], '{N} kartopu oynayacak. Eline ne taksın?', '{N} wants to make snowballs. What goes on her hands?', 'Eldivenlerini taktı, kartopu yapıyor.', 'She put on her gloves and makes snowballs.', 'out_gloves_girl'),
        ('sun', 'dress', ['shorts', 'skirt', 'tshirt', 'sandals', 'hat', 'sunglasses', 'swimsuit'], 'Hava çok sıcak. {N} ne giysin?', "It's very hot. What should {N} wear?", 'Elbisesini giydi, parka gidiyor.', 'She put on her dress and goes to the park.', 'out_sun_girl'),
        ('sun', 'sunglasses', ['hat', 'shorts', 'tshirt', 'sandals', 'dress', 'skirt'], 'Güneş gözünü alıyor. {N} ne taksın?', 'The sun is in her eyes. What should {N} put on?', 'Güneş gözlüğünü taktı, çok havalı oldu.', 'She put on her sunglasses and looks so cool.', 'out_shades_girl'),
        ('sea', 'swimsuit', ['hat', 'sunglasses', 'sandals', 'shorts'], '{N} denize gidiyor. Ne giysin?', '{N} is going to the sea. What should she wear?', 'Mayosunu giydi, denize giriyor.', 'She put on her swimsuit and jumps in.', 'out_sea_girl'),
        ('night', 'pajamas', ['slippers'], 'Hava karardı, uyku vakti. {N} ne giysin?', "It's dark, time for bed. What should {N} wear?", 'Pijamasını giydi, yatağına girdi.', 'She put on her pajamas and got into bed.', 'out_bed_girl'),
    ],
}
# Never offered to the boy, not even as a wrong card.
G64_AVOID = {'boy': ['dress', 'skirt', 'swimsuit'], 'girl': []}
G64_ALL = sorted({x[1] for rows in G64.values() for x in rows} | {o for rows in G64.values() for x in rows for o in x[2]} | {'dress', 'skirt', 'sneakers'})


def g64():
    rounds = []
    for who, rows in G64.items():
        tr_name, en_name = WHO[who]
        tag = '' if who == 'boy' else f'{who}_'
        for i, (weather, target, also, q_tr, q_en, r_tr, r_en, picture) in enumerate(rows, 1):
            q_tr, q_en = q_tr.replace('{N}', tr_name), q_en.replace('{N}', en_name)
            rounds.append({
                'who': who, 'target': f'clothes.{target}', 'stimulus': f'weather.{weather}',
                'alsoRight': [f'clothes.{a}' for a in also], 'avoid': [f'clothes.{a}' for a in G64_AVOID[who]],
                'text': text(q_tr, q_en), 'audio': line(f'g64_{tag}{i}', q_tr, q_en),
                'result': f'{PLAY}/{picture}.webp', 'resultAudio': line(f'g64_done_{tag}{i}', r_tr, r_en),
            })
    return {'theme': 'clothes', 'look': 'scene', 'choicePool': [f'clothes.{c}' for c in G64_ALL], 'rounds': rounds}


WEATHER_EXTRA = [('weather.rain', 'Yağmur', 'Rain'), ('weather.snow', 'Kar', 'Snow'), ('weather.sun', 'Güneş', 'Sun'),
                 ('weather.sea', 'Deniz', 'Sea'), ('weather.night', 'Gece', 'Night')]


# G65 Meyve Salatası ----------------------------------------------------------
FRUIT_TR = {'apple': ('elmayı', 'elma'), 'banana': ('muzu', 'muz'), 'strawberry': ('çileği', 'çilek'), 'orange': ('portakalı', 'portakal'),
            'grape': ('üzümü', 'üzüm'), 'kiwi': ('kiviyi', 'kivi'), 'peach': ('şeftaliyi', 'şeftali'), 'pear': ('armudu', 'armut')}
FRUIT_EN = {'apple': 'apple', 'banana': 'banana', 'strawberry': 'strawberry', 'orange': 'orange',
            'grape': 'grapes', 'kiwi': 'kiwi', 'peach': 'peach', 'pear': 'pear'}
# Inside the bowl of bowl_empty.webp: two at the back, then the front ones;
# bowl_front.webp (the bowl's near wall) is drawn over them, so each fruit
# sits in the bowl and not on it.
BOWL_SLOTS = [[.25, .19, .24, .36], [.5, .19, .24, .36], [.14, .29, .24, .36], [.61, .29, .24, .36], [.375, .32, .24, .36]]
SALADS = {
    'easy': [['apple', 'banana'], ['strawberry', 'orange'], ['grape', 'pear'], ['kiwi', 'peach'], ['banana', 'strawberry']],
    'medium': [['apple', 'banana', 'orange'], ['strawberry', 'kiwi', 'pear'], ['grape', 'peach', 'apple'], ['orange', 'strawberry', 'banana'], ['pear', 'grape', 'kiwi']],
    'hard': [['apple', 'banana', 'strawberry', 'orange'], ['grape', 'kiwi', 'peach', 'pear'], ['orange', 'apple', 'grape', 'kiwi', 'banana'], ['strawberry', 'pear', 'peach', 'apple', 'grape'], ['banana', 'kiwi', 'orange', 'pear', 'strawberry']],
}


def g65():
    first = {f: line(f'g65_first_{f}', f'Meyve salatası yapalım. Önce {FRUIT_TR[f][0]} koyalım.', f"Let's make a fruit salad. First, the {FRUIT_EN[f]}.") for f in FRUIT_TR}
    asks = {f: line(f'g65_ask_{f}', f'Şimdi de {FRUIT_TR[f][0]} koyalım.', f'Now the {FRUIT_EN[f]}.') for f in FRUIT_TR}
    stir_ask_tr, stir_ask_en = 'Hadi, kaşıkla karıştıralım.', "Now let's stir with the spoon."
    stir_ask = line('g65_stir', stir_ask_tr, stir_ask_en)
    done = line('g65_done', 'Meyve salatası hazır. Afiyet olsun!', 'The fruit salad is ready. Enjoy!')
    rounds = []
    rnd = random.Random(65)
    extra = {'easy': 1, 'medium': 2, 'hard': 2}
    for tier, recipes in SALADS.items():
        for i, recipe in enumerate(recipes):
            steps = []
            for j, f in enumerate(recipe):
                others = rnd.sample([x for x in FRUIT_TR if x not in recipe], extra[tier])
                steps.append({'mode': 'place', 'piece': f'fruit.{f}', 'others': [f'fruit.{o}' for o in others],
                              'zone': BOWL_SLOTS[j], 'stays': True, 'askAudio': asks[f],
                              'askText': text(f'Şimdi de {FRUIT_TR[f][0]} koyalım.', f'Now the {FRUIT_EN[f]}.')})
            # After stirring the bowl holds pieces of the very fruits put in
            # (two of each), drawn by the app (Yunus, 16 Nov 2026).
            steps.append({'mode': 'stir', 'piece': 'stir.spoon', 'zone': [.25, .2, .5, .5],
                          'askAudio': stir_ask, 'askText': text(stir_ask_tr, stir_ask_en), 'doneAudio': done})
            first_f = recipe[0]
            rounds.append({
                'key': '-'.join(recipe), 'tier': tier, 'target': f'kitchen.bowl', 'stage': f'{PLAY}/bowl_empty.webp', 'aspect': 1.5, 'recipe': True,
                'front': f'{PLAY}/bowl_front.webp',
                'pieces': {f'fruit.{f}': f'{PLAY}/pieces/{f}.webp' for f in recipe},
                'text': text(f'Meyve salatası yapalım. Önce {FRUIT_TR[first_f][0]} koyalım.', f"Let's make a fruit salad. First, the {FRUIT_EN[first_f]}."),
                'audio': first[first_f], 'steps': steps,
            })
    return {'theme': 'kitchen', 'rounds': rounds}


# G66 Sofrayı Kuralım ---------------------------------------------------------
# piece: (Turkish "…yı", English, place on table.webp, turned by)
TABLE = {
    'plate': ('tabağı', 'plate', [.39, .32, .22, .36], 0),
    'bowl': ('kâseyi', 'bowl', [.4, .34, .2, .3], 0),
    'fork': ('çatalı', 'fork', [.29, .32, .08, .36], 0),
    'spoon': ('kaşığı', 'spoon', [.71, .32, .07, .36], 0),
    'knife': ('bıçağı', 'knife', [.63, .32, .08, .36], -0.72),
    'glass': ('bardağı', 'glass', [.63, .07, .12, .22], 0),
    'napkin': ('peçeteyi', 'napkin', [.2, .39, .09, .22], 0),
    'jug': ('sürahiyi', 'jug', [.25, .06, .14, .24], 0),
    'salt_shaker': ('tuzluğu', 'salt shaker', [.46, .06, .08, .2], 0),
}
# The order the child is asked in; every piece of the round waits on the
# right. Every round lays a different table, so no two games look the same.
TABLE_SETS = {
    'easy': [['plate', 'fork', 'spoon'], ['plate', 'glass', 'napkin'], ['bowl', 'spoon', 'glass'], ['fork', 'plate', 'knife'], ['jug', 'glass', 'plate']],
    'medium': [['plate', 'fork', 'knife', 'glass'], ['bowl', 'spoon', 'napkin', 'jug'], ['napkin', 'fork', 'plate', 'spoon'], ['glass', 'jug', 'plate', 'fork'], ['plate', 'knife', 'salt_shaker', 'glass']],
    'hard': [['plate', 'fork', 'knife', 'spoon', 'glass'], ['napkin', 'fork', 'plate', 'bowl', 'spoon'], ['jug', 'glass', 'plate', 'knife', 'fork', 'salt_shaker'],
             ['plate', 'bowl', 'spoon', 'napkin', 'glass', 'jug'], ['salt_shaker', 'plate', 'fork', 'knife', 'napkin', 'glass']],
}


def g66():
    asks = {k: line(f'g66_ask_{k}', f'Şimdi {v[0]} yerine koyalım.', f'Now the {v[1]}.') for k, v in TABLE.items()}
    firsts = {k: line(f'g66_first_{k}', f'Sofrayı kuralım. Önce {v[0]} koyalım.', f"Let's set the table. First, the {v[1]}.") for k, v in TABLE.items()}
    done = line('g66_done', 'Sofra hazır. Hadi yemeğe!', 'The table is ready. Time to eat!')
    rounds = []
    for tier, sets in TABLE_SETS.items():
        for items in sets:
            steps = []
            for name in items:
                tr, en, zone, turn = TABLE[name]
                step = {'mode': 'place', 'piece': f'kitchen.{name}', 'zone': zone, 'stays': True, 'shadow': True, 'askAudio': asks[name],
                        'askText': text(f'Şimdi {tr} yerine koyalım.', f'Now the {en}.')}
                if turn:
                    step['turn'] = turn
                steps.append(step)
            steps[-1]['doneAudio'] = done
            first = TABLE[items[0]]
            rounds.append({
                'key': '-'.join(items), 'tier': tier, 'target': f'kitchen.{items[0]}', 'stage': f'{PLAY}/table.webp', 'aspect': 1.5, 'gentle': True,
                'text': text(f'Sofrayı kuralım. Önce {first[0]} koyalım.', f"Let's set the table. First, the {first[1]}."),
                'audio': firsts[items[0]], 'steps': steps,
            })
    return {'theme': 'kitchen', 'rounds': rounds}


# G67 Nereye Koyalım? ---------------------------------------------------------
G67_PLACES = ['kitchen.fridge', 'kitchen.cupboard', 'kitchen.dishwasher', 'cleaning.trash_bin', 'kitchen.oven']
G67 = [
    ('put.milk', 'kitchen.fridge', 'Sütü nereye koyalım?', 'Where does the milk go?'),
    ('put.cheese', 'kitchen.fridge', 'Peyniri nereye koyalım?', 'Where does the cheese go?'),
    ('put.eggs', 'kitchen.fridge', 'Yumurtaları nereye koyalım?', 'Where do the eggs go?'),
    ('put.yogurt', 'kitchen.fridge', 'Yoğurdu nereye koyalım?', 'Where does the yogurt go?'),
    ('put.clean_plate', 'kitchen.cupboard', 'Temiz tabağı nereye koyalım?', 'Where does the clean plate go?'),
    ('put.clean_glass', 'kitchen.cupboard', 'Temiz bardağı nereye koyalım?', 'Where does the clean glass go?'),
    ('put.dirty_plate', 'kitchen.dishwasher', 'Kirli tabağı nereye koyalım?', 'Where does the dirty plate go?'),
    ('put.dirty_fork', 'kitchen.dishwasher', 'Kirli çatalı nereye koyalım?', 'Where does the dirty fork go?'),
    ('put.peel', 'cleaning.trash_bin', 'Muz kabuğunu nereye atalım?', 'Where does the banana peel go?'),
    ('put.empty_box', 'cleaning.trash_bin', 'Boş kutuyu nereye atalım?', 'Where does the empty box go?'),
    ('put.cake_dough', 'kitchen.oven', 'Kek hamurunu nereye koyalım?', 'Where does the cake batter go?'),
]


def g67():
    rounds = []
    for i, (stimulus, target, q_tr, q_en) in enumerate(G67, 1):
        rounds.append({'target': target, 'stimulus': stimulus, 'text': text(q_tr, q_en), 'audio': line(f'g67_{i}', q_tr, q_en)})
    return {'theme': 'kitchen', 'look': 'drop', 'choicePool': G67_PLACES, 'rounds': rounds}


SCENE_GAMES = {'G60': g60, 'G61': g61, 'G63': g63, 'G65': g65, 'G66': g66}
PAIR_GAMES = {'G62': g62, 'G64': g64, 'G67': g67}
EXTRA += WEATHER_EXTRA
