import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/player/data/adapters/platform_opened_file.dart';
import 'package:troona/features/player/domain/entities/opened_audio.dart';
import 'package:troona/features/player/domain/ports/opened_file_port.dart';
import 'package:troona/features/player/domain/use_cases/resolve_opened_file_use_case.dart';
import 'package:troona/features/player/presentation/utils/opened_file_handler.dart';

import '../../helpers/fake_player.dart';

class _Library extends Fake implements LibraryRepository {
  final List<Track> tracks;
  bool fails = false;
  int reads = 0;
  _Library(this.tracks);

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      fails
      ? left(const DatabaseFailure())
      : right([
          for (final t in tracks)
            if (ids.contains(t.id)) t,
        ]);

  @override
  Future<Either<Failure, List<Track>>> getTracks() async {
    reads++;
    return fails ? left(const DatabaseFailure()) : right(tracks);
  }
}

/// Requests handed out in order by [take]; [offer] tells the handler one
/// waits.
class _Port implements OpenedFilePort {
  final waiting = <OpenedFileRequest>[];
  final _offered = StreamController<void>.broadcast(sync: true);

  void offer(OpenedFileRequest request) {
    waiting.add(request);
    _offered.add(null);
  }

  /// Tells the handler a request waits when none does (an earlier take
  /// got it).
  void ping() => _offered.add(null);

  @override
  Stream<void> get offered => _offered.stream;

  @override
  Future<OpenedFileRequest?> take() async {
    if (waiting.isEmpty) return null;
    final last = waiting.last;
    waiting.clear();
    return last;
  }
}

