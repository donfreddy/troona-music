import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Use subtypes to carry context without leaking exceptions to the UI.
/// [message] is for logs and problem reports only; screens show their own
/// localized text.
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

// ── Backup ────────────────────────────────────────────────────────────────────

/// The file is not a Troona backup, or it is damaged.
class BackupFormatFailure extends Failure {
  const BackupFormatFailure([super.message = 'Not a valid backup file.']);
}

/// The backup was made by a newer version of Troona.
class BackupTooNewFailure extends Failure {
  const BackupTooNewFailure(int version)
    : super('Backup version $version is newer than this app.');
}

// ── Updates ───────────────────────────────────────────────────────────────────

/// GitHub could not be reached, or gave no release this app can read.
class UpdateCheckFailure extends Failure {
  const UpdateCheckFailure([super.message = 'Update check failed.']);
}

// ── Other ─────────────────────────────────────────────────────────────────────

/// An error no layer anticipated. Keeps the original for the logs.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
