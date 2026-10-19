# Account deletion foundation — local draft only

This directory is not registered in the Firebase deployment configuration. No deployment, cloud SDK operation, credential lookup, live account deletion, or production data deletion was performed. The callable also fails closed unless `ACCOUNT_DELETION_ENABLED=true` is explicitly configured after owner review. Do not enable it yet.

## Contract and scope

- Callable input is exactly `{ "confirmDelete": true }`. There is no client-selectable UID, document path, collection, or account payload.
- The function relies on the callable SDK's verified `request.auth`, requires a login `auth_time` within the last 300 seconds (refreshing `iat` alone is insufficient), and constructs only `families/{auth.uid}`. UIDs are restricted to 1–128 ASCII letters, digits, `_`, and `-`; arbitrary custom UIDs need a reviewed policy.
- Admin `recursiveDelete` covers the family subtree, including descendants whose parent documents no longer exist. It is always awaited, including when the root document is absent. No profile contents are fetched, copied, or logged by this code.
- Before cleanup, injected `beginDeletion(uid)` commits the server-only `deletionLocks/{uid}` marker outside the family subtree. The provider transaction creates it only if absent with `{status:'pending', createdAt:serverTimestamp(), updatedAt:serverTimestamp()}`. Existing markers are preserved. Marker failure prevents all cleanup. After Auth deletion, `completeDeletion(uid)` updates only status to `complete` and `updatedAt`; the tombstone is never removed. It contains no copied profile payload.
- Auth `deleteUser` runs only after recursive cleanup resolves. Cleanup failure leaves the identity untouched and reports a retryable error. An already missing Auth identity is success; other Auth errors remain failures. Partial Firestore cleanup is possible and retries resume by removing whatever remains.
- Only the private deletion marker is written; there are no writes to Premium, config, admins, or other families. Local SQLite, device files, external processors/backups, and Play subscriptions are outside this server-side subtree operation. Account deletion does not cancel a Play subscription.
- App Check enforcement is explicitly requested in the wrapper. Local fake tests do **not** prove SDK token verification, App Check attestation, IAM, or deployed callable behavior. Runtime is bounded to 120 seconds, concurrency 1 per instance, at most 3 instances. These limits are not a data-size guarantee or a distributed lock.

## Local verification

From this directory: `npm ci --ignore-scripts --no-audit --no-fund`, then `npm test`. Dependencies are pinned in package.json/package-lock.json. Tests use Node's test runner and injected fake backends; they do not instantiate an Admin app or use credentials. The provider wrapper can be syntax-checked with `node --check index.mjs`.

Tests cover missing-parent descendants and adjacent family scope, cleanup-before-Auth ordering, sanitized cleanup/Auth failures, retry after identity removal, unauthenticated and mismatched identity denial, client UID/path injection and confirmation denial, stale/future/malformed login timestamps, and the exact five-minute boundary. Fake recursive deletion tests validate the adapter call/scope and model expected recursion; they are **not** a Firestore Admin emulator integration test.

Result: 12/12 local tests passed under Node 24.19.0; provider syntax check passed. Marker ordering and failures, pending locks after cleanup/Auth failure, retry reusing a pending marker after interruption, completion tombstone after success/retry, and retained locks when completion recording fails are included. The provider opt-in gate test imports the installed SDK but does not initialize Admin or contact a backend; `.run` bypasses token/App Check middleware. Installation reported transitive deprecation notices for node-domexception 1.0.0 and glob 10.5.0; no blanket dependency upgrades were performed.

## Isolated emulator smoke harness

`../firebase.delete-emulator.json` is a separate, demo-only configuration. It points at this package as the Functions source, uses the existing Firestore rules, and binds Auth, Firestore, and Functions to loopback ports 9099, 8085, and 5001. It does not register this draft in the project's ordinary Firebase configuration. Run from the `firebase` directory with Firebase CLI already installed and the pinned package dependencies already present:

```powershell
$env:GCLOUD_PROJECT = 'demo-special-education-delete'
$env:GOOGLE_CLOUD_PROJECT = 'demo-special-education-delete'
$env:ACCOUNT_DELETION_ENABLED = 'true'
$env:FUNCTIONS_DISCOVERY_TIMEOUT = '30'
firebase emulators:exec --project demo-special-education-delete --config firebase.delete-emulator.json --only auth,firestore,functions "node functions-delete/emulator-smoke.mjs"
```

The callable HTTP script refuses a non-demo project, missing explicit opt-in, or unexpected Auth/Firestore emulator host. It remains useful for checking the actual callable boundary, but without valid App Check it is expected to stop at that gate. Emulator state is process-local and the `emulators:exec` wrapper shuts down the services after the command. Do not change this to a real project or add credentials.

The backend-only emulator command is:

```powershell
$env:GCLOUD_PROJECT = 'demo-special-education-delete'
$env:GOOGLE_CLOUD_PROJECT = 'demo-special-education-delete'
$env:ACCOUNT_DELETION_ENABLED = 'true'
firebase emulators:exec --project demo-special-education-delete --config firebase.delete-emulator.json --only auth,firestore "node functions-delete/emulator-backend-smoke.mjs"
```

