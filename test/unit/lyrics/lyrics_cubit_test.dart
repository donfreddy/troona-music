import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics_lookup.dart';
import 'package:troona/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_cubit.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_state.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

import '../../helpers/fake_player.dart';

final _synced =
    LrcParser.parse(
          '[00:01.00]One\n[00:03.00]Two\n[00:05.00]Three',
          source: LyricsSource.online,
        )!
        as SyncedLyrics;

/// Answers each song from [answers]; a song in [gates] waits for its gate.
class _Repo implements LyricsRepository {
  final answers = <String, LyricsLookup>{};
  final gates = <String, Completer<void>>{};
  final asked = <String>[];
  final offsets = <String, Duration>{};
  final deleted = <String>[];
  final imported = <String>[];

  @override
  Future<LyricsLookup> lyricsFor(
    Track track, {
    bool searchAgain = false,
  }) async {
    asked.add(searchAgain ? '${track.id}!' : track.id);
    await gates[track.id]?.future;
    return answers[track.id] ?? const LyricsMissing(onlineEnabled: false);
  }

  @override
  Future<Either<Failure, Lyrics>> import(
    String trackId,
    List<int> bytes,
  ) async {
    imported.add(trackId);
    final lyrics = LrcParser.parse(
      utf8.decode(bytes),
      source: LyricsSource.imported,
    );
    return lyrics == null ? left(const LyricsFormatFailure()) : right(lyrics);
  }

