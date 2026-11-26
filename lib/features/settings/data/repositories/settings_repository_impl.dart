import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

/// SharedPreferences keys. The online extras keys were renamed when they
/// became opt-in, so a value saved by an older build (on by default) is
/// ignored.
abstract final class _K {
  static const stopOnCallEnabled = 'stop_on_call_enabled';
  static const resumeAfterCallEnabled = 'resume_after_call_enabled';
  static const duckAudioOnNotification = 'duck_audio_on_notification';
  static const keepShuffle = 'keep_shuffle';
  static const lyricsKeepScreenOn = 'lyrics_keep_screen_on';
  static const fetchOnlineMetadata = 'online_bios_enabled';
  static const fetchArtistArtwork = 'online_photos_enabled';
  static const fetchLyrics = 'online_lyrics_enabled';
  static const onlineExtrasOffered = 'online_extras_offered';
  static const checkForUpdates = 'update_check_enabled';
  static const minTrackSeconds = 'min_track_seconds';
  static const excludedFolders = 'excluded_folders';
  static const historyPaused = 'history_paused';
  static const hapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const glassQuality = 'glass_quality';
  static const accent = 'accent';
  static const blackBackground = 'black_background';
  static const language = 'app_language';

  static const all = [
    stopOnCallEnabled,
    resumeAfterCallEnabled,
    duckAudioOnNotification,
    keepShuffle,
    lyricsKeepScreenOn,
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
    accent,
    blackBackground,
    language,
  ];
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;

  const SettingsRepositoryImpl(this._prefs);

  /// Enums are saved by name; an int is a legacy index.
  T _loadEnum<T extends Enum>({
    required String key,
    required List<T> values,
    required T defaultValue,
  }) {
    final raw = _prefs.get(key);
    if (raw is String) {
      return values.firstWhere(
        (e) => e.name == raw,
        orElse: () => defaultValue,
      );
    }
    if (raw is int && raw >= 0 && raw < values.length) {
      return values[raw];
    }
    return defaultValue;
  }

  bool _bool(String key, bool fallback) {
    final raw = _prefs.get(key);
    return raw is bool ? raw : fallback;
  }

  int _minTrackSeconds(int fallback) {
    final raw = _prefs.get(_K.minTrackSeconds);
    return raw is int && AppSettings.minTrackChoices.contains(raw)
        ? raw
        : fallback;
  }

  List<String> _folders() {
    final raw = _prefs.get(_K.excludedFolders);
    return raw is List ? [...raw.whereType<String>()] : const [];
  }

  @override
  Future<Either<Failure, AppSettings>> loadSettings() async {
    try {
      const d = AppSettings();
      return Right(
        AppSettings(
          stopOnCallEnabled: _bool(_K.stopOnCallEnabled, d.stopOnCallEnabled),
          resumeAfterCallEnabled: _bool(
            _K.resumeAfterCallEnabled,
            d.resumeAfterCallEnabled,
          ),
          duckAudioOnNotification: _bool(
            _K.duckAudioOnNotification,
            d.duckAudioOnNotification,
          ),
          keepShuffle: _bool(_K.keepShuffle, d.keepShuffle),
          lyricsKeepScreenOn: _bool(
            _K.lyricsKeepScreenOn,
            d.lyricsKeepScreenOn,
          ),
          fetchOnlineMetadata: _bool(
            _K.fetchOnlineMetadata,
            d.fetchOnlineMetadata,
          ),
          fetchArtistArtwork: _bool(
            _K.fetchArtistArtwork,
            d.fetchArtistArtwork,
          ),
          fetchLyrics: _bool(_K.fetchLyrics, d.fetchLyrics),
          onlineExtrasOffered: _bool(
            _K.onlineExtrasOffered,
            d.onlineExtrasOffered,
          ),
          checkForUpdates: _bool(_K.checkForUpdates, d.checkForUpdates),
          minTrackSeconds: _minTrackSeconds(d.minTrackSeconds),
          excludedFolders: _folders(),
          historyPaused: _bool(_K.historyPaused, d.historyPaused),
          hapticFeedbackEnabled: _bool(
            _K.hapticFeedbackEnabled,
            d.hapticFeedbackEnabled,
          ),
          glassQuality: _loadEnum(
            key: _K.glassQuality,
            values: GlassQuality.values,
            defaultValue: d.glassQuality,
          ),
          accent: _loadEnum(
            key: _K.accent,
            values: AppAccent.values,
            defaultValue: d.accent,
          ),
          blackBackground: _bool(_K.blackBackground, d.blackBackground),
          language: _loadEnum(
            key: _K.language,
            values: AppLanguage.values,
            defaultValue: d.language,
          ),
        ),
      );
    } catch (e, st) {
      return Left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings s) async {
    try {
      await Future.wait([
        _prefs.setBool(_K.stopOnCallEnabled, s.stopOnCallEnabled),
        _prefs.setBool(_K.resumeAfterCallEnabled, s.resumeAfterCallEnabled),
        _prefs.setBool(_K.duckAudioOnNotification, s.duckAudioOnNotification),
        _prefs.setBool(_K.keepShuffle, s.keepShuffle),
        _prefs.setBool(_K.lyricsKeepScreenOn, s.lyricsKeepScreenOn),
        _prefs.setBool(_K.fetchOnlineMetadata, s.fetchOnlineMetadata),
        _prefs.setBool(_K.fetchArtistArtwork, s.fetchArtistArtwork),
        _prefs.setBool(_K.fetchLyrics, s.fetchLyrics),
        _prefs.setBool(_K.onlineExtrasOffered, s.onlineExtrasOffered),
        _prefs.setBool(_K.checkForUpdates, s.checkForUpdates),
        _prefs.setInt(_K.minTrackSeconds, s.minTrackSeconds),
        _prefs.setStringList(_K.excludedFolders, s.excludedFolders),
        _prefs.setBool(_K.historyPaused, s.historyPaused),
        _prefs.setBool(_K.hapticFeedbackEnabled, s.hapticFeedbackEnabled),
        _prefs.setString(_K.glassQuality, s.glassQuality.name),
        _prefs.setString(_K.accent, s.accent.name),
        _prefs.setBool(_K.blackBackground, s.blackBackground),
        _prefs.setString(_K.language, s.language.name),
      ]);
      return const Right(unit);
    } catch (e, st) {
      return Left(ErrorHandler.handle(e, st));
    }
  }

  /// Removes the settings only: the playback session lives in the same
  /// preferences and must survive a reset.
  @override
  Future<Either<Failure, Unit>> resetSettings() async {
    try {
      await Future.wait(_K.all.map(_prefs.remove));
      return const Right(unit);
    } catch (e, st) {
      return Left(ErrorHandler.handle(e, st));
    }
  }
}
