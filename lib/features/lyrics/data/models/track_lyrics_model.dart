import 'package:isar_plus/isar_plus.dart';

part 'track_lyrics_model.g.dart';

/// A song's lyrics as found, or the memory that none were: without it,
/// each look at a song with no lyrics would ask the online sources again.
/// Apart from the tracks, which the lists load whole.
@collection
class TrackLyricsModel {
  /// The song's id, as the library names it.
  late String id;

  /// The LRC or plain text as found, parsed on reading: a better parser
  /// serves every song already stored. Null when nothing was found.
  String? raw;

  /// `imported`, `embedded` or `online`; null when nothing was found.
  String? source;

  /// The user's correction for this song, in milliseconds: positive shows
  /// the lines earlier.
  int offsetMs = 0;

  /// When the sources were last asked, to ask again later for what was
  /// not found.
  late DateTime checkedAt;

  /// Some source could not be reached on that look: it is asked again
  /// sooner.
  bool partial = false;
}
