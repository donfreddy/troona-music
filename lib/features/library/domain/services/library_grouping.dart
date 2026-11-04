import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/single_release.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

/// Builds albums and artists from tracks, keyed by the ids the detail pages
/// query with. Grouping by name merged distinct albums that share a title
/// ("Greatest Hits") and linked to only one of them.
///
/// Every screen that shows albums or artists builds them here, so a count
/// or an artist name reads the same everywhere.
abstract final class LibraryGrouping {
  LibraryGrouping._();

  /// The albums of [tracks], in the order their first song comes.
  static List<Album> albumsOf(List<Track> tracks) {
    final groups = <int, List<Track>>{};
    for (final t in tracks) {
      groups.putIfAbsent(t.albumId, () => []).add(t);
    }
    return [for (final group in groups.values) _album(group)];
  }

  /// The albums [tracks] hold that credit the artist [artistId]: their own
  /// albums and singles (they are the album's artist) and the ones they
  /// appear on. [tracks] are the whole albums, so counts are the albums'
  /// own.
  ///
  /// Each list comes newest first, then the albums without a year in the
  /// order their first song comes.
  static ArtistAlbums albumsOfArtist(int artistId, List<Track> tracks) {
    final own = <Album>[];
    final singles = <Album>[];
    final appearsOn = <Album>[];
    final groups = <int, List<Track>>{};
    for (final t in tracks) {
      groups.putIfAbsent(t.albumId, () => []).add(t);
    }
    for (final group in groups.values) {
      if (!group.any((t) => _credits(t, artistId))) continue;
      final album = _album(group);
      if (!_sharedCredits(group).any((c) => c.id == artistId)) {
        appearsOn.add(album);
      } else if (album.isSingle) {
        singles.add(album);
      } else {
        own.add(album);
      }
    }
    return ArtistAlbums(
      own: _newestFirst(own),
      singles: _newestFirst(singles),
      appearsOn: _newestFirst(appearsOn),
    );
  }

  /// The artists of [tracks], in the order their first song comes.
  ///
  /// An artist only ever credited as a guest is left out unless [guests]:
  /// a playlist of collaborations would otherwise list dozens of artists
  /// with one song each. Their songs still count for them, and their page
  /// opens from search.
  static List<Artist> artistsOf(List<Track> tracks, {bool guests = false}) {
    final owned = _ownedCounts(tracks);
    final names = <int, String>{};
    final songs = <int, List<Track>>{};
    final leads = <int>{};
    for (final t in tracks) {
      leads.add(t.credits.first.id);
      for (final credit in t.credits) {
        names.putIfAbsent(credit.id, () => credit.name);
        songs.putIfAbsent(credit.id, () => []).add(t);
      }
    }
    return [
      for (final MapEntry(key: id, value: group) in songs.entries)
        if (guests || leads.contains(id)) _artist(id, names[id]!, group, owned),
    ];
  }

  /// The artist [artistId] as [tracks] show it, or null when none of them
  /// credits the artist. [tracks] are the whole albums the artist is on,
  /// so their own albums can be told from the ones they appear on.
  static Artist? artistOf(int artistId, List<Track> tracks) {
    final group = [
      for (final t in tracks)
        if (_credits(t, artistId)) t,
    ];
    if (group.isEmpty) return null;
    final name = group.first.credits.firstWhere((c) => c.id == artistId).name;
    return _artist(artistId, name, group, _ownedCounts(tracks));
  }

  /// How many albums and singles of [tracks] each artist owns: they are
  /// the album's artist.
  static ({Map<int, int> albums, Map<int, int> singles}) _ownedCounts(
    List<Track> tracks,
  ) {
    final groups = <int, List<Track>>{};
    for (final t in tracks) {
      groups.putIfAbsent(t.albumId, () => []).add(t);
    }
    final albums = <int, int>{};
    final singles = <int, int>{};
    for (final group in groups.values) {
      final counts = _isSingle(group) ? singles : albums;
      for (final credit in _sharedCredits(group)) {
        counts[credit.id] = (counts[credit.id] ?? 0) + 1;
      }
    }
    return (albums: albums, singles: singles);
  }

