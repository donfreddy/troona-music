import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_actions.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_bar.dart';
import 'package:troona/features/library/presentation/widgets/selection/track_selection_scope.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/swipe_actions.dart';

import '../../helpers/fake_player.dart';

/// No song liked: enough for the track menu to open.
final class _NoLikes implements LibraryRepository {
  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async =>
      right(const Playlist(id: 'likes', name: 'Likes', trackIds: []));

  @override
  Future<Either<Failure, bool>> isTrackInLikes(String trackId) async =>
      right(false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final songs = [
    for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
  ];

  late TrackSelectionCubit selection;
  late FakeAudioPort port;
  late List<String> plays;

  /// A page of [songs] (a list that can pick unless [scoped] is false),
  /// under a header with a back button, above the actions the shell shows
  /// while songs are picked. [playing] starts a queue first.
  Future<void> pump(
    WidgetTester tester, {
    bool scoped = true,
    ValueListenable<bool>? enabled,
    bool playing = false,
    bool pushed = false,
    bool album = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort()..duration = const Duration(minutes: 1);
    final player = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    selection = TrackSelectionCubit();
    final likes = _NoLikes();
    final likesCubit = LikesCubit(
      addTrack: AddTrackToLikesUseCase(likes),
      removeTrack: RemoveTrackFromLikesUseCase(likes),
      isTrackLiked: IsTrackInLikesUseCase(likes),
      getLikesPlaylist: GetLikesPlaylistUseCase(likes),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(player.close());
      unawaited(port.close());
      unawaited(selection.close());
      unawaited(likesCubit.close());
    });
    if (playing) {
      port.queue = Queue.fromTracks([testTrack('p', durationMs: 60000)]);
      player.add(QueueSetRequested([testTrack('p', durationMs: 60000)]));
      await tester.pump();
      port.status.add(PlaybackStatus.playing);
      await tester.pump();
    }
    plays = [];

    Widget list() => CustomScrollView(
      slivers: [
        GlassSliverHeader.largeTitle(
          title: 'Songs',
          leading: const BackButton(),
        ),
        SliverToBoxAdapter(child: PlayShuffleButtons(tracks: songs)),
        SliverList.list(
          children: [
            for (final (i, song) in songs.indexed)
              album
                  ? AlbumTrackListTile(
                      track: song,
                      number: i + 1,
                      onTap: () => plays.add(song.id),
                    )
                  : TrackListTile(track: song, onTap: () => plays.add(song.id)),
          ],
        ),
      ],
    );

    Widget page() => Scaffold(
      body: Column(
        children: [
          Expanded(
            child: scoped
                ? ValueListenableBuilder(
                    valueListenable: enabled ?? ValueNotifier(true),
                    builder: (_, on, _) => TrackSelectionScope(
                      tracks: songs,
                      enabled: on,
                      child: list(),
                    ),
                  )
                : list(),
          ),
          // The shell's bar, as it shows the actions.
          BlocSelector<TrackSelectionCubit, TrackSelection, bool>(
            selector: (s) => s.active,
            builder: (_, picking) => SizedBox(
              height: 64,
              child: picking ? const SelectionActions() : null,
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: player),
          BlocProvider.value(value: likesCubit),
          BlocProvider.value(value: selection),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: pushed
              ? Builder(
                  builder: (context) => Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => page())),
                      child: const Text('open'),
                    ),
                  ),
                )
              : page(),
        ),
      ),
    );
    if (pushed) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }
  }

  List<String> picked() => [for (final t in selection.state.tracks) t.id];

  Finder row(String id) => find.text('Title $id');

  testWidgets('a long press starts picking, with the count in the header', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(row('b'));
    await tester.pumpAndSettle();

    expect(picked(), ['b']);
    expect(
      find.descendant(
        of: find.byType(GlassSliverHeader),
        matching: find.byType(SelectionBar),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('1 song selected'), findsOneWidget);
    // The navigation row stays below, out of reach.
    final back = find.byType(BackButton);
    expect(back, findsOneWidget);
    expect(
      tester
          .widgetList<IgnorePointer>(
            find.ancestor(of: back, matching: find.byType(IgnorePointer)),
          )
          .any((p) => p.ignoring),
      isTrue,
    );
  });

  testWidgets('while picking, a tap picks or lets go and plays nothing', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(row('b'));
    await tester.pumpAndSettle();

    await tester.tap(row('c'));
    await tester.tap(row('a'));
    await tester.pumpAndSettle();
    // The list's order, not the order picked.
    expect(picked(), ['a', 'b', 'c']);
    expect(find.bySemanticsLabel('3 songs selected'), findsOneWidget);

    await tester.tap(row('b'));
    await tester.tap(row('a'));
    await tester.pumpAndSettle();
    expect(picked(), ['c']);

    // The last one let go ends it, and the header comes back.
    await tester.tap(row('c'));
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
    expect(find.byType(SelectionBar), findsNothing);
    expect(plays, isEmpty);

    // A tap plays again.
    await tester.tap(row('a'));
    expect(plays, ['a']);
  });

  testWidgets('the options button goes and the swipes stop while picking', (
    tester,
  ) async {
    await pump(tester);
    bool swipes() => tester
        .widgetList<SwipeActions>(find.byType(SwipeActions))
        .every((s) => s.onSwipeLeft != null && s.onSwipeRight != null);
    bool optionsIgnored() => tester
        .widgetList<IgnorePointer>(
          find.ancestor(
            of: find.byTooltip('More options').first,
            matching: find.byType(IgnorePointer),
          ),
        )
        .any((p) => p.ignoring);

    expect(swipes(), isTrue);
    expect(optionsIgnored(), isFalse);

    await tester.longPress(row('a'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<SwipeActions>(find.byType(SwipeActions))
          .every((s) => s.onSwipeLeft == null && s.onSwipeRight == null),
      isTrue,
    );
    expect(optionsIgnored(), isTrue);
  });

  testWidgets('a row dragged sideways while picking does not move', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(row('a'));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(row('b'));
    final gesture = await tester.startGesture(tester.getCenter(row('b')));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.getTopLeft(row('b')), before);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(port.queueEdits, isEmpty);
  });

  testWidgets('the page\'s Play and Shuffle step aside while picking', (
    tester,
  ) async {
    // The page's own Play, the first of its two buttons.
    Finder pagePlay() => find
        .descendant(
          of: find.byType(PlayShuffleButtons),
          matching: find.byType(AppButton),
        )
        .first;
    await pump(tester);
    await tester.longPress(row('a'));
    await tester.pumpAndSettle();

    await tester.tap(pagePlay(), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(port.lastSetQueue, isNull);
    expect(selection.state.active, isTrue);

    await tester.tap(find.byTooltip('End selection'));
    await tester.pumpAndSettle();
    await tester.tap(pagePlay());
    // Not settled: the song playing draws an equalizer that never stops.
    await tester.pump();
    await tester.pump();
    expect(port.lastSetQueue, isNotNull);
  });

  testWidgets('Select all picks every song, Deselect all ends it', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(row('a'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(picked(), ['a', 'b', 'c']);

    await tester.tap(find.text('Deselect all'));
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
  });

  testWidgets('the close button ends it', (tester) async {
    await pump(tester);
    await tester.longPress(row('a'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('End selection'));
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
  });

  testWidgets('back ends the selection first, then leaves the page', (
    tester,
  ) async {
    await pump(tester, pushed: true);
    await tester.longPress(row('a'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
    expect(row('a'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(row('a'), findsNothing);
  });

  testWidgets('leaving the page ends the selection', (tester) async {
    await pump(tester, pushed: true);
    await tester.longPress(row('a'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(row('a'))).pop();
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
  });

  testWidgets('outside a list that picks, a long press opens the menu', (
    tester,
  ) async {
    for (final (scoped, enabled) in [(false, true), (true, false)]) {
      await pump(tester, scoped: scoped, enabled: ValueNotifier(enabled));
      await tester.longPress(row('a'));
      await tester.pumpAndSettle();
      expect(selection.state.active, isFalse);
      expect(find.text('Play next'), findsWidgets, reason: '$scoped');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a list turned off ends its selection', (tester) async {
    final enabled = ValueNotifier(true);
    await pump(tester, enabled: enabled);
    await tester.longPress(row('a'));
    await tester.pumpAndSettle();
    expect(selection.state.active, isTrue);

    // The same list, off (the Library leaving Songs).
    enabled.value = false;
    await tester.pumpAndSettle();
    expect(selection.state.active, isFalse);
    expect(find.byType(SelectionBar), findsNothing);
  });

  testWidgets('on an album, the ring takes the number\'s place', (
    tester,
  ) async {
    await pump(tester, album: true);
    double numberOpacity() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.text('01'),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;
    expect(numberOpacity(), 1);

    await tester.longPress(find.text('Title a'));
    await tester.pumpAndSettle();
    expect(picked(), ['a']);
    expect(numberOpacity(), 0);
    await tester.tap(find.text('Title b'));
    await tester.pumpAndSettle();
    expect(picked(), ['a', 'b']);
    expect(plays, isEmpty);
  });

  group('the actions', () {
    Future<void> pick(WidgetTester tester, List<String> ids) async {
      await tester.longPress(row(ids.first));
      await tester.pumpAndSettle();
      for (final id in ids.skip(1)) {
        await tester.tap(row(id));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('Play plays the songs picked in the list order', (
      tester,
    ) async {
      await pump(tester);
      await pick(tester, ['c', 'a']);
      await tester.tap(find.byTooltip('Play'));
      await tester.pumpAndSettle();

      final set = port.lastSetQueue!;
      expect([for (final t in set.tracks) t.id], ['a', 'c']);
      expect(set.startIndex, 0);
      expect(selection.state.active, isFalse);
    });

    testWidgets('Shuffle plays them shuffled', (tester) async {
      await pump(tester);
      await pick(tester, ['b', 'c']);
      await tester.tap(find.byTooltip('Shuffle'));
      await tester.pumpAndSettle();

      final set = port.lastSetQueue!;
      expect([for (final t in set.tracks) t.id], ['b', 'c']);
      expect(set.shuffle, isTrue);
      expect(selection.state.active, isFalse);
    });

    testWidgets('Play next and Add to queue queue them in order', (
      tester,
    ) async {
      for (final (label, at) in [('Play next', '@1'), ('Add to queue', '@')]) {
        await pump(tester, playing: true);
        await pick(tester, ['c', 'a']);
        await tester.tap(find.byTooltip(label));
        await tester.pump();
        await tester.pump();

        expect(port.queueEdits.first, startsWith('start add a,c$at'));
        expect(selection.state.active, isFalse);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    });
  });
}
