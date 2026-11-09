"""Meslekler ve Doğa ve Mevsimler: items, games and every spoken line."""

PLAY = 'assets/images/play'

JOBS = [
    ('doctor', 'easy', 'Doktor', 'Doctor'), ('nurse', 'easy', 'Hemşire', 'Nurse'),
    ('teacher', 'easy', 'Öğretmen', 'Teacher'), ('police_officer', 'easy', 'Polis', 'Police officer'),
    ('firefighter', 'easy', 'İtfaiyeci', 'Firefighter'), ('cook', 'easy', 'Aşçı', 'Cook'),
    ('driver', 'easy', 'Şoför', 'Driver'), ('farmer', 'easy', 'Çiftçi', 'Farmer'),
    ('baker', 'easy', 'Fırıncı', 'Baker'), ('dentist', 'easy', 'Diş hekimi', 'Dentist'),
    ('postman', 'medium', 'Postacı', 'Mail carrier'), ('hairdresser', 'medium', 'Kuaför', 'Hairdresser'),
    ('pilot', 'medium', 'Pilot', 'Pilot'), ('vet', 'medium', 'Veteriner', 'Vet'),
    ('waiter', 'medium', 'Garson', 'Waiter'), ('cleaner', 'medium', 'Temizlik görevlisi', 'Cleaner'),
    ('builder', 'medium', 'İnşaat işçisi', 'Builder'), ('cashier', 'medium', 'Kasiyer', 'Cashier'),
    ('painter', 'medium', 'Ressam', 'Painter'),
    ('gardener', 'hard', 'Bahçıvan', 'Gardener'), ('fisher', 'hard', 'Balıkçı', 'Fisher'),
    ('captain', 'hard', 'Kaptan', 'Captain'), ('pharmacist', 'hard', 'Eczacı', 'Pharmacist'),
    ('carpenter', 'hard', 'Marangoz', 'Carpenter'), ('mechanic', 'hard', 'Tamirci', 'Mechanic'),
    ('tailor', 'hard', 'Terzi', 'Tailor'), ('photographer', 'hard', 'Fotoğrafçı', 'Photographer'),
    ('musician', 'hard', 'Müzisyen', 'Musician'),
]

NATURE = [
    ('sun', 'easy', 'Güneş', 'Sun'), ('moon', 'easy', 'Ay', 'Moon'), ('star', 'easy', 'Yıldız', 'Star'),
    ('cloud', 'easy', 'Bulut', 'Cloud'), ('rain', 'easy', 'Yağmur', 'Rain'), ('snow', 'easy', 'Kar', 'Snow'),
    ('tree', 'easy', 'Ağaç', 'Tree'), ('flower', 'easy', 'Çiçek', 'Flower'), ('sea', 'easy', 'Deniz', 'Sea'),
    ('mountain', 'easy', 'Dağ', 'Mountain'),
    ('rainbow', 'medium', 'Gökkuşağı', 'Rainbow'), ('snowman', 'medium', 'Kardan adam', 'Snowman'),
    ('wind', 'medium', 'Rüzgâr', 'Wind'), ('lightning', 'medium', 'Şimşek', 'Lightning'),
    ('leaf', 'medium', 'Yaprak', 'Leaf'), ('grass', 'medium', 'Çimen', 'Grass'),
    ('river', 'medium', 'Nehir', 'River'), ('lake', 'medium', 'Göl', 'Lake'),
    ('forest', 'medium', 'Orman', 'Forest'),
    ('spring', 'hard', 'İlkbahar', 'Spring'), ('summer', 'hard', 'Yaz', 'Summer'),
    ('autumn', 'hard', 'Sonbahar', 'Autumn'), ('winter', 'hard', 'Kış', 'Winter'),
    ('night', 'hard', 'Gece', 'Night'), ('day', 'hard', 'Gündüz', 'Day'),
    ('seed', 'hard', 'Tohum', 'Seed'), ('sprout', 'hard', 'Filiz', 'Sprout'),
    ('sand', 'hard', 'Kum', 'Sand'),
]

EXTRA = []
LINES = {}


def line(key, tr, en):
    path = f'assets/audio/{{lang}}/scenes/{key}.mp3'
    LINES[path] = {'tr': tr, 'en': en}
    return {lang: path.replace('{lang}', lang) for lang in ('tr', 'en')}


