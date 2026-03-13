// Regroupe les use cases simples (1 seul paramètre ou aucun).
// Les use cases complexes ont leur propre fichier.

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/domain/repositories/player_repository.dart';

// ── Pause ────────────────────────────────────────────────────────────────────

@lazySingleton
class PauseUseCase {
  final PlayerRepository _repo;
  const PauseUseCase(this._repo);
  Future<Either<Failure, Unit>> call() => _repo.pause();
}

// ── Resume ───────────────────────────────────────────────────────────────────

@lazySingleton
class ResumeUseCase {
  final PlayerRepository _repo;
  const ResumeUseCase(this._repo);
  Future<Either<Failure, Unit>> call() => _repo.resume();
}

// ── Seek ─────────────────────────────────────────────────────────────────────

class SeekParams {
  final Duration position;
  const SeekParams({required this.position});
}

@lazySingleton
class SeekUseCase {
  final PlayerRepository _repo;
  const SeekUseCase(this._repo);
  Future<Either<Failure, Unit>> call(SeekParams params) => _repo.seekTo(params.position);
}

// ── Skip ─────────────────────────────────────────────────────────────────────

@lazySingleton
class SkipNextUseCase {
  final PlayerRepository _repo;
  const SkipNextUseCase(this._repo);
  Future<Either<Failure, Unit>> call() => _repo.skipToNext();
}

@lazySingleton
class SkipPreviousUseCase {
  final PlayerRepository _repo;
  const SkipPreviousUseCase(this._repo);
  Future<Either<Failure, Unit>> call() => _repo.skipToPrevious();
}

// ── Queue ────────────────────────────────────────────────────────────────────

class SetQueueParams {
  final List<Track> tracks;
  final int startIndex;
  const SetQueueParams({required this.tracks, this.startIndex = 0});
}

@lazySingleton
class SetQueueUseCase {
  final PlayerRepository _repo;
  const SetQueueUseCase(this._repo);
  Future<Either<Failure, Unit>> call(SetQueueParams params) =>
      _repo.setQueue(params.tracks, startIndex: params.startIndex);
}

class AddToQueueParams {
  final Track track;
  const AddToQueueParams({required this.track});
}

@lazySingleton
class AddToQueueUseCase {
  final PlayerRepository _repo;
  const AddToQueueUseCase(this._repo);
  Future<Either<Failure, Unit>> call(AddToQueueParams params) => _repo.addToQueue(params.track);
}

class RemoveFromQueueParams {
  final int index;
  const RemoveFromQueueParams({required this.index});
}

@lazySingleton
class RemoveFromQueueUseCase {
  final PlayerRepository _repo;
  const RemoveFromQueueUseCase(this._repo);
  Future<Either<Failure, Unit>> call(RemoveFromQueueParams params) => _repo.removeFromQueue(params.index);
}

class MoveQueueItemParams {
  final int oldIndex;
  final int newIndex;
  const MoveQueueItemParams({required this.oldIndex, required this.newIndex});
}

@lazySingleton
class MoveQueueItemUseCase {
  final PlayerRepository _repo;
  const MoveQueueItemUseCase(this._repo);
  Future<Either<Failure, Unit>> call(MoveQueueItemParams params) =>
      _repo.moveQueueItem(params.oldIndex, params.newIndex);
}

// ── Shuffle ───────────────────────────────────────────────────────────────────

class ToggleShuffleParams {
  final bool enabled;
  const ToggleShuffleParams({required this.enabled});
}

@lazySingleton
class ToggleShuffleUseCase {
  final PlayerRepository _repo;
  const ToggleShuffleUseCase(this._repo);
  Future<Either<Failure, Unit>> call(ToggleShuffleParams params) => _repo.setShuffleEnabled(params.enabled);
}

// ── Repeat mode ───────────────────────────────────────────────────────────────

class SetRepeatModeParams {
  final RepeatMode mode;
  const SetRepeatModeParams({required this.mode});
}

@lazySingleton
class SetRepeatModeUseCase {
  final PlayerRepository _repo;
  const SetRepeatModeUseCase(this._repo);
  Future<Either<Failure, Unit>> call(SetRepeatModeParams params) => _repo.setRepeatMode(params.mode);
}

// ── Volume ────────────────────────────────────────────────────────────────────

class SetVolumeParams {
  final double volume; // 0.0 – 1.0
  const SetVolumeParams({required this.volume}) : assert(volume >= 0.0 && volume <= 1.0);
}

@lazySingleton
class SetVolumeUseCase {
  final PlayerRepository _repo;
  const SetVolumeUseCase(this._repo);
  Future<Either<Failure, Unit>> call(SetVolumeParams params) => _repo.setVolume(params.volume);
}

// ── Speed ─────────────────────────────────────────────────────────────────────

class SetSpeedParams {
  final double speed; // 0.5 – 2.0
  const SetSpeedParams({required this.speed});
}

@lazySingleton
class SetSpeedUseCase {
  final PlayerRepository _repo;
  const SetSpeedUseCase(this._repo);
  Future<Either<Failure, Unit>> call(SetSpeedParams params) => _repo.setSpeed(params.speed);
}
