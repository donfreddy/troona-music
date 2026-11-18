/// Picks an artist's photo out of a Deezer search, only when it is surely
/// theirs.
///
/// Deezer's artist search returns its best guess for a name: a namesake, or
/// an artist with no photo (whose picture is a grey silhouette). A song
/// search tells them apart: the photo is taken from a result that is one of
/// the artist's own songs in the library, credited to that very name.
abstract final class DeezerArtistMatch {
  DeezerArtistMatch._();

  /// How many of the artist's songs are tried, one search each.
  static const maxSongs = 3;

  /// The query that finds [title] by [artist]. Deezer's field syntax
  /// (`artist:"…"`) finds nothing any more: the plain words do.
  static String query(String artist, String title) =>
      '${artist.trim()} ${title.trim()}'.replaceAll('"', '');

  /// The photo of [artist] among the song [results] of a search for
  /// [title], or null when no result is that song by that artist, or when
  /// the artist has no photo on Deezer.
  static String? photoIn(List<Object?> results, String artist, String title) {
    final name = nameKey(artist);
    final song = titleKey(title);
    if (name.isEmpty || song.isEmpty) return null;
    for (final result in results) {
      if (result is! Map) continue;
      final by = result['artist'];
      if (by is! Map || nameKey('${by['name'] ?? ''}') != name) continue;
      final found = result['title_short'] ?? result['title'];
      if (found is! String || titleKey(found) != song) continue;
      return pictureOf(by);
    }
    return null;
  }

  /// The largest picture of a Deezer artist, or null for the silhouette
  /// Deezer shows when it has none: its URL has an empty image hash
  /// (`/images/artist//1000x1000-…`).
  static String? pictureOf(Map<Object?, Object?> artist) {
    for (final size in const ['picture_xl', 'picture_big', 'picture_medium']) {
      final url = artist[size];
      if (url is String && _hashed.hasMatch(url)) return url;
    }
    return null;
  }

  /// An artist name as compared: no case, accents nor punctuation.
  static String nameKey(String name) => _plain(name);

  /// A song title as compared: [nameKey], without bracketed parts, what
  /// follows " - " or a featured artist, so "Song (Radio Edit)" and
  /// "Song - Remastered" are "Song".
  static String titleKey(String title) {
    var core = title.toLowerCase().replaceAll(_brackets, '');
    core = core.split(' - ').first;
    core = core.split(_featuring).first;
    return _plain(core);
  }

  static String _plain(String text) {
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      out.write(_accents[char] ?? char);
    }
    return out
        .toString()
        // Combining marks (a decomposed accent, Arabic vowel signs) belong
        // to their letter: dropped, not taken for a space.
        .replaceAll(_marks, '')
        .replaceAll('&', ' and ')
        .replaceAll(_punctuation, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
  }

  static final _hashed = RegExp(r'/images/artist/[0-9a-f]{32}/');
  static final _brackets = RegExp(r'\s*[\(\[][^\)\]]*[\)\]]');
  static final _featuring = RegExp(r'\s+(?:feat\.?|ft\.?|featuring)\s+');
  static final _marks = RegExp(r'\p{M}+', unicode: true);
  static final _punctuation = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _spaces = RegExp(r'\s+');

  static const _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
    'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', //
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', //
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', //
    'ā': 'a', 'ą': 'a', 'ă': 'a', 'ć': 'c', 'č': 'c', 'ď': 'd', 'đ': 'd', //
    'ē': 'e', 'ę': 'e', 'ě': 'e', 'ğ': 'g', 'ī': 'i', 'ı': 'i', 'ł': 'l', //
    'ń': 'n', 'ň': 'n', 'ō': 'o', 'ő': 'o', 'ř': 'r', 'ś': 's', 'š': 's', //
    'ş': 's', 'ș': 's', 'ť': 't', 'ţ': 't', 'ț': 't', 'ū': 'u', 'ů': 'u', //
    'ű': 'u', 'ź': 'z', 'ż': 'z', 'ž': 'z', //
    'œ': 'oe', 'æ': 'ae', 'ß': 'ss', '’': "'",
  };
}
