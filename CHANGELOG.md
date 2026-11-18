# Changelog

All notable changes to Troona are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Library: an alphabetical index down the right edge of Songs, Albums and Artists when they are sorted by name.
- Recently added and Recent albums: the songs and albums added last, newest first, opened from Search and Home.
- An artist's photo grows from their card into their page, and back.
- Now Playing: the artist's name opens their page. Songs and albums by several artists ask which one.
- A long press on an album card opens its menu: Play, Shuffle, Play next, Add to queue.
- Album and artist cards show an equalizer while one of their songs plays.
- Artist pages: See all opens every song of an artist on a page of its own, sorted by plays, title, album or date added.
- Album pages: the song playing comes into view on opening, and pulling down draws the record further out.
- The mini player counts the songs you queue, and a like pops the same heart everywhere.

### Changed

- Now Playing: seeking turns the ring into a lit band, closing sends the lens alone into the mini player, and dragging down moves the content only.
- Album and artist pages take the colours of their own cover.
- Album, artist and recent pages open in the tab you are in, instead of jumping to the Library, and the Library keeps its sort.
- Home is lighter: one card about the app at a time, this week's plays under the greeting, no more Your artists and Your playlists.
- Artist pages have one layout, with or without a photo, and small discographies fit better.
- Album pages: a tap on the record only pauses and resumes (Play starts the album), and the record reads better on a dark page.
- Library: artists three across, tighter grids, and only the items shown on opening play their entrance.
- Fewer outlines on Home and Settings, easier to read durations and tabs, and switches in the accent colour.

### Fixed

- Play next and Add to queue with nothing playing now start the music, and an album or artist goes into the queue in one step, never split or lost.
- "Added to queue" shows only once the songs are in, and a long press on a song vibrates once.
- Search shows artists with their downloaded photo and opens them in the Search tab. See all of artists or albums opens that list in the Library.
- Artist pages keep their card's cover and name while loading, and say so when their songs cannot be read.
- Artist photos: no more grey silhouettes or photos of namesakes, and names stay readable over them.
- Playlist covers no longer repeat one album.
- Page headers: the small title stays readable over light covers and no longer shows over the large one.
- The mini player's progress moves smoothly.

## [1.6.0] - 2026-11-16

### Added

- Your listening: any week or month, with listening time, top songs, artist and albums, and when you listen most.
- Share a week or a month as a story image.
- Swipe a song to play it next or add it to the queue. Swipe the mini player to change song, hold it to like.
- Album pages: the record turns while the album plays.
- Artist pages show their latest release.

### Changed

- Jump back in resumes the session where it stopped.
- Artist pages: one round Shuffle button, releases newest first, and a glow of their cover when they have no photo.
- One set of haptics across the app, and the song playing looks the same in every list.
- The listening calendar fills each day by how much music it had.
- The background follows a new song's colours over two seconds.

### Fixed

- The Library's segments vibrated with haptics turned off.

## [1.5.0] - 2026-11-13

### Added

- An album's cover flies into its page, and back.

### Changed

- Bold large titles, and a dot under the selected tab.
- Album and artist pages give their facts in one line, show years on songs and cards, and drop the In your library cards.
- Going from an album to its artist and back returns to the page instead of opening a copy.
- The Library no longer shows its counts.

### Fixed

- Large fonts cut artist names short in the Library.

## [1.4.0] - 2026-11-06

### Changed

- Pages run edge to edge, under the status bar and the floating tab bar.
- Every page opens on a large title that shrinks into a glass bar as you scroll.
- An artist's photo fills the top of their page, and pulling down enlarges it.
- The search field stays pinned, and scrolling the results closes the keyboard.
- Tapping the tab you are on scrolls back to the top.

## [1.3.0] - 2026-11-03

### Added

- Songs that credit several artists count for each of them, with Appears on and Singles sections on their pages. A name with a comma, such as "Tyler, The Creator", stays one artist.

### Changed

- Artist pages start with their five most played songs.
- Album counts leave out singles and guest appearances, and singles are marked as such.
- The Artists list leaves out collaborations and artists only ever featured.
- Album pages show the year and a Lossless badge, and songs without numbers keep their download order.
- About shows only when Last.fm has a text, and similar artists only when they are in your library.
- A rescan picks up edited tags.

### Fixed

- Years were never read.
- An album saved across several folders shows as one.
- A featured artist no longer turns an album into "Unknown artist" or claims a single they only appear on.
- Two albums sharing a name are no longer merged.

## [1.2.0] - 2026-10-31

### Added

- Songs without an artist tag take it from an "Artist - Title" file name.
- Replacing a queue that holds songs you added offers Undo.

### Changed

- Menus and dialogs in Troona's own style.
- One style for labels, buttons, back buttons and icons, with larger touch targets.
- The same placeholder everywhere for a missing cover.

### Fixed

- A page opened over a tab no longer shows the page below while it slides in.
- Songs without an artist read "Unknown artist".
- The record no longer shows through an album's sleeve without a cover.

## [1.1.1] - 2026-10-31

### Changed

- What's new lists every release.

### Fixed

- Home follows scans and playlist changes on its own.
- Troona could hang on launch after Android had started playback by itself.
- Now Playing's title could lag behind the song for a frame.

## [1.1.0] - 2026-10-30

### Added

- Rename a playlist.
- Like the song playing from the system media controls (Android 13 and later).
- Resume the last song from the system media controls after closing Troona (Android 11 and later).
- Backup and restore of playlists, likes, listening history and settings.
- An optional daily update check against GitHub releases.

### Changed

- The Playlists tab follows changes made elsewhere, a long press on a playlist offers Edit and Delete, and the like heart uses the accent colour.

### Removed

- The playlist description field, which was never saved.

### Fixed

- Small screens and large fonts: nothing is cut short or hidden under the bars.
- The playback notification shows Troona's icon.

## [1.0.0] - 2026-10-30

First public release. Troona plays the music stored on your phone: no account, no ads, no analytics.

### Library

- Songs, albums and artists read from the phone, with album and artist pages and search.
- Scans show their progress, and later ones run in the background.
- A Lossless badge for albums in FLAC or WAV.

### Playback

- Background playback with lock screen and notification controls.
- Shuffle, repeat, soft fades and gapless playback.
- Pauses when headphones are unplugged or a call comes in.
- Sleep timer and playback speed from 0.75x to 2x.
- The queue and position come back on the next launch.

### Now Playing

- A cover carousel under a glass lens, with a ring to seek and colours taken from the cover.
- A queue sheet to reorder, remove and undo.

### Playlists and likes

- Playlists, liked songs, and a monthly Replay of last month's 25 most played songs.

### Listening history

- A play counts after 30 s, or half a song shorter than a minute.
- Home shows recently played songs and your week in music.

### Settings and privacy

- Optional online extras, off by default: artist bios (Last.fm) and photos (Deezer).
- Glass quality, cache cleanup and problem reports.
- A privacy policy in the app and in [`docs/privacy-policy.md`](docs/privacy-policy.md), and What's new after updates.

### Languages and accessibility

- English and French, following the phone's language.
- Labelled playback controls for screen readers.

### Android

- Reads audio files only. Network access is used by the online extras alone.
- App backup is off.

[Unreleased]: https://github.com/donfreddy/troona-music/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/donfreddy/troona-music/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/donfreddy/troona-music/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/donfreddy/troona-music/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/donfreddy/troona-music/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/donfreddy/troona-music/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/donfreddy/troona-music/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/donfreddy/troona-music/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/donfreddy/troona-music/releases/tag/v1.0.0
