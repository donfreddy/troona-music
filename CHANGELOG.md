# Changelog

## [1.0.0] — MVP

### Audio Engine

- Offline music playback via `just_audio` behind an `AudioServicePort` abstraction
- Lock-screen / notification controls via `audio_service` (`AudioHandlerImpl`)
- Audio focus and interruption handling (`AudioSessionService`) — respects phone calls, other apps
- Queue management with repeat and shuffle modes
- Likes — mark/unmark tracks as favourites, persisted across sessions

### Library

- 4-phase device scan: query → diff → persist → artwork extraction
- Concurrent artwork extraction with in-flight deduplication (max 4 workers)
- Artwork cached to system temp; survives hot restart
- "Recently added" sorted by `indexedAt` timestamp (O(log n) Isar index)
- Scan cancellation always emits a final `done` event — no UI freeze

### Player UI

- Full-screen player with artwork carousel, progress bar, and playback controls
- Drag-to-dismiss: page follows the finger, snaps back if cancelled, Hero artwork contracts to mini player on confirm
- Dynamic background — colour-sampled from current artwork
- Rotating artwork disc in the centre nav slot when playing

### Navigation & Shell

- Single unified glass bottom bar: mini player row slides in above nav tabs when a track is active (`AnimatedSize`)
- Swipe-up on the mini player row opens the full player
- `Hero(tag: 'artwork_<id>')` — artwork expands from 38 px thumbnail to full carousel disc and contracts back
- Route transition is a bare fade so the Hero animation is the primary visual — no double-slide conflict

### Settings

- Audio quality toggle (glass blur level): Off / Low / Medium / High
- Applied at runtime without restart; propagated to `AudioSessionService`

### Permissions

- Navigation guard (GoRouter `redirect`) blocks all routes until audio permission is granted
- Dedicated `PermissionPage` with permanent-denial deep-link to system settings

### Design System

- Three-level token hierarchy: Primitives → Semantic (`AppColors`) → Components (`GlassTheme`)
- `GlassCard`, `GlassBottomSheet`, `GlassButton`, `GlassIconButton` — iOS 17/18 glassmorphism
- `BackdropFilter` budget enforced: max 2 per screen, always inside `RepaintBoundary`
- Dark theme only; portrait lock
