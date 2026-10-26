import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/presentation/bloc/sleep_timer/sleep_timer_cubit.dart';

import '../../helpers/fake_player.dart';

/// Records pauses with their fade, held until [finishFade]. Has no
/// setVolume: the timer must leave the user's volume alone.
final class _Port implements AudioServicePort {
  final trackCtrl = StreamController<Track?>.broadcast(sync: true);
  final positionCtrl = StreamController<Duration>.broadcast(sync: true);
  final speedCtrl = StreamController<double>.broadcast(sync: true);
  final fades = <Duration>[];
  int resumes = 0;
  Track? playing;
  Duration duration = const Duration(minutes: 3);
  PlaybackStatus status = PlaybackStatus.playing;
  Completer<void>? _fade;

  @override
  Stream<Track?> get currentTrackStream => trackCtrl.stream;
  @override
  Stream<Duration> get positionStream => positionCtrl.stream;
  @override
  Stream<double> get speedStream => speedCtrl.stream;
  @override
  Track? get currentTrack => playing;
  @override
  Duration get currentDuration => duration;
  @override
  PlaybackStatus get currentStatus => status;

  @override
  Future<Either<Failure, Unit>> pause({
    Duration fade = AudioServicePort.pauseFade,
  }) async {
    fades.add(fade);
    await (_fade = Completer<void>()).future;
    return right(unit);
  }

  /// Ends the pending pause, paused or taken back by a play.
  void finishFade() => _fade?.complete();

  @override
  Future<Either<Failure, Unit>> resume() async {
    resumes++;
    return right(unit);
  }

  void play(Track track) {
    playing = track;
    trackCtrl.add(track);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Port port;
  final a = testTrack('a', durationMs: 180000);
  final b = testTrack('b', durationMs: 180000);

  setUp(() => port = _Port());

  Duration at(int seconds) => Duration(seconds: seconds);

  group('timed', () {
    test('one pause with a 30 s fade; the state goes off after it', () {
      fakeAsync((async) {
        final cubit = SleepTimerCubit(port: port, now: () => DateTime(2026));
        cubit.startFor(const Duration(minutes: 15));
        expect(cubit.state, isA<SleepTimerRunning>());

        async.elapse(const Duration(minutes: 14, seconds: 29));
        expect(port.fades, isEmpty);
        async.elapse(at(1));
        expect(port.fades, [SleepTimerCubit.fadeDuration]);
        expect(cubit.state, isA<SleepTimerRunning>());

        port.finishFade();
        async.flushMicrotasks();
        expect(cubit.state, const SleepTimerOff());
      });
    });

    test('a short timer fades over half its length', () {
      fakeAsync((async) {
        SleepTimerCubit(port: port).startFor(at(20));
        async.elapse(at(10));
        expect(port.fades, [at(10)]);
      });
    });

    test('starting again replaces the previous timer', () {
      fakeAsync((async) {
        final cubit = SleepTimerCubit(port: port);
        cubit.startFor(const Duration(minutes: 1));
        cubit.startFor(const Duration(minutes: 30));

        async.elapse(const Duration(minutes: 5));
        expect(port.fades, isEmpty);
        async.elapse(const Duration(minutes: 25));
        expect(port.fades, hasLength(1));
      });
    });

    test('cancelling during the fade takes playback back', () {
      fakeAsync((async) {
        final cubit = SleepTimerCubit(port: port);
        cubit.startFor(at(20));
        async.elapse(at(15));
        expect(port.fades, hasLength(1));

        cubit.cancel();
        port.finishFade();
        async.flushMicrotasks();

        expect(port.resumes, 1);
        expect(cubit.state, const SleepTimerOff());
      });
    });

    test('cancelling before the fade leaves playback alone', () {
      fakeAsync((async) {
        final cubit = SleepTimerCubit(port: port);
        cubit.startFor(const Duration(minutes: 10));
        async.elapse(const Duration(minutes: 1));
        cubit.cancel();
        async.elapse(const Duration(minutes: 20));

        expect(port.fades, isEmpty);
        expect(port.resumes, 0);
      });
    });

    test('a new timer during the fade outlives the old fade', () {
      fakeAsync((async) {
        final cubit = SleepTimerCubit(port: port);
        cubit.startFor(at(20));
        async.elapse(at(12));

        cubit.startFor(const Duration(hours: 1));
        port.finishFade();
        async.flushMicrotasks();

        expect(port.resumes, 1);
        expect(cubit.state, isA<SleepTimerRunning>());
      });
    });
  });

  group('end of track', () {
    SleepTimerCubit endOfTrack() {
      port.playing = a;
      return SleepTimerCubit(port: port)..startEndOfTrack();
    }

    test('the fade ends just before the track does', () {
      fakeAsync((async) {
        final cubit = endOfTrack();

        port.positionCtrl.add(at(100));
        port.positionCtrl.add(at(149));
        expect(port.fades, isEmpty);
        port.positionCtrl.add(at(150));
        expect(port.fades, [at(30) - SleepTimerCubit.endOfTrackMargin]);
        expect(cubit.state, const SleepTimerEndOfTrack());

        // Later positions and the next track change nothing.
        port.positionCtrl.add(at(170));
        port.play(b);
        expect(port.fades, hasLength(1));

        port.finishFade();
        async.flushMicrotasks();
        expect(cubit.state, const SleepTimerOff());
      });
    });

    test('at double speed, the fade starts twice as far from the end', () {
      fakeAsync((async) {
        endOfTrack();
        port.speedCtrl.add(2);

        port.positionCtrl.add(at(118));
        expect(port.fades, isEmpty);
        port.positionCtrl.add(at(120));
        expect(port.fades, [at(30) - SleepTimerCubit.endOfTrackMargin]);
      });
    });

    test('set near the end, the fade is what is left', () {
      fakeAsync((async) {
        endOfTrack();
        port.positionCtrl.add(at(179));
        expect(port.fades, [const Duration(milliseconds: 500)]);
      });
    });

    test('paused near the end, it waits for playback', () {
      fakeAsync((async) {
        endOfTrack();
        port.status = PlaybackStatus.paused;
        port.positionCtrl.add(at(170));
        expect(port.fades, isEmpty);

        port.status = PlaybackStatus.playing;
        port.positionCtrl.add(at(171));
        expect(port.fades, hasLength(1));
      });
    });

    test('a skip moves the stop to the end of the new track', () {
      fakeAsync((async) {
        final cubit = endOfTrack();
        port.trackCtrl.add(a); // replayed on listen, or a queue edit
        port.positionCtrl.add(at(60));

        port.play(b);
        port.positionCtrl.add(at(1));
        expect(port.fades, isEmpty);
        expect(cubit.state, const SleepTimerEndOfTrack());

        port.positionCtrl.add(at(160));
        expect(port.fades, hasLength(1));
      });
    });

    test('a track that ended without the fade stops at once', () {
      fakeAsync((async) {
        endOfTrack();
        port.duration = Duration.zero; // unknown: positions cannot help
        port.positionCtrl.add(at(179));

        port.play(b);
        expect(port.fades, [Duration.zero]);
      });
    });
  });

  test('a timed start replaces end of track', () {
    fakeAsync((async) {
      port.playing = a;
      final cubit = SleepTimerCubit(port: port);
      cubit.startEndOfTrack();
      cubit.startFor(const Duration(hours: 1));

      port.play(b);
      port.positionCtrl.add(at(170));
      async.flushMicrotasks();
      expect(port.fades, isEmpty);
      expect(cubit.state, isA<SleepTimerRunning>());
    });
  });
}
