import 'package:troona/core/utils/sort_key.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// The songs added last, newest first: Search's suggestions show the first
/// few, and Recently added the whole list.
abstract final class RecentlyAdded {
  /// How many the page lists: enough to scroll back over the last
  /// imports, not the whole library again.
  static const int limit = 100;

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
}
