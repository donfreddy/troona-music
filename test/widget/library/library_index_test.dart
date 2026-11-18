import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/library_page.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/library/presentation/widgets/library_index.dart';
import 'package:troona/features/library/presentation/widgets/shuffle_banner.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

const _letters = 'ABCDEFGHIJKLMNOPQRST';

/// Three songs per letter, A to T, each on its own album by its own artist,
/// all named after their letter. New instances on every read, as Isar gives.
List<Track> _read() => [
  for (var i = 0; i < _letters.length * 3; i++)
    Track(
      id: '$i',
      title: '${_letters[i ~/ 3]} song $i',
      artist: '${_letters[i ~/ 3]} artist $i',
      artistId: i + 1,
      album: '${_letters[i ~/ 3]} album $i',
      albumId: i + 1,
      path: '/music/$i.mp3',
      uri: 'content://$i',
      size: 1,
      durationMs: 180000,
      fileName: '$i.mp3',
    ),
];

final _tracks = _read();

/// The library is [read]'s songs, [_read] by default.
class _Library extends Fake implements LibraryRepository {
  final List<Track> Function() read;

  _Library([this.read = _read]);

  @override
  Future<Either<Failure, List<Track>>> getTracks() async => right(read());

  @override
  Future<Either<Failure, Stream<ScanProgress>>> scanLibrary() async =>
      right(const Stream.empty());

  @override
  void cancelScan() {}
}

class _NoPhotos implements MetadataRepository {
  final _updates = StreamController<String>.broadcast();

  @override
  Stream<String> get onArtistArtworkUpdated => _updates.stream;

