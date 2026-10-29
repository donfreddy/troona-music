<!-- TODO(freddy): swap this placeholder for the real app icon/wordmark once the logo is ready. -->
<p align="center">
  <img src="https://placehold.co/160x160/0b0b12/b9a7ff?text=%F0%9F%8E%B5&font=montserrat" width="120" height="120" alt="Troona logo placeholder" />
</p>

<h1 align="center">Troona</h1>
<p align="center"><strong>A premium, offline-first music player for Android and iOS, with a glassmorphism interface inspired by iOS 17/18.</strong></p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white">
  <img alt="CI" src="https://github.com/donfreddy/troona-music/actions/workflows/ci.yml/badge.svg">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow.svg">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue">
  <img alt="Architecture" src="https://img.shields.io/badge/architecture-Clean%20%2B%20Feature--First-success">
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#tech-stack">Tech stack</a> •
  <a href="#getting-started">Getting started</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#privacy">Privacy</a>
</p>

---

Troona plays the music already on your phone. No account, no streaming catalogue, no ads, no analytics. Every byte of your library, your plays and your playlists stays on the device; the two online lookups it can make (artist bios, artist photos) are opt-in, off by default, and documented in plain English in the [privacy policy](docs/privacy-policy.md).

It is also an engineering showcase: a Clean Architecture Flutter codebase with a Flutter-free domain layer, an audio engine fully isolated behind a port/adapter boundary, and a disciplined glassmorphism design system built for real device performance, not just a demo reel.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="screenshots/home.jpeg" width="200" alt="Home"><br><sub>Home</sub></td>
    <td align="center"><img src="screenshots/library.jpeg" width="200" alt="Library"><br><sub>Library</sub></td>
    <td align="center"><img src="screenshots/player.jpeg" width="200" alt="Now Playing"><br><sub>Now Playing</sub></td>
    <td align="center"><img src="screenshots/search.jpeg" width="200" alt="Search"><br><sub>Search</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/playlist.jpeg" width="200" alt="Playlists"><br><sub>Playlists</sub></td>
    <td align="center"><img src="screenshots/album-detail.jpeg" width="200" alt="Album detail"><br><sub>Album</sub></td>
    <td align="center"><img src="screenshots/artist-detail.jpeg" width="200" alt="Artist detail"><br><sub>Artist (Last.fm/Deezer bio)</sub></td>
    <td></td>
  </tr>
</table>

## Features

Status reflects what is actually implemented and tested today, not a wishlist. See [`CHANGELOG.md`](CHANGELOG.md) for the full history.

### 🎧 Playback
- [x] Gapless offline playback (`just_audio`) behind an `AudioServicePort` abstraction: the domain never imports `just_audio` directly
- [x] Lock-screen and notification controls, backgrounded playback (`audio_service`)
- [x] Audio focus handling: ducks or pauses on notifications and calls, pauses instantly on headphone unplug, resumes after a call
- [x] Smooth transitions: fade-in on play, fade-out before pause, a short crossfade around skips; auto-advance stays gapless
- [x] Sleep timer with a real 30 s fade-out (your volume setting is never touched) and an "end of song" mode
- [x] Shuffle (Fisher–Yates) and repeat (off / one / all)
- [x] Queue sheet: history, now playing and up next in one list, tap to jump, drag to reorder, swipe to remove with a 4 s undo
- [x] Likes, persisted across sessions as a real playlist

### 📚 Library
- [x] 4-phase device scan: query, diff, persist, artwork extraction (4 concurrent workers, de-duplicated)
- [x] Isar-backed index (Rust core); rescans touch only what changed, with a live progress toast
- [x] Tracks, albums and artists, each with a dedicated detail page
- [x] Playlists: create, rename, delete, reorder, add/remove tracks
- [x] Monthly "Replay" playlist, auto-built from last month's 25 most-played tracks, once a month
- [x] Global search across tracks, artists and albums

### 🏠 Home & listening history
- [x] Recently Played, Your Artists, New Albums, Your Playlists
- [x] Persistent play history: a play counts after 30 s of listening (or half a track under a minute); seeking never counts
- [x] Daily listening totals (plays, time, first plays), kept forever
- [x] "Your week in music": a weekly recap with top artist/song, first listens and a monthly listening calendar

### 🌐 Online extras, opt-in and off by default
- [x] Artist and album bios via Last.fm
- [x] Artist and album photos via Deezer
- [x] Each source has its own switch; turning photos off deletes what was downloaded; "Clear online info" wipes both caches

### 🎨 Design
- [x] Glassmorphism UI: real-time blur, translucent textures, gradients sampled from the current artwork
- [x] Three-tier glass quality (Auto / Full / Light / Off) applied at runtime, tuned for low-end devices
- [x] Dark theme, portrait-locked, responsive sizing via `flutter_screenutil`

### ⚙️ Settings & maintenance
- [x] Playback toggles (duck on notification, pause on call, resume after call), glass quality, haptics
- [x] Clear cached covers / clear cached online info, each showing the size reclaimed
- [x] Version-gated "What's new" release-notes sheet, reachable anytime from Settings
- [x] Report a problem (local log, shared only if you choose to), privacy policy, open-source licenses

