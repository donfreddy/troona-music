# Troona V0 Audit

Scope: full read of `lib/`, Android/iOS platform config, and the test suite, on `main` at `7ea07ca` (2026-10-24).
Goal: decide whether the build can go to a first circle of beta testers, and define the missing Settings and track menu features.

Baseline measured during the audit:

| Check | Result |
|---|---|
| `flutter analyze` | 1 info (`onReorder` deprecated, `playlist_detail_page.dart:147`) |
| `flutter test` | 176 passed, **1 failed**: `test/widget_test.dart` (the default Flutter "Counter increments" template, it tests a widget that does not exist) |
| Crash reporting | none |
| Platforms actually exercised | Android only (see 1.1 about iOS) |

Note on the brief: the request mentions Riverpod. The project uses `flutter_bloc` only; everything below is written for Bloc.

---

## 0. Verdict

**No-Go as is. Go after the 5 blockers in section 4**, which are about 2 to 3 days of work. The core (player bloc, queue editing, session restore, history) is solid and well tested. What is not ready is everything a tester touches at the edges: errors during playback, dead UI, the system notification, and the absence of any feedback channel.

---

## 1. V0 readiness and stability

### 1.1 Permissions and onboarding

Flow today:

```
main() -> configureDependencies() -> runApp
                                         |
GoRouter.redirect (every navigation) ----+--> hasAudioPermission()?
     no  -> /permission (PermissionPage) -> request() -> context.go('/home')
     yes -> shell -> AppShell post-frame -> hasAudioPermission() -> LibraryBootstrapRequested
```

What works:
- SDK split is correct: `Permission.audio` (READ_MEDIA_AUDIO) on API 33+, `Permission.storage` below (`lib/core/utils/permission_handler.dart`).
- The plugin's own permission check (`OnAudioQuery.permissionsStatus`) is double-checked, so the router and the scanner agree.
- Media playback notifications are exempt from the Android 13 `POST_NOTIFICATIONS` runtime prompt, so not requesting it is fine.

Findings:

| # | Severity | Finding | Fix |
|---|---|---|---|
| P1 | High | `AndroidManifest.xml:13-14` declares `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO`. Not used. Google Play's photo/video permission policy rejects apps that declare them without a core use case, and testers see a scarier install page. | Remove both. |
| P2 | Medium | `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` (`AndroidManifest.xml:9-10`) have no `maxSdkVersion`. `WRITE_EXTERNAL_STORAGE` is useless (the app never writes shared storage). | Remove `WRITE_EXTERNAL_STORAGE`; add `android:maxSdkVersion="32"` to `READ_EXTERNAL_STORAGE`. |
| P3 | Medium | The redirect runs `DeviceInfoPlugin().androidInfo` + `permission.status` + `permissionsStatus()` on **every** navigation, including every push to an album (`app_router.dart:48`). Three platform channel round trips per tap. | Cache the granted state in memory; only re-check on `AppLifecycleState.resumed`. |
| P4 | Medium | After "Open Settings" on a permanent denial, coming back to the app does nothing until the user taps again: `PermissionPage` has no lifecycle observer. | `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` -> re-check -> `context.go(AppRoute.home)`. |
| P5 | Low | Permanent denial is detected with `e.message.contains('permanently')` (`permission_page.dart:40`). Any wording change breaks the UI state. | Throw a typed `PermissionPermanentlyDeniedException`. |
| P6 | High (iOS) | iOS is **not verified** and several signals say it will not work as is: the iOS plugin can send `_size: nil` (`OnAudioHelper.swift`) while `SongModel.size` is a non-nullable `int` read in `_isValidTrack` (TypeError, whole scan fails); `persistentID` is a `UInt64` parsed with `int.parse` in `ArtworkExtractor`; MPMediaLibrary only exposes synced, non-DRM items. | **Ship V0 to Android testers only.** Treat iOS as a separate milestone validated on a physical device. |

### 1.2 Memory leaks and lifecycle

