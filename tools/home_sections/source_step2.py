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
    ('G63', 'scene', "Ali'yi Giydir", 'Dress Ali'),
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

TEETH_ZONE = [.32, .50, .36, .22]


def teeth_spots(n, seed):
    rnd = random.Random(seed)
    spots = []
    x0, y0, w, h = TEETH_ZONE
    while len(spots) < n:
        s = [round(x0 + rnd.random() * (w - .07), 3), round(y0 + rnd.random() * (h - .09), 3), .07, .09]
        if all(abs(a[0] - s[0]) > .055 or abs(a[1] - s[1]) > .07 for a in spots):
            spots.append(s)
    return spots


def g60():
    ask = line('g60_ask', "Ali'nin dişleri kirlenmiş. Hadi fırçalayalım!", "Ali's teeth need a clean. Let's brush them!")
    done = line('g60_done', 'Dişlerin pırıl pırıl oldu, Ali!', 'Your teeth are sparkling, Ali!')
    rounds = []
    for tier, n in (('easy', 3), ('medium', 5), ('hard', 8)):
        for i in range(5):
            rounds.append({
                'key': f'{tier}{i}', 'tier': tier, 'target': 'cleaning.toothbrush',
                'stage': f'{PLAY}/teeth_dirty.webp', 'aspect': 1.5,
                'text': text("Ali'nin dişlerini fırçalayalım.", "Let's brush Ali's teeth."), 'audio': ask,
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
WASH_OTHERS = ['cleaning.comb', 'cleaning.toothbrush', 'cleaning.sponge', 'cleaning.shampoo', 'cleaning.bucket', 'kitchen.spoon', 'cleaning.broom']


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
    for i, (target, q_tr, q_en, r_tr, r_en, picture) in enumerate(G62, 1):
        rounds.append({
            'target': target, 'text': text(q_tr, q_en), 'audio': line(f'g62_{i}', q_tr, q_en),
            'result': f'{PLAY}/{picture}.webp', 'resultAudio': line(f'g62_done_{i}', r_tr, r_en),
        })
    return {'theme': 'cleaning', 'rounds': rounds}


# G63 Ali'yi Giydir -----------------------------------------------------------
G63 = [
    ('easy', 'tshirt', 'Ali\'ye tişörtünü giydirelim.', "Let's put Ali's T-shirt on.", 'Tişört ne güzel oldu!', 'The T-shirt looks great!'),
    ('easy', 'trousers', 'Ali\'ye pantolonunu giydirelim.', "Let's put Ali's pants on.", 'Pantolon tam oldu!', 'The pants fit just right!'),
    ('easy', 'socks', 'Ali\'ye çoraplarını giydirelim.', "Let's put Ali's socks on.", 'Ayakları sıcacık oldu.', 'His feet are nice and warm.'),
    ('easy', 'shoes', 'Ali\'ye ayakkabılarını giydirelim.', "Let's put Ali's shoes on.", 'Ali artık yürüyebilir!', 'Now Ali can walk outside!'),
    ('easy', 'hat', 'Ali\'nin başına şapkasını takalım.', "Let's put Ali's hat on.", 'Şapka ona çok yakıştı!', 'That hat looks great on him!'),
    ('medium', 'coat', 'Ali üşüyor. Montunu giydirelim.', "Ali is cold. Let's put his coat on.", 'Oh, ısındı!', 'Now he is warm!'),
    ('medium', 'scarf', 'Ali\'nin boynuna atkısını takalım.', "Let's put Ali's scarf on.", 'Boynu sıcacık oldu.', 'His neck is warm now.'),
    ('medium', 'gloves', 'Ali\'nin ellerine eldivenlerini takalım.', "Let's put Ali's gloves on.", 'Elleri üşümez artık.', 'His hands will not get cold.'),
    ('medium', 'beanie', 'Ali\'nin başına beresini takalım.', "Let's put Ali's beanie on.", 'Kulakları da sıcacık.', 'His ears are warm too.'),
    ('medium', 'pajamas', 'Uyku vakti. Ali\'ye pijamasını giydirelim.', "It's bedtime. Let's put Ali's pajamas on.", 'İyi uykular, Ali!', 'Sleep well, Ali!'),
    ('hard', 'raincoat', 'Yağmur var. Ali\'ye yağmurluğunu giydirelim.', "It's raining. Let's put Ali's raincoat on.", 'Artık ıslanmaz!', 'Now he will stay dry!'),
    ('hard', 'sweater', 'Hava serin. Ali\'ye kazağını giydirelim.', "It's chilly. Let's put Ali's sweater on.", 'Kazak çok yumuşak.', 'The sweater is so soft.'),
    ('hard', 'boots', 'Dışarısı çamur. Ali\'ye çizmelerini giydirelim.', "It's muddy outside. Let's put Ali's boots on.", 'Çamura basabilir!', 'He can step in the mud!'),
    ('hard', 'vest', 'Ali\'ye yeleğini giydirelim.', "Let's put Ali's vest on.", 'Yelek çok şık oldu.', 'The vest looks so smart.'),
    ('hard', 'tracksuit', 'Spor zamanı. Ali\'ye eşofmanını giydirelim.', "It's sports time. Let's put Ali's tracksuit on.", 'Ali koşmaya hazır!', 'Ali is ready to run!'),
]
G63_OTHERS = {'easy': 1, 'medium': 2, 'hard': 3}


def g63():
    rnd = random.Random(63)
    names = [x[1] for x in G63]
    rounds = []
    for tier, slug, q_tr, q_en, r_tr, r_en in G63:
        others = rnd.sample([n for n in names if n != slug], G63_OTHERS[tier])
        rounds.append({
            'key': slug, 'tier': tier, 'target': f'clothes.{slug}', 'stage': 'assets/images/wear/ali_full.webp', 'aspect': 2 / 3,
            'text': text(q_tr, q_en), 'audio': line(f'g63_{slug}', q_tr, q_en),
            'steps': [{'mode': 'place', 'piece': f'clothes.{slug}', 'others': [f'clothes.{o}' for o in others],
                       'zone': [.15, .1, .7, .8], 'after': f'{PLAY}/wear_{slug}.webp',
                       'doneAudio': line(f'g63_done_{slug}', r_tr, r_en)}],
        })
    return {'theme': 'clothes', 'rounds': rounds}


# G64 Bugün Ne Giysek? --------------------------------------------------------
# (weather picture, target, also right, question, answer sentence, result picture)
G64 = [
    ('rain', 'raincoat', ['umbrella', 'boots'], 'Dışarıda yağmur yağıyor. Ali ne giysin?', "It's raining outside. What should Ali wear?", 'Yağmurluğunu giydi, dışarı çıkıyor.', 'He put on his raincoat and off he goes.', 'out_rain'),
    ('rain', 'umbrella', ['raincoat', 'boots'], 'Yağmur başladı. Ali yanına ne alsın?', 'It started to rain. What should Ali take?', 'Şemsiyesini aldı, hiç ıslanmıyor.', 'He took his umbrella and stays dry.', 'out_umbrella'),
    ('snow', 'coat', ['beanie', 'gloves', 'scarf', 'boots', 'sweater'], 'Dışarıda kar yağıyor. Ali ne giysin?', "It's snowing outside. What should Ali wear?", 'Montunu giydi, karda oynuyor.', 'He put on his coat and plays in the snow.', 'out_snow'),
    ('snow', 'gloves', ['coat', 'beanie', 'scarf', 'boots', 'sweater'], 'Ali kartopu oynayacak. Eline ne taksın?', 'Ali wants to make snowballs. What goes on his hands?', 'Eldivenlerini taktı, kartopu yapıyor.', 'He put on his gloves and makes snowballs.', 'out_gloves'),
    ('sun', 'shorts', ['tshirt', 'sandals', 'hat', 'sunglasses', 'swimsuit'], 'Hava çok sıcak. Ali ne giysin?', "It's very hot. What should Ali wear?", 'Şortunu giydi, parka gidiyor.', 'He put on his shorts and goes to the park.', 'out_sun'),
    ('sun', 'sunglasses', ['hat', 'shorts', 'tshirt', 'sandals'], 'Güneş gözünü alıyor. Ali ne taksın?', 'The sun is in his eyes. What should Ali put on?', 'Güneş gözlüğünü taktı, çok havalı oldu.', 'He put on his sunglasses and looks so cool.', 'out_shades'),
    ('sea', 'swimsuit', ['hat', 'sunglasses', 'sandals', 'shorts'], 'Ali denize gidiyor. Ne giysin?', 'Ali is going to the sea. What should he wear?', 'Mayosunu giydi, denize giriyor.', 'He put on his swimsuit and jumps in.', 'out_sea'),
    ('night', 'pajamas', ['slippers'], 'Hava karardı, uyku vakti. Ali ne giysin?', "It's dark, time for bed. What should Ali wear?", 'Pijamasını giydi, yatağına girdi.', 'He put on his pajamas and got into bed.', 'out_bed'),
]
G64_ALL = sorted({x[1] for x in G64} | {o for x in G64 for o in x[2]} | {'dress', 'skirt', 'sneakers'})


def g64():
    rounds = []
    for i, (weather, target, also, q_tr, q_en, r_tr, r_en, picture) in enumerate(G64, 1):
        rounds.append({
            'target': f'clothes.{target}', 'stimulus': f'weather.{weather}', 'alsoRight': [f'clothes.{a}' for a in also],
            'text': text(q_tr, q_en), 'audio': line(f'g64_{i}', q_tr, q_en),
            'result': f'{PLAY}/{picture}.webp', 'resultAudio': line(f'g64_done_{i}', r_tr, r_en),
        })
    return {'theme': 'clothes', 'look': 'scene', 'choicePool': [f'clothes.{c}' for c in G64_ALL], 'rounds': rounds}


WEATHER_EXTRA = [('weather.rain', 'Yağmur', 'Rain'), ('weather.snow', 'Kar', 'Snow'), ('weather.sun', 'Güneş', 'Sun'),
                 ('weather.sea', 'Deniz', 'Sea'), ('weather.night', 'Gece', 'Night')]


# G65 Meyve Salatası ----------------------------------------------------------
FRUIT_TR = {'apple': ('elmayı', 'elma'), 'banana': ('muzu', 'muz'), 'strawberry': ('çileği', 'çilek'), 'orange': ('portakalı', 'portakal'),
            'grape': ('üzümü', 'üzüm'), 'kiwi': ('kiviyi', 'kivi'), 'peach': ('şeftaliyi', 'şeftali'), 'pear': ('armudu', 'armut')}
FRUIT_EN = {'apple': 'apple', 'banana': 'banana', 'strawberry': 'strawberry', 'orange': 'orange',
            'grape': 'grapes', 'kiwi': 'kiwi', 'peach': 'peach', 'pear': 'pear'}
BOWL_SLOTS = [[.26, .34, .2, .3], [.42, .3, .2, .3], [.56, .36, .2, .3], [.34, .46, .2, .3], [.5, .47, .2, .3]]
SALADS = {
    'easy': [['apple', 'banana'], ['strawberry', 'orange'], ['grape', 'pear'], ['kiwi', 'peach'], ['banana', 'strawberry']],
    'medium': [['apple', 'banana', 'orange'], ['strawberry', 'kiwi', 'pear'], ['grape', 'peach', 'apple'], ['orange', 'strawberry', 'banana'], ['pear', 'grape', 'kiwi']],
    'hard': [['apple', 'banana', 'strawberry', 'orange'], ['grape', 'kiwi', 'peach', 'pear'], ['orange', 'apple', 'grape', 'kiwi', 'banana'], ['strawberry', 'pear', 'peach', 'apple', 'grape'], ['banana', 'kiwi', 'orange', 'pear', 'strawberry']],
}


def g65():
    first = {f: line(f'g65_first_{f}', f'Meyve salatası yapalım. Önce {FRUIT_TR[f][0]} koyalım.', f"Let's make a fruit salad. First, the {FRUIT_EN[f]}.") for f in FRUIT_TR}
    asks = {f: line(f'g65_ask_{f}', f'Şimdi de {FRUIT_TR[f][0]} koyalım.', f'Now the {FRUIT_EN[f]}.') for f in FRUIT_TR}
    stir_ask_tr, stir_ask_en = 'Hadi, karıştıralım.', "Now let's stir."
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
            steps.append({'mode': 'stir', 'piece': 'stir.spoon', 'zone': [.25, .3, .5, .5], 'after': f'{PLAY}/bowl_mixed.webp',
                          'askAudio': stir_ask, 'askText': text(stir_ask_tr, stir_ask_en), 'doneAudio': done})
            first_f = recipe[0]
            rounds.append({
                'key': '-'.join(recipe), 'tier': tier, 'target': f'kitchen.bowl', 'stage': f'{PLAY}/bowl_empty.webp', 'aspect': 1.5, 'recipe': True,
                'text': text(f'Meyve salatası yapalım. Önce {FRUIT_TR[first_f][0]} koyalım.', f"Let's make a fruit salad. First, the {FRUIT_EN[first_f]}."),
                'audio': first[first_f], 'steps': steps,
            })
    return {'theme': 'kitchen', 'rounds': rounds}


# G66 Sofrayı Kuralım ---------------------------------------------------------
TABLE = {
    'plate': ('tabağı', 'plate', [.39, .42, .22, .33]),
    'fork': ('çatalı', 'fork', [.27, .42, .10, .33]),
    'spoon': ('kaşığı', 'spoon', [.63, .42, .10, .33]),
    'knife': ('bıçağı', 'knife', [.74, .42, .10, .33]),
    'glass': ('bardağı', 'glass', [.66, .12, .14, .26]),
    'napkin': ('peçeteyi', 'napkin', [.13, .46, .12, .24]),
}
TABLE_SETS = {
    'easy': [['plate', 'glass'], ['plate', 'fork'], ['plate', 'spoon'], ['glass', 'spoon'], ['fork', 'glass']],
    'medium': [['plate', 'fork', 'glass'], ['plate', 'spoon', 'glass'], ['plate', 'fork', 'spoon'], ['plate', 'knife', 'glass'], ['fork', 'knife', 'plate']],
    'hard': [['plate', 'fork', 'spoon', 'glass'], ['plate', 'fork', 'knife', 'glass'], ['plate', 'spoon', 'glass', 'napkin'], ['plate', 'fork', 'knife', 'spoon', 'glass'], ['plate', 'fork', 'knife', 'glass', 'napkin']],
}
TABLE_OTHERS = ['kitchen.pot', 'kitchen.pan', 'kitchen.teapot', 'kitchen.tray', 'kitchen.ladle', 'kitchen.jug']


def g66():
    asks = {k: line(f'g66_ask_{k}', f'Şimdi {v[0]} yerine koyalım.', f'Now the {v[1]}.') for k, v in TABLE.items()}
    firsts = {k: line(f'g66_first_{k}', f'Sofrayı kuralım. Önce {v[0]} koyalım.', f"Let's set the table. First, the {v[1]}.") for k, v in TABLE.items()}
    done = line('g66_done', 'Sofra hazır. Hadi yemeğe!', 'The table is ready. Time to eat!')
    rnd = random.Random(66)
    extra = {'easy': 1, 'medium': 2, 'hard': 2}
    rounds = []
    for tier, sets in TABLE_SETS.items():
        for items in sets:
            steps = []
            for name in items:
                tr, en, zone = TABLE[name]
                steps.append({'mode': 'place', 'piece': f'kitchen.{name}', 'others': rnd.sample(TABLE_OTHERS, extra[tier]),
                              'zone': zone, 'stays': True, 'shadow': True, 'askAudio': asks[name],
                              'askText': text(f'Şimdi {tr} yerine koyalım.', f'Now the {en}.')})
            steps[-1]['doneAudio'] = done
            first = TABLE[items[0]]
            rounds.append({
                'key': '-'.join(items), 'tier': tier, 'target': f'kitchen.{items[0]}', 'stage': f'{PLAY}/table.webp', 'aspect': 1.5,
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
    return {'theme': 'kitchen', 'look': 'basket', 'choicePool': G67_PLACES, 'rounds': rounds}


SCENE_GAMES = {'G60': g60, 'G61': g61, 'G63': g63, 'G65': g65, 'G66': g66}
PAIR_GAMES = {'G62': g62, 'G64': g64, 'G67': g67}
EXTRA += WEATHER_EXTRA
