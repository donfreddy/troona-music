import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/playlist/domain/services/playlist_order.dart';

void main() {
  // Upper case songs are shown, lower case ones hidden.
  bool shown(String id) => id == id.toUpperCase();
  List<String>? move(String stored, int from, int to) =>
      PlaylistOrder.move(stored.split(''), shown, from: from, to: to);

  test('with every song shown it is a plain move', () {
    expect(move('ABCD', 0, 2), 'BCAD'.split(''));
    expect(move('ABCD', 3, 0), 'DABC'.split(''));
    expect(move('ABCD', 1, 1), 'ABCD'.split(''));
  });

  test('moves the song the page shows, not the one stored there', () {
    // Shown: A B C. Moving B (shown at 1) to the top.
    expect(move('AxBC', 1, 0), 'BAxC'.split(''));
  });

  test('hidden songs keep their place among the others', () {
    // Shown: A B C D. Moving A below C: just before D.
    expect(move('AxByCzD', 0, 2), 'xByCzAD'.split(''));
    // Moving D to the top.
    expect(move('AxByCzD', 3, 0), 'DAxByCz'.split(''));
  });

  test('to the end goes just after the last song shown', () {
    expect(move('ABxy', 0, 1), 'BAxy'.split(''));
  });

  test('a place out of range moves nothing', () {
    expect(move('AxB', 2, 0), isNull);
    expect(move('AxB', 0, 2), isNull);
    expect(move('AxB', -1, 0), isNull);
    expect(move('xy', 0, 0), isNull);
  });

  test('a song moved onto its own place stays, alone shown or not', () {
    expect(move('xAy', 0, 0), 'xAy'.split(''));
    expect(move('AB', 1, 1), 'AB'.split(''));
  });
}