The brief mentions isolates: **there are none** in the codebase (no `Isolate`, no `compute`). Nothing to close, but see 2.3 for what runs on the UI isolate instead.

Subscriptions audit:

| Owner | Subscriptions | Lifetime | Verdict |
|---|---|---|---|
| `PlayerBloc` | 7 port streams + `ValueNotifier` | singleton, `close()` cancels all and disposes the notifier after `super.close()` | OK, well done |
| `LibraryBloc` | `_scanSub` | factory per shell mount, cancelled in `close()` | OK, but see S1 |
| `AudioHandlerImpl` | 4 port streams | app lifetime, never cancelled | Acceptable (singleton process-wide) |
| `AudioSessionService` | 3 | singleton, `dispose()` exists | OK |
| `PlayHistoryRecorder` | 2 | singleton, `dispose()` exists | OK |
| `AppShell` | router delegate listener | removed in `dispose()` | OK |
| `ProgressRing` and friends | `progress.addListener` | removed in `dispose`, swapped in `didUpdateWidget` | OK |

Findings:

- **S1 (Medium). A rescan does not stop the previous artwork extraction.** `LibraryBloc._cancelScan()` cancels the stream subscription but never calls `MediaScannerService.cancel()`. Inside `ArtworkExtractor.extractArtworks`, the dispatch loop runs *before* `yield* controller.stream`, so cancelling the subscription does not reach it: the old run keeps extracting with 4 slots while the new run starts 4 more. Fix: call `_scanner.cancel()` from `_cancelScan` (through the use case), and in the extractor check `_cancelRequested` again right after `semaphore.acquire()`.
- **S2 (Low). Artwork progress is buffered.** For the same reason, no artwork progress event reaches the UI until the dispatch loop has queued every track: the bar sits at 0 then jumps. Fix: start listening first (`yield*` on a controller fed by an unawaited dispatcher function).
- **S3 (Low). Isar "cache cleanup".** The database is bounded where it matters (play history capped at 500). What is *not* cleaned:
  - artwork files of tracks removed from the device (orphans stay in `troona_artwork_cache`; the OS may purge the cache dir, so this is cosmetic);
  - artwork is keyed by `deviceId` and served from disk if present, so a re-tagged cover is never refreshed;
  - the scan diff is by `deviceId` only, so edited tags (title, album) of an existing file are never re-read.
  None of these block V0. The Settings "Clear artwork cache" action (3.1) gives testers a manual escape hatch.
- **S4 (Low). Settings enums are persisted by `index`** (`settings_repository_impl.dart:49-114`). Adding or reordering a value (needed for `GlassQuality.auto`, see 2.2) silently remaps saved preferences, and an out-of-range index throws `RangeError`. Persist `enum.name` and fall back to the default on unknown names.

### 1.3 Error handling

#### E1 (Blocker). Playback errors are never observed

`just_audio` 0.10 moved errors off the playback event stream: its CHANGELOG for 0.10.0 says *"Replace playbackEventStream.onError by errorStream"*. The app never subscribes to `AudioPlayer.errorStream` (no match in `lib/`), and the player is built with the default `maxSkipsOnError: 0` (`just_audio_adapter.dart:51`).

Consequences:
- `PlayerBloc`'s `onError` handlers on `positionStream` / `statusStream` (`player_bloc.dart:116`, `:126`) never fire for decoding errors.
- `_onAudioError` and its 2 s "smart recovery" skip (`player_bloc.dart:654-675`) are effectively dead code.
- When a track in the middle of a queue cannot be decoded, the engine stops on it with nobody told. Depending on the state reported, the UI either looks frozen on "playing" or looks like the queue ended.

How likely is it for testers: high. `_allowedExtensions` includes `wma` (`local_audio_data_source.dart:48`), which ExoPlayer does not decode, and personal libraries always contain a few truncated MP3s.

Only the *first* track of a newly set queue is covered today, because `setAudioSources` throws synchronously for it and `_loadQueue` maps that to a `PlaybackFailure`.

Fix (engine skips, UI informs, no double skip):

