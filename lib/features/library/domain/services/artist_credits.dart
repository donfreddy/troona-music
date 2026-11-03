import 'package:troona/features/library/domain/services/track_tags.dart';

/// Reads the artists credited in the artist tags of a library.
///
/// Downloaded songs credit their guests in the artist tag, the way Spotify
/// lists them: "Nicki Minaj, Beyoncé", or "Chiké feat Mohbad". Android keeps
/// that text as one artist, so every collaboration was an artist of its own.
///
/// "feat." and "ft." always separate artists. A comma separates them only
/// when one of the names around it is known as an artist of its own: a
/// whole tag ("Nicki Minaj"), or a name set apart by a known one ("Qing
/// Madi, BNXN" makes BNXN known, then "BNXN, Sarz" makes Sarz known).
///
/// A whole tag with a comma and no known name in it ("Tyler, The Creator")
/// is taken for one artist, and stays one inside longer lists ("Tyler, The
/// Creator, Kali Uchis"). It is cut again only if one of its parts is set
/// apart by a list it is not in. "&", "/" and "x" never separate: "Simon &
/// Garfunkel" and "AC/DC" are one artist.
final class ArtistCredits {
  /// Lower-case names known as artists of their own.
  final Set<String> _known;

  /// Lower-case comma names taken for one artist, as lists of parts, the
  /// longest first.
  final List<List<String>> _compounds;

  ArtistCredits._(this._known, this._compounds);

  /// Learns the names [tags] (every artist tag of the library) show.
  factory ArtistCredits.of(Iterable<String> tags) {
    final sides = [for (final tag in tags) ..._sides(tag)];
    final solo = <String>{};
    final lists = <List<String>>[];
    for (final side in sides) {
      final names = [for (final n in _commaNames(side)) n.toLowerCase()];
      if (names.length == 1) {
        solo.add(names.single);
      } else if (names.length > 1) {
        lists.add(names);
      }
    }
    solo.removeAll(TrackTags.unknownArtistNames);

    // Whole comma tags without a known name: candidates for one artist.
    final compounds = <String, List<String>>{
      for (final names in lists)
        if (!names.any(solo.contains)) names.join(', '): names,
    };

    while (true) {
      final known = Set.of(solo);
      final longestFirst = _longestFirst(compounds.values);
      final units = [for (final names in lists) _units(names, longestFirst)];
      var grown = true;
      while (grown) {
        grown = false;
        for (final list in units) {
          if (list.any(known.contains) && !list.every(known.contains)) {
            known.addAll(list);
            grown = true;
          }
        }
      }
      // A part set apart on its own means the compound was two artists.
      final cut = compounds.keys
          .where((c) => compounds[c]!.any(known.contains))
          .toList();
      if (cut.isEmpty) {
        known.removeAll(TrackTags.unknownArtistNames);
        return ArtistCredits._(known, longestFirst);
      }
      cut.forEach(compounds.remove);
    }
  }

  /// The artists [tag] names, in order and without repeats. A missing
  /// artist gives `[TrackTags.unknownArtist]`.
  List<String> split(String tag) {
    final names = <String>[];
    final seen = <String>{};
    for (final side in _sides(tag)) {
      final parts = _commaNames(side);
      final lower = [for (final p in parts) p.toLowerCase()];
      final units = _units(lower, _compounds);
      final separate = units.length > 1 && units.any(_known.contains);
      final split = <String>[];
      if (separate) {
        var at = 0;
        for (final unit in units) {
          final size = ', '.allMatches(unit).length + 1;
          split.add(parts.sublist(at, at + size).join(', '));
          at += size;
        }
      } else {
        split.add(parts.join(', '));
      }
      for (final name in split) {
        if (TrackTags.isUnknownArtist(name)) continue;
        if (seen.add(name.toLowerCase())) names.add(name);
      }
    }
    return names.isEmpty ? const [TrackTags.unknownArtist] : names;
  }

  static List<List<String>> _longestFirst(Iterable<List<String>> compounds) =>
      compounds.toList()..sort((a, b) => b.length.compareTo(a.length));

  /// [names] (lower case) with each run that spells one of [longestFirst]
  /// joined back into one name.
  static List<String> _units(
    List<String> names,
    List<List<String>> longestFirst,
  ) {
    final units = <String>[];
    var i = 0;
    while (i < names.length) {
      final match = longestFirst
          .where((c) => _startsAt(names, i, c))
          .firstOrNull;
      if (match == null) {
        units.add(names[i]);
        i++;
      } else {
        units.add(match.join(', '));
        i += match.length;
      }
    }
    return units;
  }

  static bool _startsAt(List<String> names, int at, List<String> run) {
    if (at + run.length > names.length) return false;
    for (var k = 0; k < run.length; k++) {
      if (names[at + k] != run[k]) return false;
    }
    return true;
  }

  /// [tag] cut at each "feat.": "A (feat. B)" and "A ft. B" give A and B.
  static List<String> _sides(String tag) => tag
      .replaceAllMapped(_bracketedFeaturing, (m) => ' feat. ${m[1]}')
      .split(_featuring)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  static List<String> _commaNames(String side) =>
      side.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  static const _featWord = r'(?:feat\.?|ft\.?|featuring)';

  /// "feat." as a word between two names: "Little Feat" stays whole.
  static final _featuring = RegExp('\\s+$_featWord\\s+', caseSensitive: false);

  /// "(feat. B)" or "[ft. B]" at any place of the tag.
  static final _bracketedFeaturing = RegExp(
    '\\s*[(\\[]\\s*$_featWord\\s+([^)\\]]+)[)\\]]',
    caseSensitive: false,
  );
}
