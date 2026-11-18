import 'dart:async';

import 'package:dartz/dartz.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/features/player/presentation/bloc/palette/cover_palette.dart';
import 'package:troona/shared/widgets/cover_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/artist_detail.dart';
import 'package:troona/features/library/domain/repositories/artist_detail_repository.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/similar_artists/similar_artists_cubit.dart';
import 'package:troona/features/library/presentation/pages/artist_detail_page.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_row.dart';
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
  /// The photo already on disk when the page opens.
  String? downloaded;

  /// A photo the metadata finds after the page opened: completes with its
  /// address.
  Completer<String>? found;

  final updates = StreamController<String>.broadcast();

  @override
  Stream<String> get onArtistArtworkUpdated => updates.stream;

  @override
  String? getCachedArtistArtworkPath(String artistId) => downloaded;

  @override
  Future<ArtistOnlineInfo?> getArtistInfo(
    String artistName, {
    List<String> songTitles = const [],
    bool forceRefresh = false,
  }) async {
    final found = this.found;
    if (found == null) return null;
    return ArtistOnlineInfo(imageUrl: await found.future);
  }

  @override
  Future<String?> downloadAndCacheArtistArtwork({
    required String artistId,
    required String imageUrl,
  }) async => '/photos/artists/$artistId.jpg';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedArtists extends Fake implements ArtistDetailRepository {
  /// No similar artist in the library.
  @override
  Future<Either<Failure, List<Artist>>> getArtistsByNames(
    List<String> names,
  ) async => const Right([]);
}

Album _album(String id, String name, {int? year, bool single = false}) => Album(
  id: id,
  name: name,
  artist: 'Khaid',
  artistId: 1,
  trackCount: single ? 1 : 10,
  isSingle: single,
  year: year,
);

