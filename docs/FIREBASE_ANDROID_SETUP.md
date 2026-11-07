# Firebase Android setup for IrShoGram

## Registered Android application

The Android Gradle namespace and application ID are both:

`com.irshogram.app`

The Firebase Android app's `google-services.json` must have this exact package name. Place the downloaded file at:

`android/app/google-services.json`

Do not rename it to `google-services (1).json`. The file is intentionally excluded from public source control.

## Firebase Console checklist

1. Open Firebase Console and select the IrShoGram project.
2. In Authentication → Sign-in method, enable **Phone**.
3. Confirm the Android app registered in Project settings uses `com.irshogram.app`.
4. Add the debug and release SHA-1 and SHA-256 fingerprints for the signing certificates used by the app.
5. Confirm the Firestore database and Storage bucket exist.
6. Deploy `firestore.rules`, `storage.rules`, and `firestore.indexes.json` from this repository.
7. Test phone verification on a physical Android device. Use Firebase test phone numbers during development to avoid repeated SMS quota use.

## Local build

After placing the config file at the path above:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The first release build currently uses the Android debug signing configuration. It is suitable for controlled installation/testing, not a production store release. A private release keystore and signing configuration must be added before publishing.

## GitHub Actions APK builds

The workflow can restore the config file from a protected repository Actions secret named:

`FIREBASE_ANDROID_CONFIG_BASE64`

Create the secret with the Base64-encoded contents of the exact `google-services.json` file. For example, on Linux/macOS:

```bash
base64 -w 0 android/app/google-services.json
```

Copy the output into the repository's Settings → Secrets and variables → Actions → New repository secret. Never paste the raw JSON or its API key into source files, issues, or chat messages. If this secret is absent, CI still runs dependency resolution, analysis, and tests, but intentionally skips the Firebase-configured APK build.

## Phone-auth limitations

Phone OTP delivery depends on Firebase project settings, allowed regions, quotas, billing/risk controls, and valid signing fingerprints. A successful code compile does not prove that real SMS delivery works. The first physical-device login is a required acceptance test.

8. Link the Firebase project to a Cloud Billing account before relying on SMS delivery. Firebase's no-cost SMS allowance on the Spark plan was discontinued for Phone Authentication in September 2024.
9. Configure the Authentication SMS region policy explicitly. New projects may default to allowing no regions; only allow the countries where your users actually need SMS delivery.

## Important note for +98 (Iran) phone numbers

Firebase says phone verification is supported globally, but its published list of regions with good expected delivery rates does not include Iran. That does not prove every Iranian carrier will fail, but it means delivery to +98 cannot be promised and must be tested with the actual carrier. Keep an alternate sign-in/recovery path available if the app is intended for users in Iran.
