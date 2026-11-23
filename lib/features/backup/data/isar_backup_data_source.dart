import 'dart:math';

import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/smart_rules_json.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/history/data/models/listening_models.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/lyrics/data/models/track_lyrics_model.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// Reads and restores the playlists and the listening history, in the
/// database the library and the history share.
///
/// A restore merges, and is written in one transaction: running it twice
/// changes nothing the second time, and a failure leaves the database as it
/// was. Totals keep the larger of the two counts, never their sum.
final class IsarBackupDataSource {
  final Isar _isar;

  /// The history keeps this many plays (see `IsarPlayHistoryDataSource`).
  final int maxPlays;

  IsarBackupDataSource(this._isar, {required this.maxPlays});

  /// Songs are keyed by their device id. A song no longer in the library
  /// cannot be described, so what names it is left out. Only the [parts]
  /// asked for are read; [settings] come with [BackupPart.settings].
  Backup read({
    required DateTime createdAt,
    required AppSettings? settings,
    required int? replayMonth,
    Set<BackupPart> parts = BackupPart.all,
  }) {
    final history = parts.contains(BackupPart.history);
    final playlists = [
      if (parts.contains(BackupPart.playlists) ||
          parts.contains(BackupPart.likes))
        for (final p in _isar.playlistModels.where().findAll())
          if (parts.contains(
            p.playlistId == Playlist.likesId
                ? BackupPart.likes
                : BackupPart.playlists,
          ))
            p,
    ];
    final plays = history
        ? _isar.playEventModels.where().sortByPlayedAt().findAll()
        : const <PlayEventModel>[];
    final trackDays = history
        ? _isar.trackDayModels.where().findAll()
        : const <TrackDayModel>[];
    final firstPlays = history
        ? _isar.trackFirstPlayModels.where().findAll()
        : const <TrackFirstPlayModel>[];
    final withLyrics = parts.contains(BackupPart.lyrics);
    final lyrics = withLyrics
        ? _isar.trackLyricsModels.where().sourceEqualTo(_imported).findAll()
        : const <TrackLyricsModel>[];
    // Lyrics found online are found again; a correction set on them by
    // hand is not. One restored and still waiting for its lyrics (a row
    // with no text) is carried on too, or the next backup would lose it.
    final corrected = [
      if (withLyrics)
        for (final l
            in _isar.trackLyricsModels
                .where()
                .not()
                .offsetMsEqualTo(0)
                .sortById()
                .findAll())
          if (l.source != _imported) l,
    ];

    final named = {
      for (final l in lyrics) l.id,
      for (final l in corrected) l.id,
      for (final p in playlists) ...p.trackIds,
      for (final p in plays) p.trackId,
      for (final d in trackDays) d.trackId,
      for (final f in firstPlays) f.id,
    };
    final tracks = {
      if (named.isNotEmpty)
        for (final t in _isar.trackModels.where().findAll())
          if (named.contains(t.deviceId))
            t.deviceId: BackupTrack(
              title: t.title,
              artist: t.artist,
              album: t.album,
              durationMs: t.durationMs,
              fileName: t.fileName,
              size: t.size,
            ),
    };

    return Backup(
      createdAt: createdAt,
      parts: {
        for (final part in parts)
          if (part != BackupPart.settings || settings != null) part,
      },
      tracks: tracks,
      playlists: [
        for (final p in playlists)
          BackupPlaylist(
            name: p.name,
            isLikes: p.playlistId == Playlist.likesId,
            tracks: [
              for (final id in p.trackIds)
                if (tracks.containsKey(id)) id,
            ],
            rules: SmartRulesJson.decodeString(p.rulesJson),
          ),
      ],
      plays: [
        for (final p in plays)
          if (tracks.containsKey(p.trackId))
            BackupPlay(track: p.trackId, at: p.playedAt),
      ],
      days: [
        if (history)
          for (final d in _isar.listeningDayModels.where().findAll())
            BackupDay(day: d.id, plays: d.plays, listenedMs: d.listenedMs),
      ],
      trackDays: [
        for (final d in trackDays)
          if (tracks.containsKey(d.trackId))
            BackupTrackDay(day: d.day, track: d.trackId, plays: d.plays),
      ],
      firstPlays: [
        for (final f in firstPlays)
          if (tracks.containsKey(f.id))
            BackupFirstPlay(track: f.id, day: f.day),
      ],
      hours: [
        if (history)
          for (final h in _isar.listeningHourModels.where().findAll())
            BackupHour(hour: h.id, plays: h.plays),
      ],
      replayMonth: history ? replayMonth : null,
      settings: parts.contains(BackupPart.settings) ? settings : null,
      lyrics: [
        for (final l in lyrics)
          if (tracks.containsKey(l.id) && l.raw != null)
            BackupLyrics(track: l.id, text: l.raw!, offsetMs: l.offsetMs),
      ],
      lyricsOffsets: [
        for (final l in corrected)
          if (tracks.containsKey(l.id))
            BackupLyricsOffset(track: l.id, offsetMs: l.offsetMs),
      ],
    );
  }

