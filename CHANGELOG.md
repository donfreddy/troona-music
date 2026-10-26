# Changelog

## [Unreleased]

### Store readiness

- English and French UI (gen-l10n), sentence case, one toast and one dialog component, empty states with an action.
- Online extras are opt-in and off by default, with separate switches for bios (Last.fm) and photos (Deezer). Each switch gates its own service; turning photos off deletes downloaded photos. Privacy policy in `docs/privacy-policy.md` and in Settings.
- Real sleep timer and playback speed; demo lyrics, equalizer and cast removed. Fake settings removed.
- "Lossless" only when every song of an album is FLAC or WAV.
- Android: audio-only permissions (vendored `on_audio_query_plus_android` patched), `INTERNET` for the online extras, release signing from `key.properties`, backup off, label "Troona", dark launch window.
- Library: pure, accent-aware filter and sort; albums grouped by id; one read per load; short songs kept; no playlist cap; artwork checked once, written in batches, with live progress; silent rescans with a toast when songs were added or removed; a restarted or failed scan keeps the library on screen.
- Player: every Shuffle button turns shuffle mode on and keeps the source order; lock screen position and queue index stay right after auto-advance and in-app seeks; labelled controls keep their tap action for screen readers.
- Persistence: the session queue is written only when it changes; the crash log writes asynchronously; downloaded pictures are written atomically.
- Settings: one shared settings state, maintenance actions (clear covers, clear online info, report a problem) that finish even if the page is left.

### Added

- Queue sheet over the Now Playing page: session history, now playing and up next in one list. It opens on now playing; the history is above, reached by scrolling up or with the history button. Tap to jump, drag the handle to reorder, swipe to remove with a 4 s undo. Opens from the top bar button or a flick up.
- Insert a track at a given queue position (`addToQueue(track, index:)`).
- Persistent play history (`lib/features/history/`): a play counts after 30 s of listening, or half a track shorter than a minute; seeks do not count. Up to 500 events in Isar.
- Home "Recently Played" now lists the last played tracks, topped up with the newest ones until four have been played, and refreshes when a play is recorded.
- Now Playing: fixed glass lens over a cover carousel, elapsed-time arc with circular seek on the ring, and a morph between the glass ring and the mini player.
- Global search for tracks, artists and albums; playlist management; album and artist detail pages.
- Playback session restore, dynamic track palette, audio fading, haptic feedback on controls, smart recovery from playback errors.

### Changed

- The Isar database is opened once in `lib/core/database/` (`AppDatabase`), with each feature declaring its own collections.
- Artwork is decoded at its displayed size (`ArtworkImage`).
- Navigation uses a `StatefulShellRoute`; icons moved to Lucide.
- Now Playing: the title and artist follow the cover being swiped to, instead of changing once the player has switched tracks.
- Now Playing: the title slides up for a next track and down for a previous one, fading out at the top and bottom edges instead of being cut.
- Theme tokens aligned with the lilac on black reference design.

### Fixed

- Shuffle no longer reshuffles the queue on each carousel swipe: the player jumps within the queue.
- Queue edits stay consistent with the original order and apply one after the other.
- Queue sheet: after a removal rejected by the player, the next swipes no longer remove a neighbouring track, and an Undo tapped while the removal was pending no longer queues the track twice.
- A new queue is published before the player loads it, so the lock screen and the player no longer show the previous track after starting another album or toggling shuffle.
- With a track queued twice, the player follows the entry actually playing instead of the first copy.
- The tabs come back after leaving a detail page with the system back (Android button, iOS swipe).
- Position ticks no longer rebuild the player surfaces.
- Playback controls are centred between the ring and the nav bar; the ring hairline opens behind the time label.
- The theme compiles on Flutter 3.47 (`cupertino` import).

## [1.0.0]: MVP

### Audio Engine

- Offline music playback via `just_audio` behind an `AudioServicePort` abstraction
- Lock-screen / notification controls via `audio_service` (`AudioHandlerImpl`)
- Audio focus and interruption handling (`AudioSessionService`): respects phone calls, other apps
- Queue management with repeat and shuffle modes
- Likes: mark/unmark tracks as favourites, persisted across sessions

### Library

- 4-phase device scan: query → diff → persist → artwork extraction
- Concurrent artwork extraction with in-flight deduplication (max 4 workers)
- Artwork cached to system temp; survives hot restart
- "Recently added" sorted by `indexedAt` timestamp (O(log n) Isar index)
- Scan cancellation always emits a final `done` event: no UI freeze

### Player UI

- Full-screen player with artwork carousel, progress bar, and playback controls
- Drag-to-dismiss: page follows the finger, snaps back if cancelled, Hero artwork contracts to mini player on confirm
- Dynamic background: colour-sampled from current artwork
- Rotating artwork disc in the centre nav slot when playing

### Navigation & Shell

- Single unified glass bottom bar: mini player row slides in above nav tabs when a track is active (`AnimatedSize`)
- Swipe-up on the mini player row opens the full player
- `Hero(tag: 'artwork_<id>')`: artwork expands from 38 px thumbnail to full carousel disc and contracts back
- Route transition is a bare fade so the Hero animation is the primary visual: no double-slide conflict

### Settings

- Audio quality toggle (glass blur level): Off / Low / Medium / High
- Applied at runtime without restart; propagated to `AudioSessionService`

### Permissions

- Navigation guard (GoRouter `redirect`) blocks all routes until audio permission is granted
- Dedicated `PermissionPage` with permanent-denial deep-link to system settings

### Design System

- Three-level token hierarchy: Primitives → Semantic (`AppColors`) → Components (`GlassTheme`)
- `GlassCard`, `GlassBottomSheet`, `GlassButton`, `GlassIconButton`: iOS 17/18 glassmorphism
- `BackdropFilter` budget enforced: max 2 per screen, always inside `RepaintBoundary`
- Dark theme only; portrait lock
