import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/use_cases/play_track_use_case.dart';
import 'package:troona/features/player/domain/use_cases/player_use_cases.dart';

part 'player_event.dart';

part 'player_state.dart';

part 'playback_progress.dart';

part 'player_notice.dart';

@injectable
final class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  // ── Use cases ───────────────────────────────────────────────────────────────
  final PlayTrackUseCase _playTrack;
  final PauseUseCase _pause;
  final ResumeUseCase _resume;
  final SeekUseCase _seek;
  final SkipNextUseCase _skipNext;
  final SkipPreviousUseCase _skipPrevious;
  final SetQueueUseCase _setQueue;
  final AddToQueueUseCase _addToQueue;
  final RemoveFromQueueUseCase _removeFromQueue;
  final MoveQueueItemUseCase _moveQueueItem;
  final ToggleShuffleUseCase _toggleShuffle;
  final SetRepeatModeUseCase _setRepeatMode;
  final SetVolumeUseCase _setVolume;
  final SetSpeedUseCase _setSpeed;
  final SkipToIndexUseCase _skipToIndex;
  final AudioServicePort _audioServicePort;
  final PlaybackSessionStore _sessionStore;
  final GetTracksByIdsUseCase _getTracksByIds;

  // ── Stream subscriptions ────────────────────────────────────────────────────
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _bufferedSub;
  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<PlaybackStatus> _statusSub;
  late final StreamSubscription<dynamic> _trackSub;
  late final StreamSubscription<Queue> _queueSub;
  late final StreamSubscription<double> _volumeSub;
  late final StreamSubscription<Failure> _errorSub;
  final StreamController<PlayerNotice> _noticesController =
      StreamController<PlayerNotice>.broadcast();

  /// One-shot error notices (e.g. unplayable track). Listen in the shell
  /// to show a toast. Does not affect player state.
  Stream<PlayerNotice> get notices => _noticesController.stream;

  int? _lastPersistedPositionSecond;
  PlaybackSessionSnapshot? _restoringSnapshot;
  bool _isManualSeeking = false;

  /// Track explicitly asked for (tap, swipe, queue start) while loading.
  /// The engine re-announces its previous index while swapping sources;
  /// those stale announcements must not replace the requested track.
  String? _requestedTrackId;

  final ValueNotifier<PlaybackProgress> _progress = ValueNotifier(
    PlaybackProgress.zero,
  );

  /// Playback clock (position, buffered, duration), updated at stream rate
  /// without emitting states. Listen to it from painters or
  /// [ValueListenableBuilder]s, never from a [BlocBuilder].
  ValueListenable<PlaybackProgress> get progress => _progress;

  PlayerBloc({
    required PlayTrackUseCase playTrack,
    required PauseUseCase pause,
    required ResumeUseCase resume,
    required SeekUseCase seek,
    required SkipNextUseCase skipNext,
    required SkipPreviousUseCase skipPrevious,
    required SetQueueUseCase setQueue,
    required AddToQueueUseCase addToQueue,
    required RemoveFromQueueUseCase removeFromQueue,
    required MoveQueueItemUseCase moveQueueItem,
    required ToggleShuffleUseCase toggleShuffle,
    required SetRepeatModeUseCase setRepeatMode,
    required SetVolumeUseCase setVolume,
    required SetSpeedUseCase setSpeed,
    required SkipToIndexUseCase skipToIndex,
    required AudioServicePort audioServicePort,
    required PlaybackSessionStore sessionStore,
    required GetTracksByIdsUseCase getTracksByIds,
  }) : _playTrack = playTrack,
       _pause = pause,
       _resume = resume,
       _seek = seek,
       _skipNext = skipNext,
       _skipPrevious = skipPrevious,
       _setQueue = setQueue,
       _addToQueue = addToQueue,
       _removeFromQueue = removeFromQueue,
       _moveQueueItem = moveQueueItem,
       _toggleShuffle = toggleShuffle,
       _setRepeatMode = setRepeatMode,
       _setVolume = setVolume,
       _setSpeed = setSpeed,
       _skipToIndex = skipToIndex,
       _audioServicePort = audioServicePort,
       _sessionStore = sessionStore,
       _getTracksByIds = getTracksByIds,
       super(const PlayerIdle()) {
    // ── Incoming streams ──────────────────────────────────
    _positionSub = audioServicePort.positionStream.listen(
      _onPositionTick,
      onError: (e) => add(_AudioErrorOccurred(e.toString())),
    );
    _bufferedSub = audioServicePort.bufferedPositionStream.listen(
      (buf) => _progress.value = _progress.value.copyWith(buffered: buf),
    );
    _durationSub = audioServicePort.durationStream.listen(
      (dur) => add(_DurationUpdated(dur)),
    );
    _statusSub = audioServicePort.statusStream.listen(
      (status) => add(_StatusChanged(status)),
      onError: (e) => add(_AudioErrorOccurred(e.toString())),
    );
    _trackSub = audioServicePort.currentTrackStream.listen(
      (track) => add(_TrackChanged(track)),
    );
    _queueSub = audioServicePort.queueStream.listen(
      (queue) => add(_QueueChanged(queue)),
    );
    _volumeSub = audioServicePort.volumeStream.listen(
      (vol) => add(_VolumeUpdated(vol)),
    );
    _errorSub = audioServicePort.errorStream.listen(
      (f) => add(_AudioErrorOccurred(f.message)),
    );

    // ── Handler registration ───────────────────────────────────────
    on<PlayTrackRequested>(_onPlayTrackRequested, transformer: droppable());
    on<PauseRequested>(_onPauseRequested, transformer: droppable());
    on<ResumeRequested>(_onResumeRequested, transformer: droppable());
    // Sequential, not droppable: a second scrub released while the first
    // seek settles must still be applied.
    on<SeekRequested>(_onSeekRequested, transformer: sequential());
    on<SkipNextRequested>(_onSkipNextRequested, transformer: droppable());
    on<SkipPreviousRequested>(
      _onSkipPreviousRequested,
      transformer: droppable(),
    );
    on<ShuffleToggleRequested>(_onShuffleToggleRequested);
    on<RepeatModeChangeRequested>(_onRepeatModeChangeRequested);
    on<VolumeChangeRequested>(_onVolumeChangeRequested);
    on<SpeedChangeRequested>(_onSpeedChangeRequested);
    on<PlayerDismissed>(_onPlayerDismissed);
    on<RestorePlaybackSessionRequested>(
      _onRestorePlaybackSessionRequested,
      transformer: droppable(),
    );
    on<QueueSetRequested>(_onQueueSetRequested, transformer: droppable());
    on<QueueIndexRequested>(_onQueueIndexRequested, transformer: droppable());
    // One handler for every edit type: sequential() only orders events
    // within a single handler.
    on<QueueEditEvent>(_onQueueEdit, transformer: sequential());

    // Internal streams: always concurrent
    on<_DurationUpdated>(_onDurationUpdated, transformer: concurrent());
    on<_StatusChanged>(_onStatusChanged, transformer: concurrent());
    on<_TrackChanged>(_onTrackChanged, transformer: concurrent());
    on<_QueueChanged>(_onQueueChanged, transformer: concurrent());
    on<_VolumeUpdated>(_onVolumeUpdated, transformer: concurrent());
    on<_AudioErrorOccurred>(_onAudioError, transformer: concurrent());
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HANDLERS: user commands
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _onPlayTrackRequested(
    PlayTrackRequested event,
    Emitter<PlayerState> emit,
  ) async {
    unawaited(AppHaptics.lightImpact());

    _requestedTrackId = event.track.id;
    emit(PlayerLoading(event.track));

    if (event.contextQueue != null) {
      final result = await _setQueue(
        SetQueueParams(
          tracks: event.contextQueue!,
          startIndex: event.contextIndex ?? 0,
          shuffle: event.shuffle ? true : null,
        ),
      );
      if (result.isLeft()) {
        emit(
          PlayerError(
            message: result.fold((f) => f.message, (_) => ''),
            lastTrack: event.track,
          ),
        );
      }
    } else {
      final result = await _playTrack(PlayTrackParams(track: event.track));
      if (result.isLeft()) {
        emit(
          PlayerError(
            message: result.fold((f) => f.message, (_) => ''),
            lastTrack: event.track,
          ),
        );
      }
    }
    // The active state arrives through _onTrackChanged and _onStatusChanged
  }

  Future<void> _onPauseRequested(
    PauseRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    unawaited(AppHaptics.lightImpact());
    await _pause();
  }

  Future<void> _onResumeRequested(
    ResumeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    unawaited(AppHaptics.lightImpact());
    await _resume();
  }

  Future<void> _onSeekRequested(
    SeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    _isManualSeeking = true;
    try {
      // Optimistic update
      _setPosition(event.position);
      await _seek(SeekParams(position: event.position));
    } finally {
      // Short delay to ignore the last stale position events from the stream
      await Future<void>.delayed(const Duration(milliseconds: 150));
      _isManualSeeking = false;
    }
  }

  Future<void> _onSkipNextRequested(
    SkipNextRequested event,
    Emitter<PlayerState> emit,
  ) async {
    unawaited(AppHaptics.mediumImpact());
    await _skipNext();
  }

  Future<void> _onSkipPreviousRequested(
    SkipPreviousRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    unawaited(AppHaptics.mediumImpact());
    final current = state as PlayerActive;

    // Past 3 s, or on the first track, "previous" restarts the current one.
    if (_progress.value.position.inSeconds > 3 || !current.hasPrevious) {
      _isManualSeeking = true;
      try {
        _setPosition(Duration.zero);
        await _seek(SeekParams(position: Duration.zero));
      } finally {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        _isManualSeeking = false;
      }
    } else {
      await _skipPrevious();
    }
  }

  // ── Helpers de transition audio ──────────────────────────────────────────────

  Future<void> _onShuffleToggleRequested(
    ShuffleToggleRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    unawaited(AppHaptics.selectionClick());
    final current = state as PlayerActive;
    await _toggleShuffle(ToggleShuffleParams(enabled: !current.shuffleEnabled));
  }

  Future<void> _onRepeatModeChangeRequested(
    RepeatModeChangeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    unawaited(AppHaptics.selectionClick());
    await _setRepeatMode(SetRepeatModeParams(mode: event.mode));
  }

  Future<void> _onVolumeChangeRequested(
    VolumeChangeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    // Optimistic volume update in the UI
    if (state is PlayerActive) {
      emit((state as PlayerActive).copyWith(volume: event.volume));
    }
    await _setVolume(SetVolumeParams(volume: event.volume));
  }

  Future<void> _onSpeedChangeRequested(
    SpeedChangeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is PlayerActive) {
      final next = (state as PlayerActive).copyWith(speed: event.speed);
      emit(next);
      _persistSession(next);
    }
    await _setSpeed(SetSpeedParams(speed: event.speed));
  }

  Future<void> _onPlayerDismissed(
    PlayerDismissed event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioServicePort
        .stop(); // Actually stops the audio engine (e.g. swiped away while playing)
    await _clearPersistedSession();
    emit(const PlayerIdle());
  }

  Future<void> _onRestorePlaybackSessionRequested(
    RestorePlaybackSessionRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerIdle) return;

    final snapshot = _sessionStore.load();
    if (snapshot == null) return;

    final ids = {
      ...snapshot.originalTrackIds,
      ...snapshot.playbackTrackIds,
      snapshot.currentTrackId,
    }.toList(growable: false);
    final cachedTracks = (await _getTracksByIds(
      ids,
    )).fold((_) => null, (tracks) => tracks);
    // A failed read is not a lost session: keep it for the next launch.
    if (cachedTracks == null) return;
    if (cachedTracks.isEmpty) {
      await _sessionStore.clear();
      return;
    }

    final trackById = {for (final track in cachedTracks) track.id: track};
    final originalTracks = snapshot.originalTrackIds
        .map((id) => trackById[id])
        .whereType<Track>()
        .toList(growable: false);
    final playbackTracks = snapshot.playbackTrackIds
        .map((id) => trackById[id])
        .whereType<Track>()
        .toList(growable: false);

    final hasMissingOriginalTracks =
        originalTracks.isNotEmpty &&
        originalTracks.length != snapshot.originalTrackIds.length;
    final hasMissingPlaybackTracks =
        playbackTracks.length != snapshot.playbackTrackIds.length;

    if (playbackTracks.isEmpty ||
        hasMissingOriginalTracks ||
        hasMissingPlaybackTracks) {
      await _clearPersistedSession();
      return;
    }

    final restoredIndex = playbackTracks.indexWhere(
      (t) => t.id == snapshot.currentTrackId,
    );
    if (restoredIndex < 0) {
      await _clearPersistedSession();
      return;
    }
    final currentIndex =
        (restoredIndex >= 0 ? restoredIndex : snapshot.currentIndex).clamp(
          0,
          playbackTracks.length - 1,
        );
    final queue = Queue(
      originalTracks: List.unmodifiable(
        originalTracks.isEmpty ? playbackTracks : originalTracks,
      ),
      playbackTracks: List.unmodifiable(playbackTracks),
      currentIndex: currentIndex,
      shuffleEnabled: snapshot.shuffleEnabled,
      repeatMode: snapshot.repeatMode,
    );

    _restoringSnapshot = snapshot;
    emit(PlayerLoading(queue.currentTrack ?? playbackTracks[currentIndex]));

    final result = await _audioServicePort.restoreQueue(
      queue,
      position: Duration(milliseconds: snapshot.positionMs),
      play: event.play,
      volume: snapshot.volume,
      speed: snapshot.speed,
    );

    if (result.isLeft()) {
      _restoringSnapshot = null;
      await _clearPersistedSession();
    }
  }

  Future<void> _onQueueSetRequested(
    QueueSetRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.tracks.isEmpty) return;

    _requestedTrackId = event.tracks[event.startIndex].id;
    emit(PlayerLoading(event.tracks[event.startIndex]));
    await _setQueue(
      SetQueueParams(tracks: event.tracks, startIndex: event.startIndex),
    );
  }

  Future<void> _onQueueIndexRequested(
    QueueIndexRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final current = state;
    if (current is! PlayerActive) return;
    final queue = current.queue;
    if (event.index < 0 ||
        event.index >= queue.length ||
        event.index == queue.currentIndex) {
      return;
    }
    unawaited(AppHaptics.lightImpact());
    // No Loading state: the engine keeps the same sources, and _TrackChanged
    // moves the active state to the new index.
    final result = await _skipToIndex(SkipToIndexParams(index: event.index));
    if (result.isLeft()) {
      emit(
        PlayerError(
          message: result.fold((f) => f.message, (_) => ''),
          lastTrack: current.currentTrack,
          lastQueue: queue,
        ),
      );
    }
  }

  /// The last removal, when it did not happen: its undo inserts nothing.
  /// Only the last removal can be undone, so one is enough. Compared by
  /// identity: two removals of the same slot are different edits.
  TrackRemovedFromQueue? _failedRemoval;

  /// Whether the port's queue (the one edits apply to, and up to date:
  /// edits run one at a time) still has [trackId] at [index], in up next.
  /// The player may have reached the track while the edit was queued.
  bool _isAt(int index, String? trackId) {
    if (trackId == null) return true;
    final queue = _audioServicePort.currentQueue;
    if (queue == null) return false;
    final tracks = queue.playbackTracks;
    return index > queue.currentIndex &&
        index < tracks.length &&
        tracks[index].id == trackId;
  }

  Future<void> _onQueueEdit(
    QueueEditEvent event,
    Emitter<PlayerState> emit,
  ) async {
    switch (event) {
      case TrackAddedToQueue(:final undoing?)
          when identical(undoing, _failedRemoval):
        _failedRemoval = null;
        return;
      case TrackAddedToQueue(:final track, :final index):
        await _addToQueue(AddToQueueParams(track: track, index: index));
      case TrackRemovedFromQueue(:final index, :final trackId):
        _failedRemoval = event;
        if (!_isAt(index, trackId)) return;
        final result = await _removeFromQueue(
          RemoveFromQueueParams(index: index),
        );
        if (result.isRight()) _failedRemoval = null;
      case QueueItemMoved(:final oldIndex, :final newIndex, :final trackId):
        if (!_isAt(oldIndex, trackId)) return;
        await _moveQueueItem(
          MoveQueueItemParams(oldIndex: oldIndex, newIndex: newIndex),
        );
      case TrackQueuedNext(:final track):
        final queue = _audioServicePort.currentQueue;
        if (queue == null) {
          add(PlayTrackRequested(track));
          return;
        }
        await _addToQueue(
          AddToQueueParams(track: track, index: queue.currentIndex + 1),
        );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HANDLERS: incoming streams
  // ════════════════════════════════════════════════════════════════════════════

  /// Position ticks bypass the event queue entirely: no event, no emit.
  ///
  /// Ticks are only trusted while active: during loading they may still come
  /// from the outgoing source, and [_onStatusChanged] seeds the position from
  /// the engine snapshot when the new track becomes active.
  void _onPositionTick(Duration position) {
    if (isClosed || _isManualSeeking) return;
    final current = state;
    if (current is! PlayerActive) return;
    _setPosition(position);
    // Ticks can overtake a queued _TrackChanged: never persist the new
    // track's position under the previous track's id.
    if (_audioServicePort.currentTrack?.id != current.currentTrack.id) return;
    _persistPositionIfNeeded(current);
  }

  void _setPosition(Duration position) =>
      _progress.value = _progress.value.copyWith(position: position);

  void _onDurationUpdated(_DurationUpdated event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      final current = state as PlayerActive;
      final fallbackDuration = Duration(
        milliseconds: current.currentTrack.durationMs,
      );
      final next = current.copyWith(
        duration: event.duration == Duration.zero
            ? fallbackDuration
            : event.duration,
      );
      emit(next);
      _persistSession(next);
    }
  }

  void _onStatusChanged(_StatusChanged event, Emitter<PlayerState> emit) {
    switch (state) {
      case PlayerLoading(:final track):
        if (event.status == PlaybackStatus.playing ||
            event.status == PlaybackStatus.paused) {
          var queue = _audioServicePort.currentQueue ?? Queue.single(track);
          // Only realign when the queue names another track: looking the
          // loaded track up by id would pick the first copy of a track
          // queued more than once.
          if (queue.currentTrack?.id != track.id) {
            final loadedIndex = queue.playbackTracks.indexWhere(
              (t) => t.id == track.id,
            );
            if (loadedIndex >= 0) {
              queue = queue.copyWith(currentIndex: loadedIndex);
            }
          }
          final restored = _restoringSnapshot;
          final targetVolume = restored?.volume ?? 1.0;

          _setPosition(_audioServicePort.currentPosition);
          final next = PlayerActive(
            currentTrack: track,
            status: event.status,
            duration: _audioServicePort.currentDuration == Duration.zero
                ? Duration(milliseconds: track.durationMs)
                : _audioServicePort.currentDuration,
            queue: queue,
            shuffleEnabled: queue.shuffleEnabled,
            repeatMode: queue.repeatMode,
            volume: targetVolume,
            speed: restored?.speed ?? 1.0,
          );

          emit(next);

          _persistSession(next);
          _restoringSnapshot = null;
        }
      case PlayerActive():
        final current = state as PlayerActive;
        final next = current.copyWith(status: event.status);

        if (_shouldClearSessionAfterStop(next)) {
          // Instead of Idle (clearing player), we stay Active but reset position to 0
          // and ensure the status is "paused" for the UI.
          final resetState = next.copyWith(status: PlaybackStatus.paused);
          _setPosition(Duration.zero);
          emit(resetState);
          _persistSession(resetState);

          // Explicitly sync the audio engine to position 0
          unawaited(_audioServicePort.seekTo(Duration.zero));
        } else {
          emit(next);
          _persistSession(next);
        }
      case _:
        break;
    }
  }

  void _onTrackChanged(_TrackChanged event, Emitter<PlayerState> emit) {
    if (event.track == null) return;
    switch (state) {
      case PlayerLoading():
        final requested = _requestedTrackId;
        if (requested != null && event.track!.id != requested) return;
        emit(PlayerLoading(event.track!));
      case PlayerActive():
        final current = state as PlayerActive;
        // The port's queue says which entry plays. Looking the track up by
        // id would pick the first copy of a track queued more than once.
        // Track and queue are read together: the event may be a step behind.
        final queue = _audioServicePort.currentQueue ?? current.queue;
        final track = queue.currentTrack ?? event.track!;
        if (track.id != current.currentTrack.id) {
          _setPosition(Duration.zero);
        }
        final next = current.copyWith(
          currentTrack: track,
          duration: Duration(milliseconds: track.durationMs),
          queue: queue,
        );
        emit(next);
        _persistSession(next);
      case _:
        break;
    }
  }

  void _onQueueChanged(_QueueChanged event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      final current = state as PlayerActive;
      final next = current.copyWith(
        queue: event.queue,
        shuffleEnabled: event.queue.shuffleEnabled,
        repeatMode: event.queue.repeatMode,
      );
      emit(next);
      _persistSession(next);
    }
  }

  void _onVolumeUpdated(_VolumeUpdated event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      final next = (state as PlayerActive).copyWith(volume: event.volume);
      emit(next);
      _persistSession(next);
    }
  }

  void _onAudioError(_AudioErrorOccurred event, Emitter<PlayerState> emit) {
    // The raw engine message is for the log; the user gets the song title.
    appLogger.w('[PlayerBloc] audio error: ${event.message}');
    if (!_noticesController.isClosed) {
      _noticesController.add(
        TrackUnplayable(_audioServicePort.currentTrack?.title),
      );
    }
    // just_audio's maxSkipsOnError handles recovery: no timer, no state replace.
  }

  void _persistPositionIfNeeded(PlayerActive state) {
    final bucket = _progress.value.position.inSeconds ~/ 5;
    if (_lastPersistedPositionSecond == bucket) return;
    _lastPersistedPositionSecond = bucket;
    _persistSession(state);
  }

  bool _shouldClearSessionAfterStop(PlayerActive state) {
    // ProcessingState.completed (mapped to stopped) in just_audio signifies
    // the end of the entire playlist when repetition is off.
    if (state.status != PlaybackStatus.stopped) return false;
    if (state.queue.repeatMode != RepeatMode.off) return false;

    // We assume that if it's completed, it's the end, regardless of sub-second
    // precision issues with the last reported position.
    return true;
  }

  void _persistSession(PlayerActive state) {
    final maxDuration = state.duration.inMilliseconds == 0
        ? state.currentTrack.durationMs
        : state.duration.inMilliseconds;
    final positionMs = _progress.value.position.inMilliseconds.clamp(
      0,
      maxDuration,
    );
    unawaited(
      _sessionStore.save(
        PlaybackSessionSnapshot(
          currentTrackId: state.currentTrack.id,
          originalTrackIds: state.queue.originalTracks
              .map((t) => t.id)
              .toList(growable: false),
          playbackTrackIds: state.queue.playbackTracks
              .map((t) => t.id)
              .toList(growable: false),
          currentIndex: state.queue.currentIndex,
          positionMs: positionMs,
          wasPlaying: state.isPlaying,
          shuffleEnabled: state.queue.shuffleEnabled,
          repeatMode: state.queue.repeatMode,
          volume: state.volume,
          speed: state.speed,
        ),
      ),
    );
  }

  Future<void> _clearPersistedSession() async {
    _lastPersistedPositionSecond = null;
    _restoringSnapshot = null;
    await _sessionStore.clear();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  /// Keeps the progress clock aligned with the structural state, and drops
  /// the pending track request once loading is over (success or failure).
  @override
  void onChange(Change<PlayerState> change) {
    super.onChange(change);
    if (change.nextState is! PlayerLoading) _requestedTrackId = null;
    _progress.value = switch (change.nextState) {
      PlayerActive(:final duration) => _progress.value.copyWith(
        duration: duration,
      ),
      PlayerLoading(:final track) => PlaybackProgress.zero.copyWith(
        duration: Duration(milliseconds: track.durationMs),
      ),
      PlayerIdle() => PlaybackProgress.zero,
      PlayerError() => _progress.value,
    };
  }

  @override
  Future<void> close() async {
    await Future.wait([
      _positionSub.cancel(),
      _bufferedSub.cancel(),
      _durationSub.cancel(),
      _statusSub.cancel(),
      _trackSub.cancel(),
      _queueSub.cancel(),
      _volumeSub.cancel(),
      _errorSub.cancel(),
    ]);
    await _noticesController.close();
    // Events queued before close can still emit (and hit onChange) while
    // super.close() drains them, so the notifier must outlive it.
    await super.close();
    _progress.dispose();
  }
}
