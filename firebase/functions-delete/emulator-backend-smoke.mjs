// Backend-only emulator test. Calling .run() deliberately bypasses callable
// HTTP middleware; this does not test verified tokens or App Check enforcement.
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { deleteFamilyAccount } from './index.mjs';

const projectId = 'demo-special-education-delete';
assert.equal(process.env.GCLOUD_PROJECT, projectId, 'refusing non-demo project');
assert.equal(process.env.GOOGLE_CLOUD_PROJECT, projectId, 'refusing non-demo project');
assert.equal(process.env.ACCOUNT_DELETION_ENABLED, 'true', 'explicit emulator-only opt-in required');
assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9099', 'refusing non-loopback Auth host');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8085', 'refusing non-loopback Firestore host');

const app = initializeApp({ projectId }, `account-delete-backend-smoke-${Date.now()}`);
const auth = getAuth(app);
const db = getFirestore(app);
const uid = `delete-smoke-${Date.now()}`;
const email = `${uid}@example.test`;
const password = 'Synthetic-Emulator-Only-8472';
const currentSeconds = Math.floor(Date.now() / 1000);

function syntheticRequest(authTime = currentSeconds, data = { confirmDelete: true }) {
  // This shape exercises handler logic only. It is not an SDK-verified JWT or App Check proof.
  return { auth: { uid, token: { auth_time: authTime, uid, sub: uid } }, data };
}

try {
  await auth.createUser({ uid, email, password, displayName: 'Synthetic backend smoke' });
  const family = db.doc(`families/${uid}`);
  await family.set({ createdAt: new Date(), locale: 'en', updatedAt: new Date() });
  await family.collection('profiles').doc('synthetic-child').set({ marker: 'synthetic only' });
  await family.collection('profiles').doc('synthetic-child')
    .collection('sessions').doc('orphan-descendant').set({ marker: 'synthetic only' });
  await db.doc('families/unrelated-synthetic-family').set({ marker: 'must remain' });

  await assert.rejects(deleteFamilyAccount.run(syntheticRequest(currentSeconds - 301)),
    error => error.code === 'failed-precondition');
  await assert.rejects(deleteFamilyAccount.run(syntheticRequest(currentSeconds, { confirmDelete: false })),
    error => error.code === 'invalid-argument');
  assert.equal((await family.get()).exists, true, 'invalid contexts must not delete family data');
  assert.equal((await db.doc(`deletionLocks/${uid}`).get()).exists, false, 'invalid contexts must not create a lock');

  const first = await deleteFamilyAccount.run(syntheticRequest());
  assert.deepEqual(first, { deleted: true });
  assert.equal((await db.doc(`families/${uid}`).get()).exists, false);
  assert.equal((await db.doc(`families/${uid}/profiles/synthetic-child`).get()).exists, false);
  assert.equal((await db.doc(`families/${uid}/profiles/synthetic-child/sessions/orphan-descendant`).get()).exists, false);
  const lock = db.doc(`deletionLocks/${uid}`);
  assert.equal((await lock.get()).get('status'), 'complete');
  assert.equal((await db.doc('families/unrelated-synthetic-family').get()).exists, true);
  await assert.rejects(auth.getUser(uid), error => error.code === 'auth/user-not-found');

  // Recreate the synthetic identity with the same UID to exercise provider retry behavior.
  await auth.createUser({ uid, email, password, displayName: 'Synthetic backend retry' });
  const retry = await deleteFamilyAccount.run(syntheticRequest());
  assert.deepEqual(retry, { deleted: true });
  assert.equal((await lock.get()).get('status'), 'complete');
  await assert.rejects(auth.getUser(uid), error => error.code === 'auth/user-not-found');

  console.log('PASS backend-only emulator smoke: production handler, Auth/Firestore emulator cleanup, retained lock, unrelated family, same-UID retry.');
  console.log('LIMIT: direct .run() supplies synthetic auth context and skips callable middleware; no real App Check or verified recent-auth proof.');
} finally {
  await deleteApp(app);
}
