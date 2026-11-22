import 'dart:math' as math;

/// Room for the bands that boost: a song already near full scale clips
/// once a band adds 6 dB, so the level comes down by as much.
abstract final class EqHeadroom {
  /// How far to lower the level so the highest band's gain fits: 0 or
  /// negative. Volume + is left out: it is meant to be louder, and its
  /// enhancer limits its own output.
  static double trimDb(List<double> gains) => -gains.fold(0.0, math.max);

  /// [db] as a factor of amplitude, for the player's volume.
  static double factorOf(double db) => math.pow(10, db / 20).toDouble();
}
