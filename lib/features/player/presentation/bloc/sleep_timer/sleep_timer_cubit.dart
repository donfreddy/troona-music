import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

part 'sleep_timer_state.dart';

/// Pauses playback after a delay, or at the end of the current track.
///
/// A timed stop fades the volume out over [fadeDuration] first, then pauses
/// and puts the volume back, so the next play is not silent. Singleton: the
/// timer outlives the Now Playing page.
final class SleepTimerCubit extends Cubit<SleepTimerState> {
  final AudioServicePort _port;
  final DateTime Function() _now;

  /// Length of the fade before a timed stop.
  static const fadeDuration = Duration(seconds: 10);
  static const _fadeSteps = 20;

  Timer? _fadeStart;
  Timer? _fadeTick;
  StreamSubscription<Track?>? _trackSub;
  late final StreamSubscription<double> _volumeSub;

  /// The user's volume, so a fade starts from it and comes back to it.
  double _volume = 1;
  double? _volumeBeforeFade;

  SleepTimerCubit({required AudioServicePort port, DateTime Function()? now})
    : _port = port,
      _now = now ?? DateTime.now,
      super(const SleepTimerOff()) {
    _volumeSub = port.volumeStream.listen((v) {
      // The fade's own steps must not become the volume to restore.
      if (_fadeTick == null) _volume = v;
    });
  }

  /// Pauses after [duration], fading out over its last [fadeDuration].
  void startFor(Duration duration) {
    _reset();
    final fadeIn = duration - fadeDuration;
    _fadeStart = Timer(fadeIn.isNegative ? Duration.zero : fadeIn, _fadeOut);
    emit(SleepTimerRunning(endsAt: _now().add(duration)));
  }

  /// Pauses when the current track ends.
  void startEndOfTrack() {
    _reset();
    // Compared by id: the port's stream may replay the current track on
    // listen. With repeat one the track never changes, so nothing stops.
    final current = _port.currentTrack?.id;
    _trackSub = _port.currentTrackStream
        .where((track) => track?.id != current)
        .listen((_) => _stop());
    emit(const SleepTimerEndOfTrack());
  }

  /// Cancels the timer. Playback goes on; a fade in progress is undone.
  void cancel() {
    final restore = _volumeBeforeFade;
    _reset();
    emit(const SleepTimerOff());
    if (restore != null) unawaited(_port.setVolume(restore));
  }

  void _fadeOut() {
    final start = _volumeBeforeFade = _volume;
    var step = 0;
    _fadeTick = Timer.periodic(fadeDuration ~/ _fadeSteps, (timer) {
      step++;
      unawaited(_port.setVolume(start * (1 - step / _fadeSteps)));
      if (step >= _fadeSteps) _stop();
    });
  }

  Future<void> _stop() async {
    final restore = _volumeBeforeFade;
    _reset();
    emit(const SleepTimerOff());
    // The timer's own fade is over: the player's would only add a delay.
    await _port.pause(fade: false);
    if (restore != null) await _port.setVolume(restore);
  }

  void _reset() {
    _fadeStart?.cancel();
    _fadeTick?.cancel();
    _trackSub?.cancel();
    _fadeStart = null;
    _fadeTick = null;
    _trackSub = null;
    _volumeBeforeFade = null;
  }

  @override
  Future<void> close() async {
    _reset();
    await _volumeSub.cancel();
    return super.close();
  }
}
