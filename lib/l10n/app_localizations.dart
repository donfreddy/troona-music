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
  /// **'Artist photos'**
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
  /// **'Bios and album notes will download again when you open an artist or an album.'**
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
  /// **'If you turn them on, Troona sends artist and album names to Last.fm and Deezer to fetch photos and bios. These services also see your IP address, as with any web request. No file, account or listening history is sent. Turn them off at any time in Settings.'**
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
