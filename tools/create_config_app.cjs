// Creates Firestore `config/app` with the app's current defaults so the owner
// can edit them in the Firebase console. Uses the logged-in Firebase CLI
// account (never prints the token). Refuses to overwrite an existing document.
//
//   node tools/create_config_app.cjs
const path = require('path');
const { execSync } = require('child_process');

const globalRoot = execSync('npm root -g').toString().trim();
const { requireAuth } = require(path.join(globalRoot, 'firebase-tools/lib/requireAuth'));
const { getAccessToken } = require(path.join(globalRoot, 'firebase-tools/lib/apiv2'));
const { getGlobalDefaultAccount } = require(path.join(globalRoot, 'firebase-tools/lib/auth'));

const project = 'specialeducationgames';
const defaults = require('../assets/config_defaults.json');

const str = (v) => ({ stringValue: v });
const int = (v) => ({ integerValue: String(v) });
const arr = (list) => ({ arrayValue: { values: list.map(str) } });
const map = (fields) => ({ mapValue: { fields } });

const fields = {
  freeGames: arr(defaults.freeGames),
  disabledGames: arr(defaults.disabledGames),
  hiddenThemes: arr(defaults.hiddenThemes),
  newBadge: arr([]),
  paywallText: map({}),
  trialDays: int(7),
  privacyUrl: str('https://yesastudio.com/ozel-egitim-oyunlari/privacy/'),
  termsUrl: str('https://yesastudio.com/ozel-egitim-oyunlari/terms/'),
  minSupportedVersion: int(0),
  difficultyDefaults: map({
    fadeAfterErrors: int(2),
    choiceCounts: map({ easy: int(2), medium: int(3), hard: int(4) }),
  }),
};

(async () => {
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('run firebase login first');
  await requireAuth({ project, user: account.user, tokens: account.tokens });
  const token = await getAccessToken();
  const url =
    `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/config/app` +
    '?currentDocument.exists=false';
  const res = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  const body = await res.json();
  if (!res.ok) {
    console.log('HTTP', res.status, body.error && body.error.status, body.error && body.error.message);
    process.exit(1);
  }
  console.log('created', body.name.split('/documents/')[1], Object.keys(body.fields).sort().join(','));
})().catch((e) => {
  console.log('failed:', e.message);
  process.exit(1);
});
