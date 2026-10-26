import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/data/sources/shared_prefs_monthly_replay_log.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/monthly_replay_log.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/use_cases/create_monthly_replay_use_case.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';

import '../../helpers/fake_player.dart';

final class _History implements PlayHistoryRepository {
  Map<String, int> plays = {};
  (int, int)? asked;

  @override
  Future<Either<Failure, ListeningStats>> listeningStats({
    required int firstDay,
    required int lastDay,
  }) async {
    asked = (firstDay, lastDay);
    return right(
      ListeningStats(
        plays: plays.values.fold(0, (s, p) => s + p),
        listened: Duration.zero,
        trackPlays: plays,
        discoveries: 0,
        historyStart: null,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Library implements LibraryRepository {
  final Set<String> known;
  _Library(this.known);

  @override
  Future<Either<Failure, List<Track>>> getTracksByIds(List<String> ids) async =>
      right([
        for (final id in ids)
          if (known.contains(id)) testTrack(id, durationMs: 1000),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Playlists implements PlaylistRepository {
  final saved = <String, Playlist>{};
  final deleted = <String>[];
  bool failUpdate = false;

  @override
  Future<Either<Failure, Playlist>> createPlaylist({
    required String title,
    String? description,
    String? artworkPath,
  }) async {
    final p = Playlist(id: 'p${saved.length + 1}', name: title);
    saved[p.id] = p;
    return right(p);
  }

  @override
  Future<Either<Failure, Unit>> updatePlaylist(Playlist playlist) async {
    if (failUpdate) return left(const DatabaseFailure());
    saved[playlist.id] = playlist;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deletePlaylist(String id) async {
    saved.remove(id);
    deleted.add(id);
    return right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Log implements MonthlyReplayLog {
  @override
  int? lastMonth;

  @override
  Future<void> setLastMonth(int month) async => lastMonth = month;
}

void main() {
  late _History history;
  late _Playlists playlists;
  late _Log log;
  late CreateMonthlyReplayUseCase replay;

  final november = DateTime(2026, 11, 3, 9);
  const octoberKey = 2026 * 12 + 9;
  String name(DateTime month) => 'Replay ${month.year}-${month.month}';

  /// [count] songs, `t0` most played.
  Map<String, int> songs(int count) => {
    for (var i = 0; i < count; i++) 't$i': 100 - i,
  };

  void build({Set<String>? known}) {
    replay = CreateMonthlyReplayUseCase(
      history: history,
      getTracksByIds: GetTracksByIdsUseCase(
        _Library(known ?? {for (var i = 0; i < 40; i++) 't$i'}),
      ),
      playlists: playlists,
      log: log,
    );
  }

  setUp(() {
    history = _History();
    playlists = _Playlists();
    log = _Log();
    build();
  });

  Future<Playlist?> run({DateTime? now}) async =>
      (await replay(now: now ?? november, name: name)).getOrElse(() => null);

  test('last month, first to last day', () async {
    history.plays = songs(10);
    await run();
    expect(history.asked, (
      ListeningDay.of(DateTime(2026, 10, 1)),
      ListeningDay.of(DateTime(2026, 10, 31)),
    ));
  });

  test('the 25 most played songs, most played first', () async {
    history.plays = songs(30);

    final playlist = await run();

    expect(playlist?.name, 'Replay 2026-10');
    expect(playlist?.trackIds, [for (var i = 0; i < 25; i++) 't$i']);
    expect(playlists.saved[playlist!.id]?.trackIds, hasLength(25));
    expect(log.lastMonth, octoberKey);
  });

  test('January makes the Replay of December', () async {
    history.plays = songs(10);
    final playlist = await run(now: DateTime(2027, 1, 1));
    expect(playlist?.name, 'Replay 2026-12');
  });

  test('once per month, even after the playlist is deleted', () async {
    history.plays = songs(10);
    final first = await run();
    await playlists.deletePlaylist(first!.id);

    expect(await run(), isNull);
    expect(playlists.saved, isEmpty);
  });

  test('songs removed from the device are skipped', () async {
    history.plays = songs(10);
    build(known: {'t1', 't3', 't5', 't7', 't9', 't8'});

    final playlist = await run();

    expect(playlist?.trackIds, ['t1', 't3', 't5', 't7', 't8', 't9']);
  });

  test('a quiet month makes no playlist and is not checked again', () async {
    history.plays = songs(4);

    expect(await run(), isNull);
    expect(playlists.saved, isEmpty);
    expect(log.lastMonth, octoberKey);
  });

  test('a failed save leaves no empty playlist and retries later', () async {
    history.plays = songs(10);
    playlists.failUpdate = true;

    final result = await replay(now: november, name: name);

    expect(result.isLeft(), isTrue);
    expect(playlists.saved, isEmpty);
    expect(playlists.deleted, hasLength(1));
    expect(log.lastMonth, isNull);
  });

  test('the log survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SharedPrefsMonthlyReplayLog(prefs).setLastMonth(octoberKey);
    expect(SharedPrefsMonthlyReplayLog(prefs).lastMonth, octoberKey);
  });
}