```dart
// audio_service_port.dart
/// Errors raised while playing, after the load call returned.
Stream<Failure> get errorStream;
```

```dart
// just_audio_adapter.dart
JustAudioAdapter({AudioPlayer? player})
  : _player = player ??
        AudioPlayer(handleInterruptions: false, maxSkipsOnError: 3) { ... }

@override
Stream<Failure> get errorStream => _player.errorStream.map(
  (e) => PlaybackFailure(e.message ?? 'This file cannot be played (${e.code})'),
);
```

```dart
// player_bloc.dart: subscribe like the other port streams, and drop the
// recovery timer: just_audio already skips (and pauses after 3 in a row).
_errorSub = audioServicePort.errorStream.listen(
  (f) => add(_AudioErrorOccurred(f.message)),
);
```

`_onAudioError` should then stop replacing `PlayerActive` with `PlayerError` (that hides the mini player while the engine is already on the next track). Expose the message as a one-shot notice instead (a `Stream<String> notices` on the bloc, listened to in `AppShell` to show a toast).

Remove `'wma'` from `_allowedExtensions` as well.

Tests to add (`test/unit/player/`):
- corrupt track in the middle of a queue -> engine moves to the next track, one notice emitted, state stays `PlayerActive`;
- corrupt **last** track -> paused, notice emitted, no skip loop;
- 4 corrupt tracks in a row -> stops after 3 skips;
- error while the full player is open -> no route change, no stale `PlayerError`.

#### E2 (Blocker). No global error handler, no crash reporting, silent release logs

- No `FlutterError.onError`, no `PlatformDispatcher.instance.onError` (no match in `lib/`).
- `appLogger` is `Level.off` in release (`app_logger.dart`). Every `ErrorHandler.handle` call disappears in the beta build.
- `configureDependencies()` runs before `runApp` with no `try`. If Isar fails to open (disk full, schema mismatch after a downgrade) or `AudioService.init` throws, the tester gets a blank screen forever and you get nothing.

