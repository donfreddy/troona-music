import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';

/// A layout with a band at each of [centers], from [min] to [max] dB.
EqLayout layoutOf(List<double> centers, {double min = -15, double max = 15}) =>
    EqLayout(
      bands: [
        for (final c in centers)
          EqBand(lowHz: c / 2, centerHz: c, highHz: c * 2),
      ],
      minDb: min,
      maxDb: max,
    );

/// Android's usual five bands.
final fiveBands = layoutOf([60, 230, 910, 3600, 14000]);

/// A ten-band phone.
final tenBands = layoutOf([
  31,
  62,
  125,
  250,
  500,
  1000,
  2000,
  4000,
  8000,
  16000,
]);

/// The phone's effects, recording every output sent.
final class FakeEqualizerPort implements EqualizerPort {
  FakeEqualizerPort({this.supported = true, EqLayout? layout})
    : _layout = BehaviorSubject.seeded(layout);

  @override
  final bool supported;

  final BehaviorSubject<EqLayout?> _layout;
  final outputs = <EqOutput>[];

  /// The bands become known, as when the player loads its first song.
  void loadBands(EqLayout layout) => _layout.add(layout);

  @override
  EqLayout? get layout => _layout.value;

  @override
  Stream<EqLayout?> get layoutStream => _layout.stream;

  @override
  Future<void> apply(EqOutput output) async => outputs.add(output);
}
