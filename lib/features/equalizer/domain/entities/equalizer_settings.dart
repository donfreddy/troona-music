import 'package:equatable/equatable.dart';
import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/services/eq_presets.dart';

/// The equalizer as the user left it.
final class EqualizerSettings extends Equatable {
  final bool enabled;

  /// What [curve] came from: a preset's id, a profile's
  /// ([EqPresets.profileKey]), or null once the curve was changed by hand.
  final String? presetId;
  final EqCurve curve;

  /// The loudness enhancer's gain, from 0 to [maxBoostDb].
  final double boostDb;

  /// Lowers the level by the highest band's gain, so a boost does not clip.
  final bool antiClip;

  /// Past this, distortion becomes likely.
  static const maxBoostDb = 6.0;

  const EqualizerSettings({
    this.enabled = false,
    this.presetId = EqPresets.flatId,
    this.curve = EqCurve.flat,
    this.boostDb = 0,
    this.antiClip = true,
  });

  EqualizerSettings copyWith({
    bool? enabled,
    String? Function()? presetId,
    EqCurve? curve,
    double? boostDb,
    bool? antiClip,
  }) => EqualizerSettings(
    enabled: enabled ?? this.enabled,
    presetId: presetId != null ? presetId() : this.presetId,
    curve: curve ?? this.curve,
    boostDb: boostDb ?? this.boostDb,
    antiClip: antiClip ?? this.antiClip,
  );

  @override
  List<Object?> get props => [enabled, presetId, curve, boostDb, antiClip];
}
