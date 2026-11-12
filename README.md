# KamKaj Pro

Local delivery, shopping and ride-services app built in Flutter from the
[Figma design](https://www.figma.com/design/9kC9eVbqZ1vW51K57fst2G/Nouman-Gul-Junejo-s-team-library?node-id=0-1).

**Stack:** Flutter 3.47 · Dart 3.13 · Clean Architecture + MVVM · Riverpod 3 · GoRouter · Dio ·
flutter_secure_storage · SharedPreferences · Mocktail · GitHub Actions

## Quick start (VS Code)

```bash
cd ~/development/kamkaj_pro
./tool/setup_platforms.sh       # one-time: creates android/ & ios/, wires signing, pub get
code .                          # open in VS Code
```

Then press **F5** and pick a launch configuration (`Development`, `Staging`, `Production`)
from `.vscode/launch.json`.

**Demo login (mock backend):** `hello@appname.com` / `Password1`.
Any 6-digit verification code works except `000000`, which simulates a wrong code.

## Running

| Task | Command |
|------|---------|
| Run (mock API, default) | `flutter run` |
| Run against a real API | `flutter run --dart-define-from-file=config/staging.json` |
| Analyze | `flutter analyze` |
| Format | `dart format lib test integration_test` |
| Unit tests | `flutter test --exclude-tags widget` |
| Widget tests | `flutter test --tags widget` |
| Coverage | `flutter test --coverage` |
| Integration test | `flutter test integration_test` (device/simulator) |
| Release APK | `flutter build apk --release --dart-define-from-file=config/production.json` |

## Images from Figma

Photos and 3D illustrations must be exported from Figma into `assets/images/` using the file
names in [FIGMA_ANALYSIS.md §6](FIGMA_ANALYSIS.md). Until then every image shows a
design-system placeholder, so the app runs without them.

## Documentation

| Doc | What's inside |
|-----|---------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layers, folders, adding features / ViewModels / repositories / DI |
| [FIGMA_ANALYSIS.md](FIGMA_ANALYSIS.md) | Screens, flows, tokens, assets, assumptions |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | Tokens & components and how to use them |
| [API_DOCUMENTATION.md](API_DOCUMENTATION.md) | Backend contracts, adding endpoints, mock mode |
| [TESTING.md](TESTING.md) | Test strategy and how to run each suite |
| [CI_CD.md](CI_CD.md) | Workflows, secrets, signing |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branching, code style, review checklist |
| [DEVELOPMENT_PROGRESS.md](DEVELOPMENT_PROGRESS.md) | What's done and what's pending |
