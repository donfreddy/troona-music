import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/recently_added.dart';

import '../../helpers/fake_player.dart';

Track _song(String id, String title, {int? day}) {
  final t = testTrack(id, durationMs: 1000);
  return Track(
    id: id,
    title: title,
    artist: t.artist,
    artistId: t.artistId,
    album: t.album,
    albumId: t.albumId,
    path: t.path,
    uri: t.uri,
    size: t.size,
    durationMs: t.durationMs,
    fileName: t.fileName,
    dateAdded: day == null ? null : DateTime(2026, 1, day),
  );
}

void main() {
  List<String> ids(List<Track> tracks) => [for (final t in tracks) t.id];

  test('newest first, songs without a date last', () {
    final songs = [
      _song('old', 'A', day: 1),
      _song('none', 'B'),
      _song('new', 'C', day: 9),
    ];
    expect(ids(RecentlyAdded.of(songs)), ['new', 'old', 'none']);
  });

  test('added together: by title, accents folded', () {
    final songs = [
      _song('z', 'Zebra', day: 3),
      _song('e', 'Été', day: 3),
      _song('a', 'apple', day: 3),
    ];
    expect(ids(RecentlyAdded.of(songs)), ['a', 'e', 'z']);
  });

  test('at most the limit asked, the newest', () {
    final songs = [for (var d = 1; d <= 9; d++) _song('$d', 'S', day: d)];
    expect(ids(RecentlyAdded.of(songs, limit: 3)), ['9', '8', '7']);
    expect(RecentlyAdded.of(songs, limit: 50), hasLength(9));
  });

  test('the list given is left as it was', () {
    final songs = [_song('old', 'A', day: 1), _song('new', 'B', day: 2)];
    RecentlyAdded.of(songs);
    expect(ids(songs), ['old', 'new']);
  });
}
