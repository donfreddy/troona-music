import 'dart:async';
import 'dart:math' as math;

/// Moves a gain between 0 and 1 smoothly, one step every [step].
///
/// The ramp is linear on the square root of the gain: perceived loudness
/// follows amplitude roughly that way, so a fade sounds even instead of
/// dropping off at its quiet end.
///
/// A new ramp, or a [jump], takes over from wherever the gain is: quick
/// play and pause taps reverse a fade instead of restarting it.
final class GainRamp {
  GainRamp(this._apply, {this.step = const Duration(milliseconds: 20)});

  /// Sends a gain to the player.
  final Future<void> Function(double gain) _apply;

  /// Time between two steps. Finer than an audio buffer is wasted.
  final Duration step;

  double _gain = 1;
  int _token = 0;

  double get gain => _gain;

  /// Sets [gain] at once, stopping any ramp.
  Future<void> jump(double gain) {
    _token++;
    _gain = gain;
    return _apply(gain);
  }

  /// Stops any ramp where it is.
  void stop() => _token++;

  /// Ramps to [target]. A full sweep (0 to 1) lasts [duration], a shorter
  /// one proportionally less. True once there, false when a newer ramp or a
  /// [jump] took over.
  Future<bool> to(double target, Duration duration) async {
    final token = ++_token;
    final from = math.sqrt(_gain);
    final end = math.sqrt(target);
    final steps =
        (duration.inMicroseconds * (end - from).abs() / step.inMicroseconds)
            .ceil();
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(step);
      if (token != _token) return false;
      final level = from + (end - from) * i / steps;
      _gain = level * level;
      await _apply(_gain);
    }
    if (token != _token) return false;
    _gain = target;
    return true;
  }
}
