import 'package:isar_plus/isar_plus.dart';

part 'track_edges_model.g.dart';

/// Where a song's music starts and stops, found once in its file. Apart
/// from the tracks, which the lists load whole.
@collection
class TrackEdgesModel {
  /// The song's id, as the library names it.
  late String id;

  /// The file analysed, by its size and last change: another file under
  /// the same id is analysed again.
  late int size;
  int? modifiedMs;

  /// Null when the file could not be read: remembered, so it is not
  /// decoded again on every play.
  int? musicStartMs;
  int? musicEndMs;
  int? fadeDownMs;

  late DateTime analyzedAt;
}
