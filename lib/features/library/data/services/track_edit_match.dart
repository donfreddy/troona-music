import 'package:troona/features/library/data/models/track_edit_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/domain/services/album_merge.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

/// Lays the user's corrections over the songs a scan read.
abstract final class TrackEditMatch {
  /// Applies each of [edits] to its song among [scanned] (see
  /// [TrackModel.applyEdit]), found by device id, else by file name and size
  /// when that names one song only: the id changes when a file moves.
  /// Returns the edits to write again: found under a new id (rekeyed), or
  /// whose file was renamed or changed in place (its name and size taken
  /// again, so the edit still follows it once it moves). An edit whose
  /// song is gone is kept as it is, for the day it comes back.
  static List<TrackEditModel> apply(
    List<TrackModel> scanned,
    List<TrackEditModel> edits,
  ) {
    if (edits.isEmpty) return const [];
    final byId = {for (final t in scanned) t.deviceId: t};
    final byFile = <(String, int), List<TrackModel>>{};
    for (final t in scanned) {
      (byFile[(t.fileName, t.size)] ??= []).add(t);
    }
    final edited = <String>{};
    final rekeyed = <TrackEditModel>[];
    // By id first, all of them: a moved file must not take the place of a
    // song that kept its id.
    final pending = <TrackEditModel>[];
    for (final edit in edits) {
      final track = byId[edit.deviceId];
      if (track == null) {
        pending.add(edit);
      } else if (edited.add(track.deviceId)) {
        track.applyEdit(edit);
        if (edit.fileName != track.fileName || edit.size != track.size) {
          rekeyed.add(
            edit
              ..fileName = track.fileName
              ..size = track.size,
          );
        }
      }
    }
    for (final edit in pending) {
      final same = byFile[(edit.fileName, edit.size)];
      if (same == null || same.length != 1) continue;
      final track = same.single;
      if (!edited.add(track.deviceId)) continue;
      track.applyEdit(edit);
      rekeyed.add(edit..deviceId = track.deviceId);
    }
    _moveAlbums(scanned);
    return rekeyed;
  }

  /// Takes each song whose album was corrected out of the album MediaStore
  /// filed it in: into the album of its new name in its folder when
  /// MediaStore made one (a compilation's stray song, whose songs share no
  /// artist for `AlbumMerge` to join them by), else into the one made for
  /// that name, in its folder or from its first album, so songs renamed
  /// together stay together, across folders too. Names compare as
  /// `AlbumMerge` joins them. `link` then joins albums as usual.
  static void _moveAlbums(List<TrackModel> scanned) {
    final filed = <(String, String), int>{};
    for (final t in scanned) {
      if (t.fileAlbum == null) {
        filed[(t.folder, AlbumMerge.nameKey(t.album))] ??= t.albumId;
      }
    }
    final byFolder = <(String, String), int>{};
    final bySource = <(int, String), int>{};
    for (final t in scanned) {
      if (t.fileAlbum == null) continue;
      final name = AlbumMerge.nameKey(t.album);
      final id =
          filed[(t.folder, name)] ??
          byFolder[(t.folder, name)] ??
          bySource[(t.albumId, name)] ??
          TrackTags.stableId('${t.albumId}\u0000$name');
      byFolder[(t.folder, name)] ??= id;
      bySource[(t.albumId, name)] ??= id;
      t.albumId = id;
    }
  }
}
