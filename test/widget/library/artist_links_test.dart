import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/library/presentation/widgets/album_artist_links.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/features/player/presentation/widgets/track_title_switcher.dart';
import 'package:troona/l10n/app_localizations.dart';

const _burna = ArtistCredit(id: 11, name: 'Burna Boy');
const _ed = ArtistCredit(id: 12, name: 'Ed Sheeran');

Track _song(List<ArtistCredit> credits, {String id = 's'}) => Track(
  id: id,
  title: 'For My Hand',
  artist: credits.map((c) => c.name).join(', '),
  artistId: credits.isEmpty ? 0 : credits.first.id,
  credits: credits,
  album: 'Love, Damini',
  albumId: 1,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 0,
  fileName: '$id.mp3',
);

/// The library as it is now: a song may have been retagged since queued.
final class _Library implements LibraryRepository {
  _Library(this.tracks);
  final Map<String, Track> tracks;

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      right([for (final id in ids) ?tracks[id]]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Now Playing artist line', () {
    Future<List<Track>> show(WidgetTester tester, Track track) async {
      final taps = <Track>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: TrackTitleSwitcher(
                  track: track,
                  index: 0,
                  queueLength: 1,
                  onArtistTap: taps.add,
                ),
              ),
            ),
          ),
        ),
      );
      return taps;
    }

    testWidgets("a tap on the artist's name follows the link", (tester) async {
      final track = _song([_burna]);
      final taps = await show(tester, track);
      await tester.tap(find.text('Burna Boy'));
      expect(taps, [track]);
    });

    testWidgets('its target is 44 dp tall, the name at its top', (
      tester,
    ) async {
      final track = _song([_burna]);
      final taps = await show(tester, track);
      final link = tester.getRect(
        find.byKey(const ValueKey('nowPlayingArtistLink')),
      );
      expect(link.height, greaterThanOrEqualTo(44));
      expect(tester.getRect(find.text('Burna Boy')).top, link.top);

      // Below the name, still the link.
      await tester.tapAt(link.bottomCenter - const Offset(0, 4));
      expect(taps, [track]);
    });

    testWidgets('while titles swap, the leaving one takes no tap', (
      tester,
    ) async {
      final taps = <Track>[];
      Widget at(Track track, int index) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: TrackTitleSwitcher(
                track: track,
                index: index,
                queueLength: 2,
                onArtistTap: taps.add,
              ),
            ),
          ),
        ),
      );
      final before = _song([_ed], id: 'a');
      final after = _song([_burna], id: 'b');
      await tester.pumpWidget(at(before, 0));
      await tester.pumpWidget(at(after, 1));
      await tester.pump(const Duration(milliseconds: 100));
      // Both lines are there mid-swap: the leaving one opens nothing.
      await tester.tap(find.text('Ed Sheeran'), warnIfMissed: false);
      expect(taps, isNot(contains(before)));
      await tester.tap(find.text('Burna Boy'), warnIfMissed: false);
      expect(taps.last, after);
      await tester.pumpAndSettle();
    });

    testWidgets('a song without an artist links nowhere', (tester) async {
      final taps = await show(tester, _song(const []));
      await tester.tap(find.text('Unknown artist'));
      expect(taps, isEmpty);
      expect(
        find.ancestor(
          of: find.text('Unknown artist'),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.button ?? false),
          ),
        ),
        findsNothing,
      );
    });
  });

  group('openArtistOf', () {
    late List<String> opened;
    late GoRouter router;

    /// The tabs as the app has them, each with its artist pages, and Now
    /// Playing over them. Returns the context of the page shown: the Home
    /// tab's, or Now Playing's when [nowPlaying].
    Future<BuildContext> pump(
      WidgetTester tester,
      Map<String, Track> library, {
      bool nowPlaying = false,
    }) async {
      getIt.registerSingleton(GetTracksByIdsUseCase(_Library(library)));
      addTearDown(getIt.reset);
      opened = [];
      late BuildContext shown;
      final root = GlobalKey<NavigatorState>();
      GoRoute tab(String path) => GoRoute(
        path: path,
        builder: (context, _) {
          shown = context;
          return Scaffold(body: Text(path));
        },
        routes: [
          GoRoute(
            path: 'artists/:id',
            builder: (_, state) {
              opened.add('${state.uri}');
              return const Scaffold();
            },
          ),
        ],
      );
      router = GoRouter(
        navigatorKey: root,
        initialLocation: AppRoute.home,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(routes: [tab(AppRoute.home)]),
              StatefulShellBranch(routes: [tab(AppRoute.library)]),
            ],
          ),
          GoRoute(
            path: AppRoute.player,
            parentNavigatorKey: root,
            builder: (context, _) {
              shown = context;
              return const Scaffold(body: Text('Now Playing'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      if (nowPlaying) {
        router.push(AppRoute.player);
        await tester.pumpAndSettle();
      }
      return shown;
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    testWidgets('one artist: their page at once', (tester) async {
      final song = _song([_burna]);
      final home = await pump(tester, {'s': song});
      openArtistOf(home, song);
      await settle(tester);
      expect(opened, ['/home/artists/11']);
    });

    testWidgets('several artists: a choice, then the one picked', (
      tester,
    ) async {
      final song = _song([_burna, _ed]);
      final home = await pump(tester, {'s': song});
      openArtistOf(home, song);
      await settle(tester);
      expect(opened, isEmpty);
      expect(find.text('Burna Boy'), findsOneWidget);

      await tester.tap(find.text('Ed Sheeran'));
      await settle(tester);
      expect(opened, ['/home/artists/12']);
    });

    testWidgets('a double tap asks once', (tester) async {
      final song = _song([_burna, _ed]);
      final home = await pump(tester, {'s': song});
      openArtistOf(home, song);
      openArtistOf(home, song);
      await settle(tester);
      expect(find.text('Go to artist'), findsOneWidget);
    });

    testWidgets("the library's credits, not the queued song's", (tester) async {
      final queued = _song([_burna]);
      final home = await pump(tester, {
        's': _song([_ed]),
      });
      openArtistOf(home, queued);
      await settle(tester);
      expect(opened, ['/home/artists/12']);
    });

    testWidgets('from Now Playing: it closes, the artist opens in the tab '
        'below, and back returns there', (tester) async {
      final song = _song([_ed]);
      final player = await pump(tester, {'s': song}, nowPlaying: true);
      openArtistOf(player, song, origin: TrackActionOrigin.nowPlaying);
      await settle(tester);
      expect(opened, ['/home/artists/12']);
      expect(find.text('Now Playing'), findsNothing);

      router.pop();
      await settle(tester);
      expect(router.state.uri.path, AppRoute.home);
    });

    testWidgets('from Now Playing, several artists: the one picked, in the '
        'tab below', (tester) async {
      final song = _song([_burna, _ed]);
      final player = await pump(tester, {'s': song}, nowPlaying: true);
      openArtistOf(player, song, origin: TrackActionOrigin.nowPlaying);
      await settle(tester);
      await tester.tap(find.text('Burna Boy'));
      await settle(tester);
      expect(opened, ['/home/artists/11']);
      expect(find.text('Now Playing'), findsNothing);
    });

    testWidgets('a song gone from the library keeps its own', (tester) async {
      final queued = _song([_burna]);
      final home = await pump(tester, const {});
      openArtistOf(home, queued);
      await settle(tester);
      expect(opened, ['/home/artists/11']);
    });
  });

  group('album artists', () {
    Future<List<String>> show(WidgetTester tester, Album album) async {
      final opened = <String>[];
      final router = GoRouter(
        initialLocation: '/library/albums/7',
        routes: [
          GoRoute(
            path: '/library/albums/7',
            builder: (_, _) => Scaffold(
              body: Center(child: AlbumArtistLinks(album: album)),
            ),
          ),
          GoRoute(
            path: '/library/artists/:id',
            builder: (_, state) {
              opened.add(state.pathParameters['id']!);
              return const Scaffold();
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      return opened;
    }

    Album album(List<ArtistCredit> credits) => Album(
      id: '7',
      name: 'Love, Damini',
      artist: credits.map((c) => c.name).join(', '),
      artistId: credits.isEmpty ? 0 : credits.first.id,
      trackCount: 2,
      credits: credits,
    );

    testWidgets('two artists: one line, then a choice of either', (
      tester,
    ) async {
      final opened = await show(tester, album([_burna, _ed]));
      expect(find.text('Burna Boy, Ed Sheeran'), findsOneWidget);

      await tester.tap(find.text('Burna Boy, Ed Sheeran'));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
      await tester.tap(find.text('Ed Sheeran'));
      await tester.pumpAndSettle();
      expect(opened, ['12']);

      GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Burna Boy, Ed Sheeran'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Burna Boy'));
      await tester.pumpAndSettle();
      expect(opened, ['12', '11']);
    });

    testWidgets('one artist: their page at once, from a 44 dp target', (
      tester,
    ) async {
      final opened = await show(tester, album([_burna]));
      expect(
        tester.getSize(find.byType(AlbumArtistLinks)).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('Burna Boy'));
      await tester.pumpAndSettle();
      expect(opened, ['11']);
    });

    testWidgets('an album read without its songs still links its artist', (
      tester,
    ) async {
      const read = Album(
        id: '7',
        name: 'Love, Damini',
        artist: 'Burna Boy',
        artistId: 11,
        trackCount: 2,
      );
      final opened = await show(tester, read);
      await tester.tap(find.text('Burna Boy'));
      await tester.pumpAndSettle();
      expect(opened, ['11']);
    });

    testWidgets('a compilation names nobody to open', (tester) async {
      final opened = await show(tester, album(const []));
      expect(find.byType(InkWell), findsNothing);
      await tester.tap(find.text('Unknown artist'));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
    });
  });
}
