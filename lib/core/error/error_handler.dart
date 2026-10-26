import 'package:troona/core/utils/app_logger.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Translates raw exceptions (data layer) into typed [Failure]s (domain layer).
///
/// Call [ErrorHandler.handle] from repository `catch` blocks. The method logs
/// the error with a WARNING level and returns the appropriate [Failure] subtype
/// so the caller can propagate it via `Either<Failure, T>`.
///
/// ```dart
/// } catch (e, st) {
///   return Left(ErrorHandler.handle(e, st));
/// }
/// ```
abstract final class ErrorHandler {
  ErrorHandler._();

  /// Maps [error] to a typed [Failure] and logs the event.
  ///
  /// Unknown errors become an [UnexpectedFailure] carrying the raw error for
  /// the logs; the UI never displays it.
  static Failure handle(Object error, StackTrace stackTrace) {
    appLogger.w(
      '[ErrorHandler] ${error.runtimeType}: $error',
      error: error,
      stackTrace: stackTrace,
    );

    return switch (error) {
      PermissionException() => const PermissionFailure(),
      ScanException() => const ScanFailure(),
      PlaybackException() => const PlaybackFailure(),
      DatabaseException() => const DatabaseFailure(),
      ArtworkException() => const CacheFailure('Artwork cache error.'),
      _ => UnexpectedFailure('${error.runtimeType}: $error'),
    };
  }
}
