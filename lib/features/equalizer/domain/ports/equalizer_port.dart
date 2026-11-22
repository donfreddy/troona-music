import 'package:equatable/equatable.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';

/// Everything sent to the phone's effects, applied as a whole.
final class EqOutput extends Equatable {
  final bool enabled;

  /// One per band of the layout, in dB. A list of another length leaves the
  /// bands as they are.
  final List<double> gains;

  /// The loudness enhancer's gain; 0 turns it off.
  final double boostDb;

  /// The anti-clip attenuation, 0 or negative.
  final double trimDb;

  const EqOutput({
    required this.enabled,
    required this.gains,
    this.boostDb = 0,
    this.trimDb = 0,
  });

  /// The effects bypassed: the music as it is.
  static const off = EqOutput(enabled: false, gains: []);

  @override
  List<Object?> get props => [enabled, gains, boostDb, trimDb];
}

/// The phone's equalizer and loudness enhancer, attached to the player.
abstract interface class EqualizerPort {
  /// False on iOS, and when the effects broke playback on this phone.
  bool get supported;

  /// The phone's bands, known once the player has loaded a song: null
  /// before. Emits the current value on listen.
  Stream<EqLayout?> get layoutStream;
  EqLayout? get layout;

  /// What the effects do from now on. Kept, and sent again whenever the
  /// platform rebuilds them. Never throws: a call the platform refuses is
  /// sent again with the next session.
  Future<void> apply(EqOutput output);
}
