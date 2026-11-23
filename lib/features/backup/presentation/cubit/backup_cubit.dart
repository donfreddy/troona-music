import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_preferences.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_folder_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_preferences_repository.dart';
import 'package:troona/features/backup/domain/use_cases/export_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/run_auto_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/save_backup_use_case.dart';

/// What the backup feature is doing. One task at a time, app-wide.
enum BackupTask { export, save, read, restore, auto, folder, delete }

final class BackupState extends Equatable {
  final BackupTask? task;
  final BackupFolderState folder;

  /// The backups in the folder, newest first; empty without one.
  final List<StoredBackup> backups;

  /// What each backup holds, by [StoredBackup.id], when known.
  final Map<String, BackupSummary> summaries;
  final BackupPreferences preferences;

  const BackupState({
    this.task,
    this.folder = const NoBackupFolder(),
    this.backups = const [],
    this.summaries = const {},
    this.preferences = const BackupPreferences(),
    this.folderRead = false,
  });

  /// False until the folder was checked once: until then [folder] says
  /// nothing, and Back up now must not share what belongs in a folder.
  final bool folderRead;

  bool get busy => task != null;

  StoredBackup? get lastAuto {
    for (final b in backups) {
      // Another build's automatic backups say nothing of this one's.
      if (b.auto && b.mine) return b;
    }
    return null;
  }

  BackupState copyWith({
    BackupTask? Function()? task,
    BackupFolderState? folder,
    List<StoredBackup>? backups,
    Map<String, BackupSummary>? summaries,
    BackupPreferences? preferences,
    bool? folderRead,
  }) => BackupState(
    task: task == null ? this.task : task(),
    folder: folder ?? this.folder,
    backups: backups ?? this.backups,
    summaries: summaries ?? this.summaries,
    preferences: preferences ?? this.preferences,
    folderRead: folderRead ?? this.folderRead,
  );

  @override
  List<Object?> get props => [
    task,
    folder,
    backups,
    summaries,
    preferences,
    folderRead,
  ];
}

/// Backups by hand and automatic, the folder they go to, and restores.
///
/// A singleton: a restore keeps running after its page closes, and the
/// automatic backup must not run beside a task the user started.
final class BackupCubit extends Cubit<BackupState> {
  final ExportBackupUseCase _export;
  final RestoreBackupUseCase _restore;
  final SaveBackupUseCase _save;
  final RunAutoBackupUseCase _auto;
  final BackupFolderRepository _folder;
  final BackupPreferencesRepository _preferences;

  BackupCubit({
    required ExportBackupUseCase export,
    required RestoreBackupUseCase restore,
    required SaveBackupUseCase save,
    required RunAutoBackupUseCase auto,
    required BackupFolderRepository folder,
    required BackupPreferencesRepository preferences,
  }) : _export = export,
       _restore = restore,
       _save = save,
       _auto = auto,
       _folder = folder,
       _preferences = preferences,
       super(BackupState(preferences: preferences.load()));

  /// The task running, done when it ends.
  Future<void>? _running;

  /// Reads the preferences, the folder and its backups again, once the
  /// task running is done: read beside it (a delete), the list could come
  /// back with the file it removed.
  Future<void> load() async {
    emit(state.copyWith(preferences: _preferences.load()));
    await _running;
    await _refresh();
  }

  Future<Either<Failure, BackupFolder?>> pickFolder() =>
      _busy(BackupTask.folder, () async {
        final picked = await _folder.pick();
        // A folder chosen again is tried at once, not after the wait that
        // follows a failure.
        if (picked case Right(value: _?)) {
          await _preferences.setLastFailure(null);
        }
        await _refresh();
        return picked;
      });

