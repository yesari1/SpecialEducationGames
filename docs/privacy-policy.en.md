# Privacy Policy — INTERNAL DRAFT / NOT FOR PUBLICATION

> **Required before publication:** This is a draft, not a published policy. `[LEGAL DEVELOPER/OPERATOR NAME]`, `[PRIVACY CONTACT EMAIL]`, `[PUBLIC POLICY URL]`, effective date, retention/backup periods, and a working account/data deletion route are unverified. No legal or store-compliance review has been completed. Do not publish until placeholders are completed and actual app behavior is rechecked.

**App behavior reviewed:** 17 October 2026. **Responsible operator:** `[LEGAL DEVELOPER/OPERATOR NAME]`.

## Scope

This draft describes source-code behavior reviewed for the Android Özel Eğitim Oyunları app. Only source and configuration were reviewed; live Firebase services, store declarations, server logs, backups, and real purchases were not verified. This document is therefore not publication-ready.

## Child profiles and information kept on the device

The app stores a parent-entered child nickname, avatar, and optional onboarding survey answers in a local SQLite database for play. Survey options cover age band, communication, pointing to named objects, tap/drag ability, sound sensitivity, focus duration, familiar/preferred themes, and counting ability. The answers are used for local profile settings and game preferences.

Local play history includes theme/game/item identifiers, difficulty, wrong-answer and hint counts, selected option identifiers, response latency, active/inactive time, and round timestamps. Profile settings, app language, sound/accessibility preferences, a salted hash of the parent-gate PIN, and a local purchase-entitlement cache are also device data. The nickname, avatar, survey answers, and raw selections are not included in the daily-summary sync payload.

## Optional parent account and online requests

A Google account is not required for local play. A parent may choose Google sign-in in the family area. The reviewed app uses Firebase Authentication and its app account model receives the Firebase UID and email address; the app's own account model does not retain the parent's profile photo or display name. The full information processed by Google/Firebase during sign-in and technical service logging cannot be established from this source review; verify provider configuration and disclosures before publication.

On Android, the app attempts to read public `config/app` configuration and the announcement document matching an ID selected by the parent from Firebase Firestore. Live reads have not been verified. After signing in, a family can separately consent to sharing daily summaries for a selected profile and initiate the **Sync** action. Consent, parent authorization, account, and profile are rechecked and the operation is cancelled when scope changes. The sync fields are day, theme, game mode, difficulty, total active time, round/stage/independent-response counts, and update time; raw selections and survey answers are excluded. This is not a full profile backup. The Firebase UID and profile ID are also used in the Firestore document path. Live cloud transfer has not been verified.

## Install statistics without an account

On each install the app writes anonymous usage statistics to the Firestore record `funnel/{installId}`, under a random install ID the app creates itself. The record is not linked to a Google account, Android ID or advertising ID, and only the administrator reads it. It holds: the first times of the install and setup steps, platform, app version, language, phone model, push address (FCM token), total and daily play time and the number of days played; since 6 November 2026 also the local dates the app was opened (the last 60), when the first round was finished, opened and finished rounds per card (theme and game), the button tapped on the offer screen (trial, plan and plan ID, back) and the result of Android's notification permission. The child's nickname, survey answers and individual game answers are never written to this record.

## Purchases

On Android the app queries subscription offers from Google Play; displayed price and eligible offer depend on Play's response. Purchase and restore use Google Play Billing; the app does not ask for or store payment card details. The reviewed code reads price, trial eligibility, and purchase state from Play responses. Real products, prices, purchases, restores, and store-account behavior have not been verified. Deleting a Firebase account does not automatically cancel a Google Play subscription; cancellation must be handled separately in Google Play.

## Advertising and diagnostics

The reviewed app version has no Firebase Analytics, Firebase Crashlytics, or known advertising SDK dependency. The recorded release-manifest audit found no Android Advertising ID (AD_ID) or AdServices permissions for the audited build. The source Android manifest declares internet access. These findings do not cover future SDK additions or Play Console declarations. If analytics or crash reporting is added, reassess this policy, child-data safeguards, permissions, and merged release dependency/manifest audits.

## Retention, deletion, and requests

The local profile-delete screen clears the selected local profile, raw game/round records, profile preferences, and local summary copies associated with that profile. It does not delete cloud account data. A user interface and working server flow for deleting Firebase-account-associated Firestore data are not available. The server account-deletion code is a draft, disabled by default, undeployed, and unverified against a real account. This policy therefore cannot claim that cloud accounts can currently be deleted.

Local-data retention and device-backup behavior: `[LOCAL RETENTION/BACKUP POLICY — OWNER REVIEW REQUIRED]`. Cloud data, backups, and processor-copy retention/deletion periods: `[CLOUD RETENTION AND DELETION PERIOD — OWNER REVIEW REQUIRED]`. Account/data deletion route: `[WORKING, PUBLIC ACCOUNT/DATA DELETION URL]`; privacy/support contact: `[PRIVACY CONTACT EMAIL]`. These contact placeholders are not working request channels.

## Children and publication review

The app is designed for children. This text is not legal advice and does not claim COPPA, GDPR, Google Play Families, or store approval. Google Play requires child-directed apps to disclose personal/sensitive data practices, including data collected through APIs and SDKs, and to keep target-audience and Data safety answers accurate. A qualified reviewer should assess current audience settings, data flows, SDK terms, store declarations, and applicable local law. [Google Play Families Policy](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)

## Changes and contact

Effective date: `[DD MMM YYYY — OWNER APPROVAL REQUIRED]`. Published policy URL: `[PUBLIC HTTPS URL]`. Data controller/operator: `[LEGAL NAME AND ADDRESS — OWNER APPROVAL REQUIRED]`. Privacy requests: `[EMAIL]`. Do not show this as the operative user policy until these details are completed and the document is published.
