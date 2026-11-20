import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/services/eq_headroom.dart';
import 'package:troona/features/equalizer/domain/services/eq_presets.dart';

import '../../helpers/fake_equalizer.dart';

final five = fiveBands;
final ten = tenBands;

void main() {
  group('EqCurve.sample', () {
    final curve = EqCurve(const [EqPoint(100, 2), EqPoint(1000, -4)]);

    test('flat beyond its ends', () {
      expect(curve.sample(20), 2);
      expect(curve.sample(20000), -4);
    });

    test('exactly on a point', () {
      expect(curve.sample(100), 2);
      expect(curve.sample(1000), -4);
    });

    test('halfway on a log scale between two points', () {
      // 316 Hz is the geometric middle of 100 and 1000.
      expect(curve.sample(316.227766), closeTo(-1, 1e-6));
    });

    test('an empty curve is 0 everywhere, one point is that point', () {
      expect(EqCurve.flat.sample(440), 0);
      expect(EqCurve(const [EqPoint(500, 3)]).sample(20), 3);
      expect(EqCurve(const [EqPoint(500, 3)]).sample(20000), 3);
    });
  });

  group('EqCurve()', () {
    test('sorts its points, keeps the last of one frequency, drops the '
        'invalid', () {
      final curve = EqCurve(const [
        EqPoint(1000, 1),
        EqPoint(100, 2),
        EqPoint(1000, 3),
        EqPoint(0, 9),
        EqPoint(-5, 9),
        EqPoint(double.infinity, 9),
        EqPoint(200, double.nan),
      ]);
      expect(curve.points, const [EqPoint(100, 2), EqPoint(1000, 3)]);
    });
  });

  group('gainsFor', () {
    test('every preset fits five and ten bands within range', () {
      for (final preset in EqPresets.all) {
        for (final layout in [five, ten]) {
          final gains = preset.curve.gainsFor(layout);
          expect(gains, hasLength(layout.bands.length));
          for (final g in gains) {
            expect(g, inInclusiveRange(layout.minDb, layout.maxDb));
            // Half decibels.
            expect((g * 2) % 1, 0);
          }
        }
      }
    });

    test('flat gives 0 on every band of any phone', () {
      expect(EqCurve.flat.gainsFor(five), everyElement(0));
      expect(EqCurve.flat.gainsFor(ten), everyElement(0));
    });

    test('a phone with a narrower range clamps the curve', () {
      final narrow = layoutOf([60, 14000], min: -3, max: 3);
      final curve = EqCurve(const [EqPoint(60, 9), EqPoint(14000, -9)]);
      expect(curve.gainsFor(narrow), [3, -3]);
    });

    test('rounds to half decibels', () {
      final one = layoutOf([1000]);
      expect(EqCurve(const [EqPoint(1000, 2.26)]).gainsFor(one), [2.5]);
      expect(EqCurve(const [EqPoint(1000, 2.2)]).gainsFor(one), [2]);
      expect(EqCurve(const [EqPoint(1000, -2.76)]).gainsFor(one), [-3]);
    });

    test('Bass boost lifts the lows and leaves the highs', () {
      final gains = EqPresets.byId('bass_boost')!.curve.gainsFor(five);
      expect(gains.first, greaterThan(3));
      expect(gains.last, 0);
    });
  });

  test('a profile drawn on five bands reads back on ten through its five '
      'points', () {
    const drawn = [4.0, -2.0, 0.0, 3.5, -1.0];
    final profile = EqCurve.fromGains(five, drawn);
    // On the phone it was drawn on: exactly what was drawn.
    expect(profile.gainsFor(five), drawn);
    // On ten bands: the same curve, sampled at their centres.
    expect(profile.gainsFor(ten), [
      for (final band in ten.bands) ten.fit(profile.sample(band.centerHz)),
    ]);
    // Below the first point the curve holds its value.
    expect(profile.gainsFor(ten).first, 4);
  });

  group('EqHeadroom', () {
    test('no trim when nothing boosts', () {
      expect(EqHeadroom.trimDb([0, 0, 0]), 0);
      expect(EqHeadroom.trimDb([-3, -6, 0]), 0);
      expect(EqHeadroom.trimDb([]), 0);
    });

    test('the trim is the highest boost', () {
      expect(EqHeadroom.trimDb([2, 6, -4, 1]), -6);
    });

    test('a factor of amplitude', () {
      expect(EqHeadroom.factorOf(0), 1);
      expect(EqHeadroom.factorOf(-6), closeTo(0.501, 0.001));
    });
  });

  test('profile keys round-trip, presets are not profiles', () {
    expect(EqPresets.profileIdOf(EqPresets.profileKey('abc')), 'abc');
    expect(EqPresets.profileIdOf('bass_boost'), isNull);
    expect(EqPresets.profileIdOf(null), isNull);
  });
}
