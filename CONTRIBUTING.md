# Contributing

## Workflow

- Branch from `develop`: `feature/<short-name>`, `fix/<short-name>`.
- Open a PR into `develop`; `main` is release-only. CI must be green.
- Commit messages: imperative, e.g. `Add wallet balance to profile`.

## Before you push

```bash
dart format lib test integration_test
flutter analyze
flutter test
```

## Code rules

- Follow [ARCHITECTURE.md](ARCHITECTURE.md): widgets → ViewModels → use cases → repositories.
  No API calls or business rules in widgets.
- Styling only via design tokens and components ([DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)).
- Private by default (`_`), `final` fields, `const` constructors, `final class` unless
  extension is intended.
- No `dynamic`, no unexplained `!`, no `print` (use `AppLogger`), no secrets in code or logs.
- Every new use case, ViewModel and non-trivial widget gets a test.
- New screens follow the Figma file; document any assumption in FIGMA_ANALYSIS.md §7.

## Review checklist

- [ ] Matches Figma (spacing, type, colours via tokens)
- [ ] Loading, empty, error and offline states handled
- [ ] Works in RTL and with large text
- [ ] Tests added / updated
- [ ] Docs updated (API_DOCUMENTATION.md for new endpoints)
