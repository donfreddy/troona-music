import 'dart:convert';

import 'package:troona/features/library/data/models/smart_rules_json.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/equalizer/data/equalizer_json.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_snapshot.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';
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
/// reference between them and the sizes, and rejects the whole file on the
/// first problem: a half-read backup would restore half a library.
///
/// History records out of range are dropped instead: a restore keeps the
/// larger of two counts, so an absurd value would stay for good, yet a
/// phone with a wrong clock (1970 at boot, or ahead) writes such records
/// itself, and its backups must still restore.
abstract final class BackupCodec {
  static const format = 'troona-backup';

  /// The newest version read. Version 1 holds every part; version 2 lists
  /// the parts it holds under `contents`.
  static const version = 2;

  /// Larger than any real backup: a library of 100 000 songs with its
  /// history stays well under it.
  static const maxBytes = 20 * 1024 * 1024;
  static const _maxItems = 1000000;

  /// Longer texts are cut on export, so every file written reads back.
  static const maxText = 4096;

  /// Nothing in Troona predates this.
  static final _firstDay = ListeningDay.of(DateTime.utc(2000));

  /// A 25-hour day (daylight saving) played at the top speed, 2x.
  static const _maxDayMs = 50 * Duration.millisecondsPerHour;
  static const _maxDayPlays = 100000;

