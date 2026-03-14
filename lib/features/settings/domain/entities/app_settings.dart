import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark, amoled }

enum CrossfadeStyle { linear, equalPower, dip }

/// Minimal, user-facing settings for v1.0.
class AppSettings extends Equatable {
  // Appearance
  final AppThemeMode themeMode;
  final bool useDynamicColor; // Material You / artwork palette

  // Playback (MVP)
  final bool gaplessPlayback; // seamless transitions, no gaps
  final bool crossfadeEnabled; // overlap blend between tracks
  final int crossfadeDurationMs; // 1 000–12 000 ms
  final CrossfadeStyle crossfadeStyle;
  final bool stopOnCallEnabled;
  final bool resumeAfterCallEnabled;
  final bool duckAudioOnNotification;

  // Library
  final bool scanOnStartup;
  final bool watchFolderChanges;

  // UI
  final bool showAlbumArtInNotification;
  final bool hapticFeedbackEnabled;

  // Sleep timer
  final bool sleepTimerEnabled;
  final int sleepTimerMinutes; // 5–120

  const AppSettings({
    // Appearance
    this.themeMode = AppThemeMode.system,
    this.useDynamicColor = true,
    // Playback
    this.gaplessPlayback = true,
    this.crossfadeEnabled = false,
    this.crossfadeDurationMs = 3000,
    this.crossfadeStyle = CrossfadeStyle.equalPower,
    this.stopOnCallEnabled = true,
    this.resumeAfterCallEnabled = true,
    this.duckAudioOnNotification = true,
    // Library
    this.scanOnStartup = true,
    this.watchFolderChanges = false,
    // UI
    this.showAlbumArtInNotification = true,
    this.hapticFeedbackEnabled = true,
    // Sleep timer
    this.sleepTimerEnabled = false,
    this.sleepTimerMinutes = 30,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? useDynamicColor,
    bool? gaplessPlayback,
    bool? crossfadeEnabled,
    int? crossfadeDurationMs,
    CrossfadeStyle? crossfadeStyle,
    bool? stopOnCallEnabled,
    bool? resumeAfterCallEnabled,
    bool? duckAudioOnNotification,
    bool? scanOnStartup,
    bool? watchFolderChanges,
    bool? showAlbumArtInNotification,
    bool? hapticFeedbackEnabled,
    bool? sleepTimerEnabled,
    int? sleepTimerMinutes,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    useDynamicColor: useDynamicColor ?? this.useDynamicColor,
    gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
    crossfadeEnabled: crossfadeEnabled ?? this.crossfadeEnabled,
    crossfadeDurationMs: crossfadeDurationMs ?? this.crossfadeDurationMs,
    crossfadeStyle: crossfadeStyle ?? this.crossfadeStyle,
    stopOnCallEnabled: stopOnCallEnabled ?? this.stopOnCallEnabled,
    resumeAfterCallEnabled:
        resumeAfterCallEnabled ?? this.resumeAfterCallEnabled,
    duckAudioOnNotification:
        duckAudioOnNotification ?? this.duckAudioOnNotification,
    scanOnStartup: scanOnStartup ?? this.scanOnStartup,
    watchFolderChanges: watchFolderChanges ?? this.watchFolderChanges,
    showAlbumArtInNotification:
        showAlbumArtInNotification ?? this.showAlbumArtInNotification,
    hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    sleepTimerEnabled: sleepTimerEnabled ?? this.sleepTimerEnabled,
    sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
  );

  @override
  List<Object?> get props => [
    themeMode,
    useDynamicColor,
    gaplessPlayback,
    crossfadeEnabled,
    crossfadeDurationMs,
    crossfadeStyle,
    stopOnCallEnabled,
    resumeAfterCallEnabled,
    duckAudioOnNotification,
    scanOnStartup,
    watchFolderChanges,
    showAlbumArtInNotification,
    hapticFeedbackEnabled,
    sleepTimerEnabled,
    sleepTimerMinutes,
  ];
}
