import 'package:logger/logger.dart';

/// Application-wide structured logger powered by the [logger] package.
///
/// Exposes a single [appLogger] constant that can be imported anywhere:
///
/// ```dart
/// import 'package:troona/core/utils/app_logger.dart';
///
/// appLogger.d('Scan started');
/// appLogger.w('Permission denied');
/// appLogger.e('Playback failed', error: e, stackTrace: st);
/// ```
///
/// **Production note**: swap [PrettyPrinter] for a remote-logging output
/// (e.g. Firebase Crashlytics) and raise the minimum level to [Level.warning]
/// before shipping to avoid verbose output in release builds.
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
