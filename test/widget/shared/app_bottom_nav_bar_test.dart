import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/shared/widgets/glass_edge.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/like_burst.dart';
import 'package:flutter/rendering.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

import '../../helpers/fake_player.dart';

final class _Likes implements LibraryRepository {
  final liked = <String>{};

  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async =>
      right(Playlist(id: 'likes', name: 'Likes', trackIds: [...liked]));

  @override
  Future<Either<Failure, bool>> isTrackInLikes(String trackId) async =>
      right(liked.contains(trackId));

  @override
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId) async {
    liked.add(trackId);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> removeTrackFromLikes(String trackId) async {
    liked.remove(trackId);
    return right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAudioPort port;
  late _Likes likes;

  Future<PlayerBloc> pump(
    WidgetTester tester,
    AppTab tab, {
    List<Track>? queue,
    int start = 0,
    bool reduceMotion = false,
    GlassQuality glass = GlassQuality.high,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort();
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    if (queue != null) {
      port
        ..queue = Queue.fromTracks(queue, startIndex: start)
        ..duration = const Duration(minutes: 3);
      bloc.add(QueueSetRequested(queue, startIndex: start));
      await tester.pump();
      port.status.add(PlaybackStatus.playing);
      await tester.pump();
    }
    likes = _Likes();
    final likesCubit = LikesCubit(
      addTrack: AddTrackToLikesUseCase(likes),
      removeTrack: RemoveTrackFromLikesUseCase(likes),
      isTrackLiked: IsTrackInLikesUseCase(likes),
      getLikesPlaylist: GetLikesPlaylistUseCase(likes),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(likesCubit.close());
      unawaited(port.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: likesCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.withGlass(glass),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNavBar(currentTab: tab, onTabChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  /// Scale of the dot of each tab, in tab order.
  List<double> dotScales(WidgetTester tester) => [
    for (final element in find.byKey(const ValueKey('tabDot')).evaluate())
      tester
          .widget<AnimatedScale>(
            find.ancestor(
              of: find.byWidget(element.widget),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale,
  ];

  testWidgets('the bar blurs on full glass only: balanced and no blur draw '
      'an opaque tint with its edge', (tester) async {
    final queue = [testTrack('a', durationMs: 180000)];
    for (final (glass, blurs) in [
      (GlassQuality.high, 1),
      (GlassQuality.low, 0),
      (GlassQuality.off, 0),
    ]) {
      await pump(tester, AppTab.home, queue: queue, glass: glass);
      expect(
        find.byType(BackdropFilter),
        findsNWidgets(blurs),
        reason: glass.name,
      );
      if (blurs == 0) {
        final box = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(AppBottomNavBar),
                matching: find.byType(Container),
              ),
            )
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .first;
        expect(box.color!.a, greaterThan(.87), reason: glass.name);
      }
      // On every tier: the shared edge, and a shadow under the bar.
      final edges = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(AppBottomNavBar),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((p) => p.foregroundPainter)
          .whereType<GlassEdgePainter>();
      expect(edges.first.width, greaterThan(0), reason: glass.name);
      final shadows = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(AppBottomNavBar),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((p) => p.foregroundPainter)
          .whereType<OuterShadowPainter>();
      expect(shadows, isNotEmpty, reason: glass.name);
    }
  });

  testWidgets('a dot shows under the selected tab only, and follows it', (
    tester,
  ) async {
    await pump(tester, AppTab.home);
    expect(dotScales(tester), [1, 0, 0, 0]);

    await pump(tester, AppTab.search);
    expect(dotScales(tester), [0, 0, 1, 0]);
  });

  testWidgets('the dot sits under its icon, which stays centred in the row', (
    tester,
  ) async {
    await pump(tester, AppTab.library);
    final icon = tester.getRect(find.byIcon(AppIcons.library));
    final dot = tester.getRect(find.byKey(const ValueKey('tabDot')).at(1));
    expect(dot.center.dx, closeTo(icon.center.dx, .01));
    expect(dot.top, greaterThan(icon.bottom));

    // Same height as the tabs without a dot.
    final home = tester.getRect(find.byIcon(AppIcons.home));
    expect(icon.center.dy, home.center.dy);
  });

  testWidgets('screen readers still hear which tab is selected', (
    tester,
  ) async {
    await pump(tester, AppTab.playlists);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppBottomNavBar)),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(l10n.navPlaylists)),
      matchesSemantics(
        label: l10n.navPlaylists,
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
  });

  group('the mini player\'s song carousel', () {
    final tracks = [
      for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
    ];

    Finder title(String id) => find.text('Title $id');
    double xOf(WidgetTester tester, String id) =>
        tester.getTopLeft(title(id)).dx;
    double opacityOf(WidgetTester tester, String id) => tester
        .widget<Opacity>(
          find.ancestor(of: title(id), matching: find.byType(Opacity)).first,
        )
        .opacity;

    /// Where the cover's images are: the song's, and the old one fading.
    List<Rect> coverAt(WidgetTester tester) => [
      for (final element
          in find
              .descendant(
                of: find
                    .ancestor(
                      of: find.byType(LikeBurst),
                      matching: find.byType(Stack),
                    )
                    .first,
                matching: find.byType(ArtworkPlaceholder),
              )
              .evaluate())
        switch (element.renderObject) {
          final RenderBox box => box.localToGlobal(Offset.zero) & box.size,
          _ => Rect.zero,
        },
    ];

    /// Every image of the cover sits at [cover], where it was at rest.
    void expectCoverAt(WidgetTester tester, List<Rect> cover, [String? why]) {
      expect(cover, hasLength(1));
      for (final rect in coverAt(tester)) {
        expect(rect, cover.single, reason: why);
      }
    }

    Finder oldCover() => find.byWidgetPredicate(
      (w) => w is FadeTransition && w.opacity is ReverseAnimation,
    );
    int masks(WidgetTester tester) =>
        tester.layers.whereType<ShaderMaskLayer>().length;

    /// The engine moves on to [index], as after a jump.
    Future<void> engineTo(WidgetTester tester, int index) async {
      port.queue = Queue.fromTracks(tracks, startIndex: index);
      port.track.add(tracks[index]);
      // The bloc hears it, then the bar rebuilds.
      await tester.pump();
      await tester.pump();
    }

    /// Drags the song [from] by [dx] and keeps the finger down.
    Future<TestGesture> drag(
      WidgetTester tester,
      double dx, {
      String from = 'b',
    }) async {
      final gesture = await tester.startGesture(tester.getCenter(title(from)));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(dx / 10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      return gesture;
    }

    testWidgets('the next title comes in with the finger; the cover stays', (
      tester,
    ) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      final rest = xOf(tester, 'b');
      final cover = coverAt(tester);
      expect(title('c'), findsNothing);

      final gesture = await drag(tester, -100);
      expectCoverAt(tester, cover);
      // Past the touch slop, the titles follow the finger.
      expect(xOf(tester, 'b'), lessThan(rest - 60));
      // The neighbour, one text width along, each fading with its
      // distance from the middle.
      final span = xOf(tester, 'c') - xOf(tester, 'b');
      expect(span, greaterThan(100));
      expect(
        opacityOf(tester, 'c'),
        moreOrLessEquals(1 - (xOf(tester, 'c') - rest) / span, epsilon: .01),
      );
      expect(
        opacityOf(tester, 'b'),
        moreOrLessEquals(1 - (rest - xOf(tester, 'b')) / span, epsilon: .01),
      );
      expect(title('a'), findsNothing);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [2]);
      await engineTo(tester, 2);
      // The old cover fades out over the new one, in place.
      expect(oldCover(), findsOneWidget);
      final xs = <double>[];
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expectCoverAt(tester, cover, 'frame $i');
        xs.add(xOf(tester, 'c'));
      }
      await tester.pumpAndSettle();
      expect(xOf(tester, 'c'), moreOrLessEquals(rest));
      // Right to left all the way: never back the other way.
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], lessThanOrEqualTo(xs[i - 1]), reason: '$xs');
      }
      expect(title('b'), findsNothing);
      expectCoverAt(tester, cover);
    });

    testWidgets('a swipe right plays the previous song itself, which comes '
        'in from the left', (tester) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      final rest = xOf(tester, 'b');

      final gesture = await drag(tester, 100);
      expect(xOf(tester, 'a'), lessThan(xOf(tester, 'b')));
      expect(title('c'), findsNothing);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [0]);
      expect(port.skipPreviousCalls, 0);

      await engineTo(tester, 0);
      await tester.pump(const Duration(milliseconds: 50));
      expect(xOf(tester, 'a'), lessThan(rest));
      // The old song leaves to the right, fading out.
      expect(xOf(tester, 'b'), greaterThan(rest));
      await tester.pumpAndSettle();
      expect(xOf(tester, 'a'), moreOrLessEquals(rest));
    });

    testWidgets('a short swipe springs back; one the player never answers '
        'puts the song back', (tester) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      final rest = xOf(tester, 'b');

      await (await drag(tester, -40)).up();
      await tester.pumpAndSettle();
      expect(port.indexJumps, isEmpty);
      expect(xOf(tester, 'b'), moreOrLessEquals(rest));
      expect(title('c'), findsNothing);

      await (await drag(tester, -100)).up();
      await tester.pumpAndSettle();
      expect(port.indexJumps, [2]);
      // Still the old song: it comes back once the player had its chance.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(xOf(tester, 'b'), moreOrLessEquals(rest));
      expect(opacityOf(tester, 'b'), 1);
      expect(title('c'), findsNothing);
    });

    testWidgets('no song that way: the finger meets resistance, nothing '
        'shows', (tester) async {
      await pump(tester, AppTab.home, queue: tracks, start: 2);
      final rest = tester.getTopLeft(title('c')).dx;

      final gesture = await drag(tester, -100, from: 'c');
      expect(tester.getTopLeft(title('c')).dx, greaterThan(rest - 30));
      expect(title('a'), findsNothing);
      expect(title('b'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(port.indexJumps, isEmpty);
    });

    testWidgets('under repeat all, the last song swipes round to the first', (
      tester,
    ) async {
      await pump(tester, AppTab.home, queue: tracks, start: 2);
      port.queueCtrl.add(
        Queue.fromTracks(tracks, startIndex: 2, repeatMode: RepeatMode.all),
      );
      await tester.pump();

      final gesture = await drag(tester, -100, from: 'c');
      expect(title('a'), findsOneWidget);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [0]);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('while titles move both edges fade; at rest no mask', (
      tester,
    ) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      expect(masks(tester), 0);
      final gesture = await drag(tester, -100);
      expect(masks(tester), 1);
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(masks(tester), 0);
    });

    testWidgets('a quick swipe after Next goes on to the song after, not '
        'back', (tester) async {
      await pump(tester, AppTab.home, queue: tracks, start: 0);
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
      await engineTo(tester, 1);
      // The new title still settling from the right, a short left drag.
      await tester.pump(const Duration(milliseconds: 20));
      final gesture = await tester.startGesture(tester.getCenter(title('b')));
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(-15, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [2]);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('a fling short of the threshold still changes song', (
      tester,
    ) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      await tester.fling(title('b'), const Offset(-50, 0), 1500);
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [2]);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('while a swipe waits for its song, Next and other swipes '
        'wait too', (tester) async {
      await pump(tester, AppTab.home, queue: tracks, start: 0);
      await (await drag(tester, -100, from: 'a')).up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [1]);
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
      expect(port.skipNextCalls, 0);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('under repeat one, Next replays the song and swipes stay '
        'free', (tester) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      port.queueCtrl.add(
        Queue.fromTracks(tracks, startIndex: 1, repeatMode: RepeatMode.one),
      );
      // The bloc hears it, then the bar rebuilds.
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
      expect(port.skipNextCalls, 1);
      // Right after: a swipe still goes to the next song itself.
      await (await drag(tester, -100)).up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [2]);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('a song changing under the finger ends that drag', (
      tester,
    ) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      final rest = xOf(tester, 'b');
      final gesture = await drag(tester, -100);
      await engineTo(tester, 2);
      await tester.pumpAndSettle();
      expect(xOf(tester, 'c'), moreOrLessEquals(rest));
      // The finger goes on: nothing follows it, nothing is sent.
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      expect(xOf(tester, 'c'), moreOrLessEquals(rest));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(port.indexJumps, isEmpty);
    });

    testWidgets('screen readers read the song playing only, even while it '
        'is moved out', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      final gesture = await drag(tester, -100);
      expect(find.bySemanticsLabel(RegExp('Title c')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Title b')), findsOneWidget);
      await gesture.up();
      // Waiting for the player: the song is moved out of sight, still read.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacityOf(tester, 'b'), 0);
      expect(find.bySemanticsLabel(RegExp('Title b')), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      semantics.dispose();
    });

    testWidgets('under repeat all with two songs, either way is the other', (
      tester,
    ) async {
      final two = tracks.take(2).toList();
      await pump(tester, AppTab.home, queue: two, start: 0);
      port.queueCtrl.add(
        Queue.fromTracks(two, startIndex: 0, repeatMode: RepeatMode.all),
      );
      await tester.pump();
      final gesture = await drag(tester, 100, from: 'a');
      // From the left, as the song before.
      expect(xOf(tester, 'b'), lessThan(xOf(tester, 'a')));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.indexJumps, [1]);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('the cover keeps its image across a change, so the old one '
        'shows until the new one is decoded', (tester) async {
      for (final track in tracks) {
        track.artworkPath = '/covers/${track.id}.jpg';
      }
      addTearDown(() {
        for (final track in tracks) {
          track.artworkPath = null;
        }
      });
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      Finder heroImage() => find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is Hero && w.tag == NowPlayingHero.artworkTag,
        ),
        matching: find.byType(Image),
      );
      final before = tester.state(heroImage());
      await engineTo(tester, 2);
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(heroImage());
      expect(tester.state(heroImage()), same(before));
      expect(image.gaplessPlayback, isTrue);
      expect((image.image as FileImage).file.path, '/covers/c.jpg');
    });

    testWidgets('leaving while a swipe waits leaves nothing behind', (
      tester,
    ) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      await (await drag(tester, -100)).up();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      // A timer or ticker left running would fail the test here.
    });

    testWidgets('Next slides the new song in from the right', (tester) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      final rest = xOf(tester, 'b');
      final cover = coverAt(tester);

      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
      expect(port.skipNextCalls, 1);
      await engineTo(tester, 2);
      await tester.pump(const Duration(milliseconds: 50));
      expect(xOf(tester, 'c'), greaterThan(rest + 10));
      expectCoverAt(tester, cover);
      await tester.pumpAndSettle();
      expect(xOf(tester, 'c'), moreOrLessEquals(rest));
    });

    testWidgets('a change from elsewhere fades in place: nothing slides', (
      tester,
    ) async {
      await pump(tester, AppTab.home, queue: tracks, start: 1);
      final rest = xOf(tester, 'b');

      await engineTo(tester, 2);
      await tester.pump(const Duration(milliseconds: 80));
      expect(xOf(tester, 'c'), moreOrLessEquals(rest));
      expect(xOf(tester, 'b'), moreOrLessEquals(rest));
      expect(opacityOf(tester, 'c'), inExclusiveRange(0, 1));
      expect(opacityOf(tester, 'b'), inExclusiveRange(0, 1));
      // The old cover fades out over the new one.
      expect(
        find.byWidgetPredicate(
          (w) => w is FadeTransition && w.opacity is ReverseAnimation,
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(title('b'), findsNothing);
      expect(opacityOf(tester, 'c'), 1);
      expect(
        find.byWidgetPredicate(
          (w) => w is FadeTransition && w.opacity is ReverseAnimation,
        ),
        findsNothing,
      );
    });

    testWidgets('with reduced motion a swipe still changes song, and the '
        'titles fade in place', (tester) async {
      await pump(
        tester,
        AppTab.home,
        queue: tracks,
        start: 1,
        reduceMotion: true,
      );
      final rest = xOf(tester, 'b');

      await (await drag(tester, -100)).up();
      await tester.pump();
      expect(port.indexJumps, [2]);
      expect(xOf(tester, 'b'), moreOrLessEquals(rest));
      await engineTo(tester, 2);
      await tester.pump(const Duration(milliseconds: 80));
      expect(xOf(tester, 'c'), moreOrLessEquals(rest));
      expect(opacityOf(tester, 'c'), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('a swipe down on the mini player closes it, the bar coming '
      'down in one movement', (tester) async {
    final bloc = await pump(
      tester,
      AppTab.home,
      queue: [testTrack('a', durationMs: 60000)],
    );
    double barTop() => tester.getTopLeft(find.byType(AppBottomNavBar)).dy;
    final tops = [barTop()];
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Title a')),
    );
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump(const Duration(milliseconds: 16));
      tops.add(barTop());
    }
    await gesture.up();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      tops.add(barTop());
    }
    await tester.pumpAndSettle();
    tops.add(barTop());
    expect(bloc.state, isA<PlayerIdle>());
    expect(find.text('Title a'), findsNothing);
    // Down all the way, never back up, and down already under the finger.
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThanOrEqualTo(tops[i - 1]), reason: '$tops');
    }
    expect(tops[6], greaterThan(tops[0] + 40));
    // Nothing left once the player is idle: no second shrink after it.
    final idleAt = tops.length - 1;
    expect(tops[idleAt], tops[idleAt - 20]);
  });

  testWidgets('a short swipe down springs back and keeps playing', (
    tester,
  ) async {
    final bloc = await pump(
      tester,
      AppTab.home,
      queue: [testTrack('a', durationMs: 60000)],
    );
    final rest = tester.getTopLeft(find.text('Title a'));
    final barHeight = tester.getSize(find.byType(AppBottomNavBar)).height;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Title a')),
    );
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // The bar's top edge follows the finger: the bar itself shrinks.
    expect(tester.getTopLeft(find.text('Title a')).dy, greaterThan(rest.dy));
    expect(
      tester.getSize(find.byType(AppBottomNavBar)).height,
      moreOrLessEquals(barHeight - 40, epsilon: 20),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(bloc.state, isA<PlayerActive>());
    expect(tester.getTopLeft(find.text('Title a')), rest);
  });

  testWidgets('a song played while the row leaves keeps it', (tester) async {
    final tracks = [
      for (final id in ['a', 'b']) testTrack(id, durationMs: 60000),
    ];
    final bloc = await pump(tester, AppTab.home, queue: tracks);
    final rest = tester.getTopLeft(find.text('Title a'));
    await tester.fling(find.text('Title a'), const Offset(0, 60), 1500);
    await tester.pump();
    // Mid-way out, the engine moves on to another song.
    port.queue = Queue.fromTracks(tracks, startIndex: 1);
    port.track.add(tracks[1]);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(bloc.state, isA<PlayerActive>());
    // Back in place, fully shown.
    expect(tester.getTopLeft(find.text('Title b')), rest);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('Title b'),
                  matching: find.byType(Opacity),
                )
                .last,
          )
          .opacity,
      1,
    );
  });

  testWidgets('the mini player\'s fill moves on every position tick', (
    tester,
  ) async {
    await pump(
      tester,
      AppTab.home,
      queue: [testTrack('a', durationMs: 180000)],
    );
    CustomPainter painter() => tester
        .widget<CustomPaint>(find.byKey(const ValueKey('miniPlayerFill')))
        .painter!;

    // just_audio ticks every 200 ms on a 3 minute song: each tick must
    // repaint, not one in five.
    var previous = painter();
    for (var ms = 200; ms <= 1000; ms += 200) {
      port.position.add(Duration(milliseconds: ms));
      await tester.pump();
      final current = painter();
      expect(current.shouldRepaint(previous), isTrue, reason: 'at $ms ms');
      previous = current;
    }
  });

  testWidgets('a long press on the mini player likes the song, and again '
      'takes it back', (tester) async {
    await pump(tester, AppTab.home, queue: [testTrack('a', durationMs: 60000)]);
    final burst = find.byKey(const ValueKey('likeBurst'));

    await tester.longPress(find.text('Title a'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(likes.liked, {'a'});
    expect(burst, findsOneWidget);
    expect(find.text('Added to Liked songs'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(burst, findsNothing, reason: 'the heart fades away');

    await tester.longPress(find.text('Title a'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(likes.liked, isEmpty);
    expect(find.text('Removed from Liked songs'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Next keeps its button.
    expect(find.byTooltip('Next'), findsOneWidget);
  });

  testWidgets('screen readers get the like as an action', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, AppTab.home, queue: [testTrack('a', durationMs: 60000)]);

    final node = tester.getSemantics(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.customSemanticsActions != null,
      ),
    );
    final labels = [
      for (final id in node.getSemanticsData().customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)?.label,
    ];
    expect(labels, contains('Like'));
    handle.dispose();
  });

  testWidgets('no heart with reduced motion: the toast says it', (
    tester,
  ) async {
    await pump(
      tester,
      AppTab.home,
      queue: [testTrack('a', durationMs: 60000)],
      reduceMotion: true,
    );

    await tester.longPress(find.text('Title a'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(likes.liked, {'a'});
    expect(find.byKey(const ValueKey('likeBurst')), findsNothing);
    expect(find.text('Added to Liked songs'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  group('songs queued by hand', () {
    final songs = [
      for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
    ];
    final extra = testTrack('x', durationMs: 60000);
    const badge = ValueKey('queuedBadge');

    double badgeOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(badge),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    String badgeText(WidgetTester tester) => tester
        .widget<Text>(
          find.descendant(of: find.byKey(badge), matching: find.byType(Text)),
        )
        .data!;

    double coverScale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find.descendant(
            of: find
                .ancestor(of: find.byKey(badge), matching: find.byType(Stack))
                .first,
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    /// The largest the cover grows over the next half second, frame by
    /// frame: the edit runs through the bloc, its notice comes frames later.
    Future<double> peakScale(WidgetTester tester) async {
      var peak = coverScale(tester);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        peak = math.max(peak, coverScale(tester));
      }
      return peak;
    }

    testWidgets('the cover pulses and counts them, then the count leaves', (
      tester,
    ) async {
      final bloc = await pump(tester, AppTab.home, queue: songs);
      expect(badgeOpacity(tester), 0);

      bloc.add(TrackAddedToQueue(extra));
      expect(await peakScale(tester), greaterThan(1.05));
      expect(badgeOpacity(tester), 1);
      expect(badgeText(tester), '+1');
      expect(coverScale(tester), 1, reason: 'one pulse, then at rest');

      // An album queued next: its songs add up in the same badge.
      bloc.add(TracksQueued([songs[1], songs[2]], next: true));
      expect(await peakScale(tester), greaterThan(1.05));
      expect(badgeText(tester), '+3');

      await tester.pump(const Duration(seconds: 2));
      expect(badgeOpacity(tester), 0);

      // A song queued later counts from one again.
      bloc.add(TrackAddedToQueue(extra));
      await peakScale(tester);
      expect(badgeText(tester), '+1');
      expect(badgeOpacity(tester), 1);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('songs queued in a row pulse once: no restart halfway', (
      tester,
    ) async {
      final bloc = await pump(tester, AppTab.home, queue: songs);
      bloc.add(TrackAddedToQueue(extra));
      final scales = <double>[];
      var again = false;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        scales.add(coverScale(tester));
        if (!again && coverScale(tester) > 1.05) {
          again = true;
          bloc.add(TrackAddedToQueue(extra));
        }
      }
      expect(again, isTrue);
      // One swell: never back near rest between two grown frames.
      final first = scales.indexWhere((scale) => scale > 1.05);
      final last = scales.lastIndexWhere((scale) => scale > 1.05);
      for (var i = first; i <= last; i++) {
        expect(scales[i], greaterThan(1.03), reason: 'frame $i: $scales');
      }
      expect(badgeText(tester), '+2');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('the count stays when the song changes right after', (
      tester,
    ) async {
      final bloc = await pump(tester, AppTab.home, queue: songs);
      bloc.add(TracksQueued([extra], next: true));
      await peakScale(tester);
      expect(badgeText(tester), '+1');

      // The engine moves on to it.
      port.queue = Queue.fromTracks(port.queue!.playbackTracks, startIndex: 1);
      port.track.add(extra);
      await tester.pump();
      await tester.pump();
      expect(find.text('Title x'), findsWidgets);
      expect(badgeOpacity(tester), 1);
      expect(badgeText(tester), '+1');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('not while Now Playing covers the row: the cover is a hero '
        'in flight', (tester) async {
      final bloc = await pump(tester, AppTab.home, queue: songs);
      addTearDown(() => NowPlayingHero.coverAnimation.value = null);

      // A pulse under way stops when Now Playing comes over.
      bloc.add(TrackAddedToQueue(extra));
      while (coverScale(tester) <= 1.02) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      NowPlayingHero.coverAnimation.value = kAlwaysCompleteAnimation;
      await tester.pump();
      expect(coverScale(tester), 1);

      // None starts under it; the count still goes up.
      bloc.add(TrackAddedToQueue(extra));
      expect(await peakScale(tester), 1);
      expect(badgeText(tester), '+2');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('nothing for a song put back, or one the player refused', (
      tester,
    ) async {
      final bloc = await pump(tester, AppTab.home, queue: songs);

      // A song swiped out of the queue sheet, then put back with Undo.
      const removal = TrackRemovedFromQueue(index: 1, trackId: 'b');
      bloc
        ..add(removal)
        ..add(TrackAddedToQueue(songs[1], index: 1, undoing: removal));
      expect(await peakScale(tester), 1);
      expect(port.queue!.playbackTracks.map((t) => t.id), ['a', 'b', 'c']);
      expect(badgeOpacity(tester), 0);

      port.failEdits = true;
      bloc.add(TrackAddedToQueue(extra));
      expect(await peakScale(tester), 1);
      expect(port.queue!.playbackTracks, hasLength(3));
      expect(badgeOpacity(tester), 0);
    });

    testWidgets('with reduced motion the count shows, the cover stays still', (
      tester,
    ) async {
      final bloc = await pump(
        tester,
        AppTab.home,
        queue: songs,
        reduceMotion: true,
      );
      bloc.add(TrackQueuedNext(extra));
      expect(await peakScale(tester), 1);
      expect(badgeText(tester), '+1');
      expect(badgeOpacity(tester), 1);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });
}
