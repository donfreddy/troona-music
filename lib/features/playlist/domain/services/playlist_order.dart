/// Moves a song of a playlist by the places the page shows.
///
/// A playlist stores songs the page does not show: one a folder turned off
/// or the shortest length leaves out, one whose file is gone. They keep
/// their place among the others, so letting them back in finds them where
/// they were. The page numbers only the songs it shows, so its places are
/// mapped onto the stored list.
abstract final class PlaylistOrder {
  /// [stored] with the song shown at [from] moved to [to], both places
  /// among the songs for which [shown] holds, [to] counted once the song
  /// is taken out (as a reorderable list reports it). Null when either
  /// place is out of range.
  static List<String>? move(
    List<String> stored,
    bool Function(String id) shown, {
    required int from,
    required int to,
  }) {
    final places = [
      for (final (i, id) in stored.indexed)
        if (shown(id)) i,
    ];
    if (from < 0 || from >= places.length) return null;
    if (to < 0 || to >= places.length) return null;
    final order = [...stored];
    final taken = places[from];
    final song = order.removeAt(taken);
    final others = [
      for (final (i, p) in places.indexed)
        if (i != from) p > taken ? p - 1 : p,
    ];
    // Before the song shown at [to] once it is out, or just after the last
    // one shown when it goes to the end.
    final at = to < others.length ? others[to] : others.last + 1;
    return order..insert(at, song);
  }
}
