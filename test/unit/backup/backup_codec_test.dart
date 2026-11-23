import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/backup/data/backup_codec.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/library/data/models/smart_rules_json.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_snapshot.dart';
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
    BackupPlaylist(
      name: 'Forgotten',
      isLikes: false,
      tracks: [],
      rules: SmartRules(
        rules: [LastPlayed(LastPlayedKind.olderThan, days: 90)],
        sort: SmartSort.random,
      ),
    ),
  ],
  plays: [BackupPlay(track: '1', at: DateTime.utc(2026, 10, 29, 18))],
  days: const [BackupDay(day: 20390, plays: 3, listenedMs: 600000)],
  trackDays: const [BackupTrackDay(day: 20390, track: '1', plays: 3)],
  firstPlays: const [BackupFirstPlay(track: '1', day: 20101)],
  hours: const [BackupHour(hour: 20390 * 24 + 18, plays: 3)],
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

final _equalizer = EqualizerSnapshot(
  settings: EqualizerSettings(
    enabled: true,
    presetId: null,
    curve: EqCurve(const [EqPoint(60, 4), EqPoint(14000, -2.5)]),
    boostDb: 2,
  ),
  profiles: [
    EqProfile(
      id: 'k3f9',
      name: 'Headphones',
      curve: EqCurve(const [EqPoint(230, 3)]),
    ),
  ],
);

