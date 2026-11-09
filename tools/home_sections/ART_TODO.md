# Pictures still to draw (ChatGPT image limit reopens 9 Nov 2026, 20:25 Turkey time)

Style and saving rules are inside each prompt. Work in `D:\_MobileProjects\SpecialEducationGames-home`, branch `feature/home-sections`.

## 1. Instruments (5 of 9 missing)

Save as `artifacts/illustrations-home/items/music/<slug>.png`, SEG soft clay, 1024x1024, transparent, no people, no text.
Missing: `tambourine`, `recorder`, `violin`, `trumpet`, `accordion`.
(`drum`, `piano`, `guitar`, `bell` are done; `xylophone.png` exists but is not used.)
List of what is in the theme: `MUSIC` in `source_step4.py`.

## 2. Colouring pages (20)

Save as `artifacts/illustrations-home/coloring/<name>.png`, opaque white background, pure black thick closed outlines (about 10 px at 1024), no shading or grey, 6 to 12 large areas.
Names: lamb, apple, car, fish, flower, house, sun, butterfly, teddy, ball, tree, cat, boat, cupcake, duck, train, umbrella, star, strawberry, snail.

## 3. Stickers (160, about 30 per batch)

    python -I tools/home_sections/stickers.py prompt 0 30 > prompt.txt

Next batches: `30 60`, `60 90`, and so on. It writes the exact paths.

## After drawing

    python -I tools/home_sections/install_coloring.py
    python -I tools/home_sections/stickers.py install
    python -I tools/home_sections/build_themes.py
    python -I tools/build_photo_bounds.py
    python -I tools/home_sections/record_lines.py

Then add to `pubspec.yaml`: `assets/coloring/`, `assets/stickers/<theme>/` for each theme, `assets/images/music/`, `assets/audio/tr/music/`, `assets/audio/en/music/`.

Tests to update when Music opens (it is hidden until all its pictures exist): the free-card count 45 becomes 48 in `test/config_test.dart` and `test/phase_two_games_test.dart`, `music_G02`, `music_G74`, `music_G75` join the list in `test/learning_test.dart`, the card count 95 there becomes 99.
Sen de Çal (G75) and Çal Bakalım (G76) have only been checked by code so far; play them once on a device.
