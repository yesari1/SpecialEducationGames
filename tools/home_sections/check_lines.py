"""Listens to the new clips with ElevenLabs speech-to-text and lists mismatches.

    python -I tools/home_sections/check_lines.py

Report: artifacts/voice-check/home_sections_stt.json. A clip is only sent once
for its sha256. The API key comes from ELEVENLABS_API_KEY and is never printed.
"""
import concurrent.futures
import importlib.util
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'tools/home_sections/voice_manifest.json'
REPORT = ROOT / 'artifacts/voice-check/home_sections_stt.json'
spec = importlib.util.spec_from_file_location('check_voice_stt', ROOT / 'tools/check_voice_stt.py')
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)


def main():
    key = os.environ['ELEVENLABS_API_KEY']
    clips = json.loads(MANIFEST.read_text(encoding='utf-8'))
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    report = json.loads(REPORT.read_text(encoding='utf-8')) if REPORT.exists() else {}
    todo = [(p, c) for p, c in clips.items() if report.get(p, {}).get('sha256') != c['sha256']]
    print(f'{len(todo)} clips', flush=True)

    def one(pair):
        path, clip = pair
        heard = tool.stt(ROOT / path, clip['language'], key)
        return path, {'sha256': clip['sha256'], 'expected': clip['text'], 'heard': heard,
                      'match': tool.matches(clip['text'], heard, clip['language'])}

    with concurrent.futures.ThreadPoolExecutor(4) as pool:
        for path, result in pool.map(one, todo):
            report[path] = result
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding='utf-8')
    bad = {p: r for p, r in report.items() if not r['match']}
    print(len(report), 'checked,', len(bad), 'differ')
    out = REPORT.with_name('home_sections_stt_differs.txt')
    out.write_text('\n'.join(f"{p}\n  beklenen: {r['expected']}\n  duyulan:  {r['heard']}" for p, r in sorted(bad.items())), encoding='utf-8')


if __name__ == '__main__':
    main()
