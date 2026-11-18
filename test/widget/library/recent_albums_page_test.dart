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
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';

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
  Future<void> open(WidgetTester tester, List<Track> tracks) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    final (:player, port: _) = await testPlayer(addTearDown);
    final library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
      getTracks: GetTracksUseCase(_UnusedLibrary()),
    );
    final albums = LibraryGrouping.albumsOf(tracks);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(
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
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RecentAlbumsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
}