void main() {
  late _NoMetadata metadata;

  setUp(() {
    metadata = _NoMetadata();
    getIt
      ..registerSingleton<MetadataRepository>(metadata)
      ..registerFactory<ArtistMetadataCubit>(
        () => ArtistMetadataCubit(repo: metadata),
      )
      ..registerFactory<SimilarArtistsCubit>(
        () => SimilarArtistsCubit(repo: _UnusedArtists()),
      );
  });
  tearDown(getIt.reset);
  // Covers here are paths of nothing: their colours are none, at once.
  setUp(
    () => CoverPalette.read = (_) async => throw const FileSystemException(),
  );
  tearDown(CoverPalette.clear);

  Future<PlayerBloc> open(
    WidgetTester tester,
    ArtistAlbums albums, {
    String? artworkPath,
    Size size = const Size(400, 1600),
    double textScale = 1,
    int songs = 2,
    GoRouter? router,
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
            for (var i = 0; i < songs; i++)
              testTrack(i < 2 ? 'ab'[i] : 's$i', durationMs: 1000),
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
                home: const ArtistDetailPage(id: '1'),
              ),
      ),
    );
    await tester.pumpAndSettle();
    return player;
  }

  group('See all', () {
    GoRouter routes() => GoRouter(
      initialLocation: '/library/artists/1',
      routes: [
        GoRoute(
          path: '/library/artists/:id',
          builder: (_, _) => const ArtistDetailPage(id: '1'),
        ),
        GoRoute(
          path: '/library/artists/:id/songs',
          builder: (_, state) => Text('songs of ${state.pathParameters['id']}'),
        ),
      ],
    );

    Future<void> seeAll(WidgetTester tester) async {
      final button = find.textContaining('See all');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('up to twenty songs, they unfold in place', (tester) async {
      final router = routes();
      await open(tester, const ArtistAlbums(), songs: 20, router: router);
      await seeAll(tester);
      await tester.scrollUntilVisible(
        find.text('Show less'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Show less'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));
    });

    testWidgets('more, and they open on a page of their own', (tester) async {
      final router = routes();
      await open(tester, const ArtistAlbums(), songs: 21, router: router);
      await seeAll(tester);
      expect(find.text('songs of 1'), findsOneWidget);
    });
  });

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
        own: [
          _album('2', 'Emotions', year: 2023),
          _album('4', 'Before', year: 2021),
          _album('5', 'First', year: 2019),
        ],
        singles: [
          _album('3', 'Anabella', year: 2024, single: true),
          _album('6', 'Other', year: 2020, single: true),
        ],
      ),
    );
    expect(find.text('Latest release'), findsOneWidget);
    expect(find.text('2024'), findsWidgets);
    final latest = tester.getTopLeft(find.text('Latest release'));
    final albums = tester.getTopLeft(find.text('Albums'));
    expect(latest.dy, lessThan(albums.dy));
  });

  testWidgets('no latest release under four: its cover is right below', (
    tester,
  ) async {
    await open(
      tester,
      ArtistAlbums(
        own: [_album('2', 'Emotions', year: 2023)],
        singles: [_album('3', 'Anabella', year: 2024, single: true)],
      ),
    );
    expect(find.text('Latest release'), findsNothing);
  });

  testWidgets('few releases: one Discography, singles marked, as rows', (
    tester,
  ) async {
    await open(
      tester,
      ArtistAlbums(
        own: [_album('2', 'Emotions', year: 2023)],
        singles: [_album('3', 'Anabella', year: 2024, single: true)],
      ),
    );
    expect(find.text('Discography'), findsOneWidget);
    expect(find.text('Albums'), findsNothing);
    expect(find.text('Singles'), findsNothing);
    expect(find.byType(AlbumRow), findsNWidgets(2));
    expect(find.byType(AlbumCard), findsNothing);
    expect(find.text('2024 • Single'), findsOneWidget);
    // Its ink shows: drawn on a Material of its own, not under the page's
    // background.
    final ink = find
        .descendant(
          of: find.byType(AlbumRow).first,
          matching: find.byType(InkWell),
        )
        .first;
    expect(
      tester
          .widget<Material>(
            find.ancestor(of: ink, matching: find.byType(Material)).first,
          )
          .type,
      MaterialType.transparency,
    );
    // Newest first, the 2024 single before the 2023 album.
    expect(
      tester.getTopLeft(find.text('Anabella')).dy,
      lessThan(tester.getTopLeft(find.text('Emotions')).dy),
    );
  });

  testWidgets('three or more in a section: a carousel; fewer: rows', (
    tester,
  ) async {
    await open(
      tester,
      ArtistAlbums(
        own: [
          _album('2', 'A', year: 2023),
          _album('4', 'B', year: 2021),
          _album('5', 'C', year: 2019),
        ],
        singles: [
          _album('3', 'S', year: 2024, single: true),
          _album('6', 'T', year: 2020, single: true),
        ],
        appearsOn: [_album('7', 'Guest', year: 2022)],
      ),
    );
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Singles'), findsOneWidget);
    expect(find.byType(AlbumCard), findsNWidgets(3));
    // Two singles and the album they appear on, which names its artist.
    expect(find.byType(AlbumRow), findsNWidgets(3));
    expect(
      find.descendant(
        of: find.widgetWithText(AlbumRow, 'Guest'),
        matching: find.textContaining('Khaid'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no latest release when no release has a year', (tester) async {
    await open(tester, ArtistAlbums(own: [_album('2', 'A'), _album('3', 'B')]));
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

  testWidgets('without a photo, their cover glows behind the name, blurred '
      'once off screen: nothing is filtered on screen', (tester) async {
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    final glow = find.byKey(const ValueKey('coverGlow'));
    expect(glow, findsOneWidget);
    expect(
      tester.getSize(glow).width,
      tester.getSize(find.byType(CustomScrollView)).width,
      reason: 'stretched over the header',
    );
    expect(find.byType(ImageFiltered), findsNothing);
    // The collapsed bar's own blur is the only one on the page.
    expect(
      find.descendant(of: glow, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
  });

  testWidgets("the page takes its colours from the artist's photo, else "
      'from their cover, not from the song playing', (tester) async {
    String? path() =>
        tester.widget<CoverBackground>(find.byType(CoverBackground)).path;
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    expect(path(), '/covers/k.jpg');

    metadata.downloaded = '/photos/artists/1.jpg';
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    expect(path(), '/photos/artists/1.jpg');

    metadata.downloaded = null;
    await open(tester, const ArtistAlbums());
    expect(path(), '', reason: 'no picture at all: the neutral glow');
  });

  testWidgets('a photo downloaded, then deleted, while the page is open '
      'turns its colours', (tester) async {
    String? path() =>
        tester.widget<CoverBackground>(find.byType(CoverBackground)).path;
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    expect(path(), '/covers/k.jpg');

    metadata.downloaded = '/photos/artists/1.jpg';
    metadata.updates.add('1');
    await tester.pump();
    await tester.pump();
    expect(path(), '/photos/artists/1.jpg');

    metadata.downloaded = null;
    metadata.updates.add(MetadataRepository.allArtists);
    await tester.pump();
    await tester.pump();
    expect(path(), '/covers/k.jpg');
    await tester.pumpAndSettle();
  });

  testWidgets('without a photo nor a cover, no glow', (tester) async {
    await open(tester, const ArtistAlbums());
    expect(find.byKey(const ValueKey('coverGlow')), findsNothing);
  });

  /// The artist's name in the expanded header (the bar has one too).
  Finder headerName() => find.descendant(
    of: find
        .ancestor(
          of: find.byType(ShuffleRoundButton),
          matching: find.byType(Row),
        )
        .first,
    matching: find.text('Khaid'),
  );

  testWidgets('one layout without a photo: the name at the bottom left, '
      'Shuffle on its right, no circle', (tester) async {
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    final name = tester.getRect(headerName());
    final shuffle = tester.getRect(find.byType(ShuffleRoundButton));
    expect(name.left, 16, reason: 'aligned on the page margin');
    expect(shuffle.left, greaterThan(name.right));
    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets('with or without a photo, the name and the songs sit at the '
      'same place', (tester) async {
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    final name = tester.getTopLeft(headerName());
    final songs = tester.getTopLeft(find.text('Title a'));
    await tester.pumpWidget(const SizedBox());
    metadata.downloaded = '/photos/artists/1.jpg';
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    expect(tester.getTopLeft(headerName()), name);
    expect(tester.getTopLeft(find.text('Title a')), songs);
  });

  Finder glow() => find.byKey(const ValueKey('coverGlow'));

  testWidgets('a photo found after the page opened fades in behind a name '
      'that does not move', (tester) async {
    metadata.found = Completer();
    await open(tester, const ArtistAlbums(), artworkPath: '/covers/k.jpg');
    final before = tester.getTopLeft(headerName());
    final songs = tester.getTopLeft(find.text('Title a'));

    metadata.found!.complete('https://photos.test/k.jpg');
    await tester.pump(); // the metadata comes
    await tester.pump(); // the photo is switched in
    await tester.pump(const Duration(milliseconds: 150));
    // Mid-fade: the glow below, the photo coming, one name all along.
    expect(glow(), findsOneWidget);
    expect(
      find.byType(FadeTransition).evaluate().where((e) {
        final fade = e.widget as FadeTransition;
        return fade.opacity.value > 0 && fade.opacity.value < 1;
      }),
      isNotEmpty,
      reason: 'the photo is fading in',
    );
    expect(find.text('Khaid'), findsNWidgets(2), reason: 'bar and header');
    expect(tester.getTopLeft(headerName()), before);
    await tester.pumpAndSettle();
    expect(glow(), findsNothing);
    expect(tester.getTopLeft(headerName()), before);
    expect(tester.getTopLeft(find.text('Title a')), songs);
  });

  Finder downloadedPhoto() => find.byWidgetPredicate(
    (w) => w is ArtworkImage && w.path == '/photos/artists/1.jpg',
  );

  testWidgets('photos turned off while the page is open: the downloaded '
      'photo goes', (tester) async {
    metadata.downloaded = '/photos/artists/1.jpg';
    await open(tester, const ArtistAlbums());
    expect(downloadedPhoto(), findsOneWidget);

    // Offline: the metadata has nothing either way, only the disk changes.
    metadata.downloaded = null;
    metadata.updates.add(MetadataRepository.allArtists);
    await tester.pumpAndSettle();
    expect(downloadedPhoto(), findsNothing);
  });

  for (final scale in const [1.3, 2.0]) {
    testWidgets('360 x 640, text x$scale, opened on a photo: no overflow, '
        'Shuffle above the songs', (tester) async {
      metadata.downloaded = '/photos/artists/1.jpg';
      await open(
        tester,
        const ArtistAlbums(),
        size: const Size(360, 640),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      final button = tester.getRect(find.byType(ShuffleRoundButton));
      expect(
        button.bottom,
        lessThanOrEqualTo(tester.getRect(find.text('Title a')).top),
      );
    });
  }
}