  @override
  String? getCachedArtistArtworkPath(String artistId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LibraryLoaded _loaded({
  LibraryFilter filter = LibraryFilter.tracks,
  LibrarySort sort = LibrarySort.title,
  int count = 30,
}) {
  final tracks = _tracks.take(count).toList();
  return LibraryLoaded(
    allTracks: tracks,
    allAlbums: const [],
    allArtists: const [],
    visibleTracks: tracks,
    visibleAlbums: [
      for (final t in tracks)
        Album(
          id: '${t.albumId}',
          name: t.album,
          artist: 'Z ${t.artist}',
          artistId: t.artistId,
          trackCount: 1,
        ),
    ],
    visibleArtists: [
      for (final t in tracks)
        Artist(
          id: '${t.artistId}',
          name: t.artist,
          albumCount: 1,
          trackCount: 1,
        ),
    ],
    filter: filter,
    sort: sort,
  );
}

void main() {
  group('sections', () {
    test('files each name under its first letter, as the list sorts it', () {
      expect(LibraryIndexSections.letterOf('Adele'), 'A');
      expect(LibraryIndexSections.letterOf('the Weeknd'), 'W');
      expect(LibraryIndexSections.letterOf('Édith Piaf'), 'E');
      expect(LibraryIndexSections.letterOf('2Pac'), '#');
      expect(LibraryIndexSections.letterOf('Кино'), '#');
      expect(LibraryIndexSections.letterOf('  '), '#');
    });

    test('one section per letter, at its first item', () {
      expect(LibraryIndexSections.of(['Abba', 'Adele', 'Beck', 'Cher']), [
        (letter: 'A', index: 0),
        (letter: 'B', index: 2),
        (letter: 'C', index: 3),
      ]);
    });

    test('a letter met again later keeps its first place', () {
      // Unnamed items sort last, after names filed under # first.
      expect(LibraryIndexSections.of(['1999', 'Abba', '']), [
        (letter: '#', index: 0),
        (letter: 'A', index: 1),
      ]);
    });

    test('a short strip writes every other letter, or fewer', () {
      expect(LibraryIndex.stepFor(26, 26 * 18), 1);
      expect(LibraryIndex.stepFor(26, 26 * 14), 1);
      expect(LibraryIndex.stepFor(26, 26 * 10), 2);
      expect(LibraryIndex.stepFor(26, 26 * 4), 4);
      expect(LibraryIndex.stepFor(0, 100), 1);
    });
  });

  testWidgets('a list that shrinks under the finger drops its letter', (
    tester,
  ) async {
    List<IndexSection> sections(int n) => [
      for (var i = 0; i < n; i++)
        (letter: String.fromCharCode(0x41 + i), index: i),
    ];
    final jumps = <String>[];
    Widget index(int n) => MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryIndex(
        sections: sections(n),
        onSection: (s) => jumps.add(s.letter),
        top: 0,
        bottom: 0,
      ),
    );
    await tester.pumpWidget(index(26));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Z')));
    await tester.pump();
    expect(jumps, ['Z']);
    await tester.pumpWidget(index(20));
    expect(tester.takeException(), isNull);
    expect(find.text('Z'), findsNothing);
    await gesture.up();
  });

  group('which lists get an index', () {
    test('songs by the key they are sorted with', () {
      expect(libraryIndexTexts(_loaded())!.first, _tracks.first.title);
      expect(
        libraryIndexTexts(_loaded(sort: LibrarySort.artist))!.first,
        _tracks.first.artist,
      );
      expect(
        libraryIndexTexts(_loaded(sort: LibrarySort.album))!.first,
        _tracks.first.album,
      );
    });

    test('albums by artist when sorted by artist, else by name', () {
      final albums = _loaded(filter: LibraryFilter.albums);
      expect(libraryIndexTexts(albums)!.first, _tracks.first.album);
      expect(
        libraryIndexTexts(
          _loaded(filter: LibraryFilter.albums, sort: LibrarySort.artist),
        )!.first,
        'Z ${_tracks.first.artist}',
      );
    });

    test('none by date added, in the All view, or for a short list', () {
      expect(libraryIndexTexts(_loaded(sort: LibrarySort.dateAdded)), isNull);
      expect(libraryIndexTexts(_loaded(filter: LibraryFilter.all)), isNull);
      expect(
        libraryIndexTexts(_loaded(count: libraryIndexMinItems - 1)),
        isNull,
      );
      expect(
        libraryIndexTexts(_loaded(count: libraryIndexMinItems)),
        isNotNull,
      );
    });
  });

  group('the page', () {
    setUpAll(loadRoboto);
    setUp(() => getIt.registerSingleton<MetadataRepository>(_NoPhotos()));
    tearDown(getIt.reset);

    Future<LibraryBloc> pump(
      WidgetTester tester, {
      LibraryFilter filter = LibraryFilter.tracks,
      LibrarySort sort = LibrarySort.title,
      Size size = const Size(390, 844),
      double textScale = 1,
      bool settle = true,
      List<Track> Function() read = _read,
    }) async {
      tester.view
        ..devicePixelRatio = 3
        ..physicalSize = size * 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final port = FakeAudioPort();
      final player = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
      final library = LibraryBloc(
        scanLibrary: ScanLibraryUseCase(_Library(read)),
        getTracks: GetTracksUseCase(_Library(read)),
      );
      final palette = TrackPaletteCubit();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        unawaited(player.close());
        unawaited(port.close());
        unawaited(library.close());
        unawaited(palette.close());
      });

      library
        ..add(const LibraryBootstrapRequested())
        ..add(LibraryFilterChanged(filter))
        ..add(LibrarySortChanged(sort));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: player),
            BlocProvider.value(value: library),
            BlocProvider.value(value: palette),
          ],
          child: MaterialApp(
            theme: robotoTheme(AppTheme.dark),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LibraryPage(),
          ),
        ),
      );
      await tester.pump();
      if (settle) {
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      return library;
    }

    /// The bottom of the collapsed header: where the index brings an item.
    double pinnedBottom(WidgetTester tester) {
      final context = tester.element(find.byType(LibraryPage));
      // The Library's filter, pinned under the navigation row.
      return GlassSliverHeader.navBarBottom(context) +
          AppSpacing.tabBarHeight +
          AppSpacing.xl;
    }

    /// The bottom of the last line of text in [card].
    double lastLineBottom(WidgetTester tester, Finder card) => tester
        .getRect(find.descendant(of: card, matching: find.byType(Text)).last)
        .bottom;

    Finder letter(String l) =>
        find.descendant(of: find.byType(LibraryIndex), matching: find.text(l));

    testWidgets('a letter brings its first song under the header', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(LibraryIndex), findsOneWidget);
      // The rows leave the strip its room.
      final strip = tester.getRect(find.byType(LibraryIndex));
      expect(
        tester.getRect(find.byType(TrackListTile).first).right,
        lessThanOrEqualTo(strip.right - LibraryIndex.width),
      );

      await tester.tap(letter('M'));
      await tester.pump();

      final first = find.ancestor(
        of: find.text('M song 36'),
        matching: find.byType(TrackListTile),
      );
      expect(tester.getTopLeft(first).dy, closeTo(pinnedBottom(tester), 0.5));
      // The song before it is just out of sight, under the header.
      final before = find.ancestor(
        of: find.text('L song 35'),
        matching: find.byType(TrackListTile),
      );
      expect(
        tester.getBottomLeft(before).dy,
        lessThanOrEqualTo(pinnedBottom(tester) + 0.5),
      );
    });

    double opacityAbove(WidgetTester tester, Finder finder) => tester
        .widgetList<FadeTransition>(
          find.ancestor(of: finder, matching: find.byType(FadeTransition)),
        )
        .fold(1.0, (o, f) => o * f.opacity.value);

    testWidgets('the rows first shown play their entrance', (tester) async {
      await pump(tester, settle: false);
      final first = find.byType(TrackListTile).first;
      expect(opacityAbove(tester, first), lessThan(1));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(opacityAbove(tester, first), 1);
    });

    testWidgets('rows a jump brought in neither replay nor remount when a '
        'rescan reads the library again', (tester) async {
      final library = await pump(tester);
      await tester.tap(letter('M'));
      await tester.pump();
      Finder tile() => find.ancestor(
        of: find.text('M song 36'),
        matching: find.byType(TrackListTile),
      );
      final before = tester.state(tile());
      expect(opacityAbove(tester, tile()), 1);

      library.add(const LibraryRefreshRequested());
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
      expect(library.state, isA<LibraryLoaded>());
      expect(identical(tester.state(tile()), before), isTrue);
      expect(opacityAbove(tester, tile()), 1);
    });

    testWidgets('a jump right after a new sort shows its rows at once', (
      tester,
    ) async {
      final library = await pump(tester);
      library.add(const LibrarySortChanged(LibrarySort.artist));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      // The rows a letter brings, a frame later, do not wait their turn.
      await tester.tap(letter('M'));
      await tester.pump(const Duration(milliseconds: 16));
      final first = find.ancestor(
        of: find.text('M song 36'),
        matching: find.byType(TrackListTile),
      );
      expect(opacityAbove(tester, first), 1);
      expect(tester.getTopLeft(first).dy, closeTo(pinnedBottom(tester), 0.5));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a new sort of the albums keeps the cards in view shown', (
      tester,
    ) async {
      // Albums named A to T by artists named T to A: by artist, the order
      // turns around.
      List<Track> reversed() => [
        for (final t in _read())
          Track(
            id: t.id,
            title: t.title,
            artist: '${_letters[19 - int.parse(t.id) ~/ 3]} artist ${t.id}',
            artistId: t.artistId,
            album: t.album,
            albumId: t.albumId,
            path: t.path,
            uri: t.uri,
            size: t.size,
            durationMs: t.durationMs,
            fileName: t.fileName,
          ),
      ];
      final library = await pump(
        tester,
        filter: LibraryFilter.albums,
        read: reversed,
      );
      await tester.tap(letter('K'));
      await tester.pump(const Duration(milliseconds: 16));

      library.add(const LibrarySortChanged(LibrarySort.artist));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      final cards = find.byType(AlbumCard);
      expect(cards, findsWidgets);
      for (var i = 0; i < cards.evaluate().length; i++) {
        expect(opacityAbove(tester, cards.at(i)), 1, reason: 'card $i');
      }
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Shuffle stays clear of the strip', (tester) async {
      await pump(tester);
      final strip = tester.getRect(find.byType(LibraryIndex));
      expect(
        tester.getRect(find.byType(ShuffleBanner)).right,
        lessThanOrEqualTo(strip.right - LibraryIndex.width),
      );
    });

    testWidgets('sliding along the letters follows the finger', (tester) async {
      await pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(letter('C')));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(letter('H')));
      await tester.pump();
      // The large letter shows the one under the finger.
      expect(letter('H'), findsNWidgets(2));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));

      final first = find.ancestor(
        of: find.text('H song 21'),
        matching: find.byType(TrackListTile),
      );
      expect(tester.getTopLeft(first).dy, closeTo(pinnedBottom(tester), 0.5));
    });

    testWidgets('the last letters stop where the list ends', (tester) async {
      await pump(tester);
      await tester.tap(letter('T'));
      await tester.pump();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.pixels, position.maxScrollExtent);
      expect(find.text('T song 59'), findsOneWidget);
    });

    testWidgets('no index for songs by date added', (tester) async {
      await pump(tester, sort: LibrarySort.dateAdded);
      expect(find.byType(LibraryIndex), findsNothing);
      expect(find.byType(TrackListTile), findsWidgets);
    });

    testWidgets('a letter brings its first album to the top of the grid', (
      tester,
    ) async {
      await pump(tester, filter: LibraryFilter.albums);
      await tester.tap(letter('K'));
      await tester.pump();
      final first = find.ancestor(
        of: find.text('K album 30'),
        matching: find.byType(AlbumCard),
      );
      expect(tester.getTopLeft(first).dy, closeTo(pinnedBottom(tester), 0.5));
      // The cell ends with the card's last line.
      expect(
        lastLineBottom(tester, first),
        closeTo(tester.getBottomLeft(first).dy, 0.5),
      );
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('360 x 640, text x$scale: three artists across, each cell '
          'its circle and its two lines, nothing cut', (tester) async {
        await pump(
          tester,
          filter: LibraryFilter.artists,
          size: const Size(360, 640),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final cards = find.byType(ArtistCard);
        final a = tester.getRect(cards.at(0));
        final b = tester.getRect(cards.at(1));
        final c = tester.getRect(cards.at(2));
        final d = tester.getRect(cards.at(3));
        expect([a.top, b.top, c.top], everyElement(a.top));
        expect(d.top, greaterThan(a.bottom));
        // The cell ends with the song count: no empty band under it.
        expect(lastLineBottom(tester, cards.at(0)), closeTo(a.bottom, 0.5));
        // The strip sits in the right margin, clear of the third column.
        final strip = tester.getRect(find.byType(LibraryIndex));
        expect(c.right, lessThanOrEqualTo(strip.right - LibraryIndex.width));

        await tester.tap(letter('G'));
        await tester.pump();
        final first = find.ancestor(
          of: find.text('G artist 18'),
          matching: find.byType(ArtistCard),
        );
        expect(tester.getTopLeft(first).dy, closeTo(pinnedBottom(tester), 0.5));
      });
    }
  });
}
