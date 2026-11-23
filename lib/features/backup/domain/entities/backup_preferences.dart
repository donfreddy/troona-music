import 'package:equatable/equatable.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';

enum BackupFrequency { daily, weekly }

/// How this phone backs up. Kept on the phone, never in a backup: the
/// folder it names is this phone's.
final class BackupPreferences extends Equatable {
  /// What a backup holds, by hand or automatic. Never empty.
  final Set<BackupPart> parts;
  final bool auto;
  final BackupFrequency frequency;

  const BackupPreferences({
    this.parts = BackupPart.all,
    this.auto = false,
    this.frequency = BackupFrequency.weekly,
  });

  BackupPreferences copyWith({
    Set<BackupPart>? parts,
    bool? auto,
    BackupFrequency? frequency,
  }) => BackupPreferences(
    parts: parts ?? this.parts,
    auto: auto ?? this.auto,
    frequency: frequency ?? this.frequency,
  );

  @override
  List<Object?> get props => [parts, auto, frequency];
}

/// The last automatic backup: when it ran, what it held and the file it
/// is in, so a phone where nothing changed writes no copy of that file
/// while it is still there.
final class AutoBackupMark extends Equatable {
  final DateTime at;
  final String fingerprint;

  /// The file's name in the folder; null for a mark saved before names
  /// were kept, which a new backup replaces.
  final String? name;

  const AutoBackupMark({
    required this.at,
    required this.fingerprint,
    this.name,
  });

  @override
  List<Object?> get props => [at, fingerprint, name];
}
