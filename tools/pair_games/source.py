"""Texts of the data-driven pairing games (Nov 2026).

Each game: theme, look, optional choicePool, and rounds with stimulus,
target and the spoken question (TR written natively, not translated).
build_pair_games.py turns this into assets/content/pair_games.json and
records the clips.
"""

import source_more  # noqa: E402

EASY_COLORS = ['red', 'blue', 'yellow', 'green', 'orange', 'purple', 'pink', 'brown', 'black', 'white', 'gray']

# (stimulus item, color, TR name for the question, EN name)
COLOR_OBJECTS = [
    ('produce.tomato', 'red', 'Domates', 'tomato'),
    ('produce.strawberry', 'red', 'Çilek', 'strawberry'),
    ('produce.apple', 'red', 'Elma', 'apple'),
    ('produce.cherry', 'red', 'Kiraz', 'cherry'),
    ('vehicles.fire_truck', 'red', 'İtfaiye aracı', 'fire truck'),
    ('produce.banana', 'yellow', 'Muz', 'banana'),
    ('produce.lemon', 'yellow', 'Limon', 'lemon'),
    ('vehicles.taxi', 'yellow', 'Taksi', 'taxi'),
    ('vehicles.school_bus', 'yellow', 'Okul otobüsü', 'school bus'),
    ('produce.carrot', 'orange', 'Havuç', 'carrot'),
    ('produce.orange', 'orange', 'Portakal', 'orange'),
    ('produce.mandarin', 'orange', 'Mandalina', 'tangerine'),
    ('produce.cucumber', 'green', 'Salatalık', 'cucumber'),
    ('animals.frog', 'green', 'Kurbağa', 'frog'),
    ('produce.broccoli', 'green', 'Brokoli', 'broccoli'),
    ('produce.lettuce', 'green', 'Marul', 'lettuce'),
    ('produce.eggplant', 'purple', 'Patlıcan', 'eggplant'),
    ('animals.flamingo', 'pink', 'Flamingo', 'flamingo'),
    ('produce.chestnut', 'brown', 'Kestane', 'chestnut'),
    ('animals.bear', 'brown', 'Ayı', 'bear'),
    ('produce.coconut', 'brown', 'Hindistan cevizi', 'coconut'),
    ('animals.sheep', 'white', 'Koyun', 'sheep'),
    ('food.egg', 'white', 'Yumurta', 'egg'),
    ('animals.elephant', 'gray', 'Fil', 'elephant'),
    ('animals.rhinoceros', 'gray', 'Gergedan', 'rhino'),
    ('home.chair', 'blue', 'Sandalye', 'chair'),
    ('home.remote_control', 'blue', 'Kumanda', 'remote control'),
]


def games():
    out = {}
    out['G40'] = {
        'theme': 'colors',
        'choicePool': [f'colors.{c}' for c in EASY_COLORS],
        'rounds': [
            {'stimulus': item, 'target': f'colors.{color}',
             'text': {'tr': f'{tr} ne renk?', 'en': f'What color is the {en}?'}}
            for item, color, tr, en in COLOR_OBJECTS
        ],
    }
    basket_q = {'tr': 'Aynı renkteki sepete koy.', 'en': 'Put it in the basket with the same color.'}
    out['G41'] = {
        'theme': 'colors',
        'look': 'basket',
        'choicePool': [f'colors.{c}' for c in EASY_COLORS],
        'rounds': [
            {'stimulus': item, 'target': f'colors.{color}', 'text': basket_q, 'clip': 'basket'}
            for item, color, _, _ in COLOR_OBJECTS
        ],
    }
    return out


PAINT = {
    'red': ('Kırmızıya boya!', 'Paint it red!'),
    'blue': ('Maviye boya!', 'Paint it blue!'),
    'yellow': ('Sarıya boya!', 'Paint it yellow!'),
    'green': ('Yeşile boya!', 'Paint it green!'),
    'orange': ('Turuncuya boya!', 'Paint it orange!'),
    'purple': ('Mora boya!', 'Paint it purple!'),
    'pink': ('Pembeye boya!', 'Paint it pink!'),
    'brown': ('Kahverengiye boya!', 'Paint it brown!'),
}


def clips():
    """Single clips used by code-driven games: stem -> {tr, en}."""
    out = {f'G42_{slug}': {'tr': tr, 'en': en} for slug, (tr, en) in PAINT.items()}
    out.update(source_more.clips())
    return out


def all_games():
    out = games()
    out.update(source_more.games())
    return out
