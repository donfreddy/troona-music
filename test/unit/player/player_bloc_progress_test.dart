import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/repositories/player_repository.dart';
import 'package:troona/features/player/domain/use_cases/play_track_use_case.dart';
import 'package:troona/features/player/domain/use_cases/player_use_cases.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAudioPort port;
  late PlaybackSessionStore store;
  late PlayerBloc bloc;
  late List<PlayerState> emitted;
  late StreamSubscription<PlayerState> sub;

  final track = _track('a', durationMs: 200000);
  final other = _track('b', durationMs: 100000);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = _FakeAudioPort();
    store = PlaybackSessionStore(prefs);
    bloc = _buildBloc(port, store);
    emitted = [];
    sub = bloc.stream.listen(emitted.add);
  });

  tearDown(() async {
    await sub.cancel();
    await bloc.close();
    await port.close();
  });

  Future<void> activate({
    int index = 0,
    RepeatMode repeatMode = RepeatMode.off,
  }) async {
    final tracks = [track, other];
    port.queue = Queue(
      originalTracks: tracks,
      playbackTracks: tracks,
      currentIndex: index,
      shuffleEnabled: false,
      repeatMode: repeatMode,
    );
    port.duration = Duration(milliseconds: tracks[index].durationMs);
    bloc.add(QueueSetRequested(tracks, startIndex: index));
    await pumpEventQueue();
    port.status.add(PlaybackStatus.playing);
    await pumpEventQueue();
    expect(bloc.state, isA<PlayerActive>());
    emitted.clear();
  }

  group('PlaybackProgress', () {
    test('ratio is 0 when duration is unknown', () {
      const p = PlaybackProgress(
        position: Duration(seconds: 5),
        buffered: Duration.zero,
        duration: Duration.zero,
      );
      expect(p.ratio, 0);
    });

    test('ratio and remaining are clamped past the end', () {
      const p = PlaybackProgress(
        position: Duration(seconds: 12),
        buffered: Duration.zero,
        duration: Duration(seconds: 10),
      );
      expect(p.ratio, 1);
      expect(p.remaining, Duration.zero);
    });

    test('remaining is duration minus position', () {
      const p = PlaybackProgress(
        position: Duration(seconds: 4),
        buffered: Duration.zero,
        duration: Duration(seconds: 10),
      );
      expect(p.ratio, closeTo(0.4, 1e-9));
      expect(p.remaining, const Duration(seconds: 6));
    });
  });

  group('PlayerBloc progress clock', () {
    test('position ticks update progress without emitting states', () async {
      await activate();

      for (var ms = 0; ms < 1000; ms += 16) {
        port.position.add(Duration(milliseconds: ms));
      }
      await pumpEventQueue();

      expect(emitted, isEmpty);
      expect(bloc.progress.value.position, const Duration(milliseconds: 992));
    });

    test('buffered ticks update progress without emitting states', () async {
      await activate();

      port.buffered.add(const Duration(seconds: 30));
      await pumpEventQueue();

      expect(emitted, isEmpty);
      expect(bloc.progress.value.buffered, const Duration(seconds: 30));
    });

    test('progress mirrors the active track duration', () async {
      await activate();
      expect(bloc.progress.value.duration, const Duration(seconds: 200));
    });

    test(
      'seek updates progress optimistically and ignores stale ticks',
      () async {
        await activate();
        port.position.add(const Duration(seconds: 10));
        await pumpEventQueue();

        bloc.add(const SeekRequested(Duration(seconds: 90)));
        await pumpEventQueue();
        expect(bloc.progress.value.position, const Duration(seconds: 90));

        // A stale engine tick arriving during the seek window is ignored.
        port.position.add(const Duration(seconds: 10));
        await pumpEventQueue();
        expect(bloc.progress.value.position, const Duration(seconds: 90));
        expect(port.seeks, [const Duration(seconds: 90)]);
      },
    );

    test('ticks are accepted again once the seek window closes', () async {
      await activate();
      bloc.add(const SeekRequested(Duration(seconds: 90)));
      await pumpEventQueue();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      port.position.add(const Duration(seconds: 91));
      await pumpEventQueue();

      expect(bloc.progress.value.position, const Duration(seconds: 91));
    });

    test('identical structural updates are deduplicated', () async {
      await activate();

      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();

      expect(emitted, isEmpty);
    });

    test('a status change still emits', () async {
      await activate();

      port.status.add(PlaybackStatus.paused);
      await pumpEventQueue();

      expect(emitted, hasLength(1));
      expect((emitted.single as PlayerActive).status, PlaybackStatus.paused);
    });

    test('a volume change still emits', () async {
      await activate();

      bloc.add(const VolumeChangeRequested(0.4));
      await pumpEventQueue();

      expect(emitted, hasLength(1));
      expect((emitted.single as PlayerActive).volume, 0.4);
    });

    test('skip previous restarts the track after 3 seconds', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.seeks, [Duration.zero]);
      expect(port.skipPreviousCalls, 0);
      expect(bloc.progress.value.position, Duration.zero);
    });

    test('skip previous skips back from a middle track', () async {
      await activate(index: 1);
      port.position.add(const Duration(seconds: 1));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.skipPreviousCalls, 1);
      expect(port.seeks, isEmpty);
    });

    test('skip previous wraps on the first track with repeat all', () async {
      await activate(repeatMode: RepeatMode.all);
      port.position.add(const Duration(seconds: 1));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.skipPreviousCalls, 1);
      expect(port.seeks, isEmpty);
    });

    test('skip previous restarts the first track instead of no-op', () async {
      await activate();
      port.position.add(const Duration(seconds: 1));
      await pumpEventQueue();

      bloc.add(const SkipPreviousRequested());
      await pumpEventQueue();

      expect(port.seeks, [Duration.zero]);
      expect(port.skipPreviousCalls, 0);
    });

    test('track change resets the position', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.track.add(other);
      await pumpEventQueue();

      expect(bloc.progress.value.position, Duration.zero);
      expect(bloc.progress.value.duration, const Duration(seconds: 100));
    });

    test('a stale engine track does not override a requested track', () async {
      await activate();

      bloc.add(
        PlayTrackRequested(
          other,
          contextQueue: [track, other],
          contextIndex: 1,
        ),
      );
      await pumpEventQueue();
      expect((bloc.state as PlayerLoading).track.id, 'b');

      // While swapping sources the engine re-announces the previous index.
      port.track.add(track);
      await pumpEventQueue();
      expect((bloc.state as PlayerLoading).track.id, 'b');

      // The requested track is confirmed, then playback starts.
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.track.add(other);
      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();
      final active = bloc.state as PlayerActive;
      expect(active.currentTrack.id, 'b');
      expect(active.queue.currentIndex, 1);
    });

    test('engine track changes are followed again once active', () async {
      await activate();
      bloc.add(
        PlayTrackRequested(
          other,
          contextQueue: [track, other],
          contextIndex: 1,
        ),
      );
      await pumpEventQueue();
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.status.add(PlaybackStatus.playing);
      await pumpEventQueue();

      // Auto-advance or lock screen skip back to the first track.
      port.queue = port.queue!.copyWith(currentIndex: 0);
      port.track.add(track);
      await pumpEventQueue();
      expect((bloc.state as PlayerActive).currentTrack.id, 'a');
    });

    test(
      'loading a new track resets progress and ignores stale ticks',
      () async {
        await activate();
        port.position.add(const Duration(seconds: 42));
        await pumpEventQueue();

        bloc.add(QueueSetRequested([other]));
        await pumpEventQueue();
        expect(bloc.state, isA<PlayerLoading>());

        // A tick from the outgoing source must not leak into the new track.
        port.position.add(const Duration(seconds: 50));
        await pumpEventQueue();

        expect(bloc.progress.value.position, Duration.zero);
        expect(bloc.progress.value.duration, const Duration(seconds: 100));
      },
    );

    test('becoming active seeds the position from the engine', () async {
      port.currentPositionValue = const Duration(seconds: 33);
      await activate();

      expect(bloc.progress.value.position, const Duration(seconds: 33));
    });

    test('dismissing the player resets progress to zero', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      bloc.add(const PlayerDismissed());
      await pumpEventQueue();

      expect(bloc.state, isA<PlayerIdle>());
      expect(bloc.progress.value, PlaybackProgress.zero);
    });

    test('end of queue rewinds to zero and pauses', () async {
      await activate();
      port.position.add(const Duration(seconds: 199));
      await pumpEventQueue();

      port.status.add(PlaybackStatus.stopped);
      await pumpEventQueue();

      expect((bloc.state as PlayerActive).status, PlaybackStatus.paused);
      expect(bloc.progress.value.position, Duration.zero);
      expect(port.seeks, [Duration.zero]);
    });

    test('ticks persist the position once per second', () async {
      await activate();

      port.position.add(const Duration(milliseconds: 42500));
      await pumpEventQueue();

      final snapshot = store.load();
      expect(snapshot?.currentTrackId, 'a');
      expect(snapshot?.positionMs, 42500);
    });

    test('ticks overtaking a track change are not persisted', () async {
      await activate();
      port.position.add(const Duration(seconds: 42));
      await pumpEventQueue();

      // The engine already switched, but _TrackChanged has not run yet.
      port.queue = port.queue!.copyWith(currentIndex: 1);
      port.position.add(const Duration(seconds: 77));
      await pumpEventQueue();

      final snapshot = store.load();
      expect(snapshot?.currentTrackId, 'a');
      expect(snapshot?.positionMs, 42000);
    });
  });
}

