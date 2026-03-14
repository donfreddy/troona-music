# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (required after adding/changing injectable annotations or Isar schemas)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Lint / static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/unit/domain/use_cases/play_track_use_case_test.dart
```

## Architecture

**Feature-First + Clean Architecture.** Each feature under `lib/features/` is self-contained with three layers:

```
feature/
├── domain/       # Entities, Repository interfaces, Use Cases — pure Dart, no Flutter
├── data/         # Models, DataSources, Repository implementations
└── presentation/ # Pages, Widgets, Bloc/Cubit
```

### Key architectural rules
- The **Domain layer** has zero Flutter or third-party imports. It only speaks to interfaces.
- The **audio engine** is isolated behind `AudioServicePort` (in `lib/features/player/domain/ports/`). The Domain never imports `just_audio` or `audio_service` directly.
  - `JustAudioAdapter` implements `AudioServicePort` (the real playback engine).
  - `AudioHandlerImpl` bridges `audio_service` (lock-screen/notifications) to `AudioServicePort` — it delegates everything and has no business logic.
  - Wired together in `AudioServiceInitializer.init()` which must run before DI registration.

### Dependency Injection
Uses **get_it** with **manual** registration in `lib/core/di/injection.dart` (`configureDependencies()`). The `injectable` package is listed as a dependency but annotations are not the source of truth — `injection.dart` is. `PlayerBloc` and `LibraryBloc` are registered as `registerFactory` (new instance per use); everything else is `registerLazySingleton`.

### State Management
`flutter_bloc` throughout. Blocs are provided at the ShellRoute level via `MultiBlocProvider` in `app_router.dart`, making `PlayerBloc` and `LibraryBloc` available to all shell pages. `FullPlayerPage` is outside the shell and receives `PlayerBloc` via `BlocProvider.value`.

### Navigation
`go_router` with a `ShellRoute` wrapping all bottom-nav pages (`/home`, `/queue`, `/search`, `/visualizer`). The full player (`/player`) is a `CupertinoPage` fullscreen dialog outside the shell.

### Storage
`IsarLibraryDataSource` is currently an **in-memory implementation** (despite the name). The Isar DB persistence layer is not yet wired. Artwork files are cached to `Directory.systemTemp/troona_artwork_cache`.

### Design System (Glassmorphism)
Three-level token hierarchy in `lib/core/theme/`:
1. **Primitives** — raw colors, sizes, radii
2. **Semantic** — `bgPrimary`, `glassFill`, `glassBorder`, `accent`
3. **Components** — `GlassCard` with low/medium/high blur presets

`BackdropFilter` performance rules (enforced throughout):
- Always wrap in a `RepaintBoundary`.
- Never place inside an `AnimatedBuilder` that rebuilds on audio position.
- Maximum two `BackdropFilter`s on screen at once.

### Library Scanning (4-phase)
`MediaScannerService` orchestrates: (1) query device via `on_audio_query_pluse`, (2) diff against cache to find added/removed tracks, (3) persist to `IsarLibraryDataSource`, (4) extract artwork via `ArtworkExtractor` (semaphore × 4 for concurrency control).

### Misc
- App is **portrait-only** (locked in `main.dart`).
- Dark theme only (`ThemeMode.dark`).
- `flutter_screenutil` is used for responsive sizing — initialize before use in widget trees.