def text(tr, en):
    return {'tr': tr, 'en': en}


GAMES = [
    ('G68', 'pair', 'Kim Ne Kullanır?', 'Who Uses It?'),
    ('G69', 'pair', 'Kim Yardım Eder?', 'Who Can Help?'),
    ('G70', 'pair', 'Nerede Çalışır?', 'Where Do They Work?'),
    ('G71', 'scene', 'Tohumu Büyüt', 'Grow the Seed'),
    ('G72', 'scene', 'Ağacı Hazırla', 'Dress the Tree'),
    ('G73', 'pair', 'Hava Nasıl?', "What's the Weather?"),
]
THEME_GAMES = {
    'jobs': ['G02', 'G68', 'G69', 'G70'],
    'nature': ['G02', 'G71', 'G72', 'G73'],
}
FREE = ['jobs_G02', 'jobs_G68', 'jobs_G69', 'nature_G02', 'nature_G71', 'nature_G72']

# G68 Kim Ne Kullanır? --------------------------------------------------------
# (tool, drawn as, person, question, sentence after)
G68 = [
    ('stethoscope', 'Steteskop', 'Stethoscope', 'doctor', 'Steteskopu kim kullanır?', 'Who uses the stethoscope?', 'Doktor hastayı dinliyor.', 'The doctor is listening to the patient.'),
    ('hose', 'Hortum', 'Fire hose', 'firefighter', 'Bu hortumu kim kullanır?', 'Who uses this hose?', 'İtfaiyeci yangını söndürüyor.', 'The firefighter is putting out the fire.'),
    ('ladle', 'Kepçe', 'Ladle', 'cook', 'Kepçeyi kim kullanır?', 'Who uses the ladle?', 'Aşçı çorbayı dağıtıyor.', 'The cook is serving the soup.'),
    ('chalk', 'Tebeşir', 'Chalk', 'teacher', 'Tebeşiri kim kullanır?', 'Who uses the chalk?', 'Öğretmen tahtaya yazıyor.', 'The teacher is writing on the board.'),
    ('whistle', 'Düdük', 'Whistle', 'police_officer', 'Düdüğü kim çalar?', 'Who blows the whistle?', 'Polis trafiği yönetiyor.', 'The police officer is directing the traffic.'),
    ('tractor', 'Traktör', 'Tractor', 'farmer', 'Traktörü kim kullanır?', 'Who drives the tractor?', 'Çiftçi tarlayı sürüyor.', 'The farmer is ploughing the field.'),
    ('letter', 'Mektup', 'Letter', 'postman', 'Mektubu kim getirir?', 'Who brings the letter?', 'Postacı mektubu getirdi.', 'The mail carrier brought the letter.'),
    ('scissors', 'Makas', 'Scissors', 'hairdresser', 'Saçı kesmek için makası kim kullanır?', 'Who uses scissors to cut hair?', 'Kuaför saçı kesiyor.', 'The hairdresser is cutting hair.'),
    ('dental_mirror', 'Diş aynası', 'Dental mirror', 'dentist', 'Diş aynasını kim kullanır?', 'Who uses the dental mirror?', 'Diş hekimi dişlere bakıyor.', 'The dentist is checking the teeth.'),
    ('bread_peel', 'Ekmek küreği', 'Bread peel', 'baker', 'Ekmek küreğini kim kullanır?', 'Who uses the bread peel?', 'Fırıncı ekmeği fırına sürüyor.', 'The baker is putting the bread in the oven.'),
    ('hammer', 'Çekiç', 'Hammer', 'carpenter', 'Çekici kim kullanır?', 'Who uses the hammer?', 'Marangoz çivi çakıyor.', 'The carpenter is hammering a nail.'),
    ('thermometer', 'Ateş ölçer', 'Thermometer', 'nurse', 'Ateş ölçeri kim kullanır?', 'Who uses the thermometer?', 'Hemşire ateşe bakıyor.', 'The nurse is checking the temperature.'),
]
EXTRA += [(f'use.{g[0]}', g[1], g[2]) for g in G68]
USERS = sorted({g[3] for g in G68})


