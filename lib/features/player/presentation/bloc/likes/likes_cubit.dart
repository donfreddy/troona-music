import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';

part 'likes_state.dart';

final class LikesCubit extends Cubit<LikesState> {
  LikesCubit({
    required AddTrackToLikesUseCase addTrack,
    required RemoveTrackFromLikesUseCase removeTrack,
    required IsTrackInLikesUseCase isTrackLiked,
    required GetLikesPlaylistUseCase getLikesPlaylist,
  }) : _addTrack = addTrack,
       _removeTrack = removeTrack,
       _isTrackLiked = isTrackLiked,
       _getLikesPlaylist = getLikesPlaylist,
       super(const LikesState(id: null, isLiked: false, likedTrackIds: {})) {
    loadAllLikes();
  }

  final AddTrackToLikesUseCase _addTrack;
  final RemoveTrackFromLikesUseCase _removeTrack;
  final IsTrackInLikesUseCase _isTrackLiked;
  final GetLikesPlaylistUseCase _getLikesPlaylist;
  final Map<String, bool> _knownLikes = {};
  int _syncRequestId = 0;

  Future<void> loadAllLikes() async {
    final result = await _getLikesPlaylist();
    result.fold((_) {}, (playlist) {
      final ids = playlist.trackIds.toSet();
      for (final id in ids) {
        _knownLikes[id] = true;
      }
      final currentTrackLiked =
          state.id != null ? ids.contains(state.id) : state.isLiked;
      emit(
        state.copyWith(
          isLiked: currentTrackLiked,
          likedTrackIds: ids,
        ),
      );
    });
  }

  Future<void> syncTrack(Track? track) async {
    if (track == null) {
      emit(state.copyWith(id: null, isLiked: false));
      return;
    }
    final immediateLiked =
        state.likedTrackIds.contains(track.id) ||
        (_knownLikes[track.id] ??
            (state.id == track.id ? state.isLiked : false));
    emit(state.copyWith(id: track.id, isLiked: immediateLiked));

    final requestId = ++_syncRequestId;
    final result = await _isTrackLiked(track.id);
    if (requestId != _syncRequestId) return;

    final nextLiked = result.fold((_) => immediateLiked, (liked) => liked);
    _knownLikes[track.id] = nextLiked;

    final updatedIds = Set<String>.from(state.likedTrackIds);
    if (nextLiked) {
      updatedIds.add(track.id);
    } else {
      updatedIds.remove(track.id);
    }
    emit(
      LikesState(
        id: track.id,
        isLiked: nextLiked,
        likedTrackIds: updatedIds,
      ),
    );
  }

  Future<void> toggle(Track? track) async {
    if (track == null) return;

    final previousLiked =
        _knownLikes[track.id] ?? state.isTrackLiked(track.id);
    final nextLiked = !previousLiked;

    _knownLikes[track.id] = nextLiked;

    final updatedIds = Set<String>.from(state.likedTrackIds);
    if (nextLiked) {
      updatedIds.add(track.id);
    } else {
      updatedIds.remove(track.id);
    }

    emit(
      LikesState(
        id: track.id,
        isLiked: nextLiked,
        likedTrackIds: updatedIds,
      ),
    );

    final result = nextLiked
        ? await _addTrack(track.id)
        : await _removeTrack(track.id);

    if (result.isLeft()) {
      _knownLikes[track.id] = previousLiked;
      final revertedIds = Set<String>.from(state.likedTrackIds);
      if (previousLiked) {
        revertedIds.add(track.id);
      } else {
        revertedIds.remove(track.id);
      }
      emit(
        LikesState(
          id: track.id,
          isLiked: previousLiked,
          likedTrackIds: revertedIds,
        ),
      );
    }
  }
}
