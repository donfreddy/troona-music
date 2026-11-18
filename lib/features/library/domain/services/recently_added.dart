import 'package:troona/core/utils/sort_key.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// The songs added last, newest first: Search's suggestions show the first
/// few, and Recently added the whole list. The albums they belong to come
/// in the same order: Home's row shows the first few, Recent albums more.
abstract final class RecentlyAdded {
  /// How many the page lists: enough to scroll back over the last
  /// imports, not the whole library again.
  static const int limit = 100;

  /// How many albums Recent albums lists.
  static const int albumLimit = 50;

  /// [tracks] newest first, at most [limit] of them (all when null). Songs
  /// without a date come last; songs added together by title.
  static List<Track> of(List<Track> tracks, {int? limit}) {
    final keys = <String, String>{};
    String key(String s) => keys[s] ??= sortKey(s);
    final sorted = List.of(tracks)
      ..sort((a, b) {
        final added = (b.dateAdded?.millisecondsSinceEpoch ?? 0).compareTo(
          a.dateAdded?.millisecondsSinceEpoch ?? 0,
        );
        if (added != 0) return added;
        final byTitle = key(a.title).compareTo(key(b.title));
        return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
      });
    return limit == null || sorted.length <= limit
        ? sorted
        : sorted.sublist(0, limit);
  }

  /// The albums of [tracks] newest first, at most [limit] of them (all when
  /// null): an album comes when its newest song does. They are taken from
  /// [albums], the library's own, so a card reads as it does in the
  /// Library (an album's cover and year come from the first of its songs
  /// in the library's order, not the newest).
  static List<Album> albumsOf(
    List<Track> tracks,
    List<Album> albums, {
    int? limit,
  }) {
    final byId = {for (final a in albums) a.id: a};
    final seen = <String>{};
    final newest = <Album>[];
    for (final t in of(tracks)) {
      if (limit != null && newest.length >= limit) break;
      final id = t.albumId.toString();
      if (!seen.add(id)) continue;
      if (byId[id] case final album?) newest.add(album);
    }
    return newest;
  }
}
