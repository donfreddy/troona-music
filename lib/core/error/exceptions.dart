/// Infrastructure-level exceptions (data layer only).
/// Never let these cross into the domain or presentation layers;
/// convert them to [Failure] inside repositories.
class PermissionException implements Exception {
  final String message;
  const PermissionException([this.message = 'Permission not granted.']);

  @override
  String toString() => 'PermissionException: $message';
}

class ScanException implements Exception {
  final String message;
  final Object? cause;
  const ScanException([this.message = 'Scan failed.', this.cause]);

  @override
  String toString() => 'ScanException: $message${cause != null ? ' | cause: $cause' : ''}';
}

class PlaybackException implements Exception {
  final String message;
  final Object? cause;
  const PlaybackException([this.message = 'Playback failed.', this.cause]);

  @override
  String toString() => 'PlaybackException: $message';
}

class DatabaseException implements Exception {
  final String message;
  final Object? cause;
  const DatabaseException([this.message = 'Database error.', this.cause]);

  @override
  String toString() => 'DatabaseException: $message';
}

class ArtworkException implements Exception {
  final String message;
  const ArtworkException([this.message = 'Artwork extraction failed.']);

  @override
  String toString() => 'ArtworkException: $message';
}
