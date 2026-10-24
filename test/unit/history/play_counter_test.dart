import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/history/domain/play_counter.dart';

void main() {
  const tick = Duration(milliseconds: 200);

  /// Feeds positions from [from] to [to] in [tick] steps and returns the
  /// ids the counter reported.
  List<String> play(PlayCounter counter, Duration from, Duration to) {
    final counted = <String>[];
    for (var p = from; p <= to; p += tick) {
      if (counter.onPosition(p) case final id?) counted.add(id);
    }
    return counted;
  }

  const s = Duration(seconds: 1);

  test('counts after 30 s of listening, once', () {
    final counter = PlayCounter()..start('a', s * 240);

    expect(play(counter, Duration.zero, s * 29), isEmpty);
    expect(play(counter, s * 29 + tick, s * 31), ['a']);
    expect(play(counter, s * 31 + tick, s * 200), isEmpty);
  });

  test('counts half of a track shorter than a minute', () {
    final counter = PlayCounter()..start('a', s * 40);

    expect(play(counter, Duration.zero, s * 19), isEmpty);
    expect(play(counter, s * 19 + tick, s * 21), ['a']);
  });

  test('uses 30 s when the duration is unknown', () {
    final counter = PlayCounter()..start('a', Duration.zero);

    expect(play(counter, Duration.zero, s * 29), isEmpty);
    expect(play(counter, s * 29 + tick, s * 31), ['a']);
  });

  test('a seek forward is not listening', () {
    final counter = PlayCounter()..start('a', s * 240);

    play(counter, Duration.zero, s * 5);
    // Jump to 2:00, then listen 20 s: 25 s listened in all.
    expect(play(counter, s * 120, s * 140), isEmpty);
    expect(play(counter, s * 140 + tick, s * 146), ['a']);
  });

  test('a seek back mid-track keeps what was listened', () {
    final counter = PlayCounter()..start('a', s * 240);

    play(counter, Duration.zero, s * 20);
    expect(play(counter, s * 10, s * 21), ['a']);
  });

  test('back to the start is a new listen (repeat one)', () {
    final counter = PlayCounter()..start('a', s * 40);

    expect(play(counter, Duration.zero, s * 40), ['a']);
    expect(play(counter, Duration.zero, s * 40), ['a']);
  });

  test('starting another track resets the listen', () {
    final counter = PlayCounter()..start('a', s * 240);

    play(counter, Duration.zero, s * 25);
    counter.start('b', s * 240);
    expect(play(counter, Duration.zero, s * 25), isEmpty);
    expect(play(counter, s * 25 + tick, s * 31), ['b']);
  });

  test('a listen resumed mid-track counts from where it resumed', () {
    final counter = PlayCounter()..start('a', s * 240);

    expect(play(counter, s * 90, s * 119), isEmpty);
    expect(play(counter, s * 119 + tick, s * 121), ['a']);
  });

  test('reports nothing once stopped', () {
    final counter = PlayCounter()..start('a', s * 240);

    play(counter, Duration.zero, s * 10);
    counter.stop();
    expect(play(counter, s * 10, s * 60), isEmpty);
  });
}
