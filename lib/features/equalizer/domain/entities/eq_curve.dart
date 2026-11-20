import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';

/// A gain at a frequency.
final class EqPoint extends Equatable {
  final double hz;
  final double db;

  const EqPoint(this.hz, this.db);

  @override
  List<Object?> get props => [hz, db];
}

/// A setting of the equalizer as a curve over frequencies, not as one gain
/// per band: the phone's bands are sampled from it ([gainsFor]), so a
/// preset or a profile fits any phone, whatever its bands.
final class EqCurve extends Equatable {
  /// Sorted by frequency, each frequency positive and once.
  final List<EqPoint> points;

  const EqCurve._(this.points);

  /// No gain anywhere.
  static const flat = EqCurve._([]);

  /// [points] in any order. Frequencies that are not positive and finite,
  /// and gains that are not finite, are left out; of two points at one
  /// frequency, the last one given stays.
  factory EqCurve(Iterable<EqPoint> points) {
    final byHz = <double, double>{};
    for (final p in points) {
      if (p.hz > 0 && p.hz.isFinite && p.db.isFinite) byHz[p.hz] = p.db;
    }
    final sorted = byHz.keys.toList()..sort();
    return EqCurve._(
      List.unmodifiable([for (final hz in sorted) EqPoint(hz, byHz[hz]!)]),
    );
  }

  /// The curve through [gains], one per band of [layout], at the bands'
  /// centres: what the user drew on this phone.
  factory EqCurve.fromGains(EqLayout layout, List<double> gains) => EqCurve([
    for (var i = 0; i < layout.bands.length && i < gains.length; i++)
      EqPoint(layout.bands[i].centerHz, gains[i]),
  ]);

  /// The gain at [hz]: straight lines between the points on a logarithmic
  /// frequency scale, flat beyond the first and the last.
  double sample(double hz) {
    if (points.isEmpty) return 0;
    if (hz <= points.first.hz) return points.first.db;
    if (hz >= points.last.hz) return points.last.db;
    final i = points.indexWhere((p) => p.hz >= hz);
    final a = points[i - 1], b = points[i];
    final t =
        (math.log(hz) - math.log(a.hz)) / (math.log(b.hz) - math.log(a.hz));
    return a.db + (b.db - a.db) * t;
  }

  /// One gain per band of [layout], within its range, by half decibels.
  List<double> gainsFor(EqLayout layout) => List.unmodifiable([
    for (final band in layout.bands) layout.fit(sample(band.centerHz)),
  ]);

  @override
  List<Object?> get props => [points];
}
