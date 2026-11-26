import 'dart:async';
import 'dart:math' as math;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/domain/entities/mix_settings.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';

import '../../../helpers/fake_just_audio_player.dart';
import '../../../helpers/fake_player.dart';

/// Songs of 200 s fading over 6 s: the transition runs from 193.7 s
/// (outAt) to 199.7 s (end), and is prepared from 178.7 s.
void main() {
  const s = Duration(seconds: 1);
  const ms = Duration(milliseconds: 1);
  final prepareAt = s * 179;
  final outAt = s * 193 + ms * 700;
  final middle = s * 196 + ms * 700;
  final end = s * 199 + ms * 700;

  late List<Track> tracks;
  late MixSettings settings;
  late Map<String, TrackEdges> edges;
  late FakeJustAudioPlayer one;
  late FakeJustAudioPlayer two;
  late JustAudioAdapter adapter;

  setUp(() {
    tracks = [
      for (final id in 'abcd'.split('')) testTrack(id, durationMs: 200000),
    ];
    settings = const MixSettings(crossfade: true);
    edges = {};
  });

  /// Runs [body] with an adapter playing [queue] (the four songs) from
  /// [start], its fade-in over.
  void run(
    void Function(FakeAsync async) body, {
    List<Track>? queue,
    int start = 0,
  }) => fakeAsync((async) {
    one = FakeJustAudioPlayer()..duration = s * 200;
    two = FakeJustAudioPlayer()..duration = s * 200;
    adapter = JustAudioAdapter(
      players: [one, two],
      mix: () => settings,
      edgesOf: (track) => edges[track.id],
    );
    adapter.setQueue(queue ?? tracks, startIndex: start);
    async.elapse(s);
    body(async);
    adapter.dispose();
    async.flushMicrotasks();
  });

  /// [deck] plays to [position], and a transition's ticker reads it.
  void at(FakeAsync async, FakeJustAudioPlayer deck, Duration position) {
    deck.moveTo(position);
    async.elapse(ms * 25);
  }

  /// Plays deck one into the middle of the transition.
  void intoTheFade(FakeAsync async) {
    at(async, one, prepareAt);
    at(async, one, outAt);
    at(async, one, middle);
  }

  int index() => adapter.currentQueue!.currentIndex;

  test('prepares the next song on the idle deck 15 s ahead, paused and '
      'silent', () {
    run((async) {
      at(async, one, s * 178);
      expect(two.loads, isEmpty);

      at(async, one, prepareAt);
      expect(two.loads, [
        ['a', 'b', 'c', 'd'],
      ]);
      expect(two.loadStarts.single, (1, Duration.zero));
      expect(two.playing, isFalse);
      expect(two.volumes.last, 0);
      expect(index(), 0);
      expect(adapter.currentTrack, tracks[0]);
    });
  });

  test('at outAt the song coming starts and becomes the current one', () {
    run((async) {
      final shown = <String?>[];
      adapter.currentTrackStream.listen((t) => shown.add(t?.id));
      at(async, one, prepareAt);
      at(async, one, outAt - ms);
      expect(two.playing, isFalse);

      at(async, one, outAt);
      expect(two.playing, isTrue);
      expect(one.playing, isTrue);
      expect(index(), 1);
      expect(adapter.currentTrack, tracks[1]);
      expect(shown.last, 'b');
    });
  });

  test('the gains follow the song leaving, their powers adding up to '
      'one', () {
    run((async) {
      intoTheFade(async);
      final leaving = one.volumes.last;
      final coming = two.volumes.last;
      expect(leaving, closeTo(math.sqrt1_2, 1e-6));
      expect(leaving * leaving + coming * coming, closeTo(1, 1e-6));
    });
  });

  test('at the end the song leaving stops and the one coming plays at full '
      'volume', () {
    run((async) {
      intoTheFade(async);
      expect(one.stops, 0);
      at(async, one, end);
      expect(one.stops, 1);
      expect(one.playing, isFalse);
      expect(two.volumes.last, 1);
      expect(two.playing, isTrue);
      expect(index(), 1);
    });
  });

  test('the fade never shows on the volume stream', () {
    run((async) {
      final shown = <double>[];
      adapter.volumeStream.listen(shown.add);
      intoTheFade(async);
      at(async, one, end);
      expect(shown, everyElement(1));
    });
  });

  test('the user volume and the trim scale both songs', () {
    run((async) {
      intoTheFade(async);
      adapter.setVolume(0.5);
      async.elapse(Duration.zero);
      expect(one.volumes.last, closeTo(0.5 * math.sqrt1_2, 1e-6));
      expect(two.volumes.last, closeTo(0.5 * math.sqrt1_2, 1e-6));
    });
  });

  group('no transition', () {
    test('when crossfade is off: the song moves on by itself', () {
      settings = MixSettings.off;
      run((async) {
        intoTheFade(async);
        expect(two.loads, isEmpty);
        expect(index(), 0);
      });
    });

    test('under repeat one', () {
      run((async) {
        adapter.setRepeatMode(RepeatMode.one);
        async.elapse(Duration.zero);
        intoTheFade(async);
        expect(two.loads, isEmpty);
      });
    });

    test('after the last song', () {
      run((async) {
        intoTheFade(async);
        expect(two.loads, isEmpty);
      }, start: 3);
    });

    test('from the last song to the first under repeat all', () {
      run((async) {
        adapter.setRepeatMode(RepeatMode.all);
        async.elapse(Duration.zero);
        intoTheFade(async);
        expect(two.loadStarts.single.$1, 0);
        expect(index(), 0);
        expect(two.loopModes.last.name, 'all');
      }, start: 3);
    });

    test('between songs that follow on an album kept whole', () {
      tracks[0].trackNumber = 1;
      tracks[1].trackNumber = 2;
      run((async) {
        intoTheFade(async);
        expect(two.loads, isEmpty);
      });
    });

    test('when the position jumps past the start (a seek): the song ends '
        'by itself', () {
      run((async) {
        at(async, one, prepareAt);
        at(async, one, outAt + s);
        expect(two.playing, isFalse);
        expect(two.stops, 1);
        expect(index(), 0);
      });
    });

    test('when the preparation fails, and it is not tried again for that '
        'queue', () {
      run((async) {
        two.loadError = Exception('unreadable');
        at(async, one, prepareAt);
        at(async, one, prepareAt + s);
        at(async, one, outAt);
        expect(two.loads, hasLength(1));
        expect(two.playing, isFalse);
        expect(index(), 0);
      });
    });
  });

  group('before the start', () {
    test('turning crossfade off drops the song prepared', () {
      run((async) {
        at(async, one, prepareAt);
        settings = MixSettings.off;
        at(async, one, outAt);
        expect(two.playing, isFalse);
        expect(two.stops, 1);
        expect(index(), 0);
      });
    });

    test('a queue edit drops the song prepared; the next position prepares '
        'it again', () {
      run((async) {
        at(async, one, prepareAt);
        adapter.addAllToQueue([tracks[0]], index: 1);
        async.elapse(Duration.zero);
        expect(two.stops, 1);

        at(async, one, prepareAt + s);
        expect(two.loads, hasLength(2));
        expect(two.loads.last, ['a', 'a', 'b', 'c', 'd']);
      });
    });

    test('paused at outAt it waits, and starts once playing again within '
        'the window', () {
      run((async) {
        at(async, one, prepareAt);
        adapter.pause();
        async.elapse(s);
        at(async, one, outAt);
        expect(two.playing, isFalse);

        adapter.resume();
        async.elapse(Duration.zero);
        at(async, one, outAt + ms * 100);
        expect(two.playing, isTrue);
        expect(index(), 1);
      });
    });

    test('a skip drops the song prepared and skips on the deck playing', () {
      run((async) {
        at(async, one, prepareAt);
        adapter.skipToNext();
        async.elapse(s);
        expect(two.stops, 1);
        expect(one.switches.single.$1, 'next');
      });
    });
  });

  group('during the fade', () {
    test('a pause pauses both songs, and resuming plays both', () {
      run((async) {
        intoTheFade(async);
        adapter.pause();
        async.elapse(s);
        expect(one.playing, isFalse);
        expect(two.playing, isFalse);

        adapter.resume();
        async.elapse(s);
        expect(one.playing, isTrue);
        expect(two.playing, isTrue);
        // The transition held still: the gains are where they were.
        expect(one.volumes.last, closeTo(math.sqrt1_2, 1e-6));
      });
    });

    test('a skip applies to the song coming; the one leaving goes out at '
        'once', () {
      run((async) {
        intoTheFade(async);
        adapter.skipToNext();
        async.elapse(s);
        expect(two.switches.single.$1, 'next');
        expect(one.switches, isEmpty);
        expect(one.stops, 1);
        expect(one.volumes.last, 0);
      });
    });

    test('a seek applies to the song coming at full volume', () {
      run((async) {
        intoTheFade(async);
        adapter.seekTo(s * 30);
        async.elapse(s);
        expect(two.seeks.last, (s * 30, null));
        expect(one.seeks, isEmpty);
        expect(two.volumes.last, 1);
        expect(one.stops, 1);
      });
    });

    test('stop stops both songs', () {
      run((async) {
        intoTheFade(async);
        adapter.stop();
        async.elapse(Duration.zero);
        expect(one.stops, 1);
        expect(two.stops, 1);
      });
    });

    test('a queue edit goes to the song coming; the one leaving carries '
        'on', () {
      run((async) {
        intoTheFade(async);
        adapter.addAllToQueue([tracks[0]]);
        async.elapse(Duration.zero);
        expect(two.batches, ['end:a']);
        expect(one.batches, isEmpty);
        expect(one.playing, isTrue);
        expect(one.stops, 0);
        expect(adapter.currentQueue!.playbackTracks.last, tracks[0]);
      });
    });

    test('the deck leaving moving on by itself stops at once', () {
      run((async) {
        intoTheFade(async);
        one.index.add(1);
        async.elapse(Duration.zero);
        expect(one.stops, 1);
        expect(index(), 1);
      });
    });

    test('the index of the deck leaving never moves the queue', () {
      run((async) {
        intoTheFade(async);
        one.index.add(3);
        async.elapse(Duration.zero);
        expect(index(), 1);
      });
    });
  });

  group('fixes from review', () {
    test('a pause and a play within the 15 s keep the song prepared, and '
        'the transition still happens', () {
      run((async) {
        at(async, one, prepareAt);
        adapter.pause();
        async.elapse(s);
        adapter.resume();
        async.elapse(s);
        expect(two.stops, 0);
        expect(two.loads, hasLength(1));

        at(async, one, outAt);
        expect(two.playing, isTrue);
        expect(index(), 1);
      });
    });

    test('paused just before outAt, played again within the window: the '
        'transition starts', () {
      run((async) {
        at(async, one, prepareAt);
        at(async, one, outAt - ms * 200);
        adapter.pause();
        async.elapse(s);
        at(async, one, outAt);
        expect(two.playing, isFalse);
        adapter.resume();
        async.elapse(Duration.zero);
        at(async, one, outAt + ms * 100);
        expect(two.playing, isTrue);
        expect(two.loads, hasLength(1));
      });
    });

    test('a failed preparation is not tried again when the index is '
        'reported again', () {
      run((async) {
        two.loadError = Exception('unreadable');
        at(async, one, prepareAt);
        adapter.pause();
        async.elapse(s);
        adapter.resume();
        async.elapse(s);
        at(async, one, prepareAt + s);
        expect(two.loads, hasLength(1));
      });
    });

    test('no timer outlives a transition, ten in a row', () {
      run((async) {
        adapter.setRepeatMode(RepeatMode.all);
        async.elapse(Duration.zero);
        var leaving = one;
        var coming = two;
        for (var i = 1; i <= 10; i++) {
          at(async, leaving, prepareAt);
          expect(async.periodicTimerCount, 1);
          at(async, leaving, outAt);
          at(async, leaving, end);
          expect(async.periodicTimerCount, 0);
          expect(index(), i % 4);
          expect(coming.playing, isTrue);
          expect(leaving.playing, isFalse);
          (leaving, coming) = (coming, leaving);
        }
      });
    });

    test('a stop still pending never lands on the next load of its '
        'deck', () {
      run((async) {
        intoTheFade(async);
        // The song leaving goes out in 120 ms, then stops: held.
        final held = one.stopGate = Completer<void>();
        adapter.skipToNext();
        async.elapse(s);
        // A transition is prepared on that deck, waits for the stop, and
        // is dropped by a queue edit; the next one is prepared.
        at(async, two, prepareAt);
        adapter.addAllToQueue([tracks[0]]);
        async.elapse(Duration.zero);
        at(async, two, prepareAt + s);

        held.complete();
        async.elapse(s);
        expect(one.loads, hasLength(2));
        // Every stop came before the load: none of them undid it.
        expect(one.stopsAtLoad.last, one.stops);
      });
    });

    test('an index out of range leaves the transition alone', () {
      run((async) {
        intoTheFade(async);
        adapter.skipToIndex(9);
        async.elapse(s);
        expect(one.stops, 0);
        expect(one.playing, isTrue);
      });
    });
  });

  group('smart transitions', () {
    test('the song coming starts after its silence', () {
      edges['b'] = const TrackEdges(
        musicStart: Duration(seconds: 2),
        musicEnd: Duration(seconds: 200),
      );
      run((async) {
        at(async, one, prepareAt);
        expect(two.loadStarts.single, (1, s * 2));
      });
    });

    test('the song leaving ends where its music does', () {
      edges['a'] = const TrackEdges(
        musicStart: Duration.zero,
        musicEnd: Duration(seconds: 190),
      );
      run((async) {
        at(async, one, s * 169);
        expect(two.loads, hasLength(1));
        at(async, one, s * 184 - ms);
        expect(two.playing, isFalse);
        at(async, one, s * 184);
        expect(two.playing, isTrue);
        expect(index(), 1);
        at(async, one, s * 190);
        expect(one.stops, 1);
        expect(two.volumes.last, 1);
      });
    });

    test('a song fading out by itself keeps its volume until the next is '
        'whole, then goes to nothing by its end', () {
      edges['a'] = const TrackEdges(
        musicStart: Duration.zero,
        musicEnd: Duration(seconds: 195),
        fadeDown: Duration(seconds: 190),
      );
      run((async) {
        at(async, one, s * 175);
        at(async, one, s * 190);
        expect(two.playing, isTrue);
        at(async, one, s * 191);
        expect(one.volumes.last, 1);
        expect(two.volumes.last, greaterThan(0));
        expect(two.volumes.last, lessThan(1));
        // Whole at 60 % of the 5 s overlap.
        at(async, one, s * 193);
        expect(two.volumes.last, closeTo(1, 1e-6));
        expect(one.volumes.last, 1);
        at(async, one, s * 194);
        expect(one.volumes.last, closeTo(math.sqrt1_2, 1e-6));
        at(async, one, s * 195 - ms * 50);
        expect(one.volumes.last, lessThan(0.05));
        at(async, one, s * 195);
        expect(one.stops, 1);
      });
    });

    test('edges found once past their start leave the plain transition', () {
      run((async) {
        at(async, one, s * 170);
        edges['a'] = const TrackEdges(
          musicStart: Duration.zero,
          musicEnd: Duration(seconds: 172),
        );
        at(async, one, s * 171);
        expect(two.loads, isEmpty);
        at(async, one, prepareAt);
        expect(two.loads, hasLength(1));
        at(async, one, outAt);
        expect(two.playing, isTrue);
        expect(index(), 1);
      });
    });

    test('turned off, the edges are ignored', () {
      settings = const MixSettings(crossfade: true, smart: false);
      edges['b'] = const TrackEdges(
        musicStart: Duration(seconds: 2),
        musicEnd: Duration(seconds: 200),
      );
      run((async) {
        at(async, one, prepareAt);
        expect(two.loadStarts.single, (1, Duration.zero));
      });
    });
  });

  test('transitions alternate between the decks', () {
    run((async) {
      intoTheFade(async);
      at(async, one, end);

      at(async, two, prepareAt);
      expect(one.loads.last, ['a', 'b', 'c', 'd']);
      expect(one.loadStarts.last, (2, Duration.zero));
      at(async, two, outAt);
      expect(one.playing, isTrue);
      expect(index(), 2);
      expect(adapter.currentTrack, tracks[2]);
      at(async, two, end);
      expect(two.stops, 1);
      expect(one.volumes.last, 1);
    });
  });
}
