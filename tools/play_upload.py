"""Google Play internal testing through the Play Developer API.

Key: android/play-service-account.json (git-ignored, Yunus, 21 October 2026).

  python tools/play_upload.py check
      Read-only: lists the releases on every track, then discards the edit.
  python tools/play_upload.py upload GooglePlayBuild/<bundle>.aab "notes TR" "notes EN"
      Uploads the bundle and rolls it out to the internal testing track.
      Only bundles that passed tools/build_release.sh belong here.
"""
import sys
from pathlib import Path

import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

ROOT = Path(__file__).resolve().parents[1]
KEY = ROOT / 'android' / 'play-service-account.json'
PACKAGE = 'com.YeS.OzelEgitimOyunlari'
API = f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}'
UPLOAD = f'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}'


def session():
    creds = service_account.Credentials.from_service_account_file(
        str(KEY), scopes=['https://www.googleapis.com/auth/androidpublisher'])
    creds.refresh(Request())
    s = requests.Session()
    s.headers['Authorization'] = f'Bearer {creds.token}'
    return s


def ok(r):
    if r.status_code >= 400:
        try:
            err = r.json().get('error', {})
            print('HTTP', r.status_code, err.get('status'), err.get('message'))
        except ValueError:
            print('HTTP', r.status_code)
        sys.exit(1)
    return r.json() if r.content else {}


def tracks(s, edit):
    for t in ok(s.get(f'{API}/edits/{edit}/tracks')).get('tracks', []):
        for rel in t.get('releases', []):
            print(f"{t['track']}: {rel.get('status')} versionCodes={rel.get('versionCodes')} name={rel.get('name')}")


def check():
    s = session()
    edit = ok(s.post(f'{API}/edits'))['id']
    try:
        tracks(s, edit)
    finally:
        s.delete(f'{API}/edits/{edit}')
    print('OK: key works (nothing was changed)')


def upload(aab, notes_tr, notes_en):
    s = session()
    edit = ok(s.post(f'{API}/edits'))['id']
    committed = False
    try:
        with open(aab, 'rb') as f:
            bundle = ok(s.post(
                f'{UPLOAD}/edits/{edit}/bundles?uploadType=media',
                data=f, headers={'Content-Type': 'application/octet-stream'},
                timeout=1800))
        code = bundle['versionCode']
        print('uploaded versionCode', code)
        ok(s.put(f'{API}/edits/{edit}/tracks/internal', json={
            'track': 'internal',
            'releases': [{
                'versionCodes': [str(code)],
                'status': 'completed',
                'releaseNotes': [
                    {'language': 'tr-TR', 'text': notes_tr},
                    {'language': 'en-US', 'text': notes_en},
                ],
            }],
        }))
        ok(s.post(f'{API}/edits/{edit}:commit'))
        committed = True
        print('OK: versionCode', code, 'is live on internal testing')
    finally:
        if not committed:
            s.delete(f'{API}/edits/{edit}')


if __name__ == '__main__':
    if sys.argv[1:2] == ['check']:
        check()
    elif sys.argv[1:2] == ['upload'] and len(sys.argv) == 5:
        upload(*sys.argv[2:5])
    else:
        print(__doc__)
        sys.exit(2)