  static List<int> encode(Backup backup) {
    final held = {
      for (final part in backup.parts)
        if (part != BackupPart.settings || backup.settings != null) part,
    };
    // The equalizer and lyrics are optional in version 1 too: a backup
    // without them is still one an older app restores whole.
    final complete = held.containsAll(
      BackupPart.all.difference({BackupPart.equalizer, BackupPart.lyrics}),
    );
    bool has(BackupPart part) => held.contains(part);
    return utf8.encode(
      jsonEncode({
        'format': format,
        // A whole backup keeps the first version, which older apps read; one
        // that leaves parts out is a version they refuse, rather than
        // restore as if it held nothing.
        'version': complete ? 1 : version,
        if (!complete)
          'contents': [
            for (final part in BackupPart.values)
              if (has(part)) part.name,
          ],
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
        if (has(BackupPart.playlists) || has(BackupPart.likes))
          'playlists': [
            for (final p in backup.playlists)
              if (has(p.isLikes ? BackupPart.likes : BackupPart.playlists))
                {
                  'name': _clip(p.name),
                  'likes': p.isLikes,
                  'tracks': p.tracks,
                  if (p.rules case final rules?)
                    'rules': SmartRulesJson.encode(rules),
                },
          ],
        if (has(BackupPart.history))
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
              for (final f in backup.firstPlays)
                {'track': f.track, 'day': f.day},
            ],
            'hours': [
              for (final h in backup.hours) {'hour': h.hour, 'plays': h.plays},
            ],
            'replayMonth': backup.replayMonth,
          },
        if (backup.settings case final settings? when has(BackupPart.settings))
          'settings': _encodeSettings(settings),
        if (backup.equalizer case final eq? when has(BackupPart.equalizer))
          'equalizer': {
            'settings': EqualizerJson.encodeSettings(eq.settings),
            'profiles': EqualizerJson.encodeProfiles(eq.profiles),
          },
        if (has(BackupPart.lyrics) && backup.lyrics.isNotEmpty)
          'lyrics': [
            for (final l in backup.lyrics)
              {'track': l.track, 'text': l.text, 'offsetMs': l.offsetMs},
          ],
        if (has(BackupPart.lyrics) && backup.lyricsOffsets.isNotEmpty)
          'lyricsOffsets': [
            for (final o in backup.lyricsOffsets)
              {'track': o.track, 'offsetMs': o.offsetMs},
          ],
      }),
    );
  }

  /// What [backup] holds, as 16 hex digits: 64-bit FNV-1a over its
  /// encoding with the date left out, so two backups of the same data
  /// match. Not for security: it only spares writing the same backup twice.
  static String fingerprint(Backup backup) {
    final undated = Backup(
      createdAt: DateTime.utc(2000),
      parts: backup.parts,
      tracks: backup.tracks,
      playlists: backup.playlists,
      plays: backup.plays,
      days: backup.days,
      trackDays: backup.trackDays,
      firstPlays: backup.firstPlays,
      hours: backup.hours,
      replayMonth: backup.replayMonth,
      settings: backup.settings,
      equalizer: backup.equalizer,
      lyrics: backup.lyrics,
      lyricsOffsets: backup.lyricsOffsets,
    );
    // Dart ints wrap on overflow, which is the modulo FNV needs.
    var hash = 0xcbf29ce484222325;
    for (final byte in encode(undated)) {
      hash = (hash ^ byte) * 0x100000001b3;
    }
    // In two halves: a 64-bit hash is often negative as a Dart int.
    String half(int bits) => bits.toRadixString(16).padLeft(8, '0');
    return half((hash >> 32) & 0xffffffff) + half(hash & 0xffffffff);
  }

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
    final parts = fileVersion == 1
        ? BackupPart.all
        : _contents(json['contents']);
    bool has(BackupPart part) => parts.contains(part);
    bool inRange(int day) => day >= _firstDay && day <= lastDay;
    // Records failing these are dropped, not fatal (see the class comment).
    bool fair(int day, {int plays = 0, int listenedMs = 0}) =>
        inRange(day) && plays <= _maxDayPlays && listenedMs <= _maxDayMs;

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

    // A part listed must be there; one left out is not read, even if its
    // key is.
    final history = has(BackupPart.history)
        ? _map(json['history'], 'history')
        : const <String, Object?>{
            'plays': [],
            'days': [],
            'trackDays': [],
            'firstPlays': [],
          };
    final playlists = has(BackupPart.playlists) || has(BackupPart.likes)
        ? json['playlists']
        : const <Object?>[];
    return Backup(
      createdAt: _utc(_text(json['createdAt'], 'createdAt'), 'createdAt'),
      parts: parts,
      tracks: tracks,
      playlists: [
        for (final playlist in _list(playlists, 'playlists', (p) {
          final m = _map(p, 'playlist');
          return BackupPlaylist(
            name: _text(m['name'], 'playlist name'),
            isLikes: _bool(m['likes'], 'likes'),
            tracks: _list(m['tracks'], 'playlist tracks', ref),
            // Lenient: rules that cannot be read still make a smart playlist,
            // one that keeps nothing until edited.
            rules: m.containsKey('rules')
                ? SmartRulesJson.decode(m['rules']) ?? SmartRulesJson.unreadable
                : null,
          );
        }))
          if (has(playlist.isLikes ? BackupPart.likes : BackupPart.playlists))
            playlist,
      ],
      plays: [
        for (final play in _list(history['plays'], 'plays', (p) {
          final m = _map(p, 'play');
          return BackupPlay(
            track: ref(m['track']),
            at: _utc(_text(m['at'], 'play time'), 'play time'),
          );
        }))
          if (inRange(ListeningDay.of(play.at))) play,
      ],
      days: [
        for (final d in _list(history['days'], 'days', (d) {
          final m = _map(d, 'day');
          return BackupDay(
            day: _int(m['day'], 'day'),
            plays: _int(m['plays'], 'plays'),
            listenedMs: _int(m['listenedMs'], 'listenedMs'),
          );
        }))
          if (fair(d.day, plays: d.plays, listenedMs: d.listenedMs)) d,
      ],
      trackDays: [
        for (final d in _list(history['trackDays'], 'trackDays', (d) {
          final m = _map(d, 'trackDay');
          return BackupTrackDay(
            day: _int(m['day'], 'day'),
            track: ref(m['track']),
            plays: _int(m['plays'], 'plays'),
          );
        }))
          if (fair(d.day, plays: d.plays)) d,
      ],
      firstPlays: [
        for (final f in _list(history['firstPlays'], 'firstPlays', (f) {
          final m = _map(f, 'firstPlay');
          return BackupFirstPlay(
            track: ref(m['track']),
            day: _int(m['day'], 'day'),
          );
        }))
          if (inRange(f.day)) f,
      ],
      // Absent from backups made before the hours were counted.
      hours: [
        if (history['hours'] != null)
          for (final h in _list(history['hours'], 'hours', (h) {
            final m = _map(h, 'hour');
            return BackupHour(
              hour: _int(m['hour'], 'hour'),
              plays: _int(m['plays'], 'plays'),
            );
          }))
            if (fair(h.hour ~/ 24, plays: h.plays)) h,
      ],
      replayMonth: switch (history['replayMonth']) {
        null => null,
        final month => switch (_int(month, 'replayMonth')) {
          final m when m >= 2000 * 12 && m <= lastMonth => m,
          _ => null,
        },
      },
      settings: has(BackupPart.settings)
          ? _decodeSettings(_map(json['settings'], 'settings'))
          : null,
      equalizer: has(BackupPart.equalizer)
          ? _decodeEqualizer(json['equalizer'])
          : null,
      lyrics: has(BackupPart.lyrics)
          ? _decodeLyrics(json['lyrics'], tracks.keys.toSet())
          : const [],
      lyricsOffsets: has(BackupPart.lyrics)
          ? _decodeLyricsOffsets(json['lyricsOffsets'], tracks.keys.toSet())
          : const [],
    );
  }

  /// The parts a version 2 file lists. A name this version does not know
  /// (a part added later) is skipped: the parts it knows still restore.
  static Set<BackupPart> _contents(Object? json) {
    final names = _list(json, 'contents', (n) => _text(n, 'part'));
    return {
      for (final part in BackupPart.values)
        if (names.contains(part.name)) part,
    };
  }

  /// Optional, and read leniently, as [_decodeLyrics]: a correction of an
  /// unknown song, of nothing or out of bounds is left out.
  static List<BackupLyricsOffset> _decodeLyricsOffsets(
    Object? json,
    Set<String> tracks,
  ) {
    if (json is! List || json.length > _maxItems) return const [];
    final maxOffset = LyricsRepository.maxOffset.inMilliseconds;
    final seen = <String>{};
    return [
      for (final item in json)
        if (item
            case {'track': final String track, 'offsetMs': final int offsetMs}
            when tracks.contains(track) &&
                offsetMs != 0 &&
                _within(offsetMs, maxOffset) &&
                seen.add(track))
          BackupLyricsOffset(track: track, offsetMs: offsetMs),
    ];
  }

  /// Both bounds, never `abs()`: the lowest integer has no positive.
  static bool _within(int value, int bound) =>
      value >= -bound && value <= bound;

  /// Optional, and read leniently: lyrics that cannot be read are left
  /// out, the rest of the backup still restores. An older app ignores the
  /// key, so it needs no new [version].
  static List<BackupLyrics> _decodeLyrics(Object? json, Set<String> tracks) {
    if (json is! List || json.length > _maxItems) return const [];
    final maxOffset = LyricsRepository.maxOffset.inMilliseconds;
    return [
      for (final item in json)
        if (item
            case {
              'track': final String track,
              'text': final String text,
              'offsetMs': final int offsetMs,
            }
            when tracks.contains(track) &&
                text.trim().isNotEmpty &&
                text.length <= LrcParser.maxBytes &&
                _within(offsetMs, maxOffset) &&
                LrcParser.looksLikeText(text) &&
                LrcParser.parse(text, source: LyricsSource.imported) != null)
          BackupLyrics(track: track, text: text, offsetMs: offsetMs),
    ];
  }

  /// Optional, and checked on its own: an equalizer out of bounds is left
  /// out, the rest of the backup still restores. An older app ignores the
  /// key, so it needs no new [version].
  static EqualizerSnapshot? _decodeEqualizer(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final settings = EqualizerJson.decodeSettings(json['settings']);
    final profiles = EqualizerJson.decodeProfiles(json['profiles']);
    if (settings == null || profiles == null) return null;
    return EqualizerSnapshot(settings: settings, profiles: profiles);
  }

  static Map<String, Object?> _encodeSettings(AppSettings s) => {
    'stopOnCall': s.stopOnCallEnabled,
    'resumeAfterCall': s.resumeAfterCallEnabled,
    'duckOnNotification': s.duckAudioOnNotification,
    'onlineBios': s.fetchOnlineMetadata,
    'onlinePhotos': s.fetchArtistArtwork,
    'onlineExtrasOffered': s.onlineExtrasOffered,
    'haptics': s.hapticFeedbackEnabled,
    'keepShuffle': s.keepShuffle,
    'lyricsKeepScreenOn': s.lyricsKeepScreenOn,
    'minTrackSeconds': s.minTrackSeconds,
    'excludedFolders': s.excludedFolders,
  };

  /// The glass quality depends on the phone: it is neither saved nor read.
  /// The library filters came later and are read leniently: a backup
  /// without them, or with a value this app does not offer, reads as the
  /// defaults (what the app did before them), and a folder that is not a
  /// short text is dropped. So are the playback switches, which came
  /// later still (a value not a boolean reads as on, the default).
  static AppSettings _decodeSettings(Map<String, Object?> m) => AppSettings(
    keepShuffle: switch (m['keepShuffle']) {
      final bool b => b,
      _ => true,
    },
    lyricsKeepScreenOn: switch (m['lyricsKeepScreenOn']) {
      final bool b => b,
      _ => true,
    },
    minTrackSeconds: switch (m['minTrackSeconds']) {
      final int s when AppSettings.minTrackChoices.contains(s) => s,
      _ => const AppSettings().minTrackSeconds,
    },
    excludedFolders: switch (m['excludedFolders']) {
      final List<Object?> list => [
        for (final f in list.take(_maxItems))
          if (f is String && f.isNotEmpty && f.length <= maxText) f,
      ],
      _ => const [],
    },
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
    durationMs: _int(m['durationMs'], 'durationMs'),
    fileName: _text(m['fileName'], 'fileName'),
    size: _int(m['size'], 'size'),
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

  static int _int(Object? value, String what, {int min = 0}) =>
      value is int && value >= min
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
