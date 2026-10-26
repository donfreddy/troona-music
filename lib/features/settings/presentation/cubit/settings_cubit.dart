import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/glass_theme.dart' as glass;
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';
import 'package:troona/services/audio/audio_session_service.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;

  /// Optional — propagates runtime setting changes to the audio session
  /// (call ducking, headphone unplug behaviour, etc.) without an app restart.
  final AudioSessionService? _audioSession;

  SettingsCubit(this._repo, [this._audioSession])
    : super(const SettingsState.loading());

  // Init
  Future<void> load() async {
    final result = await _repo.loadSettings();
    result.fold((failure) => emit(SettingsState.error(failure.message)), (
      settings,
    ) {
      AppHaptics.enabled = settings.hapticFeedbackEnabled;
      emit(SettingsState.loaded(settings));
    });
  }

  AppSettings? get _current => state.mapOrNull(loaded: (s) => s.settings);

  Future<void> _update(AppSettings Function(AppSettings s) updater) async {
    final current = _current;
    if (current == null) return;
    final updated = updater(current);
    emit(SettingsState.loaded(updated)); // optimistic
    final result = await _repo.saveSettings(updated);
    result.fold(
      (_) {
        AppHaptics.enabled = current.hapticFeedbackEnabled;
        emit(SettingsState.loaded(current)); // rollback on error
      },
      (_) => _audioSession?.updateSettings(updated), // sync audio session
    );
  }

  // Playback
  Future<void> setStopOnCall(bool value) =>
      _update((s) => s.copyWith(stopOnCallEnabled: value));

  Future<void> setResumeAfterCall(bool value) =>
      _update((s) => s.copyWith(resumeAfterCallEnabled: value));

  Future<void> setDuckAudioOnNotification(bool value) =>
      _update((s) => s.copyWith(duckAudioOnNotification: value));

  // Online Metadata & Artwork
  Future<void> setFetchOnlineMetadata(bool value) =>
      _update((s) => s.copyWith(fetchOnlineMetadata: value));

  Future<void> setFetchArtistArtwork(bool value) =>
      _update((s) => s.copyWith(fetchArtistArtwork: value));

  /// Turns both online extras on or off at once (Home offer card).
  Future<void> setOnlineExtras(bool enabled) => _update(
    (s) => s.copyWith(
      fetchOnlineMetadata: enabled,
      fetchArtistArtwork: enabled,
      onlineExtrasOffered: true,
    ),
  );

  Future<void> dismissOnlineExtrasOffer() =>
      _update((s) => s.copyWith(onlineExtrasOffered: true));

  // UI

  Future<void> setHapticFeedback(bool value) {
    AppHaptics.enabled = value;
    return _update((s) => s.copyWith(hapticFeedbackEnabled: value));
  }

  Future<void> setGlassQuality(GlassQuality quality) {
    glass.GlassTheme.overrideQuality(
      quality == glass.GlassQuality.auto ? null : quality,
    );
    return _update((s) => s.copyWith(glassQuality: quality));
  }

  // Reset
  Future<void> resetToDefaults() async {
    await _repo.resetSettings();
    await load();
  }
}
