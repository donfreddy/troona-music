# Changelog

All notable changes to Troona are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Artist pages show their latest release on its own, above their albums, when the songs carry a year.
- Swipe the song in the mini player left for the next one, right for the previous one. A light tick tells when the swipe will count.
- On an album page, the record slides further out of its sleeve and turns while the album plays, with the cover as its label. Tap it to play the album, or to pause and resume it. It stays still when the phone asks for less motion.
- Swipe a song right to play it next, or left to add it to the queue, in the Library, albums, artists and search. Screen readers offer both as actions of the song.
- Your listening, opened from the Home card, shows any week or month: switch between Week and Month, and step back to earlier ones with the arrows. Each gives its listening time, days with music, busiest day, top five songs (tap one to play the list from it), top artist and top albums.
- When you listen: the plays of the week or month by weekday and time of day, with the moment that stands out in words ("Peak: Friday evening").

### Changed

- Home's Jump back in card goes on with the session where it stopped, instead of playing the last song again from its start. It names the album, artist or playlist it was started from, the listening time left and how far along it is; while it plays, it reads Now playing and opens Now Playing.
- Artist pages have one action, Shuffle, as a round button on their photo: an artist's songs have no order. Tap a song to play in order from it.
- An artist without a photo opens on a soft glow of their cover's colours instead of a plain background.
- An artist's albums, singles and the albums they appear on come newest first, also in More by on album pages.
- The counts under an artist's name read clearly on a light photo.
- Haptics follow one vocabulary: a firm tap when playback starts or stops, a light one for a skip, a refresh or a menu, a tick for a choice. Playing a song or Play and Shuffle no longer tap twice.
- The song playing looks the same in every list: its cover dimmed under the moving equalizer, which stops while paused, and its title in the accent colour. Playlists and Home showed a still note instead.
- The background behind the tabs takes two seconds to follow a new song's colours, instead of switching at once.
- The listening calendar shows each day as a square filled by how much music it had, in five steps from none to 30 plays or more, instead of a dot for any music at all. Tap a day for its count. The squares light up one after the other, unless the phone asks for less motion.

### Fixed

- The Library's segments vibrated even with haptics turned off in Settings.

## [1.5.0] - 2026-11-04

### Added

- Tapping an album's cover opens its page with the cover flying into place, and back takes it home.

### Changed

- Large titles are bold, in the same voice as album and artist names and section titles.
- The selected tab shows a dot under its icon, not only a brighter colour.
- Album pages state their year, song count and length, and artist pages their song count, releases and length, as one line of text instead of pills. Lossless keeps its badge.
- Album pages no longer title their track list Songs. Under the songs, a quiet line gives the album's size and formats instead of the In your library card.
- Artist pages show each song's album and year under its title, instead of repeating the artist's name, and their album and single cards give the year. Their In your library card is gone: the counts it repeated are under the name.
- More by on album pages gives each album's year instead of the artist's name, with Single on singles.
- The Library no longer shows its counts of songs, albums and artists above All.
- Opening an artist from one of their albums, when you came to the album from that artist, goes back to their page instead of opening it a second time, and the same the other way round.
- An album or playlist page keeps its cover and buttons in sight while they scroll away, instead of leaving an empty band under the bar.

### Fixed

- With a large font, the Library's row of artists cut their names short.

## [1.4.0] - 2026-11-04

### Changed

- Pages draw edge to edge: lists scroll under the status bar and the floating tab bar, on every Android version, and fade out under the tab bar instead of stopping on a line.
- Every page opens on a large title (Home, Library, Playlists, Settings, the privacy policy, Your week in music) that shrinks into a glass bar as you scroll, with the back button and the page's actions. A title left halfway settles open or closed.
- Album and playlist pages scroll their cover and buttons away under the same glass bar, which then shows their name.
- An artist with a photo opens on it, edge to edge, with their name over it; pulling down enlarges it.
- The search field stays pinned at the top in a glass bar while the results scroll under it, and scrolling the results closes the keyboard.
- Tapping the tab you are on scrolls its page back to the top.

## [1.3.0] - 2026-11-03

### Added

