import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist_detail/playlist_detail_bloc.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_detail_page.dart';
import 'package:troona/l10n/app_localizations.dart';

import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import '../../helpers/fake_player.dart';
import '../../helpers/fake_smart.dart';

/// Likes kept in [playlists], as the database keeps them; no song read
/// back for a mosaic.
final class _Likes extends Fake implements LibraryRepository {
  _Likes(this.playlists);

  final MemoryPlaylists playlists;

  Playlist get _likes =>
      playlists.stored[Playlist.likesId] ??
      const Playlist(id: Playlist.likesId, name: 'Likes');

  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async => right(_likes);

  @override
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId) async {
    playlists.stored[Playlist.likesId] = Playlist(
      id: Playlist.likesId,
      name: 'Likes',
      trackIds: [..._likes.trackIds, trackId],
    );
    return right(unit);
  }

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      right(const []);
}

void main() {
  late LibraryBloc libraryBloc;
  late MemoryPlaylists playlists;
  late FakeSmartLibrary library;
  late LikesCubit likesCubit;

  Future<void> pump(WidgetTester tester, SmartRules rules) async {
    final (:player, port: _) = await testPlayer(addTearDown);
    library = FakeSmartLibrary([
      for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 60000),
    ]);
    playlists = MemoryPlaylists()
      ..stored['s'] = Playlist(id: 's', name: 'Smart', rules: rules);
    final detail = PlaylistDetailBloc(
      repo: playlists,
      smart: fakeSmartSource(
        library: library,
        history: FakeSmartHistory(),
        playlists: playlists,
      ),
    )..add(const PlaylistDetailRequested('s'));
    final selection = TrackSelectionCubit();
    final palette = TrackPaletteCubit();
    final likes = _Likes(playlists);
    getIt.registerSingleton(GetTracksByIdsUseCase(likes));
    addTearDown(() => getIt.unregister<GetTracksByIdsUseCase>());
    likesCubit = LikesCubit(
      addTrack: AddTrackToLikesUseCase(likes),
      removeTrack: RemoveTrackFromLikesUseCase(likes),
      isTrackLiked: IsTrackInLikesUseCase(likes),
      getLikesPlaylist: GetLikesPlaylistUseCase(likes),
    );
    libraryBloc = idleLibraryBloc();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(detail.close());
      unawaited(selection.close());
      unawaited(palette.close());
      unawaited(likesCubit.close());
      unawaited(libraryBloc.close());
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerBloc>.value(value: player),
          BlocProvider<PlaylistDetailBloc>.value(value: detail),
          BlocProvider<TrackSelectionCubit>.value(value: selection),
          BlocProvider<TrackPaletteCubit>.value(value: palette),
          BlocProvider<LikesCubit>.value(value: likesCubit),
          BlocProvider<LibraryBloc>.value(value: libraryBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PlaylistDetailPage(id: 's'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('its songs show marked Auto, with no handle to move them', (
    tester,
  ) async {
    await pump(tester, const SmartRules());
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('Title c'), findsOneWidget);
    expect(find.text('AUTO'), findsOneWidget);
    expect(find.byIcon(AppIcons.dragHandle), findsNothing);
  });

  testWidgets('a song\'s options are its own menu, with nothing to remove', (
    tester,
  ) async {
    await pump(tester, const SmartRules());
    await tester.tap(find.byTooltip('More options').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Remove from playlist'), findsNothing);
    expect(find.text('Play next'), findsOneWidget);
  });

  testWidgets('its menu edits the rules or saves the songs as a playlist', (
    tester,
  ) async {
    await pump(tester, const SmartRules());
    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit rules'), findsOneWidget);
    expect(find.text('Save as a playlist'), findsOneWidget);

    await tester.tap(find.text('Save as a playlist'));
    await tester.pumpAndSettle();
    // The name offered is the smart playlist's own.
    expect(find.widgetWithText(TextField, 'Smart'), findsOneWidget);
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final copy = playlists.created.single;
    expect(playlists.stored[copy.id]!.trackIds, ['a', 'b', 'c']);
    expect(playlists.stored[copy.id]!.isSmart, isFalse);
    expect(find.text('Saved as Smart'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a song liked from its menu leaves "Not liked" at once', (
    tester,
  ) async {
    await pump(tester, const SmartRules(rules: [Liked(false)]));
    expect(find.text('Title a'), findsOneWidget);

    likesCubit.toggle(testTrack('a', durationMs: 60000));
    await tester.pumpAndSettle();
    expect(find.text('Title a'), findsNothing);
    expect(find.text('Title b'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('no song kept: says so and offers to edit the rules', (
    tester,
  ) async {
    await pump(tester, const SmartRules(rules: [Lossless(true)]));
    expect(find.text('No songs match yet'), findsOneWidget);
    expect(find.text('Edit rules'), findsOneWidget);

    // Nothing to save: the menu offers the rules alone.
    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    expect(find.text('Save as a playlist'), findsNothing);
  });
}
