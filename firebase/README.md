# Firebase integration status

Local-only summary preparation is implemented in
`lib/core/sync/summary_export.dart` with five deterministic tests. It exports
only the draft session rule fields, never raw choices, target IDs, account
identifiers or entitlement. Ended interrupted sessions contribute active time
but no completed round; open/invalid/future sessions are excluded. Historical
session active time is attributed to the local end day because rows contain no
per-day active segments. Trials use their own local dates independently (there
is no sessionId for a reliable join). Whole-document last-write-wins validates
timestamps and dates; equal timestamps resolve deterministically without adding
duplicate aggregates. This module is not connected to upload/download; it
makes no network/database writes. It does not complete sync or account deletion.
The typed payload decoder rejects unknown/missing fields, malformed types,
invalid/future dates and unsafe document identifiers. An SDK adapter must first
convert Firestore timestamps to DateTime; arbitrary strings are not accepted.

Android Firebase Core and Firestore are connected using the existing Unity
Android registration for `specialeducationgames` / `com.YeS.OzelEgitimOyunlari`.
The generated `assets/firebase/android_options.json` contains public Firebase
client configuration, not an ElevenLabs key or administrator credential.
Unity source and production Firebase settings were not modified.

Only `config/app` is read. No profile or trial data is uploaded. Reads start
after the Flutter UI starts, time out after ten seconds and are attempted at
most once per six hours. Offline startup uses the validated SQLite copy, then
the packaged defaults. Config arriving during a game is applied after leaving.
Unknown game/theme IDs and malformed fields are rejected. Six free games remain
required. Higher `minSupportedVersion` only shows a parent settings message.

Firebase Core 3.15.2 / Firestore 5.6.12 were selected for the existing Android
and Flutter toolchain; existing dependencies were not blanket-upgraded.
The optional Google family authentication client is implemented locally; live
authorized sign-in, summary synchronization, Analytics, Crashlytics, Storage
packs and production security-rule verification remain unfinished.
Firebase CLI currently requires login. No rule/config deployment was performed.
The public REST read probe for `config/app` returned HTTP 403 PERMISSION_DENIED.
Live configuration access is therefore not verified; do not report cloud setup
as complete. The device continues to use local defaults/cache.
The Android SDK confirms the cause: Cloud Firestore API has not been used in
the project before or is disabled. An authorized owner must complete the
Firestore/API console setup; this task has not enabled or deployed anything.

Implemented fields: freeGames, disabledGames, hiddenThemes, gameOrder,
featuredTheme and minSupportedVersion. Announcement/new badge/paywall wording
and remotely adjustable teaching defaults still need implementation.

`firestore.rules` is a reviewable draft. Deploying it requires checking existing
production rules and owners; do not overwrite production rules automatically.