`emulator-backend-smoke.mjs` imports the production provider and calls `deleteFamilyAccount.run()` directly with a synthetic request context. It seeds an emulator Auth identity and nested family documents, confirms stale synthetic `auth_time` and bad confirmation are rejected before writes, and then checks recursive cleanup, unrelated-family retention, completed tombstone, Auth deletion, and same-UID retry. Direct `.run()` intentionally bypasses callable SDK middleware: the supplied `request.auth` is not an SDK-verified token and this test supplies no App Check attestation. It tests the production handler's Firestore/Auth backend logic against local emulators, but does not establish callable middleware, real recent-login verification, App Check, IAM, or deployment behavior.

The first bounded smoke attempt **did not pass**: Firebase CLI started Auth and Firestore and selected host Node 24 for Functions, but function discovery reported `User code failed to load ... Timeout after 10000`; the callable endpoint consequently returned `Function us-central1-deleteFamilyAccount does not exist`. This first failure is preserved in the task log; the separate fake-backend tests remained the only passing deletion-logic verification at that point.

Installed Firebase CLI 15.32.0 supports `FUNCTIONS_DISCOVERY_TIMEOUT` (seconds), verified in its local `lib/deploy/functions/runtimes/discovery/index.js`. A local import of `index.mjs` succeeded in about 598 ms. On the one authorized callable retry, a 30-second discovery timeout loaded `deleteFamilyAccount`. Its request had valid Auth (`auth: VALID`) but no App Check token (`app: MISSING`); the production callable correctly rejected it with HTTP 401 before its deletion handler ran. The failed request did not establish confirmation or deletion behavior. Do not add a fake App Check token or disable enforcement to make this pass.

The separate backend-only emulator attempt **passed** under Node 24.19.0. `emulators:exec --only auth,firestore` ran the production handler's `.run()` against emulator-backed Admin Auth and Firestore; the script confirmed stale-context and confirmation rejection, recursive nested-document cleanup, unrelated-family retention, completed tombstone, Auth identity deletion, and retry after recreating the same synthetic UID. It printed `PASS backend-only emulator smoke...` and `emulators:exec` shut down Auth and Firestore. This is backend integration evidence only, with the `.run()` middleware bypass and synthetic identity-context limitations above; the callable HTTP/App Check path remains blocked without a real supported App Check test context.

The harness cannot establish production App Check attestation or IAM/deployment behavior. Auth emulator sign-in produces a current `auth_time`, so the smoke test does not prove rejection of stale `auth_time`; that remains covered only by the unit test of the deletion logic, not by the callable SDK integration path. Emulator callable middleware behavior is evidence only for this local emulator version.

## Release blockers

1. The marker protocol requires deployed rules denying **all** family create/update operations whenever `deletionLocks/{uid}` exists and denying clients access to the marker itself, regardless of status. The companion draft rules are implemented in ../firestore.rules and passed 9/9 local emulator tests, including retained-marker denial after status becomes complete. Owners can still read/delete existing data; clients cannot create, inspect, alter or remove private markers. Rules remain undeployed. Validate both together before enabling: retained markers must stop concurrent second-device and stale-token writes, even after Auth deletion. Admin bypasses client rules; coordinate any other privileged writers. This foundation does not claim atomic account-and-data deletion. A failed cleanup keeps identity usable for retry, but the family remains write-locked intentionally; do not remove a marker to recover a partial deletion.
2. The backend-only smoke covers recursive cleanup, nested descendants, tombstone handling, Auth deletion, and a same-UID retry on local emulators. It does not cover injected partial failures or client-rule write-lock behavior (Admin SDK bypasses rules). Validate callable SDK/App Check and actual verified recent-login behavior with an App Check-capable isolated setup or owner-approved staging project. The smoke does not establish production guarantees. If Auth deletion succeeds but the final marker update fails, the retained pending lock is safe; reconcile completion server-side because a deleted user cannot reauthenticate once their recent-login token expires.
3. Review account-specific data inventory, retention/backup policy, subscriptions, support recovery, IAM, region, scaling/costs, and timeout behavior before deployment. Large subtrees may require a durable server-side deletion job rather than a single request. Never delete Auth on an ambiguous or timed-out cleanup.
4. Connect a parent-gated client confirmation and provider reauthentication flow, disable sync during deletion, handle retry and local-data choices explicitly, and deploy only after owner approval. Current client integration is not part of this directory.

## Primary references consulted

- [Firebase callable functions and verified auth context](https://firebase.google.com/docs/functions/callable)
- [Decoded ID token auth_time](https://firebase.google.com/docs/reference/admin/node/firebase-admin.auth.decodedidtoken)
- [Firestore recursiveDelete API](https://googleapis.dev/nodejs/firestore/latest/Firestore.html#recursiveDelete)
- [Firestore deletion and subcollections](https://firebase.google.com/docs/firestore/manage-data/delete-data)
- [Admin Auth user deletion](https://firebase.google.com/docs/auth/admin/manage-users#delete_a_user)

No raw personal request/error logs are added; provider-managed platform logs and retention still require deployment review.