A beta without telemetry is a beta you cannot learn from. Minimal fix, consistent with an offline app (no network SDK required):

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrashLog.init(); // ring buffer file in getApplicationSupportDirectory()

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashLog.record(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLog.record(error, stack);
    return true;
  };

  try {
    await configureDependencies();
  } catch (e, st) {
    CrashLog.record(e, st);
    return runApp(BootFailureApp(error: e)); // "Send report" + "Retry"
  }
  runApp(const TroonaApp());
}
```

Then route `appLogger` to the same file in release at `Level.warning` (a `LogOutput` subclass, as the comment in `app_logger.dart` already plans), and expose "Send feedback" in Settings (3.1) which shares that file.

Trade-off: Sentry or Crashlytics gives you aggregation and you do not depend on testers pressing a button, but it adds a network SDK, a privacy notice, and contradicts the offline positioning. For 10 to 30 testers you know personally, the local log plus a share button is enough. Revisit for a public release.

#### E3 (Medium). Scan robustness

- A single malformed `SongModel` (null where the platform model expects a value) throws inside `_isValidTrack` and fails the **whole** scan. Wrap the per-song mapping in `try` and skip the item.
- `_blockedPathFragments` contains `/media/audio/` and the rule `contains('/record') && duration < 10 min`. Both match legitimate user folders (`/Music/Records/...`, `/Media/Audio/...`). Testers will report "missing songs". Anchor the system paths (`/system/media/audio/`) and drop the `/record` heuristic, MediaStore flags already exclude call recordings in most ROMs.
- Isar reads and writes are synchronous on the UI isolate (`isar_library_data_source.dart:8`). Fine for a few hundred tracks; with 5,000+ tracks, `getAllTracks()` and the 100-track `insertTracks` batches during a background rescan will drop frames. Not a V0 blocker, but ask testers their library size.

---

## 2. Performance and glassmorphism

### 2.1 FPS and repaint boundaries

Good: position ticks never go through `emit` (the `ValueNotifier<PlaybackProgress>` pattern), every `BlocBuilder<PlayerBloc>` on hot paths has a `buildWhen`, and `GlassCard` respects the "RepaintBoundary + skip filter at sigma 0" contract.

Findings, in order of cost:

**F1 (High). The mini player progress fill animates inside the nav bar's `BackdropFilter`.**
`_MiniPlayerProgressFill` (`app_bottom_nav_bar.dart:321`, `:463`) is a `TweenAnimationBuilder` restarted on every position tick, so it produces a frame every vsync for as long as music plays. It lives inside the nav bar's `BackdropFilter` child, and a backdrop filter cannot be raster-cached: any frame re-executes **every** blur on screen. Net effect: on any page, while music plays, all visible blurs are recomputed 60 (or 120) times per second, forever. This is the main battery and jank driver on mid-range devices.

```dart
// Repaint 4 times per second at most, no tween, isolated layer.
return RepaintBoundary(
  child: ValueListenableBuilder<PlaybackProgress>(
    valueListenable: context.read<PlayerBloc>().progress,
    builder: (_, p, _) => CustomPaint(
      painter: _FillPainter(ratio: (p.ratio * 200).round() / 200, tint: progressTint),
    ),
  ),
);
```
Quantising the ratio (1/200 of the width, under 2 px) lets `shouldRepaint` return `false` for most ticks. The Marquee in the same row has the same effect while it scrolls; consider pausing it after 2 cycles.

**F2 (High). The Library page stacks 3 to 4 blurs, one of them nested.**

```
LibraryPage
├─ CustomSliverHeader      BackdropFilter #1 (sigma = collapse * 20, layer exists even at 0)
│   └─ LibrarySegmentControl -> GlassCard   BackdropFilter #2 (nested inside #1)
├─ _ScanBanner -> GlassCard                  BackdropFilter #3 (during scans)
└─ AppShell nav bar                          BackdropFilter #4
```

The project rule is "maximum two". Fixes:
- `CustomSliverHeader` (and the copies in `album_detail_page.dart:148`, `artist_detail_page.dart:146`): skip `BackdropFilter` when `collapse == 0`, and use `GlassTheme.card(context).blurSigma * collapse` so quality settings apply.
- `LibrarySegmentControl`: it already sits on a blurred surface, so give it a flat fill (`blurSigma: 0`).
- `_ScanBanner`: flat fill; it duplicates `AppShell`'s `_LibraryRescanBanner` anyway. Keep one of the two banners.

**F3 (Medium). The palette is extracted up to three times per track change, on the UI isolate, during the skip animation.**
`TrackPaletteCubit` (`track_palette_cubit.dart:48`), the shell `DynamicBackground` and the full player `DynamicBackground` (`dynamic_background.dart:84`) each run `PaletteGeneratorMaster.fromImageProvider` for the same artwork. Make `TrackPaletteCubit` the single producer (store the raw vibrant/dark colors once, derive the ambient and immersive tones in getters) and let `DynamicBackground` take colors instead of a path. Also guard the cubit against out-of-order results (a fast double skip can apply the older palette last), like `DynamicBackground` already does with `_paletteRequestId`.

**F4 (Low). Session persistence writes `SharedPreferences` every second of playback** (`player_bloc.dart:520`). Cheap on Android, but useless work; every 5 s plus on pause, on track change and on `AppLifecycleState.paused` is enough.

### 2.2 Low-tier fallback

Current behaviour: `GlassTheme._resolveQuality` (`glass_theme.dart:117`) downgrades only when `devicePixelRatio < 2.0 || shortestSide < 360`. Almost every Android phone sold since 2018 is at 2.0+ and 360+ dp: a 3 GB Helio G35 phone gets the full 28 sigma blur. In practice **no device takes the fallback**.

Additional defects:
- The persisted `glassQuality` is never applied at startup: `GlassTheme.overrideQuality` is only called from `SettingsCubit.setGlassQuality` (`settings_cubit.dart:94`). A tester who picks "Off" gets the blur back on the next launch.
- Applying it at startup as is would make things worse: the default saved value is `high`, which would override auto detection for everyone. The enum needs an `auto` value.
- Hand-written blurs ignore the theme entirely (`custom_sliver_header.dart:95`, album and artist detail headers).
- No reaction to the OS accessibility setting "Reduce transparency" (iOS) / "Remove animations" (Android).

Proposed resolution, computed once before `runApp`:

```dart
enum GlassQuality { auto, high, low, off } // persisted by name (see S4)

