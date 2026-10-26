/// Decides when a listen counts as a play: after 30 s of listening, or
/// half the track when it is shorter than a minute.
///
/// Only listening counts: position jumps (seeks) are ignored, and a paused
/// player sends no positions. Going back to the start of the track (repeat
/// one, a replay from the top) starts a new listen.
final class PlayCounter {
  PlayCounter({this.minListen = const Duration(seconds: 30)});

  final Duration minListen;

  /// Longest position step still taken as playback rather than a seek.
  static const maxStep = Duration(seconds: 2);

  /// A backward jump landing this close to the start is a new listen.
  static const restartWindow = Duration(seconds: 3);

  String? _trackId;
  Duration _threshold = Duration.zero;
  Duration _listened = Duration.zero;
  Duration? _last;
  bool _counted = false;
  Duration _heard = Duration.zero;

  String? get trackId => _trackId;

  /// Listening between the last two positions: zero after a seek, a
  /// restart or the first position of a listen. Counted plays included.
  Duration get heard => _heard;

  /// Starts a listen of [trackId]. A zero [trackDuration] means unknown.
  void start(String trackId, Duration trackDuration) {
    final half = trackDuration ~/ 2;
    _trackId = trackId;
    _threshold = trackDuration > Duration.zero && half < minListen
        ? half
        : minListen;
    _listened = Duration.zero;
    _last = null;
    _counted = false;
  }

  void stop() => _trackId = null;

  /// Returns the track id on the position that makes the listen count,
  /// once per listen; null otherwise.
  String? onPosition(Duration position) {
    _heard = Duration.zero;
    final id = _trackId;
    if (id == null) return null;
    final last = _last;
    _last = position;
    if (last == null) return null;

    final step = position - last;
    if (step.isNegative) {
      if (position < restartWindow && -step > maxStep) {
        _listened = Duration.zero;
        _counted = false;
      }
      return null;
    }
    if (step > maxStep) return null;
    _heard = step;
    if (_counted) return null;

    _listened += step;
    if (_listened < _threshold) return null;
    _counted = true;
    return id;
  }
}
