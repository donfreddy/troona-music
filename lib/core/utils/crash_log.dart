import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// File-based ring-buffer log of warnings and errors, read back by the
/// problem report.
///
/// Writes are asynchronous and queued, so a burst of warnings never blocks
/// the UI; the file is trimmed back to [_maxLines] once that many lines have
/// been appended, not on every write. Stays silent on all write failures so
/// it never causes a secondary crash.
final class CrashLog {
  CrashLog._();

  static File? _logFile;
  static const _maxLines = 500;
  static Future<void> _pending = Future.value();
  static int _appendedSinceTrim = 0;

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
    final String entry;
    try {
      final timestamp = DateTime.now().toIso8601String();
      entry = '[$timestamp] $error\n${stack ?? ''}\n---\n';
    } catch (_) {
      return; // A throwing toString must not escape the logger.
    }
    _pending = _pending.then((_) => _append(file, entry)).catchError((_) {});
  }

  /// Returns the log file to share with the user, or null if unavailable.
  static File? get logFile => _logFile;

  /// Reads up to [limit] recent lines from the crash log.
  static Future<List<String>> readRecentLogs({int limit = 50}) async {
    final file = _logFile;
    if (file == null) return [];
    await _pending;
    try {
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final lines = content
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.length <= limit) return lines;
      return lines.sublist(lines.length - limit);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _append(File file, String entry) async {
    await file.writeAsString(entry, mode: FileMode.append);
    _appendedSinceTrim += '\n'.allMatches(entry).length;
    if (_appendedSinceTrim < _maxLines) return;
    _appendedSinceTrim = 0;
    final lines = (await file.readAsString()).split('\n');
    if (lines.length > _maxLines) {
      await file.writeAsString(
        lines.sublist(lines.length - _maxLines).join('\n'),
      );
    }
  }

  /// Points the log at [file] and resets its state.
  @visibleForTesting
  static void useFile(File? file) {
    _logFile = file;
    _pending = Future.value();
    _appendedSinceTrim = 0;
  }

  /// Completes once every queued write has landed.
  @visibleForTesting
  static Future<void> flush() => _pending;
}
