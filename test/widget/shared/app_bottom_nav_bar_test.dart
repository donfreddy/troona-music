import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:dartz/dartz.dart';
import 'package:flutter/semantics.dart';
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
          .map((p) => p.painter)
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

  testWidgets('a swipe on the mini player\'s song plays the next one, or '
      'the previous one', (tester) async {
    final tracks = [
      for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
    ];
    final bloc = await pump(tester, AppTab.home, queue: tracks, start: 1);
    expect((bloc.state as PlayerActive).currentTrack.id, 'b');

    Future<void> swipe(double dx) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Title b')),
      );
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(Offset(dx / 12, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await swipe(-120);
    expect(port.skipNextCalls, 1);
    await swipe(120);
    // The previous song itself, not back to the start of this one.
    expect(port.indexJumps, [0]);
    expect(port.skipPreviousCalls, 0);

    // Short: nothing.
    await swipe(-40);
    expect(port.skipNextCalls, 1);
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
