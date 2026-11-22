import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics_lookup.dart';
import 'package:troona/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:troona/features/lyrics/domain/services/active_line.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_state.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

/// The lyrics of the song playing, for one Now Playing page.
///
/// Reads them only while they are shown, and again when the song changes
/// under them. Every read is numbered: one that ends after the song
/// changed, or after a newer read, is dropped. The line being sung is
/// published apart, in [activeLine], so the position's ticks rebuild
/// nothing.
class LyricsCubit extends Cubit<LyricsState> {
  LyricsCubit({
    required LyricsRepository repo,
    required Stream<Track?> tracks,
    required Track? initialTrack,
    required ValueListenable<PlaybackProgress> progress,
    this.lead = defaultLead,
  }) : _repo = repo,
       _track = initialTrack,
       _progress = progress,
       super(const LyricsIdle()) {
    _tracks = tracks.listen(_onTrack);
    _progress.addListener(_follow);
  }

  /// Follows [player]'s song and position.
  factory LyricsCubit.of(LyricsRepository repo, PlayerBloc player) =>
      LyricsCubit(
        repo: repo,
        tracks: player.stream.map(trackOf),
        initialTrack: trackOf(player.state),
        progress: player.progress,
      );

  /// A line lights up this early: the eye then reads it as on time.
  static const defaultLead = Duration(milliseconds: 150);

  /// One step of the user's correction.
  static const offsetStep = Duration(milliseconds: 100);

  final LyricsRepository _repo;
  final ValueListenable<PlaybackProgress> _progress;
  final Duration lead;
  late final StreamSubscription<Track?> _tracks;

  Track? _track;
  bool _visible = false;
  int _request = 0;

  final _activeLine = ValueNotifier<int>(-1);

  /// The index of the line being sung, -1 before the first one or without
  /// synced lyrics. Notifies only when it changes.
  ValueListenable<int> get activeLine => _activeLine;

  /// The song the player is on: the one loading counts.
  static Track? trackOf(PlayerState state) => switch (state) {
    PlayerActive(:final currentTrack) => currentTrack,
    PlayerLoading(:final track) => track,
    _ => null,
  };

  /// The song's lyrics are on screen, or no longer.
  void setVisible(bool visible) {
    if (visible == _visible) return;
    _visible = visible;
    if (!visible) return;
    // Back on the same song: what was read stays.
    if (state.trackId == _track?.id && state is! LyricsIdle) {
      _follow();
      return;
    }
    unawaited(_load());
  }

  void _onTrack(Track? track) {
    if (track?.id == _track?.id) {
      _track = track;
      return;
    }
    _track = track;
    _request++;
    _activeLine.value = -1;
    if (_visible) {
      unawaited(_load());
    } else {
      emit(const LyricsIdle());
    }
  }

  Future<void> _load({bool searchAgain = false}) async {
    final track = _track;
    final id = ++_request;
    if (track == null) {
      emit(const LyricsIdle());
      return;
    }
    emit(LyricsLoading(track.id));
    final found = await _repo.lyricsFor(track, searchAgain: searchAgain);
    if (isClosed || id != _request) return;
    emit(switch (found) {
      LyricsFound(:final lyrics, :final offset) => LyricsShown(
        track.id,
        lyrics,
        offset: offset,
      ),
      LyricsMissing(:final onlineEnabled, :final unreachable) => LyricsNone(
        track.id,
        onlineEnabled: onlineEnabled,
        unreachable: unreachable,
      ),
    });
    _follow();
  }

  /// Asks the online sources again, whatever was remembered.
  Future<void> searchOnline() => _load(searchAgain: true);

  /// Keeps the file [bytes] as the lyrics of [trackId], the song shown
  /// when the import was asked for (another may play once a file is
  /// picked); false when it holds none or could not be kept.
  Future<bool> import(String trackId, List<int> bytes) async {
    final result = await _repo.import(trackId, bytes);
    return result.fold((_) => false, (lyrics) {
      if (isClosed || trackId != _track?.id) return true;
      _request++;
      emit(LyricsShown(trackId, lyrics));
      _follow();
      return true;
    });
  }

  /// Moves the lines of [trackId] [steps] of [offsetStep] earlier
  /// (negative: later); nothing once another song is shown.
  void nudgeOffset(String trackId, int steps) {
    final current = state;
    if (current is! LyricsShown) return;
    _setOffset(trackId, current.offset + offsetStep * steps);
  }

  /// Back to the lyrics' own timing.
  void resetOffset(String trackId) => _setOffset(trackId, Duration.zero);

  void _setOffset(String trackId, Duration next) {
    final current = state;
    if (current is! LyricsShown ||
        current.trackId != trackId ||
        current.lyrics is! SyncedLyrics) {
      return;
    }
    const max = LyricsRepository.maxOffset;
    final clamped = next > max ? max : (next < -max ? -max : next);
    if (clamped == current.offset) return;
    emit(current.withOffset(clamped));
    _follow();
    unawaited(
      _repo.setOffset(current.trackId, clamped).then((result) {
        result.fold(
          (f) => appLogger.w('Lyrics offset not saved: ${f.message}'),
          (_) {},
        );
      }),
    );
  }

  /// Forgets the lyrics of [trackId], the song shown when it was asked
  /// for; online ones come back only when searched for again.
  Future<void> delete(String trackId) async {
    await _repo.delete(trackId);
    if (isClosed || trackId != _track?.id) return;
    await _load();
  }

  /// Where to seek for [line] to be sung: its time, corrected.
  Duration seekTargetOf(LyricLine line) {
    final current = state;
    if (current is! LyricsShown) return line.at;
    final synced = current.lyrics;
    final offset = synced is SyncedLyrics ? synced.offset : Duration.zero;
    final target = line.at - offset - current.offset;
    return target.isNegative ? Duration.zero : target;
  }

  void _follow() {
    final current = state;
    if (!_visible || current is! LyricsShown) return;
    final lyrics = current.lyrics;
    if (lyrics is! SyncedLyrics) {
      _activeLine.value = -1;
      return;
    }
    final at = _progress.value.position + lead + lyrics.offset + current.offset;
    _activeLine.value = activeLineAt(lyrics.lines, at, hint: _activeLine.value);
  }

  @override
  Future<void> close() async {
    _progress.removeListener(_follow);
    await _tracks.cancel();
    _activeLine.dispose();
    return super.close();
  }
}
