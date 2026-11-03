import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';
import 'package:troona/features/library/presentation/bloc/similar_artists/similar_artists_cubit.dart';

Artist _a(String id) =>
    Artist(id: id, name: 'Artist $id', albumCount: 0, trackCount: 1);

/// Holds each lookup until the test completes it.
final class _Repo implements ArtistDetailRepository {
  final lookups = <Completer<Either<Failure, List<Artist>>>>[];

  @override
  Future<Either<Failure, List<Artist>>> getArtistsByNames(List<String> names) {
    final lookup = Completer<Either<Failure, List<Artist>>>();
    lookups.add(lookup);
    return lookup.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'the artists found, in order, without the one whose page it is',
    () async {
      final repo = _Repo();
      final cubit = SimilarArtistsCubit(repo: repo);
      final done = cubit.load(['a', 'b', 'c'], exceptId: '2');
      repo.lookups.single.complete(right([_a('1'), _a('2'), _a('3')]));
      await done;
      expect([for (final a in cubit.state) a.id], ['1', '3']);
    },
  );

  test('a lookup that fails shows nothing', () async {
    final repo = _Repo();
    final cubit = SimilarArtistsCubit(repo: repo);
    final done = cubit.load(['a'], exceptId: '9');
    repo.lookups.single.complete(left(const DatabaseFailure('down')));
    await done;
    expect(cubit.state, isEmpty);
  });

  test('a later lookup wins over one that answers late', () async {
    final repo = _Repo();
    final cubit = SimilarArtistsCubit(repo: repo);
    final first = cubit.load(['a'], exceptId: '9');
    final second = cubit.load(['b'], exceptId: '9');
    repo.lookups[1].complete(right([_a('2')]));
    await second;
    repo.lookups[0].complete(right([_a('1')]));
    await first;
    expect([for (final a in cubit.state) a.id], ['2']);
  });

  test('an answer after the page closed is dropped', () async {
    final repo = _Repo();
    final cubit = SimilarArtistsCubit(repo: repo);
    final done = cubit.load(['a'], exceptId: '9');
    await cubit.close();
    repo.lookups.single.complete(right([_a('1')]));
    await expectLater(done, completes);
  });
}
