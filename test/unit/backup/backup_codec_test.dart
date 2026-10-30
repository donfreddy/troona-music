import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/backup/data/backup_codec.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

final _backup = Backup(
  createdAt: DateTime.utc(2026, 10, 30, 21),
  tracks: const {
    '1': BackupTrack(
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      durationMs: 200000,
      fileName: 'song.flac',
      size: 42,
    ),
  },
  playlists: const [
    BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['1']),
    BackupPlaylist(name: 'Road trip', isLikes: false, tracks: []),
  ],
  plays: [BackupPlay(track: '1', at: DateTime.utc(2026, 10, 29, 18))],
  days: const [BackupDay(day: 20390, plays: 3, listenedMs: 600000)],
  trackDays: const [BackupTrackDay(day: 20390, track: '1', plays: 3)],
  firstPlays: const [BackupFirstPlay(track: '1', day: 20101)],
  replayMonth: 24321,
  settings: const AppSettings(
    fetchArtistArtwork: true,
    hapticFeedbackEnabled: false,
  ),
);

Map<String, dynamic> _json() =>
    jsonDecode(utf8.decode(BackupCodec.encode(_backup)))
        as Map<String, dynamic>;

List<int> _bytes(Map<String, dynamic> json) => utf8.encode(jsonEncode(json));

Matcher _rejected = throwsA(isA<BackupFormatException>());

void main() {
  test('a backup reads back as it was written', () {
    expect(BackupCodec.decode(BackupCodec.encode(_backup)), _backup);
  });

  test('the glass quality is not carried', () {
    final backup = Backup(
      createdAt: _backup.createdAt,
      tracks: _backup.tracks,
      playlists: _backup.playlists,
      plays: _backup.plays,
      days: _backup.days,
      trackDays: _backup.trackDays,
      firstPlays: _backup.firstPlays,
      replayMonth: null,
      settings: const AppSettings(glassQuality: GlassQuality.off),
    );

    final read = BackupCodec.decode(BackupCodec.encode(backup));

    expect(read.settings.glassQuality, GlassQuality.auto);
    expect(read.replayMonth, isNull);
  });

  test('a backup from a newer app is refused with its version', () {
    final json = _json()..['version'] = BackupCodec.version + 1;

    expect(
      () => BackupCodec.decode(_bytes(json)),
      throwsA(
        isA<BackupVersionException>().having(
          (e) => e.version,
          'version',
          BackupCodec.version + 1,
        ),
      ),
    );
  });

  test('another JSON file is refused', () {
    expect(() => BackupCodec.decode(_bytes({'hello': 1})), _rejected);
  });

  test('a file that is not JSON is refused', () {
    expect(() => BackupCodec.decode(utf8.encode('not json')), _rejected);
  });

  test('a song named but not described is refused', () {
    final json = _json();
    (json['playlists'] as List).first['tracks'] = ['ghost'];

    expect(() => BackupCodec.decode(_bytes(json)), _rejected);
  });

  test('a negative count is refused', () {
    final json = _json();
    (json['history']['days'] as List).first['plays'] = -1;

    expect(() => BackupCodec.decode(_bytes(json)), _rejected);
  });

  test('a field of the wrong type is refused', () {
    final json = _json();
    json['tracks']['1']['size'] = '42';

    expect(() => BackupCodec.decode(_bytes(json)), _rejected);
  });

  test('an overlong name is refused', () {
    final json = _json();
    (json['playlists'] as List).first['name'] = 'x' * (BackupCodec.maxText + 1);

    expect(() => BackupCodec.decode(_bytes(json)), _rejected);
  });

  test('a missing section is refused', () {
    final json = _json()..remove('settings');

    expect(() => BackupCodec.decode(_bytes(json)), _rejected);
  });

  test('a file over the size limit is refused unread', () {
    expect(
      () => BackupCodec.decode(List.filled(BackupCodec.maxBytes + 1, 32)),
      _rejected,
    );
  });

  group('ranges, since a restore keeps the larger count for good', () {
    void rejects(void Function(Map<String, dynamic> json) change) {
      final json = _json();
      change(json);
      expect(() => BackupCodec.decode(_bytes(json)), _rejected);
    }

    test('a day longer than a day of listening', () {
      rejects(
        (j) => (j['history']['days'] as List).first['listenedMs'] = 1 << 62,
      );
    });

    test('a day to come', () {
      rejects((j) => (j['history']['days'] as List).first['day'] = 1 << 40);
    });

    test('a play in the far future', () {
      rejects(
        (j) => (j['history']['plays'] as List).first['at'] =
            '+275760-09-13T00:00:00.000Z',
      );
    });

    test('a date that does not exist', () {
      rejects(
        (j) => (j['history']['plays'] as List).first['at'] =
            '2026-02-30T10:00:00.000Z',
      );
    });

    test('a time without its zone', () {
      rejects(
        (j) => (j['history']['plays'] as List).first['at'] =
            '2026-10-29T18:00:00.000',
      );
    });

    test('a Replay month to come', () {
      rejects((j) => j['history']['replayMonth'] = 1 << 40);
    });

    test('version zero', () {
      rejects((j) => j['version'] = 0);
    });
  });

  test('an overlong tag is cut on export, so the file reads back', () {
    final long = Backup(
      createdAt: _backup.createdAt,
      tracks: {
        '1': BackupTrack(
          title: 'x' * (BackupCodec.maxText + 50),
          artist: 'Artist',
          album: 'Album',
          durationMs: 1,
          fileName: 'a.mp3',
          size: 1,
        ),
      },
      playlists: const [],
      plays: const [],
      days: const [],
      trackDays: const [],
      firstPlays: const [],
      replayMonth: null,
      settings: const AppSettings(),
    );

    final read = BackupCodec.decode(BackupCodec.encode(long));

    expect(read.tracks['1']!.title, hasLength(BackupCodec.maxText));
  });
}
