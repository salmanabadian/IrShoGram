# IrShoGram — Engineering Audit and Instagram-Parity Roadmap

This document is a handoff for Codex and future contributors. It records verified facts from the committed `main` branch inspected on 2026-11-07 and defines the intended product scope. It is not a claim that the listed features are already implemented.

## Product goal

Build IrShoGram as a production-oriented social networking app with the breadth and interaction patterns of the current Instagram product (2026), while retaining IrShoGram's own name, visual identity, assets, and implementation. Do not use Instagram's proprietary source code, logos, or copied assets.

The target is a real multi-user service, not a static UI demo. Features must work across separate accounts/devices through authenticated backend services. Do not label local-only behavior as online functionality.

## User-approved navigation and home layout

- Home header: notifications heart at top-left, centered IrShoGram wordmark, plain plus icon at top-right.
- Stories: horizontal circular avatars below the header.
- Bottom navigation, left to right: Home, Search, Direct Messages (center), Reels, Profile.
- Reels: full-screen vertical video feed with swipe navigation.
- Support multiple signed-in accounts and account switching.

## Verified current-state findings (committed source)

1. `pubspec.yaml` does not include `firebase_core`, `firebase_auth`, `cloud_firestore`, or `firebase_storage`.
2. `lib/main.dart` starts the UI directly with `runApp`; it does not initialize Firebase or establish an authenticated session.
3. The current home UI calls `LocalSocialStore` and persists posts, stories, messages, profile, and following data on the device using SharedPreferences/local files. It is not cross-device social functionality.
4. `lib/repositories/social_repository.dart` defines a broad backend contract, but the inspected source does not provide a Firebase implementation wired into the UI.
5. Firestore and Storage rules exist, but rules alone do not create authentication or connect the app to Firebase.
6. The supplied Firebase Android config registers package `com.irshogram.app`, while the committed Android Gradle `applicationId` and `namespace`, plus `MainActivity.kt`, use `com.example.irshogram`. These must be deliberately aligned. Do not change only one of these values.
7. The supplied `google-services.json` is not in the repository. Keep it out of public Git history; configure it locally at the Android app module level or use a documented FlutterFire configuration workflow.
8. The latest inspected CI run had passing setup/dependency/analyze steps but failed tests; Android APK build and upload were skipped. Fix and rerun tests before claiming a successful build.

## Implementation order

### Phase 1 — Establish a safe Firebase foundation
- Choose one canonical Android application ID and align Gradle namespace/applicationId and Kotlin package/path.
- Configure FlutterFire dependencies and Android Google Services plugin using mutually compatible stable versions.
- Initialize Firebase before `runApp`, with clear configuration errors rather than silently falling back to demo mode.
- Add a Google-only authentication/session layer using Firebase Authentication and Google Sign-In.
- Handle Google OAuth token acquisition, cancellation, provider/configuration errors, sign-out, and auth-state restoration.
- Add user profile creation after successful first sign-in; enforce unique usernames transactionally.
- Add Firebase Authentication emulator coverage for auth-state and profile bootstrap; do not add phone/SMS sign-in.
- Keep Firebase configuration files and signing secrets out of public commits.
- Document required Firebase Console steps: enable Phone provider, register the exact Android package, add debug/release SHA fingerprints, and verify the authorized domain/app configuration as applicable.
- Do not claim SMS works until an actual Android device test completes end-to-end.

### Phase 2 — Real social backend
Implement the existing `SocialRepository` and `MediaStorageRepository` contracts (or revise them coherently) against Firestore and Storage. Use server timestamps, pagination, transactions/batched writes where appropriate, ownership checks, and indexes. Audit Firestore/Storage rules against every operation before deployment. Do not weaken rules to make client requests pass.

Required real operations:
- user profiles, username lookup/search, follow/unfollow and counts
- feed posts, media upload, caption editing/deletion
- likes, comments, saved posts
- stories with 24-hour expiry and viewer tracking
- reels and full-screen feed pagination
- conversations and real-time direct messages, including media
- notifications, read state, and push delivery
- report/block/restrict and privacy controls

### Phase 3 — Complete app surfaces and interaction parity
Implement and test:
- Google sign-in onboarding, profile setup, and session management (Google account recovery remains with Google)
- home feed and ranking/pagination
- story composer/viewer/replies/highlights
- post composer with image/video selection, crop/edit tools, carousel, drafts
- search/explore, user discovery, hashtags/audio discovery as product scope allows
- full-screen Reels feed, audio attribution, comments, sharing, save and creator actions
- Direct inbox, message requests, read receipts, typing/presence where appropriate, attachments
- notifications activity screen
- profile grid, tagged content, saved collections, edit profile
- multiple accounts and reliable account switching
- settings, privacy, security, blocked accounts, report flows
- light/dark themes, accessibility, localization, responsive layouts

### Phase 4 — Production quality
- Add unit, widget, repository, security-rules, and integration tests.
- Add crash reporting, analytics with consent/privacy controls, performance monitoring, and structured logging.
- Add pagination, caching, retry/backoff, offline states, upload progress, cancellation, and graceful error states.
- Validate media limits, file types, abuse prevention, rate limits, moderation/report escalation, and data deletion/export requirements.
- Add release signing, app icons/splash, versioning, CI APK/AAB builds, and deployment documentation.

## Engineering rules for Codex

- Before editing, fetch the latest remote branch and inspect uncommitted/local work. Do not overwrite newer work or assume the local workspace matches GitHub.
- Work in small, reviewable commits. Avoid replacing the entire app with a mockup or rewriting unrelated files.
- Preserve the user-approved navigation and home layout unless the user explicitly changes it.
- Never use local SharedPreferences as the source of truth for multi-user posts/messages. Local caching is allowed only as a cache.
- Never silently fall back to fake users, fake posts, or local demo data in production.
- Every visible control must have a real action and a loading, empty, success, and error state where relevant.
- A feature is complete only when its UI, backend, security rules, tests, and device behavior are verified.
- Report what changed, which files changed, tests/build results, and any Firebase Console action still required. Clearly separate implemented, partially implemented, and planned items.

## Immediate blocker checklist

- [ ] Confirm Firebase Authentication > Sign-in providers > Google is enabled; phone/SMS authentication is intentionally out of scope.
- [ ] Confirm the canonical Android package ID. The supplied config currently says `com.irshogram.app`.
- [ ] Add the matching `google-services.json` locally (do not commit it publicly).
- [ ] Add debug and release SHA-1/SHA-256 fingerprints in Firebase.
- [ ] Complete an actual Google sign-in test on a physical Android device.
- [ ] Replace the current local-only home flows with the authenticated repository incrementally.