// ── Fakes ────────────────────────────────────────────────────────────────────

Track _track(String id, {required int durationMs}) => Track(
  id: id,
  title: 'Title $id',
  artist: 'Artist',
  artistId: 1,
  album: 'Album',
  albumId: 1,
  path: '/music/$id.mp3',
  uri: 'content://$id',
  size: 1,
  durationMs: durationMs,
  fileName: '$id.mp3',
);

PlayerBloc _buildBloc(AudioServicePort port, PlaybackSessionStore store) {
  final repo = _PortRepository(port);
  return PlayerBloc(
    playTrack: PlayTrackUseCase(repo),
    pause: PauseUseCase(repo),
    resume: ResumeUseCase(repo),
    seek: SeekUseCase(repo),
    skipNext: SkipNextUseCase(repo),
    skipPrevious: SkipPreviousUseCase(repo),
    setQueue: SetQueueUseCase(repo),
    addToQueue: AddToQueueUseCase(repo),
    removeFromQueue: RemoveFromQueueUseCase(repo),
    moveQueueItem: MoveQueueItemUseCase(repo),
    toggleShuffle: ToggleShuffleUseCase(repo),
    setRepeatMode: SetRepeatModeUseCase(repo),
    setVolume: SetVolumeUseCase(repo),
    setSpeed: SetSpeedUseCase(repo),
    audioServicePort: port,
    sessionStore: store,
    libraryCache: _UnusedLibraryCache(),
  );
}

