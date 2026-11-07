# IrShoGram implementation status

Last updated: 2026-11-07

## Completed on branch `firebase-foundation`

- Android namespace and application ID aligned to `com.irshogram.app`, matching the Firebase Android registration supplied for this project.
- Kotlin `MainActivity` moved to the matching package.
- Added FlutterFire dependencies: Firebase Core, Authentication, Cloud Firestore, and Firebase Storage.
- Added Google Services Gradle plugin.
- Added Firebase initialization before app startup and a visible setup-error screen if native Firebase configuration is unavailable.
- Added a phone-number OTP sign-in screen with verification, resend support, and user-facing handling for common Firebase Auth errors.
- Added an authenticated session gate and first-login Firestore profile creation.
- Added a Firestore/Storage implementation of the existing social repository contracts for users, follows, posts, likes, saves, comments, notifications, stories, reels, conversations, messages, and media uploads.
- Added a validated target UID field to following documents so follower counts can be queried.
- Added Firestore composite indexes for profile posts, active stories, and conversations.
- Added protected Firebase config handling to CI. APK builds run only when the Actions secret is configured.
- Excluded Android/iOS Firebase configuration files from Git.
- Adjusted the widget test so it tests the UI shell without requiring a live Firebase session.

## Not yet complete / acceptance blockers

1. The UI still uses the device-local store for its current home/feed, stories, messages, profile, and likes. The new Firebase repository is not yet fully wired into every screen. Do not describe the whole app as online until this migration is completed.
2. The private `android/app/google-services.json` file has not been installed in the local project or supplied to CI. It must match `com.irshogram.app`.
3. Firebase Authentication → Phone provider must be enabled in the Firebase Console.
4. Debug and release SHA-1/SHA-256 fingerprints must be registered.
5. Firestore indexes and security rules must be deployed to the Firebase project.
6. Real SMS delivery, account creation, media upload, and cross-device synchronization must be tested on a physical Android device.
7. The first CI pass confirmed dependency resolution and a clean analyzer. The widget test initially expected visible navigation labels, but the app exposes these as accessibility tooltips; the test was corrected to assert those tooltips. A rerun is required. No successful APK build is claimed yet.
8. Production release signing, push notification delivery, reporting/blocking, privacy controls, moderation, media processing, and broader Instagram-like surfaces remain future work.

## Immediate next engineering work

- Run CI and fix every analyzer/test/build failure.
- Connect feed, profile, story, reel, comment, like/save, and direct-message screens to the Firebase repository and Storage instead of local-only persistence.
- Add proper pagination, media compression/transcoding, upload progress/retry, thumbnails, and lifecycle cleanup.
- Add Cloud Functions or another trusted backend for notification fan-out, follower denormalization if needed, moderation, and cleanup of expired media.
- Add account switching and complete privacy/security settings.
