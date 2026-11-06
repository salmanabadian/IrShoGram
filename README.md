# IrShoGram

IrShoGram is a Flutter-based social app prototype.

## Current app foundation

- Home feed with sample posts and a horizontal stories row
- Post interactions: like, save, and local comments
- Search screen with local sample-user filtering
- Direct-message list and local chat UI
- Full-screen vertical Reels-style browsing with sample placeholders
- Profile screen, theme switch, and account-management entry point
- Persian interface with right-to-left page content and five-tab navigation

## Important implementation status

The screens currently use local demonstration data. Real accounts, secure authentication, multiple-account sessions, server-backed posts, media upload and playback, notifications, and real-time messaging still require a backend service and must not be treated as production-ready.

## Checks

GitHub Actions runs Flutter dependency installation, static analysis, widget tests, and a release APK build on pushes and pull requests to the main branch. A successful workflow run is required before treating the Android build as verified.
