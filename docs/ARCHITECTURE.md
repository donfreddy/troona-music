# Architecture

This document describes how Troona is built: the layering rules, the module layout, the design system, and the test structure. It assumes you have already read the [README](../README.md) for the product overview.

## Principles

* **Feature-First + Clean Architecture.** Each feature under `lib/features/` is a self-contained module with three layers: `domain/`, `data/`, `presentation/`.
* **Pure domain.** The Domain layer has zero Flutter or third-party imports (`dartz` excepted). It speaks only to interfaces (repositories, ports), never to a concrete implementation.
* **Ports and adapters for the audio engine.** The Domain never imports `just_audio` or `audio_service` directly. It depends on `AudioServicePort` (`lib/features/player/domain/ports/`); `JustAudioAdapter` is the concrete implementation, and `AudioHandlerImpl` bridges `audio_service` (lock screen, notifications) to that same port with no business logic of its own.
* **One database, declared by its owners.** A single Isar database is opened by `AppDatabase.open()` in `lib/core/database/`. Each data source declares its own collections (`IsarLibraryDataSource.schemas`, `IsarPlayHistoryDataSource.schemas`, …) and `injection.dart` wires them in, so `core` never imports a feature.

```
feature/
├── domain/       # Entities, Repository interfaces, Use Cases: pure Dart, no Flutter
├── data/         # Models, DataSources, Repository implementations
└── presentation/ # Pages, Widgets, Bloc/Cubit
```

App-wide services that are not a feature live in `lib/services/` (`audio/`, `scanner/`, `history/`, `metadata/`).

## Dependency injection

**get_it**, with **manual** registration in `lib/core/di/injection.dart` (`configureDependencies()`). `injectable` is a listed dependency, but its annotations are not the source of truth: `injection.dart` is read top to bottom to know what is wired.

