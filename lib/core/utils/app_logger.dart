import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application-wide structured logger, configured per build flavor.
///
/// **Usage** — import once, call anywhere:
/// ```dart
/// import 'package:troona/core/utils/app_logger.dart';
///
/// appLogger.d('Scan started');                         // debug detail
/// appLogger.i('Track loaded: ${track.title}');         // informational
/// appLogger.w('Permission denied');                    // recoverable issue
/// appLogger.e('Playback failed', error: e, stackTrace: st); // error + stack
/// ```
///
/// **Log levels by build flavor**:
/// | Flavor   | Minimum level | Output                    |
/// |----------|---------------|---------------------------|
/// | Debug    | trace         | PrettyPrinter (coloured)  |
/// | Profile  | warning       | SimplePrinter (no colour) |
/// | Release  | off           | silent — zero overhead    |
///
/// **Adding crash reporting**: in release mode, replace `Logger(level: off)`
/// with a `Logger(output: CrashlyticsOutput())` that forwards warning/error
/// events to Firebase Crashlytics or Sentry. The `LogOutput` interface takes
/// a single `output(LogEvent)` method — no other changes required.
final Logger appLogger = _buildLogger();

Logger _buildLogger() {
  if (kReleaseMode) {
    // Completely silent — no string formatting, no I/O, zero overhead.
    // Swap LogOutput here when crash reporting is wired up.
    return Logger(level: Level.off);
  }

  if (kProfileMode) {
    // Warnings and above only during performance profiling runs.
    // SimplePrinter avoids ANSI colour codes that distort profiler output.
    return Logger(
      level: Level.warning,
      printer: SimplePrinter(colors: false, printTime: true),
    );
  }

  // Full verbose output in debug builds.
  return Logger(
    level: Level.trace,
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
}
