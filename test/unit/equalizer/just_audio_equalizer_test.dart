import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/equalizer/data/adapters/equalizer_probe.dart';
import 'package:troona/features/equalizer/data/adapters/just_audio_equalizer.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<JustAudioEqualizer> equalizer({int decks = 2}) async =>
      JustAudioEqualizer(
        probe: EqualizerProbe(await SharedPreferences.getInstance()),
        decks: decks,
      );

  /// The equalizer of deck [i]'s pipeline. Unattached effects keep the
  /// state they are given, so it can be read without a platform.
  AudioEffect equalizerOf(JustAudioEqualizer eq, int i) =>
      eq.pipelines[i].androidAudioEffects.first;

  const on = EqOutput(enabled: true, gains: [], trimDb: -6);

  test('each deck has effects of its own: in just_audio an effect belongs '
      'to one player', () async {
    final eq = await equalizer();
    expect(eq.pipelines, hasLength(2));
    final [first, second] = eq.pipelines;
    for (final effect in first.androidAudioEffects) {
      expect(second.androidAudioEffects, isNot(contains(same(effect))));
    }
  });

  test('an output reaches every deck', () async {
    final eq = await equalizer();
    await eq.apply(on);
    expect(equalizerOf(eq, 0).enabled, isTrue);
    expect(equalizerOf(eq, 1).enabled, isTrue);

    await eq.apply(EqOutput.off);
    expect(equalizerOf(eq, 0).enabled, isFalse);
    expect(equalizerOf(eq, 1).enabled, isFalse);
  });

  test('a new audio session sends the output again to that deck '
      'only', () async {
    final eq = await equalizer();
    final sessions = [
      StreamController<int?>(sync: true),
      StreamController<int?>(sync: true),
    ];
    addTearDown(() => [for (final s in sessions) s.close()]);
    eq.bind(sessionIds: [for (final s in sessions) s.stream], trim: (_) {});
    await eq.apply(on);

    // Android made deck 1's effects again, with their defaults.
    await equalizerOf(eq, 1).setEnabled(false);
    // A stale state on deck 0 shows whether it is sent again too.
    await equalizerOf(eq, 0).setEnabled(false);
    sessions[1].add(7);
    await pumpEventQueue();
    expect(equalizerOf(eq, 1).enabled, isTrue);
    expect(equalizerOf(eq, 0).enabled, isFalse);
  });

  test('the anti-clip trim reaches the players once per change', () async {
    final eq = await equalizer();
    final trims = <double>[];
    eq.bind(
      sessionIds: [const Stream.empty(), const Stream.empty()],
      trim: trims.add,
    );
    await eq.apply(on);
    await eq.apply(on);
    // Said by each deck's applier, sent once, as with a single deck.
    expect(trims, hasLength(1));
    expect(trims.first, closeTo(0.5, 0.01));

    await eq.apply(EqOutput.off);
    expect(trims, hasLength(2));
    expect(trims.last, 1);
  });
}
