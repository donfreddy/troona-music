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
`flutter_bloc` throughout. `PlayerBloc` and `LibraryBloc` are provided at the shell level via `MultiBlocProvider` in `app_router.dart`, making them available to all shell pages. `FullPlayerPage` is outside the shell and receives `PlayerBloc` via `BlocProvider.value`. Queue edits (`QueueEditEvent`) go through a single sequential handler so they apply in order. The bloc remembers the ids of the album, playlist or song the queue was built from: playing another song of that source jumps within the queue, and replacing a queue that still holds songs queued by hand (`Queue.hasAddedAhead`) emits a `QueueReplaced` notice, which the shell shows as a toast with Undo (`QueueReplaceUndone` restores the queue through `restoreQueue`). A queue that keeps both layers apart is issue #2.

### Navigation
`go_router` with a `StatefulShellRoute` wrapping the bottom-nav branches (`/home`, `/library`, `/search`, `/playlists`). Its container, `tabsContainer`, is go_router's indexed stack with heroes off in the hidden tabs: they stay mounted, and a flight on the root navigator (into Now Playing) would meet the same album cover in two tabs. `GlassSliverHeader` also turns heroes off in its content once more than half faded. The full player (`/player`) is a fullscreen `CustomTransitionPage` on the root navigator, outside the shell; it morphs from the mini player through Hero flights (`now_playing_hero.dart`). The queue opens as a modal sheet over it (`queue_sheet.dart`).

The shell paints `AmbientBackground` behind the tab pages, which are transparent. A page pushed over a tab must be opaque, or the page below shows through it while it slides in, then vanishes when the slide ends: `app_router.dart` wraps such routes in `_overTab` (Settings, Privacy, Your listening); album, artist and playlist pages paint their own background.

Pages are edge to edge: content scrolls under the status bar and the floating tab bar (`SystemUiMode.edgeToEdge` in `main.dart`, `AppTheme.systemOverlay`; never `SystemUiOverlayStyle.light`, which paints the navigation bar black). Every scrolling page's header is a `GlassSliverHeader` (`lib/shared/widgets/glass_sliver_header.dart`), the first sliver of a `CustomScrollView`; no Material `AppBar` except the playlist editor's modal form. `GlassSliverHeader.largeTitle` for tab roots and pushed list pages (an iOS large title that snaps when left halfway); the plain constructor for heroes (album, artist, playlist), whose Play and Shuffle scroll away; Search pins its field (`pinnedBottom`) with no navigation row. The artist page opens on their photo, edge to edge, when one exists (`background`, `stretch`); without one, the circle, over their cover decoded a few pixels wide and stretched (a blur with no filter). The bar's glass has no hairline: its tint fades out over `softEdge` below it (the blur cannot fade: a `BackdropFilter` under a `ShaderMask` blurs nothing). Under the tab bar, the shell fades content into the background over `bottomBarInset`. Tapping the tab already shown scrolls its root page to the top (`ScrollToTopOnReselect`, wrapped around the root pages in `app_router.dart`). Album and artist pages open with `context.pushAlbum` and `context.pushArtist`, in the current tab; they hand the location they come from as `extra`, a plain string go_router can encode, so opening the page just below (an album's artist, opened from that artist) goes back to it instead of piling up copies.

