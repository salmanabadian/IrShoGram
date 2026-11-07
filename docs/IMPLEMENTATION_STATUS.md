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
- Added a Firestore/Storage implementation of the social repository contracts for users, follows, posts, likes, saves, comments, notifications, stories, reels, conversations, messages, and media uploads.
- Connected the home feed to live Firestore posts, including network image/video display, real likes, comments, and post deletion.
- Connected photo/video post publishing and 24-hour story publishing to Firebase Storage and Firestore.
- Connected the Stories strip/viewer and vertical Reels feed to live Firebase content.
- Connected user search, follow/unfollow, profile editing, profile post grid/count, and Direct Messages to Firestore; direct messages update live across clients.
- Added a validated target UID field to following documents so follower counts can be queried.
- Added Firestore composite indexes for profile posts, active stories, and conversations.
- Added protected Firebase config handling to CI. APK builds run only when the Actions secret is configured.
- Excluded Android/iOS Firebase configuration files from Git.
- Adjusted the widget test so it tests the UI shell without requiring a live Firebase session.

## Not yet complete / acceptance blockers

1. The home feed, post publishing, likes/comments, stories, reels viewing/publishing, user search/following, profile editing/post grid, and text direct messages now use Firebase. Remaining surfaces still using local or placeholder behavior include saved-post UI, parts of profile/settings, notifications, story viewer tracking/highlights/replies, message attachments/read receipts, and some explore/share/report actions.
2. The private `android/app/google-services.json` file has not been installed in the local project or supplied to CI. It must match `com.irshogram.app`.
3. Firebase Authentication → Phone provider must be enabled in the Firebase Console.
4. Debug and release SHA-1/SHA-256 fingerprints must be registered.
5. Firestore indexes and security rules must be deployed to the Firebase project.
6. Real SMS delivery, account creation, media upload, and cross-device synchronization must be tested on a physical Android device.
7. The latest GitHub Actions run on commit `0fbebe9820769ca35bef226a3ca3025a6354cf25` passed dependency resolution, `flutter analyze`, and all widget/unit tests. The APK steps were intentionally skipped because the protected `FIREBASE_ANDROID_CONFIG_BASE64` Actions secret is not configured. No APK artifact exists yet.
8. Production release signing, push notification delivery, reporting/blocking, privacy controls, moderation, media processing, and broader Instagram-like surfaces remain future work.

## Immediate next engineering work

- CI analysis and tests now pass. Configure the protected Firebase Android config secret, then run CI again to build and upload the APK.
- Finish saved posts, notifications, story viewer tracking/replies/highlights, message attachments/read receipts, account switching, and settings/privacy actions.
- Add proper pagination, media compression/transcoding, upload progress/retry, thumbnails, and lifecycle cleanup.
- Add Cloud Functions or another trusted backend for notification fan-out, follower denormalization if needed, moderation, and cleanup of expired media.
- Add account switching and complete privacy/security settings.
