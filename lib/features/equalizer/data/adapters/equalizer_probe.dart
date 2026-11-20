import 'package:shared_preferences/shared_preferences.dart';

/// Keeps a phone whose effects break playback from losing its music.
///
/// The effects are made by the platform when the player starts, and if the
/// phone cannot make them (a modified ROM, an effects engine out of room),
/// loading a song fails, or the app dies. Before the first load with the
/// effects the probe is [arm]ed, once the effects are made it is [disarm]ed.
/// A launch that ends armed is a strike; [strikesToBreak] in a row and the
/// player is built without the effects from then on ([broken]). One strike
/// alone may be the app killed at the wrong moment, and a launch that goes
/// through forgives the strikes before it.
final class EqualizerProbe {
  EqualizerProbe(this._prefs);

  final SharedPreferences _prefs;

  static const strikesToBreak = 2;
  static const _strikes = 'equalizer_probe_strikes';
  static const _broken = 'equalizer_broken';

  int _strikesBefore = 0;
  Future<void>? _arming;
  bool _armed = false;
  bool _done = false;

  /// Read once at start-up, before the player is built. Never throws: a
  /// preference that cannot be read or written keeps the effects.
  Future<bool> broken() async {
    try {
      if (_prefs.getBool(_broken) ?? false) return true;
      _strikesBefore = _prefs.getInt(_strikes) ?? 0;
      if (_strikesBefore < strikesToBreak) return false;
      await _prefs.setBool(_broken, true);
      await _prefs.remove(_strikes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Before a load: written before the platform makes the effects, once a
  /// launch. Loads asked for meanwhile wait for the same write, so they
  /// still start in the order they were asked; null once written, so later
  /// loads do not wait at all.
  Future<void>? arm() {
    if (_done || _armed) return null;
    // A failed write must not fail the load: the probe is a safety net.
    return _arming ??= _prefs
        .setInt(_strikes, _strikesBefore + 1)
        .then((_) {}, onError: (Object _) {})
        .whenComplete(() => _armed = true);
  }

  /// The effects are made: this launch went through.
  Future<void> disarm() async {
    if (_done) return;
    _done = true;
    // After the arming write, or that write would come last.
    await _arming;
    try {
      await _prefs.remove(_strikes);
    } catch (_) {
      // Left armed: one more strike, the safe side.
    }
  }
}
