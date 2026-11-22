import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/services/active_line.dart';

void main() {
  const lines = [
    LyricLine(Duration(seconds: 10), 'a'),
    LyricLine(Duration(seconds: 20), 'b'),
    LyricLine(Duration(seconds: 30), 'c'),
    LyricLine(Duration(seconds: 40), 'd'),
  ];
  int at(int seconds, {int hint = -1}) =>
      activeLineAt(lines, Duration(seconds: seconds), hint: hint);

  test('before the first line, on a stamp, between, after the last', () {
    expect(at(0), -1);
    expect(at(10), 0);
    expect(at(25), 1);
    expect(at(40), 3);
    expect(at(500), 3);
  });

  test('playing on: the hint answers, or the line after it', () {
    for (var s = 0; s < 50; s++) {
      final expected = activeLineAt(lines, Duration(seconds: s));
      expect(at(s, hint: expected), expected);
      if (expected > -1) expect(at(s, hint: expected - 1), expected);
    }
  });

  test('a seek back or forward, or a hint out of range, still finds it', () {
    expect(at(12, hint: 3), 0);
    expect(at(35, hint: 0), 2);
    expect(at(35, hint: 99), 2);
    expect(at(5, hint: -7), -1);
  });

  test('lines sharing a time: the last one is active', () {
    const twice = [
      LyricLine(Duration(seconds: 10), 'a'),
      LyricLine(Duration(seconds: 10), 'b'),
      LyricLine(Duration(seconds: 20), 'c'),
    ];
    expect(activeLineAt(twice, const Duration(seconds: 12)), 1);
    expect(activeLineAt(twice, const Duration(seconds: 12), hint: 0), 1);
  });

  test('no line, one line', () {
    expect(activeLineAt(const [], const Duration(seconds: 5)), -1);
    const one = [LyricLine(Duration(seconds: 3), 'x')];
    expect(activeLineAt(one, const Duration(seconds: 1)), -1);
    expect(activeLineAt(one, const Duration(seconds: 3)), 0);
  });
}
