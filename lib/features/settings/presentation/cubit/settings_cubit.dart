import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/core/theme/components/glass_theme.dart' as glass;
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';
import 'package:troona/services/audio/audio_session_service.dart';

part 'settings_state.dart';

@injectable
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;
  final PlaybackSessionStore? _playbackSessionStore;

  /// Optional — propagates runtime setting changes to the audio session
  /// (call ducking, headphone unplug behaviour, etc.) without an app restart.
  final AudioSessionService? _audioSession;

  SettingsCubit(this._repo, [this._audioSession, this._playbackSessionStore])
    : super(const SettingsState.loading());

  // Init
  Future<void> load() async {
    final result = await _repo.loadSettings();
    result.fold(
      (failure) => emit(SettingsState.error(failure.message)),
      (settings) => emit(SettingsState.loaded(settings)),
    );
  }

  AppSettings? get _current => state.mapOrNull(loaded: (s) => s.settings);

  Future<void> _update(AppSettings Function(AppSettings s) updater) async {
    final current = _current;
    if (current == null) return;
    final updated = updater(current);
    emit(SettingsState.loaded(updated)); // optimistic
    final result = await _repo.saveSettings(updated);
    result.fold(
      (_) => emit(SettingsState.loaded(current)), // rollback on error
      (_) => _audioSession?.updateSettings(updated), // sync audio session
    );
  }

  // Appearance
  Future<void> setThemeMode(AppThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setUseDynamicColor(bool value) =>
      _update((s) => s.copyWith(useDynamicColor: value));

  // Playback
  Future<void> setGaplessPlayback(bool value) =>
      _update((s) => s.copyWith(gaplessPlayback: value));

  Future<void> setCrossfade({
    required bool enabled,
    int? durationMs,
    CrossfadeStyle? style,
  }) => _update(
    (s) => s.copyWith(
      crossfadeEnabled: enabled,
      crossfadeDurationMs: durationMs,
      crossfadeStyle: style,
    ),
  );

  Future<void> setStopOnCall(bool value) =>
      _update((s) => s.copyWith(stopOnCallEnabled: value));

  Future<void> setResumeAfterCall(bool value) =>
      _update((s) => s.copyWith(resumeAfterCallEnabled: value));

  Future<void> setDuckAudioOnNotification(bool value) =>
      _update((s) => s.copyWith(duckAudioOnNotification: value));

  // Library
  Future<void> setScanOnStartup(bool value) =>
      _update((s) => s.copyWith(scanOnStartup: value));

  Future<void> setWatchFolderChanges(bool value) =>
      _update((s) => s.copyWith(watchFolderChanges: value));

  // UI
  Future<void> setShowAlbumArtInNotification(bool value) =>
      _update((s) => s.copyWith(showAlbumArtInNotification: value));

  Future<void> setHapticFeedback(bool value) =>
      _update((s) => s.copyWith(hapticFeedbackEnabled: value));

  Future<void> setGlassQuality(GlassQuality quality) {
    glass.GlassTheme.overrideQuality(glass.GlassQuality.values[quality.index]);
    return _update((s) => s.copyWith(glassQuality: quality));
  }

  // Sleep timer
  Future<void> setSleepTimer({required bool enabled, int? minutes}) => _update(
    (s) => s.copyWith(sleepTimerEnabled: enabled, sleepTimerMinutes: minutes),
  );

  // Reset
  Future<void> resetToDefaults() async {
    await _repo.resetSettings();
    await load();
  }

  Future<void> clearPlaybackSession() async {
    await _playbackSessionStore?.clear();
  }
}