* **Singletons**: `PlayerBloc`, `TrackPaletteCubit`, `LikesCubit`, `SleepTimerCubit`, `SettingsCubit` (shared by Settings and Home's offer card via `BlocProvider.value`), the audio port, the Isar data sources, `PlayHistoryRecorder` (started eagerly).
* **Factories** (new instance per mount): `LibraryBloc`, `HomeBloc`, `SearchBloc`, the detail blocs, `MaintenanceCubit`.
* **Repositories and use cases**: lazy singletons.

## State management

`flutter_bloc` throughout. `PlayerBloc` and `LibraryBloc` are provided at the shell level via `MultiBlocProvider` in `app_router.dart`, available to every shell page. `FullPlayerPage` lives outside the shell and receives `PlayerBloc` via `BlocProvider.value`. Queue edits (`QueueEditEvent`) go through a single sequential handler so they always apply in order, never racing each other.

## Navigation

`go_router` with a `StatefulShellRoute.indexedStack` wrapping the bottom-nav branches (`/home`, `/library`, `/search`, `/playlists`). The full player (`/player`) is a fullscreen `CustomTransitionPage` on the root navigator, outside the shell; it morphs from the mini player through Hero flights (`now_playing_hero.dart`). The queue opens as a modal sheet over it (`queue_sheet.dart`). A `GoRouter` `redirect` acts as a permission guard: no route past the permission page is reachable until audio access is granted.

## Storage

* **Library** (tracks, playlists): `IsarLibraryDataSource`.
* **Play history**: `PlayEventModel`, capped at 500 events (`lib/features/history/`). `PlayHistoryRecorder` records a play after 30 s of listening, or half a track for anything shorter than a minute (`PlayCounter`). Seeks never count. Home's "Recently Played" reads this stream.
* **Daily totals**, never pruned, written in the same transaction as each play: `ListeningDayModel` (plays, listening time), `TrackDayModel` (plays per track per day), `TrackFirstPlayModel`. Days are `ListeningDay` keys (local calendar days since epoch). The recorder writes listening time every 30 s, on a track change, and at midnight. "Your week in music" (`WeeklyRecapCubit`) reads them, and so does the monthly Replay playlist.
* **Monthly Replay**: on the first run of a new month, `CreateMonthlyReplayUseCase` builds last month's 25 most-played tracks into a normal playlist (skipped below five songs), run once from `AppShell` with the handled month tracked in `SharedPreferences` via `SharedPrefsMonthlyReplayLog`.
* **Playback session** (queue, position): `SharedPreferences`, via `PlaybackSessionStore`, written only when it changes.
* **"What's new" state**: last version whose release notes were shown, in `SharedPreferences` (`SharedPrefsWhatsNewRepository`). Add a `Release` to `release_notes.dart` for each version that should surface the sheet.
* **Artwork**: extracted from local files, cached in the app cache directory under `troona_artwork_cache`.
* **Online extras** (opt-in, both off by default): bios from Last.fm, photos from Deezer. `MetadataRepositoryImpl` contacts each source only when its own switch is on, de-dupes in-flight lookups, and caches JSON/photos under `troona_metadata_cache` (photos in `photos/`). "Clear online info" removes and measures both; turning photos off alone deletes only the downloaded photos. See [`docs/privacy-policy.md`](privacy-policy.md).

## Design system: glassmorphism

The visual direction started from a concept by [Shimon Bar Yacov](https://www.behance.net/shimon-bar-yacov) / AmazingUI on [Behance](https://www.behance.net/gallery/233232089/Music-App-Modern-Music-Player-by-AmazingUI); see the README's [Design credit](../README.md#design-credit) for the full note. Everything implemented below is original work.

Three-level token hierarchy in `lib/core/theme/`:

1. **Primitives**: raw colors, sizes, radii.
2. **Semantic**: `bgPrimary`, `glassFill`, `glassBorder`, `accent`.
3. **Components**: `GlassConfig` presets per surface and quality tier (high, low, off). `GlassCard` is flat by default: blur is reserved for chrome (tab bar, header, sheets, Now Playing), never for cards inside scrolling content.

Every `BackdropFilter` takes `GlassFilter.of(sigma, saturation: config.saturation)`, never a bare `ImageFilter.blur`. Surfaces that carry text (`GlassTheme.bar` for the tab bar, mini player and collapsed header; `GlassTheme.sheet`) use a middle material, tuned on a Pixel 8: blur 30, a 15% dark tint and a mild 1.25x saturation boost. The boost never ships without the tint, or thin glass turns covers and colored icons behind it into vivid stains. Their low tier keeps saturation at 1. The full 1.6x boost is reserved for decorative glass over artwork (Now Playing lens and dock).

**`BackdropFilter` performance rules** (enforced throughout the codebase):

* Always wrapped in a `RepaintBoundary`.
* Never placed inside an `AnimatedBuilder` that rebuilds on audio position.
* Maximum two `BackdropFilter`s on screen at once.
* One exception: a short-lived modal sheet over the shell (the tab bar blurs below it, a collapsed header may too) may add a third blur on high-tier devices only, via `GlassTheme.aboveGlass(context)` (opaque on low-tier devices and when the user turns glass down). Used by "What's new"; not for anything that stays on screen.

Artwork is decoded at its displayed size through `ArtworkImage` (`lib/shared/widgets/artwork_image.dart`).

## Library scanning (4-phase)

`MediaScannerService` orchestrates:

1. Query the device via `on_audio_query_pluse`.
2. Diff against the cache to find added/removed tracks.
3. Persist to `IsarLibraryDataSource`.
4. Extract artwork via `ArtworkExtractor` (semaphore × 4 for concurrency control, in-flight deduplication).

Rescans are silent, with a toast only when songs were added or removed; a restarted or failed scan keeps the current library on screen instead of blanking it.

## Project structure

```text
lib/
├── main.dart                        # Entry point and initialization (DI, Isar, audio_service)
├── app.dart                         # MaterialApp, GoRouter, global theme
├── app_shell.dart                   # ShellRoute stacking page, MiniPlayer, NavBar, monthly Replay trigger
│
├── core/
│   ├── di/                          # get_it, manual registration (injection.dart)
│   ├── database/                    # AppDatabase: opens the single Isar database
│   ├── router/                      # GoRouter, ShellRoute, permission guard
│   ├── theme/                       # Glassmorphism design system (primitives → semantic → components)
│   ├── error/                       # Failures, Exceptions, ErrorHandler
│   ├── extensions/                  # DurationExt (toMMSS), StringExt, ContextExt
│   └── utils/                       # Debouncer, PermissionHandler
│
├── features/
│   ├── library/                     # Scan, indexing, display (tracks, albums, artists)
│   ├── player/                      # Playback, queue, sleep timer, likes, palette
│   ├── history/                     # Play events, daily totals, weekly recap, monthly Replay
│   ├── home/                        # Local feed: Recently Played, Your Artists, New Albums, Your Playlists
│   ├── playlist/                    # Playlist CRUD, reorder
│   ├── search/                      # Global search (tracks, artists, albums)
│   ├── metadata/                    # Online bios (Last.fm) and photos (Deezer), opt-in
│   ├── settings/                    # Preferences, maintenance actions
│   ├── permissions/                 # First-run audio permission flow
│   └── whats_new/                   # Version-gated release notes sheet
│
├── services/
│   ├── audio/                       # AudioServiceInitializer, AudioSessionService
│   ├── scanner/                     # MediaScannerService (4 phases), ArtworkExtractor, MetadataParser
│   └── history/                     # PlayHistoryRecorder
│
├── shared/
│   ├── widgets/                     # GlassCard, GlassBottomSheet, DynamicBackground, ArtworkImage, …
│   └── app_shell.dart
│
└── l10n/                            # English and French (.arb), generated via flutter gen-l10n
```

## Test architecture

```text
test/
├── helpers/                   # FakeAudioPort, buildTestPlayerBloc, testTrack
├── unit/
│   ├── player/                # Queue, PlayerBloc (progress clock, queue edits), JustAudioAdapter
│   ├── history/               # PlayCounter, PlayHistoryRecorder, Isar data source (real engine)
│   └── home/                  # Recently Played from the play history
└── widget/
    ├── player/                # Queue sheet, hero morph, artwork carousel, progress ring
    ├── shared/                # ArtworkImage
    └── app_shell_location_test.dart
```

The Isar tests run against the real engine, loading the host library shipped by `isar_plus_flutter_libs`: there is no mocked database layer for persistence logic.

## Permissions

* **Android**: `READ_MEDIA_AUDIO` (13+), `READ_EXTERNAL_STORAGE` (≤ 12, `maxSdkVersion=32`), `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `INTERNET` (scoped to the opt-in online extras only). `allowBackup="false"`.
* **iOS**: `NSAppleMusicUsageDescription`, `UIBackgroundModes: audio`.

Audio-only permissions are enforced through a vendored, patched `on_audio_query_plus_android` (see `third_party/on_audio_query_plus_android/TROONA_PATCH.md`) rather than the library's default broader media permissions.
