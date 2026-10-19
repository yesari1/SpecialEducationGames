# Real photo credits

Adaptations of real photographs, not generated images. Source licenses/public-domain dedications are retained. Processing preserves photographed detail through deterministic masking/crop/resize. The app also draws a white outline at display time.

## animals.cat

File: assets/images/animals/cat_real.png
Photo author: Matsu1024
Original background removal: YukiKoKo
Source: https://commons.wikimedia.org/wiki/File:Turkish_Van_cat_transparent.png
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Original transparent cutout retained; alpha-bound crop, aspect-preserving resize and padding. Enlarged to maximum 912 px photo extent, with a 4 px white silhouette outline (combined extent <=920 px, padding >=52 px).

## animals.fish

File: `assets/images/animals/fish_real.png` (the catalog keeps the legacy `fish_1.png` after this verified photo).
Original photograph: Ffish.asia, [ギンブナ DSC4346.jpg](https://commons.wikimedia.org/wiki/File:%E3%82%AE%E3%83%B3%E3%83%96%E3%83%8A_DSC4346.jpg), CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/.
Transparent derivative: Ellicrum, [Carassius auratus 2.png](https://commons.wikimedia.org/wiki/File:Carassius_auratus_2.png), CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/.
The fish is used for the generic catalog label “Fish”; it is not identified as a goldfish. The derivative's existing transparency was retained. Adaptation: alpha-bound crop, aspect-preserving 912 px maximum extent, centered 1024×1024 RGBA export and 4 px white outer outline. No new mask or generative editing. The adapted PNG is shared under CC BY-SA 4.0, with both creators attributed and source/license links retained.
Original derivative SHA-256: `cc695c641b89bd859d1f1a1f4521dae08a9296acf9565f769bbba0e23ba30357`.
Adapted PNG SHA-256: `89dc0d8586a0ed232b8617901e916075d64f22be404e08bd4e2ab5b5bb18c0e5`.

## animals.fish — variant 2

File: `assets/images/animals/fish_trout_real.png`
Photograph: Allan Harris, [iNaturalist photo 14650939](https://www.inaturalist.org/photos/14650939), CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/.
Commons source-file contributor: Lodewicus de Honsvels; [source photo file](https://commons.wikimedia.org/wiki/File:Salvelinus_namaycush_-_Amerikanischer_Seesaibling_14650939.jpg).
Transparent derivative and crop: Ellicrum, [Salvelinus namaycush.png](https://commons.wikimedia.org/wiki/File:Salvelinus_namaycush.png), CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/.
Attribution: Allan Harris (photograph), Lodewicus de Honsvels (Commons source-file contributor), and Ellicrum (transparent derivative). Indicate changes and keep the adaptation under CC BY-SA 4.0.
Input derivative: `artifacts/legacy-alpha-source-r13/Salvelinus_namaycush.png` (SHA-256 `41da55b4c37e55fe5f214f1b108db3ef0b981575b2be54088d5820057d7792d4`).
Adapted PNG SHA-256: `501e15f0f6fdac5620e512f6e3771d5265ad52d86d61c39976726dff0ba98bc8`.
Changes: Second distinct generic fish photo, a Lake Trout (`Salvelinus namaycush`). Existing transparent alpha and photo RGB retained; alpha-bound crop, aspect-preserving Lanczos resize to 900 px maximum fish extent, centered 1024×1024 RGBA export, and 4 px white outline. No new mask, generative edits, or reconstructed detail. Soft edge pixels from the source cutout remain beneath the outline. Local technical approval is recorded; final human approval is still pending.

## animals.turtle

File: assets/images/animals/turtle_real.png
Photo author: Katrin Bolovtsova
Source: https://www.pexels.com/photo/photo-of-a-turtle-5263883/
Source and adaptation license: Pexels License — https://www.pexels.com/license/ (free app use and modification under the license terms).
Original: `artifacts/real-animal-turtle-elephant-candidate/alternative-plain-turtle/originals/pexels-5263883.jpg` (6602×4401; SHA-256 `85ac585743ff0b4ec54b3e21d402cad73b3081d2da9bc85ef8c05ee14cb10761`).
Adapted PNG SHA-256: `5e5ae81a9968aa151b9be8973bf7c44d4dfff95215944a2d250ebf3ac082b676`.
Changes: Classical OpenCV GrabCut used the reviewed source contour, central-shell and visible-head/forelimb foreground seeds, and background seeds (5 iterations at 1800×1200). Original RGB detail retained without repainting; aspect-preserving resize and centering on a 1024×1024 RGBA canvas, with a 4 px white outer outline. Rear limbs and tail are naturally tucked beneath the shell in the source photograph. No generative edits. Reproducible helper inputs and report are retained in `artifacts/real-animal-turtle-elephant-candidate/alternative-plain-turtle/mask2/`.

## produce.apple

File: assets/images/produce/apple_real.png
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Honeycrisp-Apple.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.avocado

File: assets/images/produce/avocado_real.png
Photo author: Tiia Monto
Source: https://commons.wikimedia.org/wiki/File:Avocado.png
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Decoded pixel RGBA checked identical after lossless96dpi working-copy normalization (prevents GDI DrawImageUnscaled physical-size clipping). Existing source transparency retained where present; border-connected neutral white otherwise removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.

## produce.banana

File: assets/images/produce/banana_real.png
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Banana-Single.jpg
Source and adaptation license: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.kiwi

File: assets/images/produce/kiwi_real.png
Photo author: Boris Stumpf
Source: https://commons.wikimedia.org/wiki/File:Whole_kiwifruit_on_white_background.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Decoded pixel RGBA checked identical after lossless96dpi working-copy normalization (prevents GDI DrawImageUnscaled physical-size clipping). Existing source transparency retained where present; border-connected neutral white otherwise removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.

## produce.lemon

File: assets/images/produce/lemon_real.png
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Whole-Lemon.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.melon

File: assets/images/produce/melon_real.png
Photo author: Tiia Monto
Source: https://commons.wikimedia.org/wiki/File:Galia_melon.jpg
Source and adaptation license: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0/
Changes: Decoded pixel RGBA checked identical after lossless96dpi working-copy normalization (prevents GDI DrawImageUnscaled physical-size clipping). Existing source transparency retained where present; border-connected neutral white otherwise removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.

## produce.orange

File: assets/images/produce/orange_real.png
Photo author: Renee Comet (Photographer), National Cancer Institute
Source: https://commons.wikimedia.org/wiki/File:Orange_(1).jpg
Source and adaptation license: Public domain — https://creativecommons.org/publicdomain/mark/1.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.pepper

File: assets/images/produce/pepper_real.png
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Green-Bell-Pepper.jpg
Source and adaptation license: Public domain — https://commons.wikimedia.org/wiki/Commons:Copyright_tags#Public_domain
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.tomato

File: assets/images/produce/tomato_real.png
Photo author: Renee Comet (Photographer), National Cancer Institute
Source: https://commons.wikimedia.org/wiki/File:Tomato_(1).jpg
Source and adaptation license: Public domain — https://creativecommons.org/publicdomain/mark/1.0/
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.zucchini

File: assets/images/produce/zucchini_real.png
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Zucchini-Whole.jpg
Source and adaptation license: Public domain — https://commons.wikimedia.org/wiki/Commons:Copyright_tags#Public_domain
Changes: Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; disconnected background specks discarded retaining largest silhouette; original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.

## produce.leek

File: assets/images/produce/leek_real.png
Photo author: Amada44
Source: https://commons.wikimedia.org/wiki/File:Leek_on_white_background_-_0947.jpg
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Decoded RGBA identity checked after lossless96dpi metadata normalization. Near-white neutral background alpha-keyed (minimum RGB249, channel difference<=8), including enclosed leaf gaps; photographed white stem retained. Largest silhouette retained, proportional912px resize, centered1024x1024 RGBA and4px white silhouette outline. Foreground photographic RGB retained without repainting or generative edits.


## produce.pear

File: assets/images/produce/pear_real.png
Photo author: Fructibus
Source: https://commons.wikimedia.org/wiki/File:Conference_pear_2017_D1.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Complete pear; source background and cast shadow masked. Original photographed RGB detail retained; transparent exterior created by masking, alpha-bound crop, aspect-preserving resize to a maximum 912 px, centered 1024x1024 RGBA export, and 4 px white silhouette contour. No generative editing.
Original file: artifacts/real-produce-next/source/pear.jpg (SHA-256 `934f71fc0c22a32e90d6c90b797e56cec28545c98643fdbc7231ced2d81c1888`).
Adapted PNG SHA-256: `76ab1a1f8e7a6f3e63f019c11becefeffebc86624e38ccc48d2466798c550665`.

## produce.plum

File: assets/images/produce/plum_real.png
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Red-Plums.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Changes: Selected the complete whole plum from the left of the source photo; cut half excluded with crop (35, 210, 1785, 1830) in original-image pixels; border-connected background and cast shadow masked. Original photographed RGB detail retained; transparent exterior created by masking, alpha-bound crop, aspect-preserving resize to a maximum 912 px, centered 1024x1024 RGBA export, and 4 px white silhouette contour. No generative editing.
Original file: artifacts/real-produce-next/source/plum.jpg (SHA-256 `9bd1763236d1617f8ac7642a813badd320158942378ca54a4cd94d9f99ad312b`).
Adapted PNG SHA-256: `bd6126f09422d7e986a78611bb1ae14ed469c5ee2ee32658c9e5c9280bc3904d`.

## produce.strawberry

File: `assets/images/produce/strawberry_real.png`
Photo author: Paolo Neo
Source: https://commons.wikimedia.org/wiki/File:Strawberry_fruit.jpg
Source and adaptation license: Public domain (author dedication) — https://commons.wikimedia.org/wiki/File:Strawberry_fruit.jpg
Original: `artifacts/real-produce-batch2/originals/strawberry_paolo_neo.jpg` (SHA-256 `9baa5005b6f8885cf4729122476f40dfb57875718fdaf12ed447af6be97f7fa0`).
Adapted PNG SHA-256: `a8013b3c44d9f61648fa52a0f6a2856a03f5825e513b3acd27731333f6f1aea3`.
Changes: Single complete photographed strawberry with calyx. Border-connected near-white background and the two locally bounded background gaps between leaves were made transparent; photographed RGB detail retained. Alpha-bound crop with 1.2% padding, aspect-preserving LANCZOS resize to 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white silhouette outline. No generative editing.

## produce.pomegranate

File: `assets/images/produce/pomegranate_real.png`
Photo author: Rhododendrites
Source: https://commons.wikimedia.org/wiki/File:Pomegranate_on_white.jpg
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Original: `artifacts/real-produce-batch2/originals/pomegranate_rhododendrites.jpg` (SHA-256 `19bf770bb8af0b5251dbab9871f4fc949b7f97017f4c67798e8ae4dfda73dcd1`).
Adapted PNG SHA-256: `c5fc4cfa293972f43ea1b5ae4ca64876ac82efe9cab70a8190534a25b3c0f357`.
Changes: Single complete photographed pomegranate and crown. A traced closed Catmull-Rom perimeter, refined by red-rind chroma masking on the body, excludes the neutral studio background and cast shadow while retaining crown detail. Original photographed RGB detail retained; alpha-bound crop with 1.2% padding, aspect-preserving LANCZOS resize to 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white silhouette outline. No generative editing; adaptation shared under CC BY-SA 4.0.

## produce.grapefruit

File: `assets/images/produce/grapefruit_real.png`
Photo author: Evan-Amos
Source: https://commons.wikimedia.org/wiki/File:Grapefruit-Whole-%26-Split.jpg
Source and adaptation license: Public domain — https://creativecommons.org/publicdomain/mark/1.0/
Original: `artifacts/real-produce-batch3/originals/grapefruit_evan_amos.jpg` (SHA-256 `c06202e0a4cc4c0bfbdab4b726f3c78a74bb1900de0a6894da140f20e539298e`).
Adapted PNG SHA-256: `b8ed19cd92802e4495669f16b9520c297ba5532233ef0e7a316b8afb8ed2241f`.
Changes: The complete whole grapefruit was cropped from a source photo also showing a separate cut half. Border-connected near-neutral white and pale cream studio background/shadow were masked; the rind’s chromatic photographed RGB detail was retained. Alpha-bound crop with 14 px padding, aspect-preserving LANCZOS resize to a 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white silhouette outline. No generative editing; public-domain source dedication retained.

## produce.quince

File: `assets/images/produce/quince_real.png`
Photo author: Rhododendrites
Source: https://commons.wikimedia.org/wiki/File:Quince_(10889s).jpg
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Original: `artifacts/real-produce-batch3/originals/quince_rhododendrites.jpg` (SHA-256 `ee089c9aacfb46cd6279e7f0640a24ac8ad8f52e2b792bfd1016d44dcfd8dc2e`).
Adapted PNG SHA-256: `8c122b336cec59ac853f65955a9c7e507467d4c4b578a1621888b0dc29bbf0fe`.
Changes: Single complete photographed quince. Border-connected neutral studio backdrop and cast shadow were masked; original photographed RGB detail retained. Alpha-bound crop with 14 px padding, aspect-preserving LANCZOS resize to a 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white silhouette outline. No generative editing; adaptation shared under CC BY-SA 4.0.

## vehicles.car

File: `assets/images/vehicles/car_real.png`
Photo author: Jackson2161
Source: https://commons.wikimedia.org/wiki/File:BMWcar.jpg
Source and adaptation license: CC0 1.0 — https://creativecommons.org/publicdomain/zero/1.0/
Original: `artifacts/real-vehicle-car-candidate/originals/bmwcar_jackson2161.jpg` (SHA-256 `89b6c16f5072f657e2e413200bdcc02a0d9539126bfb646c0109b0692fa46094`).
Adapted PNG SHA-256: `{photo['sha256']}`.
Changes: Complete photographed sedan and both visible tires retained. Manually traced the outer silhouette and made the exterior background transparent; natural scene visible through car windows was preserved. Alpha-bound crop, 16 px padding, aspect-preserving 912 px maximum extent, centered 1024x1024 RGBA export and 4 px white outline. No generative edits.

- `assets/images/produce/peach_real.png` — Renee Comet (Photographer), National Cancer Institute; public domain by author dedication; source: https://commons.wikimedia.org/wiki/File:Peach_(1).jpg. Complete peach and attached leaf retained. Border-connected neutral-white background masked; original photo detail retained; alpha-bound crop, aspect-preserving resize, 1024x1024 RGBA export and approximately 4 px white outline. No generative editing. Original/output hashes are recorded in `assets/content/real_photo_manifest.json`.

- `assets/images/produce/coconut_real.png` — Leiliane Dutra; Pexels License (<https://www.pexels.com/license/>); source: <https://www.pexels.com/photo/close-up-of-a-rough-coconut-on-a-surface-35788125/>. Pexels marks this photo free to use; the license permits modifications and app use, while prohibiting stock-photo redistribution and sale of unaltered copies. The complete photographed coconut was manually masked to remove the rail and background; source RGB detail retained; 1024x1024 RGBA export with a 4 px white contour. No generative edits. Hashes are in `assets/content/real_photo_manifest.json`.

## produce.pineapple

File: `assets/images/produce/pineapple_real.png`
Photo author: Tony Wu
Source: https://www.pexels.com/photo/photo-of-an-pineapple-against-white-background-16814688/
Source and adaptation license: Pexels License — https://www.pexels.com/license/ (Pexels page labels this photo “Free to use”; modification and app use permitted).
Original: `artifacts/real-produce-pineapple-candidate/pineapple-original.jpg` (SHA-256 `2866c6c52fb654de2e5fecf37039c74a20d6b0b28dc0d4401d1a1a67e1773e5b`).
Adapted PNG SHA-256: `9178f4c95b0a93aeaf60fd165c3229bb94888356e27ef740be0b08bfeaaed6a4`.
Changes: Single whole pineapple photographed against a white studio background. Edge-seeded near-white, low-chroma background flood-filled to transparency; a source-coordinate contour removes the floor/contact shadow while retaining the fruit base and crown leaf openings. Original RGB detail retained without repainting or reconstruction; aspect-preserving 910 px maximum extent, centered 1024x1024 RGBA export and approximately 4 px white silhouette outline. No generative editing. Reproducible processing script: `artifacts/real-produce-pineapple-candidate/process_pineapple.py`.

## produce.apricot

File: `assets/images/produce/apricot_real.png`
Photo author: Benjamint444
Source: https://commons.wikimedia.org/wiki/File:Apricot_whole444.jpg
Source and adaptation license: CC BY-SA 3.0 — https://creativecommons.org/licenses/by-sa/3.0/
Attribution: Benjamint444, “Apricot whole444.jpg,” Wikimedia Commons, CC BY-SA 3.0; include the source and license links and indicate the changes. The adapted PNG is shared under CC BY-SA 3.0.
Original: `artifacts/real-produce-apricot-fig-candidate/apricot_original.jpg` (SHA-256 `E89BFFF5F73E60F94A2028D11EFBC9C83385433D62017185A2C58449D7CEA66A`).
Adapted PNG SHA-256: `CF1AE7A349A422598302457543160DB485203A70F2A89F3777CF86DCC33913AD`.
Changes: Single whole photographed apricot on a white studio background. A smooth manually traced source-coordinate mask removes the background and lower studio/floor fringe while retaining the pale fruit rim and original photographed RGB detail. Aspect-preserving LANCZOS resize to an 870 px maximum extent, centered 1024x1024 RGBA export and approximately 4 px white outer silhouette. No generative edits. Reproducible processing script: `artifacts/real-produce-apricot-fig-candidate/process_apricot.py`.

## produce.artichoke

File: `assets/images/produce/artichoke_real.png`
Photo author: Antonio Filigno
Source: https://www.pexels.com/photo/an-artichoke-on-a-green-surface-8538302/
Source and adaptation license: Pexels License — https://www.pexels.com/license/ (free use and modification, including app use).
Original: `artifacts/real-produce-artichoke-greenbean-candidate/originals/pexels-antonio-filigno-8538302.jpg` (SHA-256 `df959d287867887d1b3a8a23186df03e860e789ce844474b6251468033bd99fc`).
Changes: Single complete photographed artichoke with crown, side leaves, and cut stem retained. Classical OpenCV GrabCut refined a loose polygon from the existing hand-traced silhouette using protected interior foreground seeds and known green-background seeds (5 iterations, processing side capped at 1800 px). Original photographic RGB detail retained; largest connected object alpha-cropped, aspect-preserving resize to 900 px maximum extent, centered 1024x1024 RGBA export, and 4 px white outer contour. No generative edits or RGB reconstruction. Reproducible mask inputs, command, and hashes: `artifacts/photo-tools/artichoke-pilot/README.md`. Adapted PNG SHA-256: `5e033925045f0f4662202dfffea424913f9dd9050a23eed17e49b59cd771141c`.

## produce.raspberry

File: `assets/images/produce/raspberry_real.png`
Photo author: Ivar Leidus
Source: https://commons.wikimedia.org/wiki/File:Raspberry_-_whole_(Rubus_idaeus).jpg
Attribution: Ivar Leidus, “Raspberry - whole (Rubus idaeus).jpg,” Wikimedia Commons, CC BY-SA 4.0; include source and license links and indicate changes. The adapted PNG is shared under CC BY-SA 4.0.
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Original: `artifacts/real-produce-fig-raspberry-candidate/originals/raspberry-whole.jpg` (SHA-256 `71ac8acd0332ca50c4104d2c2cf96e953f3add685e4b79393a53e49e7f4f7fad`).
Adapted PNG SHA-256: `80552a2cc6e7ac868c02f222dd9df59a4c9f6382078e69c115a510a639b15564`.
Changes: Single whole photographed raspberry. Classical OpenCV GrabCut used a loose traced probable-foreground polygon, definite foreground seeds restricted to the red berry interior, and reviewed definite-background seeds in the backdrop wedges (5 iterations, processing side capped at 1800 px). Original photographic RGB detail retained; transparent exterior, alpha-bound crop, aspect-preserving resize to 900 px maximum extent, centered 1024x1024 RGBA export, and 4 px white outer contour. No generative edits or RGB reconstruction. Reproducible strategy and hashes: `artifacts/real-produce-fig-raspberry-candidate/SEED_STRATEGY.md`.

## vehicles.airplane

File: `assets/images/vehicles/airplane_real.png`
Photo author: U.S. Air Force photo by TSgt Ben Bloker; transparent derivative by Kjetil r
Source: https://commons.wikimedia.org/wiki/File:Jagerfly.png
Original photograph: https://commons.wikimedia.org/wiki/File:Two_F-22A_Raptor_in_column_flight.jpg
Source and adaptation license: Public domain (PD-USGov; official-duty U.S. federal government photograph) — https://commons.wikimedia.org/wiki/Template:PD-USGov
Changes: Retained existing transparent photographic cutout and alpha by Kjetil r; alpha-bound crop (existing alpha bounds span the full source dimensions), aspect-preserving Lanczos resize to a 900 px maximum extent, centered 1024x1024 RGBA export and 4 px white outer contour. No new mask, background reconstruction, or generative editing.
Content review: Pending final human approval that this specific F-22 fighter aircraft is suitable for the generic catalog labels “Uçak” / “Airplane”.

## animals.dog

File: `assets/images/animals/dog_real.png`
Photo author: Anton Porsche (Superanton)
Source: https://commons.wikimedia.org/wiki/File:Labradoodle-Brown-Transparent.png
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/
Changes: Retained the existing transparent photographic cutout and alpha; alpha-bound crop, aspect-preserving resize to 900 px maximum extent, centered 1024×1024 RGBA export and 4 px white contour derived from the existing alpha. No new segmentation or generative editing. Content review pending for the generic “Köpek” / “Dog” label.


## vehicles.helicopter

File: `assets/images/vehicles/helicopter_real.png`
Photo: Iain Thomson; Crown Copyright, RAF / Defence Imagery. Transparent cutout derivative retouched by Offnfopt.
Source derivative: https://commons.wikimedia.org/wiki/File:Griffin-HT1-Helicopter.png
Original photograph: https://commons.wikimedia.org/wiki/File:A_Griffin_Helicopter,_with_an_underslung_load,_shown_in_silhouette_against_a_full_moon.jpg
License: Open Government Licence v1.0 — https://nationalarchives.gov.uk/doc/open-government-licence/version/1/
Attribution: Crown Copyright / Defence Imagery and Offnfopt; source and licence links are provided. Contains public sector information licensed under the Open Government Licence v1.0.
Changes: Retained the existing photographic transparent cutout and alpha; alpha-bound crop, aspect-preserving resize to 900 px maximum subject extent, centered 1024×1024 RGBA export and 4 px white contour. The source background/moon and suspended load were removed in the pre-existing cutout. No AI, generative edits, or rerendering. Human content review pending for the dark backlit style and generic “Helicopter” label. SHA-256: `f2e2d5342dbb6fb6eedd0b8273a005f5003e56da3e4d503d53fce744e68e9ba5`.


## animals.bird

File: `assets/images/animals/bird_real.png`
Photograph: David Raju, [Eurasian crag martin David Raju.jpg](https://commons.wikimedia.org/wiki/File:Eurasian_crag_martin_David_Raju.jpg).
Transparent derivative: Paolo Villa, [Eurasian crag martin David Raju (transparent background).png](https://commons.wikimedia.org/wiki/File:Eurasian_crag_martin_David_Raju_(transparent_background).png).
Source and adaptation license: CC BY-SA 4.0 — https://creativecommons.org/licenses/by-sa/4.0/ . Attribute both creators and share this adaptation under CC BY-SA 4.0.
Changes: Paolo Villa’s existing derivative includes a color correction; its belly appears lighter than in the original JPEG. We retained the derivative alpha, cropped to its alpha bounds, resampled proportionally to a 900 px maximum extent, centered it on a 1024×1024 RGBA canvas, and added a 4 px white outer outline. No further RGB editing, background reconstruction, or generative processing was performed; RGB resampling occurred during resize. Final human approval of the generic “Kuş” / “Bird” label remains pending.
Adapted PNG SHA-256: `951f45f39ef962649c49828c16a18e89ff3c7e2209ef87076f9f5e343ea1b288`.
