// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Troona';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClose => 'Close';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionShuffle => 'Shuffle';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: 'No albums',
    );
    return '$_temp0';
  }

  @override
  String artistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artists',
      one: '1 artist',
      zero: 'No artists',
    );
    return '$_temp0';
  }

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get likedSongs => 'Liked songs';

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSearch => 'Search';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPlayback => 'Playback';

  @override
  String get settingsDuck => 'Lower volume for notifications';

  @override
  String get settingsPauseOnCall => 'Pause during calls';

  @override
  String get settingsResumeAfterCall => 'Resume after calls';

  @override
  String get settingsLibrary => 'Library';

  @override
  String get settingsRescan => 'Rescan library';

  @override
  String get settingsRescanSubtitle => 'Find songs added since the last scan';

  @override
  String get settingsRescanning => 'Updating your library…';

  @override
  String get settingsCoversClear => 'Clear cover cache';

  @override
  String get settingsCoversClearSubtitle => 'Covers are rebuilt automatically.';

  @override
  String get settingsCoversConfirmTitle => 'Clear cover cache?';

  @override
  String get settingsCoversConfirmBody =>
      'Covers reload in the background. Your music, likes and playlists aren\'t affected.';

  @override
  String get settingsCoversCleared => 'Cover cache cleared';

  @override
  String get settingsOnline => 'Online extras';

  @override
  String get settingsOnlineFooter =>
      'Optional. Bios and photos send artist and album names to Last.fm and Deezer. The update check asks GitHub for Troona\'s latest version. Your music files never leave this device.';

  @override
  String get settingsOnlineBios => 'Artist bios and album notes';

  @override
  String get settingsOnlinePhotos => 'Artist photos and album covers';

  @override
  String get settingsOnlineClear => 'Clear downloaded info';

  @override
  String get settingsOnlineConfirmTitle => 'Clear downloaded info?';

  @override
  String get settingsOnlineConfirmBody =>
      'Bios, album notes and photos will download again when you open an artist or an album, if they are still turned on.';

  @override
  String get settingsOnlineCleared => 'Downloaded info cleared';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsGlass => 'Glass effects';

  @override
  String get settingsGlassAuto => 'Auto';

  @override
  String get settingsGlassFull => 'Full';

  @override
  String get settingsGlassLight => 'Light';

  @override
  String get settingsGlassOff => 'Off';

  @override
  String get settingsGlassFooter =>
      'Auto adapts to your phone. Choose Light or Off for smoother scrolling on older devices.';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsSupport => 'Help and feedback';

  @override
  String get settingsReport => 'Report a problem';

  @override
  String get settingsReportSubtitle =>
      'Shares device info and recent errors. You can read it before sending.';

  @override
  String get settingsReportSubject => 'Troona problem report';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsForgetQueue => 'Clear queue and position';

  @override
  String get settingsForgetQueueConfirmTitle => 'Clear queue and position?';

  @override
  String get settingsForgetQueueConfirmBody =>
      'Playback stops and Troona forgets where you were.';

  @override
  String get settingsForgetQueueDone => 'Queue cleared';

  @override
  String get settingsResetSettings => 'Reset settings';

  @override
  String get settingsResetConfirmTitle => 'Reset settings?';

  @override
  String get settingsResetConfirmBody =>
      'All preferences go back to their defaults. Your library, likes and playlists stay as they are.';

  @override
  String settingsVersion(String version, String build) {
    return 'Troona $version ($build)';
  }

  @override
  String get settingsTagline => 'Made for the music you own.';

  @override
  String get settingsLoadError => 'We couldn\'t load your settings.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyIntro =>
      'Troona plays the music stored on your phone. It has no account, no ads and no analytics.';

  @override
  String get privacyLocalTitle => 'On this device';

  @override
  String get privacyLocalBody =>
      'Your library, likes, playlists and listening history are stored only on this phone. Troona reads your audio files and never your photos, videos or documents.';

  @override
  String get privacyOnlineTitle => 'Online extras (off by default)';

  @override
  String get privacyOnlineBody =>
      'There are two separate switches. Bios sends artist and album names to Last.fm. Photos sends them to Deezer, and downloads pictures from Deezer or Last.fm. These services also see your IP address, as with any web request. No file, account or listening history is sent. Turn either switch off at any time in Settings: requests to that service stop, and turning photos off also deletes the photos already downloaded.';

  @override
  String get privacyReportsTitle => 'Problem reports';

  @override
  String get privacyReportsBody =>
      'Errors are written to a log on this device. It can contain file names. Nothing is sent unless you choose Report a problem and share it yourself.';

  @override
  String get privacyBackupTitle => 'Backups';

  @override
  String get privacyBackupBody =>
      'Exporting a backup writes your playlists, likes, listening history and settings, with the names and sizes of your music files, to a file, unencrypted, and hands it to the app you choose. It goes nowhere else. Restoring reads only the file you pick.';

  @override
  String get privacyDeleteTitle => 'Deleting your data';

  @override
  String get privacyDeleteBody =>
      'Uninstalling Troona deletes everything it stored. Your music files, and backups you exported, are never touched.';

  @override
  String get permissionHeadline => 'All your music.\nNothing in the way.';

  @override
  String get permissionSubhead =>
      'Troona plays the songs already on your phone. No account, no ads, no streaming.';

  @override
  String get permissionQualityTitle => 'Plays what you own';

  @override
  String get permissionQualityBody =>
      'MP3, FLAC, AAC, WAV, OGG and Opus, at their original quality.';

  @override
  String get permissionPrivacyTitle => 'Private by design';

  @override
  String get permissionPrivacyBody =>
      'Your music stays on this device. Online extras are optional.';

  @override
  String get permissionLibraryTitle => 'Ready in seconds';

  @override
  String get permissionLibraryBody =>
      'Covers, albums and artists, sorted for you.';

  @override
  String get permissionAllow => 'Allow access';

  @override
  String get permissionDeniedTitle => 'Troona can\'t see your music yet';

  @override
  String get permissionDeniedBody =>
      'Troona needs access to your audio files to build your library. It never reads your photos, videos or documents.';

  @override
  String get permissionBlockedTitle => 'Access is turned off';

  @override
  String get permissionBlockedBody =>
      'Allow Troona to access your music in your phone\'s settings, then come back. We\'ll take it from there.';

  @override
  String get permissionOpenSettings => 'Open settings';

  @override
  String get permissionCheckAgain => 'I turned it on';

  @override
  String get permissionFooter => 'Free • No ads • No account';

  @override
  String get scanTitle => 'Finding your music';

  @override
  String get scanPhaseScanning => 'Looking for songs on your phone…';

  @override
  String get scanPhaseIndexing => 'Building your library…';

  @override
  String get scanPhaseArtwork => 'Adding album covers…';

  @override
  String get scanPhaseDone => 'Almost ready…';

  @override
  String scanSongsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs found',
      one: '1 song found',
    );
    return '$_temp0';
  }

  @override
  String scanProgress(int count, int total) {
    return '$count of $total';
  }

  @override
  String scanNewSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new songs added',
      one: '1 new song added',
    );
    return '$_temp0';
  }

  @override
  String scanRemovedSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs are no longer on your phone',
      one: '1 song is no longer on your phone',
    );
    return '$_temp0';
  }

  @override
  String get libraryRescanFailed =>
      'Couldn\'t check for new music. Your library is as it was.';

  @override
  String get libraryLoadErrorTitle => 'We couldn\'t open your library';

  @override
  String get libraryLoadErrorBody =>
      'Check that Troona can still access your music, then try again.';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String playerCantPlay(String title) {
    return 'Can\'t play \"$title\". Skipping to the next song.';
  }

  @override
  String get playerCantPlayUnknown =>
      'This song can\'t be played. Skipping to the next one.';

  @override
  String get notificationChannelName => 'Playback controls';

  @override
  String get bootTitle => 'Troona couldn\'t start';

  @override
  String get bootBody =>
      'Restart the app. If it keeps happening, copy the report and send it to us.';

  @override
  String get bootCopyReport => 'Copy report';

  @override
  String get bootReportCopied => 'Report copied';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterSongs => 'Songs';

  @override
  String get libraryFilterAlbums => 'Albums';

  @override
  String get libraryFilterArtists => 'Artists';

  @override
  String get libraryEmptyTitle => 'No music on this device yet';

  @override
  String get libraryEmptyBody => 'Copy songs to your phone, then scan again.';

  @override
  String get libraryScanAgain => 'Scan again';

  @override
  String get libraryNoSongs => 'No songs yet';

  @override
  String get libraryNoAlbums => 'No albums yet';

  @override
  String get libraryNoArtists => 'No artists yet';

  @override
  String get librarySort => 'Sort';

  @override
  String get librarySortBy => 'Sort by';

  @override
  String get librarySortTitle => 'Title';

  @override
  String get librarySortArtist => 'Artist';

  @override
  String get librarySortAlbum => 'Album';

  @override
  String get librarySortRecent => 'Recently added';

  @override
  String get libraryUpdating => 'Updating your library…';

  @override
  String get libraryShuffleAll => 'Shuffle all';

  @override
  String albumByArtist(String artist, String songs) {
    return '$artist • $songs';
  }

  @override
  String statSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'songs',
      one: 'song',
    );
    return '$_temp0';
  }

  @override
  String statAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'albums',
      one: 'album',
    );
    return '$_temp0';
  }

  @override
  String statArtists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'artists',
      one: 'artist',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours hr';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get trackPlayNext => 'Play next';

  @override
  String get trackAddToQueue => 'Add to queue';

  @override
  String get detailSongs => 'Songs';

  @override
  String get detailAlbums => 'Albums';

  @override
  String detailMoreBy(String artist) {
    return 'More by $artist';
  }

  @override
  String get detailMore => 'More options';

  @override
  String get detailBack => 'Back';

  @override
  String detailCountsSummary(String songs, String albums) {
    return '$songs • $albums';
  }

  @override
  String get albumAbout => 'About this album';

  @override
  String get artistInLibrary => 'In your library';

  @override
  String get infoSongs => 'Songs';

  @override
  String get infoAlbums => 'Albums';

  @override
  String get infoLength => 'Length';

  @override
  String get infoYear => 'Year';

  @override
  String get infoSize => 'Size';

  @override
  String get infoFormat => 'Format';

  @override
  String get formatLossless => 'Lossless';

  @override
  String get albumLoadError => 'We couldn\'t open this album.';

  @override
  String get artistLoadError => 'We couldn\'t open this artist.';

  @override
  String metaListeners(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString listeners',
      one: '1 listener',
    );
    return '$_temp0';
  }

  @override
  String metaPlays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Songs, artists, albums';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchIdleTitle => 'Search your library';

  @override
  String get searchIdleBody => 'Songs, artists and albums on this device.';

  @override
  String searchNoResultsTitle(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchNoResultsBody => 'Try a shorter word or an artist name.';

  @override
  String get searchError => 'Search isn\'t available right now.';

  @override
  String get searchSuggestedArtists => 'Artists';

  @override
  String get searchSuggestedAlbums => 'Albums';

  @override
  String get searchRecentlyAdded => 'Recently added';

  @override
  String get searchBadgeArtist => 'Artist';

  @override
  String get searchBadgeAlbum => 'Album';

  @override
  String get searchBadgeSong => 'Song';

  @override
  String get playlistsCreate => 'New';

  @override
  String get playlistsListView => 'List view';

  @override
  String get playlistsGridView => 'Grid view';

  @override
  String get playlistsYours => 'Your playlists';

  @override
  String get playlistsEmptyTitle => 'Make your first playlist';

  @override
  String get playlistsEmptyBody =>
      'Group songs for a mood, a moment or a road trip.';

  @override
  String get playlistNew => 'New playlist';

  @override
  String get playlistEdit => 'Edit playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get playlistAddCover => 'Add a cover';

  @override
  String get playlistCreateAndAdd => 'Create and add';

  @override
  String get playlistCreate => 'Create';

  @override
  String get playlistAddTo => 'Add to playlist';

  @override
  String get playlistNoneYet => 'No playlists yet';

  @override
  String playlistAddedTo(String name) {
    return 'Added to $name';
  }

  @override
  String playlistAlreadyIn(String name) {
    return 'Already in $name';
  }

  @override
  String playlistDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get playlistDeleteBody =>
      'This removes the playlist only. The songs stay in your library.';

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get playlistEmptyTitle => 'This playlist is empty';

  @override
  String get playlistEmptyBody => 'Add songs from the ··· menu on any song.';

  @override
  String get playlistRemove => 'Remove from playlist';

  @override
  String get playlistLoadError => 'We couldn\'t load your playlists.';

  @override
  String get playlistOpenError => 'We couldn\'t open this playlist.';

  @override
  String get likesEmptyTitle => 'Songs you like will live here';

  @override
  String get likesEmptyBody => 'Tap the heart on any song to save it.';

  @override
  String likesSubtitle(String songs) {
    return '$songs • Your favorites in one place';
  }

  @override
  String get likesBadge => 'Favorites';

  @override
  String get likesRemove => 'Remove from Liked songs';

  @override
  String get trackLike => 'Like';

  @override
  String get trackAddToPlaylist => 'Add to playlist…';

  @override
  String get trackGoToAlbum => 'Go to album';

  @override
  String get trackGoToArtist => 'Go to artist';

  @override
  String get toastPlaysNext => 'Plays next';

  @override
  String get toastAddedToQueue => 'Added to queue';

  @override
  String get toastLiked => 'Added to Liked songs';

  @override
  String get toastUnliked => 'Removed from Liked songs';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeGreetingNight => 'Late-night session';

  @override
  String get homeSubtitleWarm => 'Pick up where you left off.';

  @override
  String homeSongsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs, ready when you are.',
      one: '1 song, ready when you are.',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyTitle => 'No music here yet';

  @override
  String get homeEmptyBody =>
      'Copy songs to your phone\'s Music folder, then scan again.';

  @override
  String get homeFreshTitle => 'Your library is ready';

  @override
  String get homeJumpBackIn => 'Jump back in';

  @override
  String get homeQuickRecent => 'Recently added';

  @override
  String get homeRecentlyPlayed => 'Recently played';

  @override
  String get homeOnRepeat => 'On repeat this week';

  @override
  String get homeRediscover => 'Rediscover';

  @override
  String get homeYourArtists => 'Your artists';

  @override
  String get homeRecentlyAdded => 'Recently added';

  @override
  String get homeYourPlaylists => 'Your playlists';

  @override
  String homeWeeklyPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'plays this week',
      one: 'play this week',
    );
    return '$_temp0';
  }

  @override
  String get homeLoadError =>
      'We couldn\'t load your home. Pull down to try again.';

  @override
  String get homeExtrasTitle => 'Add artist photos and bios?';

  @override
  String get homeExtrasBody =>
      'Troona can fetch them from Last.fm and Deezer using artist and album names. Your music files stay on this device.';

  @override
  String get homeExtrasAccept => 'Turn on';

  @override
  String get homeExtrasDecline => 'Not now';

  @override
  String get homeExtrasDeclined => 'You can turn them on anytime in Settings.';

  @override
  String get recapTitle => 'Your week in music';

  @override
  String recapRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String get recapOpen => 'Open your week in music';

  @override
  String get recapListened => 'listened';

  @override
  String get recapTopArtist => 'Top artist';

  @override
  String get recapTopSong => 'Top song';

  @override
  String get recapDiscoveries => 'First listens';

  @override
  String recapDiscoveriesValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs heard for the first time',
      one: '1 song heard for the first time',
      zero: 'No new songs this week',
    );
    return '$_temp0';
  }

  @override
  String recapPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String recapHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String recapMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get recapEmpty => 'Nothing was played last week.';

  @override
  String get recapCalendarCaption => 'A filled dot is a day with music.';

  @override
  String recapCalendarDay(String date) {
    return '$date, music played';
  }

  @override
  String replayName(String month) {
    return 'Replay $month';
  }

  @override
  String replayReady(String name) {
    return '$name is in your playlists: last month\'s most played songs.';
  }

  @override
  String recapCalendarQuietDay(String date) {
    return '$date, no music';
  }

  @override
  String get queueTitle => 'Queue';

  @override
  String get queueHistory => 'History';

  @override
  String get queueBackToNow => 'Back to now playing';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueRepeatOne => 'Repeating this song';

  @override
  String get queueRepeatAll => 'Then back to the start';

  @override
  String get queueNothingNext => 'Nothing up next';

  @override
  String queueUpNext(int count) {
    return 'Up next • $count';
  }

  @override
  String queueRemoved(String title) {
    return 'Removed \"$title\"';
  }

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String sleepStopsAt(String time) {
    return 'Music stops at $time.';
  }

  @override
  String get sleepStopsEndOfSong => 'Music stops at the end of this song.';

  @override
  String get sleepIdle => 'Stop the music after a while.';

  @override
  String get sleepOneHour => '1 hour';

  @override
  String get sleepEndOfSong => 'End of song';

  @override
  String get sleepTurnOff => 'Turn off';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String playbackSpeedNormal(String speed) {
    return '$speed (normal)';
  }

  @override
  String get playbackPosition => 'Playback position';

  @override
  String playbackPositionValue(String position, String duration) {
    return '$position of $duration';
  }

  @override
  String get metaAboutAlbum => 'About this album';

  @override
  String get metaAboutArtist => 'About';

  @override
  String get metaOnTour => 'On tour';

  @override
  String get metaReadMore => 'Read more';

  @override
  String get metaReadLess => 'Show less';

  @override
  String get metaSimilarArtists => 'Similar artists';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get playerRepeatOff => 'Repeat off';

  @override
  String get playerRepeatAll => 'Repeat all';

  @override
  String get playerRepeatOne => 'Repeat this song';

  @override
  String get playerClose => 'Close player';

  @override
  String get playerOpen => 'Open player';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String whatsNewVersion(String version) {
    return 'Version $version';
  }

  @override
  String get whatsNewAdded => 'New';

  @override
  String get whatsNewImproved => 'Improved';

  @override
  String get whatsNewFixed => 'Fixed';

  @override
  String get whatsNewContinue => 'Continue';

  @override
  String get whatsNew100WeekTitle => 'Your week in music';

  @override
  String get whatsNew100WeekBody =>
      'Every Monday on Home: listening time, top artist and top song, with a calendar of the days you listened.';

  @override
  String get whatsNew100ReplayTitle => 'Monthly Replay';

  @override
  String get whatsNew100ReplayBody =>
      'At the start of each month, your 25 most played songs of the month before become a playlist.';

  @override
  String get whatsNew100SleepTitle => 'Sleep timer and speed';

  @override
  String get whatsNew100SleepBody =>
      'Stop the music after 15, 30 or 45 minutes, an hour or at the end of the song, and play from 0.75x to 2x.';

  @override
  String get whatsNew100QueueTitle => 'Queue';

  @override
  String get whatsNew100QueueBody =>
      'See what played and what comes next. Drag to reorder, swipe to remove, undo in one tap.';

  @override
  String get whatsNew100ExtrasTitle => 'Artist photos and bios, your call';

  @override
  String get whatsNew100ExtrasBody =>
      'Two switches in Settings, off by default. Your music files never leave your phone.';

  @override
  String get whatsNew100LibraryTitle => 'Your library, offline';

  @override
  String get whatsNew100LibraryBody =>
      'Songs, albums and artists from your phone, with search across all three. Scans show their progress live.';

  @override
  String get whatsNew100PlayerTitle => 'Now Playing';

  @override
  String get whatsNew100PlayerBody =>
      'Swipe between covers, seek on the ring, and enjoy soft fades on play, pause and skip.';

  @override
  String get whatsNew100PlaylistsTitle => 'Playlists and likes';

  @override
  String get whatsNew100PlaylistsBody =>
      'Create playlists, reorder their songs, and find every song you like in one place.';

  @override
  String get whatsNew100LanguageTitle => 'English and French';

  @override
  String get whatsNew100LanguageBody =>
      'The whole app follows your phone\'s language.';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsBackupFooter =>
      'The file holds your playlists, likes, listening history and settings, with the names and sizes of your music files, unencrypted. Keep it somewhere private.';

  @override
  String get backupExport => 'Export a backup';

  @override
  String get backupExportSubtitle => 'Save it to Files, Drive or another app.';

  @override
  String get backupShareSubject => 'Troona backup';

  @override
  String get backupRestore => 'Restore a backup';

  @override
  String get backupRestoreSubtitle =>
      'Adds its playlists, likes and history to yours.';

  @override
  String get backupRestoreConfirmTitle => 'Restore a backup?';

  @override
  String get backupRestoreConfirmBody =>
      'Its playlists, likes and listening history are added to yours. Its settings replace yours, except online extras.';

  @override
  String get backupRestoreAction => 'Choose file';

  @override
  String get backupRestoreInvalid =>
      'This file is not a Troona backup, or it is damaged.';

  @override
  String get backupRestoreTooNew =>
      'This backup comes from a newer version of Troona. Update the app, then try again.';

  @override
  String get backupRestoreDoneTitle => 'Backup restored';

  @override
  String backupRestoreFound(int found, int total) {
    return 'Songs found on this phone: $found of $total.';
  }

  @override
  String backupRestoreMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count songs are not on this phone. Add them, then restore the same file again to link them.',
      one:
          '1 song is not on this phone. Add it, then restore the same file again to link it.',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreMore(int count) {
    return 'and $count more';
  }

  @override
  String get backupRestoreOnline =>
      'Online extras were on in this backup. They stay as they are on this phone: turn them on above if you want them.';

  @override
  String get settingsUpdateCheck => 'Check for updates';

  @override
  String get settingsUpdateCheckSubtitle => 'Once a day, on GitHub';

  @override
  String get updateCheckNow => 'Check for updates now';

  @override
  String get updateUpToDate => 'Troona is up to date';

  @override
  String get updateCheckFailed =>
      'Couldn\'t check for updates. Try again later.';

  @override
  String updateAvailable(String version) {
    return 'Troona $version is available';
  }

  @override
  String get updateAvailableBody =>
      'Download it from its release page on GitHub.';

  @override
  String get updateView => 'View';

  @override
  String get updateSkip => 'Skip this version';

  @override
  String get updateOpenFailed => 'Couldn\'t open the browser';

  @override
  String get privacyUpdatesTitle => 'Update check (off by default)';

  @override
  String get privacyUpdatesBody =>
      'When on, Troona asks GitHub once a day for the number of its latest version. \"Check for updates now\" asks once, only when you tap it. GitHub sees your IP address, as with any web request; no data about you or your music is sent. Troona never downloads or installs an update itself: \"View\" opens the release page in your browser.';

  @override
  String get whatsNew110BackupTitle => 'Backup and restore';

  @override
  String get whatsNew110BackupBody =>
      'Save your playlists, likes, listening history and settings to a file, and bring them back on this phone or a new one. In Settings, under Backup.';

  @override
  String get whatsNew110UpdatesTitle => 'Know when Troona updates';

  @override
  String get whatsNew110UpdatesBody =>
      'Turn on Check for updates in Settings: a card on Home tells you when a new version is out. Off by default, nothing is installed for you.';

  @override
  String get whatsNew110ControlsTitle => 'Like and resume from the lock screen';

  @override
  String get whatsNew110ControlsBody =>
      'A heart in the media notification likes the current song (Android 13 and later). After Troona is closed, the media controls resume your last song (Android 11 and later).';

  @override
  String get whatsNew110RenameTitle => 'Rename a playlist';

  @override
  String get whatsNew110RenameBody =>
      'Long press a playlist, then Edit playlist.';

  @override
  String get whatsNew110ScreensTitle => 'Small screens and large fonts';

  @override
  String get whatsNew110ScreensBody =>
      'Now Playing keeps its controls on screen on smaller phones, and the whole app follows your phone\'s font size.';

  @override
  String get whatsNew110NotificationTitle => 'Notification icon';

  @override
  String get whatsNew110NotificationBody =>
      'The playback notification shows the Troona note in the status bar.';
}
