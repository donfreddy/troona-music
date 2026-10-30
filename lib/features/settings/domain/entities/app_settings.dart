import 'package:equatable/equatable.dart';

/// Global glass quality to balance fidelity vs performance.
enum GlassQuality { auto, high, low, off }

/// User preferences. Every field here is read somewhere: a setting that
/// does nothing is a bug report waiting to happen.
class AppSettings extends Equatable {
  // Playback
  final bool stopOnCallEnabled;
  final bool resumeAfterCallEnabled;
  final bool duckAudioOnNotification;

  // Online extras: opt-in, they send artist and album names to Last.fm and
  // Deezer.
  final bool fetchOnlineMetadata;
  final bool fetchArtistArtwork;

  /// Whether the Home card offering online extras was answered or closed.
  final bool onlineExtrasOffered;

  /// Opt-in: asks GitHub once a day for the latest release.
  final bool checkForUpdates;

  // UI
  final bool hapticFeedbackEnabled;
  final GlassQuality glassQuality;

  const AppSettings({
    this.stopOnCallEnabled = true,
    this.resumeAfterCallEnabled = true,
    this.duckAudioOnNotification = true,
    this.fetchOnlineMetadata = false,
    this.fetchArtistArtwork = false,
    this.onlineExtrasOffered = false,
    this.checkForUpdates = false,
    this.hapticFeedbackEnabled = true,
    this.glassQuality = GlassQuality.auto,
  });

  bool get onlineExtrasEnabled => fetchOnlineMetadata || fetchArtistArtwork;

  AppSettings copyWith({
    bool? stopOnCallEnabled,
    bool? resumeAfterCallEnabled,
    bool? duckAudioOnNotification,
    bool? fetchOnlineMetadata,
    bool? fetchArtistArtwork,
    bool? onlineExtrasOffered,
    bool? checkForUpdates,
    bool? hapticFeedbackEnabled,
    GlassQuality? glassQuality,
  }) => AppSettings(
    stopOnCallEnabled: stopOnCallEnabled ?? this.stopOnCallEnabled,
    resumeAfterCallEnabled:
        resumeAfterCallEnabled ?? this.resumeAfterCallEnabled,
    duckAudioOnNotification:
        duckAudioOnNotification ?? this.duckAudioOnNotification,
    fetchOnlineMetadata: fetchOnlineMetadata ?? this.fetchOnlineMetadata,
    fetchArtistArtwork: fetchArtistArtwork ?? this.fetchArtistArtwork,
    onlineExtrasOffered: onlineExtrasOffered ?? this.onlineExtrasOffered,
    checkForUpdates: checkForUpdates ?? this.checkForUpdates,
    hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    glassQuality: glassQuality ?? this.glassQuality,
  );

  @override
  List<Object?> get props => [
    stopOnCallEnabled,
    resumeAfterCallEnabled,
    duckAudioOnNotification,
    fetchOnlineMetadata,
    fetchArtistArtwork,
    onlineExtrasOffered,
    checkForUpdates,
    hapticFeedbackEnabled,
    glassQuality,
  ];
}
