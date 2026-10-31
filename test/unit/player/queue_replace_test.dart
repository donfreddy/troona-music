import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

import '../../helpers/fake_player.dart';

class _Library extends Fake implements LibraryRepository {
  final List<Track> tracks;
  _Library(this.tracks);

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      right(tracks);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final a = testTrack('a', durationMs: 200000);
  final b = testTrack('b', durationMs: 200000);
  final c = testTrack('c', durationMs: 200000);
  final d = testTrack('d', durationMs: 200000);
  final e = testTrack('e', durationMs: 200000);
  final x = testTrack('x', durationMs: 200000);
  final album = [a, b, c];
  final otherAlbum = [d, e];

  late FakeAudioPort port;
  late PlaybackSessionStore store;
  late PlayerBloc bloc;
  late List<PlayerNotice> notices;

  Future<void> build({LibraryRepository? library}) async {
    bloc = buildTestPlayerBloc(port, store, library: library);
    notices = [];
    final sub = bloc.notices.listen(notices.add);
    addTearDown(() async {
      await sub.cancel();
      await bloc.close();
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PlaybackSessionStore(await SharedPreferences.getInstance());
    port = FakeAudioPort();
    addTearDown(port.close);
  });

  /// Plays [tracks] from [index] as a context, the way a tap on a list does,
  /// and lets the engine report it playing.
  Future<void> play(
    List<Track> tracks, {
    int index = 0,
    bool shuffle = false,
  }) async {
    bloc.add(
      PlayTrackRequested(
        tracks[index],
        contextQueue: tracks,
        contextIndex: index,
        shuffle: shuffle,
      ),
    );
    await pumpEventQueue();
    port.queue = Queue.fromTracks(tracks, startIndex: index);
    port.status.add(PlaybackStatus.playing);
    await pumpEventQueue();
    expect(bloc.state, isA<PlayerActive>());
  }

  Future<void> queueNext(Track track) async {
    bloc.add(TrackQueuedNext(track));
    await pumpEventQueue();
  }

  group('a new album', () {
    setUp(() => build());

    test('replaces a queue nothing was added to, without a notice', () async {
      await play(album);
      await play(otherAlbum);
      expect(port.lastSetQueue!.tracks, otherAlbum);
      expect(notices, isEmpty);
    });

    test('replacing songs queued by hand offers to undo', () async {
      await play(album);
      await queueNext(x);
      port.position.add(const Duration(seconds: 42));
      final before = port.queue;

      await play(otherAlbum);
      expect(port.lastSetQueue!.tracks, otherAlbum);
      expect(notices, [const QueueReplaced()]);

      bloc.add(const QueueReplaceUndone());
      await pumpEventQueue();
      expect(port.restoredQueue, before);
      expect(port.restoredPosition, const Duration(seconds: 42));
      expect(port.restoredPlaying, isTrue);

      // Once only.
      port.restoredQueue = null;
      bloc.add(const QueueReplaceUndone());
      await pumpEventQueue();
      expect(port.restoredQueue, isNull);
    });

    test('songs queued by hand that already played do not count', () async {
      await play(album);
      await queueNext(x);
      port.queue = port.queue!.jumpTo(2);
      await play(otherAlbum);
      expect(notices, isEmpty);
    });

    test('undo restores the queue the last replacement dropped', () async {
      await play(album);
      await queueNext(x);
      await play(otherAlbum);
      await queueNext(x);
      final second = port.queue;
      await play(album);
      expect(notices, hasLength(2));

      bloc.add(const QueueReplaceUndone());
      await pumpEventQueue();
      expect(port.restoredQueue, second);
    });

    test('an undo with nothing to restore does nothing', () async {
      await play(album);
      await play(otherAlbum);
      bloc.add(const QueueReplaceUndone());
      await pumpEventQueue();
      expect(port.restoredQueue, isNull);
    });
  });

  group('the same album', () {
    setUp(() => build());

    test('another of its songs is played in the current queue', () async {
      await play(album);
      await queueNext(x);
      final setQueues = port.setQueueCalls;

      bloc.add(PlayTrackRequested(b, contextQueue: album, contextIndex: 1));
      await pumpEventQueue();
      expect(port.indexJumps, [2], reason: 'x sits before b');
      expect(port.setQueueCalls, setQueues);
      expect(notices, isEmpty);
    });

    test('the current song starts over', () async {
      await play(album);
      await queueNext(x);
      final setQueues = port.setQueueCalls;

      bloc.add(PlayTrackRequested(a, contextQueue: album));
      await pumpEventQueue();
      expect(port.seeks, [Duration.zero]);
      expect(port.setQueueCalls, setQueues);
    });

    test('a song removed from the queue replaces it', () async {
      await play(album);
      await queueNext(x);
      bloc.add(TrackRemovedFromQueue(index: 2, trackId: 'b'));
      await pumpEventQueue();

      bloc.add(PlayTrackRequested(b, contextQueue: album, contextIndex: 1));
      await pumpEventQueue();
      expect(port.lastSetQueue!.tracks, album);
      expect(notices, [const QueueReplaced()]);
    });

    test('shuffle deals it again', () async {
      await play(album);
      final setQueues = port.setQueueCalls;
      bloc.add(
        PlayTrackRequested(
          b,
          contextQueue: album,
          contextIndex: 1,
          shuffle: true,
        ),
      );
      await pumpEventQueue();
      expect(port.setQueueCalls, setQueues + 1);
    });
  });

  test('a queue restored at launch is its own source', () async {
    await store.save(
      const PlaybackSessionSnapshot(
        currentTrackId: 'a',
        originalTrackIds: ['a', 'x', 'b'],
        playbackTrackIds: ['a', 'x', 'b'],
        currentIndex: 0,
        positionMs: 0,
        wasPlaying: false,
        shuffleEnabled: false,
        repeatMode: RepeatMode.off,
        volume: 1,
        speed: 1,
      ),
    );
    await build(library: _Library([a, x, b]));
    bloc.add(const RestorePlaybackSessionRequested());
    await pumpEventQueue();
    port.queue = Queue.fromTracks([a, x, b]);
    port.status.add(PlaybackStatus.paused);
    await pumpEventQueue();
    expect(bloc.state, isA<PlayerActive>());

    await play(otherAlbum);
    expect(notices, isEmpty);
  });

  test('a song queued by hand after a restore counts', () async {
    await store.save(
      const PlaybackSessionSnapshot(
        currentTrackId: 'a',
        originalTrackIds: ['a', 'b'],
        playbackTrackIds: ['a', 'b'],
        currentIndex: 0,
        positionMs: 0,
        wasPlaying: false,
        shuffleEnabled: false,
        repeatMode: RepeatMode.off,
        volume: 1,
        speed: 1,
      ),
    );
    await build(library: _Library([a, b]));
    bloc.add(const RestorePlaybackSessionRequested());
    await pumpEventQueue();
    port.queue = Queue.fromTracks([a, b]);
    port.status.add(PlaybackStatus.paused);
    await pumpEventQueue();

    await queueNext(x);
    await play(otherAlbum);
    expect(notices, [const QueueReplaced()]);
  });
}
