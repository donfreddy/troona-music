import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';

part 'track_edit_model.g.dart';

/// A song's correction (see [TrackEdit]), apart from the tracks, which a
/// scan rewrites. Found again by the song's device id, else by its file's
/// name and size: the id changes when the file moves, the size when it is
/// tagged again elsewhere, rarely both.
@collection
class TrackEditModel {
  int id = 0;

  @Index()
  late String deviceId;
  late String fileName;
  late int size;

  String? title;
  String? artist;
  String? album;
  int? year;
  String? coverPath;

  late DateTime editedAt;

  TrackEdit toEntity() => TrackEdit(
    title: title,
    artist: artist,
    album: album,
    year: year,
    coverPath: coverPath,
  );

  void set(TrackEdit edit) {
    title = edit.title;
    artist = edit.artist;
    album = edit.album;
    year = edit.year;
    coverPath = edit.coverPath;
  }
}
