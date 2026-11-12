# Development Progress

_Last updated: 11 Nov 2026_

## Done

| Phase | Status |
|-------|--------|
| 1 · Figma analysis | ✅ 23 frames inventoried, tokens extracted → FIGMA_ANALYSIS.md |
| 2 · Foundation | ✅ pubspec, strict analysis options, environments (`config/*.json`), bootstrap, DI, GoRouter with guards, theme |
| 3 · Core | ✅ Dio client + auth/refresh + logging interceptors, Result/Failure/ErrorMapper, secure & prefs storage, validators, Money |
| 4 · Features | ✅ Splash, Onboarding ×3, Language (RTL), Sign In, Sign Up, Forgot Password, Verify Email (OTP + resend timer), Reset Password, Change Password, Dashboard, Explore/Categories (+ stores sheet), Store Detail, Product Detail, Basket, Checkout, Saved Addresses (+ set-default dialog), Add/Edit Address, My Orders (pay, track, re-order), Services (book a ride), Profile |
| 5 · Quality | ✅ 15 unit/widget test files + integration journey; import/symbol checks |
| 6 · CI/CD | ✅ flutter_ci, android_build, ios_build workflows + signing setup script |
| 7 · Docs | ✅ README, ARCHITECTURE, FIGMA_ANALYSIS, DESIGN_SYSTEM, API_DOCUMENTATION, TESTING, CI_CD, CONTRIBUTING |

## Needs doing on your machine

The project was written in a cloud workspace that has no Flutter SDK, so these still have to
be run locally (Flutter 3.47.7 is installed at `~/development/flutter`):

1. `./tool/setup_platforms.sh` — generates `android/` + `ios/` and runs `pub get`.
2. `flutter analyze` and `flutter test` — fix anything they report (expect at most minor
   lints / version tweaks; nothing has been compiled yet).
3. Export the Figma images listed in FIGMA_ANALYSIS.md §6 into `assets/images/`.
4. Commit `android/`, `ios/`, `pubspec.lock` and push to GitHub to run CI.
5. Run on an iOS simulator and an Android emulator and compare against Figma.

## Pending (needs product / backend input)

- Real backend — contracts in API_DOCUMENTATION.md; switch `USE_MOCK_API=false`.
- Payment provider, maps provider + API key, social sign-in, push notifications, live tracking.
- Translations for Arabic, Urdu, French, Spanish (locale + RTL switching already works).
- Checkout steps 1 & 3, Profile and empty/error states have no Figma frames — built from tokens.
- Golden tests once real images are in place.
