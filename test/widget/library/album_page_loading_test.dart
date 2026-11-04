import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/album_detail_page.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/metadata/presentation/cubit/album_metadata_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';

const _album = Album(
  id: '7',
  name: 'Love, Damini',
  artist: 'Burna Boy',
  artistId: 1,
  trackCount: 19,
  year: 2022,
);

/// Loads only once [release] completes: the page's first frames.
class _SlowAlbums implements AlbumDetailRepository {
  final release = Completer<void>();

  @override
  Future<Either<Failure, Album>> getAlbumById(String id) async {
    await release.future;
    return right(_album);
  }

  @override
  Future<Either<Failure, List<Track>>> getTracksByAlbumId(int id) async =>
      right(const []);

  @override
  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(int id) async =>
      right(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoMetadata implements MetadataRepository {
  @override
  Stream<String> get onArtistArtworkUpdated => const Stream.empty();

  @override
  Future<AlbumOnlineInfo?> getAlbumInfo(
    String artistName,
    String albumName, {
    bool forceRefresh = false,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedLibrary extends Fake implements LibraryRepository {
  @override
  void cancelScan() {}
}

/// The shell's library, already loaded with [albums].
LibraryBloc _library(List<Album> albums) {
  final bloc = LibraryBloc(
    scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
    getTracks: GetTracksUseCase(_UnusedLibrary()),
  );
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  bloc.emit(
    LibraryLoaded(
      allTracks: const [],
      allAlbums: albums,
      allArtists: const [],
      visibleTracks: const [],
      visibleAlbums: albums,
      visibleArtists: const [],
    ),
  );
  return bloc;
}

void main() {
  setUp(
    () => getIt.registerFactory<AlbumMetadataCubit>(
      () => AlbumMetadataCubit(repo: _NoMetadata()),
    ),
  );
  tearDown(getIt.reset);

  Future<_SlowAlbums> open(WidgetTester tester, List<Album> library) async {
    final albums = _SlowAlbums();
    final bloc = AlbumDetailBloc(repo: albums)..add(AlbumDetailRequested(7));
    final libraryBloc = _library(library);
    final palette = TrackPaletteCubit();
    addTearDown(() async {
      if (!albums.release.isCompleted) albums.release.complete();
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(libraryBloc.close());
      unawaited(palette.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AlbumDetailBloc>.value(value: bloc),
          BlocProvider<LibraryBloc>.value(value: libraryBloc),
          BlocProvider<TrackPaletteCubit>.value(value: palette),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlbumDetailPage(id: '7'),
        ),
      ),
    );
    await tester.pump();
    expect(bloc.state, isA<AlbumDetailLoading>());
    return albums;
  }

  testWidgets('while its songs load, the page already shows the cover the '
      'card flies to, and keeps it once they are in', (tester) async {
    final albums = await open(tester, [_album]);
    expect(find.byType(AlbumCoverHero), findsOneWidget);
    expect(find.text('Love, Damini'), findsWidgets);
    final landing = tester.element(find.byType(AlbumCoverHero));

    albums.release.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.element(find.byType(AlbumCoverHero)),
      same(landing),
      reason: 'the cover was rebuilt: a flight landing on it would be cut',
    );
  });

  testWidgets('an album the library does not hold yet waits on a spinner', (
    tester,
  ) async {
    await open(tester, const []);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AlbumCoverHero), findsNothing);
  });
}
