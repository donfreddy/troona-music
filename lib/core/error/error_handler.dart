import 'dart:developer' as dev;

import 'exceptions.dart';
import 'failures.dart';

/// Translates raw exceptions (data layer) into typed [Failure]s (domain layer).
/// Call from repository implementations inside catch blocks.
abstract final class ErrorHandler {
  ErrorHandler._();

  static Failure handle(Object error, StackTrace stackTrace) {
    dev.log(
      '[ErrorHandler] ${error.runtimeType}: $error',
      stackTrace: stackTrace,
      level: 900, // WARNING
      name: 'troona.error',
    );

    return switch (error) {
      PermissionException() => const PermissionFailure(),
      ScanException() => const ScanFailure(),
      PlaybackException() => const PlaybackFailure(),
      DatabaseException() => const DatabaseFailure(),
      ArtworkException() => const CacheFailure('Artwork cache error.'),
      _ => CacheFailure('Unexpected error: $error'),
    };
  }
}
