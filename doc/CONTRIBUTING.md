# Contributing to anchor_kit

Thanks for your interest. This is a young project — every issue and PR helps.

## Development setup

```bash
git clone https://github.com/redhotsixbull/anchor_kit.git
cd anchor_kit
flutter pub get
flutter analyze
flutter test
```

Run the example app:

```bash
cd example
flutter pub get
flutter run -d macos   # or ios / android / chrome
```

## Code style

- `dart format .` before committing.
- `flutter analyze` must be clean (zero info/warning/error).
- New public APIs need a dartdoc `///` comment on the class / member.
- Prefer relative imports inside `lib/src/`, package imports (`package:anchor_kit/...`) in tests and examples.

## Tests

- **Positioning logic** goes in unit tests using `computePosition` directly
  — no widgets needed. The pure function makes this cheap.
- **Widget behavior** (measurement, re-positioning on scroll) goes in
  `testWidgets`. Prefer verifying the resulting `Offset` / `Placement` via
  `middlewareData`, not pixel-perfect layout.
- Every bug fix ships with a regression test.

## Middleware contract

If you're adding a new middleware:

1. It must implement `Middleware` and be **pure** (same input → same output).
2. It should be **idempotent** where meaningful (applying it twice = applying once).
3. It should document what it puts in `data`, and use a unique key.
4. Add unit tests that verify:
   - No-op case (input already satisfies the constraint).
   - Active case (middleware actually changes something).
   - Data-emission case (`middlewareData` contains the expected key).

## Commits

- Present-tense imperative subject: `add size middleware`, not `added`.
- Reference the issue if applicable: `add size middleware (fixes #7)`.
- Keep commits small and focused.

## PRs

- One logical change per PR.
- Fill in the description: what changed, why, and how to test.
- Green CI is required.
- Breaking API changes need a `CHANGELOG.md` entry and, on merge, a minor
  version bump (pre-1.0). After 1.0 they need a major bump.

## Roadmap alignment

Before starting a large feature, please open a discussion issue or check
[ROADMAP.md](./ROADMAP.md) to see if it's already planned or explicitly
out of scope.
