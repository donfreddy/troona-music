import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/platform_track_edge_analyzer.dart';
import 'package:troona/features/player/data/repositories/track_edges_repository_impl.dart';
import 'package:troona/features/player/data/sources/isar_track_edges_data_source.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/ports/track_edge_analyzer.dart';

import '../../../helpers/fake_player.dart';
import '../../../helpers/isar_host.dart';

final class _Analyzer implements TrackEdgeAnalyzer {
  final asked = <String>[];
  Object? error;

  /// A song of 200 s whose music stops at 196 s.
  @override
  Future<TrackEnvelope> envelopeOf(Track track) async {
    asked.add(track.id);
    if (error case final e?) throw e;
    return TrackEnvelope(
      duration: const Duration(seconds: 200),
      window: const Duration(milliseconds: 50),
      head: [for (var k = 0; k < 200; k++) k < 20 ? -80 : -10],
      tailFrom: const Duration(seconds: 170),
      tail: [for (var k = 0; k < 600; k++) k < 520 ? -10 : -90],
    );
  }
}

void main() {
  late Directory dir;
  late Isar isar;
  late _Analyzer analyzer;
  late TrackEdgesRepositoryImpl repo;
  late Track track;

  final library = hostIsarLibrary();
  final skip = library == null
      ? 'No Isar core for ${Platform.operatingSystem}'
      : null;

  setUpAll(() async {
    if (library != null) await Isar.initialize(library);
  });

  setUp(() async {
    track = testTrack('a', durationMs: 200000)
      ..size = 1000
      ..dateModified = DateTime(2026, 11, 1);
    if (skip != null) return;
    dir = await Directory.systemTemp.createTemp('track_edges_test');
    isar = Isar.open(
      schemas: IsarTrackEdgesDataSource.schemas,
      directory: dir.path,
      inspector: false,
    );
    analyzer = _Analyzer();
    repo = TrackEdgesRepositoryImpl(
      store: IsarTrackEdgesDataSource(isar),
      analyzer: analyzer,
    );
  });

  tearDown(() async {
    if (skip != null) return;
    isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  const expected = TrackEdges(
    musicStart: Duration(seconds: 1),
    musicEnd: Duration(seconds: 196),
  );

  test('finds the edges once, then reads them back', () async {
    expect(await repo.edgesOf(track), expected);
    expect(await repo.edgesOf(track), expected);
    expect(analyzer.asked, ['a']);
  }, skip: skip);

  test('another file under the same id is analysed again', () async {
    await repo.edgesOf(track);
    track.size = 2000;
    await repo.edgesOf(track);
    track.dateModified = DateTime(2026, 11, 2);
    await repo.edgesOf(track);
    expect(analyzer.asked, ['a', 'a', 'a']);
  }, skip: skip);

  test('a file that cannot be read is remembered: not decoded again', () async {
    analyzer.error = const UnreadableTrack('MediaCodec');
    expect(await repo.edgesOf(track), isNull);
    expect(await repo.edgesOf(track), isNull);
    expect(analyzer.asked, ['a']);
  }, skip: skip);

  test('a passing failure stores nothing: tried again next time', () async {
    analyzer.error = TimeoutException('decoder');
    expect(await repo.edgesOf(track), isNull);
    analyzer.error = null;
    expect(await repo.edgesOf(track), expected);
    expect(analyzer.asked, ['a', 'a']);
  }, skip: skip);

  group('the channel', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(
      () => messenger.setMockMethodCallHandler(
        PlatformTrackEdgeAnalyzer.channel,
        null,
      ),
    );

    test('reads the envelope it answers', () async {
      messenger.setMockMethodCallHandler(
        PlatformTrackEdgeAnalyzer.channel,
        (call) async => {
          'durationMs': 200000,
          'windowMs': 50,
          'head': [-10.0, -20.0],
          'tailFromMs': 170000,
          'tail': [-30.0, -200.0],
        },
      );
      final envelope = await PlatformTrackEdgeAnalyzer().envelopeOf(track);
      expect(envelope.duration, const Duration(seconds: 200));
      expect(envelope.head, [-10, -20]);
      expect(envelope.tail.last, lessThanOrEqualTo(TrackEnvelope.noData));
    });

    test('a file it cannot read is unreadable; anything else is '
        'passing', () async {
      messenger.setMockMethodCallHandler(
        PlatformTrackEdgeAnalyzer.channel,
        (call) async => throw PlatformException(code: 'unreadable'),
      );
      await expectLater(
        PlatformTrackEdgeAnalyzer().envelopeOf(track),
        throwsA(isA<UnreadableTrack>()),
      );

      messenger.setMockMethodCallHandler(
        PlatformTrackEdgeAnalyzer.channel,
        (call) async => throw PlatformException(code: 'failed'),
      );
      await expectLater(
        PlatformTrackEdgeAnalyzer().envelopeOf(track),
        throwsA(isA<PlatformException>()),
      );
    });

    test('a malformed answer is unreadable', () {
      expect(
        () => PlatformTrackEdgeAnalyzer.envelopeFrom({'durationMs': 'x'}),
        throwsA(isA<UnreadableTrack>()),
      );
    });
  });
}
