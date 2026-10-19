# Selected voice demonstration overrides

Fourteen existing vocabulary MP3 samples are reused without regeneration: cat,
dog, rabbit, apple, banana, red and three, each in Turkish and English. Turkish
uses İrem (`uvU9jrgGLWNPeNA4NgNT`); English uses Laura
(`GZ4PpFJV8ikEGUtBrjK7`). Model: `eleven_multilingual_v2`. Every vocabulary word
ends with a period. These are demonstrations of the selected voices; technical
validation does not establish user approval of pronunciation or authorize a
complete catalog regeneration.

`real_audio_manifest.json` records every item ID, language, exact spoken text,
voice/model/settings, sample/configuration SHA256, generation time interval and
source sample. Stability 0.35, similarity 0.75, style 0.43 and speed 1.0 are
estimates from sliders without numerical labels. Speaker boost was a tooling
default, not visible in the screenshot. Historical Lauren and Unity recordings
are retained. No key or API credential is bundled.

The six question/praise/retry samples remain in the original trial gallery:
there is no exact authoritative spoken-text mapping for legacy catalog prompts,
so their semantics are not assumed interchangeable.

To reproduce, run `python tools/install_selected_voice_samples.py` followed by
`python tools/build_content.py`. The installer makes no network/API calls and
does not read credentials. All twenty source files must match their recorded
SHA256, byte sizes and FFprobe stream/duration metadata before copying starts.
Selected filenames end in `_selected.mp3` in existing bundled language/theme
directories. Catalog generation should call `load_selected_audio(root)` from
the installer and prefer its `(item_id, language)` mapping before Unity copying;
its value's `path` is the bundled audio path. This validation rejects unknown
IDs/languages, duplicates, label or voice mismatch, unexpected filenames and
modified installed bytes. File licensing is not inferred from technical checks;
release rights remain subject to the owner's ElevenLabs account terms.
