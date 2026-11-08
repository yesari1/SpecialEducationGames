"""Lists Wikimedia Commons recordings with a free licence for a search term.

    python -I tools/home_sections/find_audio.py "<term>" ["<term>" ...]

Prints title, licence, author, duration and size; downloads nothing.
"""
import json
import re
import sys
import urllib.parse
import urllib.request

API = 'https://commons.wikimedia.org/w/api.php'
OK = re.compile(r'^(cc0|pd|public domain|cc[- ]by(-sa)?)', re.I)
HEADERS = {'User-Agent': 'SpecialEducationGamesAssetImport/1.0 (local educational app development)'}


def search(term):
    query = urllib.parse.urlencode({
        'action': 'query', 'format': 'json', 'generator': 'search', 'gsrnamespace': 6, 'gsrlimit': 40,
        'gsrsearch': f'filetype:audio {term}', 'prop': 'imageinfo', 'iiprop': 'url|extmetadata|size|mediatype',
    })
    with urllib.request.urlopen(urllib.request.Request(f'{API}?{query}', headers=HEADERS), timeout=45) as response:
        data = json.loads(response.read().decode('utf-8'))
    for page in (data.get('query', {}).get('pages', {}) or {}).values():
        info = page['imageinfo'][0]
        meta = info.get('extmetadata', {})
        licence = meta.get('LicenseShortName', {}).get('value', '')
        if not OK.match(licence) or page['title'].startswith(('File:LL-', 'File:En-', 'File:De-', 'File:Fr-')):
            continue
        author = re.sub(r'<[^>]+>', '', meta.get('Artist', {}).get('value', ''))[:40]
        yield round(info.get('duration') or 0, 1), info.get('size', 0), licence, author, page['title']


def main():
    for term in sys.argv[1:]:
        print(f'== {term}')
        for row in sorted(search(term), key=lambda r: (r[0] > 20, r[0]))[:14]:
            print(row)


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main()
