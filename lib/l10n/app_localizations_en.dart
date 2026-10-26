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
      'Optional. When on, Troona sends artist and album names to Last.fm and Deezer to fetch photos and bios. Your music files never leave this device.';

  @override
  String get settingsOnlineBios => 'Artist bios and album notes';

  @override
  String get settingsOnlinePhotos => 'Artist photos';

  @override
  String get settingsOnlineClear => 'Clear downloaded info';

  @override
  String get settingsOnlineConfirmTitle => 'Clear downloaded info?';

  @override
  String get settingsOnlineConfirmBody =>
      'Bios and album notes will download again when you open an artist or an album.';

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
      'If you turn them on, Troona sends artist and album names to Last.fm and Deezer to fetch photos and bios. These services also see your IP address, as with any web request. No file, account or listening history is sent. Turn them off at any time in Settings.';

  @override
  String get privacyReportsTitle => 'Problem reports';

  @override
  String get privacyReportsBody =>
      'Errors are written to a log on this device. It can contain file names. Nothing is sent unless you choose Report a problem and share it yourself.';

  @override
  String get privacyDeleteTitle => 'Deleting your data';

  @override
  String get privacyDeleteBody =>
      'Uninstalling Troona deletes everything it stored. Your music files are never touched.';
}
