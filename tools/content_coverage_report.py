"""Read-only catalog coverage inventory; no downloads, generation or app writes."""
import hashlib
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative):
    return json.loads((ROOT / relative).read_text(encoding='utf-8-sig'))


def exists(path):
    return bool(path) and path.startswith('assets/') and '..' not in Path(path).parts and (ROOT / path).is_file()


def verified(entry, field='path'):
    path = entry.get(field)
    return exists(path) and hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == entry.get('sha256')


def main():
    themes = read('assets/content/themes.json')
    active = {theme['id'] for theme in themes if theme.get('active') is True}
    photos = {variant['path'] for entry in read('assets/content/real_photo_manifest.json')['assets']
              for variant in [entry, *entry.get('additionalVariants', [])]
              if variant.get('licenseVerified') is True and verified(variant)}
    voices = {entry['path'] for entry in read('assets/content/real_audio_manifest.json')['assets'] if verified(entry)}
    effects = {entry['asset'] for entry in read('assets/sfx/sources.json') if verified(entry, 'asset')}
    records = []
    counts = defaultdict(lambda: defaultdict(int))
    for file in sorted((ROOT / 'assets/content/items').glob('*.json')):
        for item in json.loads(file.read_text(encoding='utf-8-sig')):
            images = item.get('images', [])
            first = images[0] if images else None
            native = not images and item['theme'] in ('colors', 'numbers')
            tr = item.get('audio', {}).get('tr')
            en = item.get('audio', {}).get('en')
            same_audio = exists(tr) and exists(en) and (
                hashlib.sha256((ROOT / tr).read_bytes()).digest() ==
                hashlib.sha256((ROOT / en).read_bytes()).digest())
            record = dict(id=item['id'], theme=item['theme'], tier=item['tier'],
                          name=item['name'], activeTheme=item['theme'] in active,
                          availableVisual=exists(first) or native, nativeVisual=native,
                          verifiedLicensedPhoto=first in photos,
                          verifiedPhotoAssets=sum(1 for path in set(images) if path in photos and exists(path)),
                          imageNeedsReview=exists(first) and first not in photos,
                          audioTR=exists(item.get('audio', {}).get('tr')),
                          audioEN=exists(item.get('audio', {}).get('en')),
                          selectedVoiceTR=item.get('audio', {}).get('tr') in voices,
                          selectedVoiceEN=item.get('audio', {}).get('en') in voices,
                          duplicateLocaleAudio=same_audio,
                          differentLabelsSameAudio=same_audio and
                          item['name']['tr'].strip().casefold() != item['name']['en'].strip().casefold(),
                          licensedEffect=item.get('sfx') in effects)
            records.append(record)
            group = counts[f"{item['theme']}/{item['tier']}"]
            group['items'] += 1
            for key, value in record.items():
                if isinstance(value, bool):
                    group[key] += int(value)
            group['verifiedPhotoAssets'] += record['verifiedPhotoAssets']
    active_records = [record for record in records if record['activeTheme']]
    summary = {'items': len(active_records)}
    for key in ('availableVisual', 'nativeVisual', 'verifiedLicensedPhoto', 'imageNeedsReview',
                'audioTR', 'audioEN', 'selectedVoiceTR', 'selectedVoiceEN', 'licensedEffect',
                'duplicateLocaleAudio', 'differentLabelsSameAudio'):
        summary[key] = sum(record[key] for record in active_records)
    summary['verifiedPhotoAssets'] = sum(record['verifiedPhotoAssets'] for record in active_records)
    output = ROOT / 'artifacts/content_coverage'
    output.mkdir(parents=True, exist_ok=True)
    result = dict(activeThemes=sorted(active), totalCatalogItems=len(records),
                  activeSummary=summary, byThemeTier=dict(counts), items=records,
                  limitations=['Verified source/hash is not final human visual or listening approval.',
                               'Existing non-verified images/voices need rights and quality review.',
                               'Colors/numbers use native visuals; they do not require photographs.',
                               'File presence does not establish pronunciation, game eligibility or pedagogy.'])
    (output / 'coverage.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    lines = ['# İçerik kapsamı', '', 'Yalnız katalog ve dosya/manifest denetimidir; kullanıcı onayı veya tam oyun kabulü değildir.', '',
             '| Aktif tema / zorluk | Öğe | Görsel | Lisanslı fotoğraf | TR ses | EN ses | Lisanslı efekt |',
             '|---|---:|---:|---:|---:|---:|---:|']
    for key, group in sorted(counts.items()):
        if key.split('/')[0] in active:
            lines.append('| ' + key + ' | ' + ' | '.join(str(group[field]) for field in
                         ('items', 'availableVisual', 'verifiedLicensedPhoto', 'audioTR', 'audioEN', 'licensedEffect')) + ' |')
    lines += ['', f"TR/EN ses dosyası byte olarak aynı olan {summary['duplicateLocaleAudio']} aktif öğe var; "
              f"bunların {summary['differentLabelsSameAudio']} tanesinde Türkçe/İngilizce etiketler farklı. "
              'Dosya varlığı, doğru dilde konuşma hazır olduğu anlamına gelmez. Bu kayıtlar içerik incelemesi gerektirir.', '',
              f"Lisanslı fotoğraf sayısı öğe sayısından ayrıdır: aktif öğelerde {summary['verifiedLicensedPhoto']} ilk fotoğraflı öğe ve toplam {summary['verifiedPhotoAssets']} doğrulanmış fotoğraf dosyası bulunur.", '',
              'Renkler/sayılar yerel çizim kullanabilir. Diğer görsellerin hak/kalite incelemesi ve seslerin dinleme/telaffuz onayı ayrı kalır.', '',
              '## Aktif temalarda görseli eksik öğeler', '']
    lines += [f"- {record['id']} — {record['name']['tr']}" for record in active_records if not record['availableVisual']]
    lines += ['', 'Öğe bazlı TR/EN ve kaynak durumu: `coverage.json`. Yenilemek için `python tools/content_coverage_report.py`.']
    (output / 'README.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(json.dumps(summary))


if __name__ == '__main__':
    main()
