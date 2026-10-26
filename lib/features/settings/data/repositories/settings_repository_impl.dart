import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

// ── Clés SharedPreferences ────────────────────────────────────────────────────
abstract final class _K {
  // Appearance
  static const themeMode = 'theme_mode';
  static const useDynamicColor = 'use_dynamic_color';
  // Playback
  static const gaplessPlayback = 'gapless_playback';
  static const crossfadeEnabled = 'crossfade_enabled';
  static const crossfadeDurationMs = 'crossfade_duration_ms';
  static const crossfadeStyle = 'crossfade_style';
  static const stopOnCallEnabled = 'stop_on_call_enabled';
  static const resumeAfterCallEnabled = 'resume_after_call_enabled';
  static const duckAudioOnNotification = 'duck_audio_on_notification';
  // Library
  static const scanOnStartup = 'scan_on_startup';
  static const watchFolderChanges = 'watch_folder_changes';
  // UI
  static const showAlbumArtInNotification = 'show_album_art_in_notification';
  static const hapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const glassQuality = 'glass_quality';
  // Sleep timer
  static const sleepTimerEnabled = 'sleep_timer_enabled';
  static const sleepTimerMinutes = 'sleep_timer_minutes';
}

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;

  const SettingsRepositoryImpl(this._prefs);

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

  // ── Interface ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppSettings>> loadSettings() async {
    try {
      const d = AppSettings(); // valeurs par défaut
      final settings = AppSettings(
        // Appearance
        themeMode: _loadEnum(
          key: _K.themeMode,
          values: AppThemeMode.values,
          defaultValue: d.themeMode,
        ),
        useDynamicColor:
            _prefs.getBool(_K.useDynamicColor) ?? d.useDynamicColor,
        // Playback
        gaplessPlayback:
            _prefs.getBool(_K.gaplessPlayback) ?? d.gaplessPlayback,
        crossfadeEnabled:
            _prefs.getBool(_K.crossfadeEnabled) ?? d.crossfadeEnabled,
        crossfadeDurationMs:
            _prefs.getInt(_K.crossfadeDurationMs) ?? d.crossfadeDurationMs,
        crossfadeStyle: _loadEnum(
          key: _K.crossfadeStyle,
          values: CrossfadeStyle.values,
          defaultValue: d.crossfadeStyle,
        ),
        stopOnCallEnabled:
            _prefs.getBool(_K.stopOnCallEnabled) ?? d.stopOnCallEnabled,
        resumeAfterCallEnabled:
            _prefs.getBool(_K.resumeAfterCallEnabled) ??
            d.resumeAfterCallEnabled,
        duckAudioOnNotification:
            _prefs.getBool(_K.duckAudioOnNotification) ??
            d.duckAudioOnNotification,
        // Library
        scanOnStartup: _prefs.getBool(_K.scanOnStartup) ?? d.scanOnStartup,
        watchFolderChanges:
            _prefs.getBool(_K.watchFolderChanges) ?? d.watchFolderChanges,
        // UI
        showAlbumArtInNotification:
            _prefs.getBool(_K.showAlbumArtInNotification) ??
            d.showAlbumArtInNotification,
        hapticFeedbackEnabled:
            _prefs.getBool(_K.hapticFeedbackEnabled) ?? d.hapticFeedbackEnabled,
        glassQuality: _loadEnum(
          key: _K.glassQuality,
          values: GlassQuality.values,
          defaultValue: d.glassQuality,
        ),
        // Sleep timer
        sleepTimerEnabled:
            _prefs.getBool(_K.sleepTimerEnabled) ?? d.sleepTimerEnabled,
        sleepTimerMinutes:
            _prefs.getInt(_K.sleepTimerMinutes) ?? d.sleepTimerMinutes,
      );
      return Right(settings);
    } catch (e, st) {
      return Left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings s) async {
    try {
      await Future.wait([
        // Appearance
        _prefs.setString(_K.themeMode, s.themeMode.name),
        _prefs.setBool(_K.useDynamicColor, s.useDynamicColor),
        _prefs.setBool(_K.gaplessPlayback, s.gaplessPlayback),
        _prefs.setBool(_K.crossfadeEnabled, s.crossfadeEnabled),
        _prefs.setInt(_K.crossfadeDurationMs, s.crossfadeDurationMs),
        _prefs.setString(_K.crossfadeStyle, s.crossfadeStyle.name),
        _prefs.setBool(_K.stopOnCallEnabled, s.stopOnCallEnabled),
        _prefs.setBool(_K.resumeAfterCallEnabled, s.resumeAfterCallEnabled),
        _prefs.setBool(_K.duckAudioOnNotification, s.duckAudioOnNotification),
        _prefs.setBool(_K.scanOnStartup, s.scanOnStartup),
        _prefs.setBool(_K.watchFolderChanges, s.watchFolderChanges),
        _prefs.setBool(
          _K.showAlbumArtInNotification,
          s.showAlbumArtInNotification,
        ),
        _prefs.setBool(_K.hapticFeedbackEnabled, s.hapticFeedbackEnabled),
        _prefs.setString(_K.glassQuality, s.glassQuality.name),
        _prefs.setBool(_K.sleepTimerEnabled, s.sleepTimerEnabled),
        _prefs.setInt(_K.sleepTimerMinutes, s.sleepTimerMinutes),
      ]);
      return const Right(unit);
    } catch (e, st) {
      return Left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetSettings() async {
    try {
      await _prefs.clear();
      return const Right(unit);
    } catch (e, st) {
      return Left(ErrorHandler.handle(e, st));
    }
  }
}
