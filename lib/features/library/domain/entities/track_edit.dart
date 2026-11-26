import 'package:equatable/equatable.dart';

/// The fields a correction holds.
enum TrackEditField { title, artist, album, year, cover }

/// What the user corrected on a song, shown over what its file says. The
/// file itself is never written. A null field is not corrected.
///
/// [artist] may be empty: the song then reads as by an unknown artist,
/// whatever its file says. [year] 0 means no year.
final class TrackEdit extends Equatable {
  final String? title;
  final String? artist;
  final String? album;
  final int? year;

  /// A picture copied into the app's own files, never the cache (which the
  /// system may empty).
  final String? coverPath;

  const TrackEdit({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.coverPath,
  });

  static const none = TrackEdit();

  /// The longest text a field takes, as backups bound their texts.
  static const maxText = 500;

  /// The years a correction takes, besides 0 (no year).
  static const firstYear = 1000;
  static const lastYear = 9999;

  bool get isEmpty =>
      title == null &&
      artist == null &&
      album == null &&
      year == null &&
      coverPath == null;

  /// Whether [year] is one a correction may hold.
  static bool validYear(int year) =>
      year == 0 || (year >= firstYear && year <= lastYear);

  /// This edit with [fields] taken from [other], a null there clearing
  /// the field: an album's correction lands on each of its songs, keeping
  /// what was corrected on them alone.
  TrackEdit withFields(TrackEdit other, Set<TrackEditField> fields) =>
      TrackEdit(
        title: fields.contains(TrackEditField.title) ? other.title : title,
        artist: fields.contains(TrackEditField.artist) ? other.artist : artist,
        album: fields.contains(TrackEditField.album) ? other.album : album,
        year: fields.contains(TrackEditField.year) ? other.year : year,
        coverPath: fields.contains(TrackEditField.cover)
            ? other.coverPath
            : coverPath,
      );

  /// This edit without the fields that only repeat [file]: a value set back
  /// to what the file says is no correction.
  TrackEdit beyond(TrackFileTags file) => TrackEdit(
    title: title == file.title ? null : title,
    artist: artist == file.artist ? null : artist,
    album: album == file.album ? null : album,
    year: year == file.year ? null : year,
    coverPath: coverPath,
  );

  @override
  List<Object?> get props => [title, artist, album, year, coverPath];
}

/// A song's tags as its file gives them, under any correction.
final class TrackFileTags extends Equatable {
  final String title;
  final String artist;
  final String album;
  final int year;

  /// The cover found in the file, null when it has none.
  final String? coverPath;

  const TrackFileTags({
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
    this.coverPath,
  });

  @override
  List<Object?> get props => [title, artist, album, year, coverPath];
}
