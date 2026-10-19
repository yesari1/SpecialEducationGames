# Local Firestore security tests

No login, production API enablement or deployment is required. The project ID
is deliberately `demo-special-education-rules`; test identities/data are synthetic.

Prerequisites: Node >=24.12, Java 21, Firebase CLI (verified 15.32.0).
From this repository:

```powershell
cd firebase/rules-tests
npm ci --ignore-scripts --no-audit --no-fund
cd ..
firebase emulators:exec --only firestore --project demo-special-education-rules --config firebase.test.json "npm --prefix rules-tests test"
```

The CLI starts and stops only the configured local Firestore emulator. Tests use
127.0.0.1:8085, hub4405/logging4505; the emulator also uses websocket9150. Check
those ports before running concurrently. A first run downloads the official
Firestore emulator JAR to the Firebase user cache. SDK test dependencies are
local to this directory, pinned in package-lock.json; no Flutter deps change.

Coverage: exact nine-field daily summary round-trip; owner isolation and anonymous
denial; config public direct get/no list/admin-only writes; no self-provisioning
admins; raw trials and Premium documents/extra fields denied; missing fields,
counter types/negative values, independent>stages, future timestamps, malformed
IDs and calendar dates; family/profile field allowlists; progress/item counters.
Owner deletions remain permitted for account deletion. Local calendar dates may
be one day ahead of UTC, never farther; timestamp must not exceed request.time.

These rules remain a reviewable deployment draft. Profile survey/settings map
contents are not a finalized sync protocol and their nested schema is not yet
validated; this suite does not claim that protocol is complete. Content pack,
announcement and Storage policy, App Check, real OAuth and production deployment
are outside this test run. No real accounts or production data are used.

Official references:
- https://firebase.google.com/docs/rules/unit-tests
- https://firebase.google.com/docs/reference/emulator-suite/rules-unit-testing/rules-unit-testing
- https://firebase.google.com/docs/reference/rules/rules.timestamp
- https://firebase.google.com/docs/reference/rules/rules.Timestamp_

Deletion lock coverage (16 October 2026): 9/9 tests pass. A server-only
`deletionLocks/{uid}` marker blocks create/update throughout the family tree,
including missing parents and old-token recreation after completion. Owners
can still read/delete their existing data. All clients, including config admins,
are denied marker read/write/delete. Other unlocked accounts remain independent.
This is the companion rule protocol for `functions-delete/`; the callable stays
disabled and undeployed. Admin SDK writers bypass rules and must honor the lock.

Announcement coverage (16 October 2026): 10/10 local rule tests pass. Public
exact document get only; no announcement collection lists. Only provisioned
admins can write/delete; schemaVersion integer1, bounded TR/EN text maps with
at least one complete language pair, no unknown document fields. UI separately
requires parent access, renders plain text and rejects markup/URLs. No rules
were deployed and no live announcement data was written.
