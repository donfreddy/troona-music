import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/artist_photo_hero.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';
import 'package:troona/features/search/presentation/widgets/search_results_view.dart';
import 'package:troona/features/search/presentation/widgets/search_suggestions.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

import '../../helpers/fake_player.dart';

class _Photos implements MetadataRepository {
  String? photo;
  final updates = StreamController<String>.broadcast();

  @override
  Stream<String> get onArtistArtworkUpdated => updates.stream;

  @override
  String? getCachedArtistArtworkPath(String artistId) => photo;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedLibrary extends Fake implements LibraryRepository {
  @override
  void cancelScan() {}
}

const _khaid = Artist(
  id: '1',
  name: 'Khaid',
  albumCount: 1,
  trackCount: 1,
  artworkPath: '/covers/k.jpg',
);
const _photo = '/photos/artists/1.jpg';

void main() {
  late _Photos metadata;

  setUp(() {
    metadata = _Photos();
    getIt.registerSingleton<MetadataRepository>(metadata);
  });
  tearDown(getIt.reset);

  /// The Search tab showing [body], with the pages it can push, and the
  /// Library's, which it must not open.
  late LibraryBloc library;

  Future<GoRouter> search(
    WidgetTester tester,
    Widget body, {
    List<Track> tracks = const [],
    List<Album> albums = const [],
  }) async {
    final (:player, port: _) = await testPlayer(addTearDown);
    library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
      getTracks: GetTracksUseCase(_UnusedLibrary()),
    );
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(
      LibraryLoaded(
        allTracks: tracks,
        allAlbums: albums,
        allArtists: const [_khaid],
        visibleTracks: tracks,
        visibleAlbums: albums,
        visibleArtists: const [_khaid],
      ),
    );
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (_, _) => Scaffold(body: CustomScrollView(slivers: [body])),
          routes: [
            GoRoute(
              path: 'artists/:id',
              builder: (_, state) =>
                  Text('search artist ${state.pathParameters['id']}'),
            ),
            GoRoute(path: 'recent', builder: (_, _) => const Text('recent')),
          ],
        ),
        GoRoute(
          path: '/library',
          builder: (_, _) => const Text('library'),
          routes: [
            GoRoute(
              path: 'artists/:id',
              name: 'artistDetail',
              builder: (_, _) => const Text('library artist'),
            ),
          ],
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(library.close());
      router.dispose();
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: player),
          BlocProvider<LibraryBloc>.value(value: library),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  const results = SearchResultsView(
    result: SearchResult(tracks: [], artists: [_khaid], albums: []),
    query: 'kha',
  );
  Finder showing(String path) =>
      find.byWidgetPredicate((w) => w is ArtworkImage && w.path == path);

  testWidgets('results: the top result and the circle show the downloaded '
      'photo, not the cover', (tester) async {
    metadata.photo = _photo;
    await search(tester, results);
    expect(showing(_photo), findsNWidgets(2));
    expect(showing('/covers/k.jpg'), findsNothing);
    // One of the two carries the flight: two heroes of one artist on a
    // page would share a tag.
    expect(find.byType(ArtistPhotoHero), findsOneWidget);
  });

  testWidgets('results: without a photo, their cover, nothing flies', (
    tester,
  ) async {
    await search(tester, results);
    expect(showing('/covers/k.jpg'), findsNWidgets(2));
    expect(find.byType(ArtistPhotoHero), findsNothing);
  });

  testWidgets('a photo downloaded while the results show comes in', (
    tester,
  ) async {
    await search(tester, results);
    metadata.photo = _photo;
    metadata.updates.add('1');
    await tester.pump(); // the update comes
    await tester.pump(); // and is drawn
    expect(showing(_photo), findsNWidgets(2));
  });

  testWidgets('suggestions: the circles show the downloaded photo too', (
    tester,
  ) async {
    metadata.photo = _photo;
    await search(
      tester,
      const SearchSuggestions(),
      tracks: [testTrack('a', durationMs: 1000)],
    );
    expect(showing(_photo), findsOneWidget);
  });

  testWidgets('a circle opens the artist in the Search tab', (tester) async {
    await search(tester, results);
    await tester.tap(find.text('Khaid').last);
    await tester.pumpAndSettle();
    expect(find.text('search artist 1'), findsOneWidget);
    expect(find.text('library artist'), findsNothing);
  });

  testWidgets("Recently added's See all opens its page in the Search tab, "
      'not the Library', (tester) async {
    await search(
      tester,
      const SearchSuggestions(),
      tracks: [testTrack('a', durationMs: 1000)],
    );
    final seeAll = find.text('See all').last;
    await tester.ensureVisible(seeAll);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();
    expect(find.text('recent'), findsOneWidget);
    expect(find.text('library'), findsNothing);
  });

  for (final (section, filter) in [
    ('Artists', LibraryFilter.artists),
    ('Albums', LibraryFilter.albums),
  ]) {
    testWidgets("$section' See all opens the Library on that list", (
      tester,
    ) async {
      await search(
        tester,
        const SearchSuggestions(),
        tracks: [testTrack('a', durationMs: 1000)],
        albums: const [
          Album(
            id: '9',
            name: 'Nexus',
            artist: 'Khaid',
            artistId: 1,
            trackCount: 1,
          ),
        ],
      );
      // Artists first, then albums.
      final seeAll = find.text('See all').at(section == 'Artists' ? 0 : 1);
      await tester.ensureVisible(seeAll);
      await tester.tap(seeAll);
      await tester.pumpAndSettle();
      expect(find.text('library'), findsOneWidget);
      expect((library.state as LibraryLoaded).filter, filter);
    });
  }
}