def g68():
    rounds = []
    for i, (tool, _, _, person, q_tr, q_en, r_tr, r_en) in enumerate(G68, 1):
        rounds.append({'target': f'jobs.{person}', 'stimulus': f'use.{tool}', 'text': text(q_tr, q_en),
                       'audio': line(f'g68_{i}', q_tr, q_en), 'result': f'{PLAY}/job_{person}.webp',
                       'resultAudio': line(f'g68_done_{i}', r_tr, r_en)})
    return {'theme': 'jobs', 'look': 'drop', 'choicePool': [f'jobs.{u}' for u in USERS], 'rounds': rounds}


# G69 Kim Yardım Eder? --------------------------------------------------------
G69 = [
    ('cat_tree', 'firefighter', 'Kedi ağaçta kaldı. Kim yardım eder?', 'The cat is stuck in the tree. Who can help?', 'İtfaiyeci kediyi kurtardı.', 'The firefighter saved the cat.'),
    ('fire', 'firefighter', 'Bir yerde yangın çıktı. Kim yardım eder?', 'There is a fire. Who can help?', 'İtfaiyeci yangını söndürdü.', 'The firefighter put out the fire.'),
    ('fever', 'doctor', 'Ali hasta oldu. Kim yardım eder?', 'Ali is sick. Who can help?', 'Doktor Ali\'yi muayene etti.', 'The doctor checked Ali.'),
    ('toothache', 'dentist', 'Ali\'nin dişi ağrıyor. Kim yardım eder?', "Ali's tooth hurts. Who can help?", 'Diş hekimi dişine baktı.', 'The dentist looked at his tooth.'),
    ('lost', 'police_officer', 'Ali yolunu kaybetti. Kim yardım eder?', 'Ali is lost. Who can help?', 'Polis Ali\'yi annesine götürdü.', 'The police officer took Ali to his mom.'),
    ('sick_dog', 'vet', 'Köpek hasta oldu. Kim yardım eder?', 'The dog is sick. Who can help?', 'Veteriner köpeği iyileştirdi.', 'The vet made the dog better.'),
    ('broken_car', 'mechanic', 'Araba bozuldu. Kim yardım eder?', 'The car broke down. Who can help?', 'Tamirci arabayı yaptı.', 'The mechanic fixed the car.'),
    ('long_hair', 'hairdresser', 'Ali\'nin saçı çok uzadı. Kim yardım eder?', "Ali's hair is too long. Who can help?", 'Kuaför saçını kesti.', 'The hairdresser cut his hair.'),
    ('dry_garden', 'gardener', 'Çiçekler solmuş. Kim yardım eder?', 'The flowers are wilting. Who can help?', 'Bahçıvan çiçekleri suladı.', 'The gardener watered the flowers.'),
    ('torn_shirt', 'tailor', 'Gömlek yırtıldı. Kim yardım eder?', 'The shirt is torn. Who can help?', 'Terzi gömleği dikti.', 'The tailor sewed the shirt.'),
]
HELPERS = sorted({g[1] for g in G69} | {'teacher', 'cook', 'baker', 'farmer', 'pilot'})
EXTRA += [(f'need.{g[0]}', g[2].split('.')[0], g[3].split('.')[0]) for g in G69]


def g69():
    rounds = []
    for i, (scene, who, q_tr, q_en, r_tr, r_en) in enumerate(G69, 1):
        rounds.append({'target': f'jobs.{who}', 'stimulus': f'need.{scene}', 'text': text(q_tr, q_en),
                       'audio': line(f'g69_{i}', q_tr, q_en), 'result': f'{PLAY}/help_{scene}.webp',
                       'resultAudio': line(f'g69_done_{i}', r_tr, r_en)})
    return {'theme': 'jobs', 'look': 'scene', 'choicePool': [f'jobs.{h}' for h in HELPERS], 'rounds': rounds}