void main() {
  test('a backup reads back as it was written', () {
    expect(BackupCodec.decode(BackupCodec.encode(_backup)), _backup);
  });

  test('a playlist of songs carries no rules key', () {
    final playlists = _json()['playlists'] as List;
    expect((playlists[1] as Map).containsKey('rules'), isFalse);
  });

  test('smart rules that cannot be read still restore a smart playlist '
      'that keeps nothing, and the rest of the file', () {
    final json = _json();
    ((json['playlists'] as List)[2] as Map)['rules'] = 'broken';
    final read = BackupCodec.decode(_bytes(json));
    expect(read.playlists[2].rules, SmartRulesJson.unreadable);
    expect(read.plays, hasLength(1));
  });

  group('the equalizer', () {
    final withEq = _backup.withEqualizer(_equalizer);

    test('reads back as it was written', () {
      expect(BackupCodec.decode(BackupCodec.encode(withEq)), withEq);
    });

    test('a backup made before it has none', () {
      expect(_json().containsKey('equalizer'), isFalse);
      expect(BackupCodec.decode(BackupCodec.encode(_backup)).equalizer, isNull);
    });

    test('out of bounds, it is left out and the rest restores', () {
      final json =
          jsonDecode(utf8.decode(BackupCodec.encode(withEq)))
              as Map<String, dynamic>;
      json['equalizer']['settings']['boost_db'] = 99;
      final read = BackupCodec.decode(_bytes(json));
      expect(read.equalizer, isNull);
      expect(read.playlists, _backup.playlists);
      expect(read.settings, _backup.settings);
    });

    test('not an object, it is left out', () {
      final json = _json()..['equalizer'] = 'loud';
      expect(BackupCodec.decode(_bytes(json)).equalizer, isNull);
    });
  });

  group('imported lyrics', () {
    final withLyrics = Backup(
      createdAt: _backup.createdAt,
      tracks: _backup.tracks,
      playlists: _backup.playlists,
      plays: _backup.plays,
      days: _backup.days,
      trackDays: _backup.trackDays,
      firstPlays: _backup.firstPlays,
      hours: _backup.hours,
      replayMonth: _backup.replayMonth,
      settings: _backup.settings,
      lyrics: const [
        BackupLyrics(track: '1', text: '[00:01.00]Mine', offsetMs: -300),
      ],
    );

    Map<String, dynamic> json() =>
        jsonDecode(utf8.decode(BackupCodec.encode(withLyrics)))
            as Map<String, dynamic>;

    test('read back as they were written', () {
      expect(
        BackupCodec.decode(BackupCodec.encode(withLyrics)).lyrics,
        withLyrics.lyrics,
      );
    });

    test('a backup made before them has none, and no key', () {
      expect(_json().containsKey('lyrics'), isFalse);
      expect(BackupCodec.decode(BackupCodec.encode(_backup)).lyrics, isEmpty);
    });

    test('an entry that cannot be read is left out, the rest restores', () {
      final j = json();
      (j['lyrics'] as List).addAll([
        {'track': '9', 'text': 'Unknown song', 'offsetMs': 0},
        {'track': '1', 'text': '  ', 'offsetMs': 0},
        {'track': '1', 'text': 'Too far', 'offsetMs': 60000},
        {'track': '1', 'text': 42, 'offsetMs': 0},
        // Tags alone: no lyrics to show, never stored.
        {'track': '1', 'text': '[ar:Someone]', 'offsetMs': 0},
        {'track': '1', 'text': 'Bin\u0000ary\u0001\u0002\u0003', 'offsetMs': 0},
        'not an object',
      ]);
      final read = BackupCodec.decode(_bytes(j));
      expect(read.lyrics, withLyrics.lyrics);
      expect(read.playlists, _backup.playlists);
    });

    test('not a list, they are left out', () {
      final j = json()..['lyrics'] = 'la la la';
      expect(BackupCodec.decode(_bytes(j)).lyrics, isEmpty);
    });
  });

  group('corrections of lyrics found online', () {
    final withOffsets = Backup(
      createdAt: _backup.createdAt,
      tracks: _backup.tracks,
      playlists: _backup.playlists,
      plays: _backup.plays,
      days: _backup.days,
      trackDays: _backup.trackDays,
      firstPlays: _backup.firstPlays,
      hours: _backup.hours,
      replayMonth: _backup.replayMonth,
      settings: _backup.settings,
      lyricsOffsets: const [BackupLyricsOffset(track: '1', offsetMs: 400)],
    );

    Map<String, dynamic> json() =>
        jsonDecode(utf8.decode(BackupCodec.encode(withOffsets)))
            as Map<String, dynamic>;

    test('read back as they were written', () {
      expect(
        BackupCodec.decode(BackupCodec.encode(withOffsets)).lyricsOffsets,
        withOffsets.lyricsOffsets,
      );
    });

    test('a backup without any has no key', () {
      expect(_json().containsKey('lyricsOffsets'), isFalse);
      expect(
        BackupCodec.decode(BackupCodec.encode(_backup)).lyricsOffsets,
        isEmpty,
      );
    });

    test('an entry that cannot be read is left out, the rest restores', () {
      final j = json();
      (j['lyricsOffsets'] as List).addAll([
        {'track': '9', 'offsetMs': 100}, // unknown song
        {'track': '1', 'offsetMs': 200}, // the song again: the first wins
        {'track': '1', 'offsetMs': 0}, // nothing to restore
        {'track': '1', 'offsetMs': 60000}, // out of bounds
        {'track': '1', 'offsetMs': -60000},
        // The lowest integer: abs() leaves it negative.
        {'track': '1', 'offsetMs': -9223372036854775808},
        {'track': '1', 'offsetMs': '300'},
        'not an object',
      ]);
      final read = BackupCodec.decode(_bytes(j));
      expect(read.lyricsOffsets, withOffsets.lyricsOffsets);
      expect(read.playlists, _backup.playlists);
    });

    test('not a list, they are left out', () {
      final j = json()..['lyricsOffsets'] = 400;
      expect(BackupCodec.decode(_bytes(j)).lyricsOffsets, isEmpty);
    });
  });

  test('a backup made before the hours were counted has none', () {
    final json = _json();
    (json['history'] as Map).remove('hours');
    expect(BackupCodec.decode(_bytes(json)).hours, isEmpty);
    expect(BackupCodec.decode(_bytes(json)).days, _backup.days);
  });

  test('an hour to come is dropped', () {
    final json = _json();
    (json['history']['hours'] as List).add({'hour': 1 << 30, 'plays': 1});
    expect(BackupCodec.decode(_bytes(json)).hours, _backup.hours);
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

    expect(read.settings?.glassQuality, GlassQuality.auto);
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

  group('history out of range is dropped, so it never sticks', () {
    Backup decoded(void Function(Map<String, dynamic> json) change) {
      final json = _json();
      change(json);
      return BackupCodec.decode(_bytes(json));
    }

    test('a day longer than a day of listening at 2x', () {
      final read = decoded(
        (j) => (j['history']['days'] as List).first['listenedMs'] = 1 << 62,
      );
      expect(read.days, isEmpty);
      expect(read.plays, hasLength(1));
    });

    test('a day to come', () {
      final read = decoded(
        (j) => (j['history']['trackDays'] as List).first['day'] = 1 << 40,
      );
      expect(read.trackDays, isEmpty);
    });

    test('a play in the far future', () {
      final read = decoded(
        (j) => (j['history']['plays'] as List).first['at'] =
            '9999-01-01T00:00:00.000Z',
      );
      expect(read.plays, isEmpty);
    });

    test('a Replay month to come', () {
      final read = decoded((j) => j['history']['replayMonth'] = 1 << 40);
      expect(read.replayMonth, isNull);
    });

    test('a phone whose clock said 1970 still restores', () {
      final read = BackupCodec.decode(
        BackupCodec.encode(
          Backup(
            createdAt: DateTime.utc(1970),
            tracks: _backup.tracks,
            playlists: _backup.playlists,
            plays: [BackupPlay(track: '1', at: DateTime.utc(1970))],
            days: const [BackupDay(day: 0, plays: 1, listenedMs: 1)],
            trackDays: const [BackupTrackDay(day: 0, track: '1', plays: 1)],
            firstPlays: const [BackupFirstPlay(track: '1', day: 0)],
            replayMonth: null,
            settings: const AppSettings(),
          ),
        ),
      );

      expect(read.playlists, _backup.playlists);
      expect(read.plays, isEmpty);
      expect(read.days, isEmpty);
      expect(read.firstPlays, isEmpty);
    });
  });

  group('malformed times reject the file', () {
    void rejects(String at) {
      final json = _json();
      (json['history']['plays'] as List).first['at'] = at;
      expect(() => BackupCodec.decode(_bytes(json)), _rejected);
    }

    test('a date that does not exist', () => rejects('2026-02-30T10:00:00Z'));

    test('a time without its zone', () => rejects('2026-10-29T18:00:00.000'));

    test('a year beyond four digits', () {
      rejects('+275760-09-13T00:00:00.000Z');
    });
  });

  test('version zero is refused', () {
    final json = _json()..['version'] = 0;
    expect(() => BackupCodec.decode(_bytes(json)), _rejected);
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

  group('parts', () {
    test('a whole backup keeps version 1 and lists no contents', () {
      final json = _json();

      expect(json['version'], 1);
      expect(json.containsKey('contents'), isFalse);
    });

    test('every part but the equalizer is still version 1, which older apps '
        'read whole', () {
      final noEq = _backup.only(
        BackupPart.all.difference({BackupPart.equalizer}),
      );
      final json =
          jsonDecode(utf8.decode(BackupCodec.encode(noEq)))
              as Map<String, dynamic>;

      expect(json['version'], 1);
      expect(json.containsKey('contents'), isFalse);
      expect(json.containsKey('equalizer'), isFalse);
    });

    test('without lyrics and the equalizer, still version 1: older apps '
        'ignore both', () {
      final json =
          jsonDecode(
                utf8.decode(
                  BackupCodec.encode(
                    _backup.only(
                      BackupPart.all.difference({
                        BackupPart.lyrics,
                        BackupPart.equalizer,
                      }),
                    ),
                  ),
                ),
              )
              as Map<String, dynamic>;

      expect(json['version'], 1);
      expect(json.containsKey('contents'), isFalse);
    });

    test('lyrics alone are version 2, with the songs they name', () {
      final lyrics = Backup(
        createdAt: DateTime.utc(2026, 10, 30),
        tracks: _backup.tracks,
        playlists: _backup.playlists,
        plays: const [],
        days: const [],
        trackDays: const [],
        firstPlays: const [],
        replayMonth: null,
        settings: null,
        lyrics: const [
          BackupLyrics(track: '1', text: '[00:01.00]La', offsetMs: 100),
        ],
        lyricsOffsets: const [],
      ).only({BackupPart.lyrics});
      final bytes = BackupCodec.encode(lyrics);
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(json['version'], 2);
      expect(json['contents'], ['lyrics']);
      expect(json.containsKey('playlists'), isFalse);
      expect(BackupCodec.decode(bytes), lyrics);
    });

    test('lyrics a backup holds outside its parts are not written', () {
      final stray = Backup(
        createdAt: DateTime.utc(2026, 10, 30),
        parts: const {BackupPart.likes},
        tracks: _backup.tracks,
        playlists: const [
          BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['1']),
        ],
        plays: const [],
        days: const [],
        trackDays: const [],
        firstPlays: const [],
        replayMonth: null,
        settings: null,
        lyrics: const [BackupLyrics(track: '1', text: '[00:01.00]La')],
        lyricsOffsets: const [BackupLyricsOffset(track: '1', offsetMs: 300)],
      );
      final json =
          jsonDecode(utf8.decode(BackupCodec.encode(stray)))
              as Map<String, dynamic>;

      expect(json.containsKey('lyrics'), isFalse);
      expect(json.containsKey('lyricsOffsets'), isFalse);
    });

    test('lyrics in a file that does not list them are not read', () {
      final json = _json()
        ..['version'] = 2
        ..['contents'] = ['likes']
        ..['lyrics'] = [
          {'track': '1', 'text': '[00:01.00]La', 'offsetMs': 0},
        ];

      expect(BackupCodec.decode(_bytes(json)).lyrics, isEmpty);
    });

    test('lyrics change the fingerprint, so a new lyric is backed up', () {
      final withLyrics = Backup(
        createdAt: _backup.createdAt,
        tracks: _backup.tracks,
        playlists: _backup.playlists,
        plays: _backup.plays,
        days: _backup.days,
        trackDays: _backup.trackDays,
        firstPlays: _backup.firstPlays,
        hours: _backup.hours,
        replayMonth: _backup.replayMonth,
        settings: _backup.settings,
        lyricsOffsets: const [BackupLyricsOffset(track: '1', offsetMs: 300)],
      );

      expect(
        BackupCodec.fingerprint(withLyrics),
        isNot(BackupCodec.fingerprint(_backup)),
      );
    });

    test('a backup of some parts is version 2 and holds only those', () {
      final likes = _backup.only({BackupPart.likes, BackupPart.equalizer});
      final json =
          jsonDecode(utf8.decode(BackupCodec.encode(likes)))
              as Map<String, dynamic>;

      expect(json['version'], 2);
      // Listed though this backup has no equalizer, as a whole backup may
      // lack one: a restore offers it only when there.
      expect(json['contents'], ['likes', 'equalizer']);
      expect(json.containsKey('history'), isFalse);
      expect(json.containsKey('settings'), isFalse);
      expect((json['playlists'] as List).single['likes'], isTrue);
      expect(BackupCodec.decode(BackupCodec.encode(likes)), likes);
    });

    test('settings alone name no song', () {
      final settings = _backup.only({BackupPart.settings});
      final read = BackupCodec.decode(BackupCodec.encode(settings));

      expect(read.parts, {BackupPart.settings});
      expect(read.tracks, isEmpty);
      expect(read.settings, _backup.settings);
    });

    test('a part this version does not know is skipped', () {
      final json = _json()
        ..['version'] = 2
        ..['contents'] = ['likes', 'podcasts'];

      final read = BackupCodec.decode(_bytes(json));

      expect(read.parts, {BackupPart.likes});
      expect(read.playlists.single.isLikes, isTrue);
    });

    test('a section of a part not listed is not read', () {
      final json = _json()
        ..['version'] = 2
        ..['contents'] = ['playlists'];

      final read = BackupCodec.decode(_bytes(json));

      expect(read.settings, isNull);
      expect(read.plays, isEmpty);
      expect(read.replayMonth, isNull);
      expect(read.playlists.map((p) => p.name), ['Road trip', 'Forgotten']);
    });

    test('a part listed without its section is refused', () {
      final json = _json()
        ..['version'] = 2
        ..['contents'] = ['history']
        ..remove('history');

      expect(() => BackupCodec.decode(_bytes(json)), _rejected);
    });

    test('version 2 without a list of contents is refused', () {
      final json = _json()..['version'] = 2;

      expect(() => BackupCodec.decode(_bytes(json)), _rejected);
    });
  });

  group('library filters', () {
    Backup withSettings(AppSettings settings) => Backup(
      createdAt: _backup.createdAt,
      tracks: _backup.tracks,
      playlists: _backup.playlists,
      plays: _backup.plays,
      days: _backup.days,
      trackDays: _backup.trackDays,
      firstPlays: _backup.firstPlays,
      replayMonth: null,
      settings: settings,
    );

    test('travel with the settings', () {
      final read = BackupCodec.decode(
        BackupCodec.encode(
          withSettings(
            const AppSettings(minTrackSeconds: 120, excludedFolders: ['/a/b']),
          ),
        ),
      );

      expect(read.settings?.minTrackSeconds, 120);
      expect(read.settings?.excludedFolders, ['/a/b']);
    });

    test('the playback switches travel, and read as on when absent', () {
      final read = BackupCodec.decode(
        BackupCodec.encode(
          withSettings(
            const AppSettings(keepShuffle: false, lyricsKeepScreenOn: false),
          ),
        ),
      );
      expect(read.settings?.keepShuffle, isFalse);
      expect(read.settings?.lyricsKeepScreenOn, isFalse);

      final json = _json();
      (json['settings'] as Map)
        ..remove('keepShuffle')
        ..['lyricsKeepScreenOn'] = 'yes';
      final older = BackupCodec.decode(_bytes(json));
      expect(older.settings?.keepShuffle, isTrue);
      expect(older.settings?.lyricsKeepScreenOn, isTrue);
    });

    test('a paused history stays on the phone it was paused on', () {
      final bytes = BackupCodec.encode(
        withSettings(const AppSettings(historyPaused: true)),
      );

      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect((json['settings'] as Map).keys, isNot(contains('historyPaused')));
      expect(BackupCodec.decode(bytes).settings?.historyPaused, isFalse);
    });

    test('a backup made before them reads as the defaults', () {
      final json = _json();
      (json['settings'] as Map)
        ..remove('minTrackSeconds')
        ..remove('excludedFolders');

      final read = BackupCodec.decode(_bytes(json));

      expect(read.settings?.minTrackSeconds, 10);
      expect(read.settings?.excludedFolders, isEmpty);
    });

    test('a broken value is dropped, never the backup', () {
      final json = _json();
      (json['settings'] as Map)
        ..['minTrackSeconds'] = 45
        ..['excludedFolders'] = ['/ok', 3, '', 'x' * 5000];

      final read = BackupCodec.decode(_bytes(json));

      expect(read.settings?.minTrackSeconds, 10);
      expect(read.settings?.excludedFolders, ['/ok']);
      expect(read.settings?.hapticFeedbackEnabled, isFalse);
    });
  });
}
