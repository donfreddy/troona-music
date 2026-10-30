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
  static const fetchOnlineMetadata = 'online_bios_enabled';
  static const fetchArtistArtwork = 'online_photos_enabled';
  static const onlineExtrasOffered = 'online_extras_offered';
  static const checkForUpdates = 'update_check_enabled';
  static const hapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const glassQuality = 'glass_quality';

  static const all = [
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
          fetchOnlineMetadata: _bool(
            _K.fetchOnlineMetadata,
            d.fetchOnlineMetadata,
          ),
          fetchArtistArtwork: _bool(
            _K.fetchArtistArtwork,
            d.fetchArtistArtwork,
          ),
          onlineExtrasOffered: _bool(
            _K.onlineExtrasOffered,
            d.onlineExtrasOffered,
          ),
          checkForUpdates: _bool(_K.checkForUpdates, d.checkForUpdates),
          hapticFeedbackEnabled: _bool(
            _K.hapticFeedbackEnabled,
            d.hapticFeedbackEnabled,
          ),
          glassQuality: _loadEnum(
            key: _K.glassQuality,
            values: GlassQuality.values,
            defaultValue: d.glassQuality,
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
        _prefs.setBool(_K.fetchOnlineMetadata, s.fetchOnlineMetadata),
        _prefs.setBool(_K.fetchArtistArtwork, s.fetchArtistArtwork),
        _prefs.setBool(_K.onlineExtrasOffered, s.onlineExtrasOffered),
        _prefs.setBool(_K.checkForUpdates, s.checkForUpdates),
        _prefs.setBool(_K.hapticFeedbackEnabled, s.hapticFeedbackEnabled),
        _prefs.setString(_K.glassQuality, s.glassQuality.name),
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