Track _track(String id, {required String file, required int size}) =>
    testTrack(id, durationMs: 1000)
      ..fileName = file
      ..size = size;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolve', () {
    final intro = _track('11', file: '01 Intro.mp3', size: 4000);
    final otherIntro = _track('12', file: '01 Intro.mp3', size: 5000);
    late _Library library;
    late ResolveOpenedFileUseCase resolve;

    setUp(() {
      library = _Library([intro, otherIntro]);
      resolve = ResolveOpenedFileUseCase(library);
    });

    test('a MediaStore address: the song of that id', () async {
      final opened = await resolve(
        const OpenedFileRequest(uri: 'content://media/x', mediaStoreId: '12'),
      );
      expect((opened as OpenedLibraryTrack).track, otherIntro);
      expect(library.reads, 0, reason: 'no need to read every song');
    });

    test('a file manager\'s address: by name and size, which tells two '
        'songs of one name apart', () async {
      final opened = await resolve(
        const OpenedFileRequest(
          uri: 'content://files/x',
          name: '01 Intro.mp3',
          size: 5000,
        ),
      );
      expect((opened as OpenedLibraryTrack).track, otherIntro);
    });

    test('an id the library lacks still tries name and size', () async {
      final opened = await resolve(
        const OpenedFileRequest(
          uri: 'content://media/x',
          mediaStoreId: '99',
          name: '01 Intro.mp3',
          size: 4000,
        ),
      );
      expect((opened as OpenedLibraryTrack).track, intro);
    });

    test('a name with no size is not enough', () async {
      expect(
        await resolve(
          const OpenedFileRequest(uri: 'content://x', name: '01 Intro.mp3'),
        ),
        isA<OpenedNotInLibrary>(),
      );
      expect(library.reads, 0);
    });

    test('a file: address: by its path, exactly', () async {
      final atPath = _track('13', file: 'other.mp3', size: 1)
        ..path = '/storage/emulated/0/Music/01 Intro.mp3';
      library = _Library([intro, atPath]);
      resolve = ResolveOpenedFileUseCase(library);
      final opened = await resolve(
        const OpenedFileRequest(
          uri: 'file:///storage/emulated/0/Music/01%20Intro.mp3',
          name: '01 Intro.mp3',
          size: 4000,
        ),
      );
      expect((opened as OpenedLibraryTrack).track, atPath);
    });

    test('nothing that matches: not in the library', () async {
      expect(
        await resolve(
          const OpenedFileRequest(uri: 'content://x', name: 'b.mp3', size: 1),
        ),
        isA<OpenedNotInLibrary>(),
      );
    });

    test(
      'a library that cannot be read: not in the library, no error',
      () async {
        library.fails = true;
        expect(
          await resolve(
            const OpenedFileRequest(
              uri: 'content://x',
              mediaStoreId: '11',
              name: '01 Intro.mp3',
              size: 4000,
            ),
          ),
          isA<OpenedNotInLibrary>(),
        );
      },
    );
  });

  group('handler', () {
    const a = OpenedFileRequest(uri: 'content://a');
    const b = OpenedFileRequest(uri: 'content://b');
    late _Port port;
    late List<String> seen;
    late Map<String, Completer<void>> gates;
    late OpenedFileHandler handler;

    setUp(() {
      port = _Port();
      seen = [];
      gates = {};
      handler = OpenedFileHandler(
        port: port,
        resolve: (r) async {
          await gates[r.uri]?.future;
          return OpenedLibraryTrack(testTrack(r.uri, durationMs: 1));
        },
        onOpened: (o) => seen.add((o as OpenedLibraryTrack).track.id),
      );
      addTearDown(handler.dispose);
    });

    test('a cold start: the request waiting is played once started', () async {
      port.waiting.add(a);
      handler.start();
      await pumpEventQueue();
      expect(seen, ['content://a']);
    });

    test('nothing waiting: nothing happens', () async {
      handler.start();
      await pumpEventQueue();
      expect(seen, isEmpty);
    });

    test('a request offered while running is played', () async {
      handler.start();
      await pumpEventQueue();
      port.offer(b);
      await pumpEventQueue();
      expect(seen, ['content://b']);
    });

    test('two files opened close together: the last wins, the first '
        'still being looked up is dropped', () async {
      gates['content://a'] = Completer();
      handler.start();
      port.offer(a);
      await pumpEventQueue();
      port.offer(b);
      await pumpEventQueue();
      gates['content://a']!.complete();
      await pumpEventQueue();
      expect(seen, ['content://b']);
    });

    test('a take that finds nothing does not drop the request under '
        'way', () async {
      gates['content://a'] = Completer();
      port.waiting.add(a);
      handler.start();
      await pumpEventQueue();
      // Told again, but already taken: this take finds nothing.
      port.ping();
      await pumpEventQueue();
      gates['content://a']!.complete();
      await pumpEventQueue();
      expect(seen, ['content://a']);
    });

    test('nothing after dispose', () async {
      gates['content://a'] = Completer();
      port.waiting.add(a);
      handler.start();
      await pumpEventQueue();
      await handler.dispose();
      gates['content://a']!.complete();
      await pumpEventQueue();
      expect(seen, isEmpty);
    });
  });

  group('channel', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(
      () =>
          messenger.setMockMethodCallHandler(PlatformOpenedFile.channel, null),
    );

    test('reads what the activity describes', () async {
      messenger.setMockMethodCallHandler(PlatformOpenedFile.channel, (
        call,
      ) async {
        expect(call.method, 'take');
        return {
          'uri': 'content://media/external/audio/media/42',
          'name': 'song.mp3',
          'size': 1234,
        };
      });
      expect(
        await PlatformOpenedFile().take(),
        const OpenedFileRequest(
          uri: 'content://media/external/audio/media/42',
          mediaStoreId: '42',
          name: 'song.mp3',
          size: 1234,
        ),
      );
    });

    test('no activity or another platform: no request, no error', () async {
      expect(await PlatformOpenedFile().take(), isNull);
      messenger.setMockMethodCallHandler(
        PlatformOpenedFile.channel,
        (_) async => throw PlatformException(code: 'gone'),
      );
      expect(await PlatformOpenedFile().take(), isNull);
    });

    group('the MediaStore id an address carries', () {
      for (final (address, id) in [
        ('content://media/external/audio/media/42', '42'),
        ('content://media/external_primary/audio/media/42', '42'),
        // Ringtones and system sounds: ids counted apart.
        ('content://media/internal/audio/media/42', null),
        ('content://media/external/video/media/42', null),
        ('content://media/external/audio/albums/42', null),
        (
          'content://com.android.providers.media.documents/document/audio%3A42',
          '42',
        ),
        (
          'content://com.android.providers.media.documents/document/video%3A42',
          null,
        ),
        (
          'content://com.android.providers.downloads.documents/document/msf%3A42',
          '42',
        ),
        // The downloads' own ids and raw paths are not MediaStore's.
        (
          'content://com.android.providers.downloads.documents/document/42',
          null,
        ),
        (
          'content://com.android.providers.downloads.documents/document/'
              'raw%3A%2Fstorage%2Femulated%2F0%2FDownload%2Fa.mp3',
          null,
        ),
        (
          'content://com.android.externalstorage.documents/tree/primary%3AMusic'
              '/document/primary%3AMusic%2Fa.mp3',
          null,
        ),
        ('content://com.whatsapp.provider.media/item/42', null),
        ('file:///storage/emulated/0/Music/a.mp3', null),
        ('content://media/external/audio/media/abc', null),
      ]) {
        test(address, () {
          expect(PlatformOpenedFile.mediaStoreIdOf(address), id);
        });
      }
    });

    test('a request with no address is none', () {
      expect(PlatformOpenedFile.requestOf({'name': 'x.mp3'}), isNull);
    });

    test('the activity telling a request waits reaches the stream', () async {
      final port = PlatformOpenedFile();
      final offers = <void>[];
      final sub = port.offered.listen(offers.add);
      addTearDown(sub.cancel);
      await messenger.handlePlatformMessage(
        PlatformOpenedFile.channel.name,
        PlatformOpenedFile.channel.codec.encodeMethodCall(
          const MethodCall('offered'),
        ),
        (_) {},
      );
      await pumpEventQueue();
      expect(offers, hasLength(1));
    });
  });
}
