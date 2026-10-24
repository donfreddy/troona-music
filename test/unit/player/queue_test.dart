import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';

void main() {
  final a = _track('a'), b = _track('b'), c = _track('c'), d = _track('d');
  List<String> ids(List<Track> tracks) => [for (final t in tracks) t.id];

  group('removeAt', () {
    final queue = Queue.fromTracks([a, b, c, d], startIndex: 2);

    test('before the current track shifts the index back', () {
      final next = queue.removeAt(0);
      expect(ids(next.playbackTracks), ['b', 'c', 'd']);
      expect(next.currentTrack, c);
    });

    test('after the current track keeps the index', () {
      final next = queue.removeAt(3);
      expect(next.currentIndex, 2);
      expect(next.currentTrack, c);
    });

    test('the current track lands on the following one', () {
      expect(queue.removeAt(2).currentTrack, d);
    });

    test('the current last track falls back to the previous one', () {
      final last = Queue.fromTracks([a, b, c], startIndex: 2);
      expect(last.removeAt(2).currentTrack, b);
    });

    test('a duplicated track removes only that occurrence', () {
      final dup = Queue.fromTracks([a, b, a, c]);
      final next = dup.removeAt(2);
      expect(ids(next.playbackTracks), ['a', 'b', 'c']);
      expect(ids(next.originalTracks), ['a', 'b', 'c']);
    });

    test('out of range is a no-op', () {
      expect(queue.removeAt(9), same(queue));
    });
  });

  group('insertAt', () {
    final queue = Queue.fromTracks([a, b, c], startIndex: 1);

    test('before the current track shifts the index forward', () {
      final next = queue.insertAt(0, d);
      expect(ids(next.playbackTracks), ['d', 'a', 'b', 'c']);
      expect(next.currentTrack, b);
    });

    test('after the current track keeps the index', () {
      final next = queue.insertAt(2, d);
      expect(ids(next.playbackTracks), ['a', 'b', 'd', 'c']);
      expect(ids(next.originalTracks), ['a', 'b', 'd', 'c']);
      expect(next.currentTrack, b);
    });

    test('undoes a removal exactly', () {
      final removed = queue.removeAt(2);
      final restored = removed.insertAt(2, c);
      expect(ids(restored.playbackTracks), ids(queue.playbackTracks));
      expect(ids(restored.originalTracks), ids(queue.originalTracks));
      expect(restored.currentIndex, queue.currentIndex);
    });

    test('shuffled, appends to the original order', () {
      final shuffled = queue.toggleShuffle();
      final next = shuffled.insertAt(1, d);
      expect(next.playbackTracks[1], d);
      expect(next.originalTracks.last, d);
      expect(next.currentTrack, shuffled.currentTrack);
    });
  });

  group('moveItem', () {
    final queue = Queue.fromTracks([a, b, c, d], startIndex: 1);

    test('moving the current track follows it', () {
      final next = queue.moveItem(1, 3);
      expect(ids(next.playbackTracks), ['a', 'c', 'd', 'b']);
      expect(next.currentTrack, b);
    });

    test('moving a played track after the current one', () {
      final next = queue.moveItem(0, 2);
      expect(ids(next.playbackTracks), ['b', 'c', 'a', 'd']);
      expect(next.currentTrack, b);
    });

    test('moving an upcoming track before the current one', () {
      final next = queue.moveItem(3, 0);
      expect(ids(next.playbackTracks), ['d', 'a', 'b', 'c']);
      expect(next.currentTrack, b);
    });

    test('reordering without shuffle survives a shuffle round trip', () {
      final moved = queue.moveItem(3, 2); // a b d c
      final roundTrip = moved.toggleShuffle().toggleShuffle();
      expect(ids(roundTrip.playbackTracks), ['a', 'b', 'd', 'c']);
      expect(roundTrip.currentTrack, b);
    });
  });
}

Track _track(String id) => Track(
  id: id,
  title: 'Title $id',
  artist: 'Artist',
  artistId: 1,
  album: 'Album',
  albumId: 1,
  path: '/music/$id.mp3',
  uri: 'content://$id',
  size: 1,
  durationMs: 180000,
  fileName: '$id.mp3',
);
