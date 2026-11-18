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
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/presentation/widgets/album_artist_links.dart';
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
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/shared/widgets/meta_line.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

/// An album by three artists with long names: the header's worst case.
final _album = Album(
  id: '7',
  name: 'Love, Damini',
  artist: 'Christine and the Queens, Charlotte Gainsbourg, Mademoiselle K',
  artistId: 1,
  trackCount: 2,
  year: 2022,
  credits: const [
    ArtistCredit(id: 1, name: 'Christine and the Queens'),
    ArtistCredit(id: 2, name: 'Charlotte Gainsbourg'),
    ArtistCredit(id: 3, name: 'Mademoiselle K'),
  ],
);

final _tracks = [
  for (final id in ['a', 'b']) testTrack(id, durationMs: 60000),
];

class _Albums implements AlbumDetailRepository {
  @override
  Future<Either<Failure, Album>> getAlbumById(String id) async => right(_album);

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
  setUpAll(loadRoboto);
  setUp(
    () => getIt.registerFactory<AlbumMetadataCubit>(
      () => AlbumMetadataCubit(repo: _NoMetadata()),
    ),
  );
  tearDown(getIt.reset);

  Future<void> open(WidgetTester tester, double scale) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final port = FakeAudioPort();
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
            size: const Size(360, 640),
            textScaler: TextScaler.linear(scale),
          ),
          child: MaterialApp(
            theme: robotoTheme(AppTheme.dark),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AlbumDetailPage(id: '7'),
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('360 x 640, text x$scale: the artists, the facts and Play '
        'each in their own room', (tester) async {
      await open(tester, scale);
      expect(tester.takeException(), isNull);
      final links = tester.getRect(find.byType(AlbumArtistLinks));
      final facts = tester.getRect(
        find
            .descendant(of: find.byType(Wrap), matching: find.byType(MetaLine))
            .first,
      );
      final play = tester.getRect(find.byType(PlayShuffleButtons));
      debugPrint('x$scale links $links facts $facts play $play');
      expect(links.height, greaterThanOrEqualTo(AlbumArtistLinks.minHeight));
      expect(links.bottom, lessThanOrEqualTo(facts.top + 0.5));
      expect(facts.bottom, lessThanOrEqualTo(play.top + 0.5));
    });
  }
}
