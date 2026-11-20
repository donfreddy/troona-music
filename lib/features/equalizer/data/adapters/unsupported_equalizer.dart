import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';

/// No effects: iOS, and phones whose effects broke playback. The app shows
/// no way to the equalizer.
final class UnsupportedEqualizer implements EqualizerPort {
  const UnsupportedEqualizer();

  @override
  bool get supported => false;

  @override
  EqLayout? get layout => null;

  @override
  Stream<EqLayout?> get layoutStream => Stream.value(null);

  @override
  Future<void> apply(EqOutput output) async {}
}