abstract final class GlassTier {
  /// Best effort: RAM is the only signal that correlates with GPU class
  /// across Android vendors.
  static Future<GlassQuality> detect() async {
    if (!Platform.isAndroid) return GlassQuality.high;
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.isLowRamDevice || info.physicalRamSize < 3072) return GlassQuality.off;
    if (info.physicalRamSize < 6144 || info.version.sdkInt < 29) return GlassQuality.low;
    return GlassQuality.high;
  }
}

// configureDependencies(), after loading initialSettings:
GlassTheme.setDetectedTier(await GlassTier.detect());
GlassTheme.overrideQuality(
  initialSettings.glassQuality == GlassQuality.auto ? null : initialSettings.glassQuality,
);
```

Trade-off: RAM is a proxy, not a GPU benchmark. The honest alternative is to measure: sample `SchedulerBinding.addTimingsCallback` for the first 10 s of the first session and downgrade if the 90th percentile raster time exceeds the frame budget. More precise, more code. Ship the RAM heuristic in V0, add the measured downgrade only if testers report jank.

Also add `MediaQuery.highContrastOf(context)` / `MediaQuery.disableAnimationsOf(context)` as an `off` trigger in `_resolveQuality`.

---

## 3. UX and key features

### 3.1 Settings screen

#### State today

A Settings page exists, but:
1. **Nothing navigates to it.** `AppRoute.settings` is declared in `app_router.dart` and used nowhere else.
2. Of its 13 controls, 3 are wired (pause on call, resume after call, duck), 1 is half wired (glass quality, see 2.2), **9 do nothing**: theme (the app is dark only), dynamic color, gapless, crossfade (the adapter code is commented out), scan on startup, watch folders, haptics, album art in notification, sleep timer.
3. It uses stock Material widgets (`SliverAppBar.large`, `SwitchListTile`) on the default scaffold: visually off-brand next to the rest of the app.

Recommendation: **ship fewer settings that all work.** A toggle that does nothing is a bug report from every tester who tries it.

#### Routing decision

Move Settings **inside the shell, under the Home branch**: `/home/settings`.

| Option | Pros | Cons |
|---|---|---|
| Root route (today) | Full-screen, no nav bar | `LibraryBloc` is not in scope (it is provided by the shell), so "Rescan" cannot work without a new global service; mini player disappears |
| **Child of `/home` (recommended)** | `LibraryBloc` and `PlayerBloc` in scope; mini player stays; tabs hide automatically (`isRootPage` is false); back gesture works natively | Settings belongs to the Home stack (same as Apple Music's account page) |

```dart
GoRoute(
  path: AppRoute.home,
  builder: ...,
  routes: [
    GoRoute(
      path: 'settings',
      name: AppRoute.settings, // turn the constant into a route name
      builder: (_, _) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<SettingsCubit>()..load()),
          BlocProvider(create: (_) => getIt<MaintenanceCubit>()..load()),
        ],
        child: const SettingsPage(),
      ),
    ),
  ],
),
```

#### Entry point

`_HomeHeader` in `lib/features/home/presentation/pages/home_page.dart:216`. Today it is a `Column` (greeting + subtitle). Make it a `Row`: the `Column` in an `Expanded`, then a `GlassIconButton(icon: LucideIcons.settings)` aligned to the greeting's first line. It is the only screen with a free top-right slot (Library's header already holds Sort and Refresh), and it is where users look for "account" style settings in Apple Music and Spotify.

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(child: greetingColumn),
    GlassIconButton(
      icon: LucideIcons.settings,
      onTap: () => context.pushNamed(AppRoute.settings),
    ),
  ],
)
```

#### Module structure

