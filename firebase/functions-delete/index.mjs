// Draft provider adapter. Not registered in the project's Firebase config or deployed.
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { createDeleteAccount, DeletionError } from './delete-account.mjs';

export const deleteFamilyAccount = onCall({
  enforceAppCheck: true,
  timeoutSeconds: 120,
  maxInstances: 3,
  concurrency: 1,
  memory: '256MiB',
}, async (request) => {
  // Owner review + staged validation are required before opting in at deployment.
  if (process.env.ACCOUNT_DELETION_ENABLED !== 'true') {
    throw new HttpsError('failed-precondition', 'Account deletion is not configured.');
  }
  try {
    const app = getApps()[0] ?? initializeApp();
    const firestore = getFirestore(app);
    return await createDeleteAccount({
      firestore, auth: getAuth(app),
      async beginDeletion(uid) {
        const lock = firestore.doc(`deletionLocks/${uid}`);
        await firestore.runTransaction(async (transaction) => {
          if (!(await transaction.get(lock)).exists) {
            transaction.create(lock, {
              status: 'pending', createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
            });
          }
        });
      },
      async completeDeletion(uid) {
        // Never remove this tombstone: older ID tokens can outlive Auth deletion.
        await firestore.doc(`deletionLocks/${uid}`).update({
          status: 'complete', updatedAt: FieldValue.serverTimestamp(),
        });
      },
    })(request);
  } catch (error) {
    if (error instanceof DeletionError) throw new HttpsError(error.code, error.message);
    // Never expose SDK errors, raw requests, tokens, document contents, or paths.
    throw new HttpsError('internal', 'Account deletion could not be completed.');
  }
});
