import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/album_detail_page.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/metadata/presentation/cubit/album_metadata_cubit.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

const _album = Album(
  id: '7',
  name: 'Love, Damini',
  artist: 'Burna Boy',
  artistId: 1,
  trackCount: 2,
);

final _tracks = [
  for (final id in ['a', 'b']) testTrack(id, durationMs: 60000),
];

/// A song of the album sung by someone else: its row names them.
Track _guest(String id) {
  final t = testTrack(id, durationMs: 60000);
  return Track(
    id: id,
    title: t.title,
    artist: 'Guest',
    artistId: 2,
    album: t.album,
    albumId: t.albumId,
    path: t.path,
    uri: t.uri,
    size: t.size,
    durationMs: t.durationMs,
    fileName: t.fileName,
  );
}

/// The album's songs; a test may hand a longer list.
var _albumTracks = _tracks;

class _Albums implements AlbumDetailRepository {
  @override
  Future<Either<Failure, Album>> getAlbumById(String id) async => right(_album);

  @override
  Future<Either<Failure, List<Track>>> getTracksByAlbumId(int id) async =>
      right(_albumTracks);

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

void main() {
  setUp(() {
    _albumTracks = _tracks;
    getIt.registerFactory<AlbumMetadataCubit>(
      () => AlbumMetadataCubit(repo: _NoMetadata()),
    );
  });
  tearDown(getIt.reset);

  late FakeAudioPort port;

  /// The album page, with [playing] in the player when given.
  Future<void> open(
    WidgetTester tester, {
    List<Track>? playing,
    bool reducedMotion = false,
    double textScale = 1,
    GlobalKey<NavigatorState>? pushedOn,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort()..duration = const Duration(minutes: 1);
    final player = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    final detail = AlbumDetailBloc(repo: _Albums())
      ..add(AlbumDetailRequested(7));
    final library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
      getTracks: GetTracksUseCase(_UnusedLibrary()),
    );
    final palette = TrackPaletteCubit();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(player.close());
      unawaited(port.close());
      unawaited(detail.close());
      unawaited(library.close());
      unawaited(palette.close());
    });
    if (playing != null) {
      port.queue = Queue.fromTracks(playing);
      player.add(QueueSetRequested(playing));
      await tester.pump();
      port.status.add(PlaybackStatus.playing);
      await tester.pump();
    }
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: player),
          BlocProvider.value(value: detail),
          BlocProvider.value(value: library),
          BlocProvider.value(value: palette),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reducedMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorKey: pushedOn,
            // Pushed over a first page, its transition left to the test.
            home: pushedOn == null
                ? const AlbumDetailPage(id: '7')
                : const SizedBox(),
          ),
        ),
      ),
    );
    if (pushedOn != null) {
      unawaited(
        pushedOn.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const AlbumDetailPage(id: '7'),
          ),
        ),
      );
      return;
    }
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Finder record() => find.descendant(
    of: find.byKey(const ValueKey('albumVinyl')),
    matching: find.byType(RotationTransition),
  );

  double turns(WidgetTester tester) =>
      tester.widget<RotationTransition>(record()).turns.value;

  double slide(WidgetTester tester) => tester
      .widget<AnimatedSlide>(
        find.ancestor(of: record(), matching: find.byType(AnimatedSlide)),
      )
      .offset
      .dx;

  testWidgets('at rest, in its sleeve and still; a tap starts nothing', (
    tester,
  ) async {
    await open(tester);
    expect(slide(tester), 0);
    final before = turns(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(turns(tester), before);

    // Its edge out of the sleeve.
    final rect = tester.getRect(record());
    await tester.tapAt(rect.centerRight - const Offset(12, 0));
    await tester.pump();
    expect(port.lastSetQueue, isNull, reason: 'Play, below, starts it');
    expect((port.pauseCalls, port.resumeCalls), (0, 0));
  });

  testWidgets('while the album plays, out further and turning', (tester) async {
    await open(tester, playing: _tracks);
    expect(slide(tester), greaterThan(0));
    final before = turns(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(turns(tester), isNot(before));
  });

  testWidgets('while the album plays, a tap pauses it; paused, resumes it', (
    tester,
  ) async {
    await open(tester, playing: _tracks);
    final queued = port.lastSetQueue;
    // Its edge, out of the sleeve: the cover hides the rest.
    Offset edge() => tester.getRect(record()).centerRight - const Offset(12, 0);
    await tester.tapAt(edge());
    await tester.pump();
    expect(port.pauseCalls, 1);

    port.status.add(PlaybackStatus.paused);
    await tester.pump();
    await tester.tapAt(edge());
    await tester.pump();
    expect(port.resumeCalls, 1);
    expect(port.lastSetQueue, same(queued), reason: 'the queue stays');
  });

  testWidgets('a screen reader can pause it too', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, playing: _tracks);
    final node = tester.getSemantics(find.byKey(const ValueKey('albumVinyl')));
    expect(node.label, 'Pause');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Pause'));
    await tester.pump();
    await tester.pump();
    expect(port.pauseCalls, 1);
    semantics.dispose();
  });

  testWidgets('another album playing: a tap leaves it alone', (tester) async {
    await open(tester, playing: [testTrack('z', durationMs: 60000)]);
    final rect = tester.getRect(record());
    await tester.tapAt(rect.centerRight - const Offset(12, 0));
    await tester.pump();
    expect((port.pauseCalls, port.resumeCalls), (0, 0));
    expect(port.lastSetQueue?.tracks.single.id, 'z');
  });

  testWidgets('another album playing: it stays in its sleeve', (tester) async {
    await open(tester, playing: [testTrack('z', durationMs: 60000)]);
    expect(slide(tester), 0);
  });

  testWidgets('reduced motion: out, but it does not turn', (tester) async {
    await open(tester, playing: _tracks, reducedMotion: true);
    expect(slide(tester), greaterThan(0));
    final before = turns(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(turns(tester), before);
  });

  testWidgets('its light stays put while it turns, and slides with it', (
    tester,
  ) async {
    await open(tester, playing: _tracks);
    final sheen = find.byKey(const ValueKey('vinylSheen'));
    expect(
      find.ancestor(of: sheen, matching: find.byType(RotationTransition)),
      findsNothing,
    );
    expect(tester.getRect(sheen), tester.getRect(record()));
  });

  testWidgets('the record is painted once and turned as a layer', (
    tester,
  ) async {
    await open(tester, playing: _tracks);
    // A boundary right inside the rotation: the turning transform sits
    // above it, so the grooves are not repainted on every frame.
    expect(
      tester.widget<RotationTransition>(record()).child,
      isA<RepaintBoundary>(),
    );
  });

  testWidgets('pulling the page down draws the record further out, and it '
      'goes back on release', (tester) async {
    await open(tester, playing: _tracks);
    final rest = tester.getRect(record()).left;
    final pull = await tester.startGesture(const Offset(200, 500));
    for (var i = 0; i < 6; i++) {
      await pull.moveBy(const Offset(0, 30));
      await tester.pump();
    }
    final pulled = tester.getRect(record()).left;
    expect(pulled, greaterThan(rest + 10));
    expect(pulled, lessThanOrEqualTo(rest + 28));
    await pull.up();
    // It spins on: no settling, frames of the page springing back.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.getRect(record()).left, closeTo(rest, 0.5));
  });

  group('opening the album that plays', () {
    final long = [
      for (var i = 0; i < 40; i++) testTrack('s$i', durationMs: 60000),
    ];
    ScrollPosition scroll(WidgetTester tester) => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    // A tall phone: the first rows show under the cover.
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 900);
    });
    tearDown(
      () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
          .reset(),
    );

    /// The middle of what the mini player leaves on screen.
    double middle(WidgetTester tester) {
      final view = tester.getRect(find.byType(CustomScrollView));
      return view.top +
          (view.height - AppSpacing.miniPlayerHeight - AppSpacing.xl) / 2;
    }

    Finder playingRow() => find.byWidgetPredicate(
      (w) => w is AlbumTrackListTile && w.track.id == 's24',
    );

    Future<void> settle(WidgetTester tester) async {
      // The record turns: frames, not pumpAndSettle.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('its song far below: the list comes to it', (tester) async {
      _albumTracks = long;
      await open(tester, playing: [long[24]]);
      await settle(tester);
      final row = find.byWidgetPredicate(
        (w) => w is AlbumTrackListTile && w.track.id == 's24',
      );
      expect(row, findsOneWidget);
      final rect = tester.getRect(row);
      final view = tester.getRect(find.byType(CustomScrollView));
      expect(rect.top, greaterThanOrEqualTo(view.top));
      expect(rect.bottom, lessThanOrEqualTo(view.bottom - 100));
      // Brought near the middle, not left at the bottom edge.
      expect(rect.center.dy, closeTo(middle(tester), 1));
    });

    testWidgets('reduced motion: there at once', (tester) async {
      _albumTracks = long;
      await open(tester, playing: [long[24]], reducedMotion: true);
      await tester.pump();
      await tester.pump();
      final row = find.byWidgetPredicate(
        (w) => w is AlbumTrackListTile && w.track.id == 's24',
      );
      final view = tester.getRect(find.byType(CustomScrollView));
      expect(tester.getRect(row).bottom, lessThanOrEqualTo(view.bottom - 100));
      expect(tester.getRect(row).top, greaterThanOrEqualTo(view.top));
    });

    testWidgets('its song in view: the page stays at the top', (tester) async {
      _albumTracks = long;
      await open(tester, playing: [long[1]]);
      await settle(tester);
      expect(scroll(tester).pixels, 0);
    });

    testWidgets('another album playing: the page stays at the top', (
      tester,
    ) async {
      _albumTracks = long;
      await open(tester, playing: [testTrack('z', durationMs: 60000)]);
      await settle(tester);
      expect(scroll(tester).pixels, 0);
    });

    testWidgets('scrolled by the user while the page comes in: left where '
        'they are', (tester) async {
      _albumTracks = long;
      final nav = GlobalKey<NavigatorState>();
      await open(tester, playing: [long[24]], pushedOn: nav);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AlbumTrackListTile), findsWidgets);
      scroll(tester).jumpTo(40);
      await settle(tester);
      expect(scroll(tester).pixels, 40);
    });

    testWidgets('the record pulled out as the page comes in: left alone', (
      tester,
    ) async {
      _albumTracks = long;
      final nav = GlobalKey<NavigatorState>();
      await open(tester, playing: [long[24]], pushedOn: nav);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final pull = await tester.startGesture(const Offset(200, 500));
      for (var i = 0; i < 3; i++) {
        await pull.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The transition is over, the finger still down.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(scroll(tester).pixels, lessThan(0));
      await pull.up();
      await settle(tester);
      expect(scroll(tester).pixels, closeTo(0, 1));
    });

    testWidgets('a touch on its way stops it there', (tester) async {
      _albumTracks = long;
      final nav = GlobalKey<NavigatorState>();
      await open(tester, playing: [long[24]], pushedOn: nav);
      // Frames until the list starts moving, once the page is in.
      bool moving() =>
          find.byType(CustomScrollView).evaluate().isNotEmpty &&
          scroll(tester).pixels > 0;
      for (var i = 0; i < 30 && !moving(); i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 50));
      final touch = await tester.startGesture(const Offset(200, 600));
      await tester.pump();
      await touch.up();
      final stopped = scroll(tester).pixels;
      expect(stopped, greaterThan(0), reason: 'it was on its way');
      await settle(tester);
      expect(scroll(tester).pixels, closeTo(stopped, 1));
      // Not brought on to the middle afterwards.
      if (playingRow().evaluate().isNotEmpty) {
        final row = tester.getRect(playingRow());
        expect((row.center.dy - middle(tester)).abs(), greaterThan(50));
      }
    });

    testWidgets('pushed: it waits for the page to be in, then comes to it', (
      tester,
    ) async {
      _albumTracks = long;
      final nav = GlobalKey<NavigatorState>();
      await open(tester, playing: [long[24]], pushedOn: nav);
      // Frames of the transition: a scroll started now would show.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(scroll(tester).pixels, 0, reason: 'still coming in');
      await settle(tester);
      final row = find.byWidgetPredicate(
        (w) => w is AlbumTrackListTile && w.track.id == 's24',
      );
      expect(tester.getRect(row).center.dy, closeTo(middle(tester), 1));
    });

    testWidgets('rows above taller than the first: still brought to the '
        'middle', (tester) async {
      // Songs by a guest carry a second line, which makes their rows
      // taller at a large font size: the first row alone underestimates
      // where the song is.
      // The rows built at first are the short ones, the tall ones lie
      // between them and the song.
      _albumTracks = [
        ...long.take(13),
        for (var i = 13; i < 24; i++) _guest('s$i'),
        ...long.skip(24),
      ];
      await open(tester, playing: [long[24]], textScale: 2);
      await settle(tester);
      final row = find.byWidgetPredicate(
        (w) => w is AlbumTrackListTile && w.track.id == 's24',
      );
      expect(tester.getRect(row).center.dy, closeTo(middle(tester), 1));
    });
  });

  test('the pull eases towards its limit', () {
    final out = [
      for (final p in const [0.0, 40.0, 80.0, 400.0, 4000.0])
        albumRecordPullOut(p),
    ];
    expect(out.first, 0);
    for (var i = 1; i < out.length; i++) {
      expect(out[i], greaterThan(out[i - 1]));
    }
    expect(out.last, lessThan(28));
  });
}
