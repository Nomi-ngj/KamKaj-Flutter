# CI/CD

Three GitHub Actions workflows in `.github/workflows/`.

| Workflow | Trigger | Does |
|----------|---------|------|
| `flutter_ci.yml` | every PR, push to `develop` / `main` | pub get (lockfile enforced when committed) → dependency check → `dart format` check → `flutter analyze` → unit tests → widget tests → coverage artifact → staging APK artifact |
| `android_build.yml` | manual (choose env) or tag `v*` | tests → decode keystore → signed **AAB + APK** → artifacts |
| `ios_build.yml` | manual (choose env) or tag `v*` (macOS runner) | tests → import cert + profile → signed **IPA** → artifact |

Flutter is pinned to **3.47.7** (`FLUTTER_VERSION` in each workflow) and Flutter, pub and Gradle
caches are enabled.

## One-time setup

1. Run `./tool/setup_platforms.sh` locally and **commit `android/`, `ios/` and `pubspec.lock`**.
   The script wires Android release signing to `android/key.properties`.
2. iOS: in Xcode → Runner → Signing & Capabilities → **Release**: turn off automatic signing,
   choose your team and the App Store provisioning profile. Commit.
3. Create GitHub **Environments** `staging` and `production` and add the secrets below to each.

## Secrets

| Secret | Used by | How to get it |
|--------|---------|---------------|
| `API_BASE_URL` | Android, iOS | Backend base URL for that environment |
| `ANDROID_KEYSTORE_BASE64` | Android | `base64 -i upload-keystore.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | Android | Keystore password |
| `ANDROID_KEY_ALIAS` | Android | Key alias (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | Android | Key password |
| `IOS_DISTRIBUTION_CERT_P12_BASE64` | iOS | Export "Apple Distribution" cert from Keychain as .p12, then base64 |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | iOS | Password used for the .p12 |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS | Download the App Store profile, base64 it |
| `IOS_TEAM_ID` | iOS | Apple Developer → Membership |

Optional **variables**: `API_BASE_URL_STAGING` (CI APK), `IOS_BUNDLE_ID` (default
`com.kamkaj.kamkajPro`), `IOS_EXPORT_METHOD` (default `app-store-connect`; use `ad-hoc` for
testers).

Create an Android upload keystore:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Security

- Keystores, passwords, certificates and profiles exist only as encrypted GitHub secrets and are
  deleted from the runner after use. `.gitignore` blocks `key.properties`, `*.jks`, `*.p12`,
  `*.mobileprovision` and `.env*`.
- Release builds set `USE_MOCK_API=false`; mock data can't ship to production by accident.
- Each workflow fails fast with a clear message if a secret or platform folder is missing.

## Local release builds

```bash
# Android (needs android/key.properties — see android_build.yml for the format)
flutter build appbundle --release --dart-define-from-file=config/production.json

# iOS
flutter build ipa --release --dart-define-from-file=config/production.json
```
