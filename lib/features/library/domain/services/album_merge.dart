import 'package:troona/features/library/domain/services/track_tags.dart';

/// A song as [AlbumMerge] sees it: its MediaStore album, the album name and
/// the ids of the artists it credits, the first one first.
typedef AlbumMember = ({int albumId, String album, List<int> artistIds});

/// Puts back together albums that Android split.
///
/// Without an album artist tag, MediaStore makes one album per album name
/// and folder. Downloaders save an album in batches, one folder each
/// ("Album", "Album (1)", "Album (2)"), and a playlist of singles saves each
/// song in its own folder: one album shows up as several.
///
/// MediaStore albums are only ever joined, never cut: a compilation, whose
/// songs share no artist, stays the album Android made of its folder. Two
/// of them join when they have the same name and share an artist credited
/// on every song of each.
abstract final class AlbumMerge {
  AlbumMerge._();

  /// The album id of each of [members], in order.
  ///
  /// An album with an artist gets a [TrackTags.stableId] of its name and
  /// lead artist (the one credited first on most of its songs), so the id
  /// stays the same however many folders it spans and as folders come and
  /// go. A compilation keeps its MediaStore id.
  static List<int> albumIds(List<AlbumMember> members) {
    final groups = <int, _Group>{};
    for (final (index, m) in members.indexed) {
      final artists = {
        for (final id in m.artistIds)
          if (id != TrackTags.unknownArtistId) id,
      };
      final group = groups[m.albumId] ??= _Group(m.albumId, _key(m.album));
      group.members.add(index);
      group.artists = group.artists?.intersection(artists) ?? artists;
    }

    // Groups of one name sharing an artist are one album, however they
    // chain: {A, B} and {A} and {B} are one.
    final byName = <String, List<_Group>>{};
    for (final g in groups.values) {
      byName.putIfAbsent(g.name, () => []).add(g);
    }
    for (final sameName in byName.values) {
      for (var i = 0; i < sameName.length; i++) {
        for (var j = i + 1; j < sameName.length; j++) {
          final a = sameName[i], b = sameName[j];
          if (a.artists!.any(b.artists!.contains)) a.join(b);
        }
      }
    }

    final albums = <_Group, List<_Group>>{};
    for (final g in groups.values) {
      albums.putIfAbsent(g.root, () => []).add(g);
    }

    final ids = List<int>.filled(members.length, 0);
    for (final album in albums.values) {
      final lead = _lead(album, members);
      final id = lead == null
          ? album.first.albumId
          : TrackTags.stableId('${album.first.name}\u0000$lead');
      for (final group in album) {
        for (final index in group.members) {
          ids[index] = id;
        }
      }
    }
    return ids;
  }

  /// The artist credited first on most songs of [album], among those its
  /// MediaStore albums share; the smallest id on a tie. Null for a
  /// compilation.
  static int? _lead(List<_Group> album, List<AlbumMember> members) {
    final candidates = {for (final g in album) ...g.artists!};
    if (candidates.isEmpty) return null;
    final firsts = <int, int>{};
    for (final g in album) {
      for (final index in g.members) {
        final first = members[index].artistIds.firstOrNull;
        if (first != null && candidates.contains(first)) {
          firsts[first] = (firsts[first] ?? 0) + 1;
        }
      }
    }
    int? best;
    for (final id in candidates) {
      final count = firsts[id] ?? 0;
      final bestCount = best == null ? -1 : firsts[best] ?? 0;
      if (count > bestCount || (count == bestCount && id < best!)) best = id;
    }
    return best;
  }

  /// [album] as compared: case, spaces around and runs of spaces ignored.
  static String _key(String album) =>
      album.trim().toLowerCase().replaceAll(_spaces, ' ');

  static final _spaces = RegExp(r'\s+');
}

/// The songs of one MediaStore album, and the album it belongs to.
final class _Group {
  final int albumId;
  final String name;
  final members = <int>[];

  /// The artists credited on every song of the group.
  Set<int>? artists;

  _Group? _parent;

  _Group(this.albumId, this.name);

  _Group get root {
    var g = this;
    while (g._parent != null) {
      g = g._parent!;
    }
    return g;
  }

  void join(_Group other) {
    final a = root, b = other.root;
    if (!identical(a, b)) b._parent = a;
  }
}
