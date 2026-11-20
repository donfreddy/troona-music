import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';

/// The presets shipped with the app, defined at ten frequencies so they fit
/// any phone's bands.
///
/// Starting values, kept mild (6 dB at most) to limit clipping: tuned by
/// ear, not measured.
abstract final class EqPresets {
  static const flatId = 'flat';

  /// The anchors of every preset, in hertz.
  static const _hz = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

  static EqPreset _preset(String id, List<double> db) => EqPreset(
    id,
    EqCurve([
      for (var i = 0; i < _hz.length; i++) EqPoint(_hz[i] * 1.0, db[i]),
    ]),
  );

  /// Flat first, then in the order the sheet shows them.
  static final all = List<EqPreset>.unmodifiable([
    const EqPreset(flatId, EqCurve.flat),
    _preset('bass_boost', [6, 5, 4, 2, 0, 0, 0, 0, 0, 0]),
    _preset('acoustic', [3, 3, 2, 1, 1, 1, 2, 3, 2, 2]),
    _preset('electronic', [4, 4, 1, 0, -2, 2, 1, 1, 4, 5]),
    _preset('vocal', [-2, -3, -3, 1, 3, 4, 3, 2, 0, -1]),
    _preset('rock', [4, 3, 2, 1, -1, -1, 1, 2, 3, 4]),
    _preset('hip_hop', [5, 4, 1, 2, -1, -1, 1, 0, 2, 3]),
    _preset('jazz', [3, 2, 1, 2, -1, -1, 0, 1, 2, 3]),
    _preset('treble_boost', [0, 0, 0, 0, 0, 1, 2, 3, 4, 5]),
  ]);

  static EqPreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const _profilePrefix = 'profile:';

  /// The [EqualizerSettings.presetId] of a profile.
  static String profileKey(String profileId) => '$_profilePrefix$profileId';

  /// The profile's id in [key], null when [key] names a preset.
  static String? profileIdOf(String? key) =>
      key != null && key.startsWith(_profilePrefix)
      ? key.substring(_profilePrefix.length)
      : null;
}
