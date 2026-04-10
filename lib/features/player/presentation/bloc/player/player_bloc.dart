import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/use_cases/play_track_use_case.dart';
import 'package:troona/features/player/domain/use_cases/player_use_cases.dart';

part 'player_event.dart';

part 'player_state.dart';

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
  final AudioServicePort _audioServicePort;
  final PlaybackSessionStore _sessionStore;
  final IsarLibraryDataSource _libraryCache;

  // ── Stream subscriptions ────────────────────────────────────────────────────
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _bufferedSub;
  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<PlaybackStatus> _statusSub;
  late final StreamSubscription<dynamic> _trackSub;
  late final StreamSubscription<Queue> _queueSub;
  late final StreamSubscription<double> _volumeSub;
  int? _lastPersistedPositionSecond;
  PlaybackSessionSnapshot? _restoringSnapshot;
  Timer? _recoveryTimer;
  bool _isManualSeeking = false;

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
    required AudioServicePort audioServicePort,
    required PlaybackSessionStore sessionStore,
    required IsarLibraryDataSource libraryCache,
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
       _audioServicePort = audioServicePort,
       _sessionStore = sessionStore,
       _libraryCache = libraryCache,
       super(const PlayerIdle()) {
    // ── Branchement des streams entrants ──────────────────────────────────
    _positionSub = audioServicePort.positionStream.listen(
      (pos) => add(_PositionUpdated(pos)),
      onError: (e) => add(_AudioErrorOccurred(e.toString())),
    );
    _bufferedSub = audioServicePort.bufferedPositionStream.listen(
      (buf) => add(_BufferedUpdated(buf)),
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

    // ── Enregistrement des handlers ───────────────────────────────────────
    on<PlayTrackRequested>(_onPlayTrackRequested, transformer: droppable());
    on<PauseRequested>(_onPauseRequested, transformer: droppable());
    on<ResumeRequested>(_onResumeRequested, transformer: droppable());
    on<SeekRequested>(_onSeekRequested, transformer: droppable());
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
    on<TrackAddedToQueue>(_onTrackAddedToQueue);
    on<TrackRemovedFromQueue>(_onTrackRemovedFromQueue);
    on<QueueItemMoved>(_onQueueItemMoved);

    // Streams internes — toujours concurrent
    on<_PositionUpdated>(_onPositionUpdated, transformer: concurrent());
    on<_BufferedUpdated>(_onBufferedUpdated, transformer: concurrent());
    on<_DurationUpdated>(_onDurationUpdated, transformer: concurrent());
    on<_StatusChanged>(_onStatusChanged, transformer: concurrent());
    on<_TrackChanged>(_onTrackChanged, transformer: concurrent());
    on<_QueueChanged>(_onQueueChanged, transformer: concurrent());
    on<_VolumeUpdated>(_onVolumeUpdated, transformer: concurrent());
    on<_AudioErrorOccurred>(_onAudioError, transformer: concurrent());
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HANDLERS — commandes utilisateur
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _onPlayTrackRequested(
    PlayTrackRequested event,
    Emitter<PlayerState> emit,
  ) async {
    unawaited(AppHaptics.lightImpact());

    emit(PlayerLoading(event.track));

    if (event.contextQueue != null) {
      final result = await _setQueue(
        SetQueueParams(
          tracks: event.contextQueue!,
          startIndex: event.contextIndex ?? 0,
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
    // État Active arrive via _onTrackChanged + _onStatusChanged
  }

  Future<void> _onPauseRequested(
    PauseRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    unawaited(AppHaptics.lightImpact());
    unawaited(_pause(fadeDuration: 150.ms));
    //await _pause(fadeDuration: const Duration(milliseconds: 150));
  }

  Future<void> _onResumeRequested(
    ResumeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    unawaited(AppHaptics.lightImpact());
    unawaited(_resume(fadeDuration: 250.ms));
    //await _resume(fadeDuration: const Duration(milliseconds: 250));
  }

  Future<void> _onSeekRequested(
    SeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    _isManualSeeking = true;
    try {
      // Mise à jour optimiste
      emit((state as PlayerActive).copyWith(position: event.position));
      await _seek(SeekParams(position: event.position));
    } finally {
      // Petit délai pour ignorer les derniers évènements de position obsolètes du stream
      await Future.delayed(const Duration(milliseconds: 150));
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

    if (current.position.inSeconds > 3) {
      _isManualSeeking = true;
      try {
        emit(current.copyWith(position: Duration.zero));
        await _seek(SeekParams(position: Duration.zero));
      } finally {
        await Future.delayed(const Duration(milliseconds: 150));
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
    // Mise à jour optimiste du volume dans l'UI
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
    final cachedTracks = await _libraryCache.getTracksByIds(ids);
    if (cachedTracks.isEmpty) {
      await _sessionStore.clear();
      return;
    }

    final trackById = {
      for (final model in cachedTracks) model.deviceId: model.toEntity(),
    };
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
      play: false,
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

    emit(PlayerLoading(event.tracks[event.startIndex]));
    await _setQueue(
      SetQueueParams(tracks: event.tracks, startIndex: event.startIndex),
    );
  }

  Future<void> _onTrackAddedToQueue(
    TrackAddedToQueue event,
    Emitter<PlayerState> emit,
  ) async => _addToQueue(AddToQueueParams(track: event.track));

  Future<void> _onTrackRemovedFromQueue(
    TrackRemovedFromQueue event,
    Emitter<PlayerState> emit,
  ) async => _removeFromQueue(RemoveFromQueueParams(index: event.index));

  Future<void> _onQueueItemMoved(
    QueueItemMoved event,
    Emitter<PlayerState> emit,
  ) async => _moveQueueItem(
    MoveQueueItemParams(oldIndex: event.oldIndex, newIndex: event.newIndex),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // HANDLERS — streams entrants
  // ════════════════════════════════════════════════════════════════════════════

  void _onPositionUpdated(_PositionUpdated event, Emitter<PlayerState> emit) {
    if (state is PlayerActive && !_isManualSeeking) {
      final next = (state as PlayerActive).copyWith(position: event.position);
      emit(next);
      _persistPositionIfNeeded(next);
    }
  }

  void _onBufferedUpdated(_BufferedUpdated event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      emit((state as PlayerActive).copyWith(buffered: event.buffered));
    }
  }

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
          final queue = _audioServicePort.currentQueue ?? Queue.single(track);
          final restored = _restoringSnapshot;
          final targetVolume = restored?.volume ?? 1.0;

          final next = PlayerActive(
            currentTrack: track,
            status: event.status,
            position: _audioServicePort.currentPosition,
            buffered: Duration.zero,
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
          // Au lieu de Idle, on reste en Active mais on reset la position à 0
          // et on s'assure que le statut est "paused" pour l'UI.
          final resetState = next.copyWith(
            status: PlaybackStatus.paused,
            position: Duration.zero,
          );
          emit(resetState);
          _persistSession(resetState);
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
        emit(PlayerLoading(event.track!));
      case PlayerActive():
        final current = state as PlayerActive;
        final trackIndex = current.queue.playbackTracks.indexWhere(
          (t) => t.id == event.track!.id,
        );
        final next = current.copyWith(
          currentTrack: event.track,
          position: trackIndex >= 0 && trackIndex != current.queue.currentIndex
              ? Duration.zero
              : current.position,
          duration: Duration(milliseconds: event.track!.durationMs),
          queue: trackIndex >= 0
              ? current.queue.copyWith(currentIndex: trackIndex)
              : current.queue,
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
    final currentState = state;
    emit(
      PlayerError(
        message: event.message,
        lastTrack: switch (currentState) {
          PlayerActive(:final currentTrack) => currentTrack,
          PlayerLoading(:final track) => track,
          _ => null,
        },
        lastQueue: currentState is PlayerActive ? currentState.queue : null,
      ),
    );

    // Smart Recovery: if we were playing or trying to play, try to skip to next
    if (currentState is PlayerActive && currentState.queue.hasNext) {
      _recoveryTimer?.cancel();
      _recoveryTimer = Timer(const Duration(seconds: 2), () {
        if (!isClosed) add(const SkipNextRequested());
      });
    }
  }

  void _persistPositionIfNeeded(PlayerActive state) {
    final second = state.position.inSeconds;
    if (_lastPersistedPositionSecond == second) return;
    _lastPersistedPositionSecond = second;
    _persistSession(state);
  }

  bool _shouldClearSessionAfterStop(PlayerActive state) {
    if (state.status != PlaybackStatus.stopped) return false;
    if (state.queue.repeatMode != RepeatMode.off) return false;
    if (state.queue.currentIndex != state.queue.playbackTracks.length - 1) {
      return false;
    }
    final durationMs = state.duration.inMilliseconds == 0
        ? state.currentTrack.durationMs
        : state.duration.inMilliseconds;
    return durationMs > 0 && state.position.inMilliseconds >= durationMs - 1500;
  }

  void _persistSession(PlayerActive state) {
    final maxDuration = state.duration.inMilliseconds == 0
        ? state.currentTrack.durationMs
        : state.duration.inMilliseconds;
    final positionMs = state.position.inMilliseconds.clamp(0, maxDuration);
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

  @override
  Future<void> close() async {
    _recoveryTimer?.cancel();
    await Future.wait([
      _positionSub.cancel(),
      _bufferedSub.cancel(),
      _durationSub.cancel(),
      _statusSub.cancel(),
      _trackSub.cancel(),
      _queueSub.cancel(),
      _volumeSub.cancel(),
    ]);
    return super.close();
  }
}
