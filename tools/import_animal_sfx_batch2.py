"""Reproduce two natural Commons SFX; preserve existing sound credits/assets.

Python stdlib + ffmpeg/ffprobe. Downloads only the two named public originals
and source pages; reruns reuse stored originals. No synthesis or paid API.
The MP3 adaptations retain each source's listed license.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BATCH = ROOT / 'artifacts/sfx_batch2'
SOURCES = [
    dict(slug='sheep', title='Sheep_bleat.ogg', author='Eviatar Bach',
         source='https://commons.wikimedia.org/wiki/File:Sheep_bleat.ogg',
         originalUrl='https://upload.wikimedia.org/wikipedia/commons/2/28/Sheep_bleat.ogg',
         license='CC0-1.0', licenseUrl='https://creativecommons.org/publicdomain/zero/1.0/',
         sourceRevision='https://commons.wikimedia.org/w/index.php?title=File:Sheep_bleat.ogg&oldid=1222010622',
         expectedOriginalSha256='0b58fb9fc4c2e5f1b71fd0a769cfcc580991b0a19f731293a43ddc0f5ab4b5a3',
         description='Sheep bleat, Maan Farms, Abbotsford, British Columbia, Canada; own work, 9 October 2011.',
         duration=0.481814058956916),
    dict(slug='duck', title='Anas_platyrhynchos_-_Mallard_-_XC62258.ogg',
         author='Jonathon Jongsma',
         source='https://commons.wikimedia.org/wiki/File:Anas_platyrhynchos_-_Mallard_-_XC62258.ogg',
         originalUrl='https://upload.wikimedia.org/wikipedia/commons/f/fa/Anas_platyrhynchos_-_Mallard_-_XC62258.ogg',
         license='CC-BY-SA-3.0', licenseUrl='https://creativecommons.org/licenses/by-sa/3.0/',
         sourceRevision='https://commons.wikimedia.org/w/index.php?title=File:Anas_platyrhynchos_-_Mallard_-_XC62258.ogg&oldid=1272207943',
         expectedOriginalSha256='8a42ac12fc1dad2096366722b52f4bd17bf8175c90f791e04b01b93f99d4faa3',
         description='Mallard (Anas platyrhynchos), quack sequence; Powderhorn Park, Minneapolis; 14 September 2010. Xeno-canto 62258, Commons license reviewed 29 March 2020.',
         duration=2.9),
]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fetch(url, destination):
    if destination.exists():
        return
    request = urllib.request.Request(url, headers={
        'User-Agent': 'SpecialEducationGamesAssetImport/1.0 (local educational app development)',
    })
    with urllib.request.urlopen(request, timeout=45) as response:
        destination.write_bytes(response.read())


def execute(command):
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    return result.stdout, result.stderr


def metrics(stderr):
    return json.loads(re.findall(r'\{\s*"input_i".*?\}', stderr, re.S)[-1])


def main():
    BATCH.mkdir(parents=True, exist_ok=True)
    records = []
    evidence = []
    previous = json.loads((ROOT / 'assets/sfx/sources.json').read_text(encoding='utf-8-sig'))
    preserved = [record for record in previous if record['itemId'] not in ['animals.sheep', 'animals.duck']]
    preserved_hashes = {record['asset']: sha(ROOT / record['asset']) for record in preserved}
    version = execute(['ffmpeg', '-version'])[0].splitlines()[0]
    for source in SOURCES:
        slug = source['slug']
        original = BATCH / source['title']
        fetch(source['originalUrl'], original)
        if sha(original) != source['expectedOriginalSha256']:
            raise RuntimeError('Original recording differs from reviewed Commons revision: ' + slug)
        fetch(source['source'], BATCH / f'{slug}-source.html')
        output = ROOT / f'assets/sfx/animals/{slug}.mp3'
        output.parent.mkdir(parents=True, exist_ok=True)
        duration = source['duration']
        # Downmix/resample and fade BEFORE both loudness passes, so the measured
        # signal is the exact signal being normalized. No denoising/reconstruction.
        base = (f'atrim=duration={duration},asetpts=PTS-STARTPTS,'
                f'aformat=sample_rates=44100:channel_layouts=mono,'
                f'afade=t=in:d=0.04,afade=t=out:st={duration - .08}:d=0.08')
        first = ['ffmpeg', '-hide_banner', '-i', str(original), '-af',
                 base + ',loudnorm=I=-24:TP=-6:LRA=7:print_format=json', '-f', 'null', '-']
        _, log = execute(first)
        (BATCH / f'{slug}-pass1.log').write_text(log, encoding='utf-8')
        measured = metrics(log)
        normalization = ('loudnorm=I=-24:TP=-6:LRA=7:linear=true:print_format=json'
                         f":measured_I={measured['input_i']}:measured_TP={measured['input_tp']}"
                         f":measured_LRA={measured['input_lra']}:measured_thresh={measured['input_thresh']}"
                         f":offset={measured['target_offset']}")
        second = ['ffmpeg', '-hide_banner', '-y', '-i', str(original), '-af',
                  base + ',' + normalization, '-ar', '44100', '-ac', '1',
                  '-map_metadata', '-1', '-b:a', '96k', str(output)]
        _, log = execute(second)
        (BATCH / f'{slug}-pass2.log').write_text(log, encoding='utf-8')
        probe = json.loads(execute(['ffprobe', '-v', 'error', '-show_format', '-show_streams',
                                    '-of', 'json', str(output)])[0])
        _, log = execute(['ffmpeg', '-hide_banner', '-i', str(output), '-af',
                          'loudnorm=I=-24:TP=-6:LRA=7:print_format=json', '-f', 'null', '-'])
        (BATCH / f'{slug}-final-measurement.log').write_text(log, encoding='utf-8')
        final = metrics(log)
        stream = probe['streams'][0]
        assert stream['codec_name'] == 'mp3' and stream['channels'] == 1
        assert int(stream['sample_rate']) == 44100
        assert float(probe['format']['duration']) <= 3
        assert abs(float(final['input_i']) + 24) <= 1.0
        assert float(final['input_tp']) <= -5.9
        changes = ('Converted to mono 44.1 kHz 96 kbps MP3; two-pass normalization '
                   'target -24 LUFS / -6 dBTP; 40 ms fade-in and 80 ms fade-out; '
                   + ('whole 0.482-second source retained.' if slug == 'sheep'
                      else 'first 2.9 seconds selected from 3.465-second source.'))
        records.append(dict(itemId=f'animals.{slug}', asset=output.relative_to(ROOT).as_posix(),
                            title=source['title'], author=source['author'], source=source['source'],
                            license=source['license'], licenseUrl=source['licenseUrl'], changes=changes,
                            originalSha256=sha(original), sha256=sha(output)))
        evidence.append(dict(**source, originalSha256=sha(original), sha256=sha(output),
                             sourcePageSha256=sha(BATCH / f'{slug}-source.html'),
                             probe=probe, finalMeasurement=final,
                             commands=[first, second],
                             subjectiveListening='Not performed: this agent has no auditory audition tool. Source metadata verifies species; user approval pending.'))
    assert all(sha(ROOT / asset) == digest for asset, digest in preserved_hashes.items())
    (ROOT / 'assets/sfx/sources.json').write_text(
        json.dumps(preserved + records, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (BATCH / 'evidence.json').write_text(json.dumps(dict(
        ffmpeg=version, preservedAssetHashes=preserved_hashes, records=evidence),
        ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Imported 2 natural recordings; previous credits and asset hashes preserved.')
    for entry in evidence:
        print(entry['slug'], entry['probe']['format']['duration'],
              entry['finalMeasurement']['input_i'], entry['finalMeasurement']['input_tp'])


if __name__ == '__main__':
    main()
