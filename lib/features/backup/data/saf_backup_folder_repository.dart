import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/backup/data/backup_codec.dart';
import 'package:troona/features/backup/data/backup_file_name.dart';
import 'package:troona/features/backup/data/backup_files.dart';
import 'package:troona/features/backup/data/backup_summary_json.dart';
import 'package:troona/features/backup/data/platform_backup_folder.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_folder_repository.dart';

/// [BackupFolderRepository] over a folder the user picked through the
/// system (Android's Storage Access Framework).
///
/// The folder's address and the summaries of its backups are kept in
/// [SharedPreferences], never in a backup: they belong to this phone.
final class SafBackupFolderRepository implements BackupFolderRepository {
  final BackupFolderPlatform _platform;
  final SharedPreferences _prefs;

  /// Files on their way to or from the folder, deleted once moved.
  final Directory _workDir;

  /// Copies to share, deleted with the other exports.
  final Directory _exportDir;

  /// False where there is no folder to pick (iOS).
  final bool _supported;

  /// The build's tag in its automatic backups' names; null for the
  /// release (see [BackupFileName]).
  final String? _tag;

  static const uriKey = 'backup.folder.uri';
  static const nameKey = 'backup.folder.name';
  static const summariesKey = 'backup.folder.summaries';

  SafBackupFolderRepository({
    required BackupFolderPlatform platform,
    required SharedPreferences prefs,
    required Directory workDir,
    required Directory exportDir,
    required bool supported,
    String? tag,
  }) : _tag = tag,
       _platform = platform,
       _prefs = prefs,
       _workDir = workDir,
       _exportDir = exportDir,
       _supported = supported;

  String? get _uri => _prefs.getString(uriKey);

  @override
  Future<BackupFolderState> state() async {
    if (!_supported) return const BackupFolderUnsupported();
    final uri = _uri;
    if (uri == null) return const NoBackupFolder();
    final name = _prefs.getString(nameKey) ?? '';
    try {
      final status = await _platform.status(uri);
      final now = status?['name'];
      if (now is! String) return BackupFolderLost(name);
      // Renamed since it was picked.
      if (now != name) await _prefs.setString(nameKey, now);
      return BackupFolderReady(BackupFolder(uri: uri, name: now));
    } on MissingPluginException {
      return const BackupFolderUnsupported();
    } catch (e) {
      appLogger.w('Backup folder not checked: ${e.runtimeType}');
      return BackupFolderLost(name);
    }
  }

  @override
  Future<Either<Failure, BackupFolder?>> pick() => _guard(() async {
    final picked = await _platform.pick();
    final uri = picked?['uri'];
    if (uri is! String) return null;
    final name = picked?['name'];
    final folder = BackupFolder(uri: uri, name: name is String ? name : '');
    final before = _uri;
    if (before != null && before != uri) {
      try {
        await _platform.release(before);
      } catch (e) {
        appLogger.w('Old backup folder not released: ${e.runtimeType}');
      }
    }
    if (before != uri) await _prefs.remove(summariesKey);
    await _prefs.setString(uriKey, uri);
    await _prefs.setString(nameKey, folder.name);
    return folder;
  });

  @override
  Future<Either<Failure, List<StoredBackup>>> list() => _inFolder((uri) async {
    final files = await _platform.list(uri);
    final backups = [for (final file in files) ?_storedOf(file)]
      ..sort(_newestFirst);
    // Summaries of files gone from the folder are forgotten.
    final summaries = _summaries();
    final names = {for (final b in backups) b.name};
    if (summaries.keys.any((name) => !names.contains(name))) {
      summaries.removeWhere((name, _) => !names.contains(name));
      await _saveSummaries(summaries);
    }
    return backups;
  });

  @override
  Future<Either<Failure, StoredBackup>> save(
    Backup backup, {
    required bool auto,
  }) => _inFolder((uri) async {
    final name = BackupFileName.of(backup.createdAt, auto: auto, tag: _tag);
    final local = await _workFile(name);
    try {
      await BackupFiles.write(backup, local);
      final written = await _platform.write(uri, name, local.path);
      final stored =
          _storedOf(written) ??
          StoredBackup(
            id: written['id'] as String? ?? '',
            name: written['name'] as String? ?? name,
            createdAt: backup.createdAt,
            auto: auto,
            size: written['size'] as int?,
          );
      await _remember(stored, BackupSummary.of(backup));
      return stored;
    } finally {
      await _deleteQuietly(local);
    }
  });