### Storage
One Isar database (`isar_plus`), opened by `AppDatabase.open()` in `lib/core/database/`. Each data source declares its collections (`IsarLibraryDataSource.schemas`, `IsarPlayHistoryDataSource.schemas`) and `injection.dart` passes them in, so core never imports a feature. Adding a collection needs no migration.
- Library: tracks and playlists (`IsarLibraryDataSource`).
- Play history: `PlayEventModel`, capped at 500 events (`lib/features/history/`). `PlayHistoryRecorder` records a play after 30 s of listening, or half a track shorter than a minute (`PlayCounter`). Home "Recently Played" reads it.
- Daily totals, never pruned, written in the same transaction as each play: `ListeningDayModel` (plays, listening time), `TrackDayModel` (plays per track per day), `TrackFirstPlayModel`, `ListeningHourModel` (plays per local hour, id `day * 24 + hour`). Days are `ListeningDay` keys (local calendar days since epoch). `backfill()`, before the recorder starts, fills each of these that is still empty from the stored events. The recorder writes listening time every 30 s, on a track change and at midnight. Your listening (`ListeningRecapCubit`, `GetListeningRecapUseCase`: any week or month, `RecapPeriod`; Home's card is last week) reads them. Its calendar fills days by fixed steps of plays (`PlayIntensity`, the same in every span); When you listen (`ListeningMoments`, weekday by quarter of the day) by steps relative to its busiest cell. Both draw `HeatCell`. The monthly Replay playlist reads the daily totals too (`CreateMonthlyReplayUseCase`, run once per month from `AppShell`; the handled month is kept in `SharedPreferences`).
- Playback session (queue, position, and the album, artist or playlist it was started from: `QueueOrigin`, passed with `PlayTrackRequested` by those pages, `PlayerBloc.origin`) is saved to `SharedPreferences` by `PlaybackSessionStore`. Home's resume card reads it from the player.
- Last version whose "What's new" was handled: `SharedPreferences` (`SharedPrefsWhatsNewRepository`). Add a `Release` (version, date as in CHANGELOG.md, notes) to the top of `releaseNotes()` with each version that should show the sheet; the sheet features the installed release and lists the earlier ones.
- Covers extracted from local files are cached in the app cache directory under `troona_artwork_cache`.
- Online extras are opt-in, behind two switches: bios (Last.fm) and photos (Deezer). `MetadataRepositoryImpl` contacts each source only when its switch is on. Their JSON and downloaded photos live under `troona_metadata_cache` (photos in `photos/`), so "clear online info" removes and measures both. Turning photos off deletes the downloaded ones.
- Artist and album pages show About (`OnlineAboutCard`, `lib/features/metadata/presentation/widgets/`) only when Last.fm has a text: counts and tags alone make no card. Similar artists show only when the library holds them (`SimilarArtistsCubit`, `ArtistDetailRepository.getArtistsByNames`), in Also in your library.

### Design System (Glassmorphism)
Three-level token hierarchy in `lib/core/theme/`:
1. **Primitives**: raw colors, sizes, radii
2. **Semantic**: `bgPrimary`, `glassFill`, `glassBorder`, `accent`
3. **Components**: `GlassConfig` presets per surface and quality tier (high, low, off). `GlassCard` is flat by default: blur is for chrome (tab bar, header, sheets, Now Playing), never for cards in scrolling content.

Every `BackdropFilter` takes `GlassFilter.of(sigma, saturation: config.saturation)`, never a bare `ImageFilter.blur`. Surfaces that carry text (`GlassTheme.bar` for the tab bar, mini player and `GlassSliverHeader`; `GlassTheme.sheet`) use a middle material, tuned on a Pixel 8: blur 30, a 15 % dark tint and a mild 1.25x saturation. The boost never goes without the tint: on thin glass it turns covers and coloured icons behind into vivid stains. Their low tier keeps saturation 1. The full 1.6x boost is for decorative glass over artwork (Now Playing lens and dock).

`BackdropFilter` performance rules (enforced throughout):
- Always wrap in a `RepaintBoundary`.
- Never place inside an `AnimatedBuilder` that rebuilds on audio position.
- Maximum two `BackdropFilter`s on screen at once (the Now Playing page already uses both, so sheets over it are opaque). A page's header and the tab bar are the two; the header's blur keeps one sigma and is only enabled once content passes under it (`BackdropFilter.enabled`), and a push or pop between two collapsed headers shows three for the length of the transition.
- One exception: a short-lived modal sheet over the shell (the tab bar blurs below it, a collapsed header may too) may add a third blur on high-tier devices only. `showGlassBottomSheet` gets its quality from `GlassTheme.aboveGlass(context)`, read from the context it is opened from: opaque on low-tier devices, when the user turns glass down, and below a `BlurBudgetSpent` (`lib/core/theme/components/blur_budget.dart`). Now Playing and the content of every sheet are marked with it, so the queue, its menus and a sheet opened from a sheet are opaque. Not for anything that stays on screen.

Modals and labels go through one entry point each, in `lib/shared/widgets/`; never `showModalBottomSheet`, `showCupertinoModalPopup`, `showDialog` or a Cupertino sheet or dialog directly:
- `showGlassBottomSheet`: every bottom sheet (queue, What's new, add to playlist).
- `showActionSheet` with `SheetAction`s: every menu of actions or options (track actions, sort, sleep timer, speed). A tap closes the sheet, then runs the action.
- `app_dialog.dart` (`showConfirmDialog`, `showMessageDialog`, `showTextInputDialog`): opaque, fade and scale in, fade only when animations are reduced.
- `AppToast`: every transient message.
- Haptics go through `AppHaptics` (`lib/core/utils/haptics_helper.dart`, which states the vocabulary), never `HapticFeedback`. Playback ticks once, in `PlayerBloc`: a button that sends a playback event adds none.
- `SwipeActions`: every horizontal swipe that runs an action (a tick once armed, then it springs back). Song rows wrap it in `QueueSwipe` (right plays next, left adds to the queue); the mini player swipes to the next or previous song.
- `AppBadge` (neutral) and `AppBadge.accent`: small pill labels.
- `AppButton.primary`, `.secondary` and `.text`, in two sizes: `small` (32 dp pill, in-line actions such as See all) and `medium` (44 dp, the default). Both take at least 44 x 44 dp, the touch target. Never a raw `TextButton`, `FilledButton`, `OutlinedButton` or a `GestureDetector` pill; the dialog actions and the boot failure screen are the exceptions. Play and Shuffle on album and playlist pages are one widget, `PlayShuffleButtons`; the artist page has Shuffle alone, as a round button (`ShuffleRoundButton`, same file): an artist's songs have no order.
- `AppBackButton`: the back button of every pushed page (glass circle), the `leading` of its `GlassSliverHeader`. In an `AppBar`, also set `leadingWidth: AppBackButton.leadingWidth`.
- Icon-only buttons: `GlassIconButton` for a glass circle (header actions), `AppIconButton` for a bare icon (row options, sheet close, field clear, mini player). `AppIconButton` takes 44 x 44 dp and requires a tooltip, the label screen readers read. Never a raw `IconButton`.

A song's cover in a list row is `TrackRowArtwork` (`lib/features/library/presentation/widgets/track_row_artwork.dart`): the current song's is dimmed under the `MiniEqualizer`, still while paused; numbered album rows show the equalizer in place of the number.

Artwork is decoded at its displayed size through `ArtworkImage` (`lib/shared/widgets/artwork_image.dart`). A null or empty path, or a file that cannot be read, shows `ArtworkPlaceholder` with the role's icon (`placeholder: AppIcons.album`), opaque like a cover; never a hand-made grey box.

Icons come from `AppIcons` (`lib/core/theme/semantic/app_icons.dart`), named by role, not by glyph. It is the only file that imports an icon pack (Lucide, plus Eva for the filled glyphs Lucide lacks) or names `CupertinoIcons` or Material `Icons`, which `test/unit/architecture/icon_sources_test.dart` enforces (the boot failure screen may use Material `Icons`). Give each role its own entry, even when two roles share a glyph (a playlist and the queue).

### Library Scanning (4-phase)
`MediaScannerService` orchestrates: (1) query device via `on_audio_query_pluse`, (2) diff against cache to find added/removed tracks, (3) persist to `IsarLibraryDataSource`, (4) extract artwork via `ArtworkExtractor` (semaphore × 4 for concurrency control).

A missing artist (Android's `<unknown>`, older "Unknown Artist") is stored and passed around as `''` (`TrackTags.unknownArtist`, `lib/features/library/domain/services/track_tags.dart`); screens show it with `context.artistName(...)`, which reads "Unknown artist" in the app's language. When a song has none, `TrackModel.nameMissingArtist` reads it from an "Artist - Title" file name (`TrackTags.fromName`, which returns null when in doubt); a real title tag is never split.

Artists and albums are rebuilt from the whole library on every scan (`TrackModel.link`, after phase 1), not taken from MediaStore:
- Artists are keyed by name: `artistId` is `TrackTags.artistIdFor(name)`, never a MediaStore id (MediaStore gives every distinct artist tag an id, so "A" and "A, B" were two artists).
- A song credits every artist its tag names (`artistNames`, `artistIds`; `Track.credits` in the domain), read by `ArtistCredits.of(allTags).split(tag)` (`artist_credits.dart`): "feat."/"ft." always separate, a comma only when one of the names around it is an artist of its own somewhere in the library, "&" and "/" never. A whole comma tag with no known name in it ("Tyler, The Creator") is one artist, also inside longer lists, until one of its parts is set apart by a list it is not in. `artistId` is the first credit. An artist page holds every song that credits them, their albums (they are the album's artist), their singles and, apart, the albums they appear on (`ArtistAlbums`, `LibraryGrouping.albumsOfArtist`), each newest first, the undated ones last; Latest release shows their newest album or single (`ArtistAlbums.latest`), none without a year or with one release only; "More by" on an album page lists their own albums, then their singles; its songs come most played first (`ArtistSongs.ranked`, all-time plays from `PlayHistoryRepository.playCounts`), five shown before See all; the Artists list leaves out artists only ever credited as guests (`LibraryGrouping.artistsOf`, `guests: true` in search).
- Without an album artist tag, MediaStore makes one album per name and folder, and downloaders save an album across folders ("Album (1)", "Album (2)"). `AlbumMerge` joins MediaStore albums of the same name that share an artist credited on all their songs, however they chain, and never cuts one (a compilation stays whole). An album with an artist gets `TrackTags.stableId(name + lead artist)`, so its id survives folders coming and going; a compilation keeps its MediaStore id.
- Ids made by `TrackTags.stableId` are negative 64-bit FNV-1a hashes; MediaStore ids are positive.
- Songs in the player queue keep the ids they had when queued: "Go to album/artist" reads the song again from the library first (`show_track_actions.dart`).
- An album's artist is the artists credited on every one of its songs, none for a compilation (`LibraryGrouping`). An album of one song belongs to its first credit only, or its guests would own it. Every screen builds albums and artists through `LibraryGrouping`, so counts and names agree.
- MediaStore has no release type: an album of at most three songs named after one of them is a single (`SingleRelease.matches`, `Album.isSingle`), comparing names without brackets, " - " parts or featured artists. `Artist.albumCount` leaves singles out; `singleCount` counts them. No EP is told apart: four songs may be half an album downloaded.
- Phase 2 calls `refreshIndexed`: indexed rows take every field the scan read (tags, size, duration, year, dates) and the links above; covers and `indexedAt` are kept. A retagged file is picked up and a row stored wrong heals. The year comes from MediaStore as text (`TrackModel.fromSongModel`).
- An album page lists its whole track list, never folded, in `AlbumOrder.sorted` order: disc and track number (MediaStore files the disc in the thousands), then the order files were added, since downloaded songs often have no number. `AlbumOrder.numbers` shows the track numbers only when every song has one, else the places. A song's artist line shows only when the album's artist does not say it all (`LibraryGrouping.creditLine`).

### Misc
- Debug and profile builds install as `com.donfreddy.troona.dev` ("Troona Dev", DEV banner icon from `android/app/src/debug/res/`), next to the release app and with their own data. To bring real data over, export a backup from the release app and restore it in the dev one. Settings shows a Debug section in non-release builds (`DebugSection`): make this month's Replay now, show "What's new" on the next launch.
- GitHub release descriptions start from `.github/RELEASE_TEMPLATE.md` (its comments list the checks before publishing).
- App is **portrait-only**: `android:screenOrientation="userPortrait"` in the manifest, and an unawaited `SystemChrome` call in `main.dart` for iOS. Nothing before `runApp` may await a platform channel that needs an activity: `audio_service` can run `main()` with none.
- Dark theme only (`ThemeMode.dark`).
- No design-size scaling: layouts follow the room they get (`LayoutBuilder`, `Expanded`). Now Playing shrinks its ring on short screens. Fixed-height chrome (tab bar and mini player, Now Playing and its queue, the navigation row and `pinnedBottom` of `GlassSliverHeader`: Library filter, Search field) caps the font size at `AppLayout.maxTextScale` (1.3, `lib/core/layout/app_layout.dart`) with a local `MediaQuery.withClampedTextScaling`; everything else follows the phone's font size and wraps or stacks instead of overflowing. Content under the floating bar pads with `context.bottomBarInset()`.
- Layout is checked at 360 x 640 dp (Galaxy S7 class) with the font at 1.3 and 2.0, as well as on tall phones. Layout tests that measure labels load Roboto (`test/helpers/roboto.dart`).
