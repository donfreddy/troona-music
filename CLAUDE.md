# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (required after changing Isar collections; the .g.dart files are committed)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Lint / static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/unit/player/queue_test.dart
```

Tests live in `test/unit/` (pure logic, blocs, repositories) and `test/widget/`. Shared player test doubles (`FakeAudioPort`, `buildTestPlayerBloc`, `testTrack`) are in `test/helpers/fake_player.dart`. The Isar tests run against the real engine, loading the host library shipped by `isar_plus_flutter_libs`.

## Architecture

**Feature-First + Clean Architecture.** Each feature under `lib/features/` is self-contained with three layers:

```
feature/
├── domain/       # Entities, Repository interfaces, Use Cases: pure Dart, no Flutter
├── data/         # Models, DataSources, Repository implementations
└── presentation/ # Pages, Widgets, Bloc/Cubit
```

App-wide services that are not a feature live in `lib/services/` (`audio/`, `scanner/`, `history/`).

### Key architectural rules
- The **Domain layer** has zero Flutter or third-party imports (`dartz` excepted). It only speaks to interfaces.
- The **audio engine** is isolated behind `AudioServicePort` (in `lib/features/player/domain/ports/`). The Domain never imports `just_audio` or `audio_service` directly.
  - `JustAudioAdapter` implements `AudioServicePort` (the real playback engine).
  - `AudioHandlerImpl` bridges `audio_service` (lock screen, notifications) to `AudioServicePort`. It delegates everything and has no business logic.
  - Wired together in `AudioServiceInitializer.init()`, called from `configureDependencies()` before the player is registered.

### Dependency Injection
Uses **get_it** with **manual** registration in `lib/core/di/injection.dart` (`configureDependencies()`). The `injectable` package is listed as a dependency but annotations are not the source of truth: `injection.dart` is.
- Singletons: `PlayerBloc`, `TrackPaletteCubit`, `LikesCubit`, `SleepTimerCubit`, `SettingsCubit` (shared by Settings and Home's offer card, provided with `BlocProvider.value`), the audio port, the Isar data sources, `PlayHistoryRecorder` (started eagerly).
- Factories (new instance per mount): `LibraryBloc`, `HomeBloc`, `SearchBloc`, the detail blocs, `MaintenanceCubit`.
- Repositories and use cases are lazy singletons.

### State Management
`flutter_bloc` throughout. `PlayerBloc` and `LibraryBloc` are provided at the shell level via `MultiBlocProvider` in `app_router.dart`, making them available to all shell pages. `FullPlayerPage` is outside the shell and receives `PlayerBloc` via `BlocProvider.value`. Queue edits (`QueueEditEvent`) go through a single sequential handler so they apply in order.

### Navigation
`go_router` with a `StatefulShellRoute.indexedStack` wrapping the bottom-nav branches (`/home`, `/library`, `/search`, `/playlists`). The full player (`/player`) is a fullscreen `CustomTransitionPage` on the root navigator, outside the shell; it morphs from the mini player through Hero flights (`now_playing_hero.dart`). The queue opens as a modal sheet over it (`queue_sheet.dart`).

### Storage
One Isar database (`isar_plus`), opened by `AppDatabase.open()` in `lib/core/database/`. Each data source declares its collections (`IsarLibraryDataSource.schemas`, `IsarPlayHistoryDataSource.schemas`) and `injection.dart` passes them in, so core never imports a feature. Adding a collection needs no migration.
- Library: tracks and playlists (`IsarLibraryDataSource`).
- Play history: `PlayEventModel`, capped at 500 events (`lib/features/history/`). `PlayHistoryRecorder` records a play after 30 s of listening, or half a track shorter than a minute (`PlayCounter`). Home "Recently Played" reads it.
- Daily totals, never pruned, written in the same transaction as each play: `ListeningDayModel` (plays, listening time), `TrackDayModel` (plays per track per day), `TrackFirstPlayModel`. Days are `ListeningDay` keys (local calendar days since epoch). The recorder writes listening time every 30 s, on a track change and at midnight. "Your week in music" (`WeeklyRecapCubit`) reads them, and so does the monthly Replay playlist (`CreateMonthlyReplayUseCase`, run once per month from `AppShell`; the handled month is kept in `SharedPreferences`).
- Playback session (queue, position) is saved to `SharedPreferences` by `PlaybackSessionStore`.
- Last version whose "What's new" was handled: `SharedPreferences` (`SharedPrefsWhatsNewRepository`). Add a `Release` to `releaseNotes()` with each version that should show the sheet.
- Covers extracted from local files are cached in the app cache directory under `troona_artwork_cache`.
- Online extras are opt-in, behind two switches: bios (Last.fm) and photos (Deezer). `MetadataRepositoryImpl` contacts each source only when its switch is on. Their JSON and downloaded photos live under `troona_metadata_cache` (photos in `photos/`), so "clear online info" removes and measures both. Turning photos off deletes the downloaded ones.

### Design System (Glassmorphism)
Three-level token hierarchy in `lib/core/theme/`:
1. **Primitives**: raw colors, sizes, radii
2. **Semantic**: `bgPrimary`, `glassFill`, `glassBorder`, `accent`
3. **Components**: `GlassConfig` presets per surface and quality tier (high, low, off). `GlassCard` is flat by default: blur is for chrome (tab bar, header, sheets, Now Playing), never for cards in scrolling content.

Every `BackdropFilter` takes `GlassFilter.of(sigma, saturation: config.saturation)`, never a bare `ImageFilter.blur`. Surfaces that carry text are thick and keep colours as they are: `GlassTheme.bar` (tab bar, collapsed header) and `GlassTheme.sheet` (about 70 % dark fill, saturation 1), so covers behind them never show as coloured stains. The 1.6x saturation boost is for decorative glass over artwork (Now Playing lens and dock).

`BackdropFilter` performance rules (enforced throughout):
- Always wrap in a `RepaintBoundary`.
- Never place inside an `AnimatedBuilder` that rebuilds on audio position.
- Maximum two `BackdropFilter`s on screen at once (the Now Playing page already uses both, so sheets over it are opaque).
- One exception: a short-lived modal sheet over the shell (the tab bar blurs below it, a collapsed header may too) may add a third blur on high-tier devices only. Its quality comes from `GlassTheme.aboveGlass(context)`, which is opaque on low-tier devices and when the user turns glass down. Used by "What's new"; not for anything that stays on screen.

Artwork is decoded at its displayed size through `ArtworkImage` (`lib/shared/widgets/artwork_image.dart`).

### Library Scanning (4-phase)
`MediaScannerService` orchestrates: (1) query device via `on_audio_query_pluse`, (2) diff against cache to find added/removed tracks, (3) persist to `IsarLibraryDataSource`, (4) extract artwork via `ArtworkExtractor` (semaphore × 4 for concurrency control).

### Misc
- App is **portrait-only** (locked in `main.dart`).
- Dark theme only (`ThemeMode.dark`).
- `flutter_screenutil` is used for responsive sizing: initialize before use in widget trees.
