import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/repositories/player_repository.dart';
import 'package:troona/features/player/domain/use_cases/play_track_use_case.dart';
import 'package:troona/features/player/domain/use_cases/player_use_cases.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

/// Test doubles for [PlayerBloc]: a scriptable [AudioServicePort] and a
/// repository that routes every use case to it.
Track testTrack(String id, {required int durationMs}) => Track(
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

PlayerBloc buildTestPlayerBloc(
  AudioServicePort port,
  PlaybackSessionStore store, {
  LibraryRepository? library,
}) {
  final repo = PortRepository(port);
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
    skipToIndex: SkipToIndexUseCase(repo),
    audioServicePort: port,
    sessionStore: store,
    getTracksByIds: GetTracksByIdsUseCase(library ?? UnusedLibrary()),
  );
}

final class FakeAudioPort implements AudioServicePort {
  final position = StreamController<Duration>.broadcast(sync: true);
  final buffered = StreamController<Duration>.broadcast(sync: true);
  final status = StreamController<PlaybackStatus>.broadcast(sync: true);
  final track = StreamController<Track?>.broadcast(sync: true);
  final durationCtrl = StreamController<Duration>.broadcast(sync: true);
  final queueCtrl = StreamController<Queue>.broadcast(sync: true);
  final volume = StreamController<double>.broadcast(sync: true);
  final speed = StreamController<double>.broadcast(sync: true);
  final errorsCtrl = StreamController<Failure>.broadcast(sync: true);

  Queue? queue;
  Duration duration = Duration.zero;
  final seeks = <Duration>[];
  final indexJumps = <int>[];
  int skipPreviousCalls = 0;
  int setQueueCalls = 0;

  static Future<Either<Failure, Unit>> get _ok async => const Right(unit);

  Future<void> close() => Future.wait([
    position.close(),
    buffered.close(),
    status.close(),
    track.close(),
    durationCtrl.close(),
    queueCtrl.close(),
    volume.close(),
    speed.close(),
    errorsCtrl.close(),
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
  Stream<double> get speedStream => speed.stream;
  @override
  Stream<Failure> get errorStream => errorsCtrl.stream;

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
  Future<Either<Failure, Unit>> skipToIndex(int index) {
    indexJumps.add(index);
    return _ok;
  }

  @override
  Future<Either<Failure, Unit>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
    bool? shuffle,
  }) {
    setQueueCalls++;
    lastSetQueue = (tracks: tracks, startIndex: startIndex, shuffle: shuffle);
    return _ok;
  }

  ({List<Track> tracks, int startIndex, bool? shuffle})? lastSetQueue;

  /// Queue edits as `start`/`end` pairs, to observe their ordering.
  final queueEdits = <String>[];

  /// When set, every edit is rolled back like a rejected player call.
  bool failEdits = false;

  /// Rejects only the next [failNextEdits] edits.
  int failNextEdits = 0;

  /// Holds the next edit on the player until completed.
  Completer<void>? editGate;

  /// Mirrors the real adapter: the queue is updated and emitted first, then
  /// restored and emitted again if the player call fails.
  Future<Either<Failure, Unit>> _edit(
    String name,
    Queue Function(Queue) apply,
  ) async {
    queueEdits.add('start $name');
    final before = queue;
    if (before != null) _emitQueue(apply(before));
    final gate = editGate;
    editGate = null;
    if (gate != null) await gate.future;
    await Future<void>.delayed(Duration.zero);
    queueEdits.add('end $name');
    final fail = failEdits || failNextEdits > 0;
    if (failNextEdits > 0) failNextEdits--;
    if (fail && before != null) {
      _emitQueue(before);
      return const Left(PlaybackFailure('rejected'));
    }
    return const Right(unit);
  }

  void _emitQueue(Queue next) {
    queue = next;
    if (!queueCtrl.isClosed) queueCtrl.add(next);
  }

  @override
  Future<Either<Failure, Unit>> addToQueue(Track track, {int? index}) => _edit(
    'add ${track.id}@$index',
    (q) => index == null
        ? q.insertAt(q.playbackTracks.length, track)
        : q.insertAt(index, track),
  );

  @override
  Future<Either<Failure, Unit>> removeFromQueue(int index) =>
      _edit('remove $index', (q) => q.removeAt(index));

  @override
  Future<Either<Failure, Unit>> moveQueueItem(int oldIndex, int newIndex) =>
      _edit('move $oldIndex>$newIndex', (q) => q.moveItem(oldIndex, newIndex));

  @override
  dynamic noSuchMethod(Invocation invocation) => _ok;
}

/// Routes the use cases to the fake port so seeks and skips are observable.
final class PortRepository implements PlayerRepository {
  PortRepository(this._port);
  final AudioServicePort _port;

  @override
  Future<Either<Failure, Unit>> seekTo(Duration position) =>
      _port.seekTo(position);

  @override
  Future<Either<Failure, Unit>> skipToPrevious() => _port.skipToPrevious();

  @override
  Future<Either<Failure, Unit>> skipToIndex(int index) =>
      _port.skipToIndex(index);

  @override
  Future<Either<Failure, Unit>> setQueue(
    List<Track> tracks, {
    int startIndex = 0,
    bool? shuffle,
  }) => _port.setQueue(tracks, startIndex: startIndex, shuffle: shuffle);

  @override
  Future<Either<Failure, Unit>> addToQueue(Track track, {int? index}) =>
      _port.addToQueue(track, index: index);

  @override
  Future<Either<Failure, Unit>> removeFromQueue(int index) =>
      _port.removeFromQueue(index);

  @override
  Future<Either<Failure, Unit>> moveQueueItem(int oldIndex, int newIndex) =>
      _port.moveQueueItem(oldIndex, newIndex);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Either<Failure, Unit>>.value(const Right(unit));
}

final class UnusedLibrary implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
