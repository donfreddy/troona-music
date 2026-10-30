import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// Finds the songs of a backup in this phone's library.
///
/// Device ids differ from one phone to another, so a song is looked up by
/// what it is, in three steps from the strictest; the first step with a
/// candidate decides:
/// 1. the same file name and size (the file was copied);
/// 2. the same title, artist and album (re-encoded or renamed);
/// 3. the same title and artist (the album was renamed).
///
/// Steps 2 and 3 only keep songs within [tolerance] of the saved duration,
/// and step 3 is skipped for an unknown artist, where a title alone
/// ("Intro") says too little. Several candidates go to the closest duration;
/// a tie matches nothing, since a missing song is better than a wrong one in
/// a playlist. At step 1 a tie is the same file in two folders: either copy
/// is right, so the first one is taken.
final class TrackMatcher {
  TrackMatcher(Iterable<Track> library) {
    for (final track in library) {
      _byFile.add(_fileKey(track.fileName, track.size), track);
      _byTags.add(_tagsKey(track.title, track.artist, track.album), track);
      _byTitle.add(_titleKey(track.title, track.artist), track);
    }
  }

  static const tolerance = Duration(seconds: 2);

  final _byFile = <String, List<Track>>{};
  final _byTags = <String, List<Track>>{};
  final _byTitle = <String, List<Track>>{};

  /// The device id of [saved] in this library, or null when it is not found.
  String? match(BackupTrack saved) {
    final copies = _byFile[_fileKey(saved.fileName, saved.size)];
    if (copies != null) return _closest(copies, saved, firstOnTie: true)?.id;

    final steps = [
      _byTags[_tagsKey(saved.title, saved.artist, saved.album)],
      if (_isKnown(saved.artist))
        _byTitle[_titleKey(saved.title, saved.artist)],
    ];
    for (final found in steps) {
      final candidates = [
        for (final track in found ?? const <Track>[])
          if (_gap(track, saved) <= tolerance.inMilliseconds) track,
      ];
      if (candidates.isNotEmpty) return _closest(candidates, saved)?.id;
    }
    return null;
  }

  static Track? _closest(
    List<Track> candidates,
    BackupTrack saved, {
    bool firstOnTie = false,
  }) {
    final sorted = [...candidates]
      ..sort((a, b) => _gap(a, saved).compareTo(_gap(b, saved)));
    if (!firstOnTie &&
        sorted.length > 1 &&
        _gap(sorted[0], saved) == _gap(sorted[1], saved)) {
      return null;
    }
    return sorted.first;
  }

  /// What Android and the scanner write when a file has no artist tag.
  static bool _isKnown(String artist) =>
      !const {'', '<unknown>', 'unknown artist'}.contains(normalize(artist));

  static int _gap(Track track, BackupTrack saved) =>
      (track.durationMs - saved.durationMs).abs();

  static String _fileKey(String fileName, int size) => '$fileName\u0000$size';

  static String _tagsKey(String title, String artist, String album) =>
      '${_titleKey(title, artist)}\u0000${normalize(album)}';

  static String _titleKey(String title, String artist) =>
      '${normalize(title)}\u0000${normalize(artist)}';

  /// Case and spacing differ between taggers.
  static String normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

extension on Map<String, List<Track>> {
  void add(String key, Track track) => (this[key] ??= []).add(track);
}
