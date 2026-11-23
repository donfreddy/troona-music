import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

/// Finds the songs of a backup in this phone's library, then among the
/// songs its scan filter leaves out.
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
/// ("Intro") says too little. A song saved without an artist is also looked
/// up as the "Artist - Title" its saved title may read as. Several candidates go to the closest duration;
/// a tie matches nothing, since a missing song is better than a wrong one in
/// a playlist. At step 1 a tie is the same file in two folders: either copy
/// is right, so the first one is taken.
final class TrackMatcher {
  /// [library] holds the songs the library shows, [leftOut] the ones the
  /// scan filter leaves out: a left-out copy is only taken where the
  /// library has none at the same step (see [match]).
  TrackMatcher(Iterable<Track> library, {Iterable<Track> leftOut = const []})
    : _library = _Pool(library),
      _leftOut = _Pool(leftOut);

  static const tolerance = Duration(seconds: 2);

  final _Pool _library;
  final _Pool _leftOut;

  /// The device id of [saved] here, or null when it is not found or two
  /// songs fit it as well.
  ///
  /// The steps go from the strictest, the library before the songs left
  /// out at each level of certainty: the same file, then the same tags in
  /// the library, then in the songs left out, then the same title and
  /// artist in either. The first step with a candidate decides, a tie
  /// included: a folder turned off often holds a second copy, which must
  /// never take or settle what the library holds.
  String? match(BackupTrack saved) {
    final named = _isKnown(saved.artist)
        ? null
        : TrackTags.fromName(saved.title);
    for (final step in [
      () => _library.byFile(saved),
      () => _library.byTags(saved, named),
      () => _leftOut.byFile(saved),
      () => _leftOut.byTags(saved, named),
      () => _library.byTitle(saved, named),
      () => _leftOut.byTitle(saved, named),
    ]) {
      if (step() case (final found, :final firstOnTie)) {
        return _closest(found, saved, firstOnTie: firstOnTie)?.id;
      }
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

  static bool _isKnown(String artist) => !TrackTags.isUnknownArtist(artist);

  static int _gap(Track track, BackupTrack saved) =>
      (track.durationMs - saved.durationMs).abs();

  static String _fileKey(String fileName, int size) => '$fileName\u0000$size';

  static String _tagsKey(String title, String artist, String album) =>
      '${_titleKey(title, artist)}\u0000${normalize(album)}';

  /// Earlier versions saved Android's `<unknown>` for a missing artist.
  static String _titleKey(String title, String artist) =>
      '${normalize(title)}\u0000${normalize(TrackTags.artist(artist))}';

  /// Case and spacing differ between taggers.
  static String normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// The songs of one place (the library, or the ones left out), indexed by
/// each step of [TrackMatcher.match]. A step gives its candidates, or null
/// when it has none.
final class _Pool {
  _Pool(Iterable<Track> tracks) {
    for (final track in tracks) {
      _byFile.add(TrackMatcher._fileKey(track.fileName, track.size), track);
      _byTags.add(
        TrackMatcher._tagsKey(track.title, track.artist, track.album),
        track,
      );
      _byTitle.add(TrackMatcher._titleKey(track.title, track.artist), track);
    }
  }

  final _byFile = <String, List<Track>>{};
  final _byTags = <String, List<Track>>{};
  final _byTitle = <String, List<Track>>{};

  /// The same file in two folders: either copy is right, so the first one
  /// is taken.
  (List<Track>, {bool firstOnTie})? byFile(BackupTrack saved) =>
      switch (_byFile[TrackMatcher._fileKey(saved.fileName, saved.size)]) {
        final copies? => (copies, firstOnTie: true),
        null => null,
      };

  (List<Track>, {bool firstOnTie})? byTags(
    BackupTrack saved,
    ({String title, String artist})? named,
  ) => _first(saved, [
    _byTags[TrackMatcher._tagsKey(saved.title, saved.artist, saved.album)],
    if (named != null)
      _byTags[TrackMatcher._tagsKey(named.title, named.artist, saved.album)],
  ]);

  (List<Track>, {bool firstOnTie})? byTitle(
    BackupTrack saved,
    ({String title, String artist})? named,
  ) => _first(saved, [
    if (TrackMatcher._isKnown(saved.artist))
      _byTitle[TrackMatcher._titleKey(saved.title, saved.artist)],
    if (named != null)
      _byTitle[TrackMatcher._titleKey(named.title, named.artist)],
  ]);

  /// The first of [lists] with songs within the tolerance of [saved].
  static (List<Track>, {bool firstOnTie})? _first(
    BackupTrack saved,
    List<List<Track>?> lists,
  ) {
    for (final found in lists) {
      final candidates = [
        for (final track in found ?? const <Track>[])
          if (TrackMatcher._gap(track, saved) <=
              TrackMatcher.tolerance.inMilliseconds)
            track,
      ];
      if (candidates.isNotEmpty) return (candidates, firstOnTie: false);
    }
    return null;
  }
}

extension on Map<String, List<Track>> {
  void add(String key, Track track) => (this[key] ??= []).add(track);
}
