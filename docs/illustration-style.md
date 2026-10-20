# Illustration style ("SEG soft clay")

Decision (Yunus, 20 October 2026): designed parts of the app (onboarding art, headers/hero scenes, survey option pictures, decorative icons) use AI-generated **illustrations** made with ChatGPT image generation, all in this one style. Game content (the animals, fruit, vehicles, food the child learns) stays **real, licensed photos** from free libraries with recorded source/author/license. Never mix the two inside one screen group: onboarding is illustration-only.

Every illustration request sends the **master prompt** below plus one asset prompt. Generated files, prompts and dates are recorded in `assets/illustrations/MANIFEST.json`.

## Look

- Soft 2.5D "clay / vinyl toy" illustration: rounded, chunky, friendly shapes with gentle volume, soft ambient-occlusion shading and one soft top-left light. No hard outlines, no black strokes, no texture noise.
- Palette (from `lib/app/theme/tokens.dart`): warm orange #FF8A32 (accent), sky blue #63C6F4, primary blue #1687D9, turquoise #10B7B0, sunny yellow #FFC546, soft pink #E76F8E, lavender #7C73DF, leaf green #6CC66B, cream #FFF6EA. Colours are clear but a step softer than toy-box saturation; at most 3-4 main colours per picture.
- Calm and low-stimulation: one clear subject (or a small, tidy group for scenes), lots of breathing room, no busy patterns, no glitter, no motion lines, no flashing effects.
- Child-friendly faces only where a character is the subject: simple dot eyes, small smile, no scary or exaggerated expressions. No humans' realistic faces, no brands or logos.
- Background: **transparent** (alpha) for icons/option pictures; hero scenes may use a soft pastel sky-to-cream gradient that fades to the app canvas (#FFFEFC) at the edges.
- No text, letters or numbers inside images unless the asset prompt asks for a numeral (numbers theme), then use rounded bold numerals only.
- Square 1024×1024 for icons/options (subject centred, about 10% margin, nothing cropped); hero 1536×1024.

## Master prompt (prefix of every request)

```
Create an illustration in the "SEG soft clay" style for a calm educational app for young children (2-8) including children with autism and special needs.
Style: soft 2.5D clay / vinyl-toy look, rounded chunky friendly shapes, gentle volume with soft ambient-occlusion shading, one soft light from the top left, no outlines, no black strokes, no texture noise, no glitter, no motion lines.
Palette: warm orange #FF8A32, sky blue #63C6F4, blue #1687D9, turquoise #10B7B0, sunny yellow #FFC546, soft pink #E76F8E, lavender #7C73DF, leaf green #6CC66B, cream #FFF6EA; clear but slightly soft, at most 3-4 main colours.
Calm, low-stimulation composition with lots of empty space, one clear subject, centred, fully inside the frame with ~10% margin, nothing cropped.
No text, no letters, no logos, no watermark. Transparent background unless told otherwise.
```

## Asset prompts

See `docs/illustration-prompts.md` (one block per asset, each with its output path). The same file is ready to paste into ChatGPT by hand.