final class _FakeAudioPort implements AudioServicePort {
  final position = StreamController<Duration>.broadcast(sync: true);
  final buffered = StreamController<Duration>.broadcast(sync: true);
  final status = StreamController<PlaybackStatus>.broadcast(sync: true);
  final track = StreamController<Track?>.broadcast(sync: true);
  final durationCtrl = StreamController<Duration>.broadcast(sync: true);
  final queueCtrl = StreamController<Queue>.broadcast(sync: true);
  final volume = StreamController<double>.broadcast(sync: true);

  Queue? queue;
  Duration duration = Duration.zero;
  final seeks = <Duration>[];
  int skipPreviousCalls = 0;

  static Future<Either<Failure, Unit>> get _ok async => const Right(unit);

  Future<void> close() => Future.wait([
    position.close(),
    buffered.close(),
    status.close(),
    track.close(),
    durationCtrl.close(),
    queueCtrl.close(),
    volume.close(),
  ]);

  @override
  Stream<Duration> get positionStream => position.stream;
  @override
  Stream<Duration> get bufferedPositionStream => buffered.stream;
  @override
  Stream<PlaybackStatus> get statusStream => status.stream;
  @override
  Stream<Track?> get currentTrackStream => track.stream;
  @override
  Stream<Duration> get durationStream => durationCtrl.stream;
  @override
  Stream<Queue> get queueStream => queueCtrl.stream;
  @override
  Stream<double> get volumeStream => volume.stream;

  @override
  PlaybackStatus get currentStatus => PlaybackStatus.paused;
  @override
  Track? get currentTrack => queue?.currentTrack;
  Duration currentPositionValue = Duration.zero;

  @override
  Duration get currentPosition => currentPositionValue;
  @override
  Duration get currentDuration => duration;
  @override
  Queue? get currentQueue => queue;

  @override
  Future<Either<Failure, Unit>> seekTo(Duration position) {
    seeks.add(position);
    return _ok;
  }

  @override
  Future<Either<Failure, Unit>> skipToPrevious() {
    skipPreviousCalls++;
    return _ok;
  }

  @override
  Future<Either<Failure, Unit>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
  }) => _ok;

  @override
  dynamic noSuchMethod(Invocation invocation) => _ok;
}

/// Routes the use cases to the fake port so seeks and skips are observable.
final class _PortRepository implements PlayerRepository {
  _PortRepository(this._port);
  final AudioServicePort _port;

  @override
  Future<Either<Failure, Unit>> seekTo(Duration position) =>
      _port.seekTo(position);

  @override
  Future<Either<Failure, Unit>> skipToPrevious() => _port.skipToPrevious();

  @override
  Future<Either<Failure, Unit>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
  }) => _port.setQueue(tracks, startIndex: startIndex);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Either<Failure, Unit>>.value(const Right(unit));
}

final class _UnusedLibraryCache implements IsarLibraryDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
