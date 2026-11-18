import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/artist_songs.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';

import '../../helpers/fake_player.dart';

/// Answers each read as told.
class _Repo extends Fake implements ArtistDetailRepository {
  bool songsFail = false;
  bool albumsFail = false;

  static const _failure = DatabaseFailure('unreadable');

  @override
  Future<Either<Failure, Artist>> getArtistById(String id) async =>
      right(Artist(id: id, name: 'Khaid', albumCount: 1, trackCount: 1));

  @override
  Future<Either<Failure, ArtistSongs>> getTopTracksByArtistId(
    String id,
  ) async => songsFail
      ? left(_failure)
      : right(ArtistSongs(tracks: [testTrack('a', durationMs: 1000)]));

  @override
  Future<Either<Failure, ArtistAlbums>> getAlbumsByArtistId(String id) async =>
      albumsFail ? left(_failure) : right(const ArtistAlbums());
}

void main() {
  late _Repo repo;
  late ArtistDetailBloc bloc;

  setUp(() {
    repo = _Repo();
    bloc = ArtistDetailBloc(repo: repo);
  });
  tearDown(() => bloc.close());

  Future<ArtistDetailState> load() async {
    bloc.add(const ArtistDetailRequested(1));
    await pumpEventQueue();
    return bloc.state;
  }

  test(
    'songs that cannot be read: an error, not an artist with none',
    () async {
      repo.songsFail = true;
      expect(await load(), isA<ArtistDetailError>());
    },
  );

  test('albums that cannot be read: an error too', () async {
    repo.albumsFail = true;
    expect(await load(), isA<ArtistDetailError>());
  });

  test('a reload that fails keeps the page shown', () async {
    final shown = await load();
    expect(shown, isA<ArtistDetailLoaded>());
    repo.songsFail = true;
    expect(await load(), same(shown));
  });
}