  @override
  Future<Either<Failure, Unit>> setOffset(String id, Duration offset) async {
    offsets[id] = offset;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> delete(String trackId) async {
    deleted.add(trackId);
    answers.remove(trackId);
    return right(unit);
  }

  @override
  Future<void> clearOnline() async {}

  @override
  Future<int> onlineSizeBytes() async => 0;
}

void main() {
  late _Repo repo;
  late StreamController<Track?> tracks;
  late ValueNotifier<PlaybackProgress> progress;
  final a = testTrack('a', durationMs: 10000);
  final b = testTrack('b', durationMs: 10000);

  setUp(() {
    repo = _Repo()..answers['a'] = LyricsFound(_synced);
    tracks = StreamController<Track?>();
    progress = ValueNotifier(PlaybackProgress.zero);
  });

  LyricsCubit build({Track? initial}) {
    final cubit = LyricsCubit(
      repo: repo,
      tracks: tracks.stream,
      initialTrack: initial ?? a,
      progress: progress,
      lead: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  void at(int ms) => progress.value = PlaybackProgress(
    position: Duration(milliseconds: ms),
    buffered: Duration.zero,
    duration: const Duration(seconds: 10),
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('hidden: nothing is read', () async {
    final cubit = build();
    tracks.add(b);
    await settle();
    expect(repo.asked, isEmpty);
    expect(cubit.state, const LyricsIdle());
  });

  test('shown: reads the song playing', () async {
    final cubit = build()..setVisible(true);
    expect(cubit.state, const LyricsLoading('a'));
    await settle();
    expect(cubit.state, LyricsShown('a', _synced));
  });

  test('lyrics are shown with a pause where nobody sings for long; the '
      'ones kept are as found', () async {
    final found =
        LrcParser.parse(
              '[00:01.00]One\n[00:30.00]Two',
              source: LyricsSource.online,
            )!
            as SyncedLyrics;
    repo.answers['a'] = LyricsFound(found);
    final cubit = build()..setVisible(true);
    await settle();
    final shown = (cubit.state as LyricsShown).lyrics as SyncedLyrics;
    expect(shown.lines.map((l) => l.text), ['One', '', 'Two']);
    expect(shown.lines[1].isPause, isTrue);
    expect(found.lines, hasLength(2));
  });

  test('a song changing during a read: the last song wins', () async {
    repo
      ..gates['a'] = Completer()
      ..answers['b'] = const LyricsMissing(onlineEnabled: true);
    final cubit = build()..setVisible(true);
    tracks.add(b);
    await settle();
    expect(cubit.state, const LyricsNone('b', onlineEnabled: true));

    repo.gates['a']!.complete();
    await settle();
    expect(cubit.state, const LyricsNone('b', onlineEnabled: true));
  });

  test('hidden then shown on the same song: not read again', () async {
    final cubit = build()..setVisible(true);
    await settle();
    cubit
      ..setVisible(false)
      ..setVisible(true);
    await settle();
    expect(repo.asked, ['a']);
  });

  test('a song changing while hidden is read once shown', () async {
    repo.answers['b'] = const LyricsMissing(onlineEnabled: false);
    final cubit = build()..setVisible(true);
    await settle();
    cubit.setVisible(false);
    tracks.add(b);
    await settle();
    expect(cubit.state, const LyricsIdle());
    cubit.setVisible(true);
    await settle();
    expect(repo.asked, ['a', 'b']);
  });

  test('the active line follows the position, notifying only when it '
      'changes', () async {
    final cubit = build()..setVisible(true);
    await settle();
    final seen = <int>[];
    cubit.activeLine.addListener(() => seen.add(cubit.activeLine.value));
    for (var ms = 0; ms <= 6000; ms += 16) {
      at(ms);
    }
    expect(seen, [0, 1, 2]);
  });

  test('a lead lights a line up early', () async {
    final cubit = LyricsCubit(
      repo: repo,
      tracks: tracks.stream,
      initialTrack: a,
      progress: progress,
      lead: const Duration(milliseconds: 150),
    )..setVisible(true);
    addTearDown(cubit.close);
    await settle();
    at(850);
    expect(cubit.activeLine.value, 0);
  });

  test('an offset moves the line at once, is kept, and is never read '
      'again', () async {
    final cubit = build()..setVisible(true);
    await settle();
    at(2500);
    expect(cubit.activeLine.value, 0);
    cubit.nudgeOffset('a', 5);
    expect(cubit.activeLine.value, 1);
    expect(
      (cubit.state as LyricsShown).offset,
      const Duration(seconds: 0, milliseconds: 500),
    );
    await settle();
    expect(repo.offsets['a'], const Duration(milliseconds: 500));
    expect(repo.asked, ['a']);
  });

  test('an offset is clamped', () async {
    final cubit = build()..setVisible(true);
    await settle();
    cubit.nudgeOffset('a', 1000);
    expect((cubit.state as LyricsShown).offset, LyricsRepository.maxOffset);
  });

  test('a tap seeks to the line, corrected', () async {
    final cubit = build()..setVisible(true);
    await settle();
    cubit.nudgeOffset('a', 3);
    expect(
      cubit.seekTargetOf(_synced.lines[1]),
      const Duration(milliseconds: 2700),
    );
    // Never before the start.
    cubit.nudgeOffset('a', 20);
    expect(cubit.seekTargetOf(_synced.lines[0]), Duration.zero);
  });

  test('an import shows its lyrics at once', () async {
    repo.answers.remove('a');
    final cubit = build()..setVisible(true);
    await settle();
    expect(await cubit.import('a', utf8.encode('[00:01.00]Mine')), isTrue);
    final shown = cubit.state as LyricsShown;
    expect(shown.lyrics.source, LyricsSource.imported);
    expect(await cubit.import('a', utf8.encode('[ar:x]')), isFalse);
  });

  test('delete reads the song again', () async {
    final cubit = build()..setVisible(true);
    await settle();
    await cubit.delete('a');
    expect(repo.deleted, ['a']);
    expect(cubit.state, const LyricsNone('a', onlineEnabled: false));
  });

  test('a file picked once another song plays is kept for the song it '
      'was picked for, and the song shown stays', () async {
    repo.answers['b'] = const LyricsMissing(onlineEnabled: false);
    final cubit = build()..setVisible(true);
    await settle();
    tracks.add(b);
    await settle();
    expect(await cubit.import('a', utf8.encode('[00:01.00]Mine')), isTrue);
    expect(repo.imported, ['a']);
    expect(cubit.state, const LyricsNone('b', onlineEnabled: false));
  });

  test('a removal confirmed once another song plays removes the song '
      'it was asked for, and the song shown stays', () async {
    repo.answers['b'] = LyricsFound(_synced);
    final cubit = build()..setVisible(true);
    await settle();
    tracks.add(b);
    await settle();
    await cubit.delete('a');
    expect(repo.deleted, ['a']);
    expect(cubit.state, LyricsShown('b', _synced));
    expect(repo.asked, ['a', 'b']);
  });

  test('a timing step for a song no longer shown changes nothing', () async {
    repo.answers['b'] = LyricsFound(_synced);
    final cubit = build()..setVisible(true);
    await settle();
    tracks.add(b);
    await settle();
    cubit
      ..nudgeOffset('a', 5)
      ..resetOffset('a');
    await settle();
    expect((cubit.state as LyricsShown).offset, Duration.zero);
    expect(repo.offsets, isEmpty);
  });

  test('reset goes back to zero, whatever the offset', () async {
    final cubit = build()..setVisible(true);
    await settle();
    // 10 s is not a whole number of steps from 9.95 s, say: a reset never
    // counts steps.
    cubit
      ..nudgeOffset('a', 1000)
      ..resetOffset('a');
    expect((cubit.state as LyricsShown).offset, Duration.zero);
    await settle();
    expect(repo.offsets['a'], Duration.zero);
  });

  test('plain lyrics take no timing', () async {
    repo.answers['a'] = const LyricsFound(
      PlainLyrics('Words', source: LyricsSource.online),
    );
    final cubit = build()..setVisible(true);
    await settle();
    cubit.nudgeOffset('a', 3);
    expect((cubit.state as LyricsShown).offset, Duration.zero);
    expect(repo.offsets, isEmpty);
  });

  test('search online asks again', () async {
    final cubit = build()..setVisible(true);
    await settle();
    await cubit.searchOnline();
    expect(repo.asked, ['a', 'a!']);
  });

  test('nothing playing: idle', () async {
    final cubit = build()..setVisible(true);
    await settle();
    tracks.add(null);
    await settle();
    expect(cubit.state, const LyricsIdle());
  });
}
