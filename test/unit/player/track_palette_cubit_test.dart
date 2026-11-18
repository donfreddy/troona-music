import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/palette/cover_palette.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';

Track _song(String id, {String? cover}) => Track(
  id: id,
  title: id,
  artist: 'Artist',
  artistId: 1,
  album: 'Album',
  albumId: 1,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 0,
  fileName: '$id.mp3',
  artworkPath: cover ?? '/$id.jpg',
);

void main() {
  /// Reads held until their gate opens, by path.
  late Map<String, Completer<void>> gates;

  setUp(() {
    gates = {};
    CoverPalette.stampOf = (_) async => DateTime(2026);
    CoverPalette.read = (path) async {
      await gates[path]?.future;
      return (
        vibrant: path == '/a.jpg' ? Colors.red : Colors.blue,
        dominant: null,
        darkVibrant: null,
        muted: null,
      );
    };
  });
  tearDown(CoverPalette.clear);

  test('A, B, A before B is read: A keeps its colours', () async {
    final cubit = TrackPaletteCubit();
    addTearDown(cubit.close);
    await cubit.updateTrack(_song('a'));
    final a = cubit.state;
    expect(a.trackId, 'a');

    gates['/b.jpg'] = Completer();
    unawaited(cubit.updateTrack(_song('b')));
    await cubit.updateTrack(_song('a'));
    gates['/b.jpg']!.complete();
    await pumpEventQueue();
    expect(cubit.state.trackId, 'a');
    expect(cubit.state, same(a));
  });

  test('a song without a cover drops the read still running', () async {
    final cubit = TrackPaletteCubit();
    addTearDown(cubit.close);
    gates['/b.jpg'] = Completer();
    unawaited(cubit.updateTrack(_song('b')));
    await cubit.updateTrack(_song('c', cover: ''));
    gates['/b.jpg']!.complete();
    await pumpEventQueue();
    expect(cubit.state.trackId, isNull);
  });

  test('the same song asked again while read is read once', () async {
    final cubit = TrackPaletteCubit();
    addTearDown(cubit.close);
    var reads = 0;
    final read = CoverPalette.read;
    CoverPalette.read = (path) {
      reads++;
      return read(path);
    };
    gates['/b.jpg'] = Completer();
    for (var i = 0; i < 3; i++) {
      unawaited(cubit.updateTrack(_song('b')));
    }
    gates['/b.jpg']!.complete();
    await pumpEventQueue();
    expect(reads, 1);
    expect(cubit.state.trackId, 'b');
  });
}
