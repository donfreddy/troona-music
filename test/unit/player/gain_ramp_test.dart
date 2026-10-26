import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/data/adapters/gain_ramp.dart';

void main() {
  late List<double> applied;
  late GainRamp ramp;

  setUp(() {
    applied = [];
    ramp = GainRamp((gain) async => applied.add(gain));
  });

  test('a full fade lasts its duration and lands on the target', () {
    fakeAsync((async) {
      bool? done;
      ramp.to(0, const Duration(milliseconds: 300)).then((v) => done = v);

      async.elapse(const Duration(milliseconds: 280));
      expect(done, isNull);
      async.elapse(const Duration(milliseconds: 20));

      expect(done, isTrue);
      expect(applied, hasLength(15));
      expect(applied.last, 0);
      expect(ramp.gain, 0);
    });
  });

  test('half way through a fade-in, the gain is a quarter', () {
    fakeAsync((async) {
      ramp.jump(0);
      ramp.to(1, const Duration(milliseconds: 400));

      async.elapse(const Duration(milliseconds: 200));

      expect(ramp.gain, closeTo(.25, 1e-9));
    });
  });

  test('a new ramp reverses from where the gain is, in less time', () {
    fakeAsync((async) {
      bool? first;
      ramp.to(0, const Duration(milliseconds: 400)).then((v) => first = v);
      async.elapse(const Duration(milliseconds: 100));
      final reached = ramp.gain;

      bool? second;
      ramp.to(1, const Duration(milliseconds: 400)).then((v) => second = v);
      async.elapse(const Duration(milliseconds: 100));

      expect(first, isFalse);
      expect(second, isTrue);
      final back = applied.skipWhile((g) => g != reached).skip(1).toList();
      expect(back.first, greaterThan(reached));
      expect(back.last, 1);
    });
  });

  test('a jump stops a ramp', () {
    fakeAsync((async) {
      bool? done;
      ramp.to(0, const Duration(milliseconds: 300)).then((v) => done = v);
      async.elapse(const Duration(milliseconds: 40));
      ramp.jump(.5);
      async.elapse(const Duration(milliseconds: 300));

      expect(done, isFalse);
      expect(applied.last, .5);
      expect(ramp.gain, .5);
    });
  });
}
