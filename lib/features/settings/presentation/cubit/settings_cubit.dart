import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/glass_theme.dart' as glass;
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';
import 'package:troona/services/audio/audio_session_service.dart';

part 'settings_state.dart';

/// App-wide singleton: Home's offer card and the Settings page share one
/// state. A per-screen instance saved a stale copy of every setting over
/// changes made elsewhere.
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;

  /// Optional: propagates runtime setting changes to the audio session
  /// (call ducking, headphone unplug behaviour, etc.) without an app restart.
  final AudioSessionService? _audioSession;

  /// Optional: forgets downloaded photos when the photos switch goes off.
  final MetadataRepository? _metadata;

  SettingsCubit(this._repo, [this._audioSession, this._metadata])
    : super(const SettingsState.loading());

  /// The cubit outlives every screen: a failed first load must not leave
  /// Settings on its error state for the whole session.
  void retryIfFailed() {
    if (state is SettingsError) load();
  }

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

  /// Pushes [settings] to the services that cache them.
  void _applyRuntime(AppSettings settings) {
    AppHaptics.enabled = settings.hapticFeedbackEnabled;
    glass.GlassTheme.overrideQuality(
      settings.glassQuality == glass.GlassQuality.auto
          ? null
          : settings.glassQuality,
    );
    _audioSession?.updateSettings(settings);
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
  // Either switch answers Home's one-time offer.
  Future<void> setFetchOnlineMetadata(bool value) => _update(
    (s) => s.copyWith(fetchOnlineMetadata: value, onlineExtrasOffered: true),
  );

  Future<void> setFetchArtistArtwork(bool value) async {
    await _update(
      (s) => s.copyWith(fetchArtistArtwork: value, onlineExtrasOffered: true),
    );
    await _forgetPhotosIfOff();
  }

  /// Turns both online extras on or off at once (Home offer card).
  Future<void> setOnlineExtras(bool enabled) async {
    await _update(
      (s) => s.copyWith(
        fetchOnlineMetadata: enabled,
        fetchArtistArtwork: enabled,
        onlineExtrasOffered: true,
      ),
    );
    await _forgetPhotosIfOff();
  }

  // Off means no online photo on screen, including ones already downloaded.
  Future<void> _forgetPhotosIfOff() async {
    if (_current?.fetchArtistArtwork == false) await _metadata?.forgetPhotos();
  }

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
    if (_current case final settings?) _applyRuntime(settings);
    await _forgetPhotosIfOff();
  }
}
