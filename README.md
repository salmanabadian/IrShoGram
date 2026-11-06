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

## Firebase backend preparation

The repository includes Firebase CLI configuration, Firestore security rules,
Cloud Storage security rules, and initial Firestore indexes.

These files are a security baseline and deployment preparation only. They are not
active until Firebase is configured for the correct Android app and the rules are
deployed to the intended Firebase project. Do not use Firebase test mode or public
read/write rules.

### Initial data model

- `users/{uid}`: public profile fields owned by the authenticated user
- `users/{uid}/following/{targetUid}`: accounts followed by the user
- `users/{uid}/followers/{followerUid}`: follower records maintained by trusted backend code
- `users/{uid}/savedPosts/{postId}`: the user's saved posts
- `users/{uid}/notifications/{notificationId}`: notifications created by trusted backend code
- `posts/{postId}` with `likes/{uid}` and `comments/{commentId}` subcollections
- `stories/{storyId}` and `reels/{reelId}`
- `conversations/{conversationId}` with a two-user `participantIds` list and `messages/{messageId}`

### Storage paths

- `users/{uid}/profile/{fileName}`
- `posts/{uid}/{fileName}`
- `stories/{uid}/{fileName}`
- `reels/{uid}/{fileName}`

The initial Storage rules restrict writes to the owning authenticated user, validate
media MIME types, and enforce upload size limits. The current limits are 10 MiB for
images and 100 MiB for videos.

### Deployment gate

Before deploying, verify the Firebase project ID and Android package name against
the supplied client configuration. Review the rules against the final application
data model, deploy to a non-production test project first, and run emulator/security
tests. Notifications, follower counters, moderation, abuse prevention, and privileged
data changes must be performed by trusted server code, never by clients.
