# Changelog

All notable changes to Troona are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

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

[1.0.0]: https://github.com/donfreddy/troona-music/releases/tag/v1.0.0
