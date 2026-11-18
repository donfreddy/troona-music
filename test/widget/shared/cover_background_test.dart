import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/palette/cover_palette.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/shared/widgets/cover_background.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

const CoverSwatches _red = (
  vibrant: Color(0xFFE53935),
  dominant: null,
  darkVibrant: Color(0xFF8E0000),
  muted: null,
);
const CoverSwatches _blue = (
  vibrant: Color(0xFF1E88E5),
  dominant: null,
  darkVibrant: Color(0xFF0D47A1),
  muted: null,
);

Track _withCover(String path) => Track(
  id: '1',
  title: 'Song',
  artist: 'Artist',
  artistId: 1,
  album: 'Album',
  albumId: 1,
  path: '/music/1.mp3',
  uri: 'content://1',
  size: 1,
  durationMs: 1000,
  fileName: '1.mp3',
  artworkPath: path,
);

void main() {
  /// Paths read, in order. `/red.jpg` and `/blue.jpg` have colours; any
  /// other path cannot be read. [gate] holds reads until completed.
  late List<String> reads;
  Completer<void>? gate;

  /// When each file last changed: every path is there, unchanged, unless
  /// a test says otherwise.
  late Map<String, DateTime?> stamps;

  setUp(() {
    reads = [];
    gate = null;
    stamps = {};
    CoverPalette.stampOf = (path) async =>
        stamps.containsKey(path) ? stamps[path] : DateTime(2026);
    CoverPalette.read = (path) async {
      reads.add(path);
      if (gate != null) await gate!.future;
      return switch (path) {
        '/red.jpg' => _red,
        '/blue.jpg' => _blue,
        _ => throw const FileSystemException('none'),
      };
    };
  });
  tearDown(CoverPalette.clear);

  final red = CoverPalette.fromSwatches(_red);
  final blue = CoverPalette.fromSwatches(_blue);
  final neutral = TrackPaletteState.initial();

  group('CoverPalette', () {
    test('reads a cover once, then keeps its colours', () async {
      expect(CoverPalette.cached('/red.jpg'), isNull);
      final first = await CoverPalette.of('/red.jpg');
      final again = await CoverPalette.of('/red.jpg');
      expect(reads, ['/red.jpg']);
      expect(identical(first, again), isTrue);
      expect(CoverPalette.cached('/red.jpg'), same(first));
    });

    test(
      'a cover that cannot be read gives none, until its file changes',
      () async {
        expect(await CoverPalette.of('/broken.jpg'), isNull);
        expect(await CoverPalette.of('/broken.jpg'), isNull);
        expect(reads, ['/broken.jpg']);

        stamps['/broken.jpg'] = DateTime(2027);
        await CoverPalette.of('/broken.jpg');
        expect(reads, ['/broken.jpg', '/broken.jpg']);
      },
    );

    test('a file that is not there is not even read', () async {
      stamps['/red.jpg'] = null;
      expect(await CoverPalette.of('/red.jpg'), isNull);
      expect(reads, isEmpty);

      // It comes back (a scan extracts the cover again).
      stamps['/red.jpg'] = DateTime(2026);
      expect(await CoverPalette.of('/red.jpg'), isNotNull);
    });

    test('an image written again at the same path is read again', () async {
      final before = await CoverPalette.of('/red.jpg');
      stamps['/red.jpg'] = DateTime(2027);
      final after = await CoverPalette.of('/red.jpg');
      expect(reads, ['/red.jpg', '/red.jpg']);
      expect(after, isNot(same(before)));
    });

    test('asked twice while reading, read once', () async {
      gate = Completer();
      final first = CoverPalette.of('/red.jpg');
      final second = CoverPalette.of('/red.jpg');
      await pumpEventQueue();
      gate!.complete();
      expect(await first, same(await second));
      expect(reads, ['/red.jpg']);
    });

    test(
      'real files: a red cover reads red, a broken one fails at once',
      () async {
        CoverPalette.clear(); // The real reader.
        final dir = await Directory.systemTemp.createTemp('palette');
        addTearDown(() => dir.delete(recursive: true));

        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 200, 200),
          Paint()..color = const Color(0xFFE53935),
        );
        final image = await recorder.endRecording().toImage(200, 200);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final cover = File('${dir.path}/red.png')
          ..writeAsBytesSync(png!.buffer.asUint8List());
        final broken = File('${dir.path}/broken.jpg')..writeAsStringSync('no');

        final colours = await CoverPalette.of(cover.path);
        final hue = HSLColor.fromColor(colours!.backgroundColorA).hue;
        expect(hue < 15 || hue > 345, isTrue, reason: 'hue $hue');

        final clock = Stopwatch()..start();
        expect(await CoverPalette.of(broken.path), isNull);
        expect(await CoverPalette.of('${dir.path}/missing.jpg'), isNull);
        expect(clock.elapsed, lessThan(const Duration(seconds: 2)));
      },
    );

    test('keeps the covers used last', () async {
      CoverPalette.read = (path) async => _red;
      for (var i = 0; i <= CoverPalette.capacity; i++) {
        await CoverPalette.of('/$i.jpg');
        // The first stays in use, so the second is the oldest.
        CoverPalette.cached('/0.jpg');
      }
      expect(CoverPalette.cached('/0.jpg'), isNotNull);
      expect(CoverPalette.cached('/1.jpg'), isNull);
      expect(CoverPalette.cached('/${CoverPalette.capacity}.jpg'), isNotNull);
    });

    test(
      'the song playing and a page with its cover share its colours',
      () async {
        final cubit = TrackPaletteCubit();
        addTearDown(cubit.close);
        await cubit.updateTrack(_withCover('/red.jpg'));
        expect(cubit.state.trackId, '1');
        expect(cubit.state.backgroundColorA, red.backgroundColorA);
        expect(
          CoverPalette.cached('/red.jpg')!.backgroundColorA,
          cubit.state.backgroundColorA,
        );
        expect(reads, ['/red.jpg']);
      },
    );
  });

  group('CoverBackground', () {
    late TrackPaletteCubit playing;

    Future<void> pump(WidgetTester tester, String? path) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: playing,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: CoverBackground(path: path, child: const SizedBox.expand()),
          ),
        ),
      );
    }

    DynamicBackground glow(WidgetTester tester) =>
        tester.widget<DynamicBackground>(find.byType(DynamicBackground));

    setUp(() async {
      playing = TrackPaletteCubit();
      // Blue is playing.
      await playing.updateTrack(_withCover('/blue.jpg'));
      reads.clear();
    });
    tearDown(() => playing.close());

    testWidgets('a cover already read: its colours from the first frame', (
      tester,
    ) async {
      await CoverPalette.of('/red.jpg');
      await pump(tester, '/red.jpg');
      expect(glow(tester).colorA, red.backgroundColorA);
    });

    testWidgets('the album playing keeps the colours it has', (tester) async {
      await pump(tester, '/blue.jpg');
      expect(glow(tester).colorA, blue.backgroundColorA);
      expect(reads, isEmpty);
    });

    testWidgets("opens in the playing song's colours, then turns to its "
        "cover's, cross-fading on the same glow", (tester) async {
      final held = gate = Completer<void>();
      await pump(tester, '/red.jpg');
      expect(glow(tester).colorA, blue.backgroundColorA);
      final before = tester.state(find.byType(DynamicBackground));

      held.complete();
      await tester.pump();
      await tester.pump();
      expect(glow(tester).colorA, red.backgroundColorA);
      expect(tester.state(find.byType(DynamicBackground)), same(before));
    });

    testWidgets('still loading (no cover known): the playing colours', (
      tester,
    ) async {
      await pump(tester, null);
      expect(glow(tester).colorA, blue.backgroundColorA);
      expect(reads, isEmpty);
    });

    testWidgets('no cover, or one that cannot be read: the neutral glow', (
      tester,
    ) async {
      await pump(tester, '');
      expect(glow(tester).colorA, neutral.backgroundColorA);

      await pump(tester, '/gone.jpg');
      await tester.pump();
      await tester.pump();
      expect(glow(tester).colorA, neutral.backgroundColorA);
    });
  });
}
