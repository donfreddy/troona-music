import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

/// Names mixing Latin and CJK are drawn by two fonts on one line, and two
/// fonts' ascents and descents add up taller than either. The Library's
/// list and grids give every row one height, measured from Latin text: the
/// rows and cards hold their lines to it.
///
/// Roboto draws the Latin; the test font, with its own metrics, stands in
/// for the phone's CJK fallback.
class _NoPhotos implements MetadataRepository {
  final _updates = StreamController<String>.broadcast();

  @override
  Stream<String> get onArtistArtworkUpdated => _updates.stream;

  @override
  String? getCachedArtistArtworkPath(String artistId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Track _track(String title) => Track(
  id: title,
  title: title,
  artist: title,
  artistId: 1,
  album: 'Album',
  albumId: 1,
  path: '/music/$title.mp3',
  uri: 'content://$title',
  size: 1,
  durationMs: 180000,
  fileName: '$title.mp3',
);

void main() {
  setUpAll(loadRoboto);
  setUp(() => getIt.registerSingleton<MetadataRepository>(_NoPhotos()));
  tearDown(getIt.reset);

  final theme = AppTheme.dark.copyWith(
    textTheme: AppTheme.dark.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['FlutterTest'],
    ),
  );

  Future<void> pump(WidgetTester tester, double scale, Widget child) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(390, 844) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({});
    final port = FakeAudioPort();
    final player = buildTestPlayerBloc(
      port,
      PlaybackSessionStore(await SharedPreferences.getInstance()),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(player.close());
      unawaited(port.close());
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: player,
        child: MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('text x$scale: a song row is as tall with a mixed title', (
      tester,
    ) async {
      await pump(
        tester,
        scale,
        ListView(
          children: [
            TrackListTile(track: _track('Ag'), onTap: () {}),
            TrackListTile(track: _track('Ag日本 song'), onTap: () {}),
          ],
        ),
      );
      final rows = find.byType(TrackListTile);
      expect(
        tester.getSize(rows.at(1)).height,
        tester.getSize(rows.at(0)).height,
      );
    });

    testWidgets('text x$scale: cards are their cover and their measured '
        'text, mixed names included', (tester) async {
      const width = 110.0;
      late double albumText, artistText;
      await pump(
        tester,
        scale,
        Builder(
          builder: (context) {
            albumText = AlbumCard.textHeight(context);
            artistText = ArtistCard.textHeight(context);
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    AlbumCard(
                      album: Album(
                        id: '1',
                        name: 'Ag 日本 album',
                        artist: 'Ag 米津玄師',
                        artistId: 1,
                        trackCount: 3,
                      ),
                    ),
                    ArtistCard(
                      artist: Artist(
                        id: '1',
                        name: 'Ag 米津玄師',
                        albumCount: 1,
                        trackCount: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AlbumCard)).height,
        closeTo(width + albumText, 0.01),
      );
      expect(
        tester.getSize(find.byType(ArtistCard)).height,
        closeTo(width + artistText, 0.01),
      );
    });
  }
}
