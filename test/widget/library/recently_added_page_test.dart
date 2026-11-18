import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/recently_added_page.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/library/presentation/widgets/track_shimmer.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

import '../../helpers/fake_player.dart';

class _UnusedLibrary extends Fake implements LibraryRepository {
  @override
  void cancelScan() {}
}

Track _song(String id, int day) {
  final t = testTrack(id, durationMs: 1000);
  return Track(
    id: id,
    title: 'Title $id',
    artist: t.artist,
    artistId: t.artistId,
    album: t.album,
    albumId: t.albumId,
    path: t.path,
    uri: t.uri,
    size: t.size,
    durationMs: t.durationMs,
    fileName: t.fileName,
    dateAdded: DateTime(2026).add(Duration(days: day)),
  );
}

void main() {
  tearDown(getIt.reset);

  Future<FakeAudioPort> open(
    WidgetTester tester,
    List<Track> tracks, {
    LibraryState? state,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    final (:player, :port) = await testPlayer(addTearDown);
    final library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
      getTracks: GetTracksUseCase(_UnusedLibrary()),
    );
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(
      state ??
          LibraryLoaded(
            allTracks: tracks,
            allAlbums: const [],
            allArtists: const [],
            visibleTracks: tracks,
            visibleAlbums: const [],
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
          home: const RecentlyAddedPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return port;
  }

  List<String> shown(WidgetTester tester) => [
    for (final tile in tester.widgetList<TrackListTile>(
      find.byType(TrackListTile),
    ))
      tile.track.id,
  ];

  testWidgets('the songs added last, newest first, and how many', (
    tester,
  ) async {
    await open(tester, [_song('old', 1), _song('new', 9), _song('mid', 5)]);
    expect(find.text('Recently added'), findsWidgets);
    expect(find.text('3 songs'), findsOneWidget);
    expect(shown(tester), ['new', 'mid', 'old']);
  });

  testWidgets('a tap plays the list as shown, from that song', (tester) async {
    final port = await open(tester, [
      _song('old', 1),
      _song('new', 9),
      _song('mid', 5),
    ]);
    await tester.tap(find.text('Title mid'));
    await tester.pump();
    expect(
      [for (final t in port.lastSetQueue!.tracks) t.id],
      ['new', 'mid', 'old'],
    );
    expect(port.lastSetQueue!.startIndex, 1);
  });

  testWidgets('the last hundred, not the whole library', (tester) async {
    await open(tester, [for (var d = 0; d < 150; d++) _song('s$d', d)]);
    expect(find.text('100 songs'), findsOneWidget);
    expect(shown(tester).first, 's149');
  });

  testWidgets('nothing added: says so', (tester) async {
    await open(tester, const []);
    expect(find.text('Nothing added yet'), findsOneWidget);
    expect(find.byType(TrackListTile), findsNothing);
  });

  testWidgets('the first scan, nothing stored yet: it loads, as the Library '
      'does', (tester) async {
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
    expect(find.byType(TrackShimmer), findsWidgets);
    expect(find.text('Nothing added yet'), findsNothing);
  });
}
