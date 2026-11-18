import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/playing_badge.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

import '../../helpers/fake_player.dart';

Track _song(String id, {int albumId = 7, List<ArtistCredit>? credits}) => Track(
  id: id,
  title: 'Song $id',
  artist: 'Burna Boy',
  artistId: 11,
  credits: credits,
  album: 'Love, Damini',
  albumId: albumId,
  path: '/$id.mp3',
  uri: '',
  size: 0,
  durationMs: 60000,
  fileName: '$id.mp3',
);

const _album = Album(
  id: '7',
  name: 'Love, Damini',
  artist: 'Burna Boy',
  artistId: 11,
  trackCount: 2,
);

final _albumSongs = [_song('1'), _song('2')];

class _Albums implements AlbumDetailRepository {
  @override
  Future<Either<Failure, List<Track>>> getTracksByAlbumId(int id) async =>
      right(id == 7 ? _albumSongs : const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoPhotos implements MetadataRepository {
  @override
  Stream<String> get onArtistArtworkUpdated => const Stream.empty();

  @override
  String? getCachedArtistArtworkPath(String artistId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late PlayerBloc player;
  late FakeAudioPort port;

  setUp(() {
    getIt
      ..registerSingleton<AlbumDetailRepository>(_Albums())
      ..registerSingleton<MetadataRepository>(_NoPhotos());
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, Widget card) async {
    (:player, :port) = await testPlayer(addTearDown);
    await tester.pumpWidget(
      BlocProvider<PlayerBloc>.value(
        value: player,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: SizedBox(width: 150, child: card)),
          ),
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  Future<void> play(WidgetTester tester, Track track, {bool on = true}) async {
    port.queue = Queue.fromTracks([track]);
    player.add(QueueSetRequested([track]));
    await tester.pump();
    port.status.add(on ? PlaybackStatus.playing : PlaybackStatus.paused);
    await tester.pump();
    await tester.pump();
  }

  Finder equalizer() => find.descendant(
    of: find.byType(PlayingBadge),
    matching: find.byType(MiniEqualizer),
  );

  group('playing badge', () {
    testWidgets('on the album playing, still while paused, none otherwise', (
      tester,
    ) async {
      await pump(tester, const AlbumCard(album: _album));
      expect(equalizer(), findsNothing);

      await play(tester, _song('1'));
      expect(tester.widget<MiniEqualizer>(equalizer()).isPlaying, isTrue);

      port.status.add(PlaybackStatus.paused);
      await tester.pump();
      await tester.pump();
      expect(tester.widget<MiniEqualizer>(equalizer()).isPlaying, isFalse);

      await play(tester, _song('9', albumId: 8));
      expect(equalizer(), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('on an artist credited on the song, guests too', (
      tester,
    ) async {
      const tems = ArtistCredit(id: 12, name: 'Tems');
      await pump(
        tester,
        const ArtistCard(
          artist: Artist(id: '12', name: 'Tems', albumCount: 1, trackCount: 3),
        ),
      );
      expect(equalizer(), findsNothing);

      await play(
        tester,
        _song(
          '1',
          credits: const [
            ArtistCredit(id: 11, name: 'Burna Boy'),
            tems,
          ],
        ),
      );
      expect(equalizer(), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('album card long press', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    testWidgets('the album menu: play, shuffle, next, queue', (tester) async {
      await pump(tester, const AlbumCard(album: _album));
      await tester.longPress(find.byType(AlbumCard));
      await settle(tester);
      for (final label in ['Play', 'Shuffle', 'Play next', 'Add to queue']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      await tester.tap(find.text('Play'));
      await settle(tester);
      expect(port.lastSetQueue?.tracks, _albumSongs);
      expect(port.lastSetQueue?.startIndex, 0);
    });

    testWidgets('add to queue: every song, in the album order', (tester) async {
      await pump(tester, const AlbumCard(album: _album));
      await play(tester, _song('9', albumId: 8));
      await tester.longPress(find.byType(AlbumCard));
      await settle(tester);
      await tester.tap(find.text('Add to queue'));
      await settle(tester);
      expect(
        [for (final t in port.queue!.playbackTracks) t.id],
        ['9', '1', '2'],
      );
      expect(find.text('Added to queue'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('play next: the album right after the current song, in order', (
      tester,
    ) async {
      await pump(tester, const AlbumCard(album: _album));
      await play(tester, _song('9', albumId: 8));
      await tester.longPress(find.byType(AlbumCard));
      await settle(tester);
      await tester.tap(find.text('Play next'));
      await settle(tester);
      expect(
        [for (final t in port.queue!.playbackTracks) t.id],
        ['9', '1', '2'],
      );
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('with nothing playing, Play next and Add to queue play the '
        'album from its first song, no toast', (tester) async {
      for (final action in ['Play next', 'Add to queue']) {
        await pump(tester, const AlbumCard(album: _album));
        await tester.longPress(find.byType(AlbumCard));
        await settle(tester);
        await tester.tap(find.text(action));
        await settle(tester);
        final set = port.lastSetQueue;
        expect(set?.tracks.map((t) => t.id), ['1', '2'], reason: action);
        expect(set?.startIndex, 0);
        expect(player.origin.value?.id, _album.id);
        expect(find.text('Plays next'), findsNothing);
        expect(find.text('Added to queue'), findsNothing);
        await tester.pump(const Duration(seconds: 5));
      }
    });
  });
}
