# IrShoGram implementation status

Last reviewed: 2026-11-10
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
- A first-login Firestore profile is created when one does not exist.
- Firestore/Storage repository implementation exists for users, follows, posts, likes, saves, comments, notifications, stories, reels, conversations, messages, and media uploads.
- The online feed supports Firestore posts, likes, comments, media display, and post deletion.
- Online post/story/reel publishing and online story/reel display are implemented in the current branch.
- User search/following, profile editing, profile post grid, and text messaging have initial Firebase-backed implementations.
- Firestore rules, Storage rules, and index configuration files are present.
- The GitHub Actions workflow runs dependency installation, analysis, tests, and conditionally builds/uploads a release APK.

## CI and APK evidence

A GitHub Actions run on 2026-11-07 completed successfully for the Firebase foundation branch:
- Flutter dependency installation: passed
- `flutter analyze`: passed
- `flutter test`: passed
- Firebase Android configuration restore: passed
- Release APK build: passed
- APK artifact upload: passed

Artifact name: `irshogram-release-apk`.
This confirms a CI build artifact was produced; it does not confirm installation or
runtime behavior on a physical device. Current authentication and feature changes
must pass a fresh workflow run as well.

## Latest CI result (2026-11-10)

GitHub Actions run [#169](https://github.com/salmanabadian/IrShoGram/actions/runs/42686377960)
completed with a Firebase OAuth certificate-validation failure:
- Flutter dependency installation, static analysis, and tests passed.
- The preview APK built and uploaded successfully.
- The protected Firebase configuration was restored, but it did not contain an
  Android OAuth client matching the signing certificate used by the branch build.
- The Firebase-configured release APK was therefore not built or uploaded.

Earlier pull-request and branch-push runs used different cached debug signing
certificates because GitHub cache scopes differ by event. The workflow now skips
Firebase APK validation on pull requests; use the SHA-1 from a push or manual run
on `firebase-foundation`. Add it to the registered Firebase Android app, download
a fresh `google-services.json`, and update either protected Actions secret above.
No Firebase rules were deployed and no physical-device login was verified by this
CI run.

## Authentication scope

Google Sign-In remains the normal sign-in path. A temporary Firebase Phone
Authentication screen is now available only when the Firebase test APK is built
with `IRSHOGRAM_ENABLE_PHONE_TEST_LOGIN=true`. The preview APK does not expose
the phone option. Configure two fixed test numbers and codes under Firebase
Authentication → Phone → Phone numbers for testing. Firebase does not send SMS
for those configured test numbers, so they do not incur SMS charges. This does
not verify real SMS delivery; numbers not on the test list may send billable SMS.
The Google provider remains enabled and unchanged.

The sign-out action is present in account settings. Physical-device testing is
still required for Google sign-in, phone test sign-in, and signing out/in as the
second test account.

## Known incomplete work

- Account sign-out and secure account deletion need completion and device tests.
- Username uniqueness is not yet enforced by a trusted backend transaction.
- Multiple simultaneous account sessions and safe account switching are not implemented.
- Saved-post UI still relies on local data in parts of the app.
- Parts of the main shell still load legacy local demo state.
- Story viewer tracking, story replies/highlights, and reliable expiry/media cleanup need work.
- Direct-message attachments, read receipts, delivery state, and push notifications are incomplete.
- Explore ranking, sharing, reporting, blocking, private-account access control, and privacy settings are incomplete.
- Firestore/Storage rules and indexes have not been proven deployed to the target Firebase project or fully emulator-tested.
- Cloud Functions/trusted server workflows for notifications, counters, moderation, cleanup, and abuse prevention are not implemented.
- Pagination, upload progress/retry, image/video compression, thumbnails, offline behavior, and lifecycle cleanup need improvement.
- Release APK is currently debug-signed; production signing is not configured.
- Physical-device Google login, media upload, and two-device synchronization acceptance tests remain outstanding.
- The previously selected app icon has not been identified in the repository. Current Android launcher resources use a generic gradient camera vector and must not be treated as the approved icon.

## Immediate next work

1. Test Google and the temporary Firebase test-phone flow on a physical device; complete secure account deletion and verify sign-out/session behavior.
2. Remove remaining local/demo data paths from production-facing screens.
3. Complete real saved posts, notification flow, story views/replies, message attachments/read receipts, and multi-account support.
4. Harden and test privacy/security rules; add trusted backend functions.
5. Add media optimization, pagination, resilient uploads, and low-bandwidth handling.
6. Verify the approved launcher image before replacing the generic icon.
7. Run CI, install the APK on a physical device, and perform cross-device acceptance tests.
8. Configure production release signing before public distribution.
