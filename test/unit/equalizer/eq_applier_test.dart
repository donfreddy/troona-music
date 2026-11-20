import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/equalizer/data/adapters/eq_applier.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';

/// The platform's effects, as a log of calls. [failNext] makes the next
/// call throw, as Android does with no audio session.
final class _Effects implements EqEffects {
  final calls = <String>[];
  final trims = <double>[];
  bool failNext = false;

  void _call(String call) {
    if (failNext) {
      failNext = false;
      throw StateError('no session');
    }
    calls.add(call);
  }

  @override
  Future<void> setEqualizerEnabled(bool enabled) async => _call('eq:$enabled');

  @override
  Future<void> setBandGain(int band, double db) async => _call('band$band:$db');

  @override
  Future<void> setBoostEnabled(bool enabled) async => _call('boost:$enabled');

  @override
  Future<void> setBoostGain(double db) async => _call('boostDb:$db');

  @override
  void setTrim(double factor) => trims.add(factor);
}

void main() {
  late _Effects effects;
  late EqApplier applier;

  setUp(() {
    effects = _Effects();
    applier = EqApplier(effects);
  });

  const on = EqOutput(enabled: true, gains: [3, 0, -2]);

  test('before the bands are known, no band is set', () async {
    await applier.apply(on);
    expect(effects.calls, ['eq:true', 'boostDb:0.0', 'boost:false']);
  });

  test('once the bands are known, every band goes', () async {
    await applier.apply(on);
    effects.calls.clear();
    await applier.bandsKnown(3);
    expect(
      effects.calls,
      containsAll(['band0:3.0', 'band1:0.0', 'band2:-2.0']),
    );
  });

  test('then only what changed', () async {
    await applier.bandsKnown(3);
    await applier.apply(on);
    effects.calls.clear();
    await applier.apply(const EqOutput(enabled: true, gains: [3, 1, -2]));
    expect(effects.calls, ['band1:1.0']);
  });

  test('gains of another length leave the bands alone', () async {
    await applier.bandsKnown(3);
    await applier.apply(on);
    effects.calls.clear();
    await applier.apply(const EqOutput(enabled: true, gains: [1, 1]));
    expect(effects.calls, isEmpty);
  });

  test('a new session sends everything again', () async {
    await applier.bandsKnown(3);
    await applier.apply(on);
    effects.calls.clear();
    await applier.rebuilt();
    expect(effects.calls, [
      'eq:true',
      'band0:3.0',
      'band1:0.0',
      'band2:-2.0',
      'boostDb:0.0',
      'boost:false',
    ]);
  });

  test(
    'a refused call is swallowed, and the next batch sends everything',
    () async {
      await applier.bandsKnown(3);
      effects.failNext = true;
      await expectLater(applier.apply(on), completes);
      effects.calls.clear();
      await applier.apply(on);
      expect(effects.calls, [
        'eq:true',
        'band0:3.0',
        'band1:0.0',
        'band2:-2.0',
        'boostDb:0.0',
        'boost:false',
      ]);
    },
  );

  test('the boost goes on with its gain, and off with the equalizer', () async {
    await applier.apply(const EqOutput(enabled: true, gains: [], boostDb: 4));
    expect(effects.calls, ['eq:true', 'boostDb:4.0', 'boost:true']);
    effects.calls.clear();
    await applier.apply(const EqOutput(enabled: false, gains: [], boostDb: 4));
    expect(effects.calls, ['eq:false', 'boostDb:0.0', 'boost:false']);
  });

  test('the trim reaches the volume at once, only when it changes', () async {
    final first = applier.apply(
      const EqOutput(enabled: true, gains: [6], trimDb: -6),
    );
    // Before the batch runs: the volume does not wait for the effects.
    expect(effects.trims.single, closeTo(0.501, 0.001));
    await first;
    await applier.apply(const EqOutput(enabled: true, gains: [5], trimDb: -6));
    expect(effects.trims, hasLength(1));
    await applier.apply(const EqOutput(enabled: false, gains: [5]));
    expect(effects.trims.last, 1);
  });

  test('outputs asked for during a batch cost one more batch, with the '
      'latest', () async {
    await applier.bandsKnown(3);
    await applier.apply(on);
    effects.calls.clear();
    final a = applier.apply(const EqOutput(enabled: true, gains: [1, 0, -2]));
    final b = applier.apply(const EqOutput(enabled: true, gains: [2, 0, -2]));
    final c = applier.apply(const EqOutput(enabled: true, gains: [4, 0, -2]));
    await Future.wait([a, b, c]);
    // The first batch already read the latest output; the others had
    // nothing left to send.
    expect(effects.calls, ['band0:4.0']);
  });
}
