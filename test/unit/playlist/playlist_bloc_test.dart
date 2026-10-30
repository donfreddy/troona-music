import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';

/// Playlists kept in memory, as the database would store them.
final class _Repo implements PlaylistRepository {
  final stored = <String, Playlist>{};

  @override
  Future<Either<Failure, List<Playlist>>> getPlaylists() async =>
      right(stored.values.toList());

  @override
  Future<Either<Failure, Playlist>> getPlaylistById(String id) async =>
      stored[id] == null
      ? left(const DatabaseFailure('Playlist not found'))
      : right(stored[id]!);

  @override
  Future<Either<Failure, Unit>> updatePlaylist(Playlist playlist) async {
    stored[playlist.id] = playlist;
    return right(unit);
  }

  final changes = StreamController<void>.broadcast(sync: true);

  @override
  Stream<void> watchPlaylists() => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repo repo;
  late PlaylistBloc bloc;

  setUp(() {
    repo = _Repo()
      ..stored['p1'] = const Playlist(id: 'p1', name: 'Old', trackIds: ['a']);
    bloc = PlaylistBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  test('renaming updates the name and lists the playlists again', () async {
    bloc.add(const PlaylistRenameRequested('p1', 'New'));
    final state = await bloc.stream.first;

    expect(repo.stored['p1']!.name, 'New');
    expect((state as PlaylistLoaded).playlists.single.name, 'New');
  });

  test('renaming keeps songs added after the list was shown', () async {
    bloc.add(PlaylistListRequested());
    await bloc.stream.first;
    // A song added from another page since the list was loaded.
    repo.stored['p1'] = const Playlist(
      id: 'p1',
      name: 'Old',
      trackIds: ['a', 'b'],
    );

    bloc.add(const PlaylistRenameRequested('p1', 'New'));
    await bloc.stream.first;

    expect(repo.stored['p1']!.trackIds, ['a', 'b']);
  });

  test('renaming a missing playlist reports an error', () async {
    bloc.add(const PlaylistRenameRequested('gone', 'New'));

    expect(await bloc.stream.first, isA<PlaylistError>());
  });

  test('a change made elsewhere lists the playlists again', () async {
    bloc.add(PlaylistListRequested());
    await bloc.stream.firstWhere((s) => s is PlaylistLoaded);
    repo.stored['p2'] = const Playlist(id: 'p2', name: 'Restored');

    repo.changes.add(null);
    await pumpEventQueue();

    expect((bloc.state as PlaylistLoaded).playlists.map((p) => p.name), [
      'Old',
      'Restored',
    ]);
  });
}
