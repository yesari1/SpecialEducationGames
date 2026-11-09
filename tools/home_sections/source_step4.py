"""Müzik Aletleri: items, games and spoken lines (Play Park)."""

MUSIC = [
    ('drum', 'easy', 'Davul', 'Drum'), ('piano', 'easy', 'Piyano', 'Piano'),
    ('guitar', 'easy', 'Gitar', 'Guitar'), ('bell', 'easy', 'Zil', 'Bell'),
    # To swap an instrument: change this list, then its drawing and its sound
    # in import_commons_sfx.py.
    ('accordion', 'medium', 'Akordeon', 'Accordion'), ('tambourine', 'medium', 'Tef', 'Tambourine'),
    ('recorder', 'medium', 'Flüt', 'Recorder'), ('violin', 'hard', 'Keman', 'Violin'),
    ('trumpet', 'hard', 'Trompet', 'Trumpet'), ('darbuka', 'hard', 'Darbuka', 'Darbuka'),
]
ITEM_SFX = {f'music.{slug}': f'assets/sfx/music/{slug}.mp3' for slug, *_ in MUSIC}

EXTRA = []
LINES = {}


def line(key, tr, en):
    path = f'assets/audio/{{lang}}/scenes/{key}.mp3'
    LINES[path] = {'tr': tr, 'en': en}
    return {lang: path.replace('{lang}', lang) for lang in ('tr', 'en')}


GAMES = [
    ('G74', 'pair', 'Hangi Alet Çalıyor?', 'Which One Is Playing?'),
    ('G75', 'echo', 'Sen de Çal', 'Your Turn'),
    ('G76', 'free_play', 'Çal Bakalım', 'Play Along'),
]
THEME_GAMES = {'music': ['G02', 'G74', 'G75', 'G76']}
FREE = ['music_G02', 'music_G74', 'music_G75']


def g74():
    q = line('g74_listen', 'Dinle bakalım. Hangi alet çalıyor?', 'Listen. Which instrument is playing?')
    rounds = [{'target': f'music.{slug}', 'sound': f'assets/sfx/music/{slug}.mp3',
               'text': {'tr': 'Dinle bakalım. Hangi alet çalıyor?', 'en': 'Listen. Which instrument is playing?'}, 'audio': q}
              for slug, *_ in MUSIC]
    return {'theme': 'music', 'rounds': rounds}


line('g75_listen', 'Dinle, sonra sen de çal.', 'Listen, then you play too.')
line('g75_again', 'Bir daha dinleyelim.', "Let's listen again.")
line('g76_play', 'Hangisini istersen çal.', 'Play whichever you like.')

SCENE_GAMES = {}
PAIR_GAMES = {'G74': g74}