  /// Turning it on without a folder asks for one first; it stays off when
  /// the user cancels. Once on, a first backup is made at once.
  Future<Either<Failure, Unit>> setAuto(bool on) async {
    if (on && state.folder is! BackupFolderReady) {
      final picked = await pickFolder();
      final failure = picked.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) return left(failure);
      if (state.folder is! BackupFolderReady) return right(unit);
    }
    await _setPreferences(state.preferences.copyWith(auto: on));
    if (!on) return right(unit);
    // The first backup, made now: a failure is said, not left for later,
    // nor skipped because one failed a moment ago.
    await _preferences.setLastFailure(null);
    return switch (await autoBackupIfDue()) {
      AutoBackupFailed(:final failure) => left(failure),
      _ => right(unit),
    };
  }

  Future<void> setFrequency(BackupFrequency frequency) =>
      _setPreferences(state.preferences.copyWith(frequency: frequency));

  /// Never empty: the last part cannot be left out.
  Future<void> setParts(Set<BackupPart> parts) async {
    if (parts.isEmpty) return;
    await _setPreferences(state.preferences.copyWith(parts: parts));
  }

  /// A backup of the parts chosen, written to the folder.
  Future<Either<Failure, StoredBackup>> backUpNow() =>
      _busy(BackupTask.save, () async {
        final saved = await _save(state.preferences.parts);
        await _refresh();
        return saved;
      });

  /// Writes a backup of the parts chosen and hands its file to [share].
  /// The file is deleted afterwards, shared or not: it carries the
  /// listening history.
  Future<Either<Failure, Unit>> export(
    Future<void> Function(String path) share,
  ) => _busy(BackupTask.export, () async {
    final written = await _export(state.preferences.parts);
    return _shareThenDiscard(written, share);
  });

  /// Hands a copy of [stored] to [share], deleted afterwards.
  Future<Either<Failure, Unit>> share(
    StoredBackup stored,
    Future<void> Function(String path) share,
  ) => _busy(BackupTask.export, () async {
    final copied = await _folder.copyToShare(stored);
    return _shareThenDiscard(copied, share);
  });

  /// Reads a backup of the folder, for the user to choose its parts.
  Future<Either<Failure, Backup>> open(StoredBackup stored) => _busy(
    BackupTask.read,
    () async {
      final read = await _folder.read(stored);
      if (read case Right(:final value)) {
        emit(
          state.copyWith(
            summaries: {...state.summaries, stored.id: BackupSummary.of(value)},
          ),
        );
      }
      return read;
    },
  );

  /// Reads the backup file at [path], for the user to choose its parts.
  Future<Either<Failure, Backup>> openFile(String path) =>
      _busy(BackupTask.read, () => _restore.read(path));

  /// Merges the [parts] of [backup] chosen into this phone.
  Future<Either<Failure, RestoreReport>> restore(
    Backup backup,
    Set<BackupPart> parts,
  ) => _busy(BackupTask.restore, () => _restore(backup, parts));

  Future<Either<Failure, Unit>> delete(StoredBackup stored) =>
      _busy(BackupTask.delete, () async {
        final deleted = await _folder.delete(stored);
        await _refresh();
        return deleted;
      });

  /// Writes an automatic backup when one is due. Skipped while another
  /// task runs: the next start or return to the app tries again.
  Future<AutoBackupOutcome?> autoBackupIfDue() async {
    if (state.busy || isClosed) return null;
    final done = Completer<void>();
    _running = done.future;
    emit(state.copyWith(task: () => BackupTask.auto));
    try {
      final outcome = await _auto();
      if (outcome is! AutoBackupSkipped) await _refresh();
      return outcome;
    } catch (e, st) {
      ErrorHandler.handle(e, st);
      return null;
    } finally {
      done.complete();
      if (!isClosed) emit(state.copyWith(task: () => null));
    }
  }

  Future<void> _setPreferences(BackupPreferences preferences) async {
    emit(state.copyWith(preferences: preferences));
    await _preferences.save(preferences);
  }

  Future<void> _refresh() async {
    var folder = await _folder.state();
    var backups = const <StoredBackup>[];
    if (folder is BackupFolderReady) {
      switch (await _folder.list()) {
        case Right(:final value):
          backups = value;
        // The access went between the check and the listing.
        case Left(:final value) when value is BackupFolderLostFailure:
          folder = await _folder.state();
        case Left():
          break;
      }
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        folder: folder,
        folderRead: true,
        backups: backups,
        summaries: {
          for (final b in backups)
            b.id: ?(state.summaries[b.id] ?? _folder.summaryOf(b)),
        },
      ),
    );
  }

  Future<Either<Failure, Unit>> _shareThenDiscard(
    Either<Failure, String> written,
    Future<void> Function(String path) share,
  ) async {
    try {
      return await written.fold((f) async => left(f), (path) async {
        await share(path);
        return right(unit);
      });
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    } finally {
      await _export.discard();
    }
  }

  /// Runs one task the user asked for. One started while the automatic
  /// backup runs (the app comes back from the file picker, and the backup
  /// starts) waits for it; one started beside another of the user's is
  /// refused.
  Future<Either<Failure, T>> _busy<T>(
    BackupTask task,
    Future<Either<Failure, T>> Function() run,
  ) async {
    if (state.task == BackupTask.auto) await _running;
    if (state.busy || isClosed) {
      return left(const UnexpectedFailure('Backup task running'));
    }
    final done = Completer<void>();
    _running = done.future;
    emit(state.copyWith(task: () => task));
    try {
      return await run();
    } finally {
      done.complete();
      if (!isClosed) emit(state.copyWith(task: () => null));
    }
  }
}
