import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/track_stats.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/domain/use_cases/smart_playlist_source.dart';

/// A library of [tracks]; [fails] makes its read fail.
final class FakeSmartLibrary implements LibraryRepository {
  FakeSmartLibrary(this.tracks);

  List<Track> tracks;
  bool fails = false;
  int reads = 0;

  @override
  Future<Either<Failure, List<Track>>> getTracks() async {
    reads++;
    return fails
        ? left(const DatabaseFailure('library'))
        : right(List.of(tracks));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Plays held as [stats]; [plays] fires as a recorded play would.
final class FakeSmartHistory implements PlayHistoryRepository {
  TrackStats stats = TrackStats.empty;
  bool fails = false;
  final plays = StreamController<void>.broadcast(sync: true);

  @override
  Future<Either<Failure, TrackStats>> trackStats() async =>
      fails ? left(const DatabaseFailure('history')) : right(stats);

  @override
  Stream<void> get changes => plays.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Playlists held in memory, as the database stores them: a smart one
/// takes no song.
final class MemoryPlaylists implements PlaylistRepository {
  final stored = <String, Playlist>{};
  final created = <Playlist>[];
  final deleted = <String>[];
  bool failAdds = false;
  int _next = 0;

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylists() async =>
      right(stored.values.toList());

  /// Likes always exists, as the data source makes sure; [failLikes] makes
  /// its read fail.
  bool failLikes = false;

  @override
  Future<Either<Failure, Playlist>> getPlaylistById(String id) async {
    if (id == Playlist.likesId) {
      if (failLikes) return left(const DatabaseFailure('likes'));
      return right(
        stored[id] ?? const Playlist(id: Playlist.likesId, name: 'Likes'),
      );
    }
    return stored[id] == null
        ? left(const DatabaseFailure('Playlist not found'))
        : right(stored[id]!);
  }

  /// Stored songs are not kept here: a playlist of songs reads none, and a
  /// smart one must never ask.
  @override
  Future<Either<Failure, List<Track>>> getTracksByPlaylistId(String id) async {
    if (stored[id]?.isSmart ?? false) {
      throw StateError('a smart playlist never reads stored songs');
    }
    return right(const []);
  }

  @override
  Future<Either<Failure, Playlist>> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
    SmartRules? rules,
  }) async {
    final playlist = Playlist(id: 'new${_next++}', name: title, rules: rules);
    stored[playlist.id] = playlist;
    created.add(playlist);
    return right(playlist);
  }

  @override
  Future<Either<Failure, Unit>> updatePlaylist(Playlist playlist) async {
    stored[playlist.id] = playlist;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deletePlaylist(String id) async {
    stored.remove(id);
    deleted.add(id);
    return right(unit);
  }

  @override
  Future<Either<Failure, List<String>>> addTracksToPlaylist(
    String playlistId,
    List<String> trackIds,
  ) async {
    if (failAdds) return left(const DatabaseFailure('write'));
    final playlist = stored[playlistId]!;
    if (playlist.isSmart) return right(const []);
    final added = [
      for (final id in trackIds)
        if (!playlist.trackIds.contains(id)) id,
    ];
    stored[playlistId] = Playlist(
      id: playlist.id,
      name: playlist.name,
      trackIds: [...playlist.trackIds, ...added],
    );
    return right(added);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A source reading [library], [history] and [playlists] on day [today].
SmartPlaylistSource fakeSmartSource({
  required FakeSmartLibrary library,
  required FakeSmartHistory history,
  required MemoryPlaylists playlists,
  DateTime? now,
}) => SmartPlaylistSource(
  library: library,
  history: history,
  playlists: playlists,
  now: () => now ?? DateTime(2026, 11, 20, 12),
);
