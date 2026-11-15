"""Read-only: recent crash and ANR issues from the Play Developer Reporting API.

    python tools/play_crashes.py [days]

Uses android/play-service-account.json (never printed). Lists the error
issues of the last days (default 7) with their version, counts and the top
of the stack, then the newest reports of each.
"""
import datetime
import sys
from pathlib import Path

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

ROOT = Path(__file__).resolve().parents[1]
KEY = ROOT / 'android' / 'play-service-account.json'
APP = 'apps/com.YeS.OzelEgitimOyunlari'
API = 'https://playdeveloperreporting.googleapis.com/v1beta1'


def main():
    days = int(sys.argv[1]) if len(sys.argv) > 1 else 7
    creds = service_account.Credentials.from_service_account_file(
        str(KEY), scopes=['https://www.googleapis.com/auth/playdeveloperreporting'])
    creds.refresh(Request())
    s = requests.Session()
    s.headers['Authorization'] = f'Bearer {creds.token}'
    end = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1)
    start = end - datetime.timedelta(days=days + 1)

    def stamp(d):
        return {'year': d.year, 'month': d.month, 'day': d.day}
    params = {
        'interval.startTime.year': start.year, 'interval.startTime.month': start.month, 'interval.startTime.day': start.day,
        'interval.endTime.year': end.year, 'interval.endTime.month': end.month, 'interval.endTime.day': end.day,
        'pageSize': 30,
    }
    r = s.get(f'{API}/{APP}/errorIssues:search', params=params)
    print('issues HTTP', r.status_code)
    if r.status_code >= 400:
        print(r.text[:600])
        return
    for issue in r.json().get('errorIssues', []):
        print('\n==', issue.get('type'), '|', issue.get('cause'), '|', issue.get('location'))
        print('   reports', issue.get('errorReportCount'), 'users', issue.get('distinctUsers'),
              'versions', issue.get('firstAppVersion', {}).get('versionCode'), '-', issue.get('lastAppVersion', {}).get('versionCode'),
              'last', issue.get('lastErrorReportTime'))
        rr = s.get(f'{API}/{APP}/errorReports:search', params={**params, 'filter': f'errorIssueId = {issue["name"].split("/")[-1]}', 'pageSize': 2})
        for rep in rr.json().get('errorReports', []):
            print('   --', rep.get('eventTime'), rep.get('appVersion', {}).get('versionCode'), rep.get('deviceModel', {}).get('marketingName'),
                  'android', rep.get('osVersion', {}).get('apiLevel'))
            print('\n'.join('      ' + line for line in rep.get('reportText', '').splitlines()[:45]))


if __name__ == '__main__':
    main()
