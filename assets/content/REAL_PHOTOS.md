# Real photo credits

Adaptations of real photographs, not generated images. Source licenses/public-domain dedications are retained. Processing preserves photographed detail through deterministic masking/crop/resize. The app also draws a white outline at display time.

## animals.cat

File: assets/images/animals/cat_real.webp
Photo author: Matsu1024
Original background removal: YukiKoKo
Source: https://commons.wikimedia.org/wiki/File:Turkish_Van_cat_transparent.png
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Original transparent cutout retained; alpha-bound crop, aspect-preserving resize and padding. Enlarged to maximum 912 px photo extent, with a 4 px white silhouette outline (combined extent <=920 px, padding >=52 px).

## animals.fish

File: `assets/images/animals/fish_real.webp` (the catalog keeps the legacy `fish_1.png` after this verified photo).
Original photograph: Ffish.asia, [ギンブナ DSC4346.jpg](https://commons.wikimedia.org/wiki/File:%E3%82%AE%E3%83%B3%E3%83%96%E3%83%8A_DSC4346.jpg), CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/.
Transparent derivative: Ellicrum, [Carassius auratus 2.png](https://commons.wikimedia.org/wiki/File:Carassius_auratus_2.png), CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/.
The fish is used for the generic catalog label “Fish”; it is not identified as a goldfish. The derivative's existing transparency was retained. Adaptation: alpha-bound crop, aspect-preserving 912 px maximum extent, centered 1024×1024 RGBA export and 4 px white outer outline. No new mask or generative editing. The adapted PNG is shared under CC BY-SA 4.0, with both creators attributed and source/license links retained.
Original derivative SHA-256: `cc695c641b89bd859d1f1a1f4521dae08a9296acf9565f769bbba0e23ba30357`.
Adapted PNG SHA-256: `4d7581d9fc6c17aba5168f6beeb3b4d8e8707346c9fb884416b7c28317a1ac61`.

## animals.fish — variant 2

File: `assets/images/animals/fish_trout_real.webp`
Photograph: Allan Harris, [iNaturalist photo 14650939](https://www.inaturalist.org/photos/14650939), CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/.
Commons source-file contributor: Lodewicus de Honsvels; [source photo file](https://commons.wikimedia.org/wiki/File:Salvelinus_namaycush_-_Amerikanischer_Seesaibling_14650939.jpg).
Transparent derivative and crop: Ellicrum, [Salvelinus namaycush.png](https://commons.wikimedia.org/wiki/File:Salvelinus_namaycush.png), CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/.
Attribution: Allan Harris (photograph), Lodewicus de Honsvels (Commons source-file contributor), and Ellicrum (transparent derivative). Indicate changes and keep the adaptation under CC BY-SA 4.0.
Input derivative: `artifacts/legacy-alpha-source-r13/Salvelinus_namaycush.png` (SHA-256 `41da55b4c37e55fe5f214f1b108db3ef0b981575b2be54088d5820057d7792d4`).
Adapted PNG SHA-256: `2693fe85ce3c7e32940d5777e15254d5d068c3e54e19b5c71c10c1c6b34667fa`.
Changes: Second distinct generic fish photo, a Lake Trout (`Salvelinus namaycush`). Existing transparent alpha and photo RGB retained; alpha-bound crop, aspect-preserving Lanczos resize to 900 px maximum fish extent, centered 1024×1024 RGBA export, and 4 px white outline. No new mask, generative edits, or reconstructed detail. Soft edge pixels from the source cutout remain beneath the outline. Local technical approval is recorded; final human approval is still pending.

## animals.turtle

File: assets/images/animals/turtle_real.webp
Photo author: Katrin Bolovtsova
Source: https://www.pexels.com/photo/photo-of-a-turtle-5263883/
Source and adaptation license: Pexels License — https://www.pexels.com/license/ (free app use and modification under the license terms).
Original: `artifacts/real-animal-turtle-elephant-candidate/alternative-plain-turtle/originals/pexels-5263883.jpg` (6602×4401; SHA-256 `85ac585743ff0b4ec54b3e21d402cad73b3081d2da9bc85ef8c05ee14cb10761`).
Adapted PNG SHA-256: `f692de6d459465afe7d4174db10a8b20ad519cbf24221c4548c817d27af84f74`.
Changes: Classical OpenCV GrabCut used the reviewed source contour, central-shell and visible-head/forelimb foreground seeds, and background seeds (5 iterations at 1800×1200). Original RGB detail retained without repainting; aspect-preserving resize and centering on a 1024×1024 RGBA canvas, with a 4 px white outer outline. Rear limbs and tail are naturally tucked beneath the shell in the source photograph. No generative edits. Reproducible helper inputs and report are retained in `artifacts/real-animal-turtle-elephant-candidate/alternative-plain-turtle/mask2/`.

## produce.apple

File: assets/images/produce/apple_real.webp
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Honeycrisp-Apple.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.avocado

File: assets/images/produce/avocado_real.webp
Photo author: Tiia Monto
Source: https://commons.wikimedia.org/wiki/File:Avocado.png
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Decoded pixel RGBA checked identical after lossless96dpi working-copy normalization (prevents GDI DrawImageUnscaled physical-size clipping). Existing source transparency retained where present; border-connected neutral white otherwise removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.

## produce.banana

File: assets/images/produce/banana_real.webp
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Banana-Single.jpg
Source and adaptation license: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.kiwi

File: assets/images/produce/kiwi_real.webp
Photo author: Boris Stumpf
Source: https://commons.wikimedia.org/wiki/File:Whole_kiwifruit_on_white_background.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Decoded pixel RGBA checked identical after lossless96dpi working-copy normalization (prevents GDI DrawImageUnscaled physical-size clipping). Existing source transparency retained where present; border-connected neutral white otherwise removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.

## produce.lemon

File: assets/images/produce/lemon_real.webp
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Whole-Lemon.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.melon

File: assets/images/produce/melon_real.webp
Photo author: Tiia Monto
Source: https://commons.wikimedia.org/wiki/File:Galia_melon.jpg
Source and adaptation license: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0/
Changes: Decoded pixel RGBA checked identical after lossless96dpi working-copy normalization (prevents GDI DrawImageUnscaled physical-size clipping). Existing source transparency retained where present; border-connected neutral white otherwise removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.

## produce.orange

File: `assets/images/produce/orange_real.webp`
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Orange-Whole-%26-Split.jpg
License: CC BY-SA 3.0 - https://creativecommons.org/licenses/by-sa/3.0
Original: `artifacts/photo-replacements-r44/orange/attempt-09/originals/source.jpg` (SHA-256 `bff01adc35ba190f0b22c3ef5d238fd7da04ec6f6c7a272879f78c0dc1aa452f`).
Adapted PNG SHA-256: `f3d1b780ca78ae044eed6f3cc3cc647d7841bd9cc4b229f0671dc9a616688c43`.
Changes: The complete whole orange was isolated from the separate half. Border-connected neutral near-white background was removed within a generous whole-fruit ROI; enclosed highlights and the stem were retained. Original photo RGB was preserved, then adapted with `tools/adapt_cutout_photo.py` to a 912 px maximum extent on a centered 1024x1024 RGBA canvas with a 4 px white outline. Attempt artifacts: `artifacts/photo-replacements-r44/orange/attempt-09/`.
## produce.pepper

File: assets/images/produce/pepper_real.webp
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Green-Bell-Pepper.jpg
Source and adaptation license: Public domain — https://commons.wikimedia.org/wiki/Commons:Copyright_tags#Public_domain
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.tomato

File: assets/images/produce/tomato_real.webp
Photo author: Renee Comet (Photographer), National Cancer Institute
Source: https://commons.wikimedia.org/wiki/File:Tomato_(1).jpg
Source and adaptation license: Public domain — https://creativecommons.org/publicdomain/mark/1.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.zucchini

File: assets/images/produce/zucchini_real.webp
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Zucchini-Whole.jpg
Source and adaptation license: Public domain — https://commons.wikimedia.org/wiki/Commons:Copyright_tags#Public_domain
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.leek

File: assets/images/produce/leek_real.webp
Photo author: Amada44
Source: https://commons.wikimedia.org/wiki/File:Leek_on_white_background_-_0947.jpg
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Decoded RGBA identity checked after lossless96dpi metadata normalization. Near-white neutral background alpha-keyed (minimum RGB249, channel difference<=8), including enclosed leaf gaps; photographed white stem retained. Largest silhouette retained, proportional912px resize, centered1024x1024 RGBA and4px white silhouette outline. Foreground photographic RGB retained without repainting or generative edits.


## produce.pear

File: assets/images/produce/pear_real.webp
Photo author: Fructibus
Source: https://commons.wikimedia.org/wiki/File:Conference_pear_2017_D1.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Complete pear; source background and cast shadow masked. Original photographed RGB detail retained; transparent exterior created by masking, alpha-bound crop, aspect-preserving resize to a maximum 912 px, centered 1024x1024 RGBA export, and 4 px white silhouette contour. No generative editing.
Original file: artifacts/real-produce-next/source/pear.jpg (SHA-256 `934f71fc0c22a32e90d6c90b797e56cec28545c98643fdbc7231ced2d81c1888`).
Adapted PNG SHA-256: `aae475a8368dd8a21dfb729571f7537c42dc149ab71c770c08e137ec71b48db5`.

## produce.plum

File: assets/images/produce/plum_real.webp
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Red-Plums.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Selected the complete whole plum from the left of the source photo; cut half excluded with crop (35, 210, 1785, 1830) in original-image pixels; border-connected background and cast shadow masked. Original photographed RGB detail retained; transparent exterior created by masking, alpha-bound crop, aspect-preserving resize to a maximum 912 px, centered 1024x1024 RGBA export, and 4 px white silhouette contour. No generative editing.
Original file: artifacts/real-produce-next/source/plum.jpg (SHA-256 `9bd1763236d1617f8ac7642a813badd320158942378ca54a4cd94d9f99ad312b`).
Adapted PNG SHA-256: `9fef6259a77ea7dcca8494ac5e042e318fa2eacd39e918af492dcb1dfe29612f`.

## produce.strawberry

File: `assets/images/produce/strawberry_real.webp`
Photo author: Shutterbug26 (Pixabay)
Source: https://pixabay.com/photos/strawberry-berry-fruit-food-fresh-1238295/
Source and adaptation license: Pixabay Content License - https://pixabay.com/service/license-summary/
Original: `artifacts/photo-replacements-r46/strawberry/attempt-01/original.jpg` (SHA-256 `7f53e310196362a977a9cf98a5b7edbc6364d84d39594d404c9df3aa9acdf998`).
Adapted PNG SHA-256: `d8ac7c9533ce5770f1be18f2c9e73c2fd330e797765d5f695bbfad48d8e2aa1f`.
Changes: One whole, bright red strawberry with its green calyx. Foreground alpha with rembg U2Net (largest region kept, holes filled, original RGB retained); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline (tools/adapt_cutout_photo.py). No generative editing.

## produce.pomegranate

File: `assets/images/produce/pomegranate_real.webp`
Photo author: Rhododendrites
Source: https://commons.wikimedia.org/wiki/File:Pomegranate_on_white.jpg
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Original: `artifacts/real-produce-batch2/originals/pomegranate_rhododendrites.jpg` (SHA-256 `19bf770bb8af0b5251dbab9871f4fc949b7f97017f4c67798e8ae4dfda73dcd1`).
Adapted PNG SHA-256: `7f6f202ef5274d98ef7eb61622c9210e1cc5aa3fe9574f8e8c063b0ca0f95e33`.
Changes: Single complete photographed pomegranate and crown. A traced closed Catmull-Rom perimeter, refined by red-rind chroma masking on the body, excludes the neutral studio background and cast shadow while retaining crown detail. Original photographed RGB detail retained; alpha-bound crop with 1.2% padding, aspect-preserving LANCZOS resize to 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white silhouette outline. No generative editing; adaptation shared under CC BY-SA 4.0.

## produce.grapefruit

File: `assets/images/produce/grapefruit_real.webp`
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Grapefruit-Whole-%26-Split.jpg
Source and adaptation license: Public domain — https://creativecommons.org/publicdomain/mark/1.0/
Original: `artifacts/real-produce-batch3/originals/grapefruit_evan_amos.jpg` (SHA-256 `c06202e0a4cc4c0bfbdab4b726f3c78a74bb1900de0a6894da140f20e539298e`).
Adapted PNG SHA-256: `e0a683070903bee496df95212b6a473ea020e1c89ec6d45b10064cce3614a9ed`.
Changes: The complete whole grapefruit was cropped from a source photo also showing a separate cut half. Border-connected near-neutral white and pale cream studio background/shadow were masked; the rind’s chromatic photographed RGB detail was retained. Alpha-bound crop with 14 px padding, aspect-preserving LANCZOS resize to a 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white silhouette outline. No generative editing; public-domain source dedication retained.

## produce.quince

File: `assets/images/produce/quince_real.webp`
Photo author: Rhododendrites
Source: https://commons.wikimedia.org/wiki/File:Quince_(10889s).jpg
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Original: `artifacts/real-produce-batch3/originals/quince_rhododendrites.jpg` (SHA-256 `ee089c9aacfb46cd6279e7f0640a24ac8ad8f52e2b792bfd1016d44dcfd8dc2e`).
Adapted PNG SHA-256: `75a6f5a5c3f7fa087e24482f10fbc10beb9cff24f838800a749eefba9a81c786`.
Changes: Single complete photographed quince. Border-connected neutral studio backdrop and cast shadow were masked; original photographed RGB detail retained. Alpha-bound crop with 14 px padding, aspect-preserving LANCZOS resize to a 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white silhouette outline. No generative editing; adaptation shared under CC BY-SA 4.0.

## vehicles.car

File: `assets/images/vehicles/car_real.webp`
Photo author: Jackson2161
Source: https://commons.wikimedia.org/wiki/File:BMWcar.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Original: `artifacts/real-vehicle-car-candidate/originals/bmwcar_jackson2161.jpg` (SHA-256 `89b6c16f5072f657e2e413200bdcc02a0d9539126bfb646c0109b0692fa46094`).
Adapted PNG SHA-256: `{photo['sha256']}`.
Changes: Complete photographed sedan and both visible tires retained. Manually traced the outer silhouette and made the exterior background transparent; natural scene visible through car windows was preserved. Alpha-bound crop, 16 px padding, aspect-preserving 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white outline. No generative edits.

- `assets/images/produce/peach_real.webp` — Renee Comet (Photographer), National Cancer Institute; public domain by author dedication; source: https://commons.wikimedia.org/wiki/File:Peach_(1).jpg. Complete peach and attached leaf retained. Border-connected neutral-white background masked; original photo detail retained; alpha-bound crop, aspect-preserving resize, 1024x1024 RGBA export and approximately 4 px white outline. No generative editing. Original/output hashes are recorded in `assets/content/real_photo_manifest.json`.

- `assets/images/produce/coconut_real.webp` — Leiliane Dutra; Pexels License (<https://www.pexels.com/license/>); source: <https://www.pexels.com/photo/close-up-of-a-rough-coconut-on-a-surface-35788125/>. Pexels marks this photo free to use; the license permits modifications and app use, while prohibiting stock-photo redistribution and sale of unaltered copies. The complete photographed coconut was manually masked to remove the rail and background; source RGB detail retained; 1024x1024 RGBA export with a 4 px white contour. No generative edits. Hashes are in `assets/content/real_photo_manifest.json`.

## produce.pineapple

File: `assets/images/produce/pineapple_real.webp`
Photo author: Tony Wu
Source: https://www.pexels.com/photo/photo-of-an-pineapple-against-white-background-16814688/
Source and adaptation license: Pexels License — https://www.pexels.com/license/ (Pexels page labels this photo “Free to use”; modification and app use permitted).
Original: `artifacts/real-produce-pineapple-candidate/pineapple-original.jpg` (SHA-256 `2866c6c52fb654de2e5fecf37039c74a20d6b0b28dc0d4401d1a1a67e1773e5b`).
Adapted PNG SHA-256: `d2821a2ec4c0910bfd1189ba2c4bc8c9d051985f7be229c80a3cd44d5926cb7c`.
Changes: Single whole pineapple photographed against a white studio background. Edge-seeded near-white, low-chroma background flood-filled to transparency; a source-coordinate contour removes the floor/contact shadow while retaining the fruit base and crown leaf openings. Original RGB detail retained without repainting or reconstruction; aspect-preserving 910 px maximum extent, centered 1024x1024 RGBA export and approximately 4 px white silhouette outline. No generative editing. Reproducible processing script: `artifacts/real-produce-pineapple-candidate/process_pineapple.py`.

## produce.apricot

File: `assets/images/produce/apricot_real.webp`
Photo author: Benjamint444
Source: https://commons.wikimedia.org/wiki/File:Apricot_whole444.jpg
Source and adaptation license: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0/
Attribution: Benjamint444, “Apricot whole444.jpg,” Wikimedia Commons, CC BY-SA 3.0; include the source and license links and indicate the changes. The adapted PNG is shared under CC BY-SA 3.0.
Original: `artifacts/real-produce-apricot-fig-candidate/apricot_original.jpg` (SHA-256 `E89BFFF5F73E60F94A2028D11EFBC9C83385433D62017185A2C58449D7CEA66A`).
Adapted PNG SHA-256: `CF1AE7A349A422598302457543160DB485203A70F2A89F3777CF86DCC33913AD`.
Changes: Single whole photographed apricot on a white studio background. A smooth manually traced source-coordinate mask removes the background and lower studio/floor fringe while retaining the pale fruit rim and original photographed RGB detail. Aspect-preserving LANCZOS resize to an 870 px maximum extent, centered 1024x1024 RGBA export and approximately 4 px white outer silhouette. No generative edits. Reproducible processing script: `artifacts/real-produce-apricot-fig-candidate/process_apricot.py`.

## produce.artichoke

File: `assets/images/produce/artichoke_real.webp`
Photo author: Antonio Filigno
Source: https://www.pexels.com/photo/an-artichoke-on-a-green-surface-8538302/
Source and adaptation license: Pexels License — https://www.pexels.com/license/ (free use and modification, including app use).
Original: `artifacts/real-produce-artichoke-greenbean-candidate/originals/pexels-antonio-filigno-8538302.jpg` (SHA-256 `df959d287867887d1b3a8a23186df03e860e789ce844474b6251468033bd99fc`).
Changes: Single complete photographed artichoke with crown, side leaves, and cut stem retained. Classical OpenCV GrabCut refined a loose polygon from the existing hand-traced silhouette using protected interior foreground seeds and known green-background seeds (5 iterations, processing side capped at 1800 px). Original photographic RGB detail retained; largest connected object alpha-cropped, aspect-preserving resize to 900 px maximum extent, centered 1024x1024 RGBA export, and 4 px white outer contour. No generative edits or RGB reconstruction. Reproducible mask inputs, command, and hashes: `artifacts/photo-tools/artichoke-pilot/README.md`. Adapted PNG SHA-256: `8f45faa581b1a077523780d3505bdc046dcce4852c97a250a18e8d2f2f69ce9d`.

## produce.raspberry

File: `assets/images/produce/raspberry_real.webp`
Photo author: Ivar Leidus
Source: https://commons.wikimedia.org/wiki/File:Raspberry_-_whole_(Rubus_idaeus).jpg
Attribution: Ivar Leidus, “Raspberry - whole (Rubus idaeus).jpg,” Wikimedia Commons, CC BY-SA 4.0; include source and license links and indicate changes. The adapted PNG is shared under CC BY-SA 4.0.
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Original: `artifacts/real-produce-fig-raspberry-candidate/originals/raspberry-whole.jpg` (SHA-256 `71ac8acd0332ca50c4104d2c2cf96e953f3add685e4b79393a53e49e7f4f7fad`).
Adapted PNG SHA-256: `e0a30588f3dbfdd45f0210c67a12491557f1da39e99c89b640f26e7e4f2aacd9`.
Changes: Single whole photographed raspberry. Classical OpenCV GrabCut used a loose traced probable-foreground polygon, definite foreground seeds restricted to the red berry interior, and reviewed definite-background seeds in the backdrop wedges (5 iterations, processing side capped at 1800 px). Original photographic RGB detail retained; transparent exterior, alpha-bound crop, aspect-preserving resize to 900 px maximum extent, centered 1024x1024 RGBA export, and 4 px white outer contour. No generative edits or RGB reconstruction. Reproducible strategy and hashes: `artifacts/real-produce-fig-raspberry-candidate/SEED_STRATEGY.md`.

## vehicles.airplane

File: `assets/images/vehicles/airplane_real.webp`
Photo author: U.S. Air Force photo by TSgt Ben Bloker; transparent derivative by Kjetil r
Source: https://commons.wikimedia.org/wiki/File:Jagerfly.png
Original photograph: https://commons.wikimedia.org/wiki/File:Two_F-22A_Raptor_in_column_flight.jpg
Source and adaptation license: Public domain (PD-USGov; official-duty U.S. federal government photograph) — https://commons.wikimedia.org/wiki/Template:PD-USGov
Changes: Retained existing transparent photographic cutout and alpha by Kjetil r; alpha-bound crop (existing alpha bounds span the full source dimensions), aspect-preserving Lanczos resize to a 900 px maximum extent, centered 1024x1024 RGBA export and 4 px white outer contour. No new mask, background reconstruction, or generative editing.
Content review: Pending final human approval that this specific F-22 fighter aircraft is suitable for the generic catalog labels “Uçak” / “Airplane”.

## animals.dog

File: `assets/images/animals/dog_real.webp`
Photo author: Anton Porsche (Superanton)
Source: https://commons.wikimedia.org/wiki/File:Labradoodle-Brown-Transparent.png
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Retained the existing transparent photographic cutout and alpha; alpha-bound crop, aspect-preserving resize to 900 px maximum extent, centered 1024×1024 RGBA export and 4 px white contour derived from the existing alpha. No new segmentation or generative editing. Content review pending for the generic “Köpek” / “Dog” label.


## vehicles.helicopter

File: `assets/images/vehicles/helicopter_real.webp`
Photo: Iain Thomson; Crown Copyright, RAF / Defence Imagery. Transparent cutout derivative retouched by Offnfopt.
Source derivative: https://commons.wikimedia.org/wiki/File:Griffin-HT1-Helicopter.png
Original photograph: https://commons.wikimedia.org/wiki/File:A_Griffin_Helicopter,_with_an_underslung_load,_shown_in_silhouette_against_a_full_moon.jpg
License: Open Government Licence v1.0 — https://nationalarchives.gov.uk/doc/open-government-licence/version/1/
Attribution: Crown Copyright / Defence Imagery and Offnfopt; source and licence links are provided. Contains public sector information licensed under the Open Government Licence v1.0.
Changes: Retained the existing photographic transparent cutout and alpha; alpha-bound crop, aspect-preserving resize to 900 px maximum subject extent, centered 1024×1024 RGBA export and 4 px white contour. The source background/moon and suspended load were removed in the pre-existing cutout. No AI, generative edits, or rerendering. Human content review pending for the dark backlit style and generic “Helicopter” label. SHA-256: `a2948d19cdf008c76825b437123d35ff4120d4fa891bbf59276556648c55a279`.


## animals.bird

File: `assets/images/animals/bird_real.webp`
Photograph: David Raju, [Eurasian crag martin David Raju.jpg](https://commons.wikimedia.org/wiki/File:Eurasian_crag_martin_David_Raju.jpg).
Transparent derivative: Paolo Villa, [Eurasian crag martin David Raju (transparent background).png](https://commons.wikimedia.org/wiki/File:Eurasian_crag_martin_David_Raju_(transparent_background).png).
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/ . Attribute both creators and share this adaptation under CC BY-SA 4.0.
Changes: Paolo Villa’s existing derivative includes a color correction; its belly appears lighter than in the original JPEG. We retained the derivative alpha, cropped to its alpha bounds, resampled proportionally to a 900 px maximum extent, centered it on a 1024×1024 RGBA canvas, and added a 4 px white outer outline. No further RGB editing, background reconstruction, or generative processing was performed; RGB resampling occurred during resize. Final human approval of the generic “Kuş” / “Bird” label remains pending.
Adapted PNG SHA-256: `bfb9cfb2b73640d95a4fca628d9ad33665a1c90c280e7c39a9ddadf8b840f5f4`.

<!-- food-photos -->
## food.bread

File: `assets/images/food/bread_real.webp`
Photo author: User:Famartin
Source: https://commons.wikimedia.org/wiki/File:Transparent_Slice_of_Sara_Lee_white_whole_grain_bread_in_the_Franklin_Farm_section_of_Oak_Hill,_Fairfax_County,_Virginia.png
License: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `9032de473a3bfee90ae37d6228f6d6c4d3d3ca01b732dfa9b0b9a0d820b5a868`.
Adapted PNG SHA-256: `eaffa180ae2f655bec87274284b205b3dcc99a33293eb1be0ca900640159f7da`.
Attempt folder: `artifacts/food-photos-attempt-01/`. Local technical review only; final human approval pending.

## food.egg

File: `assets/images/food/egg_real.webp`
Photo author: User: MrX
Source: https://commons.wikimedia.org/wiki/File:Chicken_egg.png
License: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `cc9f522c07b07f3c64106d9b94e01efb538508da3a5512a1743242719cdb0fa0`.
Adapted PNG SHA-256: `15a4c8ad3ccb425177f783c644c7dfe011abf519890e4f5d2391a5f11aa0081f`.
Attempt folder: `artifacts/food-photos-attempt-01/`. Local technical review only; final human approval pending.

## food.cake

File: `assets/images/food/cake_real.webp`
Photo author: Tiia Monto
Source: https://commons.wikimedia.org/wiki/File:Cake_2.png
License: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `10cbe0a489628c7045e48fc9c5ee070f96a232cf7bcad87d835d4ece9e770d72`.
Adapted PNG SHA-256: `14c560269222febda8c85ec18f01d607735687fd9fec219a27952dec7375e5a4`.
Attempt folder: `artifacts/food-photos-attempt-01/`. Local technical review only; final human approval pending.

## food.cheese

File: `assets/images/food/cheese_real.webp`
Photo author: Tiia Monto
Source: https://commons.wikimedia.org/wiki/File:Mustaleima.png
License: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `0231f9a64f5b17ae35f361f852ae169bc02175be4ee1d0844f33468ab5edf98c`.
Adapted PNG SHA-256: `698050697a50ea9224806b3463ccb792c730e58e064da536c215bc1099c20d73`.
Attempt folder: `artifacts/food-photos-attempt-01/`. Local technical review only; final human approval pending.

## food.cookie

File: `assets/images/food/cookie_real.webp`
Photo author: User:Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Choc-Chip-Cookie.png
License: Public domain — https://commons.wikimedia.org/wiki/File:Choc-Chip-Cookie.png
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `d904d9b9de3ddb522aa130f407dd7e5a41e054b9b63f272f201711ce2a5cffba`.
Adapted PNG SHA-256: `3a27f3bc75ee5644c4c10dff76835e32e4fc86232a1e0d2b4e68dd18315d9067`.
Attempt folder: `artifacts/food-photos-attempt-01/`. Local technical review only; final human approval pending.

## food.ice_cream

File: `assets/images/food/ice_cream_real.webp`
Photo author: Tiia Monto
Source: https://commons.wikimedia.org/wiki/File:Jaffatuutti.png
License: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `9547bd7fb248a40bbd61f8bb309f42c662dd422fd79fec891b458dff3c03d7cc`.
Adapted PNG SHA-256: `18ec6f8d68d0b68c3706b8879e68dad2eaa3745a02e8a73ad2d9594aa013a64d`.
Attempt folder: `artifacts/food-photos-attempt-01/`. Local technical review only; final human approval pending.

## food.soup

File: `assets/images/food/soup_real.webp`
Photo author: Security (Pixabay)
Source: https://pixabay.com/photos/soup-cream-soup-tomatosoup-cook-622737/
Source and adaptation license: Pixabay Content License - https://pixabay.com/service/license-summary/
Original: `artifacts/photo-replacements-r47/soup/attempt-01/original.jpg` (SHA-256 `ab52cefa551074e246ddc9b08a61790e4f4ad151e30ba06da8fe9a3334bf8fb5`).
Adapted PNG SHA-256: `c9976eeb755a13e8c28a439397f9fed79e2968ceb0924c1666333f7ebc66dd5e`.
Changes: One white bowl of tomato soup with a sprig of parsley. Foreground alpha with rembg U2Net (largest region kept, holes filled, original RGB retained); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline (tools/adapt_cutout_photo.py). No generative editing.

## food.pasta

File: `assets/images/food/pasta_real.webp`
Photo author: Miroslavik (Pixabay)
Source: https://pixabay.com/photos/pasta-food-paste-nutrition-2197831/
Source and adaptation license: Pixabay Content License - https://pixabay.com/service/license-summary/
Original: `artifacts/photo-replacements-r46/pasta/attempt-2197831-b/original.jpg` (SHA-256 `9e4bdf73bd59675d75b49396817489bdbf7a7a5f939c1eb5c687b2493115c6dc`).
Adapted PNG SHA-256: `9bb26729084a1dae9962ddeb1525c28c0be2559abd08bf8cbb86f87fe75f3ac5`.
Changes: One heap of dry penne pasta on its own, no plate. Foreground alpha with rembg ISNet, near-white gaps between pieces cleared and tiny islands removed (original RGB retained); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline (tools/adapt_cutout_photo.py). No generative editing.

## food.pizza

File: `assets/images/food/pizza_real.webp`
Photo author: Florian838
Source: https://commons.wikimedia.org/wiki/File:Pizza_Quattro_Stagioni_transparent.png
License: CC0 — http://creativecommons.org/publicdomain/zero/1.0/deed.en
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `90a12f8a41d20a644a34160ed032fab7d9ccacb04b14568029e7559f6edf270f`.
Adapted PNG SHA-256: `628a42819e421ce20f05e43ca6334b4326a6039fc955ce2762d04789c59ea319`.
Attempt folder: `artifacts/food-photos-attempt-02/`. Local technical review only; final human approval pending.

## food.simit

File: `assets/images/food/simit_real.webp`
Photo author: Barbarossa (Wikimedia Commons user, "own picture"; GFDL relicensed to CC BY-SA 3.0)
Source: https://commons.wikimedia.org/wiki/File:Simit-2x.JPG
License: CC BY-SA 3.0 — http://creativecommons.org/licenses/by-sa/3.0/
Changes: Background removed with classical OpenCV GrabCut (rectangle start, largest component, 1 px feather; tools/grabcut_rect_mask.py), original photo pixels kept; alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `c05c2c115cbdfef54efe7c746355b4b5fab25dbeb5445856d7c6e595bbfd1d4a`.
Adapted PNG SHA-256: `3e537b228a13870768f0964aada11a5bea6444a2b72d24b23589804e06ae4719`.
Attempt folder: `artifacts/food-photos-attempt-03/`. Local technical review only; final human approval pending.

## vehicles.car (replacement, 20 October 2026)

File: `assets/images/vehicles/car_honda_real.webp`
Photo author: Rich Niewiroski Jr.
Source: https://commons.wikimedia.org/wiki/File:HondaS2000-004.png
License: CC BY 2.5 — https://creativecommons.org/licenses/by/2.5
Changes: Existing transparent cutout from Wikimedia Commons retained (no new mask); baked-in soft drop shadow removed (dark pixels with alpha < 200 cleared); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline.
Original SHA-256: `1a3cc5b8446ea405eb340c4fff29eba08d1c19f1298b703ab01dd147cd67bfc3`.
Adapted PNG SHA-256: `5641f0da98995d51480682b49fcfc0f15c6b0f631a244e1947e4ad97fd73a00d`.
Replaces the earlier small red sedan photo (kept on disk). Attempt folders: `artifacts/car-photo-attempt-01/` (shadow kept, rejected) and `-02/` (accepted). Local technical review only.

<!-- produce-photos-r32 -->
## produce.cucumber

File: `assets/images/produce/cucumber_real.webp`
Photo author: Pavlofox (Pixabay)
Source: https://pixabay.com/photos/cucumber-green-vegetable-long-845953/
Source and adaptation license: Pixabay Content License - https://pixabay.com/service/license-summary/
Changes: One whole cucumber, both tips visible. Foreground alpha with rembg U2Net (original RGB retained), alpha edge hardened (threshold and 1 px erode) so the white outline is crisp like the other photos; alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline. No generative editing.
Original SHA-256: `b397a79ef7f66e2f92ff01c484cb9e4b58495c9e4487e3867367df8776d97492`.
Adapted PNG SHA-256: `4b4bf4e11a621f8df0068e822ae0eb73d10a1de635250ba8a922de589dea2f09`.
Attempt folder: `artifacts/cucumber-r1/`. Replaces the earlier Commons photo (Yunus, 3 November 2026).

## produce.mandarin

File: `assets/images/produce/mandarin_real.webp`
Photo author: Saramukitza (Pixabay)
Source: https://pixabay.com/photos/mandarin-orange-clementines-fruit-1944930/
Source and adaptation license: Pixabay Content License - https://pixabay.com/service/license-summary/
Original: `artifacts/photo-replacements-r46/mandarin/attempt-1944930/original.jpg` (SHA-256 `7ddf238a2faa6a67128ba396f4be8da1aacfb1754cbff66a82d73a7d39512686`).
Adapted PNG SHA-256: `4fe041dbe2904cebb30abac702e89533b69554301b97621fa3416dbe9c4eaaed`.
Changes: One whole mandarin with a short stem and one green leaf. Foreground alpha with rembg U2Net (largest region kept, holes filled, original RGB retained); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline (tools/adapt_cutout_photo.py). No generative editing.

## produce.watermelon

File: `assets/images/produce/watermelon_1.webp`
Photo author: TBIT (Pixabay)
Source: https://pixabay.com/photos/melon-fruit-food-edible-yummy-943753/
Source and adaptation license: Pixabay Content License - https://pixabay.com/service/license-summary/
Original: `artifacts/photo-replacements-r46/watermelon/attempt-943753/original.jpg` (SHA-256 `23c4d0dac936aae92e821295e274501a50caef2caccf821e7c01244e8b95267c`).
Adapted PNG SHA-256: `ca895a1e0ebdc8cd835a56676276eb392ab098e83130586d96fb5570285bcabb`.
Changes: One thick watermelon wedge: red flesh, black seeds, striped green rind. Foreground alpha with rembg U2Net (largest region kept, holes filled, original RGB retained); alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline (tools/adapt_cutout_photo.py). No generative editing.

## produce.onion

File: `assets/images/produce/onion_real.webp`
Photo author: Colin
Source: https://commons.wikimedia.org/wiki/File:Onion_on_White.JPG
License: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0
Changes: Background removed with classical OpenCV GrabCut (rectangle start, largest component, 1 px feather), original photo pixels kept; alpha-bound crop, aspect-preserving Lanczos resize to a 912 px maximum subject extent, centered 1024x1024 RGBA export and 4 px white outer outline. Light grey floor shadow connected to the background cleared afterwards (HSV S < 0.24, V > 0.40), enclosed holes filled; a few shadow pixels by the root remain.
Original SHA-256: `78ece07db34835f12f21375fb5ba362036f74136dbe271d349d684ddace31009`.
Adapted PNG SHA-256: `8d8eb77e3fbf4e5d5eb992c200c7a93faea781108a44761872c0ab401e8e0fa4`.
Attempt folder: `artifacts/produce-photos-attempt-r32-03/`. Local technical review only; final human approval pending.
