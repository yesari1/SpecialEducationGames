import test from 'node:test';
import assert from 'node:assert/strict';
import { createDeleteAccount } from './delete-account.mjs';

const seconds = 1_800_000_000;
function request(overrides = {}) {
  return { auth: { uid: 'owner_1', token: { auth_time: seconds, sub: 'owner_1' } },
    data: { confirmDelete: true }, ...overrides };
}
function fixture({ documents = [], cleanupError, authError, beginError, completeError } = {}) {
  const calls = [];
  const remaining = new Set(documents);
  let identityExists = true;
  const locks = new Map();
  const firestore = {
    doc(path) { calls.push(['doc', path]); return { path }; },
    async recursiveDelete(ref) {
      calls.push(['recursiveDelete', ref.path]);
      const failure = typeof cleanupError === 'function' ? cleanupError() : cleanupError;
      if (failure) throw failure;
      for (const path of remaining) if (path === ref.path || path.startsWith(`${ref.path}/`)) remaining.delete(path);
    },
  };
  const auth = { async deleteUser(uid) {
    calls.push(['deleteUser', uid]);
    if (authError) throw authError;
    if (!identityExists) throw { code: 'auth/user-not-found' };
    identityExists = false;
  } };
  return { calls, remaining, locks, identityExists: () => identityExists,
    run: createDeleteAccount({ firestore, auth, now: () => seconds * 1000,
      async beginDeletion(uid) {
        calls.push(['beginDeletion', uid]);
        if (beginError) throw beginError;
        if (!locks.has(uid)) locks.set(uid, { status: 'pending' });
      },
      async completeDeletion(uid) {
        calls.push(['completeDeletion', uid]);
        if (completeError) throw completeError;
        locks.get(uid).status = 'complete';
      },
    }) };
}
test('deletes only authenticated family recursively, including missing-parent orphans, then identity', async () => {
  const f = fixture({ documents: ['families/owner_1/profiles/missing/sessions/a',
    'families/owner_1/profiles/p/rawTrials/x', 'families/other/profiles/p',
    'families/owner_10/profiles/p', 'config/app', 'admins/owner_1'] });
  assert.deepEqual(await f.run(request()), { deleted: true });
  assert.deepEqual(f.calls, [['beginDeletion', 'owner_1'], ['doc', 'families/owner_1'],
    ['recursiveDelete', 'families/owner_1'], ['deleteUser', 'owner_1'], ['completeDeletion', 'owner_1']]);
  assert.deepEqual([...f.remaining], ['families/other/profiles/p', 'families/owner_10/profiles/p', 'config/app', 'admins/owner_1']);
  assert.equal(f.identityExists(), false);
  assert.deepEqual(f.locks.get('owner_1'), { status: 'complete' });
});
test('cleanup failure never deletes the identity, and sanitizes backend details', async () => {
  const f = fixture({ cleanupError: Error('private payload/path/token') });
  await assert.rejects(f.run(request()), e => e.code === 'unavailable' && !e.message.includes('private'));
  assert.equal(f.identityExists(), true);
  assert.equal(f.calls.some(([kind]) => kind === 'deleteUser'), false);
  assert.deepEqual(f.locks.get('owner_1'), { status: 'pending' });
});
test('retries are idempotent when identity is already missing', async () => {
  const f = fixture();
  await f.run(request());
  assert.deepEqual(await f.run(request()), { deleted: true });
  assert.deepEqual(f.locks.get('owner_1'), { status: 'complete' });
});
test('other Auth errors are failures after data cleanup, without private SDK details', async () => {
  const f = fixture({ authError: { code: 'auth/internal-error', message: 'private token' } });
  await assert.rejects(f.run(request()), e => e.code === 'unavailable' && !e.message.includes('private'));
  assert.equal(f.identityExists(), true);
  assert.equal(f.calls.at(-1)[0], 'deleteUser');
  assert.deepEqual(f.locks.get('owner_1'), { status: 'pending' });
});
test('marker setup failure prevents all recursive cleanup and Auth deletion', async () => {
  const f = fixture({ beginError: Error('private marker failure') });
  await assert.rejects(f.run(request()), { code: 'unavailable' });
  assert.deepEqual(f.calls, [['beginDeletion', 'owner_1']]);
  assert.equal(f.identityExists(), true);
  assert.equal(f.locks.size, 0);
});
test('completion marker failure keeps the tombstone after Auth deletion', async () => {
  const f = fixture({ completeError: Error('private completion failure') });
  await assert.rejects(f.run(request()), e => e.code === 'unavailable' && !e.message.includes('private'));
  assert.equal(f.identityExists(), false);
  assert.deepEqual(f.locks.get('owner_1'), { status: 'pending' });
  assert.equal(f.calls.at(-1)[0], 'completeDeletion');
});
test('retry after interrupted cleanup reuses pending marker and finishes deletion', async () => {
  let failuresRemaining = 1;
  const f = fixture({ documents: ['families/owner_1/profiles/p/sessions/a'],
    cleanupError: () => failuresRemaining-- > 0 ? Error('interrupted') : null });
  await assert.rejects(f.run(request()), { code: 'unavailable' });
  const marker = f.locks.get('owner_1');
  assert.equal(marker.status, 'pending');
  assert.equal(f.identityExists(), true);
  await f.run(request());
  assert.equal(f.locks.get('owner_1'), marker);
  assert.equal(marker.status, 'complete');
  assert.equal(f.remaining.size, 0);
  assert.equal(f.identityExists(), false);
});
test('unauthenticated calls have zero backend effects', async () => {
  const f = fixture();
  await assert.rejects(f.run(request({ auth: null })), { code: 'unauthenticated' });
  assert.deepEqual(f.calls, []);
});
test('client UID/path selectors and missing explicit confirmation are denied before cleanup', async () => {
  for (const data of [null, {}, [], { confirmDelete: false }, { confirmDelete: true, uid: 'other' },
    { confirmDelete: true, path: 'families/other' }, { confirmDelete: true, auth: { uid: 'other' } }]) {
    const f = fixture();
    await assert.rejects(f.run(request({ data })), { code: 'invalid-argument' });
    assert.deepEqual(f.calls, []);
  }
});
test('invalid identity/path and mismatched verified token identities are denied', async () => {
  for (const auth of [{ uid: '../other', token: { auth_time: seconds } },
    { uid: 'x/profiles', token: { auth_time: seconds } }, { uid: '', token: { auth_time: seconds } },
    { uid: 'x'.repeat(129), token: { auth_time: seconds } },
    { uid: 'owner_1', token: { auth_time: seconds, sub: 'other' } },
    { uid: 'owner_1', token: { auth_time: seconds, uid: 'other' } }]) {
    const f = fixture();
    await assert.rejects(f.run(request({ auth })), { code: 'permission-denied' });
    assert.deepEqual(f.calls, []);
  }
});
test('requires real recent login auth_time, not fresh token iat or client body claim', async () => {
  for (const auth_time of [undefined, 0, seconds - 301, seconds + 1, String(seconds), NaN, Infinity, seconds - 0.5]) {
    const f = fixture();
    await assert.rejects(f.run(request({ auth: { uid: 'owner_1', token: { auth_time, iat: seconds } } })),
      { code: 'failed-precondition' });
    assert.deepEqual(f.calls, []);
  }
  const f = fixture();
  await f.run(request({ auth: { uid: 'owner_1', token: { auth_time: seconds - 300 } } }));
});
test('provider draft is disabled before Admin initialization', async () => {
  const previous = process.env.ACCOUNT_DELETION_ENABLED;
  try {
    delete process.env.ACCOUNT_DELETION_ENABLED;
    const { getApps } = await import('firebase-admin/app');
    const { deleteFamilyAccount } = await import('./index.mjs');
    const count = getApps().length;
    // .run bypasses HTTP/SDK token and App Check middleware; this tests only the opt-in gate.
    await assert.rejects(deleteFamilyAccount.run(request()), { code: 'failed-precondition' });
    assert.equal(getApps().length, count);
  } finally {
    if (previous === undefined) delete process.env.ACCOUNT_DELETION_ENABLED;
    else process.env.ACCOUNT_DELETION_ENABLED = previous;
  }
});
