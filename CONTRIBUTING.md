# Contributing to Troona

Thanks for considering a contribution. This document covers the local setup, the conventions the codebase follows, and what a pull request needs before it can be merged. Everyone participating is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

- **Bug reports**: see [Reporting a bug](#reporting-a-bug) below.
- **Translations**: add or improve a locale, see [Translations](#translations).
- **Code**: fixes and well-scoped features. For anything beyond a small fix, open an issue first describing the change, so the approach can be agreed on before you invest time in an implementation that might not fit the architecture.

Troona is a product with a strong design and architecture point of view (see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)). A PR that works but breaks a layering rule or the glass performance budget will be asked to change before merge, not merged with a follow-up TODO.

## Development setup

```bash
git clone https://github.com/<your-fork>/troona-music.git
cd troona-music
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

You need a device or emulator with local audio files to scan: Troona has no demo library or mock data source for the library feature.

## Project conventions

### Architecture

Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) before touching `lib/features/*`. The two rules that matter most for a review:

1. **The domain layer imports nothing Flutter, nothing third-party** (`dartz` excepted). If your use case or entity needs a Flutter type, it belongs in `data/` or `presentation/`, not `domain/`.
2. **The audio engine stays behind `AudioServicePort`.** Nothing outside `lib/features/player/data/adapters/` should import `just_audio` or `audio_service` directly.

Do not change a module's public API (a repository interface, a use case signature, an exported entity) without discussing it in the related issue first: treat public interfaces as a contract other code already relies on.

### Commits

[Conventional Commits](https://www.conventionalcommits.org/), in English:

```
feat(player): add crossfade on manual skip
fix(library): stop rescans from dropping unplayed tracks
refactor(history): extract PlayCounter from the recorder
docs(architecture): document the monthly Replay trigger
chore(deps): bump isar_plus to 1.2.3
```

Keep commits logically scoped: a refactor and a behavior change belong in separate commits even within the same PR.

### Style

- `dart format` and `flutter analyze` must be clean (the CI workflow in `.github/workflows/ci.yml` enforces both, plus `flutter test`).
- Follow the naming and structure already used in the feature you are touching over introducing a new convention. If the codebase does it one way in nine places and you want a tenth way, raise it in the PR description rather than silently diverging.
- No comments that restate what the code does. A comment earns its place only when it explains a non-obvious *why*: a workaround, an invariant, a constraint that isn't visible from the code itself.

### Tests

- Pure logic, blocs and repositories: `test/unit/`. Widgets: `test/widget/`.
- Reuse the shared doubles in `test/helpers/fake_player.dart` (`FakeAudioPort`, `buildTestPlayerBloc`, `testTrack`) instead of writing new ones for player-related tests.
- Isar-backed tests run against the real engine (via `isar_plus_flutter_libs`); do not introduce a mocked persistence layer for new storage code, follow the existing pattern instead.
- A non-trivial function (anything with branching, edge cases, or a failure mode) needs a test covering its edge cases, not just the happy path.

### Translations

Troona currently ships English and French (`lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`), generated via `flutter gen-l10n` (config in `l10n.yaml`) into `AppLocalizations`.

To add a string:

1. Add the key to `lib/l10n/app_en.arb` (the template file) with a description.
2. Add the matching key to every other `.arb` file. A PR that adds a key to only one file will fail review: key parity across locales is enforced manually today, so check it yourself before pushing.
3. Run `dart run build_runner build --delete-conflicting-outputs` (or `flutter gen-l10n`) to regenerate `app_localizations*.dart`, and use `AppLocalizations.of(context)!.yourKey`, never a hardcoded string in `presentation/`.

To add a new locale, create `lib/l10n/app_<code>.arb` with every key from `app_en.arb` translated, and add it to the supported locales list in `app.dart`.

## Before opening a pull request

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

All three must pass: this is exactly what CI runs. In the PR description, show the result (a pasted test summary or a screenshot), not just a claim that it passes. For a UI change, include a before/after screenshot or screen recording.

## Reporting a bug

Open an issue with:

- What you expected vs. what happened.
- Steps to reproduce (the exact tap sequence if it's a UI bug).
- Device, OS version, and Troona version (`Settings → About`, or the app bar on the permission page if you can't get past it).
- The relevant excerpt of the local crash log if the bug caused one (`Settings → Report a problem` exports it; redact anything you don't want to share, since file names can appear in it).

## License

By contributing, you agree that your contribution is licensed under the project's [MIT License](LICENSE).
