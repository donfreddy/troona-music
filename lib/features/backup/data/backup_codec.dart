import 'dart:convert';

import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// Thrown by [BackupCodec.decode] on a file that is not a valid backup.
final class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Thrown by [BackupCodec.decode] on a backup from a newer app.
final class BackupVersionException implements Exception {
  final int version;
  const BackupVersionException(this.version);
}

/// Backup files: versioned JSON.
///
/// An imported file is untrusted input. [decode] checks every field, every
/// reference between them, the sizes and the ranges, and rejects the whole
/// file on the first problem: a half-read backup would restore half a
/// library. Ranges matter because a restore keeps the larger of two counts:
/// an absurd value would stay for good.
abstract final class BackupCodec {
  static const format = 'troona-backup';
  static const version = 1;

  /// Larger than any real backup: a library of 100 000 songs with its
  /// history stays well under it.
  static const maxBytes = 20 * 1024 * 1024;
  static const _maxItems = 1000000;

  /// Longer texts are cut on export, so every file written reads back.
  static const maxText = 4096;

  /// Nothing in Troona predates this.
  static final _firstDay = ListeningDay.of(DateTime.utc(2000));
  static const _maxDayMs = 25 * Duration.millisecondsPerHour; // DST
  static const _maxDayPlays = 100000;
  static const _maxDurationMs = 7 * Duration.millisecondsPerDay;
  static const _maxSize = 1 << 42;

  static List<int> encode(Backup backup) => utf8.encode(
    jsonEncode({
      'format': format,
      'version': version,
      'createdAt': backup.createdAt.toUtc().toIso8601String(),
      'tracks': {
        for (final MapEntry(:key, value: t) in backup.tracks.entries)
          key: {
            'title': _clip(t.title),
            'artist': _clip(t.artist),
            'album': _clip(t.album),
            'durationMs': t.durationMs,
            'fileName': _clip(t.fileName),
            'size': t.size,
          },
      },
      'playlists': [
        for (final p in backup.playlists)
          {'name': _clip(p.name), 'likes': p.isLikes, 'tracks': p.tracks},
      ],
      'history': {
        'plays': [
          for (final p in backup.plays)
            {'track': p.track, 'at': p.at.toUtc().toIso8601String()},
        ],
        'days': [
          for (final d in backup.days)
            {'day': d.day, 'plays': d.plays, 'listenedMs': d.listenedMs},
        ],
        'trackDays': [
          for (final d in backup.trackDays)
            {'day': d.day, 'track': d.track, 'plays': d.plays},
        ],
        'firstPlays': [
          for (final f in backup.firstPlays) {'track': f.track, 'day': f.day},
        ],
        'replayMonth': backup.replayMonth,
      },
      'settings': _encodeSettings(backup.settings),
    }),
  );

  /// [now] bounds the dates: a backup cannot hold days to come.
  static Backup decode(List<int> bytes, {DateTime? now}) {
    final today = ListeningDay.of(now ?? DateTime.now());
    // A day's margin for time zones ahead of this phone.
    final lastDay = today + 1;
    final at = now ?? DateTime.now();
    final lastMonth = at.year * 12 + at.month - 1;
    if (bytes.length > maxBytes) {
      throw const BackupFormatException('File too large');
    }
    final Object? root;
    try {
      root = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupFormatException('Not JSON');
    }
    final json = _map(root, 'root');
    if (json['format'] != format) {
      throw const BackupFormatException('Not a Troona backup');
    }
    final fileVersion = _int(json['version'], 'version', min: 1);
    if (fileVersion > version) throw BackupVersionException(fileVersion);
    int day(Object? value) => _int(value, 'day', min: _firstDay, max: lastDay);
    DateTime time(Object? value, String what) {
      final parsed = _utc(_text(value, what), what);
      final d = ListeningDay.of(parsed);
      if (d < _firstDay || d > lastDay) {
        throw BackupFormatException('$what out of range');
      }
      return parsed;
    }

    final tracks = {
      for (final MapEntry(:key, :value) in _map(
        json['tracks'],
        'tracks',
      ).entries)
        _text(key, 'track key'): _track(_map(value, 'track')),
    };
    _limit(tracks.length, 'tracks');
    String ref(Object? value) {
      final key = _text(value, 'track reference');
      if (!tracks.containsKey(key)) {
        throw BackupFormatException('Unknown track $key');
      }
      return key;
    }

    final history = _map(json['history'], 'history');
    return Backup(
      createdAt: time(json['createdAt'], 'createdAt'),
      tracks: tracks,
      playlists: _list(json['playlists'], 'playlists', (p) {
        final m = _map(p, 'playlist');
        return BackupPlaylist(
          name: _text(m['name'], 'playlist name'),
          isLikes: _bool(m['likes'], 'likes'),
          tracks: _list(m['tracks'], 'playlist tracks', ref),
        );
      }),
      plays: _list(history['plays'], 'plays', (p) {
        final m = _map(p, 'play');
        return BackupPlay(
          track: ref(m['track']),
          at: time(m['at'], 'play time'),
        );
      }),
      days: _list(history['days'], 'days', (d) {
        final m = _map(d, 'day');
        return BackupDay(
          day: day(m['day']),
          plays: _int(m['plays'], 'plays', max: _maxDayPlays),
          listenedMs: _int(m['listenedMs'], 'listenedMs', max: _maxDayMs),
        );
      }),
      trackDays: _list(history['trackDays'], 'trackDays', (d) {
        final m = _map(d, 'trackDay');
        return BackupTrackDay(
          day: day(m['day']),
          track: ref(m['track']),
          plays: _int(m['plays'], 'plays', max: _maxDayPlays),
        );
      }),
      firstPlays: _list(history['firstPlays'], 'firstPlays', (f) {
        final m = _map(f, 'firstPlay');
        return BackupFirstPlay(track: ref(m['track']), day: day(m['day']));
      }),
      replayMonth: history['replayMonth'] == null
          ? null
          : _int(
              history['replayMonth'],
              'replayMonth',
              min: 2000 * 12,
              max: lastMonth,
            ),
      settings: _decodeSettings(_map(json['settings'], 'settings')),
    );
  }