  static final _imported = LyricsSource.imported.name;

  /// Merges [backup] into the database, the records of each part it holds
  /// (narrowed with [Backup.only] for a restore of some parts). [ids] gives
  /// the device id of each song of the backup found in the library; the
  /// others are skipped.
  Future<void> restore(Backup backup, Map<String, String> ids) async =>
      _isar.write((isar) {
        _restorePlaylists(isar, backup.playlists, ids);
        final added = _restorePlays(isar, backup.plays, ids);
        _restoreTotals(isar, backup, ids);
        _restoreHours(isar, backup.hours, added);
        _restoreLyrics(isar, backup.lyrics, ids);
        _restoreLyricsOffsets(isar, backup.lyricsOffsets, ids);
      });

  /// A correction of lyrics found online comes back for the lyrics this
  /// phone finds: over online lyrics not corrected here, or kept for the
  /// first look when the song has none yet. The row it leaves then holds
  /// no lyrics and is as old as can be, so that look asks online at once
  /// (and the answer keeps the correction, see `putOnline`). A miss
  /// remembered here takes it and keeps its date: it is asked again when
  /// it was going to be. Imported lyrics (other timings) and a correction
  /// made here are left alone.
  static void _restoreLyricsOffsets(
    Isar isar,
    List<BackupLyricsOffset> saved,
    Map<String, String> ids,
  ) {
    final rows = isar.trackLyricsModels;
    for (final o in saved) {
      final id = ids[o.track];
      if (id == null) continue;
      final old = rows.get(id);
      if (old == null) {
        rows.put(
          TrackLyricsModel()
            ..id = id
            ..offsetMs = o.offsetMs
            ..checkedAt = DateTime.fromMillisecondsSinceEpoch(0),
        );
      } else if (old.source != _imported && old.offsetMs == 0) {
        rows.put(old..offsetMs = o.offsetMs);
      }
    }
  }

  /// Imported lyrics come back over lyrics found online and over the
  /// memory of none; lyrics imported on this phone stay.
  static void _restoreLyrics(
    Isar isar,
    List<BackupLyrics> saved,
    Map<String, String> ids,
  ) {
    final rows = isar.trackLyricsModels;
    final now = DateTime.now();
    for (final l in saved) {
      final id = ids[l.track];
      if (id == null || rows.get(id)?.source == _imported) continue;
      rows.put(
        TrackLyricsModel()
          ..id = id
          ..raw = l.text
          ..source = _imported
          ..offsetMs = l.offsetMs
          ..checkedAt = now,
      );
    }
  }

  /// Liked songs join the liked songs. Other playlists pair by name and
  /// rank: the second "Mix" of the backup joins the second "Mix" already
  /// here, or is created. Names need not be unique, and two playlists of one
  /// name must not merge. Songs already in a playlist keep their place.
  static void _restorePlaylists(
    Isar isar,
    List<BackupPlaylist> saved,
    Map<String, String> ids,
  ) {
    final playlists = isar.playlistModels;
    final stored = playlists.where().sortById().findAll();
    // Smart playlists and playlists of songs are matched apart: a name
    // shared by one of each never merges them.
    final byName = <String, List<PlaylistModel>>{};
    final smartByName = <String, List<PlaylistModel>>{};
    PlaylistModel? likes;
    for (final p in stored) {
      if (p.playlistId == Playlist.likesId) {
        likes = p;
      } else {
        ((p.rulesJson == null ? byName : smartByName)[p.name] ??= []).add(p);
      }
    }
    final seen = <String, int>{};
    final seenSmart = <String, int>{};
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var created = 0;
    for (final playlist in saved) {
      final PlaylistModel? target;
      if (playlist.isLikes) {
        target = likes;
      } else {
        final smart = playlist.rules != null;
        final ranks = smart ? seenSmart : seen;
        final rank = ranks[playlist.name] = (ranks[playlist.name] ?? -1) + 1;
        target = (smart ? smartByName : byName)[playlist.name]?.elementAtOrNull(
          rank,
        );
      }
      final model =
          target ??
          (PlaylistModel()
            ..id = playlists.autoIncrement()
            ..playlistId = playlist.isLikes
                ? Playlist.likesId
                : 'restored-$stamp-${created++}'
            ..name = playlist.isLikes
                ? IsarLibraryDataSource.likesPlaylistName
                : playlist.name
            ..trackIds = []);
      if (playlist.isLikes) likes = model;
      if (playlist.rules case final rules? when !playlist.isLikes) {
        // Rules the backup holds but this version cannot read never replace
        // a smart playlist that works.
        if (rules == SmartRulesJson.unreadable && target != null) continue;
        // The backup's rules: a smart playlist holds no songs.
        model
          ..rulesJson = SmartRulesJson.encodeString(rules)
          ..trackIds = [];
        playlists.put(model);
        continue;
      }
      final trackIds = [...model.trackIds];
      final present = trackIds.toSet();
      for (final key in playlist.tracks) {
        final id = ids[key];
        if (id != null && present.add(id)) trackIds.add(id);
      }
      model.trackIds = trackIds;
      playlists.put(model);
    }
  }

