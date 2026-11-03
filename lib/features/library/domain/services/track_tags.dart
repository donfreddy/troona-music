/// Cleans what a file's tags say about who made it.
///
/// Songs downloaded from the internet often have no artist tag: Android then
/// reports `<unknown>`, and their title is the file name ("Artist - Title").
abstract final class TrackTags {
  TrackTags._();

  /// Stored for a song without an artist; shown as "Unknown artist".
  static const unknownArtist = '';

  /// What Android, taggers and earlier versions of the app write for a
  /// missing artist, in lower case.
  static const unknownArtistNames = {
    '',
    '<unknown>',
    '[unknown]',
    'unknown',
    'unknown artist',
  };

  static bool isUnknownArtist(String? artist) =>
      unknownArtistNames.contains(artist?.trim().toLowerCase() ?? '');

  /// [raw] trimmed, or [unknownArtist].
  static String artist(String? raw) =>
      isUnknownArtist(raw) ? unknownArtist : raw!.trim();

  /// The artist and title of an "Artist - Title" name, or null when [name]
  /// does not clearly hold both.
  ///
  /// Noise is dropped first: a leading track number ("01 - ", "05 ",
  /// "Track 01 - "), brackets that hold only tags such as "(Official
  /// Video)" or "[320kbps]", and site names. In doubt it returns null:
  /// "Unknown artist" is better than a title shown as the artist.
  static ({String artist, String title})? fromName(String name) {
    var text = name.trim();
    if (!text.contains(' ')) text = text.replaceAll('_', ' ');
    text = text
        .replaceAll(_noiseInBrackets, ' ')
        .replaceAll(_siteName, ' ')
        .replaceAll(_spaces, ' ')
        .trim()
        .replaceFirst(_trackNumber, '');

    final separator = _separator.firstMatch(text);
    if (separator == null) return null;
    final artist = _trimDashes(text.substring(0, separator.start));
    final title = _trimDashes(text.substring(separator.end));
    if (artist.isEmpty || title.isEmpty) return null;
    if (_digits.hasMatch(artist) ||
        _numbering.hasMatch(artist) ||
        isUnknownArtist(artist)) {
      return null;
    }
    return (artist: artist, title: title);
  }

  /// The id of the artist named [artist], whatever its case and spacing.
  /// Artists are grouped by name, not by MediaStore id: Android gives every
  /// distinct artist tag an id, so "A" and "A, B" were two artists, and
  /// every song without a tag shared one.
  static int artistIdFor(String artist) =>
      stableId(artist.trim().toLowerCase().replaceAll(_spaces, ' '));

  /// The id of a song without an artist.
  static final unknownArtistId = artistIdFor(unknownArtist);

  /// A negative id that stays the same for [key] from one run to the next,
  /// so it can be stored. Negative: MediaStore ids are positive, so an id
  /// made here never meets one of them.
  static int stableId(String key) {
    // 64-bit FNV-1a: String.hashCode is not guaranteed to stay the same
    // between runs, and 32 bits give likely collisions past ten thousand
    // names. Dart ints wrap on overflow, which is the modulo FNV needs.
    var hash = 0xcbf29ce484222325;
    for (final unit in key.codeUnits) {
      hash = (hash ^ unit) * 0x100000001b3;
    }
    return -(hash & 0x7fffffffffffffff) - 1;
  }

  /// A hyphen, minus or any dash, between spaces.
  static final _separator = RegExp('\\s+[-\u2010-\u2015\u2212]\\s+');

  static final _dashes = RegExp(
    '^[\\s\\-\u2010-\u2015\u2212]+|[\\s\\-\u2010-\u2015\u2212]+\$',
  );

  /// "01 - ", "01. ", "1) ", "05 " or "Track 01 - " at the start. A number
  /// alone followed by a space is a name ("50 Cent"), unless it is padded
  /// with a zero.
  static final _trackNumber = RegExp(
    r'^(?:(?:track|cd|disc)\s*\d{1,3}\s*[.)\-]?\s*)?'
    r'(?:\d{1,3}\s*[.)\-]\s*|0\d\s+)?',
    caseSensitive: false,
  );

  /// "Part 1", "Act I", "Episode 3": the name of a section, not an artist.
  static final _numbering = RegExp(
    r'^(?:track|part|chapter|disc|cd|act|episode|vol(?:ume)?)\.?\s*'
    r'(?:\d+|[ivxlc]+)$',
    caseSensitive: false,
  );

  static final _digits = RegExp(r'^\d+$');
  static final _spaces = RegExp(r'\s+');

  /// A tag-only word: what sites append to a title, never part of it.
  static const _noiseWord =
      r'(?:official|officiel(?:le)?|music|lyrics?|paroles|vid[eé]o|audio|'
      r'clip|visuali[sz]er|hd|hq|4k|\d{2,3}\s?kbps|mp3|m4a|free\s+download|'
      r'(?:www\.)?[a-z0-9-]+\.(?:com|net|org|info|io|co|me|biz|tv))';

  /// A bracket made only of tag words: "(Official Music Video)" goes,
  /// "(Live at the Video Music Awards)" stays.
  static final _noiseInBrackets = RegExp(
    '[\\(\\[\\{]\\s*$_noiseWord(?:[\\s\\-|/,&]+$_noiseWord)*\\s*[\\)\\]\\}]',
    caseSensitive: false,
  );

  static final _siteName = RegExp(
    r'\b(www\.)?[a-z0-9-]+\.(com|net|org|info|io|biz|tv)\b',
    caseSensitive: false,
  );

  static String _trimDashes(String text) => text.replaceAll(_dashes, '');
}