  static Map<String, Object?> _encodeSettings(AppSettings s) => {
    'stopOnCall': s.stopOnCallEnabled,
    'resumeAfterCall': s.resumeAfterCallEnabled,
    'duckOnNotification': s.duckAudioOnNotification,
    'onlineBios': s.fetchOnlineMetadata,
    'onlinePhotos': s.fetchArtistArtwork,
    'onlineExtrasOffered': s.onlineExtrasOffered,
    'haptics': s.hapticFeedbackEnabled,
  };

  /// The glass quality depends on the phone: it is neither saved nor read.
  static AppSettings _decodeSettings(Map<String, Object?> m) => AppSettings(
    stopOnCallEnabled: _bool(m['stopOnCall'], 'stopOnCall'),
    resumeAfterCallEnabled: _bool(m['resumeAfterCall'], 'resumeAfterCall'),
    duckAudioOnNotification: _bool(
      m['duckOnNotification'],
      'duckOnNotification',
    ),
    fetchOnlineMetadata: _bool(m['onlineBios'], 'onlineBios'),
    fetchArtistArtwork: _bool(m['onlinePhotos'], 'onlinePhotos'),
    onlineExtrasOffered: _bool(m['onlineExtrasOffered'], 'onlineExtrasOffered'),
    hapticFeedbackEnabled: _bool(m['haptics'], 'haptics'),
  );

  static BackupTrack _track(Map<String, Object?> m) => BackupTrack(
    title: _text(m['title'], 'title'),
    artist: _text(m['artist'], 'artist'),
    album: _text(m['album'], 'album'),
    durationMs: _int(m['durationMs'], 'durationMs', max: _maxDurationMs),
    fileName: _text(m['fileName'], 'fileName'),
    size: _int(m['size'], 'size', max: _maxSize),
  );

  static Map<String, Object?> _map(Object? value, String what) =>
      value is Map<String, Object?>
      ? value
      : throw BackupFormatException('$what is not an object');

  static List<T> _list<T>(
    Object? value,
    String what,
    T Function(Object?) read,
  ) {
    if (value is! List) throw BackupFormatException('$what is not a list');
    _limit(value.length, what);
    return [for (final item in value) read(item)];
  }

  static String _clip(String text) =>
      text.length <= maxText ? text : text.substring(0, maxText);

  static String _text(Object? value, String what) =>
      value is String && value.length <= maxText
      ? value
      : throw BackupFormatException('$what is not a short text');

  static int _int(
    Object? value,
    String what, {
    int min = 0,
    int max = 1 << 53,
  }) => value is int && value >= min && value <= max
      ? value
      : throw BackupFormatException('$what is out of range');

  static final _utcTime = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d{1,6})?Z$',
  );

  /// UTC times as [encode] writes them. [DateTime.parse] alone takes local
  /// times and rolls over impossible dates (February 30 becomes March 2).
  static DateTime _utc(String text, String what) {
    final match = _utcTime.firstMatch(text);
    final parsed = match == null ? null : DateTime.tryParse(text);
    if (match == null || parsed == null) {
      throw BackupFormatException('$what is not a UTC time');
    }
    final fields = [
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    ];
    for (var i = 0; i < fields.length; i++) {
      if (fields[i] != int.parse(match.group(i + 1)!)) {
        throw BackupFormatException('$what is not a real date');
      }
    }
    return parsed;
  }

  static bool _bool(Object? value, String what) => value is bool
      ? value
      : throw BackupFormatException('$what is not true or false');

  static void _limit(int count, String what) {
    if (count > _maxItems) throw BackupFormatException('Too many $what');
  }
}
