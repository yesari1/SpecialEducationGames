// Sets only `freeGames` in Firestore `config/app` to the list in
// assets/config_defaults.json (Learn + two games per theme, 5 November 2026).
// Every other field of the document stays as it is. Uses the logged-in
// Firebase CLI account (never prints the token). The document must exist.
//
//   node tools/update_config_free_games.cjs
const path = require('path');
const { execSync } = require('child_process');

const globalRoot = execSync('npm root -g').toString().trim();
const { requireAuth } = require(path.join(globalRoot, 'firebase-tools/lib/requireAuth'));
const { getAccessToken } = require(path.join(globalRoot, 'firebase-tools/lib/apiv2'));
const { getGlobalDefaultAccount } = require(path.join(globalRoot, 'firebase-tools/lib/auth'));

const project = 'specialeducationgames';
const { freeGames } = require('../assets/config_defaults.json');

(async () => {
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('run firebase login first');
  await requireAuth({ project, user: account.user, tokens: account.tokens });
  const token = await getAccessToken();
  const url =
    `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/config/app` +
    '?currentDocument.exists=true&updateMask.fieldPaths=freeGames';
  const res = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      fields: {
        freeGames: { arrayValue: { values: freeGames.map((v) => ({ stringValue: v })) } },
      },
    }),
  });
  const body = await res.json();
  if (!res.ok) {
    console.log('HTTP', res.status, body.error && body.error.status, body.error && body.error.message);
    process.exit(1);
  }
  const saved = body.fields.freeGames.arrayValue.values.map((v) => v.stringValue);
  console.log('updated config/app.freeGames:', saved.length, saved.join(','));
})().catch((e) => {
  console.log('failed:', e.message);
  process.exit(1);
});
