import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/presentation/bloc/sleep_timer/sleep_timer_cubit.dart';

import '../../helpers/fake_player.dart';

/// Records pauses and volume changes; echoes volumes like the real adapter.
final class _Port implements AudioServicePort {
  final trackCtrl = StreamController<Track?>.broadcast(sync: true);
  final volumeCtrl = StreamController<double>.broadcast(sync: true);
  final volumes = <double>[];
  int pauses = 0;
  int fadedPauses = 0;
  Track? playing;

  @override
  Stream<Track?> get currentTrackStream => trackCtrl.stream;
  @override
  Stream<double> get volumeStream => volumeCtrl.stream;
  @override
  Track? get currentTrack => playing;

  @override
  Future<Either<Failure, Unit>> pause({bool fade = true}) async {
    pauses++;
    if (fade) fadedPauses++;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> setVolume(double volume) async {
    volumes.add(volume);
    volumeCtrl.add(volume);
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

  test('pauses after the delay, fading out, then restores the volume', () {
    fakeAsync((async) {
      final cubit = SleepTimerCubit(port: port, now: () => DateTime(2026));
      port.volumeCtrl.add(0.8);

      cubit.startFor(const Duration(minutes: 15));
      expect(cubit.state, isA<SleepTimerRunning>());

      async.elapse(const Duration(minutes: 14, seconds: 49));
      expect(port.pauses, 0);
      expect(port.volumes, isEmpty);

      async.elapse(const Duration(seconds: 11));
      expect(port.pauses, 1);
      expect(port.fadedPauses, 0, reason: 'its own fade is enough');
      expect(cubit.state, const SleepTimerOff());
      // Fades down to silence, then back to the user's level.
      expect(port.volumes.first, lessThan(0.8));
      expect(port.volumes[port.volumes.length - 2], closeTo(0, 1e-9));
      expect(port.volumes.last, 0.8);
    });
  });

  test('starting again replaces the previous timer', () {
    fakeAsync((async) {
      final cubit = SleepTimerCubit(port: port);
      cubit.startFor(const Duration(minutes: 1));
      cubit.startFor(const Duration(minutes: 30));

      async.elapse(const Duration(minutes: 5));
      expect(port.pauses, 0);
      async.elapse(const Duration(minutes: 25));
      expect(port.pauses, 1);
    });
  });

  test('cancelling leaves playback alone and undoes a fade', () {
    fakeAsync((async) {
      final cubit = SleepTimerCubit(port: port);
      port.volumeCtrl.add(0.6);
      cubit.startFor(const Duration(seconds: 20));

      async.elapse(const Duration(seconds: 15)); // halfway through the fade
      cubit.cancel();
      async.elapse(const Duration(minutes: 1));

      expect(port.pauses, 0);
      expect(port.volumes.last, 0.6);
      expect(cubit.state, const SleepTimerOff());
    });
  });

  test('end of track pauses when the next track starts', () {
    fakeAsync((async) {
      port.playing = a;
      final cubit = SleepTimerCubit(port: port);
      cubit.startEndOfTrack();

      port.trackCtrl.add(a); // replayed on listen, or a queue edit
      async.flushMicrotasks();
      expect(port.pauses, 0);

      port.play(b);
      async.flushMicrotasks();
      expect(port.pauses, 1);
      expect(cubit.state, const SleepTimerOff());
      expect(port.volumes, isEmpty);
    });
  });

  test('a timed start replaces end of track', () {
    fakeAsync((async) {
      port.playing = a;
      final cubit = SleepTimerCubit(port: port);
      cubit.startEndOfTrack();
      cubit.startFor(const Duration(hours: 1));

      port.play(b);
      async.flushMicrotasks();
      expect(port.pauses, 0);
      expect(cubit.state, isA<SleepTimerRunning>());
    });
  });
}
