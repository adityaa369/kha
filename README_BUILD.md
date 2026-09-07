# Khatha — Release Build Environment

This document records the **exact** toolchain used to produce the Phase 4H-B3 release artifact.

## Verified Build Environment

| Tool | Exact Version | Notes |
|------|--------------|-------|
| Flutter | 3.41.4 (stable) | `flutter --version` |
| Dart | 3.11.1 | Bundled with Flutter 3.41.4 |
| Android Gradle Plugin | 8.11.1 | `android/settings.gradle.kts` |
| Gradle | 8.14 | `android/gradle/wrapper/gradle-wrapper.properties` |
| JDK | 21 (Oracle SE 21+35-LTS-2513) | `java --version` |
| Node.js | 20.12.2 | Backend API server |
| npm | 10.8.2 | Node package manager |

## Flutter Version Pin

The Flutter SDK is pinned to Flutter **3.41.4** on the `stable` channel.
Framework revision: `ff37bef603`

To reproduce this exact environment:
```sh
flutter channel stable
flutter upgrade --force
# Then verify: flutter --version should show 3.41.4
```

## Application Identity
- **applicationId**: `com.vest.khataa`
- **Firebase project_id**: See `android/app/google-services.json` (not committed to this README)

## Release Build Commands
```sh
# Backend
npm install
node index.js   # or: pm2 start ecosystem.config.js

# Flutter release APK
flutter clean
flutter pub get
flutter build apk --release

# Flutter release AAB (for Play Store)
flutter build appbundle --release
```

## Release Signing
- Keystore: `upload-keystore.jks` — **NOT committed to Git** (see `.gitignore`)
- Signing credentials are stored as environment variables only:
  - `KEYSTORE_PASSWORD`
  - `KEY_ALIAS`
  - `KEY_PASSWORD`
- Keystore must be backed up securely offline (e.g., encrypted cloud storage separate from this repo) and ownership documented with the production release team before first Play Store upload.
- The same `upload-keystore.jks` must be used for all future updates to maintain Play Store signing continuity.

## Signing Verification
After building, verify the APK is signed with the production key:
```sh
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
# Confirm: SHA256 fingerprint matches the registered upload key fingerprint
```

## Obfuscation & Shrinking
R8 minification and resource shrinking are enabled in the `release` build type (see `android/app/build.gradle.kts`).
ProGuard rules are in `android/app/proguard-rules.pro`.
