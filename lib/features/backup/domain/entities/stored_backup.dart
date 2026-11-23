import 'package:equatable/equatable.dart';

/// The folder backups are written to, as the user chose it.
final class BackupFolder extends Equatable {
  /// The system's address for it, kept to reach it again.
  final String uri;

  /// Its name, as the system shows it.
  final String name;

  const BackupFolder({required this.uri, required this.name});

  @override
  List<Object?> get props => [uri, name];
}

/// Where backups can go on this phone.
sealed class BackupFolderState extends Equatable {
  const BackupFolderState();

  @override
  List<Object?> get props => [];
}

/// This platform has no folder to pick (iOS): backups are shared instead.
final class BackupFolderUnsupported extends BackupFolderState {
  const BackupFolderUnsupported();
}

final class NoBackupFolder extends BackupFolderState {
  const NoBackupFolder();
}

final class BackupFolderReady extends BackupFolderState {
  final BackupFolder folder;
  const BackupFolderReady(this.folder);

  @override
  List<Object?> get props => [folder];
}

/// A folder was chosen, but this app can no longer reach it (the access
/// was withdrawn, the folder removed). [name] is the one it had.
final class BackupFolderLost extends BackupFolderState {
  final String name;
  const BackupFolderLost(this.name);

  @override
  List<Object?> get props => [name];
}

/// A backup file in the folder.
final class StoredBackup extends Equatable {
  /// The system's address for the file.
  final String id;
  final String name;

  /// When it was made, read from its name.
  final DateTime createdAt;

  /// Made by the automatic backup, which keeps only its last few.
  final bool auto;

  /// Made by this build of the app. The debug and release builds are two
  /// apps that may share a folder: each rotates only its own automatic
  /// backups.
  final bool mine;
  final int? size;

  const StoredBackup({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.auto,
    this.mine = true,
    this.size,
  });

  @override
  List<Object?> get props => [id, name, createdAt, auto, mine, size];
}
