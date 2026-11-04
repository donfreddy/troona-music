import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/artist_detail.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/similar_artists/similar_artists_cubit.dart';
import 'package:troona/features/library/presentation/pages/artist_detail_page.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/metadata/presentation/cubit/artist_metadata_cubit.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

import '../../helpers/fake_player.dart';

class _NoMetadata implements MetadataRepository {
  @override
  Stream<String> get onArtistArtworkUpdated => const Stream.empty();

  @override
  Future<ArtistOnlineInfo?> getArtistInfo(
    String artistName, {
    bool forceRefresh = false,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedArtists extends Fake implements ArtistDetailRepository {}

Album _album(String id, String name, {int? year, bool single = false}) =>
    Album(
      id: id,
      name: name,
      artist: 'Khaid',
      artistId: 1,
      trackCount: single ? 1 : 10,
      isSingle: single,
      year: year,
    );

void main() {
  setUp(() {
    getIt
      ..registerFactory<ArtistMetadataCubit>(
        () => ArtistMetadataCubit(repo: _NoMetadata()),
      )
      ..registerFactory<SimilarArtistsCubit>(
        () => SimilarArtistsCubit(repo: _UnusedArtists()),
      );
  });
  tearDown(getIt.reset);

  Future<PlayerBloc> open(
    WidgetTester tester,
    ArtistAlbums albums, {
    String? artworkPath,
    Size size = const Size(400, 1600),
    double textScale = 1,
  }) async {
    // Tall enough to build every section, by default.
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final port = FakeAudioPort();
    final player = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    final detail = ArtistDetailBloc(repo: _UnusedArtists());
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    detail.emit(
      ArtistDetailLoaded(
        ArtistDetail(
          artist: Artist(
            id: '1',
            name: 'Khaid',
            albumCount: 2,
            trackCount: 2,
            artworkPath: artworkPath,
          ),
          topTracks: [
            testTrack('a', durationMs: 1000),
            testTrack('b', durationMs: 1000),
          ],
          albums: albums,
        ),
      ),
    );
    final palette = TrackPaletteCubit();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(detail.close());
      unawaited(player.close());
      unawaited(palette.close());
      unawaited(port.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ArtistDetailBloc>.value(value: detail),
          BlocProvider<PlayerBloc>.value(value: player),
          BlocProvider<TrackPaletteCubit>.value(value: palette),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ArtistDetailPage(id: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return player;
  }

  testWidgets('one action, Shuffle, as a round button: it plays the artist '
      'shuffled', (tester) async {
    final player = await open(tester, const ArtistAlbums());
    expect(find.byType(PlayShuffleButtons), findsNothing);
    expect(find.byType(ShuffleRoundButton), findsOneWidget);
    expect(find.bySemanticsLabel('Shuffle'), findsOneWidget);

    await tester.tap(find.byType(ShuffleRoundButton));
    await tester.pumpAndSettle();
    expect(player.state, isNot(isA<PlayerIdle>()));
  });

  testWidgets('their newest release on its own, above the carousels', (
    tester,
  ) async {
    await open(
      tester,
      ArtistAlbums(
        own: [_album('2', 'Emotions', year: 2023)],
        singles: [_album('3', 'Anabella', year: 2024, single: true)],
      ),
    );
    expect(find.text('Latest release'), findsOneWidget);
    expect(find.text('2024'), findsWidgets);
    final latest = tester.getTopLeft(find.text('Latest release'));
    final albums = tester.getTopLeft(find.text('Albums'));
    expect(latest.dy, lessThan(albums.dy));
  });

  testWidgets('no latest release when no release has a year', (tester) async {
    await open(
      tester,
      ArtistAlbums(own: [_album('2', 'A'), _album('3', 'B')]),
    );
    expect(find.text('Latest release'), findsNothing);
  });

  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('360 x 640, text x$scale, no photo: Shuffle stays whole in '
        'the header, above the songs', (tester) async {
      await open(
        tester,
        const ArtistAlbums(),
        size: const Size(360, 640),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      final button = tester.getRect(find.byType(ShuffleRoundButton));
      final firstSong = tester.getRect(find.text('Title a'));
      expect(button.bottom, lessThanOrEqualTo(firstSong.top));
      expect(button.top, greaterThan(0));
    });
  }

  testWidgets('without a photo, their cover glows behind the circle, '
      'decoded tiny and blurred by the upscale alone', (tester) async {
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    final glow = find.byWidgetPredicate(
      (w) => w is ArtworkImage && w.width == 12,
    );
    expect(glow, findsOneWidget);
    expect(
      tester.getSize(find.ancestor(of: glow, matching: find.byType(FittedBox))),
      isNot(const Size(12, 12)),
      reason: 'stretched over the header',
    );
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('without a photo nor a cover, no glow', (tester) async {
    await open(tester, const ArtistAlbums());
    expect(
      find.byWidgetPredicate((w) => w is ArtworkImage && w.width == 12),
      findsNothing,
    );
  });
}
