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
  String singleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count singles',
      one: '1 single',
    );
    return '$_temp0';
  }

  @override
  String get albumSingle => 'Single';

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
  String get settingsOnlineBios => 'Artist bios and album notes';

  @override
  String get settingsOnlinePhotos => 'Artist photos and album covers';

  @override
  String get settingsOnlineClear => 'Clear downloaded info';

  @override
  String get settingsOnlineConfirmTitle => 'Clear downloaded info?';

  @override
  String get settingsOnlineConfirmBody =>
      'Bios, album notes, photos and lyrics found online will download again when you open them, if they are still turned on. Imported lyrics are kept.';

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
  String get settingsGlassBalanced => 'Balanced';

  @override
  String get settingsGlassOff => 'No blur';

  @override
  String settingsGlassFooter(String tier) {
    return 'Auto: $tier on this phone. Balanced keeps the blur in page headers only, No blur draws none: both scroll more smoothly on older phones.';
  }

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
      'There are two separate switches. Bios sends artist and album names to Last.fm. Photos sends them to Deezer, with up to three titles of each artist\'s songs (their most played) so that the photo found is of that artist and not a namesake, and downloads pictures from Deezer or Last.fm. These services also see your IP address, as with any web request. No file, account or play count is sent. Turn either switch off at any time in Settings: requests to that service stop, and turning photos off also deletes the photos already downloaded.';

  @override
  String get privacyReportsTitle => 'Problem reports';

  @override
  String get privacyReportsBody =>
      'Errors are written to a log on this device. It can contain file names. Nothing is sent unless you choose Report a problem and share it yourself.';

  @override
  String get privacyBackupTitle => 'Backups';

  @override
  String get privacyBackupBody =>
      'A backup holds the parts you choose (playlists, likes, listening history, imported lyrics and their timing, settings, equalizer), with the names and sizes of your music files, unencrypted. Troona writes it to the folder you picked for backups, or hands it to the app you choose when you share it. It goes nowhere else. Restoring reads only the backup you pick, and writes only the parts you keep.';

  @override
  String get privacyDeleteTitle => 'Deleting your data';

  @override
  String get privacyDeleteBody =>
      'Uninstalling Troona deletes everything it stored. Your music files, and backups in your backup folder or exported, are never touched.';

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
  String get openedFileNotInLibrary =>
      'This file isn\'t in your library. For now, Troona only opens songs from your music.';

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
  String get playerQueueReplaced => 'Queue replaced';

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
  String get libraryIndex => 'Alphabetical index';

  @override
  String libraryIndexJump(String letter) {
    return 'Go to $letter';
  }

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
  String get librarySortPlays => 'Most played';

  @override
  String get libraryUpdating => 'Updating your library…';

  @override
  String get libraryShuffleAll => 'Shuffle all';

  @override
  String albumByArtist(String artist, String songs) {
    return '$artist • $songs';
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
  String get detailSingles => 'Singles';

  @override
  String get detailDiscography => 'Discography';

  @override
  String get detailLatestRelease => 'Latest release';

  @override
  String get detailAppearsOn => 'Appears on';

  @override
  String get detailAlsoInLibrary => 'Also in your library';

  @override
  String get detailPopular => 'Popular';

  @override
  String detailSeeAllSongs(int count) {
    return 'See all $count songs';
  }

  @override
  String get detailShowLess => 'Show less';

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
  String get recentlyAddedTitle => 'Recently added';

  @override
  String get recentlyAddedEmptyTitle => 'Nothing added yet';

  @override
  String get recentlyAddedEmptyBody =>
      'Songs you add to your phone show here, newest first.';

  @override
  String get recentAlbumsTitle => 'Recent albums';

  @override
  String get recentAlbumsEmptyBody =>
      'Albums you add to your phone show here, newest first.';

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
  String get homeNowPlaying => 'Now playing';

  @override
  String get queueOriginAlbum => 'Album';

  @override
  String get queueOriginArtist => 'Artist';

  @override
  String get queueOriginPlaylist => 'Playlist';

  @override
  String homeTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get homeQuickRecent => 'Recently added';

  @override
  String get homeRecentlyPlayed => 'Recently played';

  @override
  String get homeOnRepeat => 'On repeat this week';

  @override
  String get homeRediscover => 'Rediscover';

  @override
  String get homeRecentlyAdded => 'Recently added';

  @override
  String homeWeeklyPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays this week',
      one: '1 play this week',
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
      'Troona can fetch them from Last.fm and Deezer using artist and album names, and a few song titles for photos. Your music files stay on this device.';

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
      zero: 'No new songs',
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
  String get recapPageTitle => 'Your listening';

  @override
  String get recapWeek => 'Week';

  @override
  String get recapMonth => 'Month';

  @override
  String get recapThisWeek => 'This week';

  @override
  String get recapLastWeek => 'Last week';

  @override
  String get recapThisMonth => 'This month';

  @override
  String get recapLastMonth => 'Last month';

  @override
  String get recapPreviousSpan => 'Earlier';

  @override
  String get recapNextSpan => 'Later';

  @override
  String get recapInProgress => 'In progress';

  @override
  String recapActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days with music',
      one: '1 day with music',
    );
    return '$_temp0';
  }

  @override
  String get recapNothingYet => 'Nothing played yet.';

  @override
  String get recapNothing => 'Nothing was played.';

  @override
  String get recapTopSongs => 'Top songs';

  @override
  String get recapPlaysHeader => 'Plays';

  @override
  String get recapShare => 'Share';

  @override
  String get recapStoryWeek => 'My week in music';

  @override
  String get recapStoryMonth => 'My month in music';

  @override
  String get recapTopAlbums => 'Top albums';

  @override
  String get recapDayByDay => 'Day by day';

  @override
  String get recapLess => 'Less';

  @override
  String get recapMore => 'More';

  @override
  String recapDayPlays(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
      zero: 'no music',
    );
    return '$date, $_temp0';
  }

  @override
  String recapBusiestDay(String date, String plays) {
    return 'Busiest day: $date, $plays';
  }

  @override
  String get recapMoments => 'When you listen';

  @override
  String get recapMomentsEmpty =>
      'Your listening moments show up as you play music.';

  @override
  String recapPeak(String weekday, String part) {
    return 'Peak: $weekday $part';
  }

  @override
  String recapPeakNight(String eve, String day) {
    return 'Peak: $eve night';
  }

  @override
  String get recapMorning => 'Morning';

  @override
  String get recapAfternoon => 'Afternoon';

  @override
  String get recapEvening => 'Evening';

  @override
  String get recapNight => 'Night';

  @override
  String replayName(String month) {
    return 'Replay $month';
  }

  @override
  String replayReady(String name) {
    return '$name is in your playlists: last month\'s most played songs.';
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
  String get metaAbout => 'About';

  @override
  String metaSource(String source) {
    return 'From $source';
  }

  @override
  String get metaReadMore => 'Read more';

  @override
  String get metaReadLess => 'Show less';

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
  String get whatsNewLatest => 'Latest';

  @override
  String get whatsNewEarlier => 'Earlier releases';

  @override
  String whatsNewShowAll(int count) {
    return 'Show all $count changes';
  }

  @override
  String get whatsNewShowLess => 'Show fewer';

  @override
  String whatsNewCountAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String whatsNewCountImproved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count improvements',
      one: '1 improvement',
    );
    return '$_temp0';
  }

  @override
  String whatsNewCountFixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fixes',
      one: '1 fix',
    );
    return '$_temp0';
  }

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
  String get settingsBackupFooter =>
      'A backup holds what you choose above, with the names and sizes of your music files, unencrypted. Keep it somewhere private.';

  @override
  String get backupExportSubtitle => 'Save it to Files, Drive or another app.';

  @override
  String get backupShareSubject => 'Troona backup';

  @override
  String get backupRestore => 'Restore a backup';

  @override
  String get backupRestoreInvalid =>
      'This file is not a Troona backup, or it is damaged.';

  @override
  String get backupRestoreTooNew =>
      'This backup comes from a newer version of Troona. Update the app, then try again.';

  @override
  String get backupRestoreDoneTitle => 'Backup restored';

  @override
  String get backupRestoreDoneBody => 'Everything you chose is restored.';

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
      'Online extras were on in this backup. They stay as they are on this phone: turn them on in Settings if you want them.';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String backupSettingsLast(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backupSettingsNone => 'Playlists, likes, history and settings';

  @override
  String get backupAutoSection => 'Automatic backup';

  @override
  String get backupAuto => 'Back up automatically';

  @override
  String get backupAutoOff => 'Into a folder you choose, when you open Troona';

  @override
  String backupAutoLast(String date) {
    return 'Last one: $date';
  }

  @override
  String get backupAutoNone => 'None yet';

  @override
  String get backupFrequency => 'Frequency';

  @override
  String get backupDaily => 'Every day';

  @override
  String get backupWeekly => 'Every week';

  @override
  String get backupFolder => 'Folder';

  @override
  String get backupFolderChoose => 'Choose a folder';

  @override
  String backupFolderLost(String name) {
    return 'Can\'t reach $name. Choose it again.';
  }

  @override
  String get backupFolderFooter =>
      'Troona keeps its last 5 automatic backups there, and every backup you make. The folder stays if you uninstall Troona: choose it again after reinstalling to find your backups.';

  @override
  String get backupManualSection => 'Back up';

  @override
  String get backupParts => 'What to back up';

  @override
  String get backupPartsEverything => 'Everything';

  @override
  String get backupPartHistory => 'Listening history';

  @override
  String get backupPartSettings => 'Settings';

  @override
  String get backupPartLyrics => 'Lyrics';

  @override
  String get backupNow => 'Back up now';

  @override
  String backupNowInto(String name) {
    return 'Into $name';
  }

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get backupRestoreSection => 'Restore';

  @override
  String get backupNone => 'No backups in this folder yet';

  @override
  String get backupFromFile => 'Restore from a file';

  @override
  String get backupFromFileSubtitle =>
      'A backup saved elsewhere, or from another phone';

  @override
  String get backupAutoBadge => 'Auto';

  @override
  String get backupOptions => 'Backup options';

  @override
  String get backupShare => 'Share';

  @override
  String get backupDeleteTitle => 'Delete this backup?';

  @override
  String backupDeleteBody(String name) {
    return 'It is deleted from $name.';
  }

  @override
  String backupSummaryPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count liked songs',
      one: '1 liked song',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryLyrics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lyrics or timing for $count songs',
      one: 'Lyrics or timing for 1 song',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryProfiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Its setting and $count profiles',
      one: 'Its setting and 1 profile',
      zero: 'Its setting, no saved profile',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsReplace => 'They replace yours';

  @override
  String get backupRestoreTitle => 'Restore this backup';

  @override
  String backupRestoreFrom(String date) {
    return 'Made $date. Playlists, likes and history are added to yours; settings and the equalizer replace yours.';
  }

  @override
  String get backupRestoreButton => 'Restore';

  @override
  String get backupRestoreNothing => 'This backup holds nothing to restore.';

  @override
  String get backupFolderLostError =>
      'Can\'t reach the backup folder. Choose it again.';

  @override
  String get backupAutoFolderLost =>
      'Automatic backup can\'t reach its folder. Choose it again in Settings, Backup & restore.';

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

  @override
  String get whatsNew111ChangelogTitle => 'Every release in one place';

  @override
  String get whatsNew111ChangelogBody =>
      'What\'s new now keeps the notes of every version, the newest first. Open it any time from Settings, under Help and feedback.';

  @override
  String get whatsNew111StartupTitle => 'Reliable start';

  @override
  String get whatsNew111StartupBody =>
      'Troona no longer stays on its launch screen when you open it after resuming music from the media controls or a headset.';

  @override
  String get whatsNew111HomeTitle => 'Home right after the first scan';

  @override
  String get whatsNew111HomeBody =>
      'Your music shows on Home as soon as the first scan finds it, without refreshing.';

  @override
  String get whatsNew120ArtistsTitle => 'Artists from file names';

  @override
  String get whatsNew120ArtistsBody =>
      'Songs downloaded without an artist take it from their file name, such as \"Artist - Title\", and sit with that artist\'s other songs. The rest read Unknown artist, in your language.';

  @override
  String get whatsNew120UndoTitle => 'Undo a replaced queue';

  @override
  String get whatsNew120UndoBody =>
      'Starting another album while songs you added with Play next or Add to queue are still to come now offers Undo, which brings your queue back where it was.';

  @override
  String get whatsNew120MenusTitle => 'Menus and dialogs';

  @override
  String get whatsNew120MenusBody =>
      'Song, album and playlist menus open as a sheet in Troona\'s style, and dialogs fade in smoothly.';

  @override
  String get whatsNew120LookTitle => 'One look across the app';

  @override
  String get whatsNew120LookBody =>
      'Icons, buttons, back buttons and missing covers look the same on every screen, and buttons are easier to tap.';

  @override
  String get whatsNew120PagesTitle => 'Pages that slide in';

  @override
  String get whatsNew120PagesBody =>
      'Settings, the privacy policy and Your week in music no longer show the previous page through them while they open.';

  @override
  String get whatsNew130ArtistsTitle => 'Every artist of a song';

  @override
  String get whatsNew130ArtistsBody =>
      'A song by several artists, such as \"Nicki Minaj, Beyoncé\" or \"Chiké feat Mohbad\", now counts for each of them: it shows on every artist\'s page and search finds each one. Names such as \"Tyler, The Creator\" stay one artist.';

  @override
  String get whatsNew130ArtistPageTitle => 'Artist pages';

  @override
  String get whatsNew130ArtistPageBody =>
      'An artist\'s page starts with their five most played songs, then their albums, their singles, the albums they appear on and similar artists from your library.';

  @override
  String get whatsNew130AlbumPageTitle => 'Album pages';

  @override
  String get whatsNew130AlbumPageBody =>
      'Albums show their year, and downloaded songs without track numbers come in the order they were downloaded. Guests a title does not name show under it.';

  @override
  String get whatsNew130AboutTitle => 'About, when there is something to read';

  @override
  String get whatsNew130AboutBody =>
      'With online info turned on, About shows only when Last.fm has a bio or a review, with the listeners and a few genres under it.';

  @override
  String get whatsNew130AlbumsTitle => 'One album, not several copies';

  @override
  String get whatsNew130AlbumsBody =>
      'An album downloaded in several folders, or singles saved one folder each, showed up several times. It is one album again, and its year shows.';

  @override
  String get whatsNew140TopTitle => 'Back to the top';

  @override
  String get whatsNew140TopBody =>
      'Tap the tab you are on to scroll its page back to the top.';

  @override
  String get whatsNew140EdgeTitle => 'Edge to edge';

  @override
  String get whatsNew140EdgeBody =>
      'Lists now scroll under the status bar and the floating tab bar, on every Android version, and fade out softly under the tab bar instead of stopping on a line.';

  @override
  String get whatsNew140TitlesTitle => 'Large titles';

  @override
  String get whatsNew140TitlesBody =>
      'Every page opens on a large title that shrinks into a glass bar as you scroll, with the back button and the page\'s actions. A title left halfway settles open or closed.';

  @override
  String get whatsNew140CoversTitle => 'Album and playlist pages';

  @override
  String get whatsNew140CoversBody =>
      'Their cover and buttons scroll away under the same glass bar, which then shows their name.';

  @override
  String get whatsNew140ArtistPhotoTitle => 'Artist photos';

  @override
  String get whatsNew140ArtistPhotoBody =>
      'An artist with a photo opens on it, edge to edge, with their name over it. Pull down to enlarge it.';

  @override
  String get whatsNew140SearchTitle => 'Search';

  @override
  String get whatsNew140SearchBody =>
      'The search field stays pinned at the top in a glass bar while the results scroll under it, and scrolling the results closes the keyboard.';

  @override
  String get whatsNew150CoverTitle => 'The cover flies in';

  @override
  String get whatsNew150CoverBody =>
      'Tap an album and its cover flies from the card into place on the album page, then back when you leave.';

  @override
  String get whatsNew150TitlesTitle => 'Bold titles';

  @override
  String get whatsNew150TitlesBody =>
      'Large titles are bold, in the same voice as album and artist names and section titles.';

  @override
  String get whatsNew150TabTitle => 'A dot under the tab';

  @override
  String get whatsNew150TabBody =>
      'The tab you are on shows a dot under its icon, not only a brighter colour.';

  @override
  String get whatsNew150PagesTitle => 'One line of facts';

  @override
  String get whatsNew150PagesBody =>
      'Album pages state their year, song count and length, and artist pages their song count, releases and length, as one line of text instead of pills. Lossless keeps its badge.';

  @override
  String get whatsNew150AlbumTitle => 'Album pages';

  @override
  String get whatsNew150AlbumBody =>
      'The track list no longer has a Songs title. Under the songs, a quiet line gives the album\'s size and formats instead of the In your library card.';

  @override
  String get whatsNew150ArtistTitle => 'Artist pages';

  @override
  String get whatsNew150ArtistBody =>
      'Each song shows its album and year under its title instead of the artist\'s name again, and album and single cards give the year. The In your library card is gone: its counts are under the name.';

  @override
  String get whatsNew150MoreByTitle => 'More by';

  @override
  String get whatsNew150MoreByBody =>
      'On album pages, More by gives each album\'s year instead of the artist\'s name, with Single on singles.';

  @override
  String get whatsNew150LibraryTitle => 'A lighter Library';

  @override
  String get whatsNew150LibraryBody =>
      'The Library no longer shows its counts of songs, albums and artists above All.';

  @override
  String get whatsNew150BackTitle => 'Back where you came from';

  @override
  String get whatsNew150BackBody =>
      'Open an album\'s artist when you came from that artist, and you go back to their page instead of opening it again. The same goes the other way round.';

  @override
  String get whatsNew150ScrollTitle => 'No empty band';

  @override
  String get whatsNew150ScrollBody =>
      'An album or playlist page keeps its cover and buttons in sight while they scroll away, instead of leaving an empty band under the bar.';

  @override
  String get whatsNew150NamesTitle => 'Artist names with a large font';

  @override
  String get whatsNew150NamesBody =>
      'With a large font, the Library\'s row of artists no longer cuts their names short.';

  @override
  String get whatsNew160RecapTitle => 'Your listening';

  @override
  String get whatsNew160RecapBody =>
      'Any week or month at a glance: your listening time, the days you played music, your top songs, artist and albums. Open it from the card on Home, and step back with the arrows.';

  @override
  String get whatsNew160StoryTitle => 'Share it as a story';

  @override
  String get whatsNew160StoryBody =>
      'Turn a week or a month into an image for your stories, over your top song\'s colours. A finished month is shared as its Replay.';

  @override
  String get whatsNew160SwipeTitle => 'Swipe a song';

  @override
  String get whatsNew160SwipeBody =>
      'In the Library, albums, artists and search, swipe a song right to play it next, or left to add it to the queue.';

  @override
  String get whatsNew160MiniPlayerTitle => 'Swipe and hold the mini player';

  @override
  String get whatsNew160MiniPlayerBody =>
      'Swipe it left for the next song or right for the previous one. Hold it to like the song playing, or to take the like back.';

  @override
  String get whatsNew160CalendarTitle => 'A calendar of your listening';

  @override
  String get whatsNew160CalendarBody =>
      'Each day is a square, filled in five steps from no music to 30 plays or more. Tap a day for its count.';

  @override
  String get whatsNew160MomentsTitle => 'When you listen';

  @override
  String get whatsNew160MomentsBody =>
      'Your plays by weekday and time of day, with the moment that stands out, such as Friday evening. Songs played after midnight count for the night before.';

  @override
  String get whatsNew160RecordTitle => 'The record turns';

  @override
  String get whatsNew160RecordBody =>
      'On an album page, the record slides out of its sleeve and turns while the album plays. Tap it to play, pause or resume.';

  @override
  String get whatsNew160LatestTitle => 'Latest release';

  @override
  String get whatsNew160LatestBody =>
      'Artist pages show their newest album or single on its own, above the rest.';

  @override
  String get whatsNew160ResumeTitle => 'Pick up where you left off';

  @override
  String get whatsNew160ResumeBody =>
      'Jump back in on Home goes on from where the song stopped, with the album, artist or playlist it came from and the time left. While music plays, it opens Now Playing.';

  @override
  String get whatsNew160ArtistTitle => 'Artist pages';

  @override
  String get whatsNew160ArtistBody =>
      'One round Shuffle button on their photo, since an artist\'s songs have no order; tap a song to play in order from it. Releases come newest first, also in More by on album pages. An artist without a photo opens on a soft glow of their cover\'s colours.';

  @override
  String get whatsNew160PlayingTitle =>
      'The song playing looks the same everywhere';

  @override
  String get whatsNew160PlayingBody =>
      'In every list, its cover is dimmed under the moving equalizer, which stops while paused, and its title is in the accent colour.';

  @override
  String get whatsNew160HapticsTitle => 'One feel for haptics';

  @override
  String get whatsNew160HapticsBody =>
      'A firm tap when playback starts or stops, a light one for a skip, a refresh or a menu, and a tick for a choice. Playing a song no longer taps twice.';

  @override
  String get whatsNew160BackgroundTitle => 'A calmer background';

  @override
  String get whatsNew160BackgroundBody =>
      'The colours behind the tabs take two seconds to follow a new song instead of switching at once.';

  @override
  String get whatsNew160BackupTitle => 'Backups';

  @override
  String get whatsNew160BackupBody => 'They now also carry when you listen.';

  @override
  String get whatsNew160HapticsOffTitle => 'Vibrations with haptics off';

  @override
  String get whatsNew160HapticsOffBody =>
      'The Library\'s tabs at the top vibrated even with haptics turned off in Settings. They now follow the setting.';

  @override
  String get whatsNew170IndexTitle => 'Jump by letter';

  @override
  String get whatsNew170IndexBody =>
      'Songs, albums and artists sorted by name have an alphabetical index down the right edge.';

  @override
  String get whatsNew170RecentTitle => 'Recently added';

  @override
  String get whatsNew170RecentBody =>
      'The songs and albums added last, newest first, from Search and Home.';

  @override
  String get whatsNew170ArtistsTitle => 'Closer to the artists';

  @override
  String get whatsNew170ArtistsBody =>
      'Tap the artist\'s name in Now Playing to open their page. Their photo grows from the card into the page.';

  @override
  String get whatsNew170AlbumMenuTitle => 'Album shortcuts';

  @override
  String get whatsNew170AlbumMenuBody =>
      'Hold an album card for Play, Shuffle, Play next and Add to queue.';

  @override
  String get whatsNew170NowPlayingTitle => 'A smoother Now Playing';

  @override
  String get whatsNew170NowPlayingBody =>
      'Seeking lights up the ring, and closing sends the cover back into the mini player.';

  @override
  String get whatsNew170ColoursTitle => 'Pages in their own colours';

  @override
  String get whatsNew170ColoursBody =>
      'Album and artist pages take the colours of their cover, and open in the tab you are in.';

  @override
  String get whatsNew170HomeTitle => 'A lighter Home';

  @override
  String get whatsNew170HomeBody =>
      'Music comes first, with one card about the app at a time.';

  @override
  String get whatsNew170QueueTitle => 'Queueing with nothing playing';

  @override
  String get whatsNew170QueueBody =>
      'Play next and Add to queue now start the music when nothing plays, and an album goes into the queue whole.';

  @override
  String get whatsNew170PhotosTitle => 'Artist photos';

  @override
  String get whatsNew170PhotosBody =>
      'No more grey silhouettes or photos of namesakes, and Search shows the downloaded photos.';

  @override
  String get whatsNew180SmartTitle => 'Smart playlists';

  @override
  String get whatsNew180SmartBody =>
      'Playlists that fill themselves from rules: plays, last played, date added, likes, artist, genre, year and more. Start from a template with the + in Playlists.';

  @override
  String get whatsNew180SelectionTitle => 'Pick several songs';

  @override
  String get whatsNew180SelectionBody =>
      'Long press a song to start picking, then tap others. Play them, queue them or add them to a playlist in one go.';

  @override
  String get whatsNew180EqualizerTitle => 'Equalizer';

  @override
  String get whatsNew180EqualizerBody =>
      'On Android, from Now Playing or Settings > Playback: draw your curve with a finger or start from a preset, save it, and add up to 6 dB with Volume +.';

  @override
  String get whatsNew180OrbTitle => 'A button in the song\'s colours';

  @override
  String get whatsNew180OrbBody =>
      'The centre of the tab bar glows in the colours of the song playing. Tap it to open Now Playing, or to start music when nothing is loaded.';

  @override
  String get whatsNew180GlassTitle => 'Glass effects for every phone';

  @override
  String get whatsNew180GlassBody =>
      'Balanced keeps the blur in page headers only and No blur draws none, both with tinted surfaces: smoother scrolling on older phones. In Settings.';

  @override
  String get whatsNew180MiniPlayerTitle => 'A smoother mini player';

  @override
  String get whatsNew180MiniPlayerBody =>
      'Swipe to the next or previous song and the titles follow your finger while the cover fades. Swipe down to close it.';

  @override
  String get whatsNew180ReadableTitle => 'Easier to read';

  @override
  String get whatsNew180ReadableBody =>
      'Small grey text has more contrast, and Now Playing\'s ring reads over every cover.';

  @override
  String get whatsNew180GlassFixTitle => 'Glass settings apply at once';

  @override
  String get whatsNew180GlassFixBody =>
      'Changing the glass effects now redraws every screen right away, not only the ones opened afterwards.';

  @override
  String playlistAddedSongsTo(int count, String name) {
    return '$count songs added to $name';
  }

  @override
  String selectionSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs selected',
      one: '1 song selected',
    );
    return '$_temp0';
  }

  @override
  String selectionSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'selected',
      one: 'selected',
    );
    return '$_temp0';
  }

  @override
  String get selectionSelectAll => 'Select all';

  @override
  String get selectionDeselectAll => 'Deselect all';

  @override
  String get selectionEnd => 'End selection';

  @override
  String get selectionHintStart => 'pick songs';

  @override
  String get selectionHintPick => 'select';

  @override
  String get selectionHintUnpick => 'deselect';

  @override
  String get equalizerTitle => 'Equalizer';

  @override
  String get equalizerOff => 'Off';

  @override
  String get equalizerTurnOnHint => 'Turn the equalizer on to tune it.';

  @override
  String get equalizerNoBands =>
      'Play a song to tune the equalizer: your phone tells its bands once one is loaded.';

  @override
  String equalizerBandCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bands on this phone.',
      one: '1 band on this phone.',
    );
    return '$_temp0';
  }

  @override
  String get equalizerOtherEffects =>
      'A system equalizer, such as Dolby, may change the sound too.';

  @override
  String get equalizerPresetFlat => 'Flat';

  @override
  String get equalizerPresetBassBoost => 'Bass boost';

  @override
  String get equalizerPresetAcoustic => 'Acoustic';

  @override
  String get equalizerPresetElectronic => 'Electronic';

  @override
  String get equalizerPresetVocal => 'Vocal';

  @override
  String get equalizerPresetRock => 'Rock';

  @override
  String get equalizerPresetHipHop => 'Hip-hop';

  @override
  String get equalizerPresetJazz => 'Jazz';

  @override
  String get equalizerPresetTrebleBoost => 'Treble boost';

  @override
  String get equalizerCustom => 'Custom';

  @override
  String get equalizerSaveProfile => 'Save';

  @override
  String get equalizerSaveProfileTitle => 'Save this curve';

  @override
  String get equalizerProfileName => 'Name';

  @override
  String get equalizerProfileRename => 'Rename';

  @override
  String get equalizerProfileUpdate => 'Replace with the current curve';

  @override
  String equalizerProfileDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get equalizerProfileDeleteBody =>
      'The curve stays as it is; only its name goes.';

  @override
  String get equalizerCompare => 'Hold to hear without the equalizer';

  @override
  String get equalizerComparing => 'Without the equalizer';

  @override
  String get equalizerBoost => 'Volume +';

  @override
  String get equalizerAntiClip => 'Avoid clipping';

  @override
  String get equalizerAntiClipSubtitle =>
      'Lowers the level by as much as the bands boost.';

  @override
  String get equalizerReset => 'Reset the curve';

  @override
  String equalizerDecibels(String value) {
    return '$value dB';
  }

  @override
  String equalizerBandLabel(String frequency) {
    return '$frequency hertz';
  }

  @override
  String equalizerBandValue(String value) {
    return '$value decibels';
  }

  @override
  String playlistDefaultName(int number) {
    return 'My playlist #$number';
  }

  @override
  String get playlistsCreatePlaylist => 'Playlist';

  @override
  String get playlistsCreateSmart => 'Smart playlist';

  @override
  String get smartPlaylistKind => 'Smart playlist';

  @override
  String get smartPlaylistNew => 'New smart playlist';

  @override
  String get smartPlaylistEdit => 'Edit rules';

  @override
  String get smartBadge => 'Auto';

  @override
  String get smartStartFrom => 'Start from';

  @override
  String get smartTemplateTopMonth => 'Most played this month';

  @override
  String get smartTemplateNeverPlayed => 'Never played';

  @override
  String get smartTemplateForgotten => 'Forgotten';

  @override
  String get smartTemplateRecent => 'Recently added';

  @override
  String get smartTemplateLossless => 'Lossless';

  @override
  String get smartKeep => 'Keep songs that match';

  @override
  String get smartMatchAll => 'All rules';

  @override
  String get smartMatchAny => 'Any rule';

  @override
  String get smartRules => 'Rules';

  @override
  String get smartNoRules => 'No rules: every song is kept.';

  @override
  String get smartAddRule => 'Add a rule';

  @override
  String get smartRemoveRule => 'Remove this rule';

  @override
  String get smartSortBy => 'Sort by';

  @override
  String get smartLimit => 'Limit';

  @override
  String get smartNoLimit => 'No limit';

  @override
  String smartLimitSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String smartMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs match',
      one: '1 song matches',
      zero: 'No songs match',
    );
    return '$_temp0';
  }

  @override
  String get smartEmptyTitle => 'No songs match yet';

  @override
  String get smartEmptyBody =>
      'What you play and add may change that, or you can loosen the rules.';

  @override
  String get smartSaveAsPlaylist => 'Save as a playlist';

  @override
  String smartSavedAsPlaylist(String name) {
    return 'Saved as $name';
  }

  @override
  String get smartFootnote =>
      'The songs are worked out again each time you open it.';

  @override
  String get smartRulePlays => 'Plays';

  @override
  String get smartRuleLastPlayed => 'Last played';

  @override
  String get smartRuleAdded => 'Date added';

  @override
  String get smartRuleLiked => 'Liked';

  @override
  String get smartRuleArtist => 'Artist';

  @override
  String get smartRuleAlbum => 'Album';

  @override
  String get smartRuleGenre => 'Genre';

  @override
  String get smartRuleYear => 'Year';

  @override
  String get smartRuleDuration => 'Duration';

  @override
  String get smartRuleLossless => 'Lossless';

  @override
  String smartPlaysAtLeast(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Played at least $count times',
      one: 'Played at least once',
    );
    return '$_temp0 in $days days';
  }

  @override
  String smartPlaysNone(int days) {
    return 'Not played in $days days';
  }

  @override
  String smartLastPlayedOlder(int days) {
    return 'Last played over $days days ago';
  }

  @override
  String smartLastPlayedWithin(int days) {
    return 'Played in the last $days days';
  }

  @override
  String get smartNeverPlayed => 'Never played';

  @override
  String smartAddedWithin(int days) {
    return 'Added in the last $days days';
  }

  @override
  String get smartLikedYes => 'Liked';

  @override
  String get smartLikedNo => 'Not liked';

  @override
  String smartTextContains(String field, String text) {
    return '$field contains \"$text\"';
  }

  @override
  String smartTextNotContains(String field, String text) {
    return '$field doesn\'t contain \"$text\"';
  }

  @override
  String smartYearRange(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String smartYearFrom(String year) {
    return '$year or later';
  }

  @override
  String smartYearTo(String year) {
    return '$year or earlier';
  }

  @override
  String smartDurationUnder(int minutes) {
    return 'Under $minutes min';
  }

  @override
  String smartDurationOver(int minutes) {
    return 'Over $minutes min';
  }

  @override
  String smartDurationBetween(int min, int max) {
    return '$min to $max min';
  }

  @override
  String get smartLosslessYes => 'Lossless';

  @override
  String get smartLosslessNo => 'Not lossless';

  @override
  String get smartContains => 'Contains';

  @override
  String get smartNotContains => 'Doesn\'t contain';

  @override
  String get smartTextHint => 'Text to look for';

  @override
  String smartDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get smartOverLast => 'Over the last';

  @override
  String get smartSortTitle => 'Title';

  @override
  String get smartSortArtist => 'Artist';

  @override
  String get smartSortAlbum => 'Album';

  @override
  String get smartSortYear => 'Year, newest first';

  @override
  String get smartSortAddedNewest => 'Date added, newest first';

  @override
  String get smartSortAddedOldest => 'Date added, oldest first';

  @override
  String get smartSortMostPlayed => 'Most played';

  @override
  String get smartSortMostPlayedMonth => 'Most played, last 30 days';

  @override
  String get smartSortLeastPlayed => 'Least played';

  @override
  String get smartSortLastPlayedRecent => 'Played most recently';

  @override
  String get smartSortLastPlayedOldest => 'Played longest ago';

  @override
  String get smartSortRandom => 'Random';

  @override
  String get lyricsTitle => 'Lyrics';

  @override
  String get lyricsShow => 'Show lyrics';

  @override
  String get lyricsHide => 'Hide lyrics';

  @override
  String get lyricsNone => 'No lyrics for this song';

  @override
  String get lyricsNoneOnline => 'None found online either.';

  @override
  String get lyricsUnreachable =>
      'Couldn\'t reach the lyrics search. Try again later.';

  @override
  String get lyricsImport => 'Import a .lrc file';

  @override
  String get lyricsSearchOnline => 'Search online';

  @override
  String get lyricsSearchAgain => 'Search online again';

  @override
  String get lyricsEnableSearch => 'Turn on lyrics search';

  @override
  String get lyricsEnableTitle => 'Search lyrics online?';

  @override
  String get lyricsEnableBody =>
      'When a song has no lyrics, Troona sends its title, artist, album and length to LRCLIB, then lyrics.ovh, only when you open its lyrics. Nothing else leaves this device. You can turn this off in Settings.';

  @override
  String get lyricsEnableAction => 'Turn on';

  @override
  String get lyricsNotSynced => 'Not synced';

  @override
  String get lyricsBackToLine => 'Back to the current line';

  @override
  String lyricsGoTo(String time) {
    return 'Go to $time';
  }

  @override
  String get lyricsInstrumental => 'Instrumental';

  @override
  String get lyricsImported => 'Lyrics imported';

  @override
  String get lyricsImportInvalid => 'This file holds no lyrics.';

  @override
  String get lyricsOptions => 'Lyrics options';

  @override
  String get lyricsEarlier => 'Show lines earlier (0.1 s)';

  @override
  String get lyricsLater => 'Show lines later (0.1 s)';

  @override
  String get lyricsOffsetReset => 'Reset the timing';

  @override
  String lyricsOffsetValue(String value) {
    return 'Timing: $value s';
  }

  @override
  String get lyricsRemove => 'Remove lyrics';

  @override
  String get lyricsRemoveTitle => 'Remove these lyrics?';

  @override
  String get lyricsRemoveBody =>
      'Lyrics found online come back only if you search again. Imported lyrics would need importing again.';

  @override
  String get lyricsSourceImported => 'From an imported file';

  @override
  String get lyricsSourceOnline => 'Found online (LRCLIB or lyrics.ovh)';

  @override
  String get settingsOnlineLyrics => 'Song lyrics';

  @override
  String get privacyLyricsTitle => 'Lyrics search (off by default)';

  @override
  String get privacyLyricsBody =>
      'When on, opening the lyrics of a song that has none stored sends its title, artist, album and length to LRCLIB (lrclib.net), then, if it has none, its artist and title to lyrics.ovh. Nothing is sent for other songs, and never for your whole library. These services also see your IP address, as with any web request. Lyrics found are kept on this phone; \"Clear downloaded info\" deletes them. Lyrics you import from a file never leave this phone, except in a backup you export.';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioSummary => 'Equalizer, calls and notifications';

  @override
  String get settingsAudioIntro =>
      'How Troona sounds, and what it does when your phone needs the speaker for something else.';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsInterruptions => 'Interruptions';

  @override
  String get settingsDuckSubtitle =>
      'When a notification or a GPS voice speaks, the music gets quieter instead of pausing.';

  @override
  String get settingsPauseOnCallSubtitle =>
      'During a call, or while another app plays sound.';

  @override
  String get settingsResumeAfterCallSubtitle =>
      'Once a call or a short interruption is over.';

  @override
  String get settingsAudioFooter =>
      'Unplugging headphones always pauses the music.';

  @override
  String get settingsLibrarySummary => 'Songs on this phone, filters, rescan';

  @override
  String get settingsLibraryIntro =>
      'The songs Troona found on this phone, and what it leaves out.';

  @override
  String get settingsLibraryContents => 'In your library';

  @override
  String get settingsScan => 'Scan';

  @override
  String get settingsScanFooter =>
      'Troona reads the songs your phone lists as music. Ringtones, notifications and voice notes are always left out.';

  @override
  String get settingsOnlineOff => 'Off';

  @override
  String settingsOnlineOn(String parts) {
    return 'On: $parts';
  }

  @override
  String get settingsOnlineBiosShort => 'bios';

  @override
  String get settingsOnlinePhotosShort => 'photos';

  @override
  String get settingsOnlineLyricsShort => 'lyrics';

  @override
  String get settingsOnlineIntro =>
      'Optional, and off until you turn them on. Each one says what it sends, and where.';

  @override
  String get settingsOnlineBiosSubtitle =>
      'From Last.fm, with artist and album names.';

  @override
  String get settingsOnlinePhotosSubtitle =>
      'From Deezer, with artist and album names and a few song titles.';

  @override
  String get settingsOnlineLyricsSubtitle =>
      'From LRCLIB, then lyrics.ovh, when you open a song\'s lyrics.';

  @override
  String get settingsOnlinePageFooter =>
      'Nothing else about you or your music leaves this phone. Downloaded info can be cleared in Storage.';

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsAppearanceSummary => 'Glass effects, haptics';

  @override
  String get settingsAppearanceIntro =>
      'How Troona looks, and how it answers your touch.';

  @override
  String get settingsTouch => 'Touch';

  @override
  String get settingsHapticsSubtitle =>
      'Light vibrations when you tap, pick or like.';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsStorage => 'Storage';

  @override
  String settingsStorageSummary(String size) {
    return 'Cache $size, reset';
  }

  @override
  String get settingsStorageSummaryPending => 'Cache, reset';

  @override
  String get settingsStorageIntro =>
      'What Troona keeps on this phone besides your music, and how to start over.';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsOnlineClearSubtitle =>
      'Bios, photos and lyrics found online. Imported lyrics stay.';

  @override
  String get settingsForgetQueueSubtitle =>
      'Stops the music and forgets the queue and where you were.';

  @override
  String get settingsResetSettingsSubtitle =>
      'Every preference back to its default. Your library, likes and playlists stay.';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsAboutSummary(String version) {
    return 'Version $version, what\'s new, updates';
  }

  @override
  String get settingsAboutSummaryPending => 'What\'s new, updates';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get aboutUpdates => 'Updates';

  @override
  String get aboutInformation => 'Information';

  @override
  String get aboutSource => 'Source code';

  @override
  String get aboutSourceSubtitle => 'On GitHub';

  @override
  String get settingsOnlineSources => 'Sources';

  @override
  String get settingsFilters => 'Filters';

  @override
  String get settingsMinLength => 'Shortest song';

  @override
  String get settingsMinLengthSubtitle =>
      'Shorter files stay out of your library.';

  @override
  String durationSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get settingsFolders => 'Folders';

  @override
  String get settingsFoldersAll => 'Every folder is in your library';

  @override
  String settingsFoldersExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders left out',
      one: '1 folder left out',
    );
    return '$_temp0';
  }

  @override
  String get settingsFoldersIntro =>
      'Songs in a folder turned off leave your library, with its subfolders. Turn it back on and they come back with their likes, plays and playlists.';

  @override
  String get settingsFoldersFooter =>
      'At least one song stays in your library.';

  @override
  String get settingsFoldersEmpty => 'No folders yet: your library is empty.';

  @override
  String settingsFolderCoveredBy(String folder) {
    return 'Left out with $folder';
  }

  @override
  String get settingsFolderInPhone => 'Phone';

  @override
  String get settingsFolderInSdCard => 'SD card';

  @override
  String get settingsFoldersSection => 'Folders with music';

  @override
  String get licensesIntro =>
      'Troona is built with open-source software. Thank you to the people who make it.';

  @override
  String get licensesOwnTerms => 'Its own terms';

  @override
  String get licensesNotFound => 'This license is no longer listed.';

  @override
  String get settingsLicensesSubtitle => 'The software Troona is built with';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licenses',
      one: '1 license',
    );
    return '$_temp0';
  }

  @override
  String get settingsMinLengthTooLong =>
      'No song in your library is that long: it would be empty.';

  @override
  String get settingsFiltersNotApplied =>
      'No song in your library passes these filters, so they are not applied. Turn a folder back on or choose a shorter length.';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpSubtitle => 'Missing songs, playback, lyrics, a new phone';

  @override
  String get helpIntro =>
      'Answers to the questions that come up most, each with the setting that settles it.';

  @override
  String get helpLibrarySection => 'Library';

  @override
  String get helpMissingSong => 'A song is missing';

  @override
  String get helpMissingSongAnswer =>
      'Troona lists the songs Android knows about. A folder turned off or the shortest length may leave it out; a file just copied shows after Rescan library.';

  @override
  String get helpPlaybackSection => 'Playback';

  @override
  String get helpStopsInBackground => 'Music stops with the screen off';

  @override
  String get helpStopsInBackgroundAnswer =>
      'Some phones stop apps in the background to save battery. In Troona\'s page in Android\'s settings, set battery use to Unrestricted.';

  @override
  String get helpOnlineSection => 'Online extras';

  @override
  String get helpNoLyrics => 'A song has no lyrics';

  @override
  String get helpNoLyricsAnswer =>
      'Turn on Song lyrics to look them up online, or import a .lrc file from the song\'s menu, under Lyrics options.';

  @override
  String get helpArtistInfo => 'Artist photos and bios';

  @override
  String get helpArtistInfoAnswer =>
      'They come from Deezer and Last.fm, only once you turn them on. Nothing leaves your phone otherwise.';

  @override
  String get helpBackupSection => 'Backup';

  @override
  String get helpNewPhone => 'Moving to a new phone';

  @override
  String get helpNewPhoneAnswer =>
      'Make a backup, copy the file to the new phone and restore it there: playlists, likes, history and settings come back, and your songs are found again by their name, size and tags.';
}
