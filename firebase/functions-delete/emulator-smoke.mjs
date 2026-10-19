import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = 'demo-special-education-delete';
const expectedHosts = {
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099',
  FIRESTORE_EMULATOR_HOST: '127.0.0.1:8085',
};
assert.equal(process.env.GCLOUD_PROJECT, projectId, 'refusing non-demo project');
assert.equal(process.env.GOOGLE_CLOUD_PROJECT, projectId, 'refusing non-demo project');
assert.equal(process.env.ACCOUNT_DELETION_ENABLED, 'true', 'explicit emulator-only opt-in required');
for (const [name, value] of Object.entries(expectedHosts)) {
  assert.equal(process.env[name], value, `refusing non-loopback or unexpected ${name}`);
}

const base = `http://127.0.0.1:5001/${projectId}/us-central1/deleteFamilyAccount`;
const authApi = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts';
const app = initializeApp({ projectId }, `account-delete-smoke-${Date.now()}`);
const auth = getAuth(app);
const db = getFirestore(app);
const email = `delete-smoke-${Date.now()}@example.test`;
const password = 'Synthetic-Emulator-Only-8472';

async function signIn() {
  const response = await fetch(`${authApi}:signInWithPassword?key=emulator-api-key`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  assert.equal(response.status, 200, `Auth emulator sign-in failed (${response.status})`);
  return response.json();
}

async function call(token, data) {
  const headers = { 'content-type': 'application/json' };
  if (token) headers.authorization = `Bearer ${token}`;
  const response = await fetch(base, { method: 'POST', headers, body: JSON.stringify({ data }) });
  const text = await response.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = { raw: text };
  }
  return { status: response.status, body };
}

try {
  const created = await auth.createUser({ email, password, displayName: 'Synthetic delete smoke' });
  const uid = created.uid;
  const family = db.doc(`families/${uid}`);
  await family.set({ createdAt: new Date(), locale: 'en', updatedAt: new Date() });
  await family.collection('profiles').doc('synthetic-child').set({ marker: 'synthetic only' });
  await family.collection('profiles').doc('synthetic-child')
    .collection('sessions').doc('orphan-descendant').set({ marker: 'synthetic only' });
  await db.doc('families/unrelated-synthetic-family').set({ marker: 'must remain' });

  const signedIn = await signIn();
  assert.equal(signedIn.localId, uid);
  const invalidConfirmation = await call(signedIn.idToken, { confirmDelete: false });
  assert.equal(invalidConfirmation.status, 400, 'invalid confirmation should be rejected');
  assert.equal(invalidConfirmation.body.error.status, 'INVALID_ARGUMENT');
  assert.equal((await db.doc(`families/${uid}`).get()).exists, true, 'invalid request must not delete data');

  const unauthenticated = await call(null, { confirmDelete: true });
  assert.equal(unauthenticated.status, 401, 'missing auth should be rejected by callable middleware');

  const deleted = await call(signedIn.idToken, { confirmDelete: true });
  assert.equal(deleted.status, 200, `deletion failed: ${JSON.stringify(deleted.body)}`);
  assert.deepEqual(deleted.body.result, { deleted: true });
  assert.equal((await db.doc(`families/${uid}`).get()).exists, false);
  assert.equal((await db.doc(`families/${uid}/profiles/synthetic-child`).get()).exists, false);
  assert.equal((await db.doc(`families/${uid}/profiles/synthetic-child/sessions/orphan-descendant`).get()).exists, false);
  const lock = await db.doc(`deletionLocks/${uid}`).get();
  assert.equal(lock.get('status'), 'complete');
  assert.equal((await db.doc('families/unrelated-synthetic-family').get()).exists, true);
  await assert.rejects(auth.getUser(uid), error => error.code === 'auth/user-not-found');

  // Recreate the same synthetic UID to exercise an idempotent retry against the retained lock.
  await auth.createUser({ uid, email, password, displayName: 'Synthetic delete retry' });
  const retryToken = await signIn();
  assert.equal(retryToken.localId, uid);
  const retried = await call(retryToken.idToken, { confirmDelete: true });
  assert.equal(retried.status, 200, `retry failed: ${JSON.stringify(retried.body)}`);
  assert.deepEqual(retried.body.result, { deleted: true });
  assert.equal((await db.doc(`deletionLocks/${uid}`).get()).get('status'), 'complete');
  await assert.rejects(auth.getUser(uid), error => error.code === 'auth/user-not-found');

  console.log('PASS emulator smoke: callable auth/confirmation, recursive synthetic family deletion, retained lock, unrelated family, same-UID retry.');
  console.log('LIMIT: Auth emulator signs in at current time; this smoke does not exercise stale auth_time or production App Check attestation.');
} finally {
  await deleteApp(app);
}
