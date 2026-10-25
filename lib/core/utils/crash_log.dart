import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File-based ring-buffer crash logger for beta builds.
///
/// Writes warnings and errors to a plain-text file in the app support
/// directory. Stays silent on all write failures so it never causes a
/// secondary crash.
final class CrashLog {
  CrashLog._();

  static File? _logFile;
  static const _maxLines = 500;

  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}/crash_log.txt');
      if (!_logFile!.existsSync()) {
        await _logFile!.create(recursive: true);
      }
    } catch (_) {
      _logFile = null;
    }
  }

  static void record(Object error, StackTrace? stack) {
    final file = _logFile;
    if (file == null) return;
    try {
      final timestamp = DateTime.now().toIso8601String();
      final entry = '[$timestamp] $error\n${stack ?? ''}\n---\n';
      _trimAndAppend(file, entry);
    } catch (_) {}
  }

  /// Returns the log file to share with the user, or null if unavailable.
  static File? get logFile => _logFile;

  static void _trimAndAppend(File file, String entry) {
    try {
      final existing = file.existsSync() ? file.readAsStringSync() : '';
      final lines = existing.split('\n');
      final trimmed = lines.length > _maxLines
          ? lines.sublist(lines.length - _maxLines).join('\n')
          : existing;
      if (trimmed != existing) {
        file.writeAsStringSync(trimmed);
      }
      file.writeAsStringSync(entry, mode: FileMode.append);
    } catch (_) {}
  }
}
