# IrShoGram

IrShoGram is a Flutter/Dart Android social networking application under active
development. The goal is a real Firebase-backed social product, not a UI-only demo.

## Current development branch

Work is in progress on `firebase-foundation`; the changes are tracked in an open
pull request and have not been merged into `main`.

## Current foundation

- Firebase Core and Firebase Authentication
- Google Sign-In as the only current authentication method
- Cloud Firestore and Firebase Storage integration
- Auth-state gate and first-login profile creation
- Initial Firebase-backed feed, post publishing, likes/comments, stories, reels,
  user search/following, profile editing, and text direct messages
- Firestore/Storage security-rule and index files
- GitHub Actions validation and conditional release APK artifact build

## Important limitations

Several screens and workflows are still incomplete or partly backed by legacy local
state. Multi-account sessions, secure account deletion, complete privacy controls,
blocking/reporting, push notifications, story view tracking/replies, message media
and read receipts, trusted backend functions, and production release signing remain
unfinished. A successful CI APK build does not replace physical-device and
cross-device acceptance testing.

Phone-number authentication is intentionally excluded from the current scope.

## Build checks

The GitHub Actions workflow runs `flutter pub get`, `flutter analyze`, and
`flutter test`. Pull-request runs also build a preview APK, but intentionally skip
Firebase signing-certificate validation because GitHub scopes Actions caches
differently for pull requests and branch pushes. Pushes and manual runs on
`firebase-foundation` perform the Firebase configuration check and build the
Firebase-configured release APK when either protected repository secret is set:

- `FIREBASE_ANDROID_CONFIG_JSON`: raw contents of the fresh
  `google-services.json` file (recommended).
- `FIREBASE_ANDROID_CONFIG_BASE64`: Base64-encoded contents of that file.

Never commit Firebase client configuration, OAuth credentials, or signing keys.

See [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) and
[docs/FIREBASE_ANDROID_SETUP.md](docs/FIREBASE_ANDROID_SETUP.md) for current status
and setup requirements.
