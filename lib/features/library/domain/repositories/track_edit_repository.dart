import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';

/// A song's correction and what its file says under it: what the editor
/// shows.
typedef TrackEditDraft = ({TrackEdit edit, TrackFileTags file});

/// The user's corrections of songs, kept in the app and shown over their
/// files' tags. A scan applies them before artists and albums are made, so
/// a corrected artist is grouped, credited and counted as if tagged so.
abstract interface class TrackEditRepository {
  /// [track]'s correction ([TrackEdit.none] when there is none) and its
  /// file's tags.
  Future<Either<Failure, TrackEditDraft>> draftOf(Track track);

  /// Sets [fields] of each of [tracks]' corrections to [edit]'s (a null
  /// clearing one, the file's value showing again), keeping the rest; a
  /// field equal to the file's value is dropped, and a correction left
  /// empty is removed. [pickedCover], a picture chosen by the user, is
  /// copied into the app's files and becomes the cover of them all. Ends
  /// by firing [changes].
  Future<Either<Failure, Unit>> save(
    List<Track> tracks,
    TrackEdit edit, {
    required Set<TrackEditField> fields,
    String? pickedCover,
  });

  /// The names of the library's artists, sorted, for the editor to
  /// suggest: a name typed slightly off would make one more artist.
  Future<List<String>> artistNames();

  /// Fires after each change: the library scans again to apply it.
  Stream<void> get changes;

  /// Says that corrections changed elsewhere (a restore), on [changes].
  void announce();
}
