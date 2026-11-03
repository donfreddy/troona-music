import 'package:troona/features/library/domain/entities/track.dart';

/// The order of an album's songs, and the numbers shown next to them.
///
/// MediaStore files the disc in the thousands of the track number (2003 is
/// disc 2, track 3). Downloaded songs often have no number at all: they
/// come in the order they were added, which is the order the downloader
/// saved them in, close to the album's own.
abstract final class AlbumOrder {
  AlbumOrder._();

  /// [tracks] by disc, then track number, then the order they were added;
  /// songs without a number come after the numbered ones of their disc.
  static List<Track> sorted(List<Track> tracks) =>
      List.of(tracks)..sort((a, b) {
        final byDisc = _disc(a).compareTo(_disc(b));
        if (byDisc != 0) return byDisc;
        final byNumber = _sortNumber(a).compareTo(_sortNumber(b));
        if (byNumber != 0) return byNumber;
        return _added(a).compareTo(_added(b));
      });

  /// The numbers to show for [tracks], in order: their track numbers when
  /// every one has one, else their places in the list, so a half-numbered
  /// album never shows 3, 7, then 4.
  static List<int> numbers(List<Track> tracks) {
    final own = [for (final t in tracks) number(t)];
    if (own.every((n) => n != null)) return [for (final n in own) n!];
    return [for (var i = 0; i < tracks.length; i++) i + 1];
  }

  /// [track]'s number within its disc, or null when it has none.
  static int? number(Track track) {
    final n = (track.trackNumber ?? 0) % 1000;
    return n > 0 ? n : null;
  }

  static int _disc(Track t) => (t.trackNumber ?? 0) ~/ 1000;

  static int _sortNumber(Track t) => number(t) ?? 1000;

  /// MediaStore ids grow as files are added.
  static int _added(Track t) => int.tryParse(t.id) ?? 0;
}
