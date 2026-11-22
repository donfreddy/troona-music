import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

/// What an online source is told about a song: its title, artist, album
/// and length, nothing more.
final class LyricsQuery {
  /// The title as tagged.
  final String title;

  /// The title without what lyrics databases leave out: featured artists
  /// and the version notes in brackets ("Remastered 2011", "Live").
  final String plainTitle;

  /// The artist tag as written, '' when unknown.
  final String artist;

  /// The first artist credited, '' when unknown.
  final String leadArtist;

  final String album;

  /// The song's length, zero when unknown.
  final Duration duration;

  const LyricsQuery({
    required this.title,
    required this.plainTitle,
    required this.artist,
    required this.leadArtist,
    required this.album,
    required this.duration,
  });

  factory LyricsQuery.of(Track track) {
    final artist = TrackTags.isUnknownArtist(track.artist)
        ? ''
        : track.artist.trim();
    final lead = artist.isEmpty ? '' : track.credits.first.name.trim();
    return LyricsQuery(
      title: track.title.trim(),
      plainTitle: plainTitleOf(track.title),
      artist: artist,
      leadArtist: lead.isEmpty ? artist : lead,
      album: track.album.trim(),
      duration: Duration(milliseconds: track.durationMs),
    );
  }

  static final _featured = RegExp(
    r'\s*[(\[]\s*(feat\.?|ft\.?|featuring|with)\s[^)\]]*[)\]]',
    caseSensitive: false,
  );
  static final _featuredTail = RegExp(
    r'\s+(feat\.?|ft\.?|featuring)\s.*$',
    caseSensitive: false,
  );
  static final _version = RegExp(
    r'\s*[(\[][^)\]]*\b(remaster(ed)?|live|version|edit|mix|mono|stereo|'
    r'deluxe|bonus|explicit|clean|official|video|audio|lyrics?)\b[^)\]]*[)\]]',
    caseSensitive: false,
  );
  static final _versionTail = RegExp(
    r'\s+-\s+[^-]*\b(remaster(ed)?|live|version|edit|mix|mono|stereo)\b[^-]*$',
    caseSensitive: false,
  );

  /// [title] without featured artists and version notes; the title itself
  /// when nothing would be left.
  static String plainTitleOf(String title) {
    final plain = title
        .replaceAll(_featured, '')
        .replaceAll(_version, '')
        .replaceAll(_featuredTail, '')
        .replaceAll(_versionTail, '')
        .trim();
    return plain.isEmpty ? title.trim() : plain;
  }
}
