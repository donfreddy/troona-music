import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/domain/entities/queue.dart';

import '../../helpers/fake_player.dart';

/// Scriptable stand-in for just_audio's player: [onLoad] runs inside
/// `setAudioSources`, where the real player emits indexes while loading.
final class _FakeAudioPlayer implements AudioPlayer {
  final index = StreamController<int?>.broadcast(sync: true);
  void Function(List<AudioSource> sources, int? initialIndex)? onLoad;
  Object? loadError;

  @override
  Stream<int?> get currentIndexStream => index.stream;
  @override
  double get volume => 1;
  @override
  Duration get position => Duration.zero;

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    onLoad?.call(audioSources, initialIndex);
    if (loadError case final error?) throw error;
    return null;
  }

  @override
  Future<void> play() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final tracks = [
    for (final id in 'abcd'.split('')) testTrack(id, durationMs: 180000),
  ];
  final [a, b, c, d] = tracks;

  late _FakeAudioPlayer player;
  late JustAudioAdapter adapter;
  late List<String?> playing;

  setUp(() async {
    player = _FakeAudioPlayer();
    adapter = JustAudioAdapter(player: player);
    playing = [];
    adapter.currentTrackStream.listen((t) => playing.add(t?.id));
    await adapter.setQueue([a, b], startIndex: 1);
    player.index.add(1);
    await pumpEventQueue();
    playing.clear();
  });

  test('the new queue is in place before the player loads it', () async {
    Queue? seen;
    player.onLoad = (_, _) => seen = adapter.currentQueue;

    await adapter.setQueue([c, d]);

    expect(seen?.playbackTracks, [c, d]);
  });

  test('indexes emitted while loading map onto the new queue', () async {
    player.onLoad = (_, initialIndex) => player.index.add(initialIndex);

    await adapter.setQueue([c, d]);

    await pumpEventQueue();

    expect(playing, ['c']);
  });

  test(
    'a new queue starting at the same index still changes the track',
    () async {
      // The player index stays 1: just_audio emits nothing.
      await adapter.setQueue([c, d], startIndex: 1);

      await pumpEventQueue();

      expect(playing, ['d']);
    },
  );

  test('a failed load restores the previous queue', () async {
    player.loadError = Exception('unsupported format');

    final result = await adapter.setQueue([c, d]);

    expect(result.isLeft(), isTrue);
    expect(adapter.currentQueue?.playbackTracks, [a, b]);
    expect(adapter.currentQueue?.currentTrack, b);
    await pumpEventQueue();
    expect(playing.last, 'b');
  });

  test('a single track replaces the queue before loading', () async {
    Queue? seen;
    player.onLoad = (_, _) => seen = adapter.currentQueue;

    await adapter.playTrack(c);

    expect(seen?.playbackTracks, [c]);
    await pumpEventQueue();
    expect(playing, ['c']);
  });

  test('shuffling keeps the current track', () async {
    await adapter.setShuffleEnabled(true);

    expect(adapter.currentQueue?.currentTrack, b);
    await pumpEventQueue();
    expect(playing.toSet(), {'b'});
  });

  test('a late index from the replaced playlist is ignored', () async {
    await adapter.setQueue([c]);
    await pumpEventQueue();
    playing.clear();

    player.index.add(3);

    expect(adapter.currentQueue?.currentIndex, 0);
    await pumpEventQueue();
    expect(playing, isEmpty);
  });

  test('auto-advance moves the current track', () async {
    await adapter.setQueue(<Track>[a, b, c]);
    await pumpEventQueue();
    playing.clear();

    player.index.add(1);
    player.index.add(2);

    await pumpEventQueue();

    expect(playing, ['b', 'c']);
  });
}