### 🌍 Localization
- [x] English and French, full 1:1 key parity, generated via `flutter gen-l10n`

> **On the equalizer, lyrics and cast:** early builds shipped demo versions of all three with no real DSP, lyrics backend or cast protocol behind them. They were removed deliberately ahead of v1 rather than kept half-working; see the `[Unreleased]` entry in [`CHANGELOG.md`](CHANGELOG.md). A real implementation of any of them is a post-v1 discussion, not a promise.

## Roadmap to v1.0

- [ ] Store-readiness pass: release signing, store listings, submission to Google Play and the App Store
- [ ] Localization beyond English and French
- [ ] Revisit a real equalizer and synced lyrics, scoped properly this time

Tracked in [Issues](https://github.com/donfreddy/troona-music/issues); the day-to-day detail lives in [`CHANGELOG.md`](CHANGELOG.md).

## Tech stack

| Layer                | Choice                                                    | Why                                                                                        |
|----------------------|-----------------------------------------------------------|--------------------------------------------------------------------------------------------|
| UI & framework       | Flutter 3.x / Dart 3                                      | Single codebase, native-feel glassmorphism without a web view                              |
| State management     | `flutter_bloc` (Bloc for Player/Library, Cubit elsewhere) | Predictable, testable state transitions; no implicit rebuild chains                        |
| Local database       | Isar (Rust core)                                          | Typed Dart schema, very fast reads, no SQL boilerplate for a local-only app                |
| Audio engine         | `just_audio` + `audio_service`                            | Gapless playback, lock-screen/notification integration, isolated behind `AudioServicePort` |
| File scanning        | `on_audio_query_pluse`                                    | Android MediaStore / iOS MediaLibrary access, patched to audio-only permissions            |
| Artwork palette      | `palette_generator_master`                                | Dominant-color extraction for the dynamic background                                       |
| Dependency injection | `get_it` (manual registration)                            | Explicit wiring in one file, no annotation magic to debug                                  |
| Navigation           | `go_router`                                               | `StatefulShellRoute` for the tab shell, modal routes for the player                        |
| Localization         | `flutter gen-l10n`                                        | ARB-based, type-safe generated accessors                                                   |

## Architecture

Feature-First + Clean Architecture: each feature under `lib/features/` is self-contained with `domain/`, `data/` and `presentation/` layers. The domain layer is pure Dart (no Flutter, no third-party I/O), and the audio engine is isolated behind a port/adapter boundary so the player logic never depends on `just_audio` directly.

```
feature/
├── domain/       # Entities, Repository interfaces, Use Cases: pure Dart, no Flutter
├── data/         # Models, DataSources, Repository implementations
└── presentation/ # Pages, Widgets, Bloc/Cubit
```

The full breakdown (module-by-module layout, the design system's token hierarchy, the `BackdropFilter` performance budget, storage schema and the test structure) lives in **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)**.

## Getting started

### Prerequisites

- Flutter SDK 3.19+ and Dart 3.3+ (CI runs against 3.47.5)
- Android SDK 21+ or iOS 14+
- A device or emulator with local audio files to scan

### Installation

```bash
git clone https://github.com/donfreddy/troona-music.git
cd troona-music
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Required permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<!-- Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<!-- Only used for the opt-in online bios/photos, never for playback -->
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`Info.plist`):

```xml
<key>NSAppleMusicUsageDescription</key>
<string>Troona accesses your music library to play local files.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### Commands

```bash
flutter analyze                                              # Static analysis
flutter test                                                 # Full test suite
flutter test test/unit/player/queue_test.dart                 # A single test file
dart run build_runner build --delete-conflicting-outputs      # Regenerate Isar/l10n code after a schema change
```

Tests live in `test/unit/` (pure logic, blocs, repositories) and `test/widget/`. Shared player test doubles (`FakeAudioPort`, `buildTestPlayerBloc`, `testTrack`) are in `test/helpers/fake_player.dart`. Isar tests run against the real engine: there is no mocked persistence layer.

## Contributing

Contributions are welcome: bug reports, fixes, translations and well-scoped features alike. Read **[`CONTRIBUTING.md`](CONTRIBUTING.md)** before opening a PR: it covers the local setup, coding conventions, the commit format and what a review is looking for. Everyone participating is expected to follow the **[Code of Conduct](CODE_OF_CONDUCT.md)**.

## Design credit

Troona's glassmorphism direction started from a concept by **[Shimon Bar Yacov](https://www.behance.net/shimon-bar-yacov)**, Product Design Director at [AmazingUI](https://amazingui.com), published on [Behance](https://www.behance.net/gallery/233232089/Music-App-Modern-Music-Player-by-AmazingUI). Only a handful of screens were ever published there, as a concept, not a shipped product. Everything behind them, including every screen beyond the first few, the architecture, the audio engine and the entire codebase, is original work built from scratch for this repository.

## Privacy

Troona has no account, no ads and no analytics. Your library, likes, playlists and listening history never leave the device. The two online lookups it can make (artist bios via Last.fm, artist/album photos via Deezer) are opt-in, independently toggled, and send nothing beyond an artist/album name. Full detail in **[`docs/privacy-policy.md`](docs/privacy-policy.md)**.

## License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.
