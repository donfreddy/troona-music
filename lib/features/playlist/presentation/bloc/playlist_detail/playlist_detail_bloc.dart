import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/playlist/domain/entities/playlist_detail.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/domain/use_cases/smart_playlist_source.dart';

part 'playlist_detail_event.dart';
part 'playlist_detail_state.dart';

class PlaylistDetailBloc
    extends Bloc<PlaylistDetailEvent, PlaylistDetailState> {
  final PlaylistRepository _repo;
  final SmartPlaylistSource? _smart;

  /// Orders a smart playlist sorted at random: fixed while the page is
  /// open, so a reload does not shuffle it again.
  final int _seed;
  StreamSubscription<void>? _plays;
  String? _id;

  /// [smart] works out a smart playlist's songs, again after each play
  /// recorded in [playsRecorded] while one is open.
  PlaylistDetailBloc({
    required PlaylistRepository repo,
    SmartPlaylistSource? smart,
    Stream<void>? playsRecorded,
    int? seed,
  }) : _repo = repo,
       _smart = smart,
       _seed = seed ?? math.Random().nextInt(1 << 31),
       super(PlaylistDetailInitial()) {
    _plays = playsRecorded?.listen((_) {
      final id = _id;
      if (id != null && _isSmartShown) add(PlaylistDetailRequested(id));
    });
    on<PlaylistDetailRequested>(_onDetailRequested, transformer: droppable());
    on<PlaylistAddTrackRequested>(
      _onAddTrackRequested,
      transformer: droppable(),
    );
    on<PlaylistRemoveTrackRequested>(
      _onRemoveTrackRequested,
      transformer: droppable(),
    );
    on<PlaylistReorderTracksRequested>(
      _onReorderTracksRequested,
      transformer: droppable(),
    );
    on<PlaylistSaveAsRequested>(_onSaveAsRequested, transformer: droppable());
  }

  bool get _isSmartShown => switch (state) {
    PlaylistDetailLoaded(:final data) => data.playlist.isSmart,
    _ => false,
  };

  Future<void> _onDetailRequested(
    PlaylistDetailRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    _id = event.id;
    if (state is! PlaylistDetailLoaded) emit(PlaylistDetailLoading());

    final playlistResult = await _repo.getPlaylistById(event.id);
    final playlist = playlistResult.fold((_) => null, (p) => p);
    if (playlist == null) {
      playlistResult.fold((f) => emit(PlaylistDetailError(f.message)), (_) {});
      return;
    }
    final List<Track> tracks;
    if (playlist.rules case final rules?) {
      final smart = _smart;
      if (smart == null) {
        tracks = const [];
      } else {
        final read = await smart.read();
        final inputs = read.fold((_) => null, (i) => i);
        if (inputs == null) {
          // Never "no song matches" for songs that could not be read: an
          // error on a first load, the songs shown kept on a reload.
          if (state is! PlaylistDetailLoaded) {
            read.fold((f) => emit(PlaylistDetailError(f.message)), (_) {});
          }
          return;
        }
        tracks = inputs.evaluate(rules, seed: _seed);
      }
    } else {
      final tracksResult = await _repo.getTracksByPlaylistId(event.id);
      tracks = tracksResult.getOrElse(() => []);
    }
    emit(
      PlaylistDetailLoaded(PlaylistDetail(playlist: playlist, tracks: tracks)),
    );
  }

  /// All or none: a playlist whose songs could not be written is deleted.
  Future<void> _onSaveAsRequested(
    PlaylistSaveAsRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final shown = state;
    final name = event.name.trim();
    if (shown is! PlaylistDetailLoaded || name.isEmpty) return;
    final ids = [for (final t in shown.data.tracks) t.id];
    final created = await _repo.createPlaylist(title: name);
    final playlist = created.fold((_) => null, (p) => p);
    if (playlist == null) {
      event.onFailed?.call();
      return;
    }
    if (ids.isNotEmpty) {
      final added = await _repo.addTracksToPlaylist(playlist.id, ids);
      if (added.isLeft()) {
        await _repo.deletePlaylist(playlist.id);
        event.onFailed?.call();
        return;
      }
    }
    event.onSaved?.call(playlist);
  }

  @override
  Future<void> close() async {
    await _plays?.cancel();
    return super.close();
  }

  Future<void> _onAddTrackRequested(
    PlaylistAddTrackRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final result = await _repo.addTrackToPlaylist(
      event.playlistId,
      event.trackId,
    );
    result.fold(
      (f) => emit(PlaylistDetailError(f.message)),
      (_) => add(PlaylistDetailRequested(event.playlistId)),
    );
  }

  Future<void> _onRemoveTrackRequested(
    PlaylistRemoveTrackRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final result = await _repo.removeTrackFromPlaylist(
      event.playlistId,
      event.trackId,
    );
    result.fold(
      (f) => emit(PlaylistDetailError(f.message)),
      (_) => add(PlaylistDetailRequested(event.playlistId)),
    );
  }

  Future<void> _onReorderTracksRequested(
    PlaylistReorderTracksRequested event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final result = await _repo.reorderTracks(
      event.playlistId,
      event.oldIndex,
      event.newIndex,
    );
    result.fold(
      (f) => emit(PlaylistDetailError(f.message)),
      (_) => add(PlaylistDetailRequested(event.playlistId)),
    );
  }
}