```
features/settings/
├── domain/
│   ├── entities/app_settings.dart          trimmed: glassQuality(auto|high|low|off),
│   │                                       hapticsEnabled, stopOnCall, resumeAfterCall, duck
│   ├── entities/system_info.dart           version, build, OS, model, RAM, detected glass tier,
│   │                                       track count, DB size, artwork cache size
│   └── repositories/
│       ├── settings_repository.dart        (exists)
│       └── maintenance_repository.dart     systemInfo(), clearArtworkCache(),
│                                           clearHistory(), exportLogs()
├── data/repositories/
│   ├── settings_repository_impl.dart       persist enums by name
│   └── maintenance_repository_impl.dart
└── presentation/
    ├── cubit/settings_cubit.dart           preferences: sync, optimistic, rollback (exists)
    ├── cubit/maintenance_cubit.dart        long async ops with their own busy flags
    ├── pages/settings_page.dart            composition only
    ├── sections/
    │   ├── appearance_section.dart         Glass quality: Auto / High / Low / Off
    │   ├── playback_section.dart           calls, ducking, haptics
    │   ├── library_section.dart            Rescan now, last scan date, track count
    │   ├── storage_section.dart            Artwork cache (size + clear), history, session
    │   └── about_section.dart              system info, Send feedback, Copy diagnostics
    └── widgets/settings_group.dart         inset grouped card, flat glass fill
```

Why two cubits: preference changes are instant and optimistic; maintenance operations take seconds, report a busy state per row and can fail independently. One union state for both forces every preference toggle to carry "is the cache being cleared" fields.

Blur budget on this page: `CustomSliverHeader` (1) + nav bar (2). Groups use a **flat** fill (`glass.fill` + `glass.border`, no `BackdropFilter`), like `_RecentlyPlayerCard` already does on Home.

#### Targeted logic

Rescan (only possible because the route is in the shell):

```dart
BlocBuilder<LibraryBloc, LibraryState>(
  buildWhen: (p, c) => (p is LibraryScanning) != (c is LibraryScanning),
  builder: (context, state) {
    final scanning = state is LibraryScanning;
    return SettingsTile(
      icon: LucideIcons.refreshCw,
      title: 'Rescan library',
      trailing: scanning ? const CupertinoActivityIndicator() : null,
      onTap: scanning
          ? null
          : () => context.read<LibraryBloc>().add(const LibraryRefreshRequested()),
    );
  },
)
```

Clearing the artwork cache: the order matters.

```dart
Future<Either<Failure, int>> clearArtworkCache() async {
  try {
    final freed = await _directorySize(_artworkDir);
    // DB first: if the app dies in between, the next scan finds no path,
    // reuses whatever file is still on disk, and nothing points to a
    // deleted file.
    await _library.clearAllArtworkPaths();
    await _artworkDir.delete(recursive: true);
    await _artworkDir.create(recursive: true);
    return right(freed);
  } catch (e, st) {
    return left(ErrorHandler.handle(e, st));
  }
}
```

The cubit then clears `PaintingBinding.instance.imageCache` and the palette caches, and asks for a rescan so artwork is re-extracted. Accept that the track currently playing shows the placeholder until it changes.

Feedback: "Send feedback" shares the crash log file (E2) plus a diagnostics text (`SystemInfo.toText()`). This needs **`share_plus`** (attachments through the share sheet: email, WhatsApp, Telegram, which is how testers actually reply) and **`package_info_plus`** (real version/build in diagnostics). Both are Flutter Community plugins with no transitive network code. `url_launcher` + `mailto:` is not enough because it cannot attach the log. "Copy diagnostics" uses `Clipboard` and needs no dependency.

Tests to add: `MaintenanceCubit` (busy flag per action, failure keeps previous size), `SettingsRepositoryImpl` (unknown enum name -> default, legacy int index migration), and a widget test that `/home/settings` keeps the mini player visible.

### 3.2 Track menu (`...`)

#### State today

