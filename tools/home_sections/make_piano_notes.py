"""Makes the eight notes of the toy piano (Sen de Çal, G75).

    python -I tools/home_sections/make_piano_notes.py

Writes assets/sfx/piano/<do|re|mi|fa|sol|la|si|do2>.mp3: a soft piano-like
tone built from decaying harmonics (made here, no outside source), C4 to C5,
about 1.3 seconds each, every note at the same loudness.
"""
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/sfx/piano'
NOTES = {'do': 261.63, 're': 293.66, 'mi': 329.63, 'fa': 349.23, 'sol': 392.00, 'la': 440.00, 'si': 493.88, 'do2': 523.25}
RATE = 44100


def tone(f0, seconds=1.3):
    t = np.arange(int(RATE * seconds)) / RATE
    out = np.zeros_like(t)
    for k in range(1, 10):
        # A stiff string: partials a touch sharp, the high ones die first.
        f = f0 * k * (1 + .0004 * k * k)
        amp = 1 / k ** 1.5 * (0.6 if k % 2 == 0 else 1)
        for detune in (-.6, .6):
            out += amp * np.exp(-t * (2.2 + .9 * k)) * np.sin(2 * np.pi * (f + detune) * t)
    # The hammer: a very short soft knock.
    out += .25 * np.exp(-t * 90) * np.sin(2 * np.pi * f0 * 4.1 * t)
    attack = np.minimum(1, t / .006)
    release = np.minimum(1, (seconds - t) / .08)
    out *= attack * release
    return out / np.max(np.abs(out)) * .85


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, f0 in NOTES.items():
            wav = Path(tmp) / f'{name}.wav'
            data = (tone(f0) * 32767).astype('<i2')
            with wave.open(str(wav), 'wb') as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(RATE)
                w.writeframes(data.tobytes())
            subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(wav),
                            '-ar', '44100', '-ac', '1', '-b:a', '96k', str(OUT / f'{name}.mp3')], check=True)
    print('notes:', ', '.join(NOTES))


if __name__ == '__main__':
    main()