  /// A play already stored (same song, same time) is not added again.
  /// Returns the times of the plays added and kept under the cap.
  List<DateTime> _restorePlays(
    Isar isar,
    List<BackupPlay> saved,
    Map<String, String> ids,
  ) {
    final events = isar.playEventModels;
    final stored = {
      for (final e in events.where().findAll()) _playKey(e.trackId, e.playedAt),
    };
    final added = <int, DateTime>{};
    for (final play in saved) {
      final id = ids[play.track];
      if (id == null || !stored.add(_playKey(id, play.at))) continue;
      final at = play.at.toLocal();
      final eventId = events.autoIncrement();
      events.put(
        PlayEventModel()
          ..id = eventId
          ..trackId = id
          ..playedAt = at,
      );
      added[eventId] = at;
    }
    final excess = events.count() - maxPlays;
    if (excess > 0) {
      final oldest = events.where().sortByPlayedAt().findAll(limit: excess);
      events.deleteAll([for (final e in oldest) e.id]);
      // A play pruned at once is added again by the next restore: only
      // the plays kept may be counted.
      for (final e in oldest) {
        added.remove(e.id);
      }
    }
    return added.values.toList();
  }

  /// Hour totals keep the larger count, like the days. A backup made before
  /// the hours were counted has none: the plays it adds and keeps are
  /// counted in their hour instead, once, since a play still stored is not
  /// added again.
  static void _restoreHours(
    Isar isar,
    List<BackupHour> saved,
    List<DateTime> added,
  ) {
    final hours = isar.listeningHourModels;
    if (saved.isEmpty) {
      for (final at in added) {
        final id = ListeningDay.of(at) * 24 + at.hour;
        hours.put(
          (hours.get(id) ?? (ListeningHourModel()..id = id))..plays += 1,
        );
      }
      return;
    }
    for (final h in saved) {
      final stored = hours.get(h.hour) ?? (ListeningHourModel()..id = h.hour);
      hours.put(stored..plays = max(stored.plays, h.plays));
    }
  }

  static String _playKey(String trackId, DateTime at) =>
      '$trackId@${at.millisecondsSinceEpoch}';

  static void _restoreTotals(
    Isar isar,
    Backup backup,
    Map<String, String> ids,
  ) {
    final days = isar.listeningDayModels;
    for (final saved in backup.days) {
      final day = days.get(saved.day) ?? (ListeningDayModel()..id = saved.day);
      days.put(
        day
          ..plays = max(day.plays, saved.plays)
          ..listenedMs = max(day.listenedMs, saved.listenedMs),
      );
    }

    // Two songs of the backup can be one song here (the same file in two
    // folders): their plays of a day add up before meeting the stored count.
    final saved = <String, (int, String, int)>{};
    for (final d in backup.trackDays) {
      final id = ids[d.track];
      if (id == null) continue;
      final key = '${d.day}:$id';
      saved[key] = (d.day, id, (saved[key]?.$3 ?? 0) + d.plays);
    }
    final trackDays = isar.trackDayModels;
    for (final MapEntry(:key, value: (day, id, plays)) in saved.entries) {
      final stored =
          trackDays.get(key) ??
          (TrackDayModel()
            ..id = key
            ..day = day
            ..trackId = id);
      trackDays.put(stored..plays = max(stored.plays, plays));
    }

    final firstPlays = isar.trackFirstPlayModels;
    for (final saved in backup.firstPlays) {
      final id = ids[saved.track];
      if (id == null) continue;
      final stored = firstPlays.get(id);
      if (stored != null && stored.day <= saved.day) continue;
      firstPlays.put(
        TrackFirstPlayModel()
          ..id = id
          ..day = saved.day,
      );
    }
  }
}
