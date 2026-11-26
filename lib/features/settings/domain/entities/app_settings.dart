import 'package:equatable/equatable.dart';

/// Global glass quality to balance fidelity vs performance.
enum GlassQuality { auto, high, low, off }

/// The language of the app's screens: the phone's, or one of the app's.
enum AppLanguage {
  system(null),
  en('en'),
  fr('fr');

  /// Its language code; null for the phone's language.
  final String? code;

  const AppLanguage(this.code);
}

/// User preferences. Every field here is read somewhere: a setting that
/// does nothing is a bug report waiting to happen.
class AppSettings extends Equatable {
  // Playback
  final bool stopOnCallEnabled;
  final bool resumeAfterCallEnabled;
  final bool duckAudioOnNotification;

  /// A new list keeps shuffle on when it is; off, it plays in order and
  /// shuffle turns off (the Shuffle button still shuffles).
  final bool keepShuffle;

  /// The screen stays on while lyrics show and the song plays.
  final bool lyricsKeepScreenOn;

  /// The next song starts under the end of the one playing.
  final bool crossfade;

  /// How long two songs overlap, in seconds: one of [crossfadeChoices].
  final int crossfadeSeconds;

  /// Songs that follow each other on an album never overlap.
  final bool keepAlbumsWhole;

  /// Transitions follow where songs' music really starts and stops: their
  /// files are analysed once, as they are about to play.
  final bool smartTransitions;

  // Online extras: opt-in, they send artist and album names to Last.fm and
  // Deezer.
  final bool fetchOnlineMetadata;
  final bool fetchArtistArtwork;

  /// Opt-in: sends a song's title, artist, album and length to LRCLIB, then
  /// lyrics.ovh, when its lyrics are opened and none are stored.
  final bool fetchLyrics;

  /// Whether the Home card offering online extras was answered or closed.
  final bool onlineExtrasOffered;

  /// Opt-in: asks GitHub once a day for the latest release.
  final bool checkForUpdates;

  // Library: what scans leave out, besides the fixed rules.

  /// The shortest song kept, in seconds: one of [minTrackChoices].
  final int minTrackSeconds;

  /// Folders whose songs stay out of the library, subfolders included:
  /// absolute paths with no trailing slash.
  final List<String> excludedFolders;

  /// Songs played add nothing to the listening history while on. Kept on
  /// this phone: a backup made where it was on never pauses another.
  final bool historyPaused;

  // UI
  final bool hapticFeedbackEnabled;
  final GlassQuality glassQuality;

  /// Kept on this phone: never in a backup, so restoring one made
  /// elsewhere, or before the setting existed, leaves it alone.
  final AppLanguage language;

  const AppSettings({
    this.stopOnCallEnabled = true,
    this.resumeAfterCallEnabled = true,
    this.duckAudioOnNotification = true,
    this.keepShuffle = true,
    this.lyricsKeepScreenOn = true,
    this.crossfade = false,
    this.crossfadeSeconds = 6,
    this.keepAlbumsWhole = true,
    this.smartTransitions = true,
    this.fetchOnlineMetadata = false,
    this.fetchArtistArtwork = false,
    this.fetchLyrics = false,
    this.onlineExtrasOffered = false,
    this.checkForUpdates = false,
    this.minTrackSeconds = 10,
    this.excludedFolders = const [],
    this.historyPaused = false,
    this.hapticFeedbackEnabled = true,
    this.glassQuality = GlassQuality.auto,
    this.language = AppLanguage.system,
  });

  bool get onlineExtrasEnabled => fetchOnlineMetadata || fetchArtistArtwork;

  /// The lengths offered for [minTrackSeconds]; anything else reads as the
  /// default.
  static const minTrackChoices = [10, 30, 60, 120];

  /// The lengths offered for [crossfadeSeconds]; anything else reads as the
  /// default.
  static const crossfadeChoices = [3, 6, 9, 12];

  AppSettings copyWith({
    bool? stopOnCallEnabled,
    bool? resumeAfterCallEnabled,
    bool? duckAudioOnNotification,
    bool? keepShuffle,
    bool? lyricsKeepScreenOn,
    bool? crossfade,
    int? crossfadeSeconds,
    bool? keepAlbumsWhole,
    bool? smartTransitions,
    bool? fetchOnlineMetadata,
    bool? fetchArtistArtwork,
    bool? fetchLyrics,
    bool? onlineExtrasOffered,
    bool? checkForUpdates,
    int? minTrackSeconds,
    List<String>? excludedFolders,
    bool? historyPaused,
    bool? hapticFeedbackEnabled,
    GlassQuality? glassQuality,
    AppLanguage? language,
  }) => AppSettings(
    stopOnCallEnabled: stopOnCallEnabled ?? this.stopOnCallEnabled,
    resumeAfterCallEnabled:
        resumeAfterCallEnabled ?? this.resumeAfterCallEnabled,
    duckAudioOnNotification:
        duckAudioOnNotification ?? this.duckAudioOnNotification,
    keepShuffle: keepShuffle ?? this.keepShuffle,
    lyricsKeepScreenOn: lyricsKeepScreenOn ?? this.lyricsKeepScreenOn,
    crossfade: crossfade ?? this.crossfade,
    crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
    keepAlbumsWhole: keepAlbumsWhole ?? this.keepAlbumsWhole,
    smartTransitions: smartTransitions ?? this.smartTransitions,
    fetchOnlineMetadata: fetchOnlineMetadata ?? this.fetchOnlineMetadata,
    fetchArtistArtwork: fetchArtistArtwork ?? this.fetchArtistArtwork,
    fetchLyrics: fetchLyrics ?? this.fetchLyrics,
    onlineExtrasOffered: onlineExtrasOffered ?? this.onlineExtrasOffered,
    checkForUpdates: checkForUpdates ?? this.checkForUpdates,
    minTrackSeconds: minTrackSeconds ?? this.minTrackSeconds,
    excludedFolders: excludedFolders ?? this.excludedFolders,
    historyPaused: historyPaused ?? this.historyPaused,
    hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    glassQuality: glassQuality ?? this.glassQuality,
    language: language ?? this.language,
  );

  @override
  List<Object?> get props => [
    stopOnCallEnabled,
    resumeAfterCallEnabled,
    duckAudioOnNotification,
    keepShuffle,
    lyricsKeepScreenOn,
    crossfade,
    crossfadeSeconds,
    keepAlbumsWhole,
    smartTransitions,
    fetchOnlineMetadata,
    fetchArtistArtwork,
    fetchLyrics,
    onlineExtrasOffered,
    checkForUpdates,
    minTrackSeconds,
    excludedFolders,
    historyPaused,
    hapticFeedbackEnabled,
    glassQuality,
    language,
  ];
}
