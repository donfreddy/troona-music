import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/equalizer/data/adapters/equalizer_probe.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A start of the app: a probe on the preferences as saved.
  Future<EqualizerProbe> launch() async =>
      EqualizerProbe(await SharedPreferences.getInstance());

  test('a first launch keeps the effects', () async {
    expect(await (await launch()).broken(), isFalse);
  });

  test('a launch whose effects were made keeps them next time', () async {
    final probe = await launch();
    await probe.arm();
    await probe.disarm();
    expect(await (await launch()).broken(), isFalse);
  });

  test('one launch that never saw its effects made is forgiven', () async {
    await (await launch()).arm();
    expect(await (await launch()).broken(), isFalse);
  });

  test('two launches in a row that never saw their effects made turn them '
      'off for good', () async {
    final first = await launch();
    await first.broken();
    await first.arm();
    final second = await launch();
    expect(await second.broken(), isFalse);
    await second.arm();
    expect(await (await launch()).broken(), isTrue);
    // And on every launch after.
    expect(await (await launch()).broken(), isTrue);
  });

  test('a launch that goes through forgives the strike before it', () async {
    final first = await launch();
    await first.broken();
    await first.arm();
    final second = await launch();
    await second.broken();
    await second.arm();
    await second.disarm();
    final third = await launch();
    expect(await third.broken(), isFalse);
    await third.arm();
    expect(await (await launch()).broken(), isFalse);
  });

  test('a launch that played nothing does not arm the probe', () async {
    await launch();
    expect(await (await launch()).broken(), isFalse);
  });

  test('loads asked for while arming wait for the same write', () async {
    final probe = await launch();
    final a = probe.arm();
    final b = probe.arm();
    expect(identical(a, b), isTrue);
    await a;
    // Written: later loads have nothing to wait for.
    expect(probe.arm(), isNull);
    // Once disarmed, a later load does not arm it again.
    await probe.disarm();
    await probe.arm();
    expect(await (await launch()).broken(), isFalse);
  });
}
