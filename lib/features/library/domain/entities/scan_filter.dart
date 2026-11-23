import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// What the user keeps out of the library, on top of the fixed rules that
/// leave out ringtones, voice notes and the like: songs shorter than
/// [minDurationMs], and every song inside one of [excludedFolders] (their
/// subfolders included).
///
/// A song left out leaves the library on the next scan; its row stays,
/// marked as left out, so backups and restores still find it. Its likes,
/// plays and playlists name it by its MediaStore id, which does not change:
/// letting it back in brings them back.
final class ScanFilter extends Equatable {
  /// The shortest song kept. Low by default: album intros, skits and
  /// interludes are often 20 to 40 s.
  final int minDurationMs;

  /// Folder paths as [folderOf] gives them: absolute, no trailing slash.
  final Set<String> excludedFolders;

  const ScanFilter({
    this.minDurationMs = defaultMinDurationMs,
    this.excludedFolders = const {},
  });

  static const defaultMinDurationMs = 10 * 1000;

  bool allows({required String path, required int durationMs}) =>
      durationMs >= minDurationMs && !excludes(path);

  /// Whether it would leave out every one of [songs]: the scanner then
  /// applies none of it, since an emptied library reads as songs lost.
  bool leavesOutEvery(List<Track> songs) =>
      songs.isNotEmpty &&
      songs.every((t) => !allows(path: t.path, durationMs: t.durationMs));

  /// Whether [path], a file or a folder, lies inside an excluded folder (or
  /// is one). Compared up to a slash: excluding `/Music/A` keeps
  /// `/Music/AB`.
  bool excludes(String path) =>
      excludedFolders.any((f) => path == f || path.startsWith('$f/'));

  /// The excluded folder that holds [folder] from above, when it is not
  /// excluded itself: turning it back on alone would change nothing.
  String? excludedAbove(String folder) {
    for (final f in excludedFolders) {
      if (f != folder && folder.startsWith('$f/')) return f;
    }
    return null;
  }

  /// The folder holding the file at [path]; empty for a path with no folder.
  static String folderOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash <= 0 ? '' : path.substring(0, slash);
  }

  @override
  List<Object?> get props => [minDurationMs, excludedFolders];
}