# G70 Nerede Çalışır? ---------------------------------------------------------
G70 = [
    ('teacher', 'school', 'Okul', 'School', 'Öğretmen nerede çalışır?', 'Where does the teacher work?'),
    ('doctor', 'hospital', 'Hastane', 'Hospital', 'Doktor nerede çalışır?', 'Where does the doctor work?'),
    ('cook', 'restaurant', 'Lokanta', 'Restaurant', 'Aşçı nerede çalışır?', 'Where does the cook work?'),
    ('farmer', 'farm', 'Çiftlik', 'Farm', 'Çiftçi nerede çalışır?', 'Where does the farmer work?'),
    ('firefighter', 'fire_station', 'İtfaiye', 'Fire station', 'İtfaiyeci nerede çalışır?', 'Where does the firefighter work?'),
    ('baker', 'bakery', 'Fırın', 'Bakery', 'Fırıncı nerede çalışır?', 'Where does the baker work?'),
    ('police_officer', 'police_station', 'Karakol', 'Police station', 'Polis nerede çalışır?', 'Where does the police officer work?'),
    ('pilot', 'plane', 'Uçak', 'Airplane', 'Pilot nerede çalışır?', 'Where does the pilot work?'),
    ('captain', 'ship', 'Gemi', 'Ship', 'Kaptan nerede çalışır?', 'Where does the captain work?'),
    ('pharmacist', 'pharmacy', 'Eczane', 'Pharmacy', 'Eczacı nerede çalışır?', 'Where does the pharmacist work?'),
]
EXTRA += [(f'place.{g[1]}', g[2], g[3]) for g in G70]


def g70():
    rounds = []
    for i, (who, place, _, _, q_tr, q_en) in enumerate(G70, 1):
        rounds.append({'target': f'place.{place}', 'stimulus': f'jobs.{who}', 'text': text(q_tr, q_en),
                       'audio': line(f'g70_{i}', q_tr, q_en)})
    return {'theme': 'jobs', 'look': 'drop', 'choicePool': [f'place.{g[1]}' for g in G70], 'rounds': rounds}


# G71 Tohumu Büyüt ------------------------------------------------------------
FLOWERS = [('pink', 'Pembe çiçek', 'Pink flower'), ('yellow', 'Sarı çiçek', 'Yellow flower'),
           ('tulip', 'Lale', 'Tulip'), ('sunflower', 'Ayçiçeği', 'Sunflower'), ('daisy', 'Papatya', 'Daisy')]
EXTRA += [('grow.seed', 'Tohum', 'Seed'), ('grow.can', 'Sulama kabı', 'Watering can'), ('grow.sun', 'Güneş', 'Sun'),
          ('grow.shoe', 'Ayakkabı', 'Shoe'), ('grow.spoon', 'Kaşık', 'Spoon'), ('grow.ball', 'Top', 'Ball')]
GROW_ZONE = [.32, .42, .36, .45]


def g71():
    ask1 = line('g71_seed', 'Tohumu toprağa ekelim.', "Let's plant the seed.")
    ask2 = line('g71_water', 'Şimdi tohumu sulayalım.', "Now let's water the seed.")
    ask3 = line('g71_sun', 'Güneşi getirelim, büyüsün.', "Let's bring the sun, so it can grow.")
    done2 = line('g71_sprout', 'Bak, filiz çıktı!', 'Look, a sprout!')
    distract = {'easy': ['grow.ball'], 'medium': ['grow.ball', 'grow.spoon'], 'hard': ['grow.ball', 'grow.spoon', 'grow.shoe']}
    rounds = []
    for tier in ('easy', 'medium', 'hard'):
        for slug, tr, en in FLOWERS:
            done = line(f'g71_done_{slug}', f'Çiçek açtı! {tr} ne güzel!', f'It bloomed! What a lovely {en.lower()}!')
            others = distract[tier]
            rounds.append({
                'key': slug, 'tier': tier, 'target': 'nature.seed', 'stage': f'{PLAY}/grow_0.webp', 'aspect': 1.5,
                'text': text('Tohumu toprağa ekelim.', "Let's plant the seed."), 'audio': ask1,
                'steps': [
                    {'mode': 'place', 'piece': 'grow.seed', 'others': others, 'zone': GROW_ZONE, 'after': f'{PLAY}/grow_1.webp'},
                    {'mode': 'place', 'piece': 'grow.can', 'others': others, 'zone': GROW_ZONE, 'after': f'{PLAY}/grow_2.webp',
                     'askAudio': ask2, 'askText': text('Şimdi tohumu sulayalım.', "Now let's water the seed."), 'doneAudio': done2},
                    {'mode': 'place', 'piece': 'grow.sun', 'others': others, 'zone': GROW_ZONE, 'after': f'{PLAY}/grow_{slug}.webp',
                     'askAudio': ask3, 'askText': text('Güneşi getirelim, büyüsün.', "Let's bring the sun, so it can grow."), 'doneAudio': done},
                ],
            })
    return {'theme': 'nature', 'rounds': rounds}