- `TrackContextMenu` returns `Container()` (`track_context_menu.dart:11`). A long press in Library (`library_page.dart:317`) opens a `CupertinoModalPopup` with **nothing in it**: the screen dims and the tester thinks the app froze. Visible bug.
- The `...` buttons on album and artist pages, both "Shuffle" buttons there, and both Home "View all" links are `onTap: () {}`.
- The full player options sheet mixes French (`'Ajouter à Likes'`, `'Voir l'album'`) in an English app, and "Voir l'album" only closes the sheet.

#### Structure

One sheet, one entry point, used everywhere a track appears:

```
features/library/presentation/widgets/track_actions/
├── track_action.dart          enum TrackAction { playNext, addToQueue, like,
│                                                 goToAlbum, goToArtist, fileInfo }
├── track_actions_sheet.dart   header (artwork, title, artist) + action rows
├── track_file_info_view.dart  format, size, duration, path, date added
└── show_track_actions.dart    showTrackActions(context, track, origin: ...)
```

`origin` (`library`, `album`, `artist`, `queue`, `nowPlaying`) hides what makes no sense (no "Go to album" on that album's page) and picks the surface: over Now Playing the sheet must be **opaque** (that page already uses the two allowed blurs), so `GlassBottomSheet` needs a `quality` parameter forwarded to `GlassTheme.sheet(context, quality: ...)`.

Actions are pure dispatch to what already exists; the sheet holds no logic:

| Action | Target |
|---|---|
| Play next | new `TrackQueuedNext` event (below) |
| Add to queue | `TrackAddedToQueue(track)` (exists, appends) |
| Like / Unlike | `LikesCubit.toggle` (label from current liked state) |
| Go to album / artist | `context.goNamed(AppRoute.albumDetail, pathParameters: {'id': '${track.albumId}'})`; from Now Playing, pop the player first |
| File info | nested view in the same sheet |

"Play next" must resolve its index **inside the sequential queue handler**, not in the widget. Computing `currentIndex + 1` in the UI is a race: if the track advances between the tap and the event, the insert lands at the new current index, before the playing track, and is never heard.

```dart
// player_event.dart: the sealed hierarchy makes _onQueueEdit's switch
// fail to compile until the new case is handled.
final class TrackQueuedNext extends QueueEditEvent {
  final Track track;
  const TrackQueuedNext(this.track);
}

// player_bloc.dart, _onQueueEdit
case TrackQueuedNext(:final track):
  final queue = _audioServicePort.currentQueue;
  if (queue == null) {
    add(PlayTrackRequested(track)); // nothing playing: just play it
    return;
  }
  await _addToQueue(
    AddToQueueParams(track: track, index: queue.currentIndex + 1),
  );
```

Test cases: idle player -> plays; last track playing -> appended; shuffle on -> lands right after the current track in playback order; track advancing while the event waits -> still right after the *new* current track; same track queued next twice -> two entries.

"Go to" trade-off: `goNamed` switches to the Library branch and resets its stack; `pushNamed` across `StatefulShellBranch`es is not reliable. Switching tabs is also what Apple Music does.

#### Delete: out of V0

Recommendation: do not ship it in V0.
- Android 11+ needs `MediaStore.createDeleteRequest` and an `IntentSender` result, Android 10 a `RecoverableSecurityException` round trip, Android 9 and below `WRITE_EXTERNAL_STORAGE`. None of the current plugins do it: this is a custom `MethodChannel` in `MainActivity`.
- iOS cannot delete media library items at all.
- It is the only irreversible action in the app, on the testers' personal files, in the build you trust least.

Ship the menu without it. If testers ask, V1 can add a "Hide from library" flag first (Isar field, respected by the scan diff), then real deletion behind the system confirmation dialog.

### 3.3 Animations and micro-interactions

The now-playing morph is already strong. Three additions with the best effect to cost ratio:

1. **Album artwork hero, grid -> album page.** `AlbumCard` artwork and the `AlbumDetailPage` header artwork share `Hero(tag: 'album-art-${album.id}')`. Both are in the Library branch navigator, and go_router 17 wraps branch navigators in a `HeroControllerScope`, so it works without plumbing. Watch the decode size: `ArtworkImage` decodes at the displayed size, so the flight starts from a ~160 px bitmap and pops when the 300 px one arrives. Use a `flightShuttleBuilder` that renders the destination's decode size, or decode the card at the detail size (it is cached by path).

2. **Long press: press-scale then haptic.** On `TrackListTile`, scale to 0.97 over 120 ms while the finger is down, fire `HapticFeedback.mediumImpact()` exactly when the sheet opens, and `selectionClick()` on each action. That sequence is what makes iOS context menus feel physical. Gate every call behind the haptics setting inside `AppHaptics` (one static flag, set like `GlassTheme`), and move haptics out of `PlayerBloc`: today `SkipNextRequested` fired by the error recovery timer vibrates without any user action.

3. **Confirmation for invisible actions.** "Play next" and "Add to queue" change nothing on screen today. Show a small glass pill above the mini player ("Playing next", 1.5 s, slide and fade) and a single scale pulse on the mini player artwork. Same for Like: a heart bounce (`flutter_animate` is already a dependency) plus `lightImpact`.

---

## 4. Go / No-Go: blockers before the first share

Ranked by impact on what testers will experience and on what you can learn from them.

| # | Blocker | Why it blocks | Effort |
|---|---|---|---|
| **B1** | Playback errors are never observed (E1) | One unreadable file mid-queue silently stalls playback. Very likely on real libraries (`wma` is even whitelisted). | 0.5 d |
| **B2** | No crash capture, no feedback channel (E2) | Release logs are off, nothing catches uncaught errors, a startup failure is a blank screen. You would get "it crashed" with zero data. | 0.5 to 1 d |
| **B3** | Dead and fake UI | Empty long-press modal, 6 `onTap: () {}`, Settings unreachable with 9 inert toggles, French strings in the options sheet. Every tester files the same reports and the real ones get lost. | 1 d with the track menu and trimmed Settings |
| **B4** | Media notification misuse (`audio_handler_impl.dart`) | (a) every position tick is pushed to `playbackState` (`:46`): one platform channel call and MediaSession update per tick, all session long; set `updatePosition` only on seek and status changes, and pass `speed` so the OS extrapolates. (b) `_buildControls` (`:124`) always shows **both** Play and Pause; show one, and set `androidCompactActionIndices`. (c) `stop()` (`:67`) overrides `BaseAudioHandler.stop` without moving to `AudioProcessingState.idle`, so dismissing the mini player leaves a stale notification. | 0.5 d |
| **B5** | Release hygiene | Release is signed with the **debug key** (`android/app/build.gradle.kts:37`): moving to a real key later forces testers to uninstall, losing likes, playlists and history; Play internal testing refuses debug-signed builds. Plus the unused photo/video permissions (P1) and the red template test in `test/widget_test.dart`. | 0.5 d |

Strongly recommended in the same pass, not blocking: F1 (blur re-rendered at 60 fps during playback) and F2 (blur stacking on Library), the low-tier fix in 2.2, P3/P4 on permissions, and declaring the beta **Android only** (P6).

### Pre-flight checklist

```
[ ] B1  errorStream wired, maxSkipsOnError, 'wma' removed, 4 tests green
[ ] B2  global handlers, CrashLog file, BootFailureApp, Send feedback
[ ] B3  track menu shipped, Settings reachable and trimmed, no empty onTap, English only
[ ] B4  notification: no per-tick updates, single play/pause, idle on stop
[ ] B5  upload keystore, manifest cleaned, widget_test.dart removed or replaced
[ ] flutter analyze: 0 issues
[ ] flutter test: all green
[ ] flutter build apk --release on a real low-end device (3 to 4 GB RAM):
    scroll Library during playback with the performance overlay on
[ ] Manual: fresh install on Android 13+, deny then grant from system settings
[ ] Manual: queue with one corrupted file in the middle
[ ] Version bumped (1.0.0+1 -> 0.1.0+1 for a beta), CHANGELOG entry
```
