import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Troona'**
  String get appName;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get actionSeeAll;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actionPlay;

  /// No description provided for @actionShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get actionShuffle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @songCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String songCount(int count);

  /// No description provided for @albumCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No albums} =1{1 album} other{{count} albums}}'**
  String albumCount(int count);

  /// No description provided for @singleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 single} other{{count} singles}}'**
  String singleCount(int count);

  /// Stands for the song count under a single's name: Artist • Single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get albumSingle;

  /// No description provided for @artistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No artists} =1{1 artist} other{{count} artists}}'**
  String artistCount(int count);

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get unknownAlbum;

  /// No description provided for @likedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked songs'**
  String get likedSongs;

  /// No description provided for @sizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMegabytes(String size);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get navPlaylists;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsPlayback;

  /// No description provided for @settingsDuck.
  ///
  /// In en, this message translates to:
  /// **'Lower volume for notifications'**
  String get settingsDuck;

  /// No description provided for @settingsPauseOnCall.
  ///
  /// In en, this message translates to:
  /// **'Pause during calls'**
  String get settingsPauseOnCall;

  /// No description provided for @settingsResumeAfterCall.
  ///
  /// In en, this message translates to:
  /// **'Resume after calls'**
  String get settingsResumeAfterCall;

  /// No description provided for @settingsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibrary;

  /// No description provided for @settingsRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan library'**
  String get settingsRescan;

  /// No description provided for @settingsRescanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find songs added since the last scan'**
  String get settingsRescanSubtitle;

  /// No description provided for @settingsRescanning.
  ///
  /// In en, this message translates to:
  /// **'Updating your library…'**
  String get settingsRescanning;

  /// No description provided for @settingsCoversClear.
  ///
  /// In en, this message translates to:
  /// **'Clear cover cache'**
  String get settingsCoversClear;

  /// No description provided for @settingsCoversClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Covers are rebuilt automatically.'**
  String get settingsCoversClearSubtitle;

  /// No description provided for @settingsCoversConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cover cache?'**
  String get settingsCoversConfirmTitle;

  /// No description provided for @settingsCoversConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Covers reload in the background. Your music, likes and playlists aren\'t affected.'**
  String get settingsCoversConfirmBody;

  /// No description provided for @settingsCoversCleared.
  ///
  /// In en, this message translates to:
  /// **'Cover cache cleared'**
  String get settingsCoversCleared;

  /// No description provided for @settingsOnline.
  ///
  /// In en, this message translates to:
  /// **'Online extras'**
  String get settingsOnline;

  /// No description provided for @settingsOnlineBios.
  ///
  /// In en, this message translates to:
  /// **'Artist bios and album notes'**
  String get settingsOnlineBios;

  /// No description provided for @settingsOnlinePhotos.
  ///
  /// In en, this message translates to:
  /// **'Artist photos and album covers'**
  String get settingsOnlinePhotos;

  /// No description provided for @settingsOnlineClear.
  ///
  /// In en, this message translates to:
  /// **'Clear downloaded info'**
  String get settingsOnlineClear;

  /// No description provided for @settingsOnlineConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear downloaded info?'**
  String get settingsOnlineConfirmTitle;

  /// No description provided for @settingsOnlineConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Bios, album notes, photos and lyrics found online will download again when you open them, if they are still turned on. Imported lyrics are kept.'**
  String get settingsOnlineConfirmBody;

  /// No description provided for @settingsOnlineCleared.
  ///
  /// In en, this message translates to:
  /// **'Downloaded info cleared'**
  String get settingsOnlineCleared;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass effects'**
  String get settingsGlass;

  /// No description provided for @settingsGlassAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsGlassAuto;

  /// No description provided for @settingsGlassFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get settingsGlassFull;

  /// No description provided for @settingsGlassBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get settingsGlassBalanced;

  /// No description provided for @settingsGlassOff.
  ///
  /// In en, this message translates to:
  /// **'No blur'**
  String get settingsGlassOff;

  /// No description provided for @settingsGlassFooter.
  ///
  /// In en, this message translates to:
  /// **'Auto: {tier} on this phone. Balanced keeps the blur in page headers only, No blur draws none: both scroll more smoothly on older phones.'**
  String settingsGlassFooter(String tier);

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and feedback'**
  String get settingsSupport;

  /// No description provided for @settingsReport.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get settingsReport;

  /// No description provided for @settingsReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shares device info and recent errors. You can read it before sending.'**
  String get settingsReportSubtitle;

  /// No description provided for @settingsReportSubject.
  ///
  /// In en, this message translates to:
  /// **'Troona problem report'**
  String get settingsReportSubject;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsForgetQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue and position'**
  String get settingsForgetQueue;

  /// No description provided for @settingsForgetQueueConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear queue and position?'**
  String get settingsForgetQueueConfirmTitle;

  /// No description provided for @settingsForgetQueueConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Playback stops and Troona forgets where you were.'**
  String get settingsForgetQueueConfirmBody;

  /// No description provided for @settingsForgetQueueDone.
  ///
  /// In en, this message translates to:
  /// **'Queue cleared'**
  String get settingsForgetQueueDone;

  /// No description provided for @settingsResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get settingsResetSettings;

  /// No description provided for @settingsResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset settings?'**
  String get settingsResetConfirmTitle;

  /// No description provided for @settingsResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All preferences go back to their defaults. Your library, likes and playlists stay as they are.'**
  String get settingsResetConfirmBody;

  /// No description provided for @settingsTagline.
  ///
  /// In en, this message translates to:
  /// **'Made for the music you own.'**
  String get settingsTagline;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your settings.'**
  String get settingsLoadError;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Troona plays the music stored on your phone. It has no account, no ads and no analytics.'**
  String get privacyIntro;

  /// No description provided for @privacyLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get privacyLocalTitle;

  /// No description provided for @privacyLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Your library, likes, playlists and listening history are stored only on this phone. Troona reads your audio files and never your photos, videos or documents.'**
  String get privacyLocalBody;

  /// No description provided for @privacyOnlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Online extras (off by default)'**
  String get privacyOnlineTitle;

  /// No description provided for @privacyOnlineBody.
  ///
  /// In en, this message translates to:
  /// **'There are two separate switches. Bios sends artist and album names to Last.fm. Photos sends them to Deezer, with up to three titles of each artist\'s songs (their most played) so that the photo found is of that artist and not a namesake, and downloads pictures from Deezer or Last.fm. These services also see your IP address, as with any web request. No file, account or play count is sent. Turn either switch off at any time in Settings: requests to that service stop, and turning photos off also deletes the photos already downloaded.'**
  String get privacyOnlineBody;

  /// No description provided for @privacyReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem reports'**
  String get privacyReportsTitle;

  /// No description provided for @privacyReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Errors are written to a log on this device. It can contain file names. Nothing is sent unless you choose Report a problem and share it yourself.'**
  String get privacyReportsBody;

  /// No description provided for @privacyBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get privacyBackupTitle;

  /// No description provided for @privacyBackupBody.
  ///
  /// In en, this message translates to:
  /// **'A backup holds the parts you choose (playlists, likes, listening history, imported lyrics and their timing, settings, equalizer), with the names and sizes of your music files, unencrypted. Troona writes it to the folder you picked for backups, or hands it to the app you choose when you share it. It goes nowhere else. Restoring reads only the backup you pick, and writes only the parts you keep.'**
  String get privacyBackupBody;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling Troona deletes everything it stored. Your music files, and backups in your backup folder or exported, are never touched.'**
  String get privacyDeleteBody;

  /// No description provided for @permissionHeadline.
  ///
  /// In en, this message translates to:
  /// **'All your music.\nNothing in the way.'**
  String get permissionHeadline;

  /// No description provided for @permissionSubhead.
  ///
  /// In en, this message translates to:
  /// **'Troona plays the songs already on your phone. No account, no ads, no streaming.'**
  String get permissionSubhead;

  /// No description provided for @permissionQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Plays what you own'**
  String get permissionQualityTitle;

  /// No description provided for @permissionQualityBody.
  ///
  /// In en, this message translates to:
  /// **'MP3, FLAC, AAC, WAV, OGG and Opus, at their original quality.'**
  String get permissionQualityBody;

  /// No description provided for @permissionPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get permissionPrivacyTitle;

  /// No description provided for @permissionPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your music stays on this device. Online extras are optional.'**
  String get permissionPrivacyBody;

  /// No description provided for @permissionLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready in seconds'**
  String get permissionLibraryTitle;

  /// No description provided for @permissionLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Covers, albums and artists, sorted for you.'**
  String get permissionLibraryBody;

  /// No description provided for @permissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get permissionAllow;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Troona can\'t see your music yet'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Troona needs access to your audio files to build your library. It never reads your photos, videos or documents.'**
  String get permissionDeniedBody;

  /// No description provided for @permissionBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access is turned off'**
  String get permissionBlockedTitle;

  /// No description provided for @permissionBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Troona to access your music in your phone\'s settings, then come back. We\'ll take it from there.'**
  String get permissionBlockedBody;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permissionOpenSettings;

  /// No description provided for @permissionCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'I turned it on'**
  String get permissionCheckAgain;

  /// No description provided for @permissionFooter.
  ///
  /// In en, this message translates to:
  /// **'Free • No ads • No account'**
  String get permissionFooter;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding your music'**
  String get scanTitle;

  /// No description provided for @scanPhaseScanning.
  ///
  /// In en, this message translates to:
  /// **'Looking for songs on your phone…'**
  String get scanPhaseScanning;

  /// No description provided for @scanPhaseIndexing.
  ///
  /// In en, this message translates to:
  /// **'Building your library…'**
  String get scanPhaseIndexing;

  /// No description provided for @scanPhaseArtwork.
  ///
  /// In en, this message translates to:
  /// **'Adding album covers…'**
  String get scanPhaseArtwork;

  /// No description provided for @scanPhaseDone.
  ///
  /// In en, this message translates to:
  /// **'Almost ready…'**
  String get scanPhaseDone;

  /// No description provided for @scanSongsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song found} other{{count} songs found}}'**
  String scanSongsFound(int count);

  /// No description provided for @scanProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String scanProgress(int count, int total);

  /// No description provided for @scanNewSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new song added} other{{count} new songs added}}'**
  String scanNewSongs(int count);

  /// No description provided for @scanRemovedSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song is no longer on your phone} other{{count} songs are no longer on your phone}}'**
  String scanRemovedSongs(int count);

  /// No description provided for @libraryRescanFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for new music. Your library is as it was.'**
  String get libraryRescanFailed;

  /// Toast when a file opened from another app (Open with) is not in the library.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t in your library. For now, Troona only opens songs from your music.'**
  String get openedFileNotInLibrary;

  /// No description provided for @libraryLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open your library'**
  String get libraryLoadErrorTitle;

  /// No description provided for @libraryLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check that Troona can still access your music, then try again.'**
  String get libraryLoadErrorBody;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @playerCantPlay.
  ///
  /// In en, this message translates to:
  /// **'Can\'t play \"{title}\". Skipping to the next song.'**
  String playerCantPlay(String title);

  /// No description provided for @playerCantPlayUnknown.
  ///
  /// In en, this message translates to:
  /// **'This song can\'t be played. Skipping to the next one.'**
  String get playerCantPlayUnknown;

  /// No description provided for @playerQueueReplaced.
  ///
  /// In en, this message translates to:
  /// **'Queue replaced'**
  String get playerQueueReplaced;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Playback controls'**
  String get notificationChannelName;

  /// No description provided for @bootTitle.
  ///
  /// In en, this message translates to:
  /// **'Troona couldn\'t start'**
  String get bootTitle;

  /// No description provided for @bootBody.
  ///
  /// In en, this message translates to:
  /// **'Restart the app. If it keeps happening, copy the report and send it to us.'**
  String get bootBody;

  /// No description provided for @bootCopyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get bootCopyReport;

  /// No description provided for @bootReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get bootReportCopied;

  /// No description provided for @libraryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryFilterAll;

  /// No description provided for @libraryFilterSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get libraryFilterSongs;

  /// No description provided for @libraryFilterAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get libraryFilterAlbums;

  /// No description provided for @libraryFilterArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get libraryFilterArtists;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No music on this device yet'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Copy songs to your phone, then scan again.'**
  String get libraryEmptyBody;

  /// No description provided for @libraryScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get libraryScanAgain;

  /// No description provided for @libraryIndex.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical index'**
  String get libraryIndex;

  /// No description provided for @libraryIndexJump.
  ///
  /// In en, this message translates to:
  /// **'Go to {letter}'**
  String libraryIndexJump(String letter);

  /// No description provided for @libraryNoSongs.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get libraryNoSongs;

  /// No description provided for @libraryNoAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums yet'**
  String get libraryNoAlbums;

  /// No description provided for @libraryNoArtists.
  ///
  /// In en, this message translates to:
  /// **'No artists yet'**
  String get libraryNoArtists;

  /// No description provided for @librarySort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get librarySort;

  /// No description provided for @librarySortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get librarySortBy;

  /// No description provided for @librarySortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get librarySortTitle;

  /// No description provided for @librarySortArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get librarySortArtist;

  /// No description provided for @librarySortAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get librarySortAlbum;

  /// No description provided for @librarySortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get librarySortRecent;

  /// No description provided for @librarySortPlays.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get librarySortPlays;

  /// No description provided for @libraryUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating your library…'**
  String get libraryUpdating;

  /// No description provided for @libraryShuffleAll.
  ///
  /// In en, this message translates to:
  /// **'Shuffle all'**
  String get libraryShuffleAll;

  /// No description provided for @albumByArtist.
  ///
  /// In en, this message translates to:
  /// **'{artist} • {songs}'**
  String albumByArtist(String artist, String songs);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @trackPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get trackPlayNext;

  /// No description provided for @trackAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get trackAddToQueue;

  /// No description provided for @detailSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get detailSongs;

  /// No description provided for @detailAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get detailAlbums;

  /// No description provided for @detailSingles.
  ///
  /// In en, this message translates to:
  /// **'Singles'**
  String get detailSingles;

  /// No description provided for @detailDiscography.
  ///
  /// In en, this message translates to:
  /// **'Discography'**
  String get detailDiscography;

  /// No description provided for @detailLatestRelease.
  ///
  /// In en, this message translates to:
  /// **'Latest release'**
  String get detailLatestRelease;

  /// No description provided for @detailAppearsOn.
  ///
  /// In en, this message translates to:
  /// **'Appears on'**
  String get detailAppearsOn;

  /// Artists similar to this one that are in the library.
  ///
  /// In en, this message translates to:
  /// **'Also in your library'**
  String get detailAlsoInLibrary;

  /// No description provided for @detailPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get detailPopular;

  /// No description provided for @detailSeeAllSongs.
  ///
  /// In en, this message translates to:
  /// **'See all {count} songs'**
  String detailSeeAllSongs(int count);

  /// No description provided for @detailShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get detailShowLess;

  /// No description provided for @detailMoreBy.
  ///
  /// In en, this message translates to:
  /// **'More by {artist}'**
  String detailMoreBy(String artist);

  /// No description provided for @detailMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get detailMore;

  /// No description provided for @detailBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get detailBack;

  /// No description provided for @detailCountsSummary.
  ///
  /// In en, this message translates to:
  /// **'{songs} • {albums}'**
  String detailCountsSummary(String songs, String albums);

  /// No description provided for @formatLossless.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get formatLossless;

  /// No description provided for @albumLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this album.'**
  String get albumLoadError;

  /// No description provided for @artistLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this artist.'**
  String get artistLoadError;

  /// No description provided for @metaListeners.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 listener} other{{count} listeners}}'**
  String metaListeners(int count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Songs, artists, albums'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @searchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your library'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleBody.
  ///
  /// In en, this message translates to:
  /// **'Songs, artists and albums on this device.'**
  String get searchIdleBody;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResultsTitle(String query);

  /// No description provided for @searchNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter word or an artist name.'**
  String get searchNoResultsBody;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t available right now.'**
  String get searchError;

  /// No description provided for @searchSuggestedArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchSuggestedArtists;

  /// No description provided for @searchSuggestedAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get searchSuggestedAlbums;

  /// No description provided for @searchRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get searchRecentlyAdded;

  /// No description provided for @recentlyAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get recentlyAddedTitle;

  /// No description provided for @recentlyAddedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing added yet'**
  String get recentlyAddedEmptyTitle;

  /// No description provided for @recentlyAddedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Songs you add to your phone show here, newest first.'**
  String get recentlyAddedEmptyBody;

  /// No description provided for @recentAlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent albums'**
  String get recentAlbumsTitle;

  /// No description provided for @recentAlbumsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Albums you add to your phone show here, newest first.'**
  String get recentAlbumsEmptyBody;

  /// No description provided for @searchBadgeArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get searchBadgeArtist;

  /// No description provided for @searchBadgeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get searchBadgeAlbum;

  /// No description provided for @searchBadgeSong.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get searchBadgeSong;

  /// No description provided for @playlistsCreate.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get playlistsCreate;

  /// No description provided for @playlistsListView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get playlistsListView;

  /// No description provided for @playlistsGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get playlistsGridView;

  /// No description provided for @playlistsYours.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get playlistsYours;

  /// No description provided for @playlistsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Make your first playlist'**
  String get playlistsEmptyTitle;

  /// No description provided for @playlistsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Group songs for a mood, a moment or a road trip.'**
  String get playlistsEmptyBody;

  /// No description provided for @playlistNew.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistNew;

  /// No description provided for @playlistEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get playlistEdit;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @playlistAddCover.
  ///
  /// In en, this message translates to:
  /// **'Add a cover'**
  String get playlistAddCover;

  /// No description provided for @playlistCreateAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Create and add'**
  String get playlistCreateAndAdd;

  /// No description provided for @playlistCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get playlistCreate;

  /// No description provided for @playlistAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get playlistAddTo;

  /// No description provided for @playlistNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get playlistNoneYet;

  /// No description provided for @playlistAddedTo.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String playlistAddedTo(String name);

  /// No description provided for @playlistAlreadyIn.
  ///
  /// In en, this message translates to:
  /// **'Already in {name}'**
  String playlistAlreadyIn(String name);

  /// No description provided for @playlistDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String playlistDeleteTitle(String name);

  /// No description provided for @playlistDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the playlist only. The songs stay in your library.'**
  String get playlistDeleteBody;

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeleted;

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add songs from the ··· menu on any song.'**
  String get playlistEmptyBody;

  /// No description provided for @playlistRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get playlistRemove;

  /// No description provided for @playlistLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your playlists.'**
  String get playlistLoadError;

  /// No description provided for @playlistOpenError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this playlist.'**
  String get playlistOpenError;

  /// No description provided for @likesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Songs you like will live here'**
  String get likesEmptyTitle;

  /// No description provided for @likesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any song to save it.'**
  String get likesEmptyBody;

  /// No description provided for @likesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{songs} • Your favorites in one place'**
  String likesSubtitle(String songs);

  /// No description provided for @likesBadge.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get likesBadge;

  /// No description provided for @likesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from Liked songs'**
  String get likesRemove;

  /// No description provided for @trackLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get trackLike;

  /// No description provided for @trackAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get trackAddToPlaylist;

  /// No description provided for @trackGoToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get trackGoToAlbum;

  /// No description provided for @trackGoToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get trackGoToArtist;

  /// No description provided for @toastPlaysNext.
  ///
  /// In en, this message translates to:
  /// **'Plays next'**
  String get toastPlaysNext;

  /// No description provided for @toastAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get toastAddedToQueue;

  /// No description provided for @toastLiked.
  ///
  /// In en, this message translates to:
  /// **'Added to Liked songs'**
  String get toastLiked;

  /// No description provided for @toastUnliked.
  ///
  /// In en, this message translates to:
  /// **'Removed from Liked songs'**
  String get toastUnliked;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Late-night session'**
  String get homeGreetingNight;

  /// No description provided for @homeSubtitleWarm.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off.'**
  String get homeSubtitleWarm;

  /// No description provided for @homeSongsReady.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song, ready when you are.} other{{count} songs, ready when you are.}}'**
  String homeSongsReady(int count);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No music here yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Copy songs to your phone\'s Music folder, then scan again.'**
  String get homeEmptyBody;

  /// No description provided for @homeFreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is ready'**
  String get homeFreshTitle;

  /// No description provided for @homeJumpBackIn.
  ///
  /// In en, this message translates to:
  /// **'Jump back in'**
  String get homeJumpBackIn;

  /// No description provided for @homeNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get homeNowPlaying;

  /// No description provided for @queueOriginAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get queueOriginAlbum;

  /// No description provided for @queueOriginArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get queueOriginArtist;

  /// No description provided for @queueOriginPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get queueOriginPlaylist;

  /// Home resume card: listening time left in the queue, e.g. 12 min left.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String homeTimeLeft(String time);

  /// No description provided for @homeQuickRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get homeQuickRecent;

  /// No description provided for @homeRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get homeRecentlyPlayed;

  /// No description provided for @homeOnRepeat.
  ///
  /// In en, this message translates to:
  /// **'On repeat this week'**
  String get homeOnRepeat;

  /// No description provided for @homeRediscover.
  ///
  /// In en, this message translates to:
  /// **'Rediscover'**
  String get homeRediscover;

  /// No description provided for @homeRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get homeRecentlyAdded;

  /// No description provided for @homeWeeklyPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play this week} other{{count} plays this week}}'**
  String homeWeeklyPlays(int count);

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your home. Pull down to try again.'**
  String get homeLoadError;

  /// No description provided for @homeExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Add artist photos and bios?'**
  String get homeExtrasTitle;

  /// No description provided for @homeExtrasBody.
  ///
  /// In en, this message translates to:
  /// **'Troona can fetch them from Last.fm and Deezer using artist and album names, and a few song titles for photos. Your music files stay on this device.'**
  String get homeExtrasBody;

  /// No description provided for @homeExtrasAccept.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get homeExtrasAccept;

  /// No description provided for @homeExtrasDecline.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get homeExtrasDecline;

  /// No description provided for @homeExtrasDeclined.
  ///
  /// In en, this message translates to:
  /// **'You can turn them on anytime in Settings.'**
  String get homeExtrasDeclined;

  /// No description provided for @recapTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week in music'**
  String get recapTitle;

  /// No description provided for @recapRange.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String recapRange(String start, String end);

  /// No description provided for @recapOpen.
  ///
  /// In en, this message translates to:
  /// **'Open your week in music'**
  String get recapOpen;

  /// No description provided for @recapListened.
  ///
  /// In en, this message translates to:
  /// **'listened'**
  String get recapListened;

  /// No description provided for @recapTopArtist.
  ///
  /// In en, this message translates to:
  /// **'Top artist'**
  String get recapTopArtist;

  /// No description provided for @recapTopSong.
  ///
  /// In en, this message translates to:
  /// **'Top song'**
  String get recapTopSong;

  /// No description provided for @recapDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'First listens'**
  String get recapDiscoveries;

  /// No description provided for @recapDiscoveriesValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new songs} =1{1 song heard for the first time} other{{count} songs heard for the first time}}'**
  String recapDiscoveriesValue(int count);

  /// No description provided for @recapPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String recapPlays(int count);

  /// No description provided for @recapHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String recapHoursMinutes(int hours, int minutes);

  /// No description provided for @recapMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String recapMinutes(int minutes);

  /// No description provided for @recapPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Your listening'**
  String get recapPageTitle;

  /// No description provided for @recapWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get recapWeek;

  /// No description provided for @recapMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get recapMonth;

  /// No description provided for @recapThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get recapThisWeek;

  /// No description provided for @recapLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get recapLastWeek;

  /// No description provided for @recapThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get recapThisMonth;

  /// No description provided for @recapLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get recapLastMonth;

  /// No description provided for @recapPreviousSpan.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get recapPreviousSpan;

  /// No description provided for @recapNextSpan.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get recapNextSpan;

  /// No description provided for @recapInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get recapInProgress;

  /// No description provided for @recapActiveDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day with music} other{{count} days with music}}'**
  String recapActiveDays(int count);

  /// No description provided for @recapNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing played yet.'**
  String get recapNothingYet;

  /// No description provided for @recapNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing was played.'**
  String get recapNothing;

  /// No description provided for @recapTopSongs.
  ///
  /// In en, this message translates to:
  /// **'Top songs'**
  String get recapTopSongs;

  /// No description provided for @recapPlaysHeader.
  ///
  /// In en, this message translates to:
  /// **'Plays'**
  String get recapPlaysHeader;

  /// No description provided for @recapShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get recapShare;

  /// No description provided for @recapStoryWeek.
  ///
  /// In en, this message translates to:
  /// **'My week in music'**
  String get recapStoryWeek;

  /// No description provided for @recapStoryMonth.
  ///
  /// In en, this message translates to:
  /// **'My month in music'**
  String get recapStoryMonth;

  /// No description provided for @recapTopAlbums.
  ///
  /// In en, this message translates to:
  /// **'Top albums'**
  String get recapTopAlbums;

  /// No description provided for @recapDayByDay.
  ///
  /// In en, this message translates to:
  /// **'Day by day'**
  String get recapDayByDay;

  /// No description provided for @recapLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get recapLess;

  /// No description provided for @recapMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get recapMore;

  /// No description provided for @recapDayPlays.
  ///
  /// In en, this message translates to:
  /// **'{date}, {count, plural, =0{no music} =1{1 play} other{{count} plays}}'**
  String recapDayPlays(String date, int count);

  /// No description provided for @recapBusiestDay.
  ///
  /// In en, this message translates to:
  /// **'Busiest day: {date}, {plays}'**
  String recapBusiestDay(String date, String plays);

  /// No description provided for @recapMoments.
  ///
  /// In en, this message translates to:
  /// **'When you listen'**
  String get recapMoments;

  /// No description provided for @recapMomentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your listening moments show up as you play music.'**
  String get recapMomentsEmpty;

  /// No description provided for @recapPeak.
  ///
  /// In en, this message translates to:
  /// **'Peak: {weekday} {part}'**
  String recapPeak(String weekday, String part);

  /// No description provided for @recapPeakNight.
  ///
  /// In en, this message translates to:
  /// **'Peak: {eve} night'**
  String recapPeakNight(String eve, String day);

  /// No description provided for @recapMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get recapMorning;

  /// No description provided for @recapAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get recapAfternoon;

  /// No description provided for @recapEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get recapEvening;

  /// No description provided for @recapNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get recapNight;

  /// No description provided for @replayName.
  ///
  /// In en, this message translates to:
  /// **'Replay {month}'**
  String replayName(String month);

  /// No description provided for @replayReady.
  ///
  /// In en, this message translates to:
  /// **'{name} is in your playlists: last month\'s most played songs.'**
  String replayReady(String name);

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @queueHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get queueHistory;

  /// No description provided for @queueBackToNow.
  ///
  /// In en, this message translates to:
  /// **'Back to now playing'**
  String get queueBackToNow;

  /// No description provided for @queueNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get queueNowPlaying;

  /// No description provided for @queueRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeating this song'**
  String get queueRepeatOne;

  /// No description provided for @queueRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Then back to the start'**
  String get queueRepeatAll;

  /// No description provided for @queueNothingNext.
  ///
  /// In en, this message translates to:
  /// **'Nothing up next'**
  String get queueNothingNext;

  /// No description provided for @queueUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next • {count}'**
  String queueUpNext(int count);

  /// No description provided for @queueRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\"'**
  String queueRemoved(String title);

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepStopsAt.
  ///
  /// In en, this message translates to:
  /// **'Music stops at {time}.'**
  String sleepStopsAt(String time);

  /// No description provided for @sleepStopsEndOfSong.
  ///
  /// In en, this message translates to:
  /// **'Music stops at the end of this song.'**
  String get sleepStopsEndOfSong;

  /// No description provided for @sleepIdle.
  ///
  /// In en, this message translates to:
  /// **'Stop the music after a while.'**
  String get sleepIdle;

  /// No description provided for @sleepOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get sleepOneHour;

  /// No description provided for @sleepEndOfSong.
  ///
  /// In en, this message translates to:
  /// **'End of song'**
  String get sleepEndOfSong;

  /// No description provided for @sleepTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get sleepTurnOff;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @playbackSpeedNormal.
  ///
  /// In en, this message translates to:
  /// **'{speed} (normal)'**
  String playbackSpeedNormal(String speed);

  /// No description provided for @playbackPosition.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playbackPosition;

  /// No description provided for @playbackPositionValue.
  ///
  /// In en, this message translates to:
  /// **'{position} of {duration}'**
  String playbackPositionValue(String position, String duration);

  /// No description provided for @metaAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get metaAbout;

  /// Where the About text comes from, under it.
  ///
  /// In en, this message translates to:
  /// **'From {source}'**
  String metaSource(String source);

  /// No description provided for @metaReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get metaReadMore;

  /// No description provided for @metaReadLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get metaReadLess;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playerNext;

  /// No description provided for @playerPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playerPrevious;

  /// No description provided for @playerShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playerShuffle;

  /// No description provided for @playerRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get playerRepeatOff;

  /// No description provided for @playerRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get playerRepeatAll;

  /// No description provided for @playerRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat this song'**
  String get playerRepeatOne;

  /// No description provided for @playerClose.
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get playerClose;

  /// No description provided for @playerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open player'**
  String get playerOpen;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String whatsNewVersion(String version);

  /// No description provided for @whatsNewAdded.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get whatsNewAdded;

  /// No description provided for @whatsNewImproved.
  ///
  /// In en, this message translates to:
  /// **'Improved'**
  String get whatsNewImproved;

  /// No description provided for @whatsNewFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get whatsNewFixed;

  /// No description provided for @whatsNewContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get whatsNewContinue;

  /// No description provided for @whatsNewLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get whatsNewLatest;

  /// No description provided for @whatsNewEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier releases'**
  String get whatsNewEarlier;

  /// No description provided for @whatsNewShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} changes'**
  String whatsNewShowAll(int count);

  /// No description provided for @whatsNewShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get whatsNewShowLess;

  /// No description provided for @whatsNewCountAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new} other{{count} new}}'**
  String whatsNewCountAdded(int count);

  /// No description provided for @whatsNewCountImproved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 improvement} other{{count} improvements}}'**
  String whatsNewCountImproved(int count);

  /// No description provided for @whatsNewCountFixed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 fix} other{{count} fixes}}'**
  String whatsNewCountFixed(int count);

  /// No description provided for @whatsNew100WeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week in music'**
  String get whatsNew100WeekTitle;

  /// No description provided for @whatsNew100WeekBody.
  ///
  /// In en, this message translates to:
  /// **'Every Monday on Home: listening time, top artist and top song, with a calendar of the days you listened.'**
  String get whatsNew100WeekBody;

  /// No description provided for @whatsNew100ReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Replay'**
  String get whatsNew100ReplayTitle;

  /// No description provided for @whatsNew100ReplayBody.
  ///
  /// In en, this message translates to:
  /// **'At the start of each month, your 25 most played songs of the month before become a playlist.'**
  String get whatsNew100ReplayBody;

  /// No description provided for @whatsNew100SleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer and speed'**
  String get whatsNew100SleepTitle;

  /// No description provided for @whatsNew100SleepBody.
  ///
  /// In en, this message translates to:
  /// **'Stop the music after 15, 30 or 45 minutes, an hour or at the end of the song, and play from 0.75x to 2x.'**
  String get whatsNew100SleepBody;

  /// No description provided for @whatsNew100QueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get whatsNew100QueueTitle;

  /// No description provided for @whatsNew100QueueBody.
  ///
  /// In en, this message translates to:
  /// **'See what played and what comes next. Drag to reorder, swipe to remove, undo in one tap.'**
  String get whatsNew100QueueBody;

  /// No description provided for @whatsNew100ExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist photos and bios, your call'**
  String get whatsNew100ExtrasTitle;

  /// No description provided for @whatsNew100ExtrasBody.
  ///
  /// In en, this message translates to:
  /// **'Two switches in Settings, off by default. Your music files never leave your phone.'**
  String get whatsNew100ExtrasBody;

  /// No description provided for @whatsNew100LibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library, offline'**
  String get whatsNew100LibraryTitle;

  /// No description provided for @whatsNew100LibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Songs, albums and artists from your phone, with search across all three. Scans show their progress live.'**
  String get whatsNew100LibraryBody;

  /// No description provided for @whatsNew100PlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get whatsNew100PlayerTitle;

  /// No description provided for @whatsNew100PlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Swipe between covers, seek on the ring, and enjoy soft fades on play, pause and skip.'**
  String get whatsNew100PlayerBody;

  /// No description provided for @whatsNew100PlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists and likes'**
  String get whatsNew100PlaylistsTitle;

  /// No description provided for @whatsNew100PlaylistsBody.
  ///
  /// In en, this message translates to:
  /// **'Create playlists, reorder their songs, and find every song you like in one place.'**
  String get whatsNew100PlaylistsBody;

  /// No description provided for @whatsNew100LanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'English and French'**
  String get whatsNew100LanguageTitle;

  /// No description provided for @whatsNew100LanguageBody.
  ///
  /// In en, this message translates to:
  /// **'The whole app follows your phone\'s language.'**
  String get whatsNew100LanguageBody;

  /// No description provided for @settingsBackupFooter.
  ///
  /// In en, this message translates to:
  /// **'A backup holds what you choose above, with the names and sizes of your music files, unencrypted. Keep it somewhere private.'**
  String get settingsBackupFooter;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save it to Files, Drive or another app.'**
  String get backupExportSubtitle;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Troona backup'**
  String get backupShareSubject;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get backupRestore;

  /// No description provided for @backupRestoreInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Troona backup, or it is damaged.'**
  String get backupRestoreInvalid;

  /// No description provided for @backupRestoreTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup comes from a newer version of Troona. Update the app, then try again.'**
  String get backupRestoreTooNew;

  /// No description provided for @backupRestoreDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get backupRestoreDoneTitle;

  /// No description provided for @backupRestoreDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you chose is restored.'**
  String get backupRestoreDoneBody;

  /// No description provided for @backupRestoreFound.
  ///
  /// In en, this message translates to:
  /// **'Songs found on this phone: {found} of {total}.'**
  String backupRestoreFound(int found, int total);

  /// No description provided for @backupRestoreMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song is not on this phone. Add it, then restore the same file again to link it.} other{{count} songs are not on this phone. Add them, then restore the same file again to link them.}}'**
  String backupRestoreMissing(int count);

  /// No description provided for @backupRestoreMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String backupRestoreMore(int count);

  /// No description provided for @backupRestoreOnline.
  ///
  /// In en, this message translates to:
  /// **'Online extras were on in this backup. They stay as they are on this phone: turn them on in Settings if you want them.'**
  String get backupRestoreOnline;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupTitle;

  /// No description provided for @backupSettingsLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String backupSettingsLast(String date);

  /// No description provided for @backupSettingsNone.
  ///
  /// In en, this message translates to:
  /// **'Playlists, likes, history and settings'**
  String get backupSettingsNone;

  /// No description provided for @backupAutoSection.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupAutoSection;

  /// No description provided for @backupAuto.
  ///
  /// In en, this message translates to:
  /// **'Back up automatically'**
  String get backupAuto;

  /// No description provided for @backupAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Into a folder you choose, when you open Troona'**
  String get backupAutoOff;

  /// No description provided for @backupAutoLast.
  ///
  /// In en, this message translates to:
  /// **'Last one: {date}'**
  String backupAutoLast(String date);

  /// No description provided for @backupAutoNone.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get backupAutoNone;

  /// No description provided for @backupFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get backupFrequency;

  /// No description provided for @backupDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get backupDaily;

  /// No description provided for @backupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get backupWeekly;

  /// No description provided for @backupFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get backupFolder;

  /// No description provided for @backupFolderChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get backupFolderChoose;

  /// No description provided for @backupFolderLost.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {name}. Choose it again.'**
  String backupFolderLost(String name);

  /// No description provided for @backupFolderFooter.
  ///
  /// In en, this message translates to:
  /// **'Troona keeps its last 5 automatic backups there, and every backup you make. The folder stays if you uninstall Troona: choose it again after reinstalling to find your backups.'**
  String get backupFolderFooter;

  /// No description provided for @backupManualSection.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backupManualSection;

  /// No description provided for @backupParts.
  ///
  /// In en, this message translates to:
  /// **'What to back up'**
  String get backupParts;

  /// No description provided for @backupPartsEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get backupPartsEverything;

  /// No description provided for @backupPartHistory.
  ///
  /// In en, this message translates to:
  /// **'Listening history'**
  String get backupPartHistory;

  /// No description provided for @backupPartSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get backupPartSettings;

  /// No description provided for @backupPartLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get backupPartLyrics;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupNowInto.
  ///
  /// In en, this message translates to:
  /// **'Into {name}'**
  String backupNowInto(String name);

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupRestoreSection.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreSection;

  /// No description provided for @backupNone.
  ///
  /// In en, this message translates to:
  /// **'No backups in this folder yet'**
  String get backupNone;

  /// No description provided for @backupFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from a file'**
  String get backupFromFile;

  /// No description provided for @backupFromFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A backup saved elsewhere, or from another phone'**
  String get backupFromFileSubtitle;

  /// No description provided for @backupAutoBadge.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get backupAutoBadge;

  /// No description provided for @backupOptions.
  ///
  /// In en, this message translates to:
  /// **'Backup options'**
  String get backupOptions;

  /// No description provided for @backupShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get backupShare;

  /// No description provided for @backupDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this backup?'**
  String get backupDeleteTitle;

  /// No description provided for @backupDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It is deleted from {name}.'**
  String backupDeleteBody(String name);

  /// No description provided for @backupSummaryPlaylists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 playlist} other{{count} playlists}}'**
  String backupSummaryPlaylists(int count);

  /// No description provided for @backupSummaryLikes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 liked song} other{{count} liked songs}}'**
  String backupSummaryLikes(int count);

  /// No description provided for @backupSummaryPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String backupSummaryPlays(int count);

  /// No description provided for @backupSummaryLyrics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Lyrics or timing for 1 song} other{Lyrics or timing for {count} songs}}'**
  String backupSummaryLyrics(int count);

  /// No description provided for @backupSummaryProfiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Its setting, no saved profile} =1{Its setting and 1 profile} other{Its setting and {count} profiles}}'**
  String backupSummaryProfiles(int count);

  /// No description provided for @backupSettingsReplace.
  ///
  /// In en, this message translates to:
  /// **'They replace yours'**
  String get backupSettingsReplace;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreFrom.
  ///
  /// In en, this message translates to:
  /// **'Made {date}. Playlists, likes and history are added to yours; settings and the equalizer replace yours.'**
  String backupRestoreFrom(String date);

  /// No description provided for @backupRestoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreButton;

  /// No description provided for @backupRestoreNothing.
  ///
  /// In en, this message translates to:
  /// **'This backup holds nothing to restore.'**
  String get backupRestoreNothing;

  /// No description provided for @backupFolderLostError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the backup folder. Choose it again.'**
  String get backupFolderLostError;

  /// No description provided for @backupAutoFolderLost.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup can\'t reach its folder. Choose it again in Settings, Backup & restore.'**
  String get backupAutoFolderLost;

  /// No description provided for @settingsUpdateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsUpdateCheck;

  /// No description provided for @settingsUpdateCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Once a day, on GitHub'**
  String get settingsUpdateCheckSubtitle;

  /// No description provided for @updateCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check for updates now'**
  String get updateCheckNow;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Troona is up to date'**
  String get updateUpToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. Try again later.'**
  String get updateCheckFailed;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Troona {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Download it from its release page on GitHub.'**
  String get updateAvailableBody;

  /// No description provided for @updateView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get updateView;

  /// No description provided for @updateSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get updateSkip;

  /// No description provided for @updateOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the browser'**
  String get updateOpenFailed;

  /// No description provided for @privacyUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Update check (off by default)'**
  String get privacyUpdatesTitle;

  /// No description provided for @privacyUpdatesBody.
  ///
  /// In en, this message translates to:
  /// **'When on, Troona asks GitHub once a day for the number of its latest version. \"Check for updates now\" asks once, only when you tap it. GitHub sees your IP address, as with any web request; no data about you or your music is sent. Troona never downloads or installs an update itself: \"View\" opens the release page in your browser.'**
  String get privacyUpdatesBody;

  /// No description provided for @whatsNew110BackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get whatsNew110BackupTitle;

  /// No description provided for @whatsNew110BackupBody.
  ///
  /// In en, this message translates to:
  /// **'Save your playlists, likes, listening history and settings to a file, and bring them back on this phone or a new one. In Settings, under Backup.'**
  String get whatsNew110BackupBody;

  /// No description provided for @whatsNew110UpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Know when Troona updates'**
  String get whatsNew110UpdatesTitle;

  /// No description provided for @whatsNew110UpdatesBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Check for updates in Settings: a card on Home tells you when a new version is out. Off by default, nothing is installed for you.'**
  String get whatsNew110UpdatesBody;

  /// No description provided for @whatsNew110ControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Like and resume from the lock screen'**
  String get whatsNew110ControlsTitle;

  /// No description provided for @whatsNew110ControlsBody.
  ///
  /// In en, this message translates to:
  /// **'A heart in the media notification likes the current song (Android 13 and later). After Troona is closed, the media controls resume your last song (Android 11 and later).'**
  String get whatsNew110ControlsBody;

  /// No description provided for @whatsNew110RenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename a playlist'**
  String get whatsNew110RenameTitle;

  /// No description provided for @whatsNew110RenameBody.
  ///
  /// In en, this message translates to:
  /// **'Long press a playlist, then Edit playlist.'**
  String get whatsNew110RenameBody;

  /// No description provided for @whatsNew110ScreensTitle.
  ///
  /// In en, this message translates to:
  /// **'Small screens and large fonts'**
  String get whatsNew110ScreensTitle;

  /// No description provided for @whatsNew110ScreensBody.
  ///
  /// In en, this message translates to:
  /// **'Now Playing keeps its controls on screen on smaller phones, and the whole app follows your phone\'s font size.'**
  String get whatsNew110ScreensBody;

  /// No description provided for @whatsNew110NotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification icon'**
  String get whatsNew110NotificationTitle;

  /// No description provided for @whatsNew110NotificationBody.
  ///
  /// In en, this message translates to:
  /// **'The playback notification shows the Troona note in the status bar.'**
  String get whatsNew110NotificationBody;

  /// No description provided for @whatsNew111ChangelogTitle.
  ///
  /// In en, this message translates to:
  /// **'Every release in one place'**
  String get whatsNew111ChangelogTitle;

  /// No description provided for @whatsNew111ChangelogBody.
  ///
  /// In en, this message translates to:
  /// **'What\'s new now keeps the notes of every version, the newest first. Open it any time from Settings, under Help and feedback.'**
  String get whatsNew111ChangelogBody;

  /// No description provided for @whatsNew111StartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Reliable start'**
  String get whatsNew111StartupTitle;

  /// No description provided for @whatsNew111StartupBody.
  ///
  /// In en, this message translates to:
  /// **'Troona no longer stays on its launch screen when you open it after resuming music from the media controls or a headset.'**
  String get whatsNew111StartupBody;

  /// No description provided for @whatsNew111HomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home right after the first scan'**
  String get whatsNew111HomeTitle;

  /// No description provided for @whatsNew111HomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your music shows on Home as soon as the first scan finds it, without refreshing.'**
  String get whatsNew111HomeBody;

  /// No description provided for @whatsNew120ArtistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Artists from file names'**
  String get whatsNew120ArtistsTitle;

  /// No description provided for @whatsNew120ArtistsBody.
  ///
  /// In en, this message translates to:
  /// **'Songs downloaded without an artist take it from their file name, such as \"Artist - Title\", and sit with that artist\'s other songs. The rest read Unknown artist, in your language.'**
  String get whatsNew120ArtistsBody;

  /// No description provided for @whatsNew120UndoTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo a replaced queue'**
  String get whatsNew120UndoTitle;

  /// No description provided for @whatsNew120UndoBody.
  ///
  /// In en, this message translates to:
  /// **'Starting another album while songs you added with Play next or Add to queue are still to come now offers Undo, which brings your queue back where it was.'**
  String get whatsNew120UndoBody;

  /// No description provided for @whatsNew120MenusTitle.
  ///
  /// In en, this message translates to:
  /// **'Menus and dialogs'**
  String get whatsNew120MenusTitle;

  /// No description provided for @whatsNew120MenusBody.
  ///
  /// In en, this message translates to:
  /// **'Song, album and playlist menus open as a sheet in Troona\'s style, and dialogs fade in smoothly.'**
  String get whatsNew120MenusBody;

  /// No description provided for @whatsNew120LookTitle.
  ///
  /// In en, this message translates to:
  /// **'One look across the app'**
  String get whatsNew120LookTitle;

  /// No description provided for @whatsNew120LookBody.
  ///
  /// In en, this message translates to:
  /// **'Icons, buttons, back buttons and missing covers look the same on every screen, and buttons are easier to tap.'**
  String get whatsNew120LookBody;

  /// No description provided for @whatsNew120PagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pages that slide in'**
  String get whatsNew120PagesTitle;

  /// No description provided for @whatsNew120PagesBody.
  ///
  /// In en, this message translates to:
  /// **'Settings, the privacy policy and Your week in music no longer show the previous page through them while they open.'**
  String get whatsNew120PagesBody;

  /// No description provided for @whatsNew130ArtistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Every artist of a song'**
  String get whatsNew130ArtistsTitle;

  /// No description provided for @whatsNew130ArtistsBody.
  ///
  /// In en, this message translates to:
  /// **'A song by several artists, such as \"Nicki Minaj, Beyoncé\" or \"Chiké feat Mohbad\", now counts for each of them: it shows on every artist\'s page and search finds each one. Names such as \"Tyler, The Creator\" stay one artist.'**
  String get whatsNew130ArtistsBody;

  /// No description provided for @whatsNew130ArtistPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist pages'**
  String get whatsNew130ArtistPageTitle;

  /// No description provided for @whatsNew130ArtistPageBody.
  ///
  /// In en, this message translates to:
  /// **'An artist\'s page starts with their five most played songs, then their albums, their singles, the albums they appear on and similar artists from your library.'**
  String get whatsNew130ArtistPageBody;

  /// No description provided for @whatsNew130AlbumPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Album pages'**
  String get whatsNew130AlbumPageTitle;

  /// No description provided for @whatsNew130AlbumPageBody.
  ///
  /// In en, this message translates to:
  /// **'Albums show their year, and downloaded songs without track numbers come in the order they were downloaded. Guests a title does not name show under it.'**
  String get whatsNew130AlbumPageBody;

  /// No description provided for @whatsNew130AboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About, when there is something to read'**
  String get whatsNew130AboutTitle;

  /// No description provided for @whatsNew130AboutBody.
  ///
  /// In en, this message translates to:
  /// **'With online info turned on, About shows only when Last.fm has a bio or a review, with the listeners and a few genres under it.'**
  String get whatsNew130AboutBody;

  /// No description provided for @whatsNew130AlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'One album, not several copies'**
  String get whatsNew130AlbumsTitle;

  /// No description provided for @whatsNew130AlbumsBody.
  ///
  /// In en, this message translates to:
  /// **'An album downloaded in several folders, or singles saved one folder each, showed up several times. It is one album again, and its year shows.'**
  String get whatsNew130AlbumsBody;

  /// No description provided for @whatsNew140TopTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to the top'**
  String get whatsNew140TopTitle;

  /// No description provided for @whatsNew140TopBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the tab you are on to scroll its page back to the top.'**
  String get whatsNew140TopBody;

  /// No description provided for @whatsNew140EdgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edge to edge'**
  String get whatsNew140EdgeTitle;

  /// No description provided for @whatsNew140EdgeBody.
  ///
  /// In en, this message translates to:
  /// **'Lists now scroll under the status bar and the floating tab bar, on every Android version, and fade out softly under the tab bar instead of stopping on a line.'**
  String get whatsNew140EdgeBody;

  /// No description provided for @whatsNew140TitlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Large titles'**
  String get whatsNew140TitlesTitle;

  /// No description provided for @whatsNew140TitlesBody.
  ///
  /// In en, this message translates to:
  /// **'Every page opens on a large title that shrinks into a glass bar as you scroll, with the back button and the page\'s actions. A title left halfway settles open or closed.'**
  String get whatsNew140TitlesBody;

  /// No description provided for @whatsNew140CoversTitle.
  ///
  /// In en, this message translates to:
  /// **'Album and playlist pages'**
  String get whatsNew140CoversTitle;

  /// No description provided for @whatsNew140CoversBody.
  ///
  /// In en, this message translates to:
  /// **'Their cover and buttons scroll away under the same glass bar, which then shows their name.'**
  String get whatsNew140CoversBody;

  /// No description provided for @whatsNew140ArtistPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist photos'**
  String get whatsNew140ArtistPhotoTitle;

  /// No description provided for @whatsNew140ArtistPhotoBody.
  ///
  /// In en, this message translates to:
  /// **'An artist with a photo opens on it, edge to edge, with their name over it. Pull down to enlarge it.'**
  String get whatsNew140ArtistPhotoBody;

  /// No description provided for @whatsNew140SearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get whatsNew140SearchTitle;

  /// No description provided for @whatsNew140SearchBody.
  ///
  /// In en, this message translates to:
  /// **'The search field stays pinned at the top in a glass bar while the results scroll under it, and scrolling the results closes the keyboard.'**
  String get whatsNew140SearchBody;

  /// No description provided for @whatsNew150CoverTitle.
  ///
  /// In en, this message translates to:
  /// **'The cover flies in'**
  String get whatsNew150CoverTitle;

  /// No description provided for @whatsNew150CoverBody.
  ///
  /// In en, this message translates to:
  /// **'Tap an album and its cover flies from the card into place on the album page, then back when you leave.'**
  String get whatsNew150CoverBody;

  /// No description provided for @whatsNew150TitlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Bold titles'**
  String get whatsNew150TitlesTitle;

  /// No description provided for @whatsNew150TitlesBody.
  ///
  /// In en, this message translates to:
  /// **'Large titles are bold, in the same voice as album and artist names and section titles.'**
  String get whatsNew150TitlesBody;

  /// No description provided for @whatsNew150TabTitle.
  ///
  /// In en, this message translates to:
  /// **'A dot under the tab'**
  String get whatsNew150TabTitle;

  /// No description provided for @whatsNew150TabBody.
  ///
  /// In en, this message translates to:
  /// **'The tab you are on shows a dot under its icon, not only a brighter colour.'**
  String get whatsNew150TabBody;

  /// No description provided for @whatsNew150PagesTitle.
  ///
  /// In en, this message translates to:
  /// **'One line of facts'**
  String get whatsNew150PagesTitle;

  /// No description provided for @whatsNew150PagesBody.
  ///
  /// In en, this message translates to:
  /// **'Album pages state their year, song count and length, and artist pages their song count, releases and length, as one line of text instead of pills. Lossless keeps its badge.'**
  String get whatsNew150PagesBody;

  /// No description provided for @whatsNew150AlbumTitle.
  ///
  /// In en, this message translates to:
  /// **'Album pages'**
  String get whatsNew150AlbumTitle;

  /// No description provided for @whatsNew150AlbumBody.
  ///
  /// In en, this message translates to:
  /// **'The track list no longer has a Songs title. Under the songs, a quiet line gives the album\'s size and formats instead of the In your library card.'**
  String get whatsNew150AlbumBody;

  /// No description provided for @whatsNew150ArtistTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist pages'**
  String get whatsNew150ArtistTitle;

  /// No description provided for @whatsNew150ArtistBody.
  ///
  /// In en, this message translates to:
  /// **'Each song shows its album and year under its title instead of the artist\'s name again, and album and single cards give the year. The In your library card is gone: its counts are under the name.'**
  String get whatsNew150ArtistBody;

  /// No description provided for @whatsNew150MoreByTitle.
  ///
  /// In en, this message translates to:
  /// **'More by'**
  String get whatsNew150MoreByTitle;

  /// No description provided for @whatsNew150MoreByBody.
  ///
  /// In en, this message translates to:
  /// **'On album pages, More by gives each album\'s year instead of the artist\'s name, with Single on singles.'**
  String get whatsNew150MoreByBody;

  /// No description provided for @whatsNew150LibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'A lighter Library'**
  String get whatsNew150LibraryTitle;

  /// No description provided for @whatsNew150LibraryBody.
  ///
  /// In en, this message translates to:
  /// **'The Library no longer shows its counts of songs, albums and artists above All.'**
  String get whatsNew150LibraryBody;

  /// No description provided for @whatsNew150BackTitle.
  ///
  /// In en, this message translates to:
  /// **'Back where you came from'**
  String get whatsNew150BackTitle;

  /// No description provided for @whatsNew150BackBody.
  ///
  /// In en, this message translates to:
  /// **'Open an album\'s artist when you came from that artist, and you go back to their page instead of opening it again. The same goes the other way round.'**
  String get whatsNew150BackBody;

  /// No description provided for @whatsNew150ScrollTitle.
  ///
  /// In en, this message translates to:
  /// **'No empty band'**
  String get whatsNew150ScrollTitle;

  /// No description provided for @whatsNew150ScrollBody.
  ///
  /// In en, this message translates to:
  /// **'An album or playlist page keeps its cover and buttons in sight while they scroll away, instead of leaving an empty band under the bar.'**
  String get whatsNew150ScrollBody;

  /// No description provided for @whatsNew150NamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist names with a large font'**
  String get whatsNew150NamesTitle;

  /// No description provided for @whatsNew150NamesBody.
  ///
  /// In en, this message translates to:
  /// **'With a large font, the Library\'s row of artists no longer cuts their names short.'**
  String get whatsNew150NamesBody;

  /// No description provided for @whatsNew160RecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Your listening'**
  String get whatsNew160RecapTitle;

  /// No description provided for @whatsNew160RecapBody.
  ///
  /// In en, this message translates to:
  /// **'Any week or month at a glance: your listening time, the days you played music, your top songs, artist and albums. Open it from the card on Home, and step back with the arrows.'**
  String get whatsNew160RecapBody;

  /// No description provided for @whatsNew160StoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Share it as a story'**
  String get whatsNew160StoryTitle;

  /// No description provided for @whatsNew160StoryBody.
  ///
  /// In en, this message translates to:
  /// **'Turn a week or a month into an image for your stories, over your top song\'s colours. A finished month is shared as its Replay.'**
  String get whatsNew160StoryBody;

  /// No description provided for @whatsNew160SwipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe a song'**
  String get whatsNew160SwipeTitle;

  /// No description provided for @whatsNew160SwipeBody.
  ///
  /// In en, this message translates to:
  /// **'In the Library, albums, artists and search, swipe a song right to play it next, or left to add it to the queue.'**
  String get whatsNew160SwipeBody;

  /// No description provided for @whatsNew160MiniPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe and hold the mini player'**
  String get whatsNew160MiniPlayerTitle;

  /// No description provided for @whatsNew160MiniPlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Swipe it left for the next song or right for the previous one. Hold it to like the song playing, or to take the like back.'**
  String get whatsNew160MiniPlayerBody;

  /// No description provided for @whatsNew160CalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'A calendar of your listening'**
  String get whatsNew160CalendarTitle;

  /// No description provided for @whatsNew160CalendarBody.
  ///
  /// In en, this message translates to:
  /// **'Each day is a square, filled in five steps from no music to 30 plays or more. Tap a day for its count.'**
  String get whatsNew160CalendarBody;

  /// No description provided for @whatsNew160MomentsTitle.
  ///
  /// In en, this message translates to:
  /// **'When you listen'**
  String get whatsNew160MomentsTitle;

  /// No description provided for @whatsNew160MomentsBody.
  ///
  /// In en, this message translates to:
  /// **'Your plays by weekday and time of day, with the moment that stands out, such as Friday evening. Songs played after midnight count for the night before.'**
  String get whatsNew160MomentsBody;

  /// No description provided for @whatsNew160RecordTitle.
  ///
  /// In en, this message translates to:
  /// **'The record turns'**
  String get whatsNew160RecordTitle;

  /// No description provided for @whatsNew160RecordBody.
  ///
  /// In en, this message translates to:
  /// **'On an album page, the record slides out of its sleeve and turns while the album plays. Tap it to play, pause or resume.'**
  String get whatsNew160RecordBody;

  /// No description provided for @whatsNew160LatestTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest release'**
  String get whatsNew160LatestTitle;

  /// No description provided for @whatsNew160LatestBody.
  ///
  /// In en, this message translates to:
  /// **'Artist pages show their newest album or single on its own, above the rest.'**
  String get whatsNew160LatestBody;

  /// No description provided for @whatsNew160ResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get whatsNew160ResumeTitle;

  /// No description provided for @whatsNew160ResumeBody.
  ///
  /// In en, this message translates to:
  /// **'Jump back in on Home goes on from where the song stopped, with the album, artist or playlist it came from and the time left. While music plays, it opens Now Playing.'**
  String get whatsNew160ResumeBody;

  /// No description provided for @whatsNew160ArtistTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist pages'**
  String get whatsNew160ArtistTitle;

  /// No description provided for @whatsNew160ArtistBody.
  ///
  /// In en, this message translates to:
  /// **'One round Shuffle button on their photo, since an artist\'s songs have no order; tap a song to play in order from it. Releases come newest first, also in More by on album pages. An artist without a photo opens on a soft glow of their cover\'s colours.'**
  String get whatsNew160ArtistBody;

  /// No description provided for @whatsNew160PlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'The song playing looks the same everywhere'**
  String get whatsNew160PlayingTitle;

  /// No description provided for @whatsNew160PlayingBody.
  ///
  /// In en, this message translates to:
  /// **'In every list, its cover is dimmed under the moving equalizer, which stops while paused, and its title is in the accent colour.'**
  String get whatsNew160PlayingBody;

  /// No description provided for @whatsNew160HapticsTitle.
  ///
  /// In en, this message translates to:
  /// **'One feel for haptics'**
  String get whatsNew160HapticsTitle;

  /// No description provided for @whatsNew160HapticsBody.
  ///
  /// In en, this message translates to:
  /// **'A firm tap when playback starts or stops, a light one for a skip, a refresh or a menu, and a tick for a choice. Playing a song no longer taps twice.'**
  String get whatsNew160HapticsBody;

  /// No description provided for @whatsNew160BackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'A calmer background'**
  String get whatsNew160BackgroundTitle;

  /// No description provided for @whatsNew160BackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'The colours behind the tabs take two seconds to follow a new song instead of switching at once.'**
  String get whatsNew160BackgroundBody;

  /// No description provided for @whatsNew160BackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get whatsNew160BackupTitle;

  /// No description provided for @whatsNew160BackupBody.
  ///
  /// In en, this message translates to:
  /// **'They now also carry when you listen.'**
  String get whatsNew160BackupBody;

  /// No description provided for @whatsNew160HapticsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrations with haptics off'**
  String get whatsNew160HapticsOffTitle;

  /// No description provided for @whatsNew160HapticsOffBody.
  ///
  /// In en, this message translates to:
  /// **'The Library\'s tabs at the top vibrated even with haptics turned off in Settings. They now follow the setting.'**
  String get whatsNew160HapticsOffBody;

  /// No description provided for @whatsNew170IndexTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump by letter'**
  String get whatsNew170IndexTitle;

  /// No description provided for @whatsNew170IndexBody.
  ///
  /// In en, this message translates to:
  /// **'Songs, albums and artists sorted by name have an alphabetical index down the right edge.'**
  String get whatsNew170IndexBody;

  /// No description provided for @whatsNew170RecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get whatsNew170RecentTitle;

  /// No description provided for @whatsNew170RecentBody.
  ///
  /// In en, this message translates to:
  /// **'The songs and albums added last, newest first, from Search and Home.'**
  String get whatsNew170RecentBody;

  /// No description provided for @whatsNew170ArtistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Closer to the artists'**
  String get whatsNew170ArtistsTitle;

  /// No description provided for @whatsNew170ArtistsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the artist\'s name in Now Playing to open their page. Their photo grows from the card into the page.'**
  String get whatsNew170ArtistsBody;

  /// No description provided for @whatsNew170AlbumMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Album shortcuts'**
  String get whatsNew170AlbumMenuTitle;

  /// No description provided for @whatsNew170AlbumMenuBody.
  ///
  /// In en, this message translates to:
  /// **'Hold an album card for Play, Shuffle, Play next and Add to queue.'**
  String get whatsNew170AlbumMenuBody;

  /// No description provided for @whatsNew170NowPlayingTitle.
  ///
  /// In en, this message translates to:
  /// **'A smoother Now Playing'**
  String get whatsNew170NowPlayingTitle;

  /// No description provided for @whatsNew170NowPlayingBody.
  ///
  /// In en, this message translates to:
  /// **'Seeking lights up the ring, and closing sends the cover back into the mini player.'**
  String get whatsNew170NowPlayingBody;

  /// No description provided for @whatsNew170ColoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Pages in their own colours'**
  String get whatsNew170ColoursTitle;

  /// No description provided for @whatsNew170ColoursBody.
  ///
  /// In en, this message translates to:
  /// **'Album and artist pages take the colours of their cover, and open in the tab you are in.'**
  String get whatsNew170ColoursBody;

  /// No description provided for @whatsNew170HomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A lighter Home'**
  String get whatsNew170HomeTitle;

  /// No description provided for @whatsNew170HomeBody.
  ///
  /// In en, this message translates to:
  /// **'Music comes first, with one card about the app at a time.'**
  String get whatsNew170HomeBody;

  /// No description provided for @whatsNew170QueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queueing with nothing playing'**
  String get whatsNew170QueueTitle;

  /// No description provided for @whatsNew170QueueBody.
  ///
  /// In en, this message translates to:
  /// **'Play next and Add to queue now start the music when nothing plays, and an album goes into the queue whole.'**
  String get whatsNew170QueueBody;

  /// No description provided for @whatsNew170PhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist photos'**
  String get whatsNew170PhotosTitle;

  /// No description provided for @whatsNew170PhotosBody.
  ///
  /// In en, this message translates to:
  /// **'No more grey silhouettes or photos of namesakes, and Search shows the downloaded photos.'**
  String get whatsNew170PhotosBody;

  /// No description provided for @whatsNew190LyricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Synced lyrics'**
  String get whatsNew190LyricsTitle;

  /// No description provided for @whatsNew190LyricsBody.
  ///
  /// In en, this message translates to:
  /// **'In Now Playing, the Lyrics button shows the words, the line sung lit and followed. Import a .lrc file, or turn on the lyrics search in Settings > Online extras.'**
  String get whatsNew190LyricsBody;

  /// No description provided for @whatsNew190OpenWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Open with Troona'**
  String get whatsNew190OpenWithTitle;

  /// No description provided for @whatsNew190OpenWithBody.
  ///
  /// In en, this message translates to:
  /// **'Touch an audio file in a file manager or after a download: Troona plays it as the song of your library.'**
  String get whatsNew190OpenWithBody;

  /// No description provided for @whatsNew190BackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups'**
  String get whatsNew190BackupTitle;

  /// No description provided for @whatsNew190BackupBody.
  ///
  /// In en, this message translates to:
  /// **'Daily or weekly, into a folder you pick once, kept even if you uninstall Troona. Choose what each backup holds. In Settings > Backup & restore.'**
  String get whatsNew190BackupBody;

  /// No description provided for @whatsNew190FiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep folders out'**
  String get whatsNew190FiltersTitle;

  /// No description provided for @whatsNew190FiltersBody.
  ///
  /// In en, this message translates to:
  /// **'Leave voice notes or podcasts out of your library, and choose the shortest song kept. Turn a folder back on and its likes, plays and playlists come back. In Settings > Library.'**
  String get whatsNew190FiltersBody;

  /// No description provided for @whatsNew190HistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause your history'**
  String get whatsNew190HistoryTitle;

  /// No description provided for @whatsNew190HistoryBody.
  ///
  /// In en, this message translates to:
  /// **'While it is paused, the songs you play are not recorded. In Settings > Library.'**
  String get whatsNew190HistoryBody;

  /// No description provided for @whatsNew190SettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings, reorganised'**
  String get whatsNew190SettingsTitle;

  /// No description provided for @whatsNew190SettingsBody.
  ///
  /// In en, this message translates to:
  /// **'One page per subject, each row saying how it stands. Choose Troona\'s language, keep shuffle on or not, and find Help in About.'**
  String get whatsNew190SettingsBody;

  /// No description provided for @whatsNew190CoversTitle.
  ///
  /// In en, this message translates to:
  /// **'Covers come back'**
  String get whatsNew190CoversTitle;

  /// No description provided for @whatsNew190CoversBody.
  ///
  /// In en, this message translates to:
  /// **'After Android or Clear cache emptied Troona\'s cache, covers are extracted again on the next scan instead of staying blank.'**
  String get whatsNew190CoversBody;

  /// No description provided for @whatsNew190PlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists count right'**
  String get whatsNew190PlaylistsTitle;

  /// No description provided for @whatsNew190PlaylistsBody.
  ///
  /// In en, this message translates to:
  /// **'In a playlist holding songs you left out or deleted, moving a song moves the right one, and counts show only the songs you see.'**
  String get whatsNew190PlaylistsBody;

  /// No description provided for @whatsNew180SmartTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart playlists'**
  String get whatsNew180SmartTitle;

  /// No description provided for @whatsNew180SmartBody.
  ///
  /// In en, this message translates to:
  /// **'Playlists that fill themselves from rules: plays, last played, date added, likes, artist, genre, year and more. Start from a template with the + in Playlists.'**
  String get whatsNew180SmartBody;

  /// No description provided for @whatsNew180SelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick several songs'**
  String get whatsNew180SelectionTitle;

  /// No description provided for @whatsNew180SelectionBody.
  ///
  /// In en, this message translates to:
  /// **'Long press a song to start picking, then tap others. Play them, queue them or add them to a playlist in one go.'**
  String get whatsNew180SelectionBody;

  /// No description provided for @whatsNew180EqualizerTitle.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get whatsNew180EqualizerTitle;

  /// No description provided for @whatsNew180EqualizerBody.
  ///
  /// In en, this message translates to:
  /// **'On Android, from Now Playing or Settings > Playback: draw your curve with a finger or start from a preset, save it, and add up to 6 dB with Volume +.'**
  String get whatsNew180EqualizerBody;

  /// No description provided for @whatsNew180OrbTitle.
  ///
  /// In en, this message translates to:
  /// **'A button in the song\'s colours'**
  String get whatsNew180OrbTitle;

  /// No description provided for @whatsNew180OrbBody.
  ///
  /// In en, this message translates to:
  /// **'The centre of the tab bar glows in the colours of the song playing. Tap it to open Now Playing, or to start music when nothing is loaded.'**
  String get whatsNew180OrbBody;

  /// No description provided for @whatsNew180GlassTitle.
  ///
  /// In en, this message translates to:
  /// **'Glass effects for every phone'**
  String get whatsNew180GlassTitle;

  /// No description provided for @whatsNew180GlassBody.
  ///
  /// In en, this message translates to:
  /// **'Balanced keeps the blur in page headers only and No blur draws none, both with tinted surfaces: smoother scrolling on older phones. In Settings.'**
  String get whatsNew180GlassBody;

  /// No description provided for @whatsNew180MiniPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'A smoother mini player'**
  String get whatsNew180MiniPlayerTitle;

  /// No description provided for @whatsNew180MiniPlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Swipe to the next or previous song and the titles follow your finger while the cover fades. Swipe down to close it.'**
  String get whatsNew180MiniPlayerBody;

  /// No description provided for @whatsNew180ReadableTitle.
  ///
  /// In en, this message translates to:
  /// **'Easier to read'**
  String get whatsNew180ReadableTitle;

  /// No description provided for @whatsNew180ReadableBody.
  ///
  /// In en, this message translates to:
  /// **'Small grey text has more contrast, and Now Playing\'s ring reads over every cover.'**
  String get whatsNew180ReadableBody;

  /// No description provided for @whatsNew180GlassFixTitle.
  ///
  /// In en, this message translates to:
  /// **'Glass settings apply at once'**
  String get whatsNew180GlassFixTitle;

  /// No description provided for @whatsNew180GlassFixBody.
  ///
  /// In en, this message translates to:
  /// **'Changing the glass effects now redraws every screen right away, not only the ones opened afterwards.'**
  String get whatsNew180GlassFixBody;

  /// No description provided for @playlistAddedSongsTo.
  ///
  /// In en, this message translates to:
  /// **'{count} songs added to {name}'**
  String playlistAddedSongsTo(int count, String name);

  /// What a screen reader reads for the selection bar's count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song selected} other{{count} songs selected}}'**
  String selectionSelected(int count);

  /// The word after the rolling count in the selection bar (the number is drawn apart).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{selected} other{selected}}'**
  String selectionSuffix(int count);

  /// No description provided for @selectionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectionSelectAll;

  /// No description provided for @selectionDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get selectionDeselectAll;

  /// No description provided for @selectionEnd.
  ///
  /// In en, this message translates to:
  /// **'End selection'**
  String get selectionEnd;

  /// Screen reader hint for a long press on a song row: it starts picking songs. Read after 'double tap and hold to'.
  ///
  /// In en, this message translates to:
  /// **'pick songs'**
  String get selectionHintStart;

  /// Screen reader hint for a tap on a song row while picking songs, when the song is not picked yet. Read after 'double tap to'.
  ///
  /// In en, this message translates to:
  /// **'select'**
  String get selectionHintPick;

  /// Screen reader hint for a tap on a picked song row while picking songs: it lets the song go. Read after 'double tap to'.
  ///
  /// In en, this message translates to:
  /// **'deselect'**
  String get selectionHintUnpick;

  /// No description provided for @equalizerTitle.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizerTitle;

  /// No description provided for @equalizerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get equalizerOff;

  /// No description provided for @equalizerTurnOnHint.
  ///
  /// In en, this message translates to:
  /// **'Turn the equalizer on to tune it.'**
  String get equalizerTurnOnHint;

  /// No description provided for @equalizerNoBands.
  ///
  /// In en, this message translates to:
  /// **'Play a song to tune the equalizer: your phone tells its bands once one is loaded.'**
  String get equalizerNoBands;

  /// No description provided for @equalizerBandCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 band on this phone.} other{{count} bands on this phone.}}'**
  String equalizerBandCount(int count);

  /// No description provided for @equalizerOtherEffects.
  ///
  /// In en, this message translates to:
  /// **'A system equalizer, such as Dolby, may change the sound too.'**
  String get equalizerOtherEffects;

  /// No description provided for @equalizerPresetFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get equalizerPresetFlat;

  /// No description provided for @equalizerPresetBassBoost.
  ///
  /// In en, this message translates to:
  /// **'Bass boost'**
  String get equalizerPresetBassBoost;

  /// No description provided for @equalizerPresetAcoustic.
  ///
  /// In en, this message translates to:
  /// **'Acoustic'**
  String get equalizerPresetAcoustic;

  /// No description provided for @equalizerPresetElectronic.
  ///
  /// In en, this message translates to:
  /// **'Electronic'**
  String get equalizerPresetElectronic;

  /// No description provided for @equalizerPresetVocal.
  ///
  /// In en, this message translates to:
  /// **'Vocal'**
  String get equalizerPresetVocal;

  /// No description provided for @equalizerPresetRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get equalizerPresetRock;

  /// No description provided for @equalizerPresetHipHop.
  ///
  /// In en, this message translates to:
  /// **'Hip-hop'**
  String get equalizerPresetHipHop;

  /// No description provided for @equalizerPresetJazz.
  ///
  /// In en, this message translates to:
  /// **'Jazz'**
  String get equalizerPresetJazz;

  /// No description provided for @equalizerPresetTrebleBoost.
  ///
  /// In en, this message translates to:
  /// **'Treble boost'**
  String get equalizerPresetTrebleBoost;

  /// No description provided for @equalizerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get equalizerCustom;

  /// No description provided for @equalizerSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get equalizerSaveProfile;

  /// No description provided for @equalizerSaveProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this curve'**
  String get equalizerSaveProfileTitle;

  /// No description provided for @equalizerProfileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get equalizerProfileName;

  /// No description provided for @equalizerProfileRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get equalizerProfileRename;

  /// No description provided for @equalizerProfileUpdate.
  ///
  /// In en, this message translates to:
  /// **'Replace with the current curve'**
  String get equalizerProfileUpdate;

  /// No description provided for @equalizerProfileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String equalizerProfileDeleteTitle(String name);

  /// No description provided for @equalizerProfileDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The curve stays as it is; only its name goes.'**
  String get equalizerProfileDeleteBody;

  /// No description provided for @equalizerCompare.
  ///
  /// In en, this message translates to:
  /// **'Hold to hear without the equalizer'**
  String get equalizerCompare;

  /// No description provided for @equalizerComparing.
  ///
  /// In en, this message translates to:
  /// **'Without the equalizer'**
  String get equalizerComparing;

  /// The loudness boost slider of the equalizer.
  ///
  /// In en, this message translates to:
  /// **'Volume +'**
  String get equalizerBoost;

  /// No description provided for @equalizerAntiClip.
  ///
  /// In en, this message translates to:
  /// **'Avoid clipping'**
  String get equalizerAntiClip;

  /// No description provided for @equalizerAntiClipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lowers the level by as much as the bands boost.'**
  String get equalizerAntiClipSubtitle;

  /// No description provided for @equalizerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset the curve'**
  String get equalizerReset;

  /// A gain, signed: +4 dB, -2 dB, 0 dB.
  ///
  /// In en, this message translates to:
  /// **'{value} dB'**
  String equalizerDecibels(String value);

  /// Screen reader label of an equalizer band.
  ///
  /// In en, this message translates to:
  /// **'{frequency} hertz'**
  String equalizerBandLabel(String frequency);

  /// Screen reader value of an equalizer band, signed: +4 decibels.
  ///
  /// In en, this message translates to:
  /// **'{value} decibels'**
  String equalizerBandValue(String value);

  /// Name a new playlist starts with, selected so typing replaces it.
  ///
  /// In en, this message translates to:
  /// **'My playlist #{number}'**
  String playlistDefaultName(int number);

  /// No description provided for @playlistsCreatePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistsCreatePlaylist;

  /// No description provided for @playlistsCreateSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart playlist'**
  String get playlistsCreateSmart;

  /// Subtitle of a smart playlist's card and row, in place of its song count.
  ///
  /// In en, this message translates to:
  /// **'Smart playlist'**
  String get smartPlaylistKind;

  /// No description provided for @smartPlaylistNew.
  ///
  /// In en, this message translates to:
  /// **'New smart playlist'**
  String get smartPlaylistNew;

  /// No description provided for @smartPlaylistEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit rules'**
  String get smartPlaylistEdit;

  /// Badge on a smart playlist, whose songs are chosen by rules.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get smartBadge;

  /// No description provided for @smartStartFrom.
  ///
  /// In en, this message translates to:
  /// **'Start from'**
  String get smartStartFrom;

  /// No description provided for @smartTemplateTopMonth.
  ///
  /// In en, this message translates to:
  /// **'Most played this month'**
  String get smartTemplateTopMonth;

  /// No description provided for @smartTemplateNeverPlayed.
  ///
  /// In en, this message translates to:
  /// **'Never played'**
  String get smartTemplateNeverPlayed;

  /// No description provided for @smartTemplateForgotten.
  ///
  /// In en, this message translates to:
  /// **'Forgotten'**
  String get smartTemplateForgotten;

  /// No description provided for @smartTemplateRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get smartTemplateRecent;

  /// No description provided for @smartTemplateLossless.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get smartTemplateLossless;

  /// No description provided for @smartKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep songs that match'**
  String get smartKeep;

  /// No description provided for @smartMatchAll.
  ///
  /// In en, this message translates to:
  /// **'All rules'**
  String get smartMatchAll;

  /// No description provided for @smartMatchAny.
  ///
  /// In en, this message translates to:
  /// **'Any rule'**
  String get smartMatchAny;

  /// No description provided for @smartRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get smartRules;

  /// No description provided for @smartNoRules.
  ///
  /// In en, this message translates to:
  /// **'No rules: every song is kept.'**
  String get smartNoRules;

  /// No description provided for @smartAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add a rule'**
  String get smartAddRule;

  /// No description provided for @smartRemoveRule.
  ///
  /// In en, this message translates to:
  /// **'Remove this rule'**
  String get smartRemoveRule;

  /// No description provided for @smartSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get smartSortBy;

  /// No description provided for @smartLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get smartLimit;

  /// No description provided for @smartNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get smartNoLimit;

  /// No description provided for @smartLimitSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String smartLimitSongs(int count);

  /// No description provided for @smartMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs match} =1{1 song matches} other{{count} songs match}}'**
  String smartMatchCount(int count);

  /// No description provided for @smartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No songs match yet'**
  String get smartEmptyTitle;

  /// No description provided for @smartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'What you play and add may change that, or you can loosen the rules.'**
  String get smartEmptyBody;

  /// No description provided for @smartSaveAsPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Save as a playlist'**
  String get smartSaveAsPlaylist;

  /// No description provided for @smartSavedAsPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}'**
  String smartSavedAsPlaylist(String name);

  /// No description provided for @smartFootnote.
  ///
  /// In en, this message translates to:
  /// **'The songs are worked out again each time you open it.'**
  String get smartFootnote;

  /// No description provided for @smartRulePlays.
  ///
  /// In en, this message translates to:
  /// **'Plays'**
  String get smartRulePlays;

  /// No description provided for @smartRuleLastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Last played'**
  String get smartRuleLastPlayed;

  /// No description provided for @smartRuleAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get smartRuleAdded;

  /// No description provided for @smartRuleLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get smartRuleLiked;

  /// No description provided for @smartRuleArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get smartRuleArtist;

  /// No description provided for @smartRuleAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get smartRuleAlbum;

  /// No description provided for @smartRuleGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get smartRuleGenre;

  /// No description provided for @smartRuleYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get smartRuleYear;

  /// No description provided for @smartRuleDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get smartRuleDuration;

  /// No description provided for @smartRuleLossless.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get smartRuleLossless;

  /// No description provided for @smartPlaysAtLeast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Played at least once} other{Played at least {count} times}} in {days} days'**
  String smartPlaysAtLeast(int count, int days);

  /// No description provided for @smartPlaysNone.
  ///
  /// In en, this message translates to:
  /// **'Not played in {days} days'**
  String smartPlaysNone(int days);

  /// No description provided for @smartLastPlayedOlder.
  ///
  /// In en, this message translates to:
  /// **'Last played over {days} days ago'**
  String smartLastPlayedOlder(int days);

  /// No description provided for @smartLastPlayedWithin.
  ///
  /// In en, this message translates to:
  /// **'Played in the last {days} days'**
  String smartLastPlayedWithin(int days);

  /// No description provided for @smartNeverPlayed.
  ///
  /// In en, this message translates to:
  /// **'Never played'**
  String get smartNeverPlayed;

  /// No description provided for @smartAddedWithin.
  ///
  /// In en, this message translates to:
  /// **'Added in the last {days} days'**
  String smartAddedWithin(int days);

  /// No description provided for @smartLikedYes.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get smartLikedYes;

  /// No description provided for @smartLikedNo.
  ///
  /// In en, this message translates to:
  /// **'Not liked'**
  String get smartLikedNo;

  /// No description provided for @smartTextContains.
  ///
  /// In en, this message translates to:
  /// **'{field} contains \"{text}\"'**
  String smartTextContains(String field, String text);

  /// No description provided for @smartTextNotContains.
  ///
  /// In en, this message translates to:
  /// **'{field} doesn\'t contain \"{text}\"'**
  String smartTextNotContains(String field, String text);

  /// No description provided for @smartYearRange.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}'**
  String smartYearRange(String from, String to);

  /// No description provided for @smartYearFrom.
  ///
  /// In en, this message translates to:
  /// **'{year} or later'**
  String smartYearFrom(String year);

  /// No description provided for @smartYearTo.
  ///
  /// In en, this message translates to:
  /// **'{year} or earlier'**
  String smartYearTo(String year);

  /// No description provided for @smartDurationUnder.
  ///
  /// In en, this message translates to:
  /// **'Under {minutes} min'**
  String smartDurationUnder(int minutes);

  /// No description provided for @smartDurationOver.
  ///
  /// In en, this message translates to:
  /// **'Over {minutes} min'**
  String smartDurationOver(int minutes);

  /// No description provided for @smartDurationBetween.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} min'**
  String smartDurationBetween(int min, int max);

  /// No description provided for @smartLosslessYes.
  ///
  /// In en, this message translates to:
  /// **'Lossless'**
  String get smartLosslessYes;

  /// No description provided for @smartLosslessNo.
  ///
  /// In en, this message translates to:
  /// **'Not lossless'**
  String get smartLosslessNo;

  /// No description provided for @smartContains.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get smartContains;

  /// No description provided for @smartNotContains.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t contain'**
  String get smartNotContains;

  /// No description provided for @smartTextHint.
  ///
  /// In en, this message translates to:
  /// **'Text to look for'**
  String get smartTextHint;

  /// No description provided for @smartDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String smartDays(int days);

  /// No description provided for @smartOverLast.
  ///
  /// In en, this message translates to:
  /// **'Over the last'**
  String get smartOverLast;

  /// No description provided for @smartSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get smartSortTitle;

  /// No description provided for @smartSortArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get smartSortArtist;

  /// No description provided for @smartSortAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get smartSortAlbum;

  /// No description provided for @smartSortYear.
  ///
  /// In en, this message translates to:
  /// **'Year, newest first'**
  String get smartSortYear;

  /// No description provided for @smartSortAddedNewest.
  ///
  /// In en, this message translates to:
  /// **'Date added, newest first'**
  String get smartSortAddedNewest;

  /// No description provided for @smartSortAddedOldest.
  ///
  /// In en, this message translates to:
  /// **'Date added, oldest first'**
  String get smartSortAddedOldest;

  /// No description provided for @smartSortMostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get smartSortMostPlayed;

  /// No description provided for @smartSortMostPlayedMonth.
  ///
  /// In en, this message translates to:
  /// **'Most played, last 30 days'**
  String get smartSortMostPlayedMonth;

  /// No description provided for @smartSortLeastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Least played'**
  String get smartSortLeastPlayed;

  /// No description provided for @smartSortLastPlayedRecent.
  ///
  /// In en, this message translates to:
  /// **'Played most recently'**
  String get smartSortLastPlayedRecent;

  /// No description provided for @smartSortLastPlayedOldest.
  ///
  /// In en, this message translates to:
  /// **'Played longest ago'**
  String get smartSortLastPlayedOldest;

  /// No description provided for @smartSortRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get smartSortRandom;

  /// No description provided for @lyricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyricsTitle;

  /// No description provided for @lyricsShow.
  ///
  /// In en, this message translates to:
  /// **'Show lyrics'**
  String get lyricsShow;

  /// No description provided for @lyricsHide.
  ///
  /// In en, this message translates to:
  /// **'Hide lyrics'**
  String get lyricsHide;

  /// No description provided for @lyricsNone.
  ///
  /// In en, this message translates to:
  /// **'No lyrics for this song'**
  String get lyricsNone;

  /// No description provided for @lyricsNoneOnline.
  ///
  /// In en, this message translates to:
  /// **'None found online either.'**
  String get lyricsNoneOnline;

  /// No description provided for @lyricsUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the lyrics search. Try again later.'**
  String get lyricsUnreachable;

  /// No description provided for @lyricsImport.
  ///
  /// In en, this message translates to:
  /// **'Import a .lrc file'**
  String get lyricsImport;

  /// No description provided for @lyricsSearchOnline.
  ///
  /// In en, this message translates to:
  /// **'Search online'**
  String get lyricsSearchOnline;

  /// No description provided for @lyricsSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search online again'**
  String get lyricsSearchAgain;

  /// No description provided for @lyricsEnableSearch.
  ///
  /// In en, this message translates to:
  /// **'Turn on lyrics search'**
  String get lyricsEnableSearch;

  /// No description provided for @lyricsEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Search lyrics online?'**
  String get lyricsEnableTitle;

  /// No description provided for @lyricsEnableBody.
  ///
  /// In en, this message translates to:
  /// **'When a song has no lyrics, Troona sends its title, artist, album and length to LRCLIB, then lyrics.ovh, only when you open its lyrics. Nothing else leaves this device. You can turn this off in Settings.'**
  String get lyricsEnableBody;

  /// No description provided for @lyricsEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get lyricsEnableAction;

  /// No description provided for @lyricsNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get lyricsNotSynced;

  /// No description provided for @lyricsBackToLine.
  ///
  /// In en, this message translates to:
  /// **'Back to the current line'**
  String get lyricsBackToLine;

  /// No description provided for @lyricsGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to {time}'**
  String lyricsGoTo(String time);

  /// No description provided for @lyricsInstrumental.
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get lyricsInstrumental;

  /// No description provided for @lyricsImported.
  ///
  /// In en, this message translates to:
  /// **'Lyrics imported'**
  String get lyricsImported;

  /// No description provided for @lyricsImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file holds no lyrics.'**
  String get lyricsImportInvalid;

  /// No description provided for @lyricsOptions.
  ///
  /// In en, this message translates to:
  /// **'Lyrics options'**
  String get lyricsOptions;

  /// No description provided for @lyricsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Show lines earlier (0.1 s)'**
  String get lyricsEarlier;

  /// No description provided for @lyricsLater.
  ///
  /// In en, this message translates to:
  /// **'Show lines later (0.1 s)'**
  String get lyricsLater;

  /// No description provided for @lyricsOffsetReset.
  ///
  /// In en, this message translates to:
  /// **'Reset the timing'**
  String get lyricsOffsetReset;

  /// No description provided for @lyricsOffsetValue.
  ///
  /// In en, this message translates to:
  /// **'Timing: {value} s'**
  String lyricsOffsetValue(String value);

  /// No description provided for @lyricsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove lyrics'**
  String get lyricsRemove;

  /// No description provided for @lyricsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove these lyrics?'**
  String get lyricsRemoveTitle;

  /// No description provided for @lyricsRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Lyrics found online come back only if you search again. Imported lyrics would need importing again.'**
  String get lyricsRemoveBody;

  /// No description provided for @lyricsSourceImported.
  ///
  /// In en, this message translates to:
  /// **'From an imported file'**
  String get lyricsSourceImported;

  /// No description provided for @lyricsSourceOnline.
  ///
  /// In en, this message translates to:
  /// **'Found online (LRCLIB or lyrics.ovh)'**
  String get lyricsSourceOnline;

  /// No description provided for @settingsOnlineLyrics.
  ///
  /// In en, this message translates to:
  /// **'Song lyrics'**
  String get settingsOnlineLyrics;

  /// No description provided for @privacyLyricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics search (off by default)'**
  String get privacyLyricsTitle;

  /// No description provided for @privacyLyricsBody.
  ///
  /// In en, this message translates to:
  /// **'When on, opening the lyrics of a song that has none stored sends its title, artist, album and length to LRCLIB (lrclib.net), then, if it has none, its artist and title to lyrics.ovh. Nothing is sent for other songs, and never for your whole library. These services also see your IP address, as with any web request. Lyrics found are kept on this phone; \"Clear downloaded info\" deletes them. Lyrics you import from a file never leave this phone, except in a backup you export.'**
  String get privacyLyricsBody;

  /// No description provided for @settingsAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// No description provided for @settingsAudioSummary.
  ///
  /// In en, this message translates to:
  /// **'Equalizer, crossfade, shuffle, lyrics, calls'**
  String get settingsAudioSummary;

  /// No description provided for @settingsAudioIntro.
  ///
  /// In en, this message translates to:
  /// **'How Troona sounds and plays, and what it does when your phone needs the speaker for something else.'**
  String get settingsAudioIntro;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsInterruptions.
  ///
  /// In en, this message translates to:
  /// **'Interruptions'**
  String get settingsInterruptions;

  /// No description provided for @settingsListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get settingsListening;

  /// No description provided for @settingsKeepShuffle.
  ///
  /// In en, this message translates to:
  /// **'Keep shuffle on'**
  String get settingsKeepShuffle;

  /// No description provided for @settingsKeepShuffleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A list you start stays shuffled while shuffle is on. Off, lists play in order and only the Shuffle button shuffles them.'**
  String get settingsKeepShuffleSubtitle;

  /// No description provided for @settingsLyricsScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Screen on with lyrics'**
  String get settingsLyricsScreenOn;

  /// No description provided for @settingsLyricsScreenOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The screen stays on while lyrics show and the song plays.'**
  String get settingsLyricsScreenOnSubtitle;

  /// No description provided for @settingsTransitions.
  ///
  /// In en, this message translates to:
  /// **'Transitions'**
  String get settingsTransitions;

  /// No description provided for @settingsCrossfade.
  ///
  /// In en, this message translates to:
  /// **'Crossfade'**
  String get settingsCrossfade;

  /// No description provided for @settingsCrossfadeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The next song starts under the end of the one playing.'**
  String get settingsCrossfadeSubtitle;

  /// No description provided for @settingsCrossfadeLength.
  ///
  /// In en, this message translates to:
  /// **'Overlap'**
  String get settingsCrossfadeLength;

  /// No description provided for @settingsCrossfadeLengthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long both songs play together, at most.'**
  String get settingsCrossfadeLengthSubtitle;

  /// No description provided for @settingsKeepAlbumsWhole.
  ///
  /// In en, this message translates to:
  /// **'Keep albums whole'**
  String get settingsKeepAlbumsWhole;

  /// No description provided for @settingsKeepAlbumsWholeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Songs that follow each other on an album play on without a fade.'**
  String get settingsKeepAlbumsWholeSubtitle;

  /// No description provided for @settingsSmartTransitions.
  ///
  /// In en, this message translates to:
  /// **'Smart transitions'**
  String get settingsSmartTransitions;

  /// No description provided for @settingsSmartTransitionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starts the next song where the music really ends: silences are skipped, and a song that fades out keeps its own fade.'**
  String get settingsSmartTransitionsSubtitle;

  /// No description provided for @settingsDuckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a notification or a GPS voice speaks, the music gets quieter instead of pausing.'**
  String get settingsDuckSubtitle;

  /// No description provided for @settingsPauseOnCallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'During a call, or while another app plays sound.'**
  String get settingsPauseOnCallSubtitle;

  /// No description provided for @settingsResumeAfterCallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Once a call or a short interruption is over.'**
  String get settingsResumeAfterCallSubtitle;

  /// No description provided for @settingsAudioFooter.
  ///
  /// In en, this message translates to:
  /// **'Unplugging headphones always pauses the music.'**
  String get settingsAudioFooter;

  /// No description provided for @settingsLibrarySummary.
  ///
  /// In en, this message translates to:
  /// **'Songs on this phone, filters, rescan, history'**
  String get settingsLibrarySummary;

  /// No description provided for @settingsLibraryIntro.
  ///
  /// In en, this message translates to:
  /// **'The songs Troona found on this phone, what it leaves out, and whether your listening is recorded.'**
  String get settingsLibraryIntro;

  /// No description provided for @settingsLibraryContents.
  ///
  /// In en, this message translates to:
  /// **'In your library'**
  String get settingsLibraryContents;

  /// No description provided for @settingsScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get settingsScan;

  /// No description provided for @settingsScanFooter.
  ///
  /// In en, this message translates to:
  /// **'Troona reads the songs your phone lists as music. Ringtones, notifications and voice notes are always left out.'**
  String get settingsScanFooter;

  /// No description provided for @settingsOnlineOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOnlineOff;

  /// No description provided for @settingsOnlineOn.
  ///
  /// In en, this message translates to:
  /// **'On: {parts}'**
  String settingsOnlineOn(String parts);

  /// No description provided for @settingsOnlineBiosShort.
  ///
  /// In en, this message translates to:
  /// **'bios'**
  String get settingsOnlineBiosShort;

  /// No description provided for @settingsOnlinePhotosShort.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get settingsOnlinePhotosShort;

  /// No description provided for @settingsOnlineLyricsShort.
  ///
  /// In en, this message translates to:
  /// **'lyrics'**
  String get settingsOnlineLyricsShort;

  /// No description provided for @settingsOnlineIntro.
  ///
  /// In en, this message translates to:
  /// **'Optional, and off until you turn them on. Each one says what it sends, and where.'**
  String get settingsOnlineIntro;

  /// No description provided for @settingsOnlineBiosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Last.fm, with artist and album names.'**
  String get settingsOnlineBiosSubtitle;

  /// No description provided for @settingsOnlinePhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Deezer, with artist and album names and a few song titles.'**
  String get settingsOnlinePhotosSubtitle;

  /// No description provided for @settingsOnlineLyricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From LRCLIB, then lyrics.ovh, when you open a song\'s lyrics.'**
  String get settingsOnlineLyricsSubtitle;

  /// No description provided for @settingsOnlinePageFooter.
  ///
  /// In en, this message translates to:
  /// **'Nothing else about you or your music leaves this phone. Downloaded info can be cleared in Storage.'**
  String get settingsOnlinePageFooter;

  /// No description provided for @settingsPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacySection;

  /// No description provided for @settingsAppearanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Language, colour, glass effects, haptics'**
  String get settingsAppearanceSummary;

  /// No description provided for @settingsAppearanceIntro.
  ///
  /// In en, this message translates to:
  /// **'Troona\'s language, how it looks, and how it answers your touch.'**
  String get settingsAppearanceIntro;

  /// No description provided for @settingsTouch.
  ///
  /// In en, this message translates to:
  /// **'Touch'**
  String get settingsTouch;

  /// No description provided for @settingsColors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get settingsColors;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get settingsAccent;

  /// No description provided for @settingsAccentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buttons, switches and what is selected.'**
  String get settingsAccentSubtitle;

  /// No description provided for @settingsAccentLilac.
  ///
  /// In en, this message translates to:
  /// **'Lilac'**
  String get settingsAccentLilac;

  /// No description provided for @settingsAccentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get settingsAccentBlue;

  /// No description provided for @settingsAccentTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get settingsAccentTeal;

  /// No description provided for @settingsAccentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get settingsAccentGreen;

  /// No description provided for @settingsAccentYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get settingsAccentYellow;

  /// No description provided for @settingsAccentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get settingsAccentOrange;

  /// No description provided for @settingsAccentPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get settingsAccentPink;

  /// No description provided for @settingsBlackBackground.
  ///
  /// In en, this message translates to:
  /// **'Black background'**
  String get settingsBlackBackground;

  /// No description provided for @settingsBlackBackgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The tabs on black, without the glow of the song playing. Albums, artists and Now Playing keep theirs.'**
  String get settingsBlackBackgroundSubtitle;

  /// No description provided for @settingsHapticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light vibrations when you tap, pick or like.'**
  String get settingsHapticsSubtitle;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsStorageSummary.
  ///
  /// In en, this message translates to:
  /// **'Cache {size}, reset'**
  String settingsStorageSummary(String size);

  /// No description provided for @settingsStorageSummaryPending.
  ///
  /// In en, this message translates to:
  /// **'Cache, reset'**
  String get settingsStorageSummaryPending;

  /// No description provided for @settingsStorageIntro.
  ///
  /// In en, this message translates to:
  /// **'What Troona keeps on this phone besides your music, and how to start over.'**
  String get settingsStorageIntro;

  /// No description provided for @settingsCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsCache;

  /// No description provided for @settingsOnlineClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bios, photos and lyrics found online. Imported lyrics stay.'**
  String get settingsOnlineClearSubtitle;

  /// No description provided for @settingsForgetQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stops the music and forgets the queue and where you were.'**
  String get settingsForgetQueueSubtitle;

  /// No description provided for @settingsResetSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every preference back to its default. Your library, likes and playlists stay.'**
  String get settingsResetSettingsSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSummary.
  ///
  /// In en, this message translates to:
  /// **'Version {version}, what\'s new, updates'**
  String settingsAboutSummary(String version);

  /// No description provided for @settingsAboutSummaryPending.
  ///
  /// In en, this message translates to:
  /// **'What\'s new, updates'**
  String get settingsAboutSummaryPending;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get aboutUpdates;

  /// No description provided for @aboutInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get aboutInformation;

  /// No description provided for @aboutSource.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSource;

  /// No description provided for @aboutSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On GitHub'**
  String get aboutSourceSubtitle;

  /// No description provided for @settingsOnlineSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get settingsOnlineSources;

  /// No description provided for @settingsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get settingsFilters;

  /// No description provided for @settingsMinLength.
  ///
  /// In en, this message translates to:
  /// **'Shortest song'**
  String get settingsMinLength;

  /// No description provided for @settingsMinLengthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shorter files stay out of your library.'**
  String get settingsMinLengthSubtitle;

  /// No description provided for @durationSecondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String durationSecondsShort(int seconds);

  /// No description provided for @settingsFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get settingsFolders;

  /// No description provided for @settingsFoldersAll.
  ///
  /// In en, this message translates to:
  /// **'Every folder is in your library'**
  String get settingsFoldersAll;

  /// No description provided for @settingsFoldersExcluded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder left out} other{{count} folders left out}}'**
  String settingsFoldersExcluded(int count);

  /// No description provided for @settingsFoldersIntro.
  ///
  /// In en, this message translates to:
  /// **'Songs in a folder turned off leave your library, with its subfolders. Turn it back on and they come back with their likes, plays and playlists.'**
  String get settingsFoldersIntro;

  /// No description provided for @settingsFoldersFooter.
  ///
  /// In en, this message translates to:
  /// **'At least one song stays in your library.'**
  String get settingsFoldersFooter;

  /// No description provided for @settingsFoldersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No folders yet: your library is empty.'**
  String get settingsFoldersEmpty;

  /// No description provided for @settingsHistory.
  ///
  /// In en, this message translates to:
  /// **'Listening history'**
  String get settingsHistory;

  /// No description provided for @settingsHistoryPause.
  ///
  /// In en, this message translates to:
  /// **'Pause listening history'**
  String get settingsHistoryPause;

  /// No description provided for @settingsHistoryPauseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plays are not recorded. Recently played, Your listening, play counts and smart playlists leave them out.'**
  String get settingsHistoryPauseSubtitle;

  /// No description provided for @settingsHistoryFooter.
  ///
  /// In en, this message translates to:
  /// **'The history already recorded stays as it is.'**
  String get settingsHistoryFooter;

  /// No description provided for @settingsLibrarySummaryPaused.
  ///
  /// In en, this message translates to:
  /// **'Listening history paused'**
  String get settingsLibrarySummaryPaused;

  /// No description provided for @settingsFolderCoveredBy.
  ///
  /// In en, this message translates to:
  /// **'Left out with {folder}'**
  String settingsFolderCoveredBy(String folder);

  /// No description provided for @settingsFolderInPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get settingsFolderInPhone;

  /// No description provided for @settingsFolderInSdCard.
  ///
  /// In en, this message translates to:
  /// **'SD card'**
  String get settingsFolderInSdCard;

  /// No description provided for @settingsFoldersSection.
  ///
  /// In en, this message translates to:
  /// **'Folders with music'**
  String get settingsFoldersSection;

  /// No description provided for @licensesIntro.
  ///
  /// In en, this message translates to:
  /// **'Troona is built with open-source software. Thank you to the people who make it.'**
  String get licensesIntro;

  /// No description provided for @licensesOwnTerms.
  ///
  /// In en, this message translates to:
  /// **'Its own terms'**
  String get licensesOwnTerms;

  /// No description provided for @licensesNotFound.
  ///
  /// In en, this message translates to:
  /// **'This license is no longer listed.'**
  String get licensesNotFound;

  /// No description provided for @settingsLicensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The software Troona is built with'**
  String get settingsLicensesSubtitle;

  /// No description provided for @licensesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 license} other{{count} licenses}}'**
  String licensesCount(int count);

  /// No description provided for @settingsMinLengthTooLong.
  ///
  /// In en, this message translates to:
  /// **'No song in your library is that long: it would be empty.'**
  String get settingsMinLengthTooLong;

  /// No description provided for @settingsFiltersNotApplied.
  ///
  /// In en, this message translates to:
  /// **'No song in your library passes these filters, so they are not applied. Turn a folder back on or choose a shorter length.'**
  String get settingsFiltersNotApplied;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Missing songs, playback, lyrics, a new phone'**
  String get helpSubtitle;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Answers to the questions that come up most, each with the setting that settles it.'**
  String get helpIntro;

  /// No description provided for @helpLibrarySection.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get helpLibrarySection;

  /// No description provided for @helpMissingSong.
  ///
  /// In en, this message translates to:
  /// **'A song is missing'**
  String get helpMissingSong;

  /// No description provided for @helpMissingSongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Troona lists the songs Android knows about. A folder turned off or the Shortest song length may leave it out; a file just copied shows after Rescan library.'**
  String get helpMissingSongAnswer;

  /// No description provided for @helpPlaybackSection.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get helpPlaybackSection;

  /// No description provided for @helpStopsInBackground.
  ///
  /// In en, this message translates to:
  /// **'Music stops with the screen off'**
  String get helpStopsInBackground;

  /// No description provided for @helpStopsInBackgroundAnswer.
  ///
  /// In en, this message translates to:
  /// **'Some phones stop apps in the background to save battery. In Troona\'s page in Android\'s settings, let it use the battery without restrictions (the wording depends on the phone).'**
  String get helpStopsInBackgroundAnswer;

  /// No description provided for @helpOnlineSection.
  ///
  /// In en, this message translates to:
  /// **'Online extras'**
  String get helpOnlineSection;

  /// No description provided for @helpNoLyrics.
  ///
  /// In en, this message translates to:
  /// **'A song has no lyrics'**
  String get helpNoLyrics;

  /// No description provided for @helpNoLyricsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Turn on Song lyrics to look them up online. Or, playing the song, open Lyrics in Now Playing and choose Import a .lrc file.'**
  String get helpNoLyricsAnswer;

  /// No description provided for @helpArtistInfo.
  ///
  /// In en, this message translates to:
  /// **'Artist photos and bios'**
  String get helpArtistInfo;

  /// No description provided for @helpArtistInfoAnswer.
  ///
  /// In en, this message translates to:
  /// **'They come from Deezer and Last.fm, only once you turn them on: until then, nothing about your artists leaves your phone.'**
  String get helpArtistInfoAnswer;

  /// No description provided for @helpBackupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get helpBackupSection;

  /// No description provided for @helpNewPhone.
  ///
  /// In en, this message translates to:
  /// **'Moving to a new phone'**
  String get helpNewPhone;

  /// No description provided for @helpNewPhoneAnswer.
  ///
  /// In en, this message translates to:
  /// **'Make a backup, copy the file to the new phone and restore it there: playlists, likes, history and settings come back, and your songs are found again by their name, size and tags.'**
  String get helpNewPhoneAnswer;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System follows your phone\'s language.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @trackEditInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit info'**
  String get trackEditInfo;

  /// No description provided for @albumEditInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit album info'**
  String get albumEditInfo;

  /// No description provided for @editInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit info'**
  String get editInfoTitle;

  /// No description provided for @editAlbumTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit album'**
  String get editAlbumTitle;

  /// No description provided for @editFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get editFieldTitle;

  /// No description provided for @editFieldArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get editFieldArtist;

  /// No description provided for @editFieldAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get editFieldAlbum;

  /// No description provided for @editFieldYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get editFieldYear;

  /// No description provided for @editYearHint.
  ///
  /// In en, this message translates to:
  /// **'No year'**
  String get editYearHint;

  /// No description provided for @editArtistSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Artists in your library'**
  String get editArtistSuggestions;

  /// No description provided for @editCorrected.
  ///
  /// In en, this message translates to:
  /// **'Corrected'**
  String get editCorrected;

  /// Tooltip of the button that drops a correction
  ///
  /// In en, this message translates to:
  /// **'Use the file\'s value: {value}'**
  String editUseFileValue(String value);

  /// No description provided for @editChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get editChangeCover;

  /// No description provided for @editUseFileCover.
  ///
  /// In en, this message translates to:
  /// **'Use the file\'s cover'**
  String get editUseFileCover;

  /// No description provided for @editFooter.
  ///
  /// In en, this message translates to:
  /// **'These corrections stay in Troona. Your files are not changed, and other apps do not see them.'**
  String get editFooter;

  /// No description provided for @editAlbumNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to every song of this album. Titles and artists are corrected song by song.'**
  String get editAlbumNote;

  /// No description provided for @editSaved.
  ///
  /// In en, this message translates to:
  /// **'Corrections saved'**
  String get editSaved;

  /// No description provided for @editSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the corrections'**
  String get editSaveFailed;

  /// No description provided for @editLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this song\'s info'**
  String get editLoadFailed;

  /// No description provided for @backupPartEdits.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get backupPartEdits;

  /// No description provided for @backupSummaryEdits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Info corrected on 1 song} other{Info corrected on {count} songs}}'**
  String backupSummaryEdits(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