# G72 Ağacı Hazırla -----------------------------------------------------------
SEASONS = [
    ('winter', 'snow', 'Kar', 'Snow', 'Kış geldi. Ağaca ne koyalım?', 'Winter is here. What goes on the tree?', 'Ağaç bembeyaz oldu.', 'The tree is all white.'),
    ('spring', 'blossom', 'Çiçek', 'Blossoms', 'İlkbahar geldi. Ağaca ne koyalım?', 'Spring is here. What goes on the tree?', 'Ağaç çiçek açtı.', 'The tree is in bloom.'),
    ('autumn', 'yellow_leaves', 'Sarı yapraklar', 'Yellow leaves', 'Sonbahar geldi. Ağaca ne koyalım?', 'Autumn is here. What goes on the tree?', 'Yapraklar sapsarı oldu.', 'The leaves turned yellow.'),
    ('summer', 'apples', 'Elmalar', 'Apples', 'Yaz geldi. Ağaca ne koyalım?', 'Summer is here. What goes on the tree?', 'Ağaç elma dolu.', 'The tree is full of apples.'),
]
EXTRA += [(f'season.{s[1]}', s[2], s[3]) for s in SEASONS]


def g72():
    rounds = []
    count = {'easy': 1, 'medium': 2, 'hard': 3}
    names = [s[1] for s in SEASONS]
    for tier in ('easy', 'medium', 'hard'):
        for i, (season, piece, _, _, q_tr, q_en, r_tr, r_en) in enumerate(SEASONS):
            others = [n for n in names if n != piece][:count[tier]]
            rounds.append({
                'key': season, 'tier': tier, 'target': f'nature.{season}', 'stage': f'{PLAY}/tree_bare.webp', 'aspect': 1.5,
                'text': text(q_tr, q_en), 'audio': line(f'g72_{season}', q_tr, q_en),
                'steps': [{'mode': 'place', 'piece': f'season.{piece}', 'others': [f'season.{o}' for o in others],
                           'zone': [.25, .1, .5, .7], 'after': f'{PLAY}/tree_{season}.webp',
                           'doneAudio': line(f'g72_done_{season}', r_tr, r_en)}],
            })
    return {'theme': 'nature', 'rounds': rounds}


# G73 Hava Nasıl? -------------------------------------------------------------
G73 = [('rain', 'assets/sfx/nature/rain.mp3'), ('snow', 'assets/sfx/nature/snow.mp3'),
       ('sun', 'assets/sfx/nature/sun.mp3'), ('wind', 'assets/sfx/nature/wind.mp3'),
       ('lightning', 'assets/sfx/nature/thunder.mp3')]


def g73():
    q = line('g73_listen', 'Dinle bakalım. Hava nasıl?', "Listen. What's the weather like?")
    done = {'rain': ('Yağmur yağıyor.', "It's raining."), 'snow': ('Kar yağıyor.', "It's snowing."), 'sun': ('Güneş açmış.', "It's sunny."),
            'wind': ('Rüzgâr esiyor.', "It's windy."), 'lightning': ('Şimşek çakıyor.', "It's stormy.")}
    rounds = []
    for slug, sound in G73:
        rounds.append({'target': f'nature.{slug}', 'sound': sound, 'text': text('Dinle bakalım. Hava nasıl?', "Listen. What's the weather like?"), 'audio': q,
                       'resultAudio': line(f'g73_done_{slug}', *done[slug])})
    return {'theme': 'nature', 'choicePool': [f'nature.{s}' for s, _ in G73], 'rounds': rounds}


SCENE_GAMES = {'G71': g71, 'G72': g72}
PAIR_GAMES = {'G68': g68, 'G69': g69, 'G70': g70, 'G73': g73}
