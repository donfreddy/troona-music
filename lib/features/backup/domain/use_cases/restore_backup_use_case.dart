import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/backup/domain/track_matcher.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_snapshot.dart';
import 'package:troona/features/library/domain/repositories/stored_track_repository.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// What a restore found.
final class RestoreReport extends Equatable {
  /// Songs of the parts restored found in the library, out of [total]:
  /// zero of zero when those parts name no song (settings alone).
  final int found;
  final int total;

  /// Songs of the backup not in the library, by title.
  final List<BackupTrack> missing;

  /// Saved with the backup, for the caller to apply: settings act on
  /// running services that the repository does not reach. Null when they
  /// were not chosen.
  final AppSettings? settings;

  /// The equalizer saved with the backup, for the caller to apply as well;
  /// null when it has none or it was not chosen.
  final EqualizerSnapshot? equalizer;

  const RestoreReport({
    required this.found,
    required this.total,
    required this.missing,
    this.settings,
    this.equalizer,
  });

  @override
  List<Object?> get props => [found, total, missing, settings, equalizer];
}

/// Merges the parts of a backup the user chose into this phone, finding
/// its songs among the stored ones with [TrackMatcher]: a song a folder
/// turned off leaves out of the library is still found, and its likes,
/// plays and playlists come back with it. Importing the same file
/// again after adding songs links the ones found since.
final class RestoreBackupUseCase {
  final BackupRepository _backups;
  final StoredTrackRepository _library;

  const RestoreBackupUseCase(this._backups, this._library);

  /// Reads the backup file at [path], for the user to choose its parts.
  Future<Either<Failure, Backup>> read(String path) => _backups.readFile(path);

  Future<Either<Failure, RestoreReport>> call(
    Backup backup,
    Set<BackupPart> parts,
  ) async {
    final chosen = backup.only(parts);
    final library = await _library.getStoredTracks();
    return library.fold((f) async => left(f), (stored) async {
      // The library before the songs left out, step by step: a folder
      // turned off often holds a second copy (a download, a chat app's).
      final matcher = TrackMatcher(stored.kept, leftOut: stored.leftOut);
      final ids = <String, String>{};
      final missing = <BackupTrack>[];
      for (final MapEntry(:key, value: saved) in chosen.tracks.entries) {
        final id = matcher.match(saved);
        if (id == null) {
          missing.add(saved);
        } else {
          ids[key] = id;
        }
      }
      missing.sort((a, b) => a.title.compareTo(b.title));
      final restored = await _backups.restore(chosen, ids);
      return restored.map(
        (_) => RestoreReport(
          found: ids.length,
          total: chosen.tracks.length,
          missing: missing,
          settings: chosen.settings,
          equalizer: chosen.equalizer,
        ),
      );
    });
  }
}
