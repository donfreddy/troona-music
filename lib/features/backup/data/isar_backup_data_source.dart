import 'dart:math';

import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/history/data/models/listening_models.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
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
  /// cannot be described, so what names it is left out.
  Backup read({
    required DateTime createdAt,
    required AppSettings settings,
    required int? replayMonth,
  }) {
    final playlists = _isar.playlistModels.where().findAll();
    final plays = _isar.playEventModels.where().sortByPlayedAt().findAll();
    final trackDays = _isar.trackDayModels.where().findAll();
    final firstPlays = _isar.trackFirstPlayModels.where().findAll();

    final named = {
      for (final p in playlists) ...p.trackIds,
      for (final p in plays) p.trackId,
      for (final d in trackDays) d.trackId,
      for (final f in firstPlays) f.id,
    };
    final tracks = {
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
          ),
      ],
      plays: [
        for (final p in plays)
          if (tracks.containsKey(p.trackId))
            BackupPlay(track: p.trackId, at: p.playedAt),
      ],
      days: [
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
      replayMonth: replayMonth,
      settings: settings,
    );
  }

  /// Merges [backup] into the database. [ids] gives the device id of each
  /// song of the backup found in the library; the others are skipped.
  Future<void> restore(Backup backup, Map<String, String> ids) async =>
      _isar.write((isar) {
        _restorePlaylists(isar, backup.playlists, ids);
        _restorePlays(isar, backup.plays, ids);
        _restoreTotals(isar, backup, ids);
      });

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
    final byName = <String, List<PlaylistModel>>{};
    PlaylistModel? likes;
    for (final p in stored) {
      if (p.playlistId == Playlist.likesId) {
        likes = p;
      } else {
        (byName[p.name] ??= []).add(p);
      }
    }
    final seen = <String, int>{};
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var created = 0;
    for (final playlist in saved) {
      final PlaylistModel? target;
      if (playlist.isLikes) {
        target = likes;
      } else {
        final rank = seen[playlist.name] = (seen[playlist.name] ?? -1) + 1;
        target = byName[playlist.name]?.elementAtOrNull(rank);
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
  void _restorePlays(
    Isar isar,
    List<BackupPlay> saved,
    Map<String, String> ids,
  ) {
    final events = isar.playEventModels;
    final stored = {
      for (final e in events.where().findAll()) _playKey(e.trackId, e.playedAt),
    };
    for (final play in saved) {
      final id = ids[play.track];
      if (id == null || !stored.add(_playKey(id, play.at))) continue;
      events.put(
        PlayEventModel()
          ..id = events.autoIncrement()
          ..trackId = id
          ..playedAt = play.at.toLocal(),
      );
    }
    final excess = events.count() - maxPlays;
    if (excess > 0) {
      final oldest = events.where().sortByPlayedAt().findAll(limit: excess);
      events.deleteAll([for (final e in oldest) e.id]);
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
