import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_detail.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/pages/artist_songs_page.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

class _Unused extends Fake implements ArtistDetailRepository {}

Track _song(
  String id,
  String title, {
  String album = 'Album',
  int albumId = 1,
  int? number,
  int addedDay = 1,
}) {
  final t = testTrack(id, durationMs: 1000);
  return Track(
    id: id,
    title: title,
    artist: t.artist,
    artistId: t.artistId,
    album: album,
    albumId: albumId,
    trackNumber: number,
    path: t.path,
    uri: t.uri,
    size: t.size,
    durationMs: t.durationMs,
    fileName: t.fileName,
    dateAdded: DateTime(2026, 1, addedDay),
  );
}

void main() {
  // Most played first, as the artist page hands them.
  final ranked = [
    _song('1', 'Zebra', album: 'Beta', albumId: 2, number: 2, addedDay: 3),
    _song('2', 'Été', album: 'Alpha', albumId: 1, number: 1, addedDay: 9),
    _song('3', 'Apple', album: 'Beta', albumId: 2, number: 1, addedDay: 5),
  ];
  List<String> ids(List<Track> tracks) => [for (final t in tracks) t.id];

  group('ArtistSongOrder', () {
    test('plays keeps the ranking', () {
      expect(ids(ArtistSongOrder.plays.apply(ranked)), ['1', '2', '3']);
    });

    test('title folds accents', () {
      expect(ids(ArtistSongOrder.title.apply(ranked)), ['3', '2', '1']);
    });

    test('album: by name, each in its track order', () {
      expect(ids(ArtistSongOrder.album.apply(ranked)), ['2', '3', '1']);
    });

    test('recent: added last first; ties keep the ranking', () {
      expect(ids(ArtistSongOrder.recent.apply(ranked)), ['2', '3', '1']);
      final tied = [_song('a', 'A', addedDay: 1), _song('b', 'B', addedDay: 1)];
      expect(ids(ArtistSongOrder.recent.apply(tied)), ['a', 'b']);
    });
  });

  Future<FakeAudioPort> open(
    WidgetTester tester, {
    required bool byPlays,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final port = FakeAudioPort();
    final player = buildTestPlayerBloc(
      port,
      PlaybackSessionStore(await SharedPreferences.getInstance()),
    );
    final detail = ArtistDetailBloc(repo: _Unused());
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    detail.emit(
      ArtistDetailLoaded(
        ArtistDetail(
          artist: const Artist(
            id: '7',
            name: 'Khaid',
            albumCount: 2,
            trackCount: 3,
          ),
          topTracks: ranked,
          topTracksByPlays: byPlays,
          albums: const ArtistAlbums(),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(detail.close());
      unawaited(player.close());
      unawaited(port.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: detail),
          BlocProvider.value(value: player),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ArtistSongsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return port;
  }

  List<String> shown(WidgetTester tester) => [
    for (final tile in tester.widgetList<TrackListTile>(
      find.byType(TrackListTile),
    ))
      tile.track.id,
  ];

  testWidgets('every song, most played first, under the artist and count', (
    tester,
  ) async {
    await open(tester, byPlays: true);
    expect(find.text('Songs'), findsWidgets);
    expect(find.text('Khaid • 3 songs'), findsOneWidget);
    expect(shown(tester), ['1', '2', '3']);
  });

  testWidgets('nothing played: by title, and no order by plays to pick', (
    tester,
  ) async {
    await open(tester, byPlays: false);
    expect(shown(tester), ['3', '2', '1']);
    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    expect(find.text('Most played'), findsNothing);
    expect(find.text('Recently added'), findsOneWidget);
  });

  testWidgets('another order, and a tap plays the list as shown, as the '
      "artist's", (tester) async {
    final port = await open(tester, byPlays: true);
    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Album'));
    await tester.pumpAndSettle();
    expect(shown(tester), ['2', '3', '1']);

    await tester.tap(find.text('Apple'));
    await tester.pump();
    expect(ids(port.lastSetQueue!.tracks), ['2', '3', '1']);
    expect(port.lastSetQueue!.startIndex, 1);
  });
}
