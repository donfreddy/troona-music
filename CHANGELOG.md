# Changelog

All notable changes to Troona are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.1.1] - 2026-10-31

### Changed

- What's new shows every release, not only the latest: the installed one first, with its date and how many changes of each kind, then the earlier ones, each opening on tap.

### Fixed

- Home kept its "No music here yet" card after the first scan found songs, until it was refreshed by hand. It now follows scans and playlist changes on its own.
- Troona could stay on its launch screen, then stop responding, when it was opened after Android had started its playback service on its own (resuming from the system media controls, a headset button).
- Now Playing: after a swipe to another cover, the title could lag behind the song for a frame.

## [1.1.0] - 2026-10-30

### Added

- Rename a playlist: long press it, then Edit playlist.
- Android 13 and later: a heart in the system media controls (notification and lock screen) likes or unlikes the current song.
- Android 11 and later: after Troona is closed, the system media controls offer to resume the last song where it stopped. A headset play button does the same.
- Backup and restore, in Settings: playlists, likes, listening history and settings go to a file you keep, and come back on this phone or another one. Songs are found again by file, then by title, artist and album; the ones missing are listed, and restoring the same file after adding them links them. Restoring adds to what is there and never doubles anything. Online extras keep this phone's choice.
- Update check, off by default, in Settings: once a day Troona asks GitHub for its latest version and, when there is a newer one, shows a card on Home with View (opens the release page) and Skip this version. Check for updates now, in Support, works with the switch off. Troona never downloads or installs anything itself.

### Changed

- The Playlists tab follows changes made elsewhere, such as a restored backup, without being reopened.
- A long press on a playlist opens Edit playlist and Delete, instead of going straight to the delete confirmation.
- The like heart on Now Playing uses the accent colour, like the liked songs playlist, instead of red.

### Removed

- The description field of the playlist editor: it was never saved.

### Fixed

- Small and 16:9 screens (360 x 640, Galaxy S7 class) and large fonts: Now Playing shrinks its cover ring instead of pushing the playback controls under the tab bar; the Home resume card, the quick chips, the Library counts, section titles and the album and artist headers grow, wrap or stack instead of being cut; the last items of Playlists, Search and the detail pages scroll clear of the mini player. The tab bar, mini player, Now Playing, its queue and the Library filter follow the font size up to 1.3x, everything else follows it fully.
- Android: the playback notification shows the Troona note in the status bar instead of a plain disc.

## [1.0.0] - 2026-10-30

First public release. Troona plays the music stored on your phone: no account, no ads, no analytics.

### Library

- Songs, albums and artists read from the device, with album and artist pages.
- Search across songs, artists and albums.
- Scans show their progress live; later scans run silently, keep the library on screen and report songs added or removed.
- "Lossless" badge when every song of an album is FLAC or WAV.

### Playback

- Background playback with lock screen and notification controls, including the playback speed.
- Shuffle and repeat (all, one). Every Shuffle button starts on a random song; turning shuffle off brings back the original order.
- Soft fades: play and resume fade in, pause fades out, a skip fades briefly. Gapless auto-advance.
- Unplugged headphones and phone calls pause at once.
- Sleep timer: 15, 30 or 45 minutes, an hour, or the end of the song, with a 30 s fade out.
- Playback speed from 0.75x to 2x.
- The queue and position are restored on the next launch.

### Now Playing

- Cover carousel under a glass lens, with the elapsed time on a ring you can drag to seek.
- Background colours taken from the cover.
- Morphs from and back to the mini player.
- Queue sheet: what played, what is playing and what comes next in one list. Drag to reorder, swipe to remove, undo for 4 s.

### Playlists and likes

- Create and delete playlists, and reorder their songs.
- Liked songs gathered in their own playlist.
- Monthly Replay: on the first launch of a month, last month's 25 most played songs become a playlist.

### Listening history

- A play counts after 30 s of listening, or half a song shorter than a minute.
- Home: recently played songs and "Your week in music" (listening time, top artist and top song of last week, and a calendar of this month's listening days).

### Settings and privacy

- Optional online extras, both off by default: artist bios (Last.fm) and artist photos (Deezer). Turning photos off deletes the downloaded ones.
- Glass quality: automatic by device, or high, low and off.
- Maintenance: clear cached covers, clear online info, report a problem (device info and recent errors, readable before sending).
- Privacy policy in the app and in [`docs/privacy-policy.md`](docs/privacy-policy.md).
- "What's new" sheet after updates, also available from Settings.

### Languages and accessibility

- English and French, following the phone's language.
- Labelled playback controls for screen readers.

### Android

- Reads audio files only, never photos, videos or documents. Notifications carry the playback controls; network access is used by the online extras alone.
- App backup is off.

[Unreleased]: https://github.com/donfreddy/troona-music/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/donfreddy/troona-music/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/donfreddy/troona-music/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/donfreddy/troona-music/releases/tag/v1.0.0
