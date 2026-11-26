import 'package:troona/features/library/data/models/track_edit_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';

/// Lays the user's corrections over the songs a scan read.
abstract final class TrackEditMatch {
  /// Applies each of [edits] to its song among [scanned] (see
  /// [TrackModel.applyEdit]), found by device id, else by file name and size
  /// when that names one song only: the id changes when a file moves.
  /// Returns the edits found under a new id, rekeyed, for the caller to
  /// write; an edit whose song is gone is kept as it is, for the day it
  /// comes back.
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
    return rekeyed;
  }
}
