/// Tells a single from an album. MediaStore has no release type, and
/// downloaders save every single as an album of its own, named after its
/// song.
abstract final class SingleRelease {
  SingleRelease._();

  /// The most songs a single holds: a song with a remix or a B-side.
  static const maxSongs = 3;

  /// Whether an album named [album], holding the songs [titles], is a
  /// single: at most [maxSongs] songs, and named after one of them.
  ///
  /// Names are compared without case, bracketed parts, what follows " - "
  /// or a featured artist, so "Ghetto (Afrobeat Remix)" is the single of
  /// "Ghetto - Afrobeat Remix". "A / B" names two songs. An album of one
  /// song named otherwise ("Scorcha" holding "Light My Fire") is a song of
  /// a whole album, of which only that song is in the library.
  static bool matches(String album, List<String> titles) {
    if (titles.isEmpty || titles.length > maxSongs) return false;
    final names = {for (final name in album.split(' / ')) _core(name)}
      ..remove('');
    return names.isNotEmpty && titles.map(_core).any(names.contains);
  }

  /// [name] reduced to the part that names the song.
  static String _core(String name) {
    var core = name.toLowerCase().replaceAll('’', "'");
    core = core.replaceAll(_brackets, '');
    core = core.split(' - ').first;
    core = core.split(_featuring).first;
    return core.replaceAll(_spaces, ' ').trim();
  }

  static final _brackets = RegExp(r'\s*[\(\[][^\)\]]*[\)\]]');
  static final _featuring = RegExp(r'\s+(?:feat\.?|ft\.?|featuring|with)\s+');
  static final _spaces = RegExp(r'\s+');
}