  @override
  Future<Either<Failure, Backup>> read(StoredBackup stored) async {
    // Not copied at all: any file can carry a backup's name.
    if ((stored.size ?? 0) > BackupCodec.maxBytes) {
      return left(const BackupFormatFailure('File too large'));
    }
    final copied = await _inFolder((_) async {
      final local = await _workFile(stored.name);
      await _platform.read(
        stored.id,
        local.path,
        maxBytes: BackupCodec.maxBytes,
      );
      return local;
    });
    return copied.fold((f) async => left(f), (local) async {
      try {
        final read = await BackupFiles.read(local.path);
        if (read case Right(:final value)) {
          await _remember(stored, BackupSummary.of(value));
        }
        return read;
      } finally {
        await _deleteQuietly(local);
      }
    });
  }

  @override
  BackupSummary? summaryOf(StoredBackup stored) {
    final entry = _summaries()[stored.name];
    if (entry is! Map<String, Object?>) return null;
    // Another file of the same name (overwritten by hand): counted again.
    if (stored.size != null && entry['size'] != stored.size) return null;
    return BackupSummaryJson.decode(entry['summary']);
  }

  @override
  Future<Either<Failure, String>> copyToShare(StoredBackup stored) =>
      _inFolder((_) async {
        if (await _exportDir.exists()) await _exportDir.delete(recursive: true);
        await _exportDir.create(recursive: true);
        final path = '${_exportDir.path}/${stored.name}';
        await _platform.read(stored.id, path, maxBytes: BackupCodec.maxBytes);
        return path;
      });

  @override
  Future<Either<Failure, Unit>> delete(StoredBackup stored) =>
      _inFolder((_) async {
        await _platform.delete(stored.id);
        final summaries = _summaries();
        if (summaries.remove(stored.name) != null) {
          await _saveSummaries(summaries);
        }
        return unit;
      });

  StoredBackup? _storedOf(Map<String, Object?> file) {
    final id = file['id'];
    final name = file['name'];
    if (id is! String || name is! String) return null;
    final parsed = BackupFileName.parse(name);
    if (parsed == null) return null;
    final size = file['size'];
    return StoredBackup(
      id: id,
      name: name,
      createdAt: parsed.createdAt,
      auto: parsed.auto,
      mine: !parsed.auto || parsed.tag == _tag,
      size: size is int ? size : null,
    );
  }

  static int _newestFirst(StoredBackup a, StoredBackup b) {
    final byDate = b.createdAt.compareTo(a.createdAt);
    return byDate != 0 ? byDate : b.name.compareTo(a.name);
  }

  Map<String, Object?> _summaries() {
    final raw = _prefs.getString(summariesKey);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?> ? json : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _saveSummaries(Map<String, Object?> summaries) =>
      _prefs.setString(summariesKey, jsonEncode(summaries));

  Future<void> _remember(StoredBackup stored, BackupSummary summary) async {
    final summaries = _summaries()
      ..[stored.name] = {
        'size': stored.size,
        'summary': BackupSummaryJson.encode(summary),
      };
    await _saveSummaries(summaries);
  }

  /// A fresh file in the work folder, emptied first: one task runs at a
  /// time, so anything there was left by an app killed mid-way, and holds
  /// the listening history in clear.
  Future<File> _workFile(String name) async {
    try {
      if (await _workDir.exists()) await _workDir.delete(recursive: true);
    } catch (e) {
      appLogger.w('Backup work folder not emptied: ${e.runtimeType}');
    }
    await _workDir.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return File('${_workDir.path}/$stamp-$name');
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      appLogger.w('Backup work file not deleted: ${e.runtimeType}');
    }
  }

  /// Runs [work] on the chosen folder: [BackupFolderLostFailure] without
  /// one, or once it can no longer be reached.
  Future<Either<Failure, T>> _inFolder<T>(Future<T> Function(String uri) work) {
    final uri = _uri;
    if (!_supported || uri == null) {
      return Future.value(left(const BackupFolderLostFailure()));
    }
    return _guard(() => work(uri));
  }

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() work) async {
    try {
      return right(await work());
    } on PlatformException catch (e) {
      return left(switch (e.code) {
        'lost' => const BackupFolderLostFailure(),
        'large' => const BackupFormatFailure('File too large'),
        _ => BackupFolderFailure(e.code),
      });
    } on MissingPluginException {
      return left(const BackupFolderFailure('No backup folder channel'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
