# IrShoGram implementation status

Last reviewed: 2026-11-28
Active development branch: `firebase-foundation`
Default branch: `main`
Open pull request: #1 (not merged)

## Verified foundation

- Flutter/Dart Android application.
- Android namespace, application ID, and Kotlin package aligned to `com.irshogram.app`.
- Firebase Core, Firebase Authentication, Google Sign-In, Cloud Firestore, and Firebase Storage dependencies are present.
- Firebase initializes before the app starts; a setup-error screen is shown when initialization fails.
- Google Sign-In obtains an ID token and exchanges it for a Firebase credential.
- Auth state is observed through `authStateChanges()`.
- A first-login Firestore profile is created when one does not exist; a transaction also reserves a case-insensitive username claim, and Firestore Rules require the profile and claim to change atomically.
- Firestore/Storage repository implementation exists for users, follows, posts, likes, saves, comments, notifications, stories, reels, conversations, messages, and media uploads.
- The online feed supports Firestore posts, likes, comments, media display, and post deletion.
- Notification trigger source creates recipient-owned in-app notification documents for likes, comments, and follows; emulator integration tests verify each trigger, and client rules permit only a one-way unread-to-read transition.
- Online post/story/reel publishing and online story/reel display are implemented in the current branch.
- User search/following, profile editing, profile post grid, and text messaging have initial Firebase-backed implementations.
- Firestore rules, Storage rules, and index configuration files are present.
- Saved-post Firestore rules now restrict reads/deletes to the owner, permit only timestamp-only creation for an existing post, and reject updates; dedicated emulator tests cover these cases.
- Direct-message rules now require canonical sorted two-person conversation IDs, immutable participant lists, server timestamps, participant-only access, sender identity matching the authenticated user, bounded non-empty text messages, and valid image/video attachment metadata; emulator tests cover these cases.
- The GitHub Actions workflow runs Flutter dependency installation, analysis, Flutter tests, Firestore saved-post rules tests in the local emulator, and conditionally builds/uploads release APK artifacts.

## CI and APK evidence

Latest verified GitHub Actions runs on 2026-11-27:

- [Run #290 — branch push](https://github.com/salmanabadian/IrShoGram/actions/runs/45972126187), commit `df654e0`: Flutter analysis/tests, Firestore, Storage, and Cloud Functions emulator tests passed. The preview APK and Firebase-configured APK were built and uploaded.
- [Run #291 — pull request](https://github.com/salmanabadian/IrShoGram/actions/runs/45972137060), commit `df654e0`: Flutter analysis/tests, Firestore, Storage, and Cloud Functions emulator tests passed. The preview APK was built and uploaded; the Firebase-configured APK is intentionally skipped on pull requests.

These results prove CI produced APK artifacts; they do not prove Google login,
media upload, or cross-device behavior on a physical device. No Firebase rules
or Cloud Functions were deployed and no physical-device login was verified by
these runs.

## Authentication scope

Google Sign-In is the only supported authentication method. The sign-in screen
obtains a Google ID token and exchanges it for a Firebase credential. Phone/SMS
authentication is intentionally excluded from the app and its CI APK builds.
The sign-out action is present in account settings. Physical-device testing is
still required for Google sign-in, session restoration, sign-out, and signing in
with a second Google account on another device.

## Known incomplete work

- Secure account deletion needs completion and device tests; sign-out is present but still needs device verification.
- Multiple simultaneous account sessions and safe account switching are not implemented.
- Saved-post UI still relies on local data in parts of the app.
- Parts of the main shell still load legacy local demo state.
- Story viewer tracking, story replies/highlights, and reliable expiry/media cleanup need work.
- Direct-message attachments, read receipts, delivery state, and push notifications are incomplete.
- Explore ranking, sharing, reporting, blocking, private-account access control, and privacy settings are incomplete.
- Firestore/Storage rules and indexes have not been deployed to the target Firebase project. The emulator suite covers saved-post and direct-message rules; other collections and Storage rules still need broader security tests.
- Like, comment, and follow notification Cloud Functions now exist in source and are covered by emulator integration tests; they are not deployed to the target Firebase project. Push notifications and trusted counter/moderation/cleanup workflows remain incomplete.
- Pagination, upload progress/retry, image/video compression, thumbnails, offline behavior, and lifecycle cleanup need improvement.
- Release APK is currently debug-signed; production signing is not configured.
- Physical-device Google login, media upload, and two-device synchronization acceptance tests remain outstanding.
- The previously selected app icon has not been identified in the repository. Current Android launcher resources use a generic gradient camera vector and must not be treated as the approved icon.

## Immediate next work

1. Test Google sign-in, session restoration, and sign-out on a physical Android device; then verify two separate Google accounts on two devices.
2. Complete private-account follow requests and enforce access consistently across Firestore, Storage, feed, stories, and reels.
3. Remove remaining local/demo data paths from production-facing screens.
4. Deploy and verify notification triggers only after the Firebase project owner approves deployment and confirms billing eligibility; then finish story views/replies, message attachments/read receipts, and multi-account support.
5. Add media optimization, pagination, resilient uploads, and low-bandwidth handling.
6. Verify the approved launcher image before replacing the generic icon.
7. Run CI, install the APK on a physical device, and perform cross-device acceptance tests.
8. Configure production release signing before public distribution.
