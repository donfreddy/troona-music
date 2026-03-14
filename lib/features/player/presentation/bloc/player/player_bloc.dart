import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/features/library/domain/entities/track.dart';
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

  // ── Stream subscriptions ────────────────────────────────────────────────────
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _bufferedSub;
  late final StreamSubscription<Duration> _durationSub;
  late final StreamSubscription<PlaybackStatus> _statusSub;
  late final StreamSubscription<dynamic> _trackSub;
  late final StreamSubscription<Queue> _queueSub;
  late final StreamSubscription<double> _volumeSub;

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
    await _pause();
  }

  Future<void> _onResumeRequested(
    ResumeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    await _resume();
  }

  Future<void> _onSeekRequested(
    SeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    // Mise à jour optimiste
    emit((state as PlayerActive).copyWith(position: event.position));
    await _seek(SeekParams(position: event.position));
  }

  Future<void> _onSkipNextRequested(
    SkipNextRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final current = state;
    if (current is PlayerActive) {
      final next = current.queue.nextTrack;
      if (next != null) emit(PlayerLoading(next));
    }
    await _skipNext();
  }

  Future<void> _onSkipPreviousRequested(
    SkipPreviousRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    final current = state as PlayerActive;
    // Convention Apple : < 3s → track précédent, sinon → seek(0)
    if (current.position.inSeconds > 3) {
      emit(current.copyWith(position: Duration.zero));
      await _seek(SeekParams(position: Duration.zero));
    } else {
      await _skipPrevious();
    }
  }

  Future<void> _onShuffleToggleRequested(
    ShuffleToggleRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is! PlayerActive) return;
    final current = state as PlayerActive;
    await _toggleShuffle(ToggleShuffleParams(enabled: !current.shuffleEnabled));
  }

  Future<void> _onRepeatModeChangeRequested(
    RepeatModeChangeRequested event,
    Emitter<PlayerState> emit,
  ) async => _setRepeatMode(SetRepeatModeParams(mode: event.mode));

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
      emit((state as PlayerActive).copyWith(speed: event.speed));
    }
    await _setSpeed(SetSpeedParams(speed: event.speed));
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
    if (state is PlayerActive) {
      emit((state as PlayerActive).copyWith(position: event.position));
    }
  }

  void _onBufferedUpdated(_BufferedUpdated event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      emit((state as PlayerActive).copyWith(buffered: event.buffered));
    }
  }

  void _onDurationUpdated(_DurationUpdated event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      emit((state as PlayerActive).copyWith(duration: event.duration));
    }
  }

  void _onStatusChanged(_StatusChanged event, Emitter<PlayerState> emit) {
    switch (state) {
      case PlayerLoading(:final track):
        if (event.status == PlaybackStatus.playing ||
            event.status == PlaybackStatus.paused) {
          emit(
            PlayerActive(
              currentTrack: track,
              status: event.status,
              position: Duration.zero,
              buffered: Duration.zero,
              duration: Duration.zero,
              queue: Queue.single(track),
              shuffleEnabled: false,
              repeatMode: RepeatMode.off,
            ),
          );
        }
      case PlayerActive():
        emit((state as PlayerActive).copyWith(status: event.status));
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
        emit((state as PlayerActive).copyWith(currentTrack: event.track));
      case _:
        break;
    }
  }

  void _onQueueChanged(_QueueChanged event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      final current = state as PlayerActive;
      emit(
        current.copyWith(
          queue: event.queue,
          shuffleEnabled: event.queue.shuffleEnabled,
          repeatMode: event.queue.repeatMode,
        ),
      );
    }
  }

  void _onVolumeUpdated(_VolumeUpdated event, Emitter<PlayerState> emit) {
    if (state is PlayerActive) {
      emit((state as PlayerActive).copyWith(volume: event.volume));
    }
  }

  void _onAudioError(_AudioErrorOccurred event, Emitter<PlayerState> emit) {
    emit(
      PlayerError(
        message: event.message,
        lastTrack: switch (state) {
          PlayerActive(:final currentTrack) => currentTrack,
          PlayerLoading(:final track) => track,
          _ => null,
        },
        lastQueue: state is PlayerActive ? (state as PlayerActive).queue : null,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

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
    ]);
    return super.close();
  }

}
