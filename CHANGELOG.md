# Changelog

All notable changes to Troona are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Open a song from another app: Troona is offered under Open with for an audio file (in a file manager, after a download), and plays it on Now Playing, the song of your library with its cover, plays and like. A file your library does not hold is not played yet: a message says so.
- Synced lyrics in Now Playing: the Lyrics button in the dock shows them in place of the covers, the line being sung lit and kept in view, with a seek bar. Tap a line to go there; scroll freely and they follow again after a few seconds, or at once with Back to the current line. Plain lyrics show when they have no timings. The screen stays on while lyrics play. The covers and the lyrics fade into each other, the tab bar slides away to leave them the room, and the page still closes into the mini player. Now Playing opens on the lyrics when it was closed on them. Where nobody sings for a while, three dots fill until the singing comes back. The lines around the one sung take a light tint of the cover's colours instead of a grey, always readable.
- Import a `.lrc` file for a song, and set its timing a tenth of a second at a time when it runs early or late. Both are in the song's menu, under Lyrics options.
- Lyrics search, off by default: when a song has no lyrics, its title, artist, album and length go to LRCLIB, then lyrics.ovh, only when you open its lyrics. Turn it on from the lyrics screen or in Settings, Online extras. Clear downloaded info deletes the lyrics found online and keeps the ones you imported. Backups carry imported lyrics, and the timing you set on lyrics found online.
- Automatic backups: daily or weekly, into a folder you pick once, with no storage permission; the folder and its backups stay if you uninstall Troona. The last five automatic backups are kept, the ones you make by hand are never deleted, and a backup with nothing new is not written again. Troona says when it can no longer reach the folder.
- Choose what a backup holds: playlists, likes, listening history, lyrics, settings, equalizer. Restoring a backup offers the parts it holds, all ticked, and writes only the ones you keep.
- Keep folders out of your library, such as voice notes or a podcasts folder: Settings, Library, Folders. Their songs leave the library and come back, with their likes, plays and playlists, when you turn the folder back on.
- Choose the shortest song your library keeps: 10 s, 30 s, 1 min or 2 min, in Settings, Library.

### Changed

- Open-source licences open in Troona's own pages, with its background and back button: one row per package, in sections by initial, its licence shown. The list opens at once and scrolls smoothly.
- Settings are organised in pages: Audio, Library, Online extras, Appearance, Backup & restore, Storage and About, each row saying what it holds or how it stands. Every switch explains what it does, and the caches and resets have their own page.
- Backup moved to its own page, Settings > Backup & restore, which lists the backups in your folder with what each holds; each can be restored, shared or deleted.

### Fixed

- Moving a song in a playlist that holds songs you left out, or whose file is gone, moved the wrong one. Playlist and liked song counts now count only the songs you see.
- A song you left out, or deleted, no longer drops the whole queue Troona resumes on its next start: the rest comes back.
- Settings say when your filters would leave no song in your library, and are therefore not applied.
- Covers come back by themselves after Android or a "Clear cache" emptied Troona's cache: the next scan extracts them again, where they stayed blank until Clear cover cache.

## [1.8.0] - 2026-11-22

### Added

- Smart playlists: songs picked by rules (plays over a period, last played, date added, liked, artist, album, genre, year, duration, lossless), matching all or any of them, sorted and capped as you choose. Start from a template (Most played this month, Never played, Forgotten, Recently added, Lossless) or from nothing; the editor counts the songs as the rules change. They are worked out again each time you open one and after each song you play, and Save as a playlist keeps today's songs as a playlist of your own. Backups carry their rules.
- Pick several songs at once: a long press on a song in the Library's Songs, an album, a playlist, an artist's page, Recently added or Search starts picking, and taps add or remove songs. The header counts them, with Select all; the bar below plays them, shuffles them, queues them next or last, or adds them to a playlist, in the order of the list. Back ends the selection.
- An equalizer, on Android: from Now Playing or Settings, draw the curve across your phone's bands with a finger, or start from a preset (Bass boost, Vocal, Rock and more). Save a curve under a name, hold the ear to hear the song without it, and add up to 6 dB with Volume +. Avoid clipping lowers the level by as much as the bands boost. Backups carry it.

### Changed

- A new playlist starts named "My playlist #N", ready to save or rename. Its form covers the tabs and the mini player, and shows no empty cover.
- In a playlist, a long press on a song picks it: the handle at the end of the row moves it.
- The centre of the tab bar is an orb in the colours of the song playing, and a button: it opens Now Playing, or starts music when nothing is loaded (the last session, else the whole library shuffled). On Now Playing it closes the page. Its colours swirl to each new song's and it pulses on play and pause; at rest it does not move.
- Glass effects: Light becomes Balanced, which keeps the blur in page headers only and draws the tab bar, Now Playing and sheets without it. Off becomes No blur, with tinted surfaces and their edges instead of flat grey. Settings say which one Auto picked.
- The tab bar casts a shadow, and floating glass shares one edge.
- Now Playing's ring is drawn in light grey to white, which reads over every cover's colours.
- Small grey text is easier to read.
- The mini player: swiping moves the titles only, with the next or previous song's coming in as you go, and the cover fades to the new song's instead of sliding.

### Fixed

- Changing the glass effects applies at once, everywhere.
- Swiping the mini player down closes it: over the tabs it comes down onto them and dissolves, alone it slides off the screen.

## [1.7.0] - 2026-11-19

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
- Artist photos are looked up on Deezer with up to three of the artist's song titles, to tell them from namesakes. The privacy policy says so.

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

[Unreleased]: https://github.com/donfreddy/troona-music/compare/v1.8.0...HEAD
[1.8.0]: https://github.com/donfreddy/troona-music/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/donfreddy/troona-music/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/donfreddy/troona-music/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/donfreddy/troona-music/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/donfreddy/troona-music/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/donfreddy/troona-music/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/donfreddy/troona-music/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/donfreddy/troona-music/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/donfreddy/troona-music/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/donfreddy/troona-music/releases/tag/v1.0.0
