// Accept only SDK-verified callable auth. Never construct this context from body data.
export class DeletionError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}

export function createDeleteAccount({ firestore, auth, beginDeletion, completeDeletion, now = Date.now }) {
  return async function deleteAccount(request) {
    const identity = request?.auth;
    if (!identity) throw new DeletionError('unauthenticated', 'Sign in again to delete your account.');
    const uid = identity.uid;
    if (typeof uid !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)
      || (identity.token?.uid !== undefined && identity.token.uid !== uid)
      || (identity.token?.sub !== undefined && identity.token.sub !== uid)) {
      throw new DeletionError('permission-denied', 'Invalid account identity.');
    }
    const authenticatedAt = identity.token?.auth_time;
    const currentSeconds = Math.floor(now() / 1000);
    if (!Number.isSafeInteger(authenticatedAt) || authenticatedAt <= 0
      || authenticatedAt > currentSeconds || currentSeconds - authenticatedAt > 300) {
      throw new DeletionError('failed-precondition', 'Recent sign-in is required.');
    }
    const data = request.data;
    if (!data || typeof data !== 'object' || Array.isArray(data)
      || Object.keys(data).length !== 1 || data.confirmDelete !== true) {
      throw new DeletionError('invalid-argument', 'Explicit deletion confirmation is required; do not send account identifiers.');
    }
    // Private marker is outside the subtree and must commit before cleanup.
    // Rules must deny all family writes while deletionLocks/{uid} exists.
    try {
      await beginDeletion(uid);
    } catch {
      throw new DeletionError('unavailable', 'Deletion could not be started. Retry deletion.');
    }
    // No exists() shortcut: orphaned descendants can exist without the parent.
    // Await the entire recursive delete before removing the retry-capable identity.
    try {
      await firestore.recursiveDelete(firestore.doc(`families/${uid}`));
    } catch {
      throw new DeletionError('unavailable', 'Data cleanup did not finish. Sign-in remains available; retry deletion.');
    }
    try {
      await auth.deleteUser(uid);
    } catch (error) {
      if (error?.code !== 'auth/user-not-found') {
        throw new DeletionError('unavailable', 'Account cleanup did not finish. Retry deletion.');
      }
    }
    try {
      await completeDeletion(uid);
    } catch {
      // The persistent lock still prevents stale ID tokens from recreating data.
      throw new DeletionError('unavailable', 'Account removed; completion recording did not finish.');
    }
    return { deleted: true };
  };
}
