"""Re-record specific clips until speech-to-text hears exactly the text.

    python -I tools/regenerate_voice_clips.py key [key ...]

At most MAX_TAKES generations per clip (deliberate, bounded); the first take
whose transcript matches is installed, otherwise the take with the fewest
extra characters. Every take is logged to artifacts/voice-check/regen_log.json
and the manifest entry is replaced with the installed take.
"""
import datetime
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_voice_stt as stt  # noqa: E402
import generate_selected_voice as gen  # noqa: E402

MAX_TAKES = 3
LOG = gen.ROOT / 'artifacts/voice-check/regen_log.json'


def main():
    key = os.environ['ELEVENLABS_API_KEY']
    manifest = gen.load_manifest()
    log = json.loads(LOG.read_text(encoding='utf-8')) if LOG.exists() else []
    for clip_key in sys.argv[1:]:
        clip = manifest['clips'][clip_key]
        job = {'lang': clip['language'], 'text': clip['text']}
        best = None
        for take in range(1, MAX_TAKES + 1):
            audio = gen.synthesize(job, key)
            tmp = gen.ROOT / 'artifacts/voice-check' / f'take_{clip_key.replace(":", "_")}_{take}.mp3'
            tmp.write_bytes(audio)
            heard = stt.stt(tmp, clip['language'], key)
            ok = stt.matches(clip['text'], heard, clip['language'])
            extra = abs(len(stt.norm(heard)) - len(stt.norm(clip['text'])))
            log.append({'key': clip_key, 'take': take, 'text': clip['text'], 'heard': heard, 'match': ok,
                        'file': tmp.relative_to(gen.ROOT).as_posix(), 'at': datetime.datetime.now().isoformat()})
            if best is None or ok or extra < best[1]:
                best = (tmp, extra, heard)
            if ok:
                break
        out = gen.ROOT / clip['path']
        out.write_bytes(best[0].read_bytes())
        clip.update(sha256=gen.sha256(out), bytes=out.stat().st_size,
                    requested_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    note=f'Re-recorded after STT check; installed take heard as {best[2]!r}.')
        print(clip_key, '->', best[2])
    gen.MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
    LOG.write_text(json.dumps(log, ensure_ascii=False, indent=1), encoding='utf-8')


if __name__ == '__main__':
    main()
