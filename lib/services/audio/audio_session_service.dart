import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// Centralises audio session configuration and interruption handling.
///
/// Call [init] once during app start-up (after the audio layer is wired but
/// before any track is loaded) so the OS knows Troona is a **music** app and
/// can deliver focus/noisy callbacks to this service.
final class AudioSessionService {
  AudioSessionService(this._audio, this._settings);

  final AudioServicePort _audio;
  AppSettings _settings;

  late final AudioSession _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _noisySub;
  StreamSubscription<double>? _volumeSub;

  double _preDuckVolume = 1.0;
  double _currentVolume = 1.0;
  bool _isDucked = false;
  bool _isInitialized = false;

  /// Configure the shared audio session and register interruption handlers.
  Future<void> init() async {
    _session = await AudioSession.instance;
    await _session.configure(AudioSessionConfiguration.music());
    _isInitialized = true;

    // Track live volume to avoid race when multiple ducks happen quickly.
    _volumeSub = _audio.volumeStream.listen((v) => _currentVolume = v);

    // Pause when headphones are unplugged / audio route changes to speaker.
    _noisySub = _session.becomingNoisyEventStream.listen((_) async {
      await _audio.pause();
      appLogger.i('AudioSessionService: becoming noisy → pause');
    });

    // Handle audio focus / interruptions (GPS prompts, phone calls, etc.).
    _interruptionSub = _session.interruptionEventStream.listen(
      _handleInterruption,
    );
  }

  Future<void> _handleInterruption(AudioInterruptionEvent event) async {
    if (!_isInitialized) return;

    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          if (!_settings.duckAudioOnNotification) {
            await _audio.pause();
            appLogger.i(
              'AudioSessionService: duck ignored by setting, pausing',
            );
            break;
          }
          if (!_isDucked) {
            _preDuckVolume = _currentVolume;
            _isDucked = true;
            await _audio.setVolume(0.3);
            appLogger.i(
              'AudioSessionService: duck start → volume 0.3 (was $_preDuckVolume)',
            );
          }
          break;
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (_settings.stopOnCallEnabled) {
            await _audio.pause();
            appLogger.i('AudioSessionService: pause interruption');
          }
          break;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          if (_isDucked) {
            await _audio.setVolume(_preDuckVolume);
            _isDucked = false;
            appLogger.i(
              'AudioSessionService: duck end → volume $_preDuckVolume',
            );
          }
          break;
        case AudioInterruptionType.pause:
          if (_settings.resumeAfterCallEnabled && _shouldResume(event)) {
            await _audio.resume();
            appLogger.i('AudioSessionService: resume after interruption');
          } else {
            appLogger.i(
              'AudioSessionService: interruption ended, not resuming (shouldResume==false)',
            );
          }
          break;
        case AudioInterruptionType.unknown:
          // Do nothing — explicit user action will restart playback.
          break;
      }
    }
  }

  Future<void> dispose() async {
    await _interruptionSub?.cancel();
    await _noisySub?.cancel();
    await _volumeSub?.cancel();
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
  }

  /// Some platforms expose a `shouldResume` hint on the interruption event.
  /// Access it dynamically to stay compatible across versions/OS; default true.
  bool _shouldResume(AudioInterruptionEvent event) {
    try {
      final dynamic e = event;
      final value = e.shouldResume;
      if (value is bool) return value;
    } catch (_) {
      // Field absent or inaccessible — fall back to resume.
    }
    return true;
  }
}
