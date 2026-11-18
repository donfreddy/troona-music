import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/recent_albums_page.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

import '../../helpers/fake_player.dart';

class _UnusedLibrary extends Fake implements LibraryRepository {
  @override
  void cancelScan() {}
}

/// A song of album [album], added on [day].
Track _song(String id, int album, int day) {
  final t = testTrack(id, durationMs: 1000);
  return Track(
    id: id,
    title: 'Title $id',
    artist: t.artist,
    artistId: t.artistId,
    album: 'Album $album',
    albumId: album,
    path: t.path,
    uri: t.uri,
    size: t.size,
    durationMs: t.durationMs,
    fileName: t.fileName,
    dateAdded: DateTime(2026).add(Duration(days: day)),
  );
}

void main() {
  late LibraryBloc library;

  Future<void> open(
    WidgetTester tester,
    List<Track> tracks, {
    LibraryState? state,
    GoRouter? router,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    final (:player, port: _) = await testPlayer(addTearDown);
    library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
      getTracks: GetTracksUseCase(_UnusedLibrary()),
    );
    final albums = LibraryGrouping.albumsOf(tracks);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(
      state ??
          LibraryLoaded(
            allTracks: tracks,
            allAlbums: albums,
            allArtists: const [],
            visibleTracks: tracks,
            visibleAlbums: albums,
            visibleArtists: const [],
          ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(library.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: player),
          BlocProvider<LibraryBloc>.value(value: library),
        ],
        child: router != null
            ? MaterialApp.router(
                theme: AppTheme.dark,
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              )
            : MaterialApp(
                theme: AppTheme.dark,
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const RecentAlbumsPage(),
              ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  List<String> shown(WidgetTester tester) => [
    for (final card in tester.widgetList<AlbumCard>(find.byType(AlbumCard)))
      card.album.id,
  ];

  testWidgets('the albums added last, newest first, and how many', (
    tester,
  ) async {
    await open(tester, [
      _song('a', 1, 1),
      _song('b', 2, 5),
      _song('c', 1, 9),
      _song('d', 3, 3),
    ]);
    expect(find.text('Recent albums'), findsWidgets);
    expect(find.text('3 albums'), findsOneWidget);
    expect(shown(tester), ['1', '2', '3']);
  });

  testWidgets('the last fifty, not every album', (tester) async {
    await open(tester, [for (var d = 0; d < 70; d++) _song('s$d', d, d)]);
    expect(find.text('50 albums'), findsOneWidget);
    expect(shown(tester).first, '69');
  });

  testWidgets('nothing added: says so', (tester) async {
    await open(tester, const []);
    expect(find.text('Nothing added yet'), findsOneWidget);
    expect(find.byType(AlbumCard), findsNothing);
  });

  testWidgets('pushRecentAlbums opens it in Home', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: context.pushRecentAlbums,
              child: const Text('See all'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'recent/albums',
              builder: (_, _) => const Text('recent albums'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('recent albums'), findsOneWidget);
    expect(router.canPop(), isTrue);
  });

  testWidgets('the first scan, nothing stored yet: it loads, it does not '
      'say nothing was added', (tester) async {
    await open(
      tester,
      const [],
      state: const LibraryScanning(
        progress: ScanProgress(phase: ScanPhase.scanning, progress: 0),
        // A new install reads an empty database first.
        cached: LibraryLoaded(
          allTracks: [],
          allAlbums: [],
          allArtists: [],
          visibleTracks: [],
          visibleAlbums: [],
          visibleArtists: [],
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nothing added yet'), findsNothing);
  });

  group('heroes', () {
    const albumPage = ValueKey('album page cover');

    /// Home with a card of album 1, which Recent albums lists too.
    GoRouter home() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: context.pushRecentAlbums,
                  child: const Text('See all'),
                ),
                SizedBox(
                  width: 130,
                  child: AlbumCard(
                    album: library.state is LibraryLoaded
                        ? (library.state as LibraryLoaded).allAlbums.first
                        : throw StateError('no library'),
                    size: 130,
                  ),
                ),
              ],
            ),
          ),
          routes: [
            GoRoute(
              path: 'recent/albums',
              builder: (_, _) => const RecentAlbumsPage(),
            ),
            GoRoute(
              path: 'albums/:id',
              builder: (_, state) => Scaffold(
                body: AlbumCoverHero(
                  albumId: state.pathParameters['id']!,
                  artworkPath: null,
                  radius: 0,
                  child: const SizedBox.square(key: albumPage, dimension: 300),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    /// Covers shown in place: a cover in flight leaves an empty box at both
    /// ends.
    int inPlace(WidgetTester tester) => tester
        .widgetList(
          // A pushed page is offstage for its first frame, while the
          // heroes are measured.
          find.descendant(
            of: find.byType(Hero, skipOffstage: false),
            matching: find.byWidgetPredicate(
              (w) => w is ArtworkImage || w.key == albumPage,
              skipOffstage: false,
            ),
          ),
        )
        .length;

    testWidgets("nothing flies from Home's row into the page, nor back", (
      tester,
    ) async {
      final router = home();
      addTearDown(router.dispose);
      await open(tester, [_song('a', 1, 1)], router: router);
      expect(inPlace(tester), 1);
      await tester.tap(find.text('See all'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(inPlace(tester), 2, reason: 'coming in, frame $i');
      }
      await tester.pumpAndSettle();
      router.pop();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(inPlace(tester), 2, reason: 'going, frame $i');
      }
    });

    testWidgets('a card of the page still flies into its album', (
      tester,
    ) async {
      final router = home();
      addTearDown(router.dispose);
      await open(tester, [_song('a', 1, 1)], router: router);
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(RecentAlbumsPage),
          matching: find.byType(AlbumCard),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(albumPage), findsNothing, reason: 'in flight');
      await tester.pumpAndSettle();
      expect(find.byKey(albumPage), findsOneWidget);
      // And back into its card.
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Only Home's card, under the page, stays in place.
      expect(inPlace(tester), 1, reason: 'in flight back');
      await tester.pumpAndSettle();
      expect(inPlace(tester), 2, reason: "landed, beside Home's card");
    });
  });
}
