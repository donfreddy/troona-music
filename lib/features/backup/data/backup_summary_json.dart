import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';

/// [BackupSummary] as the list of backups keeps it on this phone.
abstract final class BackupSummaryJson {
  static Map<String, Object?> encode(BackupSummary s) => {
    'parts': [for (final p in s.parts) p.name],
    'playlists': s.playlists,
    'likes': s.likes,
    'plays': s.plays,
    'lyrics': s.lyrics,
    'profiles': s.profiles,
  };

  /// Null for anything else: the summary is counted again from the file.
  static BackupSummary? decode(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final parts = json['parts'];
    int? count(String key) => switch (json[key]) {
      final int n when n >= 0 => n,
      _ => null,
    };
    final playlists = count('playlists');
    final likes = count('likes');
    final plays = count('plays');
    final profiles = count('profiles');
    // Absent from summaries counted before lyrics were a part.
    final lyrics = count('lyrics') ?? 0;
    if (parts is! List ||
        playlists == null ||
        likes == null ||
        plays == null ||
        profiles == null) {
      return null;
    }
    return BackupSummary(
      parts: {
        for (final p in BackupPart.values)
          if (parts.contains(p.name)) p,
      },
      playlists: playlists,
      likes: likes,
      plays: plays,
      lyrics: lyrics,
      profiles: profiles,
    );
  }
}
