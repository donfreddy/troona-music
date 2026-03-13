# Troona: Offline Music Player

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=Dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Architecture: Clean](https://img.shields.io/badge/Architecture-Clean%20%2B%20Feature--First-green.svg)](#architecture)
[![State: flutter_bloc](https://img.shields.io/badge/State-flutter__bloc-blue.svg)](https://bloclibrary.dev)

Troona is a premium offline music player built with Flutter. It blends a refined glassmorphism aesthetic inspired by Apple with disciplined engineering to deliver performance, fluidity, and extensibility.

## ✨ Highlights

* Glassmorphism UI: immersive interface with real time blur, translucent textures, and dynamic gradients extracted from the current artwork (iOS style).
* Dynamic Artwork Background: dominant colors from every cover tint the UI via `palette_generator`, visible on the Player, Home, and Lyrics screens.
* Performance First: ultra fast indexing powered by Isar DB (Rust core) with incremental diff so only new or removed files are processed during rescans.
* Offline First: total privacy. No data is collected or sent to third parties.
* Audio Quality: gapless playback, smart queue management (Fisher Yates shuffle, repeat off/one/all), and lock screen controls through `audio_service`.
* Senior Grade Architecture: modular codebase aligned with SOLID and Clean Architecture, with a pure Domain layer free of Flutter dependencies.

## 🛠 Tech Stack

* UI and Framework: `Flutter 3.x / Dart 3` for native quality across platforms.
* State Management: `flutter_bloc` with Bloc for Player and Library, Cubit for Playlist and Settings.
* Database: `Isar DB` for very fast local storage with typed Dart schema.
* Audio Engine: `just_audio` for playback, gapless support, and position streams.
* Background Audio: `audio_service` for lock screen controls and Android/iOS notifications.
* File Scanning: `on_audio_query` targeting Android MediaStore and iOS MediaLibrary.
* Metadata: `flutter_media_metadata` as ID3 fallback when `on_audio_query` returns null.
* Artwork Palette: `palette_generator` to extract dominant colors for the dynamic background.
* Dependency Injection: `get_it` plus `injectable` using lazy singletons and factories.
* Navigation: `go_router` with ShellRoute for persistent navigation and modal routes for the Player.
* Permissions: `permission_handler` covering READ_MEDIA_AUDIO (Android 13+), READ_EXTERNAL_STORAGE (12 or lower), and MediaLibrary (iOS).

## 🏛 Architecture

The app follows a Feature First and Clean Architecture approach. Each feature is a self contained module organized in three layers:

```
feature/
├── domain/          # Entities, Repository interfaces, Use Cases (pure Dart, no Flutter)
├── data/            # Isar models, DataSources, Repository implementation
└── presentation/    # Pages, Widgets, Bloc or Cubit
```

The Domain layer never depends on Data or Flutter. The audio engine (`just_audio`) stays behind a Port and Adapter; the Domain speaks to `AudioServicePort` and never to `just_audio` directly.

## 🚀 Project Structure

```text
lib/
├── main.dart                        # Entry point and initialization (DI, Isar, audio_service)
├── app.dart                         # MaterialApp, GoRouter, global theme
│
├── core/
│   ├── di/                          # get_it and injectable (injection.dart, modules/)
│   ├── router/                      # GoRouter, ShellRoute, permission guards
│   ├── theme/                       # Glassmorphism design system
│   │   ├── app_colors.dart          # Tokens: primitive to semantic to components
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart         # 4pt grid, fixed heights (miniPlayer, navBar)
│   │   └── glass_theme.dart         # GlassCard, blur levels, opacities
│   ├── error/                       # Failures, Exceptions, ErrorHandler
│   ├── extensions/                  # DurationExt (toMMSS), StringExt, ContextExt
│   └── utils/                       # Debouncer, PermissionHandler
│
├── features/
│   ├── library/                     # Scan, indexing, display (tracks, albums, artists)
│   │   ├── domain/
│   │   │   ├── entities/            # Track, Album, Artist
│   │   │   ├── repositories/        # LibraryRepository interface
│   │   │   └── use_cases/           # ScanUseCase, GetTracksUseCase, SearchTracksUseCase
│   │   ├── data/
│   │   │   ├── models/              # TrackModel, AlbumModel (@collection Isar)
│   │   │   ├── sources/             # OnAudioQueryDataSource, IsarLibraryDataSource
│   │   │   └── repositories/        # LibraryRepositoryImpl
│   │   └── presentation/
│   │       ├── pages/               # LibraryPage (iOS style sliver), AlbumDetailPage, ArtistDetailPage
│   │       ├── widgets/             # TrackListTile, AlbumCard, ArtistCard, LibrarySearchBar
│   │       └── bloc/                # LibraryBloc with Initial, Scanning, Loaded, Error states
│   │
│   ├── player/                      # Playback, queue, commands
│   │   ├── domain/
│   │   │   ├── entities/            # Queue, PlaybackState, RepeatMode
│   │   │   ├── ports/               # AudioServicePort (interface isolating just_audio)
│   │   │   └── use_cases/           # PlayTrack, Pause, Seek, SkipNext, SetQueue, ToggleShuffle
│   │   ├── data/
│   │   │   ├── adapters/            # JustAudioAdapter (AudioServicePort impl), AudioHandlerImpl
│   │   │   └── repositories/        # PlayerRepositoryImpl
│   │   └── presentation/
│   │       ├── pages/               # FullPlayerPage (vinyl carousel with hero animation)
│   │       ├── widgets/             # MiniPlayer, PlayerControls, ArtworkCarousel, RotatingArtwork,
│   │       │                        # PlayerProgressBar, VolumeSlider
│   │       └── bloc/                # PlayerBloc with Idle, Loading, Active, Error states
│   │
│   ├── home/                        # Local feed: Popular Playlists and Trending Now
│   │   ├── domain/                  # HomeFeed, HomeRepository, GetHomeFeedUseCase
│   │   ├── data/                    # HomeRepositoryImpl (Isar source)
│   │   └── presentation/
│   │       ├── pages/               # HomePage (CustomScrollView plus DynamicBackground)
│   │       ├── widgets/             # PlaylistCard, TrendingRow, PlaylistMosaic, SectionHeader
│   │       └── bloc/                # HomeBloc with Initial, Loading, Loaded, Error states
│   │
│   ├── playlist/                    # Playlist creation and management
│   │   └── presentation/bloc/       # PlaylistCubit for CRUD
│   │
│   └── settings/                    # User preferences
│       └── presentation/bloc/       # SettingsCubit (SharedPreferences)
│
├── services/
│   ├── audio/                       # AudioServiceInitializer, EqualizerService, WaveformService
│   ├── scanner/                     # MediaScannerService (four phases), ArtworkExtractor (semaphore x4),
│   │                                # MetadataParser
│   └── cache/                       # IsarService, ArtworkCacheService
│
└── shared/
    ├── widgets/
    │   ├── glass_card.dart          # GlassCard (RepaintBoundary plus BackdropFilter)
    │   ├── glass_bottom_sheet.dart
    │   ├── dynamic_background.dart  # Animated gradient from artwork (palette_generator)
    │   ├── rotating_artwork.dart    # Rotating artwork (RotationTransition) at NavBar and MiniPlayer
    │   ├── app_bottom_nav_bar.dart  # NavBar with five tabs: Home · Queue · Artwork · Search · Now
    │   ├── mini_player.dart         # Glass card above the NavBar
    │   ├── animated_artwork.dart
    │   ├── custom_sliver_header.dart # iOS style collapsing header with dynamic blur
    │   ├── empty_state_widget.dart
    │   ├── loading_shimmer.dart
    │   └── context_menu.dart
    └── app_shell.dart               # ShellRoute stacking page, MiniPlayer, and NavBar
```

## 🎨 Design System: Glassmorphism

Theme levels:

* Primitives: raw colors, sizes, radii.
* Semantic: `bgPrimary`, `glassFill`, `glassBorder`, `accent`.
* Components: `GlassCard` with low, medium, and high blur presets.

BackdropFilter guidance for performance:

* Always wrap in a `RepaintBoundary`.
* Avoid placing inside an `AnimatedBuilder` that rebuilds on audio position.
* Keep a maximum of two BackdropFilters on screen at once.

## 📱 Implemented Screens

* LibraryPage — complete: iOS style sliver layout, scan banner, album and artist grids, search.
* FullPlayerPage — complete: vinyl style carousel, hero animation, dynamic background.
* HomePage — complete: Popular Playlists horizontal scroll and Trending Now.
* AppBottomNavBar — complete: five tabs with rotating artwork at the center.
* MiniPlayer — complete: standalone glass card with shared hero artwork.
* LyricsView — in progress: auto scroll with highlighted active line.
* QueueSheet — in progress: reorderable bottom sheet.
* AlbumDetailPage — planned.
* ArtistDetailPage — planned.
* EqualizerPage — planned.

## ⚙️ Getting Started

### Prerequisites

* Flutter SDK 3.19 or newer.
* Dart 3.3 or newer.
* Android SDK 21+ or iOS 14+.

### Installation

```bash
git clone https://github.com/votre-compte/troona.git
cd troona
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Required Permissions

**Android** (`AndroidManifest.xml`):

```xml
<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<!-- Android 12 or lower -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

**iOS** (`Info.plist`):

```xml
<key>NSAppleMusicUsageDescription</key>
<string>Troona accesses your music library to play local files.</string>
```

## 🧪 Test Architecture

```
test/
├── unit/
│   ├── domain/use_cases/      # Use case tests (pure Dart, no Flutter)
│   ├── player/queue_manager/  # Fisher Yates shuffle, RepeatMode, skipPrevious
│   └── library/scanner/       # Incremental diff, duration filters
├── widget/
│   ├── player/                # PlayerBloc plus widgets (buildWhen optimizations)
│   └── library/               # LibraryBloc, search, filter, sort
└── integration/
    └── scan_and_play/         # Scan to index to playback end to end
```

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.
