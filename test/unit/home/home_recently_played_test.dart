import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/play_event.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/home/data/repositories/home_repository_impl.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';

TrackModel _model(String id) => TrackModel()
  ..deviceId = id
  ..path = '/music/$id.mp3'
  ..uri = 'content://$id'
  ..title = 'Title $id'
  ..artist = 'Artist'
  ..artistId = 1
  ..album = 'Album'
  ..albumId = 1
  ..genre = 'Genre'
  ..genreId = 0
  ..durationMs = 180000
  ..fileName = '$id.mp3'
  ..trackNumber = 0
  ..size = 1
  ..year = 0
  ..indexedAt = DateTime(2026);

/// [library] in scan order, newest first.
final class _Library implements IsarLibraryDataSource {
  _Library(this.library);
  final List<String> library;

  @override
  Future<List<TrackModel>> getTracksByIds(List<String> ids) async => [
    // Like an Isar `anyOf` query: library order, not the ids' order.
    for (final id in library)
      if (ids.contains(id)) _model(id),
  ];

  @override
  Future<List<TrackModel>> getRecentTracks({int limit = 20}) async => [
    for (final id in library.take(limit)) _model(id),
  ];

  @override
  Future<List<TrackModel>> getUniqueArtists({int limit = 5}) async => [];
  @override
  Future<List<TrackModel>> getUniqueAlbums({int limit = 5}) async => [];
  @override
  Future<List<PlaylistModel>> getPlaylists({int? limit}) async => [];
  @override
  Future<Set<String>> getLikedTrackIds() async => const {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _History implements PlayHistoryRepository {
  _History(this.ids);
  final List<String> ids;
  final changesCtrl = StreamController<void>.broadcast(sync: true);

  @override
  Stream<void> get changes => changesCtrl.stream;

  @override
  Future<Either<Failure, List<String>>> recentTrackIds({
    required int limit,
  }) async => right(ids.take(limit).toList());

  @override
  Future<Either<Failure, Unit>> record(PlayEvent event) async => right(unit);

  @override
  Future<Either<Failure, Map<String, int>>> topTrackIds({
    int days = 7,
    int limit = 5,
  }) async => right({});

  @override
  Future<Either<Failure, List<String>>> forgottenTrackIds(
    Set<String> likedIds, {
    int staleDays = 14,
    int limit = 5,
  }) async => right([]);

  @override
  Future<Either<Failure, int>> totalPlays({int days = 7}) async => right(0);
}

void main() {
  Future<List<String>> recentlyPlayed(
    List<String> history,
    List<String> library,
  ) async {
    final repo = HomeRepositoryImpl(
      db: _Library(library),
      history: _History(history),
    );
    final feed = (await repo.getFeed()).getOrElse(() => throw 'no feed');
    return [for (final t in feed.recentlyPlayed) t.id];
  }

  const library = ['n1', 'n2', 'n3', 'n4', 'p1', 'p2', 'p3', 'p4'];

  test('shows the last played tracks in play order', () async {
    expect(await recentlyPlayed(['p3', 'p1', 'p4', 'p2'], library), [
      'p3',
      'p1',
      'p4',
      'p2',
    ]);
  });

  test('tops up with the newest tracks while little was played', () async {
    expect(await recentlyPlayed(['p2', 'n1'], library), [
      'p2',
      'n1',
      'n2',
      'n3',
    ]);
  });

  test('falls back to the newest tracks with no history', () async {
    expect(await recentlyPlayed([], library), ['n1', 'n2', 'n3', 'n4']);
  });

  test('skips plays of tracks no longer in the library', () async {
    expect(await recentlyPlayed(['gone', 'p1'], library), [
      'p1',
      'n1',
      'n2',
      'n3',
    ]);
  });

  test('plays of deleted tracks give way to older plays', () async {
    expect(
      await recentlyPlayed(['gone1', 'p1', 'gone2', 'p2', 'p3', 'p4'], library),
      ['p1', 'p2', 'p3', 'p4'],
    );
  });

  test('the home feed reloads when a play is recorded', () async {
    final history = _History(['p1']);
    final repo = _CountingRepository(
      HomeRepositoryImpl(db: _Library(library), history: history),
    );
    final bloc = HomeBloc(repo: repo)..add(const HomeFeedRequested());
    await pumpEventQueue();
    expect(repo.feeds, 1);

    history.changesCtrl.add(null);
    await pumpEventQueue();
    expect(repo.feeds, 2);
    expect(bloc.state, isA<HomeLoaded>());

    await bloc.close();
    history.changesCtrl.add(null);
    await pumpEventQueue();
    expect(repo.feeds, 2, reason: 'no reload after close');
  });
}

final class _CountingRepository implements HomeRepository {
  _CountingRepository(this._inner);
  final HomeRepository _inner;
  int feeds = 0;

  @override
  Stream<void> get feedChanges => _inner.feedChanges;

  @override
  Future<Either<Failure, HomeFeed>> getFeed() {
    feeds++;
    return _inner.getFeed();
  }

  @override
  Future<Either<Failure, int>> getTotalTrackCount() async => right(0);
}
