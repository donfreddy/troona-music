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

  /// No description provided for @settingsOnlineFooter.
  ///
  /// In en, this message translates to:
  /// **'Optional. When on, Troona sends artist and album names to Last.fm and Deezer to fetch photos and bios. Your music files never leave this device.'**
  String get settingsOnlineFooter;

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
  /// **'Bios, album notes and photos will download again when you open an artist or an album, if they are still turned on.'**
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

  /// No description provided for @settingsGlassLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsGlassLight;

  /// No description provided for @settingsGlassOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsGlassOff;

  /// No description provided for @settingsGlassFooter.
  ///
  /// In en, this message translates to:
  /// **'Auto adapts to your phone. Choose Light or Off for smoother scrolling on older devices.'**
  String get settingsGlassFooter;

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

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Troona {version} ({build})'**
  String settingsVersion(String version, String build);

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
  /// **'There are two separate switches. Bios sends artist and album names to Last.fm. Photos sends them to Deezer, and downloads pictures from Deezer or Last.fm. These services also see your IP address, as with any web request. No file, account or listening history is sent. Turn either switch off at any time in Settings: requests to that service stop, and turning photos off also deletes the photos already downloaded.'**
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

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling Troona deletes everything it stored. Your music files are never touched.'**
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

  /// No description provided for @statSongs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{song} other{songs}}'**
  String statSongs(int count);

  /// No description provided for @statAlbums.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{album} other{albums}}'**
  String statAlbums(int count);

  /// No description provided for @statArtists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{artist} other{artists}}'**
  String statArtists(int count);

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

  /// No description provided for @albumAbout.
  ///
  /// In en, this message translates to:
  /// **'About this album'**
  String get albumAbout;

  /// No description provided for @artistInLibrary.
  ///
  /// In en, this message translates to:
  /// **'In your library'**
  String get artistInLibrary;

  /// No description provided for @infoSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get infoSongs;

  /// No description provided for @infoAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get infoAlbums;

  /// No description provided for @infoLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get infoLength;

  /// No description provided for @infoYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get infoYear;

  /// No description provided for @infoSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get infoSize;

  /// No description provided for @infoFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get infoFormat;

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

  /// No description provided for @metaPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String metaPlays(int count);

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

  /// No description provided for @playlistDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get playlistDescriptionHint;

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

  /// No description provided for @homeYourArtists.
  ///
  /// In en, this message translates to:
  /// **'Your artists'**
  String get homeYourArtists;

  /// No description provided for @homeRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get homeRecentlyAdded;

  /// No description provided for @homeYourPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get homeYourPlaylists;

  /// No description provided for @homeWeeklyPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{play this week} other{plays this week}}'**
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
  /// **'Troona can fetch them from Last.fm and Deezer using artist and album names. Your music files stay on this device.'**
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
  /// **'{count, plural, =0{No new songs this week} =1{1 song heard for the first time} other{{count} songs heard for the first time}}'**
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

  /// No description provided for @recapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing was played last week.'**
  String get recapEmpty;

  /// No description provided for @recapCalendarCaption.
  ///
  /// In en, this message translates to:
  /// **'A filled dot is a day with music.'**
  String get recapCalendarCaption;

  /// No description provided for @recapCalendarDay.
  ///
  /// In en, this message translates to:
  /// **'{date}, music played'**
  String recapCalendarDay(String date);

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

  /// No description provided for @recapCalendarQuietDay.
  ///
  /// In en, this message translates to:
  /// **'{date}, no music'**
  String recapCalendarQuietDay(String date);

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

  /// No description provided for @metaAboutAlbum.
  ///
  /// In en, this message translates to:
  /// **'About this album'**
  String get metaAboutAlbum;

  /// No description provided for @metaAboutArtist.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get metaAboutArtist;

  /// No description provided for @metaOnTour.
  ///
  /// In en, this message translates to:
  /// **'On tour'**
  String get metaOnTour;

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

  /// No description provided for @metaSimilarArtists.
  ///
  /// In en, this message translates to:
  /// **'Similar artists'**
  String get metaSimilarArtists;

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
  /// **'Stop the music after 15, 30 or 45 minutes or at the end of the song, and play from 0.75x to 2x.'**
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
  /// **'Library'**
  String get whatsNew100LibraryTitle;

  /// No description provided for @whatsNew100LibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Faster scans with live progress. Your library stays on screen while it updates.'**
  String get whatsNew100LibraryBody;

  /// No description provided for @whatsNew100ShuffleTitle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get whatsNew100ShuffleTitle;

  /// No description provided for @whatsNew100ShuffleBody.
  ///
  /// In en, this message translates to:
  /// **'Every Shuffle button starts on a random song, and turning shuffle off brings back the original order.'**
  String get whatsNew100ShuffleBody;

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

  /// No description provided for @whatsNew100LockTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock screen'**
  String get whatsNew100LockTitle;

  /// No description provided for @whatsNew100LockBody.
  ///
  /// In en, this message translates to:
  /// **'The position stays right after a skip, a seek or a queue change.'**
  String get whatsNew100LockBody;

  /// No description provided for @whatsNew100ToastTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get whatsNew100ToastTitle;

  /// No description provided for @whatsNew100ToastBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmations now appear right above the player bar.'**
  String get whatsNew100ToastBody;
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
