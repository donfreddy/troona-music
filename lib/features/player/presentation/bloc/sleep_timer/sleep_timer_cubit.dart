import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

part 'sleep_timer_state.dart';

/// Pauses playback after a delay, or at the end of the current track.
///
/// The stop is a pause with a long fade, run by the player: the user's
/// volume is never touched, and playing again during the fade takes the
/// volume back up and ends the timer. The state stays on until the fade is
/// over. Singleton: the timer outlives the Now Playing page.
final class SleepTimerCubit extends Cubit<SleepTimerState> {
  final AudioServicePort _port;
  final DateTime Function() _now;

  /// Length of the fade before a stop; half the timer when it is shorter.
  static const fadeDuration = Duration(seconds: 30);

  /// The end-of-track fade is over this long before the track ends:
  /// positions arrive every few hundred milliseconds, and the next track
  /// must not be heard.
  static const endOfTrackMargin = Duration(milliseconds: 500);

  Timer? _fadeStart;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Track?>? _trackSub;
  late final StreamSubscription<double> _speedSub;

  double _speed = 1;
  bool _fading = false;

  /// Bumped by every start and cancel: a fade they replaced must not turn
  /// the new timer off.
  int _generation = 0;

  /// Time left in the track at the last position, at playback speed.
  Duration? _remaining;

  SleepTimerCubit({required AudioServicePort port, DateTime Function()? now})
    : _port = port,
      _now = now ?? DateTime.now,
      super(const SleepTimerOff()) {
    _speedSub = port.speedStream.listen((speed) => _speed = speed);
  }

  /// Pauses after [duration], fading out over its last [fadeDuration].
  void startFor(Duration duration) {
    _restart();
    final fade = duration < fadeDuration * 2 ? duration ~/ 2 : fadeDuration;
    _fadeStart = Timer(duration - fade, () => _stop(fade));
    emit(SleepTimerRunning(endsAt: _now().add(duration)));
  }

  /// Pauses when the track playing ends, fading out over its last
  /// [fadeDuration]. A skip moves the stop to the end of the new track.
  void startEndOfTrack() {
    _restart();
    _remaining = null;
    _positionSub = _port.positionStream.listen(_checkEndOfTrack);
    // Compared by id: the port's stream may replay the current track on
    // listen.
    var current = _port.currentTrack?.id;
    _trackSub = _port.currentTrackStream.listen((track) {
      if (track?.id == current) return;
      current = track?.id;
      // The track ended without the fade (unknown duration, no position
      // near the end): stop now. Otherwise it was a skip.
      final remaining = _remaining;
      _remaining = null;
      if (remaining == null || remaining <= const Duration(seconds: 2)) {
        _stop(Duration.zero);
      }
    });
    emit(const SleepTimerEndOfTrack());
  }

  /// Cancels the timer. Playback goes on; a fade in progress is undone.
  void cancel() {
    _restart();
    emit(const SleepTimerOff());
  }

  void _checkEndOfTrack(Duration position) {
    final duration = _port.currentDuration;
    if (duration <= Duration.zero) return;
    _remaining = (duration - position) * (1 / _speed);
    if (_port.currentStatus != PlaybackStatus.playing) return;
    final left = _remaining! - endOfTrackMargin;
    if (left <= fadeDuration) _stop(left.isNegative ? Duration.zero : left);
  }

  /// Pauses over [fade]. The state goes off once the player is paused, or
  /// once a play during the fade took over.
  Future<void> _stop(Duration fade) async {
    _clear();
    _fading = true;
    final generation = _generation;
    await _port.pause(fade: fade);
    if (generation != _generation) return;
    _fading = false;
    emit(const SleepTimerOff());
  }

  /// Clears the timer, taking back a fade in progress.
  void _restart() {
    final wasFading = _fading;
    _generation++;
    _clear();
    _fading = false;
    if (wasFading) unawaited(_port.resume());
  }

  void _clear() {
    _fadeStart?.cancel();
    _positionSub?.cancel();
    _trackSub?.cancel();
    _fadeStart = null;
    _positionSub = null;
    _trackSub = null;
  }

  @override
  Future<void> close() async {
    _clear();
    await _speedSub.cancel();
    return super.close();
  }
}
