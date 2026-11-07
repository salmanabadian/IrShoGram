# Firebase Android setup for IrShoGram

## Registered Android application

The Android Gradle namespace and application ID are both `com.irshogram.app`.
The Firebase Android app's `google-services.json` must use this exact package name
and be placed at `android/app/google-services.json`. This private file is excluded
from Git and must never be committed or pasted into chat.

## Google-only authentication

The current authentication flow uses Google Sign-In with Firebase Authentication.
Phone-number authentication is intentionally out of scope and must not be enabled
or referenced by the app's current sign-in flow.

In Firebase Console:

1. Open the IrShoGram Firebase project.
2. Go to Authentication → Sign-in method and enable **Google** only for the
   current app flow. Select a support email and save.
3. Confirm the registered Android app package is `com.irshogram.app`.
4. Register the debug and release SHA-1 and SHA-256 signing fingerprints.
   Google Sign-In depends on matching fingerprints and OAuth client configuration.
5. Download a fresh `google-services.json` after changing fingerprints and use it
   for local or CI builds.
6. Confirm Firestore and Cloud Storage are enabled.

## Local build

After placing the correct configuration file:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The current Gradle release build uses debug signing. It can be used for controlled
testing but is not a production-store signing configuration. Add a private release
keystore and protected signing configuration before distribution.

## GitHub Actions

The workflow restores the private Android Firebase configuration from the repository
Actions secret `FIREBASE_ANDROID_CONFIG_BASE64`. The secret must contain the
Base64-encoded contents of the exact `google-services.json` file.

Never put the raw JSON, OAuth credentials, API keys, or signing material in source
control, issues, or chat. When the secret is unavailable, CI can still run analysis
and tests but intentionally skips the Firebase-configured APK build.

## Firebase backend deployment

The repository contains Firestore rules, Storage rules, and composite indexes.
Their presence in Git does not prove that they are deployed. Review them against
the final data model, deploy to a non-production Firebase project first, and run
Firestore/Storage emulator security tests before production use.

## Device acceptance checklist

- Sign in with a real Google account on a physical Android device.
- Confirm Firebase creates exactly one account identity and a user profile.
- Confirm the session survives app restart and sign-out returns to the Google sign-in screen.
- Verify profile data and media uploads sync across two devices.
- Confirm network failures and provider/configuration errors are shown safely.