  /// The artist line to show under [track] on the page of an album by
  /// [albumArtist], or null when the album's artist says it all.
  ///
  /// A compilation names every song's artist. On an artist's album, a song
  /// with guests names them, unless its title already does: downloaded
  /// songs read "Feeling Myself (feat. Beyoncé)".
  static String? creditLine(Track track, String albumArtist) {
    if (TrackTags.isUnknownArtist(albumArtist)) {
      return TrackTags.isUnknownArtist(track.artist) ? null : track.artist;
    }
    final owners = {
      for (final name in albumArtist.split(', ')) name.toLowerCase(),
    };
    final title = track.title.toLowerCase();
    final unnamed = track.credits.where(
      (c) =>
          !owners.contains(c.name.toLowerCase()) &&
          !TrackTags.isUnknownArtist(c.name) &&
          !title.contains(c.name.toLowerCase()),
    );
    return unnamed.isEmpty ? null : track.artist;
  }

  static Album _album(List<Track> group) {
    final artists = _sharedCredits(group);
    return Album(
      id: group.first.albumId.toString(),
      name: group.first.album,
      artist: artists.isEmpty
          ? TrackTags.unknownArtist
          : artists.map((c) => c.name).join(', '),
      artistId: artists.isEmpty ? TrackTags.unknownArtistId : artists.first.id,
      trackCount: group.length,
      artworkPath: _firstArtwork(group),
      isSingle: _isSingle(group),
      year: _yearOf(group),
    );
  }

  /// [albums] by year, newest first; the ones without a year last, in
  /// their order ([List.sort] alone is not stable).
  static List<Album> _newestFirst(List<Album> albums) {
    final order = {for (final (i, album) in albums.indexed) album: i};
    int compare(Album a, Album b) {
      final byYear = (b.year ?? 0).compareTo(a.year ?? 0);
      return byYear != 0 ? byYear : order[a]!.compareTo(order[b]!);
    }

    return [...albums]..sort(compare);
  }

  /// The first year a song of [group] has, as the album page shows it.
  static int? _yearOf(List<Track> group) {
    for (final t in group) {
      if (t.year case final year? when year > 0) return year;
    }
    return null;
  }

  static bool _isSingle(List<Track> group) => SingleRelease.matches(
    group.first.album,
    [for (final t in group) t.title],
  );

  static Artist _artist(
    int id,
    String name,
    List<Track> group,
    ({Map<int, int> albums, Map<int, int> singles}) owned,
  ) => Artist(
    id: id.toString(),
    name: TrackTags.artist(name),
    albumCount: owned.albums[id] ?? 0,
    singleCount: owned.singles[id] ?? 0,
    trackCount: group.length,
    artworkPath: _firstArtwork(group),
  );

  /// The artists credited on every song of [group], in the first song's
  /// order: an album's artist. None for a compilation, or for a folder of
  /// downloads Android took for an album: crediting it to its first song's
  /// artist would be wrong.
  ///
  /// An album of one song belongs to the artist credited first: every one
  /// of its credits is on all its songs, and its guests ("Medusa (feat.
  /// Khaid)" by Layzee Ella, Khaid) would own it too. Downloaders list the
  /// lead artist first.
  static List<ArtistCredit> _sharedCredits(List<Track> group) {
    var shared = [
      for (final c in group.first.credits)
        if (c.id != TrackTags.unknownArtistId &&
            !TrackTags.isUnknownArtist(c.name))
          c,
    ];
    if (group.length == 1) return shared.take(1).toList();
    for (final t in group.skip(1)) {
      if (shared.isEmpty) break;
      final ids = {for (final c in t.credits) c.id};
      shared = [
        for (final c in shared)
          if (ids.contains(c.id)) c,
      ];
    }
    return shared;
  }

  static bool _credits(Track t, int artistId) =>
      t.credits.any((c) => c.id == artistId);

  /// The first cover found in the group: the first track may have none.
  static String? _firstArtwork(List<Track> group) {
    for (final t in group) {
      if (t.artworkPath != null) return t.artworkPath;
    }
    return null;
  }
}
