import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/services/lyric_pauses.dart';

LyricLine line(int seconds, [String text = 'A line of ten']) =>
    LyricLine(Duration(seconds: seconds), text);

void main() {
  test('lines close together get no pause', () {
    final lines = [line(0), line(4), line(12)];
    expect(LyricPauses.insert(lines), lines);
  });

  test('a long gap gets a pause once the line is taken to be sung', () {
    final lines = [line(10, 'Twenty letters long!'), line(40)];
    final out = LyricPauses.insert(lines);
    expect(out, hasLength(3));
    expect(out[1].isPause, isTrue);
    // 20 letters: 2 s, and a breath of 1 s.
    expect(out[1].at, const Duration(seconds: 13));
    expect([out[0], out[2]], lines, reason: 'the lines are kept');
  });

  test('a short line is still given two seconds, a long one at most six', () {
    expect(LyricPauses.sungFor(line(0, 'Oh')), const Duration(seconds: 3));
    expect(LyricPauses.sungFor(line(0, 'x' * 200)), const Duration(seconds: 7));
  });

  test('a character that is a syllable or a word counts for three '
      'letters', () {
    // Twelve of them: 3.6 s and a breath, not the 2 s of twelve letters.
    expect(
      LyricPauses.sungFor(line(0, '君の名前を呼んでいるよ今')),
      const Duration(milliseconds: 4600),
    );
    expect(LyricPauses.sungFor(line(0, 'x' * 12)), const Duration(seconds: 3));
  });

  test('no pause when too little silence would be left', () {
    // 9 s apart, a long line taken to last 7 s: 2 s left.
    final lines = [line(0, 'x' * 200), line(9)];
    expect(LyricPauses.insert(lines), lines);
  });

  test('a pause of the file is kept, and none is added around it', () {
    final lines = [line(0), line(5, ''), line(40)];
    expect(LyricPauses.insert(lines), lines);
  });

  test('nothing after the last line, nothing in an empty list', () {
    expect(LyricPauses.insert([line(0)]), [line(0)]);
    expect(LyricPauses.insert(const []), isEmpty);
  });

  test('the result stays sorted by time', () {
    final out = LyricPauses.insert([line(0), line(30), line(70), line(72)]);
    for (var i = 1; i < out.length; i++) {
      expect(out[i].at, greaterThanOrEqualTo(out[i - 1].at));
    }
    expect(out.where((l) => l.isPause), hasLength(2));
  });
}