References: [Flutter setup](https://firebase.google.com/docs/flutter/setup),
[Firestore offline cache](https://firebase.google.com/docs/firestore/manage-data/enable-offline).


## Optional parent Google account (local client implemented)

Pinned additions: Firebase Auth 5.7.0 and Google Sign-In 6.3.0, compatible with
Core 3.15.2 / Firestore 5.6.12. Existing dependency versions were preserved.
Account UI is available only behind the family gate. Every action independently
rechecks parent authorization. No sign-in prompt runs on startup. Google
selection cancellation, connection failure, invalid configuration and a bounded
120-second UI timeout leave local profiles and play available. Late cancelled
requests cannot publish a new account; native requests are serialized.

Firebase and Google SDKs manage their own secure session state. The app does
not persist or print access/ID tokens, credentials or email in its database,
preferences, trial logs or Firestore. The selected parent's email is displayed
only in the guarded account card. Sign-out leaves local learning records intact.
Config and auth share Firebase initialization with a 15-second wait bound.

The public OAuth web client ID was read from the unchanged Unity registration:
`579874152426-e7a15kto2l2nhmfnhfdmoc3a5cnnpfk6.apps.googleusercontent.com`.
It is passed as `serverClientId`; no secret client credential or signing key was
copied. The Android package remains `com.YeS.OzelEgitimOyunlari`. A project owner
must verify Google is enabled in Firebase Authentication and that the existing
Android OAuth registration contains the actual debug and Play App Signing SHA-1
certificates. Do not replace signing keys to match this registration.

Live sign-in has **not** been verified with a parent's Google account. No console
providers/APIs were enabled, no account was selected automatically, no rules were
deployed and no family document was written. Sign-in alone does not activate sync or Premium. A separate default-off parent
consent and explicit Sync now action sends daily aggregates only, not a full backup.
The current Firestore disabled/403 blocker remains. Account-and-data deletion
needs a verified cloud cleanup flow before an Auth user deletion button is added;
there is no misleading partial deletion action.

Unit verification: `flutter test test/family_auth_test.dart --no-pub` (3 passed).
This covers authorization, cancellation, timeouts/late completion, duplicate
requests, disposal, and recoverable offline/configuration failures with an
injected backend. It does not prove an OAuth account or console configuration.

Primary SDK references: [Firebase Google sign-in](https://firebase.google.com/docs/auth/flutter/federated-auth),
[Google Sign-In 6.3.0 Android setup](https://pub.dev/packages/google_sign_in/versions/6.3.0).

## Explicit daily-summary sync (client connected; live verification pending)

`SummarySync` accepts an injected `SummaryStore`, current UID/profile getters,
parent authorization and explicit consent getters. Construction is inert.
Call `synchronize(prepareDailySummaries(...))` only after the parent explicitly
chooses sync; pass only records for that profile. Its result is a separate
immutable merged summary snapshot, not replacement raw learning records. The parent account screen persists validated snapshots separately in
`SummarySnapshotCache`; it never replaces local raw learning records. Consent
is session-local and defaults off. Merely opening the card or checking consent
does not contact a summary server; only Sync now initiates network work. No
periodic upload is configured.

Call `cancel()` immediately on account/profile switch, consent withdrawal or
parent lock and `dispose()` on owner disposal. Getters are rechecked after each
await; stale operations cannot return a snapshot or initiate subsequent writes.
An already submitted transaction commit cannot be recalled. It remains scoped
to the originally authorized account/profile; do not describe cancellation as
server-side rollback. Errors expose only typed issue categories.

The Firestore implementation uses
`families/{uid}/profiles/{profileId}/sessions/{documentId}`, verifies the current
Firebase Auth UID, rejects path separators, converts SDK Timestamp values before
strict decoding, and requires document IDs to match their payloads. Reads are
server-only. At most 200 summary documents are accepted; oversized collections
fail explicitly instead of silently truncating. This cap is an initial safety
bound, not a completed long-term history pagination solution.

Writes use one online-only transaction with all reads before writes. Each
transaction retry compares current remote documents again with deterministic
whole-document LWW; no counts or times are incremented. Thus repeated uploads
and concurrent changes to the same document do not add duplicate totals. LWW
chooses one device's entire aggregate; it cannot combine independent same-day
learning on two devices without a future per-device model. Initialization,
reads, transaction attempts and the overall operation have bounded waits;
transactions do not queue offline batch writes for later replay.

Verification: six fake-backed adapter/SDK conversion tests and five existing
summary model tests pass (11 total). Actual Firebase transactions and OAuth
setup still require live validation. Separately, the reviewable security rules
passed nine local demo Firestore emulator tests; see
`rules-tests/TESTING.md` and `rules-tests/last-result.json`. This is not production
deployment or validation of the nested survey/settings schema.
The production API-disabled/403 blocker is unchanged. No family data was sent,
no rule/API/provider was deployed or enabled, and no production account was
selected. Account deletion remains unfinished for users. A disabled, undeployed callable
in `functions-delete/` has twelve local fake tests. It requires a recent verified
login, explicit confirmation and App Check, creates a server-only persistent
`deletionLocks/{uid}` marker before recursive family cleanup, then deletes Auth
and marks completion. Rules block all family create/update when that marker
exists, including old tokens and orphan recreation; marker access is denied to
all clients. Admin SDK writers must honor it separately. No client deletion
button, live App Check validation, deployment or real account deletion occurred.

## Presentation fields in config/app

- `newBadge`: list of existing theme IDs, e.g. `["produce"]`. Unknown IDs or
  malformed lists preserve the last valid value; `[]` clears badges. Hidden
  themes stay hidden. Home cards use the current TR/EN New label; game access is
  unchanged.
- `paywallText`: localized title map, e.g.
  `{"tr":"Birlikte keşfet","en":"Discover together"}`. Only tr/en keys and
  single-line strings up to 120 Unicode code points are accepted. Invalid fields
  preserve the previous valid map; `{}` clears overrides, empty language values
  fall back to bundled copy. Titles are plain Text. Prices, trial disclosures,
  purchase actions and entitlements are not remotely overridden by this field.

Both fields are bundled empty, included in the validated SQLite config cache,
and use the existing six-hour fetch limit/session-boundary application policy.
No production configuration document was changed. `announcementId` is connected to the parent notice card; pedagogical choice
counts remain unfinished (fade threshold is implemented below).

## Bounded pedagogical config

`difficultyDefaults` accepts recognized partial fields `fadeAfterErrors` and
`choiceCounts`. The former is a strict integer 1–3, default2. The latter must
provide exactly easy/medium/hard, strict integers 2–4 in nondecreasing order;
defaults are 2/3/4. Example:

```json
{"difficultyDefaults":{"fadeAfterErrors":2,"choiceCounts":{"easy":2,"medium":2,"hard":3}}}
```

Missing recognized fields preserve their previous values. Invalid types, unknown
keys, missing tiers, out-of-range or decreasing counts reject the whole difficulty
update transactionally. `{}` restores both defaults. The validated SQLite cache
preserves both fields. A new controller captures its threshold and choice count;
active-game deferral prevents mid-game remote changes. Parent fade-off takes
precedence. Item support reduction, target retention and available-pool caps still
apply; comparison stays binary, exploration/introduction and numeric task ranges
retain their existing rules. No production configuration was written.

## Parent announcements (client connected, production unavailable)

`config/app.announcementId` is a safe single document ID (letters/digits/hyphen,
1–128 characters); null/empty clears it. Missing/invalid fields keep the last
valid configuration. Bundled default is null. The family screen alone mounts
`ParentAnnouncementCard`; it fetches only with parent access and a configured
ID. It hides immediately on lock or ID change, suppresses late UI results and
never falls back to another language. Text contains no interactive links/actions.

Exact document schema for `announcements/{id}`:

```json
{"schemaVersion":1,"title":{"tr":"Yeni oyun","en":"New game"},"body":{"tr":"Ebeveyn bilgisi.","en":"Parent information."}}
```

Titles are <=120 Unicode code points, bodies <=1200, language keys only tr/en,
at least one complete language pair; unknown fields, empty/invalid copy,
markup and URLs are rejected by the client. Missing translation hides the notice.
The read uses a bounded server-only exact document fetch, no lists/writes/UID or
profile data. Validated SQLite snapshots are isolated by ID; each ID has a
six-hour attempt throttle, including failures and clock rollback. Offline or
missing/invalid remote results retain a valid cached notice; clear the configured
ID to hide cached notices. No periodic polling is added.

Five core/repository and five parent-widget tests plus six config tests passed.
The rules draft has ten passing local demo tests, including public exact get,
no list, admin-only bounded notice writes/delete. These informational documents
are public at the data layer; parent-only is an app display/access constraint.
The production API-disabled blocker remains; no production announcement was
created, read for validation, or deployed.
