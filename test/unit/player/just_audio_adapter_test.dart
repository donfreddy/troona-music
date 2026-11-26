import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

import '../../helpers/fake_just_audio_player.dart';
import '../../helpers/fake_player.dart';

void main() {
  final tracks = [
    for (final id in 'abcd'.split('')) testTrack(id, durationMs: 180000),
  ];
  final [a, b, c, d] = tracks;

  late FakeJustAudioPlayer player;

  /// The deck that stays idle: nothing is ever loaded on it.
  late FakeJustAudioPlayer idle;
  late JustAudioAdapter adapter;
  late List<String?> playing;

  /// A fresh adapter, playing [queue] from [start] when given.
  Future<void> setUpAdapter({List<Track>? queue, int start = 0}) async {
    player = FakeJustAudioPlayer();
    idle = FakeJustAudioPlayer();
    adapter = JustAudioAdapter(players: [player, idle]);
    addTearDown(adapter.dispose);
    playing = [];
    adapter.currentTrackStream.listen((t) => playing.add(t?.id));
    if (queue != null) {
      await adapter.setQueue(queue, startIndex: start);
      await pumpEventQueue();
      playing.clear();
    }
  }

  group('the equalizer', () {
    test('its trim scales the volume, never the volume shown', () async {
      await setUpAdapter();
      final shown = <double>[];
      adapter.volumeStream.listen(shown.add);
      await adapter.setVolume(0.8);
      player.volumes.clear();

      adapter.setTrim(0.5);
      await pumpEventQueue();
      expect(player.volumes.last, closeTo(0.4, 1e-9));
      // Kept for later volume changes too.
      await adapter.setVolume(0.6);
      expect(player.volumes.last, closeTo(0.3, 1e-9));
      await pumpEventQueue();
      expect(shown.last, 0.6);
      expect(shown, isNot(contains(closeTo(0.3, 1e-9))));
    });

    test('a trim above 1 cannot raise the volume', () async {
      await setUpAdapter();
      adapter.setTrim(3);
      await pumpEventQueue();
      expect(player.volumes.last, 1);
    });

    test('the probe runs before the platform loads, and loads keep their '
        'order', () async {
      player = FakeJustAudioPlayer();
      idle = FakeJustAudioPlayer();
      final events = <String>[];
      final probe = Completer<void>();
      adapter = JustAudioAdapter(
        players: [player, idle],
        beforeLoad: () {
          events.add('probe');
          return probe.future;
        },
      );
      addTearDown(adapter.dispose);
      player.onLoad = (_) => events.add('load');

      final first = adapter.setQueue([a], startIndex: 0);
      final second = adapter.setQueue([b], startIndex: 0);
      await pumpEventQueue();
      expect(events, ['probe', 'probe']);
      expect(player.loads, isEmpty);

      probe.complete();
      await Future.wait([first, second]);
      await pumpEventQueue();
      expect(events, ['probe', 'probe', 'load', 'load']);
      expect(player.loads, [
        ['a'],
        ['b'],
      ]);
      expect(adapter.currentQueue!.currentTrack, b);
    });

    test(
      'a hook with nothing to wait for adds no turn before the load',
      () async {
        player = FakeJustAudioPlayer();
        idle = FakeJustAudioPlayer();
        adapter = JustAudioAdapter(
          players: [player, idle],
          beforeLoad: () => null,
        );
        addTearDown(adapter.dispose);
        final done = adapter.setQueue([a], startIndex: 0);
        // Synchronously up to the platform call, as without a hook.
        expect(player.loads, [
          ['a'],
        ]);
        await done;
      },
    );
  });

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

  group('several songs queued at once', () {
    final x = testTrack('x', durationMs: 180000);
    final y = testTrack('y', durationMs: 180000);

    test('go to the player in one call, in their order', () async {
      await setUpAdapter(queue: [a, b, c], start: 0);
      await adapter.addAllToQueue([x, y], index: 1);
      await adapter.addAllToQueue([y]);
      expect(player.batches, ['1:x,y', 'end:y']);
      expect(
        [for (final t in adapter.currentQueue!.playbackTracks) t.id],
        ['a', 'x', 'y', 'b', 'c', 'y'],
      );
    });

    test('refused, none of them stays, in the queue or the player', () async {
      await setUpAdapter(queue: [a, b, c], start: 0);
      final gate = player.editGate = Completer<void>();
      final added = adapter.addAllToQueue([x, y], index: 1);
      await pumpEventQueue();
      player.loads.clear();
      gate.completeError(Exception('rejected'));
      expect((await added).isLeft(), isTrue);
      await pumpEventQueue();
      expect(adapter.currentQueue?.playbackTracks, [a, b, c]);
      expect(player.loads, [
        ['a', 'b', 'c'],
      ]);
    });
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

  group('decks', () {
    test('nothing but volume and speed ever reaches the idle deck', () async {
      await setUpAdapter(queue: tracks);
      final results = [
        await adapter.addAllToQueue([a, b]),
        await adapter.addAllToQueue([c], index: 1),
        await adapter.removeFromQueue(2),
        await adapter.setShuffleEnabled(true),
        await adapter.setRepeatMode(RepeatMode.all),
        await adapter.skipToIndex(1),
        await adapter.skipToNext(),
        await adapter.seekTo(const Duration(seconds: 30)),
        await adapter.pause(fade: Duration.zero),
        await adapter.resume(),
        await adapter.setVolume(0.7),
        await adapter.setSpeed(1.25),
        await adapter.setQueue([d, a]),
      ];
      await pumpEventQueue();
      // Every command went through, all of it on the active deck.
      expect(results.every((r) => r.isRight()), isTrue);
      expect(player.missing, isEmpty);
      expect(player.seeks, isNotEmpty);
      expect(idle.loads, isEmpty);
      expect(idle.seeks, isEmpty);
      expect(idle.batches, isEmpty);
      expect(idle.switches, isEmpty);
      expect(idle.playing, isFalse);
      expect(idle.pauses, 0);
      expect(idle.missing, isEmpty);
      expect(idle.volumes, isNotEmpty);
      expect(idle.speeds, [1.25]);
    });

    test('after a switch, commands and accessors take the new active '
        'deck', () async {
      await setUpAdapter(queue: tracks);
      adapter.debugActivateDeck(1);
      // The new deck says which song of the queue plays.
      idle.indexValue = 2;
      expect(adapter.currentTrack, c);
      await adapter.seekTo(const Duration(seconds: 5));
      expect(idle.seeks, [(const Duration(seconds: 5), null)]);
      expect(player.seeks, isEmpty);
      await adapter.pause(fade: Duration.zero);
      expect(idle.pauses, 1);
      expect(player.pauses, 0);
    });

    test('volume, trim and speed reach both decks, so either can take '
        'over', () async {
      // Nothing playing: no fade under way on either deck.
      await setUpAdapter();
      await adapter.setVolume(0.8);
      adapter.setTrim(0.5);
      await adapter.setSpeed(1.5);
      await pumpEventQueue();
      expect(player.volumes.last, closeTo(0.4, 1e-9));
      expect(idle.volumes.last, closeTo(0.4, 1e-9));
      expect(player.speeds.last, 1.5);
      expect(idle.speeds.last, 1.5);
    });

    test(
      'a restored session sets the volume and speed of both decks',
      () async {
        await setUpAdapter();
        await adapter.restoreQueue(
          Queue.fromTracks(tracks, startIndex: 1),
          position: Duration.zero,
          play: false,
          volume: 0.5,
          speed: 1.25,
        );
        expect(idle.volumes.last, 0.5);
        expect(idle.speeds.last, 1.25);
        expect(idle.loads, isEmpty);
      },
    );

    test('the streams follow the active deck', () async {
      await setUpAdapter(queue: tracks);
      final positions = <Duration>[];
      final durations = <Duration>[];
      final statuses = <PlaybackStatus>[];
      final errors = <String>[];
      final buffered = <Duration>[];
      final speeds = <double>[];
      adapter.bufferedPositionStream.listen(buffered.add);
      adapter.speedStream.listen(speeds.add);
      adapter.positionStream.listen(positions.add);
      adapter.durationStream.listen(durations.add);
      adapter.statusStream.listen(statuses.add);
      adapter.errorStream.listen((f) => errors.add(f.message));
      // The active deck reaches the streams on the next turn.
      await pumpEventQueue();

      player.positions.add(const Duration(seconds: 1));
      player.durations.add(const Duration(minutes: 3));
      idle.positions.add(const Duration(seconds: 50));
      idle.durations.add(const Duration(minutes: 4));
      idle.errors.add(PlayerException(1, 'idle', null));
      await pumpEventQueue();
      expect(positions, [const Duration(seconds: 1)]);
      expect(durations, [const Duration(minutes: 3)]);
      expect(errors, isEmpty);

      player.buffered.add(const Duration(seconds: 10));
      player.speedEvents.add(1);
      adapter.debugActivateDeck(1);
      await pumpEventQueue();
      idle.buffered.add(const Duration(seconds: 20));
      idle.speedEvents.add(1.5);
      player.buffered.add(const Duration(seconds: 99));
      player.speedEvents.add(2);
      idle.positions.add(const Duration(seconds: 2));
      idle.states.add(PlayerState(true, ProcessingState.ready));
      idle.errors.add(PlayerException(2, 'now active', null));
      player.positions.add(const Duration(seconds: 99));
      player.states.add(PlayerState(false, ProcessingState.ready));
      await pumpEventQueue();
      expect(positions, [
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ]);
      expect(statuses.last, PlaybackStatus.playing);
      expect(errors, ['now active']);
      expect(buffered, [
        const Duration(seconds: 10),
        const Duration(seconds: 20),
      ]);
      expect(speeds, [1, 1.5]);
    });

    test('the idle deck never changes the song playing', () async {
      await setUpAdapter(queue: tracks);
      idle.index.add(2);
      idle.index.add(null);
      await pumpEventQueue();
      expect(adapter.currentQueue!.currentIndex, 0);
      expect(playing, isEmpty);
    });

    test('the idle deck reaching its end leaves playback alone', () async {
      await setUpAdapter(queue: tracks);
      final pauses = player.pauses;
      idle.completeQueue();
      await pumpEventQueue();
      expect(player.pauses, pauses);
      expect(adapter.currentStatus, PlaybackStatus.playing);
    });

    test('once active, a deck drives the queue and the other is '
        'ignored', () async {
      await setUpAdapter(queue: tracks);
      adapter.debugActivateDeck(1);
      idle.indexValue = 2;
      idle.index.add(2);
      player.index.add(1);
      await pumpEventQueue();
      expect(adapter.currentQueue!.currentIndex, 2);
      expect(playing, ['c']);

      final pauses = player.pauses;
      player.completeQueue();
      await pumpEventQueue();
      expect(player.pauses, pauses);
    });

    test('dispose lets go of both decks', () async {
      await setUpAdapter();
      await adapter.dispose();
      expect(player.disposals, 1);
      expect(idle.disposals, 1);
    });
  });

  group('fades', () {
    const fade = JustAudioAdapter.fadeDuration;

    /// An adapter playing [tracks], its fade-in over and forgotten.
    void playing(FakeAsync async) {
      player = FakeJustAudioPlayer();
      idle = FakeJustAudioPlayer();
      adapter = JustAudioAdapter(players: [player, idle]);
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

    test('the end of the queue pauses the player and reads stopped', () {
      fakeAsync((async) {
        playing(async);
        expect(adapter.currentStatus, PlaybackStatus.playing);

        player.completeQueue();
        async.flushMicrotasks();

        expect(player.pauses, 1);
        expect(player.playing, isFalse);
        expect(adapter.currentStatus, PlaybackStatus.stopped);
      });
    });

    test('a completed queue reads stopped while just_audio still plays', () {
      fakeAsync((async) {
        playing(async);
        player.processingState = ProcessingState.completed;

        expect(player.playing, isTrue);
        expect(adapter.currentStatus, PlaybackStatus.stopped);
      });
    });

    test('a pause without fade pauses at once', () {
      fakeAsync((async) {
        playing(async);

        adapter.pause(fade: Duration.zero);
        async.flushMicrotasks();

        expect(player.pauses, 1);
        expect(player.volumes, isEmpty);
      });
    });

    test('a pause without fade cuts a fade-out short', () {
      fakeAsync((async) {
        playing(async);
        adapter.pause();
        async.elapse(fade ~/ 3);
        final steps = player.volumes.length;

        adapter.pause(fade: Duration.zero);
        async.flushMicrotasks();
        expect(player.pauses, 1);

        async.elapse(fade);
        expect(player.pauses, 1);
        expect(player.volumes, hasLength(steps));
      });
    });

    test('resume after a cut pause starts from silence and fades in', () {
      fakeAsync((async) {
        playing(async);
        adapter.pause(fade: Duration.zero);
        async.flushMicrotasks();

        adapter.resume();
        async.elapse(fade);

        expect(player.volumes.first, 0);
        expect(player.volumes.last, 1);
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
