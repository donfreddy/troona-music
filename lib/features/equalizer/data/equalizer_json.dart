import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/services/eq_presets.dart';

/// The equalizer as JSON, for the preferences and for backups.
///
/// A backup is untrusted input, so [decodeSettings] and [decodeProfiles]
/// check every value and give null on the first one out of bounds: the
/// equalizer is then left out, the rest of the backup still restores.
abstract final class EqualizerJson {
  static const _maxPoints = 64;

  /// Wider than any phone's equalizer, which the gains are fitted to.
  static const _maxDb = 30.0;

  static Map<String, Object?> encodeSettings(EqualizerSettings s) => {
    'enabled': s.enabled,
    'preset': s.presetId,
    'points': _encodeCurve(s.curve),
    'boost_db': s.boostDb,
    'anti_clip': s.antiClip,
  };

  static EqualizerSettings? decodeSettings(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final enabled = json['enabled'];
    final preset = json['preset'];
    final curve = _decodeCurve(json['points']);
    final boost = _number(json['boost_db']);
    final antiClip = json['anti_clip'];
    if (enabled is! bool || antiClip is! bool || curve == null) return null;
    if (preset != null && preset is! String) return null;
    if (boost == null || boost < 0 || boost > EqualizerSettings.maxBoostDb) {
      return null;
    }
    return EqualizerSettings(
      enabled: enabled,
      presetId: _knownPreset(preset as String?),
      curve: curve,
      boostDb: boost,
      antiClip: antiClip,
    );
  }

  /// A preset of this version, or a profile's key; anything else counts as
  /// a curve drawn by hand.
  static String? _knownPreset(String? id) {
    if (id == null) return null;
    if (EqPresets.byId(id) != null) return id;
    final profile = EqPresets.profileIdOf(id);
    return profile != null && profile.isNotEmpty && profile.length <= 64
        ? id
        : null;
  }

  static List<Object?> encodeProfiles(List<EqProfile> profiles) => [
    for (final p in profiles)
      {'id': p.id, 'name': p.name, 'points': _encodeCurve(p.curve)},
  ];

  static List<EqProfile>? decodeProfiles(Object? json) {
    if (json is! List) return null;
    // More than the cap: the first ones are kept, not the whole list
    // dropped.
    final items = json.take(EqProfile.maxCount);
    final profiles = <EqProfile>[];
    final ids = <String>{};
    for (final item in items) {
      if (item is! Map<String, Object?>) return null;
      final id = item['id'];
      final name = item['name'];
      final curve = _decodeCurve(item['points']);
      if (id is! String || id.isEmpty || id.length > 64) return null;
      if (name is! String || name.trim().isEmpty) return null;
      if (name.length > EqProfile.maxNameLength ||
          curve == null ||
          !ids.add(id)) {
        return null;
      }
      profiles.add(EqProfile(id: id, name: name, curve: curve));
    }
    return profiles;
  }

  static Map<String, Object?> encodeLayout(EqLayout layout) => {
    'min': layout.minDb,
    'max': layout.maxDb,
    'bands': [
      for (final b in layout.bands) [b.lowHz, b.centerHz, b.highHz],
    ],
  };

  static EqLayout? decodeLayout(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final min = _number(json['min']);
    final max = _number(json['max']);
    final bands = json['bands'];
    if (min == null || max == null || min >= max || bands is! List) {
      return null;
    }
    if (bands.isEmpty || bands.length > _maxPoints) return null;
    final read = <EqBand>[];
    for (final b in bands) {
      if (b is! List || b.length != 3) return null;
      final [low, center, high] = [for (final v in b) _number(v)];
      if (low == null || center == null || high == null) return null;
      if (center <= 0) return null;
      read.add(EqBand(lowHz: low, centerHz: center, highHz: high));
    }
    return EqLayout(bands: read, minDb: min, maxDb: max);
  }

  static List<Object?> _encodeCurve(EqCurve curve) => [
    for (final p in curve.points) [p.hz, p.db],
  ];

  static EqCurve? _decodeCurve(Object? json) {
    if (json is! List || json.length > _maxPoints) return null;
    final points = <EqPoint>[];
    for (final p in json) {
      if (p is! List || p.length != 2) return null;
      final hz = _number(p[0]);
      final db = _number(p[1]);
      if (hz == null || db == null || hz <= 0 || hz > 100000) return null;
      if (db.abs() > _maxDb) return null;
      points.add(EqPoint(hz, db));
    }
    return EqCurve(points);
  }

  static double? _number(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;
}
