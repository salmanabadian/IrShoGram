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

## Google Sign-In troubleshooting

The Android implementation of the Flutter `google_sign_in` plugin uses Android
Credential Manager. The plugin is automatically included when the app depends on
`google_sign_in`; do not add a second, manually pinned Credential Manager stack
without first confirming a dependency-resolution problem.

If the app reports
`getCredentialAsync no provider dependencies found` or
`providerConfigurationError`:

1. Update Google Play Services and the Play Store on the Android device.
2. Confirm that at least one Google account is added to the device's Android
   account settings, then restart the device.
3. If the provider error remains, verify the app package, Web OAuth client, and
   SHA-1/SHA-256 fingerprints for the certificate that signed the exact APK
   being installed. A CI-built APK can use a different debug certificate from a
   local build.
4. Re-download the Firebase Android configuration after correcting OAuth
   fingerprints, then rebuild the APK.

The plugin's official Android setup and troubleshooting notes are available at
[google_sign_in_android](https://pub.dev/packages/google_sign_in_android).

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

The workflow restores the private Android Firebase configuration from either
repository Actions secret:

- `FIREBASE_ANDROID_CONFIG_JSON`: the complete raw contents of the fresh
  `google-services.json` file (recommended for users without a computer).
- `FIREBASE_ANDROID_CONFIG_BASE64`: Base64-encoded contents of that file.

Only pushes and manual workflow runs on `firebase-foundation` perform the
Firebase-configured APK build and signing-certificate check. Pull-request runs
still execute Flutter analysis/tests and build the preview APK, but skip the
Firebase APK step because GitHub gives pull-request workflows a different cache
scope from branch pushes. When registering the Android SHA-1, use the fingerprint
printed by a push or manual run on `firebase-foundation`, not a pull-request run.

Never put the JSON, OAuth credentials, API keys, or signing material in source
control, issues, or chat. When neither secret is configured, CI can still run
analysis and tests but intentionally skips the Firebase-configured APK build.

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
