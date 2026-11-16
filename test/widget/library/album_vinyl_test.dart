import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/pages/album_detail_page.dart';
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

class _Albums implements AlbumDetailRepository {
  @override
  Future<Either<Failure, Album>> getAlbumById(String id) async =>
      right(_album);

  @override
  Future<Either<Failure, List<Track>>> getTracksByAlbumId(int id) async =>
      right(_tracks);

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
  setUp(
    () => getIt.registerFactory<AlbumMetadataCubit>(
      () => AlbumMetadataCubit(repo: _NoMetadata()),
    ),
  );
  tearDown(getIt.reset);

  late FakeAudioPort port;

  /// The album page, with [playing] in the player when given.
  Future<void> open(
    WidgetTester tester, {
    List<Track>? playing,
    bool reducedMotion = false,
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
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AlbumDetailPage(id: '7'),
          ),
        ),
      ),
    );
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

  testWidgets('at rest, in its sleeve and still; a tap plays the album', (
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
    expect(port.lastSetQueue?.tracks, _tracks);
  });

  testWidgets('while the album plays, out further and turning', (
    tester,
  ) async {
    await open(tester, playing: _tracks);
    expect(slide(tester), greaterThan(0));
    final before = turns(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(turns(tester), isNot(before));
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
}
