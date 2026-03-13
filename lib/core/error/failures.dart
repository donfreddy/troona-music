import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Use subtypes to carry context without leaking exceptions to the UI.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Library ──────────────────────────────────────────────────────────────────

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Storage permission denied.']);
}

class ScanFailure extends Failure {
  const ScanFailure([super.message = 'Failed to scan media library.']);
}

class TrackNotFoundFailure extends Failure {
  final int trackId;
  const TrackNotFoundFailure(this.trackId)
    : super('Track #$trackId not found.');

  @override
  List<Object?> get props => [message, trackId];
}

// ── Player ────────────────────────────────────────────────────────────────────

class PlaybackFailure extends Failure {
  const PlaybackFailure([super.message = 'Playback error.']);
}

class QueueEmptyFailure extends Failure {
  const QueueEmptyFailure([super.message = 'Queue is empty.']);
}

// ── Storage ───────────────────────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error.']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed.']);
}
