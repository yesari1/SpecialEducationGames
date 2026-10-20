"""List Wikimedia Commons PNG candidates with alpha for catalog items.

Read-only research helper: queries the Commons API, keeps PNG files whose
license is free (CC0 / public domain / CC BY / CC BY-SA) and writes the
candidates with author, license and source URLs to a JSON file for review.
No image is accepted automatically; see AGENTS.md photo rules.

    python -I tools/find_commons_cutouts.py food.bread:bread food.egg:egg ... --out artifacts/photo_search/food.json
"""
import json
import sys
import time
import urllib.parse
import urllib.error
import urllib.request

API = 'https://commons.wikimedia.org/w/api.php'
UA = 'SpecialEducationGames-photo-research/1.0 (owner: 1yesari1 project; contact via Commons)'
FREE = ('cc0', 'public domain', 'pd', 'cc by', 'cc-by')


def api(params):
    params = {**params, 'format': 'json', 'formatversion': '2'}
    request = urllib.request.Request(API + '?' + urllib.parse.urlencode(params), headers={'User-Agent': UA})
    for wait in (0, 20, 60):
        time.sleep(wait)
        try:
            with urllib.request.urlopen(request, timeout=40) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code != 429:
                raise
    raise RuntimeError('Commons kept rate limiting')


MIME = 'image/png'


def search(term, limit=25):
    data = api({
        'action': 'query', 'generator': 'search', 'gsrnamespace': 6, 'gsrlimit': limit,
        'gsrsearch': f'{term} filemime:{MIME}',
        'prop': 'imageinfo', 'iiprop': 'url|size|extmetadata|mime', 'iiurlwidth': 300,
    })
    results = []
    for page in data.get('query', {}).get('pages', []):
        info = (page.get('imageinfo') or [{}])[0]
        meta = info.get('extmetadata', {})
        license_name = meta.get('LicenseShortName', {}).get('value', '')
        if not any(word in license_name.lower() for word in FREE):
            continue
        if 'nc' in license_name.lower().replace('cc', ''):
            continue
        results.append({
            'title': page['title'],
            'width': info.get('width'), 'height': info.get('height'),
            'url': info.get('url'), 'thumb': info.get('thumburl'),
            'page': info.get('descriptionurl'),
            'license': license_name,
            'licenseUrl': meta.get('LicenseUrl', {}).get('value', ''),
            'artist': meta.get('Artist', {}).get('value', ''),
            'credit': meta.get('Credit', {}).get('value', ''),
        })
    return results


def main():
    global MIME
    args = sys.argv[1:]
    out = args[args.index('--out') + 1]
    if '--jpeg' in args:
        MIME = 'image/jpeg'
    pairs = [a for a in args if ':' in a and not a.startswith('--')]
    found = {}
    for pair in pairs:
        item, term = pair.split(':', 1)
        seen, rows = set(), []
        queries = ((f'{term} white background', f'{term} isolated') if MIME == 'image/jpeg'
                   else (f'{term} transparent background', f'{term} isolated'))
        for query in queries:
            for row in search(query):
                if row['title'] not in seen and (row['width'] or 0) >= 500:
                    seen.add(row['title'])
                    rows.append(row)
            time.sleep(3)
        found[item] = rows
        print(item, len(rows), flush=True)
    with open(out, 'w', encoding='utf-8') as handle:
        json.dump(found, handle, ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
