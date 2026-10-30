import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/backup/domain/track_matcher.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// What a restore found.
final class RestoreReport extends Equatable {
  /// Songs of the backup found in the library, out of [total].
  final int found;
  final int total;

  /// Songs of the backup not in the library, by title.
  final List<BackupTrack> missing;

  /// Saved with the backup, for the caller to apply: settings act on
  /// running services that the repository does not reach.
  final AppSettings settings;

  const RestoreReport({
    required this.found,
    required this.total,
    required this.missing,
    required this.settings,
  });

  @override
  List<Object?> get props => [found, total, missing, settings];
}

/// Merges a backup file into this phone, finding its songs in the library
/// with [TrackMatcher]. Importing the same file again after adding songs
/// links the ones found since.
final class RestoreBackupUseCase {
  final BackupRepository _backups;
  final LibraryRepository _library;

  const RestoreBackupUseCase(this._backups, this._library);

  Future<Either<Failure, RestoreReport>> call(String path) async {
    final read = await _backups.readFile(path);
    return read.fold((f) async => left(f), (backup) async {
      final library = await _library.getTracks();
      return library.fold((f) async => left(f), (tracks) async {
        final matcher = TrackMatcher(tracks);
        final ids = <String, String>{};
        final missing = <BackupTrack>[];
        for (final MapEntry(:key, value: saved) in backup.tracks.entries) {
          final id = matcher.match(saved);
          if (id == null) {
            missing.add(saved);
          } else {
            ids[key] = id;
          }
        }
        missing.sort((a, b) => a.title.compareTo(b.title));
        final restored = await _backups.restore(backup, ids);
        return restored.map(
          (_) => RestoreReport(
            found: ids.length,
            total: backup.tracks.length,
            missing: missing,
            settings: backup.settings,
          ),
        );
      });
    });
  }
}
