import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

import '../../helpers/fake_player.dart';

/// Stand-in for just_audio's player, with its loading order: the previous
/// index is re-emitted against the new sources first, then the platform
/// reports the initial index once prepared.
final class _FakeAudioPlayer implements AudioPlayer {
  final index = StreamController<int?>.broadcast(sync: true);
  int? indexValue;

  /// Track ids of each load, in order.
  final loads = <List<String>>[];

  /// Runs at the start of each load, before the stale index.
  void Function(int? initialIndex)? onLoad;

  /// Holds the next load until completed (an error fails it).
  Completer<void>? gate;
  Object? loadError;
  Object? loopModeError;
  bool playCompletes = true;

  /// Holds the next playlist edit until completed (an error rejects it).
  Completer<void>? editGate;

  @override
  Future<void> removeAudioSourceAt(int index) async {
    final held = editGate;
    editGate = null;
    if (held != null) await held.future;
  }

  @override
  Stream<int?> get currentIndexStream => index.stream;
  @override
  int? get currentIndex => indexValue;

  /// The platform's index when it differs from [currentIndex].
  int? platformIndex;
  @override
  PlaybackEvent get playbackEvent =>
      PlaybackEvent(currentIndex: platformIndex ?? indexValue);
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
    loads.add([
      for (final s in audioSources) ((s as IndexedAudioSource).tag as Track).id,
    ]);
    onLoad?.call(initialIndex);
    index.add(indexValue);
    final held = gate;
    gate = null;
    if (held != null) await held.future;
    await Future<void>.delayed(Duration.zero);
    if (loadError case final error?) throw error;
    indexValue = initialIndex ?? 0;
    index.add(indexValue);
    return null;
  }

  @override
  bool playing = false;

  /// Volumes sent to the platform, in order.
  final volumes = <double>[];
  int pauses = 0;

  /// Track changes asked by the user, with the volume at that moment.
  final switches = <(String, double)>[];

  @override
  PlayerState get playerState => PlayerState(playing, ProcessingState.ready);

  @override
  bool get hasNext => true;

  @override
  Future<void> seekToNext() async =>
      switches.add(('next', volumes.lastOrNull ?? 1));

  @override
  Future<void> play() {
    playing = true;
    return playCompletes ? Future.value() : Completer<void>().future;
  }

  @override
  Future<void> pause() async {
    playing = false;
    pauses++;
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    if (loopModeError case final error?) throw error;
  }

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> dispose() async {}

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

  /// A fresh adapter, playing [queue] from [start] when given.
  Future<void> setUpAdapter({List<Track>? queue, int start = 0}) async {
    player = _FakeAudioPlayer();
    adapter = JustAudioAdapter(player: player);
    addTearDown(adapter.dispose);
    playing = [];
    adapter.currentTrackStream.listen((t) => playing.add(t?.id));
    if (queue != null) {
      await adapter.setQueue(queue, startIndex: start);
      await pumpEventQueue();
      playing.clear();
    }
  }

  test('setQueue can turn shuffle on in the same load', () async {
    await setUpAdapter();

    await adapter.setQueue(tracks, startIndex: 2, shuffle: true);
    await pumpEventQueue();

    final queue = adapter.currentQueue!;
    expect(queue.shuffleEnabled, isTrue);
    expect(queue.originalTracks, tracks);
    expect(queue.playbackTracks.first, c);
    expect(queue.playbackTracks, unorderedEquals(tracks));
    expect(player.loads, hasLength(1));
    expect(playing, ['c']);
  });

  test('setQueue without shuffle keeps the current mode', () async {
    await setUpAdapter();
    await adapter.setQueue(tracks, shuffle: true);
    await adapter.setQueue([a, b]);
    expect(adapter.currentQueue!.shuffleEnabled, isTrue);

    await adapter.setQueue([a, b], shuffle: false);
    expect(adapter.currentQueue!.playbackTracks, [a, b]);
  });

  test('the new queue is in place before the player loads it', () async {
    await setUpAdapter(queue: [a, b], start: 1);
    Queue? seen;
    player.onLoad = (_) => seen = adapter.currentQueue;

    await adapter.setQueue([c, d]);

    expect(seen?.playbackTracks, [c, d]);
  });

  test('the stale index re-emitted while loading names no track', () async {
    await setUpAdapter(queue: [a, b], start: 1);

    // Index 1 is re-emitted first: against [c, d] it would mean "d".
    await adapter.setQueue([c, d]);
    await pumpEventQueue();

    expect(playing, ['c']);
  });

  test('a new queue starting at the same index changes the track', () async {
    await setUpAdapter(queue: [a, b], start: 1);

    await adapter.setQueue([c, d], startIndex: 1);
    await pumpEventQueue();

    expect(playing, ['d']);
  });

  test('shuffling keeps the current track, even for a moment', () async {
    await setUpAdapter(queue: tracks, start: 2);

    await adapter.setShuffleEnabled(true);
    await pumpEventQueue();

    expect(adapter.currentQueue?.currentTrack, c);
    expect(playing.toSet().difference({'c'}), isEmpty);
  });

  test('a failed load restores the previous queue', () async {
    await setUpAdapter(queue: [a, b], start: 1);
    player.loadError = Exception('unsupported format');

    final result = await adapter.setQueue([c, d]);
    await pumpEventQueue();

    expect(result.isLeft(), isTrue);
    expect(adapter.currentQueue?.playbackTracks, [a, b]);
    expect(adapter.currentQueue?.currentTrack, b);
    expect(playing.last, 'b');
  });

  test('a failed first load leaves no queue', () async {
    await setUpAdapter();
    player.loadError = Exception('file deleted');

    final result = await adapter.setQueue([a, b]);
    await pumpEventQueue();

    expect(result.isLeft(), isTrue);
    expect(adapter.currentQueue, isNull);
    expect(playing.whereType<String>(), isEmpty);
  });

  test('an interrupted load does not roll back the newer one', () async {
    await setUpAdapter(queue: [a, b]);
    final firstLoad = player.gate = Completer<void>();
    final first = adapter.setQueue([c]);
    await pumpEventQueue();

    await adapter.setQueue([d]);
    firstLoad.completeError(Exception('interrupted'));
    expect((await first).isLeft(), isTrue);

    expect(adapter.currentQueue?.playbackTracks, [d]);
  });

  test(
    'a restore keeps its queue when a setting fails after loading',
    () async {
      await setUpAdapter(queue: [a, b]);
      player.loopModeError = Exception('loop mode');

      final result = await adapter.restoreQueue(
        Queue.fromTracks([c, d], startIndex: 1),
        position: Duration.zero,
        play: false,
        volume: 1,
        speed: 1,
      );

      expect(result.isLeft(), isTrue);
      expect(adapter.currentQueue?.currentTrack, d);
    },
  );

  test('starting a queue does not wait for playback to end', () async {
    await setUpAdapter();
    player.playCompletes = false;

    final result = await adapter
        .setQueue([a, b])
        .timeout(const Duration(seconds: 1));

    expect(result.isRight(), isTrue);
  });

  test('a single track replaces the queue before loading', () async {
    await setUpAdapter(queue: [a, b], start: 1);
    Queue? seen;
    player.onLoad = (_) => seen = adapter.currentQueue;

    await adapter.playTrack(c);
    await pumpEventQueue();

    expect(seen?.playbackTracks, [c]);
    expect(playing, ['c']);
  });

  test('a late index from the replaced playlist is ignored', () async {
    await setUpAdapter(queue: tracks, start: 3);
    await adapter.setQueue([c]);
    await pumpEventQueue();
    playing.clear();

    player.index.add(3);
    await pumpEventQueue();

    expect(adapter.currentQueue?.currentIndex, 0);
    expect(playing, isEmpty);
  });

  group('a removal rejected by the player', () {
    late Completer<void> removal;
    late Future<void> removed;

    /// Removes "c" from [a, b, c, d] playing "b"; the player holds it.
    Future<void> startRemoval() async {
      await setUpAdapter(queue: tracks, start: 1);
      removal = player.editGate = Completer<void>();
      removed = adapter.removeFromQueue(2);
      await pumpEventQueue();
      expect(adapter.currentQueue?.playbackTracks, [a, b, d]);
    }

    Future<void> reject() async {
      removal.completeError(Exception('rejected'));
      await removed;
      await pumpEventQueue();
    }

    test('puts the track back, in the queue and the player', () async {
      await startRemoval();
      player.loads.clear();
      await reject();

      expect(adapter.currentQueue?.playbackTracks, tracks);
      expect(adapter.currentQueue?.currentTrack, b);
      // just_audio keeps its own edit after a failure: only a reload
      // realigns its sources.
      expect(player.loads, [
        ['a', 'b', 'c', 'd'],
      ]);
    });

    test(
      'keeps the platform index, not the one clamped by the player',
      () async {
        await setUpAdapter(queue: [a, b, c], start: 2);
        removal = player.editGate = Completer<void>();
        removed = adapter.removeFromQueue(0);
        await pumpEventQueue();
        // just_audio clamps its index to its shortened playlist.
        player
          ..platformIndex = 2
          ..indexValue = 1;
        await reject();

        expect(adapter.currentQueue?.playbackTracks, [a, b, c]);
        expect(adapter.currentQueue?.currentTrack, c);
      },
    );

    test('lets a load in flight finish, then rolls back', () async {
      await setUpAdapter(queue: tracks);
      final load = player.gate = Completer<void>();
      final loading = adapter.setQueue([d, c, b, a], startIndex: 1);
      await pumpEventQueue();
      removal = player.editGate = Completer<void>();
      removed = adapter.removeFromQueue(3);
      await pumpEventQueue();

      // Rejected while the player still reports index 0 of the replaced
      // playlist.
      removal.completeError(Exception('rejected'));
      await pumpEventQueue();
      load.complete();

      expect((await loading).isRight(), isTrue, reason: 'not interrupted');
      await removed;
      await pumpEventQueue();
      expect(adapter.currentQueue?.playbackTracks, [d, c, b, a]);
      expect(adapter.currentQueue?.currentTrack, c);
      expect(player.loads.last, ['d', 'c', 'b', 'a']);
    });

    test('a failed reload keeps the queue the player took', () async {
      await startRemoval();
      player.loadError = Exception('reload failed');
      await reject();

      expect(adapter.currentQueue?.playbackTracks, tracks);
    });

    test('keeps a repeat mode set meanwhile', () async {
      await startRemoval();
      await adapter.setRepeatMode(RepeatMode.one);
      await reject();

      expect(adapter.currentQueue?.playbackTracks, tracks);
      expect(adapter.currentQueue?.repeatMode, RepeatMode.one);
    });

    test('keeps the track the player moved to meanwhile', () async {
      await startRemoval();
      // Auto advance: the player, which still has "c", moves to index 2.
      player.indexValue = 2;
      player.index.add(2);
      await reject();

      expect(adapter.currentQueue?.playbackTracks, tracks);
      expect(adapter.currentQueue?.currentTrack, c);
    });

    test('keeps a queue reloaded meanwhile', () async {
      await startRemoval();
      // The shuffled sources are built from the queue without "c".
      await adapter.setShuffleEnabled(true);
      final shuffled = adapter.currentQueue!;
      await reject();

      expect(adapter.currentQueue, shuffled);
      expect(adapter.currentQueue?.playbackTracks, isNot(contains(c)));
      expect(player.loads.last, isNot(contains('c')));
    });
  });

  test('auto-advance moves the current track', () async {
    await setUpAdapter(queue: [a, b, c]);

    player.index.add(1);
    player.index.add(2);
    await pumpEventQueue();

    expect(playing, ['b', 'c']);
  });

  group('fades', () {
    const fade = JustAudioAdapter.fadeDuration;

    /// An adapter playing [tracks], its fade-in over and forgotten.
    void playing(FakeAsync async) {
      player = _FakeAudioPlayer();
      adapter = JustAudioAdapter(player: player);
      adapter.setQueue(tracks);
      async.elapse(fade * 2);
      player.volumes.clear();
    }

    bool falling(List<double> v) =>
        [for (var i = 1; i < v.length; i++) v[i] < v[i - 1]].every((x) => x);

    test('pause fades out, then pauses; the status turns at the tap', () {
      fakeAsync((async) {
        playing(async);

        adapter.pause();
        async.flushMicrotasks();
        expect(adapter.currentStatus, PlaybackStatus.paused);
        expect(player.pauses, 0);

        async.elapse(fade);
        expect(player.pauses, 1);
        expect(falling(player.volumes), isTrue);
        expect(player.volumes.last, 0);
      });
    });

    test('resume during the fade-out takes the volume back up', () {
      fakeAsync((async) {
        playing(async);

        adapter.pause();
        async.elapse(fade ~/ 3);
        adapter.resume();
        async.elapse(fade * 2);

        expect(player.pauses, 0);
        expect(player.volumes.reduce((a, b) => a < b ? a : b), greaterThan(0));
        expect(player.volumes.last, 1);
        expect(adapter.currentStatus, PlaybackStatus.playing);
      });
    });

    test('pause, resume, pause: one pause, once the last fade is over', () {
      fakeAsync((async) {
        playing(async);

        // Resume and pause again between two steps of the first fade: it
        // sees both at once and must not take the second pause for its own.
        adapter.pause();
        async.elapse(const Duration(milliseconds: 50));
        adapter.resume();
        async.elapse(const Duration(milliseconds: 5));
        adapter.pause();
        async.elapse(const Duration(milliseconds: 40));
        expect(player.pauses, 0, reason: 'the first pause must not cut');

        async.elapse(fade);
        expect(player.pauses, 1);
        expect(player.volumes.last, 0);
      });
    });

    test('resume starts from silence and fades in', () {
      fakeAsync((async) {
        playing(async);
        adapter.pause();
        async.elapse(fade);
        player.volumes.clear();

        adapter.resume();
        async.elapse(fade);

        expect(player.volumes.first, 0);
        expect(falling(player.volumes.reversed.toList()), isTrue);
        expect(player.volumes.last, 1);
      });
    });

    test('a skip fades out, changes track, then fades back in', () {
      fakeAsync((async) {
        playing(async);

        adapter.skipToNext();
        async.elapse(fade * 2);

        expect(player.switches.single.$2, 0);
        expect(player.volumes.last, 1);
      });
    });

    test('a skip while paused does not fade', () {
      fakeAsync((async) {
        playing(async);
        adapter.pause();
        async.elapse(fade);
        player.volumes.clear();

        adapter.skipToNext();
        async.elapse(fade);

        expect(player.switches, hasLength(1));
        expect(player.volumes, isEmpty);
      });
    });

    test('the fade stays off the volume stream, the user volume applies', () {
      fakeAsync((async) {
        playing(async);
        final volumes = <double>[];
        adapter.volumeStream.listen(volumes.add);

        adapter.pause();
        async.elapse(fade ~/ 2);
        adapter.setVolume(.5);
        async.elapse(fade);
        adapter.resume();
        async.elapse(fade);

        expect(volumes, [1, .5]);
        expect(player.volumes.last, .5);
      });
    });
  });
}