- Songs that credit several artists ("Nicki Minaj, Beyoncé", "Chiké feat Mohbad") count for each of them: every artist's page lists the songs they are featured on, and shows their albums apart from the ones they only appear on, in a new Appears on section, and their singles in a Singles section of their own. Search finds each artist of a collaboration. A name that holds a comma, such as "Tyler, The Creator", stays one artist, and "&" never separates names.

### Changed

- An artist page starts with five songs, their most played first (Popular), and See all shows the rest; their albums come within reach right after. Without plays yet, the songs are by title.
- An artist's album count, on their page, in the Artists list and in search, counts their own albums only, not their singles nor the ones they appear on. An artist with singles only shows their singles count, and one only ever featured shows none.
- Album cards of singles read Single instead of a song count. An album named after one of its at most three songs counts as a single.
- The Artists list no longer shows each collaboration as an artist of its own, nor artists only ever credited as guests. Their pages still open from search.
- Your week in music counts a collaboration for each of its artists when it picks the top artist.
- A rescan picks up files whose tags were edited since they were first found.
- Album pages show the album's year and, as the only format badge, Lossless when every song is; MP3 and other formats stay in About. More by the artist comes right after the songs.
- Songs of an album without track numbers, as downloaders save them, come in the order they were downloaded, numbered by place, instead of by title with a dash. A song with a guest its title does not name, or any song of a compilation, shows its artists under its title.
- Artist photos and bios turned on in Settings are downloaded again once, as artists are now identified by name.
- Artist and album pages show About only when Last.fm has a bio or a review, with the listeners and up to three genres under it, and where it comes from. Most artists have none: their page no longer shows an About card of counts and tags. The play count, the On tour badge and the date the review was written are gone.
- Similar artists show in their own section, Also in your library, and only the ones in your library: a tap opens their page. They were names in the About card that opened nothing, most of them not in the library.
- Now Playing no longer shows a drag handle above the cover.

### Fixed

- The year of songs and albums was never read, so album pages showed none.
- Album pages had two sections titled About this album: the one about the files now reads In your library, as on artist pages.
- An album downloaded in several folders, or a playlist of singles saved one folder per song, showed up as several copies of the same album. They are one album again; compilations stay whole.
- An album with a featured artist on some of its songs showed "Unknown artist" instead of its artist.
- A single an artist is only featured on, such as "Medusa (feat. Khaid)", counted as one of their albums, and its page named the guest as its artist too.
- An artist's page could merge two of their albums that share a name, and an album page hid the artist's other albums of the same name from "More by".

## [1.2.0] - 2026-10-31

### Added

- Songs downloaded without an artist tag take their artist from a file name such as "Artist - Title", and appear under that artist next to its tagged songs. Backups made earlier still find them.
- Starting another album or playlist while songs added with Play next or Add to queue are still to come shows "Queue replaced" with Undo, which brings the previous queue back where it was. Another song of the album or playlist that is playing plays within the current queue, and keeps them.

### Changed

- Menus (song, album, artist and playlist actions, sort, sleep timer, playback speed) open as a sheet in Troona's style, with icons for song, album, artist and playlist actions and a check on the current sort and speed, instead of the iOS-style menu. They close with a tap outside, a swipe down or back.
- Dialogs (confirmations, playlist names) match the app and fade in smoothly.
- Add to playlist opens above the mini player, and its height follows the number of playlists.
- The labels on album, artist and playlist pages and in search share one style.
- Buttons share one style in two sizes. See all, Shuffle all and the action in messages are easier to tap.
- Settings, the privacy policy and Your week in music have the same back button as album, artist and playlist pages.
- The options button on song rows is easier to tap and screen readers announce it.
- Icons share one style across the app, including the Now Playing controls, with a thinner stroke.
- Songs, albums and artists without a cover show the same placeholder everywhere, also when a cover file can no longer be read.

### Fixed

- Opening Settings, the privacy policy or Your week in music showed the previous page through the new one while it slid in, then made it vanish at once.
- Songs without an artist showed "<unknown>": they now read "Unknown artist" in the app's language and come after the named artists.
- On an album page without a cover, the record behind the sleeve showed through it.

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

[Unreleased]: https://github.com/donfreddy/troona-music/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/donfreddy/troona-music/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/donfreddy/troona-music/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/donfreddy/troona-music/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/donfreddy/troona-music/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/donfreddy/troona-music/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/donfreddy/troona-music/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/donfreddy/troona-music/releases/tag/v1.0.0
